DROP TABLE IF EXISTS sales.ca_producto_lift_horizonte;

SELECT
    c.horizonte,

    c.codigo_producto,
    c.nombre_producto,
    c.linea,
    c.sector,
    c.categoria,

    c.clientes_universo AS clientes_convertidos,
    c.clientes_producto AS convertidos_producto,
    c.penetracion_pct AS penetracion_convertidos_pct,

    n.clientes_universo AS clientes_nunca,
    COALESCE(n.clientes_producto, 0) AS nunca_producto,
    COALESCE(n.penetracion_pct, 0) AS penetracion_nunca_pct,

    CAST(
        c.penetracion_pct
        - COALESCE(n.penetracion_pct, 0)
        AS decimal(12,4)
    ) AS diferencia_penetracion_pp,

    CAST(
        c.penetracion_pct
        / NULLIF(n.penetracion_pct, 0)
        AS decimal(12,4)
    ) AS lift_vs_nunca,

    c.venta_producto AS venta_convertidos,
    COALESCE(n.venta_producto, 0) AS venta_nunca

INTO sales.ca_producto_lift_horizonte

FROM sales.ca_producto_penetracion_horizonte c

LEFT JOIN sales.ca_producto_penetracion_horizonte n
    ON c.horizonte = n.horizonte
    AND c.codigo_producto = n.codigo_producto
    AND n.grupo_comparacion = 'Nunca Etico'

WHERE
    c.grupo_comparacion = 'Convertido';

CREATE CLUSTERED INDEX IX_ca_producto_lift_horizonte
ON sales.ca_producto_lift_horizonte
(
    horizonte,
    codigo_producto
);    