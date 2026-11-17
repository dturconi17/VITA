TRUNCATE TABLE sales.fact_invoice;

INSERT INTO sales.fact_invoice
(
    id_sale_invoice,
    codigo_cliente,
    fecha_factura,
    periodo,
    año_mes,
    canal,
    vendedor,
    ciudad,
    sucursal,
    venta_total,
    descuento_total,
    unidades_total,
    cantidad_lineas,
    productos_distintos,
    lineas_distintas,
    tiene_etica,
    venta_etica,
    unidades_etica,
    productos_etica,
    porcentaje_etica,
    productos_no_etica,
    venta_no_etica
)


SELECT
    id_sale_invoice,
    MAX(codigo_cliente),
    CAST(MAX(fecha_hora_factura) AS DATE),
    MAX(
    CONCAT(
    YEAR(fecha_hora_factura),
    RIGHT('0'+CAST(MONTH(fecha_hora_factura) AS VARCHAR(2)),2)
    )),
    MAX([Año-mes]),
    MAX(nombre_grupo),
    MAX(nombre_vendedor),
    MAX(ciudad_cliente),
    MAX(sucursal_cliente),
    cast(SUM(total_venta) AS DECIMAL(19,4)),
    cast(SUM(descuento) AS DECIMAL(19,4)),
    SUM(cantidad),
    COUNT(*),
    COUNT(DISTINCT codigo_producto),
    COUNT(DISTINCT linea),
    MAX
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
            THEN 1
            ELSE 0
        END
    ),
    cast(SUM
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
            THEN total_venta
            ELSE 0
        END
    ) AS DECIMAL(19,4)),
    SUM
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
            THEN cantidad
            ELSE 0
        END
    ),
    COUNT
    (
        DISTINCT
        CASE
            WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
            THEN codigo_producto
        END
    ),
    CAST
    (
        SUM
        (
            CASE
                WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
                THEN total_venta
                ELSE 0
            END
        )
        /
        NULLIF(SUM(total_venta),0)
        AS DECIMAL(19,4)
    ),
    COUNT(DISTINCT codigo_producto)
        -
        COUNT
        (
        DISTINCT
        CASE
        WHEN linea='ETICO'
        THEN codigo_producto
        END
        ),
CAST
(
    SUM
    (
        CAST(ISNULL(total_venta, 0) AS DECIMAL(19,4))
    )
    -
    SUM
    (
        CASE
            WHEN UPPER
                 (
                     LTRIM
                     (
                         RTRIM
                         (
                             ISNULL(linea, '')
                         )
                     )
                 ) = 'ETICO'
            THEN CAST(ISNULL(total_venta, 0) AS DECIMAL(19,4))
            ELSE CAST(0 AS DECIMAL(19,4))
        END
    )
    AS DECIMAL(19,4)
) AS venta_no_etica
FROM sales.v_venta_total
where estado_factura='V'
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
and fecha_factura < '2026-04-01'
GROUP BY
id_sale_invoice;