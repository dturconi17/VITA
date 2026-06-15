export const queryTicketPromedioSegmentos = `
SELECT
    v.nombre_cliente,
    SUM(v.total_venta) AS facturacion, 
    count(distinct(id_sale_invoice)) as transacciones
FROM sales.v_venta_total v
WHERE v.estado_factura='V'
{{FILTROS}}
GROUP BY
v.nombre_cliente
ORDER BY
facturacion DESC
`;