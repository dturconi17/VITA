export function queryRetencion(desde: string, hasta: string) {

    const regex = /^\d{4}-\d{2}$/;

    if (!regex.test(desde) || !regex.test(hasta)) {
        throw new Error("Período inválido.");
    }

    if (desde > hasta) {
        throw new Error("El período Desde no puede ser mayor que Hasta.");
    }

    const query = `

SELECT
    SUM(CASE WHEN [${hasta}] = 1 THEN 1 ELSE 0 END) AS clientes_mes,
    SUM(CASE WHEN [${desde}] = 1 AND [${hasta}] = 1 THEN 1 ELSE 0 END) AS activos,
    SUM(CASE WHEN [${desde}] = 1 AND [${hasta}] = 0 THEN 1 ELSE 0 END) AS perdidos,
    SUM(CASE WHEN [${desde}] = 0 AND [${hasta}] = 1 THEN 1 ELSE 0 END) AS recuperados,
    SUM(CASE WHEN [${desde}] = 1 THEN 1 ELSE 0 END) AS clientes_mes_desde

FROM sales.crm_dinamica;

`;

    console.log("=================================");
    console.log("SQL EJECUTADO:");
    console.log(query);
    console.log("=================================");

    return query;
}