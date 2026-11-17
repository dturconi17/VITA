DROP TABLE IF EXISTS sales.ca_universo_horizonte;

;WITH convertidos AS
(
    SELECT
        mes_conversion AS horizonte,
        CAST('Convertido' AS varchar(20)) AS grupo_comparacion,
        COUNT(DISTINCT codigo_cliente) AS clientes_universo

    FROM sales.ca_cliente_cohortes

    WHERE
        ventana_12m_completa = 1
        AND orden_cohorte BETWEEN 1 AND 11

    GROUP BY
        mes_conversion
),

nunca AS
(
    SELECT
        h.horizonte,
        CAST('Nunca Etico' AS varchar(20)) AS grupo_comparacion,
        COUNT(DISTINCT c.codigo_cliente) AS clientes_universo

    FROM
    (
        SELECT 1 AS horizonte
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
    ) h

    CROSS JOIN sales.ca_cliente_cohortes c

    WHERE
        c.ventana_12m_completa = 1
        AND c.orden_cohorte = 99

    GROUP BY
        h.horizonte
)

SELECT *
INTO sales.ca_universo_horizonte
FROM
(
    SELECT * FROM convertidos

    UNION ALL

    SELECT * FROM nunca
) x;

SELECT *
FROM sales.ca_universo_horizonte
ORDER BY
    horizonte,
    grupo_comparacion;