
export const queryPeriodos = `
    SELECT DISTINCT
        periodo
    FROM sales.maestro_cliente_mes
    ORDER BY periodo DESC;
`;
