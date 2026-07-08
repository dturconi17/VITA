export const queryFiltros = `SELECT DISTINCT
       UPPER(LTRIM(RTRIM(nombre_grupo))) AS nombre_grupo
FROM sales.v_venta_total
WHERE estado_factura='V'
ORDER BY nombre_grupo
  `;