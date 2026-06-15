export const queryTicketPromedioKPIs = `
SELECT
    SUM(v.total_venta)                     AS facturacion,
    COUNT(DISTINCT v.nombre_cliente)       AS clientes,
    COUNT(*)                               AS transacciones,
    AVG(v.total_venta)                     AS ticket_promedio
FROM sales.v_venta_total v
WHERE v.estado_factura = 'V'
{{FILTROS}}
`;