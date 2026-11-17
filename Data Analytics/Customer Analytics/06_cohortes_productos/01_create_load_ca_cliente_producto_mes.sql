DROP TABLE IF EXISTS sales.ca_cliente_producto_mes;

;WITH detalle_producto_mes AS
(
    SELECT
        LTRIM(RTRIM(v.codigo_cliente)) AS codigo_cliente,

        DATEFROMPARTS(
            YEAR(v.fecha_factura),
            MONTH(v.fecha_factura),
            1
        ) AS fecha_mes,

        LTRIM(RTRIM(v.codigo_producto)) AS codigo_producto,

        MAX(LTRIM(RTRIM(v.nombre_producto))) AS nombre_producto,
        MAX(LTRIM(RTRIM(v.linea))) AS linea,
        MAX(LTRIM(RTRIM(v.sector))) AS sector,
        MAX(LTRIM(RTRIM(v.categoria))) AS categoria,
        MAX(LTRIM(RTRIM(v.nombre_pack))) AS nombre_pack,

        SUM(COALESCE(v.cantidad, 0)) AS cantidad_producto,
        SUM(COALESCE(v.total_venta, 0)) AS venta_producto,
        COUNT(
    DISTINCT CONCAT(
        LTRIM(RTRIM(v.sucursal)),
        '-',
        CAST(v.no_factura AS varchar(30))
    )
) AS facturas_producto

    FROM sales.v_venta_total v

    WHERE
        v.estado_factura = 'V'
        AND v.nombre_vendedor NOT IN (
            'ANA MARIA AGUILAR SUAREZ'
        )
        AND v.fecha_factura < '2026-04-01'
        AND v.fecha_factura IS NOT NULL
        AND v.codigo_cliente IS NOT NULL
        AND v.codigo_producto IS NOT NULL
        AND LTRIM(RTRIM(v.codigo_cliente)) <> ''
        AND LTRIM(RTRIM(v.codigo_producto)) <> ''

    GROUP BY
        LTRIM(RTRIM(v.codigo_cliente)),

        DATEFROMPARTS(
            YEAR(v.fecha_factura),
            MONTH(v.fecha_factura),
            1
        ),

        LTRIM(RTRIM(v.codigo_producto))
),

base AS
(
    SELECT
        d.codigo_cliente,
        c.fecha_inicio_cliente,
        d.fecha_mes AS periodo,

        DATEDIFF(
            MONTH,
            c.fecha_inicio_cliente,
            d.fecha_mes
        ) AS mes_vida,

        c.mes_conversion,
        c.orden_cohorte,
        c.cohorte,
        c.ventana_12m_completa,

        CASE
            WHEN c.orden_cohorte = 0
                THEN 'Adopción inmediata'

            WHEN c.orden_cohorte BETWEEN 1 AND 2
                THEN 'Adopción temprana'

            WHEN c.orden_cohorte BETWEEN 3 AND 5
                THEN 'Adopción media'

            WHEN c.orden_cohorte BETWEEN 6 AND 11
                THEN 'Adopción tardía'

            WHEN c.orden_cohorte = 99
                THEN 'Nunca Ético'

            ELSE 'Sin clasificar'
        END AS ventana_adopcion,

        d.codigo_producto,
        d.nombre_producto,
        d.linea,
        d.sector,
        d.categoria,
        d.nombre_pack,

        d.cantidad_producto,
        d.venta_producto,
        d.facturas_producto,

        CAST(
            CASE
                WHEN UPPER(LTRIM(RTRIM(d.linea))) = 'ETICO'
                    THEN 1
                ELSE 0
            END
            AS tinyint
        ) AS es_producto_etico,

        CAST(1 AS tinyint) AS compro_producto

    FROM detalle_producto_mes d

    INNER JOIN sales.ca_cliente_cohortes c
        ON d.codigo_cliente =
           LTRIM(RTRIM(c.codigo_cliente))

    WHERE
        c.ventana_12m_completa = 1

        AND DATEDIFF(
            MONTH,
            c.fecha_inicio_cliente,
            d.fecha_mes
        ) BETWEEN 0 AND 11
)

SELECT
    *
INTO sales.ca_cliente_producto_mes
FROM base;

CREATE CLUSTERED INDEX IX_ca_cliente_producto_mes
ON sales.ca_cliente_producto_mes
(
    codigo_cliente,
    periodo,
    codigo_producto
);

CREATE NONCLUSTERED INDEX IX_ca_cliente_producto_ventana
ON sales.ca_cliente_producto_mes
(
    ventana_adopcion,
    codigo_producto
)
INCLUDE
(
    mes_vida,
    linea,
    venta_producto,
    cantidad_producto,
    facturas_producto
);

CREATE NONCLUSTERED INDEX IX_ca_cliente_producto_cohorte
ON sales.ca_cliente_producto_mes
(
    orden_cohorte,
    mes_vida
)
INCLUDE
(
    codigo_cliente,
    codigo_producto,
    linea,
    venta_producto
);


---------------------------
-- Confirmacion -----------
---------------------------
SELECT TOP 20 *
FROM sales.ca_cliente_producto_mes
ORDER BY
    codigo_cliente,
    periodo,
    codigo_producto;

SELECT
    MIN(mes_vida) AS mes_minimo,
    MAX(mes_vida) AS mes_maximo,
    COUNT(*) AS filas,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    COUNT(DISTINCT codigo_producto) AS productos
FROM sales.ca_cliente_producto_mes;

SELECT
    cohorte,
    orden_cohorte,
    ventana_adopcion,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    COUNT(DISTINCT codigo_producto) AS productos,
    SUM(venta_producto) AS venta_12m
FROM sales.ca_cliente_producto_mes
GROUP BY
    cohorte,
    orden_cohorte,
    ventana_adopcion
ORDER BY
    orden_cohorte;

SELECT
    linea,
    es_producto_etico,
    COUNT(*) AS filas,
    COUNT(DISTINCT codigo_producto) AS productos,
    SUM(venta_producto) AS venta
FROM sales.ca_cliente_producto_mes
GROUP BY
    linea,
    es_producto_etico
ORDER BY
    linea;    


----Clientes por Ventana
SELECT
    ventana_adopcion,
    COUNT(DISTINCT codigo_cliente) AS clientes
FROM sales.ca_cliente_producto_mes
GROUP BY ventana_adopcion
ORDER BY
    CASE ventana_adopcion
        WHEN 'Adopción inmediata' THEN 1
        WHEN 'Adopción temprana' THEN 2
        WHEN 'Adopción media' THEN 3
        WHEN 'Adopción tardía' THEN 4
        WHEN 'Nunca Ético' THEN 5
    END;

SELECT
    COUNT(DISTINCT codigo_producto) AS productos,
    COUNT(DISTINCT linea) AS lineas,
    COUNT(DISTINCT sector) AS sectores,
    COUNT(DISTINCT categoria) AS categorias
FROM sales.ca_cliente_producto_mes;

SELECT
    ventana_adopcion,
    linea,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    SUM(venta_producto) AS venta
FROM sales.ca_cliente_producto_mes
GROUP BY
    ventana_adopcion,
    linea
ORDER BY
    ventana_adopcion,
    venta DESC;



SELECT TOP 30
    codigo_producto,
    nombre_producto,
    linea,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    SUM(venta_producto) AS venta
FROM sales.ca_cliente_producto_mes
GROUP BY
    codigo_producto,
    nombre_producto,
    linea
ORDER BY
    clientes DESC;
