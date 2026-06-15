  export const queryFiltros = `
  SELECT 
    (SELECT DISTINCT nombre_cliente FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY nombre_cliente FOR JSON PATH) AS clientes,
    (SELECT DISTINCT nombre_vendedor FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY nombre_vendedor FOR JSON PATH) AS vendedores,
    (SELECT DISTINCT ciudad_cliente FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY ciudad_cliente FOR JSON PATH) AS ciudades,
    (SELECT DISTINCT YEAR(fecha_factura) AS anio FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY anio DESC FOR JSON PATH) AS anios
  ;
  `;