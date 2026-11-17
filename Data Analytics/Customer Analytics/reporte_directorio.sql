WITH Farmacias AS
(
    SELECT
        c.codigo_cliente,
        c.fecha_primer_compra,

        DATEDIFF(
            MONTH,
            DATEFROMPARTS(
                YEAR(c.fecha_primer_compra),
                MONTH(c.fecha_primer_compra),
                1
            ),
            DATEFROMPARTS(
                YEAR(GETDATE()),
                MONTH(GETDATE()),
                1
            )
        ) AS antiguedad_meses

    FROM sales.ca_cliente c

    WHERE
        UPPER(LTRIM(RTRIM(c.canal))) = 'FARMACIAS'
        AND c.fecha_primer_compra IS NOT NULL
),

UltimaCompra AS
(
    SELECT
        LTRIM(RTRIM(v.codigo_cliente)) AS codigo_cliente,
        MAX(v.fecha_factura) AS fecha_ultima_compra

    FROM sales.v_venta_total v

    WHERE
        v.estado_factura = 'V'
        AND ISNULL(v.nombre_vendedor,'') <> 'ANA MARIA AGUILAR SUAREZ'

    GROUP BY
        LTRIM(RTRIM(v.codigo_cliente))
),

Base AS
(
    SELECT
        f.codigo_cliente,
        f.fecha_primer_compra,
        u.fecha_ultima_compra,
        f.antiguedad_meses,

        DATEDIFF(
            DAY,
            u.fecha_ultima_compra,
            CAST(GETDATE() AS DATE)
        ) AS dias_desde_ultima_compra,

        /* SEGMENTO DE ANTIGÜEDAD */

        CASE
            WHEN f.antiguedad_meses <= 3
                THEN '01. 0-3 meses'

            WHEN f.antiguedad_meses <= 6
                THEN '02. 4-6 meses'

            WHEN f.antiguedad_meses <= 12
                THEN '03. 7-12 meses'

            WHEN f.antiguedad_meses <= 24
                THEN '04. 13-24 meses'

            ELSE '05. Más de 24 meses'
        END AS segmento_antiguedad,

        /* SEGMENTO DE RECENCIA */

        CASE
            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 30
                THEN '01. Consumieron últimos 30 días'

            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 90
                THEN '02. Consumieron de 31 a 90 días'

            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 120
                THEN '03. Consumieron de 91 a 120 días'

            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 150
                THEN '04. Consumieron de 121 a 150 días'

            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 180
                THEN '05. Consumieron de 151 a 180 días'

            WHEN DATEDIFF(
                    DAY,
                    u.fecha_ultima_compra,
                    CAST(GETDATE() AS DATE)
                 ) <= 365
                THEN '06. Consumieron de 181 a 365 días'

            ELSE '07. Consumieron hace más de 365 días'
        END AS segmento_recencia

    FROM Farmacias f

    LEFT JOIN UltimaCompra u
        ON u.codigo_cliente = f.codigo_cliente
)

SELECT
    segmento_antiguedad,
    segmento_recencia,

    COUNT(*) AS cantidad_farmacias

FROM Base

GROUP BY
    segmento_antiguedad,
    segmento_recencia

ORDER BY
    segmento_antiguedad,
    segmento_recencia;