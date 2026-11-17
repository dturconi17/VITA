select count(distinct(codigo_cliente))
FROM sales.v_venta_total
where UPPER(LTRIM(RTRIM(nombre_grupo))) = 'FARMACIAS'
and estado_factura = 'V'
AND ISNULL(nombre_vendedor,'') <> 'ANA MARIA AGUILAR SUAREZ'


SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sales'
  AND TABLE_NAME = 'v_venta_total'
ORDER BY COLUMN_NAME;



SELECT
    nombre_grupo_venta,
    codigo_grupo_venta,
    nombre_grupo,
    nombre_subgrupo,
    sector,

    COUNT(DISTINCT codigo_cliente) AS clientes,
    COUNT(DISTINCT id_sale_invoice) AS facturas,
    SUM(COALESCE(total_venta, 0)) AS venta_total

FROM sales.v_venta_total

WHERE fecha_factura >= '2026-10-01'
  AND fecha_factura < '2026-11-01'
  AND estado_factura = 'V'
  AND (
      nombre_vendedor IS NULL
      OR nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
  )

GROUP BY
    nombre_grupo_venta,
    codigo_grupo_venta,
    nombre_grupo,
    nombre_subgrupo,
    sector

ORDER BY venta_total DESC;