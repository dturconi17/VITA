DROP TABLE IF EXISTS sales.ca_producto_activador_score;

;WITH base AS
(
    SELECT
        codigo_producto,
        MAX(nombre_producto) AS nombre_producto,
        MAX(linea) AS linea,
        MAX(sector) AS sector,
        MAX(categoria) AS categoria,

        SUM(convertidos_producto) AS farmacias_convertidas_producto,
        SUM(clientes_convertidos) AS exposiciones_convertidos,

        SUM(
            penetracion_convertidos_pct
            * clientes_convertidos
        )
        / NULLIF(SUM(clientes_convertidos), 0)
            AS penetracion_convertidos_ponderada,

        SUM(
            penetracion_nunca_pct
            * clientes_convertidos
        )
        / NULLIF(SUM(clientes_convertidos), 0)
            AS penetracion_nunca_ponderada,

        SUM(
            diferencia_penetracion_pp
            * clientes_convertidos
        )
        / NULLIF(SUM(clientes_convertidos), 0)
            AS diferencia_ponderada_pp,

        SUM(
            CASE
                WHEN diferencia_penetracion_pp >= 5
                 AND convertidos_producto >= 10
                THEN 1
                ELSE 0
            END
        ) AS horizontes_diferenciales,

        SUM(
            CASE
                WHEN horizonte BETWEEN 1 AND 5
                 AND diferencia_penetracion_pp >= 5
                 AND convertidos_producto >= 10
                THEN 1
                ELSE 0
            END
        ) AS horizontes_tempranos_diferenciales,

        MAX(
            CASE
                WHEN horizonte = 1
                THEN diferencia_penetracion_pp
            END
        ) AS diferencia_mes_1_pp,

        MAX(
            CASE
                WHEN horizonte = 2
                THEN diferencia_penetracion_pp
            END
        ) AS diferencia_mes_2_pp

    FROM sales.ca_producto_lift_horizonte

    GROUP BY
        codigo_producto
),

score AS
(
    SELECT
        *,

        CAST(
              diferencia_ponderada_pp

            + 2.0 * horizontes_tempranos_diferenciales

            + 0.5 * horizontes_diferenciales

            + CASE
                WHEN farmacias_convertidas_producto >= 300 THEN 10
                WHEN farmacias_convertidas_producto >= 150 THEN 7
                WHEN farmacias_convertidas_producto >= 75  THEN 4
                WHEN farmacias_convertidas_producto >= 30  THEN 2
                ELSE 0
              END

            AS decimal(12,4)
        ) AS score_activador

    FROM base
)

SELECT
    *
INTO sales.ca_producto_activador_score
FROM score;

---------Ranking

SELECT TOP 30
    codigo_producto,
    nombre_producto,
    linea,
    sector,

    farmacias_convertidas_producto,

    CAST(
        penetracion_convertidos_ponderada
        AS decimal(12,2)
    ) AS penetracion_convertidos_pct,

    CAST(
        penetracion_nunca_ponderada
        AS decimal(12,2)
    ) AS penetracion_nunca_pct,

    CAST(
        diferencia_ponderada_pp
        AS decimal(12,2)
    ) AS diferencia_ponderada_pp,

    horizontes_diferenciales,
    horizontes_tempranos_diferenciales,

    diferencia_mes_1_pp,
    diferencia_mes_2_pp,

    score_activador

FROM sales.ca_producto_activador_score

WHERE
    farmacias_convertidas_producto >= 30
    AND diferencia_ponderada_pp > 0

ORDER BY
    score_activador DESC;