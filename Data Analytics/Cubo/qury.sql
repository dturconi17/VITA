SELECT TOP 20 *
FROM sales.fact_cliente_mes
ORDER BY 1;



SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sales'
  AND TABLE_NAME = 'fact_cliente_mes'
ORDER BY ORDINAL_POSITION;


SELECT
    MIN(periodo) AS primer_periodo,
    MAX(periodo) AS ultimo_periodo,
    COUNT(*) AS registros,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    SUM(CASE WHEN compro = 1 THEN 1 ELSE 0 END) AS cliente_mes_con_compra,
    SUM(CASE WHEN compro = 0 THEN 1 ELSE 0 END) AS cliente_mes_sin_compra
FROM sales.fact_cliente_mes;



SELECT
    periodo,
    COUNT(*) AS clientes,
    SUM(CASE WHEN compro = 1 THEN 1 ELSE 0 END) AS compraron,
    SUM(CASE WHEN compro = 0 THEN 1 ELSE 0 END) AS no_compraron,
    SUM(venta_total) AS venta_total
FROM sales.fact_cliente_mes
GROUP BY periodo
ORDER BY periodo;

WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        año_mes,
        venta_total,
        compro,

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

Rachas AS (
    SELECT
        *,
        CASE
            WHEN compro = 1 THEN 0

            -- todavía nunca había comprado
            WHEN compras_acumuladas = 0 THEN NULL

            ELSE DATEDIFF(
                MONTH,
                DATEFROMPARTS(
                    CAST(LEFT(ultima_compra_periodo,4) AS INT),
                    CAST(RIGHT(ultima_compra_periodo,2) AS INT),
                    1
                ),
                DATEFROMPARTS(
                    CAST(LEFT(periodo,4) AS INT),
                    CAST(RIGHT(periodo,2) AS INT),
                    1
                )
            )
        END AS meses_inactivo

    FROM Base
)

SELECT TOP 200
    codigo_cliente,
    periodo,
    año_mes,
    venta_total,
    compro,
    ultima_compra_periodo,
    meses_inactivo
FROM Rachas
WHERE compras_acumuladas > 0
ORDER BY codigo_cliente, periodo;







---Reporteria

WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        año_mes,
        venta_total,
        compro,

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
                DATEFROMPARTS(
                    CAST(LEFT(periodo,4) AS INT),
                    CAST(RIGHT(periodo,2) AS INT),
                    1
                )
            )
        END AS meses_inactivo,

        DATEFROMPARTS(
            CAST(LEFT(periodo,4) AS INT),
            CAST(RIGHT(periodo,2) AS INT),
            1
        ) AS fecha_mes

    FROM Base
),

Futuro AS (
    SELECT
        r.codigo_cliente,
        r.periodo,
        r.fecha_mes,
        r.meses_inactivo,

        MAX(CASE
            WHEN f.compro = 1
             AND DATEDIFF(MONTH, r.fecha_mes, f.fecha_mes) BETWEEN 1 AND 1
            THEN 1 ELSE 0
        END) AS reactiva_1m,

        MAX(CASE
            WHEN f.compro = 1
             AND DATEDIFF(MONTH, r.fecha_mes, f.fecha_mes) BETWEEN 1 AND 3
            THEN 1 ELSE 0
        END) AS reactiva_3m,

        MAX(CASE
            WHEN f.compro = 1
             AND DATEDIFF(MONTH, r.fecha_mes, f.fecha_mes) BETWEEN 1 AND 6
            THEN 1 ELSE 0
        END) AS reactiva_6m,

        MAX(CASE
            WHEN f.compro = 1
             AND DATEDIFF(MONTH, r.fecha_mes, f.fecha_mes) BETWEEN 1 AND 12
            THEN 1 ELSE 0
        END) AS reactiva_12m

    FROM Rachas r

    LEFT JOIN Rachas f
        ON r.codigo_cliente = f.codigo_cliente
       AND f.fecha_mes > r.fecha_mes
       AND f.fecha_mes <= DATEADD(MONTH, 12, r.fecha_mes)

    WHERE r.meses_inactivo BETWEEN 1 AND 18

    GROUP BY
        r.codigo_cliente,
        r.periodo,
        r.fecha_mes,
        r.meses_inactivo
)

SELECT
    meses_inactivo,

    /* Horizonte 1 mes */
    SUM(CASE
        WHEN fecha_mes <= '2026-07-01'
        THEN 1 ELSE 0
    END) AS casos_1m,

    CAST(
        100.0 * SUM(CASE
            WHEN fecha_mes <= '2026-07-01'
             AND reactiva_1m = 1
            THEN 1 ELSE 0
        END)
        /
        NULLIF(SUM(CASE
            WHEN fecha_mes <= '2026-07-01'
            THEN 1 ELSE 0
        END),0)
    AS DECIMAL(10,2)) AS pct_reactiva_1m,


    /* Horizonte 3 meses */
    SUM(CASE
        WHEN fecha_mes <= '2026-05-01'
        THEN 1 ELSE 0
    END) AS casos_3m,

    CAST(
        100.0 * SUM(CASE
            WHEN fecha_mes <= '2026-05-01'
             AND reactiva_3m = 1
            THEN 1 ELSE 0
        END)
        /
        NULLIF(SUM(CASE
            WHEN fecha_mes <= '2026-05-01'
            THEN 1 ELSE 0
        END),0)
    AS DECIMAL(10,2)) AS pct_reactiva_3m,


    /* Horizonte 6 meses */
    SUM(CASE
        WHEN fecha_mes <= '2026-02-01'
        THEN 1 ELSE 0
    END) AS casos_6m,

    CAST(
        100.0 * SUM(CASE
            WHEN fecha_mes <= '2026-02-01'
             AND reactiva_6m = 1
            THEN 1 ELSE 0
        END)
        /
        NULLIF(SUM(CASE
            WHEN fecha_mes <= '2026-02-01'
            THEN 1 ELSE 0
        END),0)
    AS DECIMAL(10,2)) AS pct_reactiva_6m,


    /* Horizonte 12 meses */
    SUM(CASE
        WHEN fecha_mes <= '2025-08-01'
        THEN 1 ELSE 0
    END) AS casos_12m,

    CAST(
        100.0 * SUM(CASE
            WHEN fecha_mes <= '2025-08-01'
             AND reactiva_12m = 1
            THEN 1 ELSE 0
        END)
        /
        NULLIF(SUM(CASE
            WHEN fecha_mes <= '2025-08-01'
            THEN 1 ELSE 0
        END),0)
    AS DECIMAL(10,2)) AS pct_reactiva_12m

FROM Futuro

GROUP BY meses_inactivo
ORDER BY meses_inactivo;

---Hoja Reporteria


--##########################
--HAsta aca Reporte 2
--##########################


WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        año_mes,
        venta_total,
        compro,

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

Rachas AS (
    SELECT
        codigo_cliente,
        periodo,
        venta_total,
        compro,
        compras_acumuladas,

        DATEFROMPARTS(
            CAST(LEFT(periodo,4) AS INT),
            CAST(RIGHT(periodo,2) AS INT),
            1
        ) AS fecha_mes,

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
                DATEFROMPARTS(
                    CAST(LEFT(periodo,4) AS INT),
                    CAST(RIGHT(periodo,2) AS INT),
                    1
                )
            )
        END AS meses_inactivo

    FROM Base
),

Eventos AS (
    SELECT
        r.codigo_cliente,
        r.periodo,
        r.fecha_mes,
        r.meses_inactivo,

        /*
        ¿Llegó a 6 meses consecutivos de inactividad
        sin comprar entre medio?
        */
        CASE
            WHEN r.meses_inactivo < 6
             AND EXISTS (
                    SELECT 1
                    FROM Rachas f
                    WHERE f.codigo_cliente = r.codigo_cliente
                      AND f.meses_inactivo = 6
                      AND f.fecha_mes > r.fecha_mes
                      AND f.fecha_mes <= DATEADD(
                            MONTH,
                            6 - r.meses_inactivo,
                            r.fecha_mes
                          )
                )
            THEN 1 ELSE 0
        END AS llega_6m,

        /*
        ¿Llegó a 9 meses?
        */
        CASE
            WHEN r.meses_inactivo < 9
             AND EXISTS (
                    SELECT 1
                    FROM Rachas f
                    WHERE f.codigo_cliente = r.codigo_cliente
                      AND f.meses_inactivo = 9
                      AND f.fecha_mes > r.fecha_mes
                      AND f.fecha_mes <= DATEADD(
                            MONTH,
                            9 - r.meses_inactivo,
                            r.fecha_mes
                          )
                )
            THEN 1 ELSE 0
        END AS llega_9m,

        /*
        ¿Llegó a 12 meses?
        */
        CASE
            WHEN r.meses_inactivo < 12
             AND EXISTS (
                    SELECT 1
                    FROM Rachas f
                    WHERE f.codigo_cliente = r.codigo_cliente
                      AND f.meses_inactivo = 12
                      AND f.fecha_mes > r.fecha_mes
                      AND f.fecha_mes <= DATEADD(
                            MONTH,
                            12 - r.meses_inactivo,
                            r.fecha_mes
                          )
                )
            THEN 1 ELSE 0
        END AS llega_12m

    FROM Rachas r
    WHERE r.meses_inactivo BETWEEN 1 AND 11
)

SELECT
    meses_inactivo,

    /* Riesgo de llegar a 6 meses */
    SUM(
        CASE
            WHEN meses_inactivo < 6
             AND fecha_mes <= DATEADD(
                    MONTH,
                    -(6 - meses_inactivo),
                    CAST('2026-08-01' AS DATE)
                 )
            THEN 1 ELSE 0
        END
    ) AS casos_evaluables_6m,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN meses_inactivo < 6
                 AND fecha_mes <= DATEADD(
                        MONTH,
                        -(6 - meses_inactivo),
                        CAST('2026-08-01' AS DATE)
                     )
                 AND llega_6m = 1
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN meses_inactivo < 6
                     AND fecha_mes <= DATEADD(
                            MONTH,
                            -(6 - meses_inactivo),
                            CAST('2026-08-01' AS DATE)
                         )
                    THEN 1 ELSE 0
                END
            ), 0
        )
    AS DECIMAL(10,2)) AS pct_llega_6m,


    /* Riesgo de llegar a 9 meses */
    SUM(
        CASE
            WHEN meses_inactivo < 9
             AND fecha_mes <= DATEADD(
                    MONTH,
                    -(9 - meses_inactivo),
                    CAST('2026-08-01' AS DATE)
                 )
            THEN 1 ELSE 0
        END
    ) AS casos_evaluables_9m,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN meses_inactivo < 9
                 AND fecha_mes <= DATEADD(
                        MONTH,
                        -(9 - meses_inactivo),
                        CAST('2026-08-01' AS DATE)
                     )
                 AND llega_9m = 1
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN meses_inactivo < 9
                     AND fecha_mes <= DATEADD(
                            MONTH,
                            -(9 - meses_inactivo),
                            CAST('2026-08-01' AS DATE)
                         )
                    THEN 1 ELSE 0
                END
            ), 0
        )
    AS DECIMAL(10,2)) AS pct_llega_9m,


    /* Riesgo de llegar a 12 meses */
    SUM(
        CASE
            WHEN meses_inactivo < 12
             AND fecha_mes <= DATEADD(
                    MONTH,
                    -(12 - meses_inactivo),
                    CAST('2026-08-01' AS DATE)
                 )
            THEN 1 ELSE 0
        END
    ) AS casos_evaluables_12m,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN meses_inactivo < 12
                 AND fecha_mes <= DATEADD(
                        MONTH,
                        -(12 - meses_inactivo),
                        CAST('2026-08-01' AS DATE)
                     )
                 AND llega_12m = 1
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN meses_inactivo < 12
                     AND fecha_mes <= DATEADD(
                            MONTH,
                            -(12 - meses_inactivo),
                            CAST('2026-08-01' AS DATE)
                         )
                    THEN 1 ELSE 0
                END
            ), 0
        )
    AS DECIMAL(10,2)) AS pct_llega_12m

FROM Eventos

GROUP BY meses_inactivo
ORDER BY meses_inactivo;


--##########################
--HAsta aca Reporte 2
--##########################


--A partir de aca Reporte 3


WITH Base AS (
    SELECT
        codigo_cliente,
        periodo,
        año_mes,
        venta_total,
        compro,

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

Potencial AS (
    SELECT
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,

        SUM(f.venta_total) AS venta_6m_previa,

        SUM(
            CASE
                WHEN f.compro = 1 THEN 1
                ELSE 0
            END
        ) AS meses_con_compra_6m,

        CAST(
            SUM(f.venta_total) / 6.0
            AS DECIMAL(18,2)
        ) AS promedio_mensual_calendario_6m,

        CAST(
            SUM(f.venta_total)
            /
            NULLIF(
                SUM(
                    CASE
                        WHEN f.compro = 1 THEN 1
                        ELSE 0
                    END
                ),
                0
            )
            AS DECIMAL(18,2)
        ) AS promedio_mes_activo_6m,

        SUM(f.facturas) AS facturas_6m,

        SUM(f.unidades) AS unidades_6m,

        MAX(f.venta_total) AS venta_maxima_mes_6m

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
        a.ultima_compra_periodo
),

Segmentacion AS (
    SELECT
        *,
        
        NTILE(5) OVER (
            ORDER BY promedio_mensual_calendario_6m
        ) AS quintil_potencial

    FROM Potencial
)

SELECT
    quintil_potencial,

    COUNT(*) AS farmacias,

    CAST(
        MIN(promedio_mensual_calendario_6m)
        AS DECIMAL(18,2)
    ) AS potencial_minimo,

    CAST(
        AVG(promedio_mensual_calendario_6m)
        AS DECIMAL(18,2)
    ) AS potencial_promedio,

    CAST(
        MAX(promedio_mensual_calendario_6m)
        AS DECIMAL(18,2)
    ) AS potencial_maximo,

    CAST(
        SUM(promedio_mensual_calendario_6m)
        AS DECIMAL(18,2)
    ) AS potencial_total_mensual

FROM Segmentacion

GROUP BY
    quintil_potencial

ORDER BY
    quintil_potencial DESC;


---#### Hasta aca potencial Reporete 3





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

/* =========================================================
   POTENCIAL RECIENTE
   6 meses calendario terminando en la última compra
   ========================================================= */

PotencialReciente AS (
    SELECT
        a.codigo_cliente,
        a.meses_inactivo,
        a.ultima_compra_periodo,
        a.fecha_ultima_compra,

        COUNT(*) AS meses_observados,

        SUM(f.venta_total) AS venta_6m_previa,

        SUM(
            CASE WHEN f.compro = 1 THEN 1 ELSE 0 END
        ) AS meses_con_compra_6m,

        CAST(
            SUM(f.venta_total) / 6.0
            AS DECIMAL(18,2)
        ) AS potencial_reciente_6m,

        CAST(
            SUM(f.venta_total) /
            NULLIF(
                SUM(CASE WHEN f.compro = 1 THEN 1 ELSE 0 END),
                0
            )
            AS DECIMAL(18,2)
        ) AS promedio_mes_activo_6m

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

/* =========================================================
   HISTORIA COMPLETA
   Creamos ventanas móviles de 6 meses
   ========================================================= */

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

/* =========================================================
   Dejamos solamente ventanas completas y consecutivas
   ========================================================= */

VentanasValidas AS (
    SELECT
        codigo_cliente,
        periodo AS periodo_fin,
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

/* =========================================================
   Ranking de las mejores ventanas históricas
   ========================================================= */

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
        potencial_historico_6m AS mejor_potencial_historico_6m,
        fecha_inicio_ventana,
        fecha_fin_ventana

    FROM RankingHistorico

    WHERE ranking = 1
)

/* =========================================================
   RESULTADO FINAL
   ========================================================= */

SELECT top 30
    p.codigo_cliente,

    p.meses_inactivo,

    p.ultima_compra_periodo,

    p.potencial_reciente_6m,

    h.mejor_potencial_historico_6m,

    CONVERT(
        CHAR(6),
        h.fecha_inicio_ventana,
        112
    ) AS inicio_mejor_periodo,

    CONVERT(
        CHAR(6),
        h.fecha_fin_ventana,
        112
    ) AS fin_mejor_periodo,

    CAST(
        p.potencial_reciente_6m
        / NULLIF(h.mejor_potencial_historico_6m, 0)
        * 100.0
        AS DECIMAL(10,2)
    ) AS pct_reciente_vs_maximo,

    CAST(
        (
            1 -
            p.potencial_reciente_6m
            / NULLIF(h.mejor_potencial_historico_6m, 0)
        )
        * 100.0
        AS DECIMAL(10,2)
    ) AS pct_deterioro_vs_maximo,

    p.meses_con_compra_6m,

    p.promedio_mes_activo_6m

FROM PotencialReciente p

LEFT JOIN MejorHistorico h
    ON h.codigo_cliente = p.codigo_cliente

ORDER BY
    h.mejor_potencial_historico_6m DESC;