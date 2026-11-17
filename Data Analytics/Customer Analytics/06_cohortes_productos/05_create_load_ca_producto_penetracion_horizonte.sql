DROP TABLE IF EXISTS sales.ca_producto_penetracion_horizonte;

;WITH producto AS
(
    SELECT
        horizonte,
        grupo_comparacion,

        codigo_producto,
        MAX(nombre_producto) AS nombre_producto,
        MAX(linea) AS linea,
        MAX(sector) AS sector,
        MAX(categoria) AS categoria,

        COUNT(DISTINCT codigo_cliente) AS clientes_producto,

        SUM(venta_producto) AS venta_producto,
        SUM(cantidad_producto) AS cantidad_producto,
        SUM(facturas_producto) AS facturas_producto

    FROM sales.ca_cliente_producto_horizonte

    GROUP BY
        horizonte,
        grupo_comparacion,
        codigo_producto
)

SELECT
    p.horizonte,
    p.grupo_comparacion,

    p.codigo_producto,
    p.nombre_producto,
    p.linea,
    p.sector,
    p.categoria,

    u.clientes_universo,
    p.clientes_producto,

    CAST(
        100.0 * p.clientes_producto
        / NULLIF(u.clientes_universo, 0)
        AS decimal(12,4)
    ) AS penetracion_pct,

    p.venta_producto,
    p.cantidad_producto,
    p.facturas_producto

INTO sales.ca_producto_penetracion_horizonte

FROM producto p

INNER JOIN sales.ca_universo_horizonte u
    ON p.horizonte = u.horizonte
    AND p.grupo_comparacion = u.grupo_comparacion;

CREATE CLUSTERED INDEX IX_ca_producto_penetracion_horizonte
ON sales.ca_producto_penetracion_horizonte
(
    horizonte,
    codigo_producto,
    grupo_comparacion
);