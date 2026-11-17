WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        venta_total,
        compro,
        facturas,
        unidades,

        DATEFROMPARTS(
            CAST(LEFT(periodo,4) AS INT),
            CAST(RIGHT(periodo,2) AS INT),
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
   1. CALCULAMOS RACHA DE INACTIVIDAD
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
                    CAST(LEFT(ultima_compra_periodo,4) AS INT),
                    CAST(RIGHT(ultima_compra_periodo,2) AS INT),
                    1
                ),

                fecha_mes
            )
        END AS meses_inactivo

    FROM Base
),

/* ============================================================
   2. UNIVERSO ACTUAL:
      FARMACIAS CON 1 A 11 MESES INACTIVAS A AGOSTO 2026
   ============================================================ */

Actual AS (
    SELECT
        codigo_cliente,
        meses_inactivo,
        ultima_compra_periodo,

        DATEFROMPARTS(
            CAST(LEFT(ultima_compra_periodo,4) AS INT),
            CAST(RIGHT(ultima_compra_periodo,2) AS INT),
            1
        ) AS fecha_ultima_compra

    FROM Rachas

    WHERE periodo = '202608'
      AND meses_inactivo BETWEEN 1 AND 11
),

/* ============================================================
   3. COMPORTAMIENTO EN LOS 6 MESES PREVIOS A LA CAÍDA
   ============================================================ */

Previo6M AS (
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
            CAST(LEFT(f.periodo,4) AS INT),
            CAST(RIGHT(f.periodo,2) AS INT),
            1
       )
       BETWEEN DATEADD(MONTH,-5,a.fecha_ultima_compra)
           AND a.fecha_ultima_compra

    GROUP BY
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,
        a.fecha_ultima_compra

    HAVING COUNT(*) = 6
),

/* ============================================================
   4. FRECUENCIA PREVIA
   ============================================================ */

ConFrecuencia AS (
    SELECT
        *,

        CAST(
            meses_con_compra_6m / 6.0 * 100.0
            AS DECIMAL(10,2)
        ) AS frecuencia_compra_6m_pct,

        CASE
            WHEN meses_con_compra_6m >= 5
                THEN 'Frecuencia alta'

            WHEN meses_con_compra_6m >= 3
                THEN 'Frecuencia media'

            ELSE 'Frecuencia baja'
        END AS nivel_frecuencia

    FROM Previo6M
),

/* ============================================================
   5. POTENCIAL HISTÓRICO:
      MEJOR PROMEDIO MÓVIL DE 6 MESES
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
   6. UNIMOS INFORMACIÓN ACTUAL + HISTÓRICA
   ============================================================ */

MaestroBase AS (
    SELECT
        p.codigo_cliente,
        p.meses_inactivo,
        p.ultima_compra_periodo,

        p.potencial_reciente_6m,

        p.meses_con_compra_6m,
        p.frecuencia_compra_6m_pct,
        p.nivel_frecuencia,

        p.promedio_mes_activo_6m,
        p.facturas_6m,
        p.unidades_6m,

        h.mejor_potencial_historico_6m,

        h.fecha_inicio_ventana
            AS fecha_inicio_mejor_periodo,

        h.fecha_fin_ventana
            AS fecha_fin_mejor_periodo,

        CAST(
            p.potencial_reciente_6m
            /
            NULLIF(
                h.mejor_potencial_historico_6m,
                0
            ) * 100.0
            AS DECIMAL(10,2)
        ) AS pct_reciente_vs_maximo,

        CAST(
            (
                1 -
                p.potencial_reciente_6m
                /
                NULLIF(
                    h.mejor_potencial_historico_6m,
                    0
                )
            ) * 100.0
            AS DECIMAL(10,2)
        ) AS pct_deterioro_vs_maximo,

        DATEDIFF(
            MONTH,
            h.fecha_fin_ventana,
            CAST('20260801' AS DATE)
        ) AS meses_desde_maximo_historico

    FROM ConFrecuencia p

    LEFT JOIN MejorHistorico h
        ON h.codigo_cliente = p.codigo_cliente
),

/* ============================================================
   7. QUINTILES DE POTENCIAL
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
   8. RIESGO GENERAL
   ============================================================ */

RiesgoGeneral AS (
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
        END AS riesgo_12m_general

    FROM Quintiles
),

/* ============================================================
   9. NUEVO RIESGO CONDICIONADO:
      MESES INACTIVO + FRECUENCIA PREVIA
   ============================================================ */

RiesgoCondicionado AS (
    SELECT
        *,

        CASE

            /* FRECUENCIA ALTA */

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 1 THEN 3.64

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 2 THEN 13.47

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 3 THEN 30.51

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 4 THEN 50.77

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 5 THEN 62.66

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 6 THEN 73.88

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 7 THEN 81.48

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 8 THEN 86.46

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 9 THEN 92.09

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 10 THEN 94.74

            WHEN nivel_frecuencia = 'Frecuencia alta'
                 AND meses_inactivo = 11 THEN 98.51


            /* FRECUENCIA MEDIA */

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 1 THEN 4.29

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 2 THEN 9.21

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 3 THEN 17.54

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 4 THEN 28.70

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 5 THEN 40.00

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 6 THEN 51.52

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 7 THEN 62.96

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 8 THEN 73.30

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 9 THEN 81.40

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 10 THEN 88.58

            WHEN nivel_frecuencia = 'Frecuencia media'
                 AND meses_inactivo = 11 THEN 95.26


            /* FRECUENCIA BAJA */

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 1 THEN 12.49

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 2 THEN 17.94

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 3 THEN 25.18

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 4 THEN 33.48

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 5 THEN 42.94

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 6 THEN 52.25

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 7 THEN 61.37

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 8 THEN 70.80

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 9 THEN 80.56

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 10 THEN 87.81

            WHEN nivel_frecuencia = 'Frecuencia baja'
                 AND meses_inactivo = 11 THEN 93.81

        END AS riesgo_12m_condicionado

    FROM RiesgoGeneral
)

/* ============================================================
   10. DATASET MAESTRO FINAL
   ============================================================ */

SELECT 
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
    nivel_frecuencia,

    promedio_mes_activo_6m,
    facturas_6m,
    unidades_6m,

    riesgo_12m_general,
    riesgo_12m_condicionado,

    /* Diferencia contra modelo general */

    CAST(
        riesgo_12m_condicionado
        - riesgo_12m_general
        AS DECIMAL(10,2)
    ) AS diferencia_riesgo_pp,

    /* Exposición económica usando riesgo general */

    CAST(
        potencial_reciente_6m
        * riesgo_12m_general / 100.0
        AS DECIMAL(18,2)
    ) AS exposicion_riesgo_general,

    /* NUEVA exposición económica */

    CAST(
        potencial_reciente_6m
        * riesgo_12m_condicionado / 100.0
        AS DECIMAL(18,2)
    ) AS exposicion_riesgo_condicionado

FROM RiesgoCondicionado

ORDER BY
    exposicion_riesgo_condicionado DESC;






-----Reporteria

WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        venta_total,
        compro,
        facturas,
        unidades,

        DATEFROMPARTS(
            CAST(LEFT(periodo,4) AS INT),
            CAST(RIGHT(periodo,2) AS INT),
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
                    CAST(LEFT(ultima_compra_periodo,4) AS INT),
                    CAST(RIGHT(ultima_compra_periodo,2) AS INT),
                    1
                ),

                fecha_mes
            )
        END AS meses_inactivo

    FROM Base
),

/* ============================================================
   2. FARMACIAS ACTUALMENTE INACTIVAS
      1 A 11 MESES A AGOSTO 2026
   ============================================================ */

Actual AS (
    SELECT
        codigo_cliente,
        meses_inactivo,
        ultima_compra_periodo,

        DATEFROMPARTS(
            CAST(LEFT(ultima_compra_periodo,4) AS INT),
            CAST(RIGHT(ultima_compra_periodo,2) AS INT),
            1
        ) AS fecha_ultima_compra

    FROM Rachas

    WHERE periodo = '202608'
      AND meses_inactivo BETWEEN 1 AND 11
),

/* ============================================================
   3. COMPORTAMIENTO EN LOS 6 MESES PREVIOS
   ============================================================ */

Previo6M AS (
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
            CAST(LEFT(f.periodo,4) AS INT),
            CAST(RIGHT(f.periodo,2) AS INT),
            1
       )
       BETWEEN DATEADD(MONTH,-5,a.fecha_ultima_compra)
           AND a.fecha_ultima_compra

    GROUP BY
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,
        a.fecha_ultima_compra

    HAVING COUNT(*) = 6
),

/* ============================================================
   4. FRECUENCIA PREVIA
   ============================================================ */

ConFrecuencia AS (
    SELECT
        *,

        CAST(
            meses_con_compra_6m / 6.0 * 100.0
            AS DECIMAL(10,2)
        ) AS frecuencia_compra_6m_pct,

        CASE
            WHEN meses_con_compra_6m >= 5
                THEN 'Frecuencia alta'

            WHEN meses_con_compra_6m >= 3
                THEN 'Frecuencia media'

            ELSE 'Frecuencia baja'
        END AS nivel_frecuencia

    FROM Previo6M
),

/* ============================================================
   5. VENTANAS HISTÓRICAS DE 6 MESES
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
   6. BUSCAMOS EL MAYOR POTENCIAL HISTÓRICO DE CADA FARMACIA
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
   7. UNIMOS POTENCIAL RECIENTE + POTENCIAL HISTÓRICO
   ============================================================ */

MaestroBase AS (
    SELECT
        p.codigo_cliente,
        p.meses_inactivo,
        p.ultima_compra_periodo,

        p.potencial_reciente_6m,

        p.meses_con_compra_6m,
        p.frecuencia_compra_6m_pct,
        p.nivel_frecuencia,

        p.promedio_mes_activo_6m,
        p.facturas_6m,
        p.unidades_6m,

        h.mejor_potencial_historico_6m,

        h.fecha_inicio_ventana
            AS fecha_inicio_mejor_periodo,

        h.fecha_fin_ventana
            AS fecha_fin_mejor_periodo,

        CAST(
            p.potencial_reciente_6m
            /
            NULLIF(
                h.mejor_potencial_historico_6m,
                0
            ) * 100.0
            AS DECIMAL(10,2)
        ) AS pct_reciente_vs_maximo,

        CAST(
            (
                1 -
                p.potencial_reciente_6m
                /
                NULLIF(
                    h.mejor_potencial_historico_6m,
                    0
                )
            ) * 100.0
            AS DECIMAL(10,2)
        ) AS pct_deterioro_vs_maximo

    FROM ConFrecuencia p

    LEFT JOIN MejorHistorico h
        ON h.codigo_cliente = p.codigo_cliente
),

/* ============================================================
   8. ASIGNAMOS EL RIESGO GENERAL DE LLEGAR A 12 MESES
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
        END AS riesgo_12m_general

    FROM MaestroBase
),

/* ============================================================
   9. CALCULAMOS EXPOSICIÓN AL RIESGO GENERAL
   ============================================================ */

Maestro AS (
    SELECT
        *,

        CAST(
            potencial_reciente_6m
            * riesgo_12m_general / 100.0
            AS DECIMAL(18,2)
        ) AS exposicion_riesgo_general

    FROM ConRiesgo
),

/* ============================================================
   10. CALCULAMOS LAS MEDIANAS

   Estas serán las líneas que dividen el gráfico
   en cuatro cuadrantes.
   ============================================================ */

Medianas AS (
    SELECT DISTINCT

        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY mejor_potencial_historico_6m
        ) OVER () AS mediana_potencial,

        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY exposicion_riesgo_general
        ) OVER () AS mediana_exposicion

    FROM Maestro

    WHERE mejor_potencial_historico_6m IS NOT NULL
      AND exposicion_riesgo_general IS NOT NULL
),

/* ============================================================
   11. CLASIFICAMOS CADA FARMACIA EN UNO DE LOS 4 CUADRANTES
   ============================================================ */

Clasificacion AS (
    SELECT
        m.codigo_cliente,

        m.meses_inactivo,

        m.mejor_potencial_historico_6m,

        m.potencial_reciente_6m,

        m.riesgo_12m_general,

        m.exposicion_riesgo_general,

        x.mediana_potencial,

        x.mediana_exposicion,

        CASE

            WHEN m.mejor_potencial_historico_6m >= x.mediana_potencial
             AND m.exposicion_riesgo_general >= x.mediana_exposicion
                THEN '1 - Alto potencial / Alta exposicion'

            WHEN m.mejor_potencial_historico_6m >= x.mediana_potencial
             AND m.exposicion_riesgo_general < x.mediana_exposicion
                THEN '2 - Alto potencial / Baja exposicion'

            WHEN m.mejor_potencial_historico_6m < x.mediana_potencial
             AND m.exposicion_riesgo_general >= x.mediana_exposicion
                THEN '3 - Bajo potencial / Alta exposicion'

            ELSE
                '4 - Bajo potencial / Baja exposicion'

        END AS cuadrante

    FROM Maestro m

    CROSS JOIN Medianas x

    WHERE m.mejor_potencial_historico_6m IS NOT NULL
      AND m.exposicion_riesgo_general IS NOT NULL
)

/* ============================================================
   12. RESULTADO FINAL:
       CANTIDAD DE FARMACIAS POR CUADRANTE
   ============================================================ */

SELECT
    cuadrante,

    COUNT(*) AS cantidad_farmacias,

    CAST(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS pct_farmacias,

    CAST(
        AVG(mejor_potencial_historico_6m)
        AS DECIMAL(18,2)
    ) AS potencial_historico_promedio,

    CAST(
        AVG(exposicion_riesgo_general)
        AS DECIMAL(18,2)
    ) AS exposicion_promedio,

    CAST(
        MIN(mejor_potencial_historico_6m)
        AS DECIMAL(18,2)
    ) AS potencial_minimo,

    CAST(
        MAX(mejor_potencial_historico_6m)
        AS DECIMAL(18,2)
    ) AS potencial_maximo,

    CAST(
        AVG(meses_inactivo * 1.0)
        AS DECIMAL(10,2)
    ) AS meses_inactivo_promedio,

    CAST(
        MAX(mediana_potencial)
        AS DECIMAL(18,2)
    ) AS corte_mediana_potencial,

    CAST(
        MAX(mediana_exposicion)
        AS DECIMAL(18,2)
    ) AS corte_mediana_exposicion

FROM Clasificacion

GROUP BY cuadrante

ORDER BY cuadrante;