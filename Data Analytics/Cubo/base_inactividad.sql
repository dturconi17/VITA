WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        año_mes,
        venta_total,
        compro,
        facturas,
        unidades,

        DATEFROMPARTS(
            CAST(LEFT(periodo, 4) AS INT),
            CAST(RIGHT(periodo, 2) AS INT),
            1
        ) AS fecha_mes,

        MAX(CASE WHEN compro = 1 THEN periodo END)
            OVER (
                PARTITION BY codigo_cliente
                ORDER BY periodo
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS ultima_compra_periodo,

        SUM(CASE WHEN compro = 1 THEN 1 ELSE 0 END)
            OVER (
                PARTITION BY codigo_cliente
                ORDER BY periodo
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS compras_acumuladas

    FROM sales.fact_cliente_mes

    WHERE periodo <= '202608'
),

/* ============================================================
   1. CALCULAMOS MESES DE INACTIVIDAD
   ============================================================ */

Rachas AS (
    SELECT
        *,

        CASE
            WHEN compro = 1 THEN 0
            WHEN compras_acumuladas = 0 THEN NULL

            ELSE DATEDIFF(
                MONTH,

                DATEFROMPARTS(
                    CAST(LEFT(ultima_compra_periodo, 4) AS INT),
                    CAST(RIGHT(ultima_compra_periodo, 2) AS INT),
                    1
                ),

                fecha_mes
            )

        END AS meses_inactivo

    FROM Base
),

/* ============================================================
   2. FOTO ACTUAL - AGOSTO 2026
   ============================================================ */

Actual AS (
    SELECT
        codigo_cliente,
        meses_inactivo,
        ultima_compra_periodo,

        DATEFROMPARTS(
            CAST(LEFT(ultima_compra_periodo, 4) AS INT),
            CAST(RIGHT(ultima_compra_periodo, 2) AS INT),
            1
        ) AS fecha_ultima_compra

    FROM Rachas

    WHERE periodo = '202608'
      AND meses_inactivo BETWEEN 1 AND 11
),

/* ============================================================
   3. POTENCIAL RECIENTE
   6 meses terminando en el mes de la última compra
   ============================================================ */

PotencialReciente AS (
    SELECT
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,
        a.fecha_ultima_compra,

        COUNT(*) AS meses_observados_6m,

        SUM(f.venta_total) AS venta_6m_previa,

        SUM(
            CASE WHEN f.compro = 1 THEN 1 ELSE 0 END
        ) AS meses_con_compra_6m,

        CAST(
            SUM(f.venta_total) / 6.0
            AS DECIMAL(18,2)
        ) AS potencial_reciente_6m,

        CAST(
            SUM(f.venta_total)
            /
            NULLIF(
                SUM(CASE WHEN f.compro = 1 THEN 1 ELSE 0 END),
                0
            )
            AS DECIMAL(18,2)
        ) AS promedio_mes_activo_6m,

        SUM(f.facturas) AS facturas_6m,

        SUM(f.unidades) AS unidades_6m

    FROM Actual a

    INNER JOIN sales.fact_cliente_mes f
        ON f.codigo_cliente = a.codigo_cliente

       AND DATEFROMPARTS(
            CAST(LEFT(f.periodo, 4) AS INT),
            CAST(RIGHT(f.periodo, 2) AS INT),
            1
       )
       BETWEEN DATEADD(MONTH, -5, a.fecha_ultima_compra)
           AND a.fecha_ultima_compra

    GROUP BY
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,
        a.fecha_ultima_compra

    HAVING COUNT(*) = 6
),

/* ============================================================
   4. TODAS LAS VENTANAS HISTÓRICAS DE 6 MESES
   ============================================================ */

Historico6M AS (
    SELECT
        codigo_cliente,
        periodo,
        fecha_mes,

        COUNT(*) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS meses_ventana,

        SUM(venta_total) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS venta_ventana_6m,

        MIN(fecha_mes) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS fecha_inicio_ventana

    FROM Base
),

/* ============================================================
   5. VENTANAS COMPLETAS Y CONSECUTIVAS
   ============================================================ */

VentanasValidas AS (
    SELECT
        codigo_cliente,

        fecha_inicio_ventana,

        fecha_mes AS fecha_fin_ventana,

        CAST(
            venta_ventana_6m / 6.0
            AS DECIMAL(18,2)
        ) AS potencial_historico_6m

    FROM Historico6M

    WHERE meses_ventana = 6

      AND DATEDIFF(
            MONTH,
            fecha_inicio_ventana,
            fecha_mes
          ) = 5
),

/* ============================================================
   6. BUSCAMOS LA MEJOR VENTANA HISTÓRICA
   ============================================================ */

RankingHistorico AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY codigo_cliente
            ORDER BY
                potencial_historico_6m DESC,
                fecha_fin_ventana DESC
        ) AS ranking

    FROM VentanasValidas
),

MejorHistorico AS (
    SELECT
        codigo_cliente,

        potencial_historico_6m
            AS mejor_potencial_historico_6m,

        fecha_inicio_ventana,

        fecha_fin_ventana

    FROM RankingHistorico

    WHERE ranking = 1
),

/* ============================================================
   7. UNIMOS POTENCIAL RECIENTE + HISTÓRICO
   ============================================================ */

MaestroBase AS (
    SELECT
        p.codigo_cliente,

        p.meses_inactivo,

        p.ultima_compra_periodo,

        p.fecha_ultima_compra,

        p.potencial_reciente_6m,

        h.mejor_potencial_historico_6m,

        h.fecha_inicio_ventana
            AS fecha_inicio_mejor_periodo,

        h.fecha_fin_ventana
            AS fecha_fin_mejor_periodo,

        /* Nivel reciente respecto del máximo */

        CAST(
            p.potencial_reciente_6m
            /
            NULLIF(
                h.mejor_potencial_historico_6m,
                0
            )
            * 100.0

            AS DECIMAL(10,2)
        ) AS pct_reciente_vs_maximo,

        /* Deterioro */

        CAST(
            (
                1 -
                p.potencial_reciente_6m
                /
                NULLIF(
                    h.mejor_potencial_historico_6m,
                    0
                )
            )
            * 100.0

            AS DECIMAL(10,2)
        ) AS pct_deterioro_vs_maximo,

        /* Antigüedad del máximo histórico */

        DATEDIFF(
            MONTH,
            h.fecha_fin_ventana,
            CAST('20260801' AS DATE)
        ) AS meses_desde_maximo_historico,

        p.meses_con_compra_6m,

        CAST(
            p.meses_con_compra_6m / 6.0 * 100.0
            AS DECIMAL(10,2)
        ) AS frecuencia_compra_6m_pct,

        p.promedio_mes_activo_6m,

        p.facturas_6m,

        p.unidades_6m

    FROM PotencialReciente p

    LEFT JOIN MejorHistorico h
        ON h.codigo_cliente = p.codigo_cliente
),

/* ============================================================
   8. QUINTILES
   ============================================================ */

Quintiles AS (
    SELECT
        *,

        NTILE(5) OVER (
            ORDER BY potencial_reciente_6m
        ) AS quintil_potencial_reciente,

        NTILE(5) OVER (
            ORDER BY mejor_potencial_historico_6m
        ) AS quintil_potencial_historico

    FROM MaestroBase
),

/* ============================================================
   9. AGREGAMOS RIESGO HISTÓRICO DE LLEGAR A 12 MESES
   ============================================================ */

ConRiesgo AS (
    SELECT
        *,

        CASE meses_inactivo
            WHEN 1  THEN 7.14
            WHEN 2  THEN 14.23
            WHEN 3  THEN 23.54
            WHEN 4  THEN 33.91
            WHEN 5  THEN 44.54
            WHEN 6  THEN 54.92
            WHEN 7  THEN 64.64
            WHEN 8  THEN 73.61
            WHEN 9  THEN 82.26
            WHEN 10 THEN 88.92
            WHEN 11 THEN 94.77
        END AS riesgo_llegar_12m_pct

    FROM Quintiles
)

/* ============================================================
   10. DATASET MAESTRO FINAL
   ============================================================ */

SELECT top 30
    codigo_cliente,

    meses_inactivo,

    ultima_compra_periodo,

    potencial_reciente_6m,

    quintil_potencial_reciente,

    mejor_potencial_historico_6m,

    quintil_potencial_historico,

    CONVERT(
        CHAR(6),
        fecha_inicio_mejor_periodo,
        112
    ) AS inicio_mejor_periodo,

    CONVERT(
        CHAR(6),
        fecha_fin_mejor_periodo,
        112
    ) AS fin_mejor_periodo,

    meses_desde_maximo_historico,

    pct_reciente_vs_maximo,

    pct_deterioro_vs_maximo,

    meses_con_compra_6m,

    frecuencia_compra_6m_pct,

    promedio_mes_activo_6m,

    facturas_6m,

    unidades_6m,

    riesgo_llegar_12m_pct,

    /* Exposición basada en potencial reciente */

    CAST(
        potencial_reciente_6m
        * riesgo_llegar_12m_pct
        / 100.0

        AS DECIMAL(18,2)
    ) AS exposicion_reciente_riesgo,

    /* Exposición basada en máximo histórico.
       La dejamos como información, NO como venta perdida. */

    CAST(
        mejor_potencial_historico_6m
        * riesgo_llegar_12m_pct
        / 100.0

        AS DECIMAL(18,2)
    ) AS exposicion_historica_riesgo

FROM ConRiesgo

ORDER BY
    exposicion_reciente_riesgo DESC;









    WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        venta_total,
        compro,

        DATEFROMPARTS(
            CAST(LEFT(periodo,4) AS INT),
            CAST(RIGHT(periodo,2) AS INT),
            1
        ) AS fecha_mes

    FROM sales.fact_cliente_mes
    WHERE periodo <= '202608'
),

/* ============================================================
   1. VENTANAS MÓVILES DE 6 MESES
   Para cada cliente y cada mes calculamos cómo venía comprando
   ============================================================ */

Ventanas6M AS (
    SELECT
        codigo_cliente,
        periodo,
        fecha_mes,
        compro,

        COUNT(*) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS meses_ventana,

        MIN(fecha_mes) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS fecha_inicio_ventana,

        SUM(venta_total) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) / 6.0 AS potencial_6m,

        SUM(
            CASE WHEN compro = 1 THEN 1 ELSE 0 END
        ) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS meses_con_compra_6m

    FROM Base
),

/* ============================================================
   2. SOLO VENTANAS DE 6 MESES REALES Y CONSECUTIVOS
   ============================================================ */

VentanasValidas AS (
    SELECT
        *,
        CAST(
            meses_con_compra_6m / 6.0 * 100.0
            AS DECIMAL(10,2)
        ) AS frecuencia_compra_6m_pct

    FROM Ventanas6M

    WHERE meses_ventana = 6

      AND DATEDIFF(
            MONTH,
            fecha_inicio_ventana,
            fecha_mes
          ) = 5
),

/* ============================================================
   3. MEJOR POTENCIAL HISTÓRICO CONOCIDO HASTA CADA MOMENTO

   IMPORTANTE:
   No usamos el futuro.
   ============================================================ */

HistoriaPotencial AS (
    SELECT
        *,

        MAX(potencial_6m) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS mejor_potencial_hasta_fecha

    FROM VentanasValidas
),

/* ============================================================
   4. DETECTAMOS EL INICIO DE CADA RACHA DE INACTIVIDAD

   Un episodio comienza cuando:
   mes anterior = compró
   mes actual   = no compró
   ============================================================ */

Secuencia AS (
    SELECT
        *,

        LAG(compro) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
        ) AS compro_mes_anterior

    FROM Base
),

InicioInactividad AS (
    SELECT
        codigo_cliente,
        periodo AS primer_mes_inactivo,
        fecha_mes AS fecha_inicio_inactividad

    FROM Secuencia

    WHERE compro = 0
      AND compro_mes_anterior = 1
),

/* ============================================================
   5. TOMAMOS EL MES ANTERIOR A LA INACTIVIDAD

   Ahí medimos:
   - potencial reciente
   - frecuencia
   - máximo histórico conocido
   ============================================================ */

Episodios AS (
    SELECT
        i.codigo_cliente,
        i.primer_mes_inactivo,
        i.fecha_inicio_inactividad,

        h.periodo AS ultimo_mes_activo,

        h.potencial_6m
            AS potencial_previo_6m,

        h.mejor_potencial_hasta_fecha,

        h.frecuencia_compra_6m_pct,

        CAST(
            h.potencial_6m
            /
            NULLIF(h.mejor_potencial_hasta_fecha,0)
            * 100.0
            AS DECIMAL(10,2)
        ) AS pct_vs_maximo_previo

    FROM InicioInactividad i

    INNER JOIN HistoriaPotencial h
        ON h.codigo_cliente = i.codigo_cliente

       AND h.fecha_mes =
           DATEADD(
               MONTH,
               -1,
               i.fecha_inicio_inactividad
           )
),

/* ============================================================
   6. OBSERVAMOS QUÉ PASÓ DESPUÉS DEL INICIO DE LA INACTIVIDAD
   ============================================================ */

Resultados AS (
    SELECT
        e.*,

        /* Reactivó dentro de los primeros 3 meses */

        CASE
            WHEN EXISTS (
                SELECT 1

                FROM Base f

                WHERE f.codigo_cliente = e.codigo_cliente

                  AND f.fecha_mes BETWEEN
                      e.fecha_inicio_inactividad
                      AND DATEADD(
                          MONTH,
                          2,
                          e.fecha_inicio_inactividad
                      )

                  AND f.compro = 1
            )
            THEN 1
            ELSE 0
        END AS reactivo_3m,

        /* Llegó a 12 meses consecutivos sin comprar */

        CASE
            WHEN NOT EXISTS (
                SELECT 1

                FROM Base f

                WHERE f.codigo_cliente = e.codigo_cliente

                  AND f.fecha_mes BETWEEN
                      e.fecha_inicio_inactividad
                      AND DATEADD(
                          MONTH,
                          11,
                          e.fecha_inicio_inactividad
                      )

                  AND f.compro = 1
            )
            THEN 1
            ELSE 0
        END AS llego_12m

    FROM Episodios e

    /* Necesitamos 12 meses futuros observables */

    WHERE DATEADD(
              MONTH,
              11,
              e.fecha_inicio_inactividad
          ) <= '20260801'
),

/* ============================================================
   7. CLASIFICAMOS EL ESTADO PREVIO A LA CAÍDA
   ============================================================ */

Clasificacion AS (
    SELECT
        *,

        CASE
            WHEN pct_vs_maximo_previo >= 80
                THEN 'Estable / cerca del maximo'

            WHEN pct_vs_maximo_previo >= 50
                THEN 'Deterioro moderado'

            ELSE 'Muy deteriorada'

        END AS estado_previo,

        CASE
            WHEN frecuencia_compra_6m_pct >= 83.33
                THEN 'Frecuencia alta'

            WHEN frecuencia_compra_6m_pct >= 50
                THEN 'Frecuencia media'

            ELSE 'Frecuencia baja'

        END AS nivel_frecuencia

    FROM Resultados
)

/* ============================================================
   8. RESULTADO
   ============================================================ */

SELECT
    estado_previo,

    nivel_frecuencia,

    COUNT(*) AS episodios,

    SUM(reactivo_3m) AS episodios_reactivados_3m,

    CAST(
        AVG(
            CAST(reactivo_3m AS DECIMAL(10,4))
        ) * 100
        AS DECIMAL(10,2)
    ) AS pct_reactiva_3m,

    SUM(llego_12m) AS episodios_llegan_12m,

    CAST(
        AVG(
            CAST(llego_12m AS DECIMAL(10,4))
        ) * 100
        AS DECIMAL(10,2)
    ) AS pct_llega_12m,

    CAST(
        AVG(potencial_previo_6m)
        AS DECIMAL(18,2)
    ) AS potencial_promedio_previo

FROM Clasificacion

GROUP BY
    estado_previo,
    nivel_frecuencia

ORDER BY
    estado_previo,
    nivel_frecuencia;









 WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        venta_total,
        compro,

        DATEFROMPARTS(
            CAST(LEFT(periodo, 4) AS INT),
            CAST(RIGHT(periodo, 2) AS INT),
            1
        ) AS fecha_mes

    FROM sales.fact_cliente_mes
    WHERE periodo <= '202608'
),

/* ============================================================
   1. IDENTIFICAMOS INICIO DE CADA RACHA DE INACTIVIDAD
   ============================================================ */

Secuencia AS (
    SELECT
        *,

        LAG(compro) OVER (
            PARTITION BY codigo_cliente
            ORDER BY periodo
        ) AS compro_mes_anterior

    FROM Base
),

InicioInactividad AS (
    SELECT
        codigo_cliente,
        periodo AS primer_mes_inactivo,
        fecha_mes AS fecha_inicio_inactividad

    FROM Secuencia

    WHERE compro = 0
      AND compro_mes_anterior = 1
),

/* ============================================================
   2. CALCULAMOS COMPORTAMIENTO DE LOS 6 MESES PREVIOS
   ============================================================ */

FrecuenciaPrevia AS (
    SELECT
        i.codigo_cliente,
        i.primer_mes_inactivo,
        i.fecha_inicio_inactividad,

        COUNT(f.periodo) AS meses_observados_previos,

        SUM(
            CASE WHEN f.compro = 1 THEN 1 ELSE 0 END
        ) AS meses_con_compra_previos,

        CAST(
            SUM(
                CASE WHEN f.compro = 1 THEN 1 ELSE 0 END
            ) / 6.0 * 100.0
            AS DECIMAL(10,2)
        ) AS frecuencia_previa_pct,

        CAST(
            SUM(f.venta_total) / 6.0
            AS DECIMAL(18,2)
        ) AS potencial_previo_6m

    FROM InicioInactividad i

    INNER JOIN Base f
        ON f.codigo_cliente = i.codigo_cliente

       AND f.fecha_mes BETWEEN
           DATEADD(MONTH, -6, i.fecha_inicio_inactividad)
           AND
           DATEADD(MONTH, -1, i.fecha_inicio_inactividad)

    GROUP BY
        i.codigo_cliente,
        i.primer_mes_inactivo,
        i.fecha_inicio_inactividad

    HAVING COUNT(f.periodo) = 6
),

/* ============================================================
   3. CLASIFICAMOS FRECUENCIA PREVIA
   ============================================================ */

Episodios AS (
    SELECT
        *,

        CASE
            WHEN meses_con_compra_previos >= 5
                THEN 'Frecuencia alta'

            WHEN meses_con_compra_previos >= 3
                THEN 'Frecuencia media'

            ELSE 'Frecuencia baja'
        END AS nivel_frecuencia

    FROM FrecuenciaPrevia

    /* Necesitamos poder observar los 12 meses posteriores */
    WHERE DATEADD(
              MONTH,
              11,
              fecha_inicio_inactividad
          ) <= CAST('20260801' AS DATE)
),

/* ============================================================
   4. EXPANDIMOS CADA EPISODIO A LOS MESES 1...11
   ============================================================ */

Meses AS (
    SELECT 1 AS meses_inactivo
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
    UNION ALL SELECT 6
    UNION ALL SELECT 7
    UNION ALL SELECT 8
    UNION ALL SELECT 9
    UNION ALL SELECT 10
    UNION ALL SELECT 11
),

EpisodiosMes AS (
    SELECT
        e.codigo_cliente,
        e.primer_mes_inactivo,
        e.fecha_inicio_inactividad,
        e.nivel_frecuencia,
        e.meses_con_compra_previos,
        e.frecuencia_previa_pct,
        e.potencial_previo_6m,

        m.meses_inactivo,

        DATEADD(
            MONTH,
            m.meses_inactivo - 1,
            e.fecha_inicio_inactividad
        ) AS fecha_mes_evaluado

    FROM Episodios e

    CROSS JOIN Meses m
),

/* ============================================================
   5. NOS QUEDAMOS SOLO CON LOS EPISODIOS QUE REALMENTE
      ALCANZARON CADA NIVEL DE INACTIVIDAD

   Si compró antes de llegar al mes X, ese episodio no forma
   parte de la población condicionada a X meses.
   ============================================================ */

AlcanzoMes AS (
    SELECT
        em.*

    FROM EpisodiosMes em

    WHERE NOT EXISTS (
        SELECT 1

        FROM Base b

        WHERE b.codigo_cliente = em.codigo_cliente

          AND b.fecha_mes BETWEEN
              em.fecha_inicio_inactividad
              AND em.fecha_mes_evaluado

          AND b.compro = 1
    )
),

/* ============================================================
   6. PARA LOS QUE YA LLEGARON A X MESES:
      ¿TERMINARON LLEGANDO A 12 MESES SIN COMPRAR?
   ============================================================ */

Resultado AS (
    SELECT
        a.*,

        CASE
            WHEN NOT EXISTS (
                SELECT 1

                FROM Base b

                WHERE b.codigo_cliente = a.codigo_cliente

                  AND b.fecha_mes BETWEEN
                      a.fecha_inicio_inactividad
                      AND DATEADD(
                          MONTH,
                          11,
                          a.fecha_inicio_inactividad
                      )

                  AND b.compro = 1
            )
            THEN 1
            ELSE 0
        END AS llego_12m

    FROM AlcanzoMes a
)

/* ============================================================
   7. CURVA DE RIESGO CONDICIONADA
   ============================================================ */

SELECT
    meses_inactivo,

    nivel_frecuencia,

    COUNT(*) AS casos,

    SUM(llego_12m) AS casos_llegan_12m,

    CAST(
        AVG(
            CAST(llego_12m AS DECIMAL(10,4))
        ) * 100.0
        AS DECIMAL(10,2)
    ) AS riesgo_llegar_12m_pct,

    CAST(
        AVG(potencial_previo_6m)
        AS DECIMAL(18,2)
    ) AS potencial_promedio_previo

FROM Resultado

GROUP BY
    meses_inactivo,
    nivel_frecuencia

ORDER BY
    meses_inactivo,

    CASE nivel_frecuencia
        WHEN 'Frecuencia alta' THEN 1
        WHEN 'Frecuencia media' THEN 2
        WHEN 'Frecuencia baja' THEN 3
    END;   