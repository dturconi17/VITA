DROP TABLE IF EXISTS sales.ca_cliente_pre_conversion;

SELECT
    codigo_cliente,
    orden_cohorte,
    mes_conversion,
    ventana_adopcion,

    mes_vida,

    codigo_producto,
    nombre_producto,

    linea,
    sector,
    categoria,
    nombre_pack,

    cantidad_producto,
    venta_producto,
    facturas_producto

INTO sales.ca_cliente_pre_conversion

FROM sales.ca_cliente_producto_mes

WHERE
    orden_cohorte BETWEEN 1 AND 11

    AND mes_vida < mes_conversion

    AND es_producto_etico = 0;


SELECT
    codigo_producto,
    nombre_producto, linea,
    COUNT(DISTINCT codigo_cliente)
        AS clientes
FROM sales.ca_cliente_pre_conversion
GROUP BY
    codigo_producto,
    nombre_producto, linea
ORDER BY
    clientes DESC;