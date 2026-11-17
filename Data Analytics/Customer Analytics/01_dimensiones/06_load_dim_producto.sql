TRUNCATE TABLE sales.dim_producto;
INSERT INTO sales.dim_producto
(
codigo_producto,
nombre_producto,
nombre_linea,
producto_etico,
fecha_primera_venta,
fecha_ultima_venta,
clientes_distintos,
facturas_distintas,
unidades_vendidas,
venta_total_historica,
ticket_promedio,
clientes_etica
)

SELECT
codigo_producto,
MAX(nombre_producto),
MAX(linea),
CASE
WHEN UPPER(LTRIM(RTRIM(MAX(linea))))='ETICO'
THEN 1
ELSE 0
END,
MIN(CAST(fecha_hora_factura AS DATE)),
MAX(CAST(fecha_hora_factura AS DATE)),
COUNT(DISTINCT codigo_cliente),
COUNT(DISTINCT id_sale_invoice),
SUM(cantidad),
SUM(total_venta),
CAST
(
SUM(total_venta)
/NULLIF(COUNT(DISTINCT id_sale_invoice),0)
AS DECIMAL(19,4)
),
COUNT
(
DISTINCT
CASE
WHEN UPPER(LTRIM(RTRIM(linea)))='ETICO'
THEN codigo_cliente
END
)
FROM sales.v_venta_total
where estado_factura='V'
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
and fecha_factura < '2026-04-01'
GROUP BY
codigo_producto;

DECLARE @clientes INT;

SELECT

@clientes=COUNT(*)

FROM sales.dim_cliente;
UPDATE p SET penetracion_clientes = CAST(p.clientes_distintos AS DECIMAL(18,6))/CAST
(
    (
        SELECT COUNT(*)
        FROM sales.dim_cliente
    )
AS DECIMAL(19,4))
FROM sales.dim_producto p;


WITH ranking AS
(
SELECT
codigo_producto,
ROW_NUMBER()
OVER
(
ORDER BY venta_total_historica DESC
)
ranking
FROM sales.dim_producto
)
UPDATE p
SET ranking_facturacion=r.ranking
FROM sales.dim_producto p
INNER JOIN ranking r
ON p.codigo_producto=r.codigo_producto;

/*=========================================
VALIDACION
=========================================*/

SELECT
COUNT(*) productos
FROM sales.dim_producto;

SELECT
SUM(venta_total_historica)
FROM sales.dim_producto;

SELECT
COUNT(*)
FROM sales.dim_producto
WHERE codigo_producto IS NULL;

SELECT
COUNT(*)
FROM sales.dim_producto
WHERE fecha_primera_venta>fecha_ultima_venta;