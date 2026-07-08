export const queryPeriodos = `

SELECT
    name AS periodo
FROM sys.columns
WHERE object_id = OBJECT_ID('sales.crm_dinamica')
AND name LIKE '[1-2][0-9][0-9][0-9]-[0-1][0-9]'
ORDER BY name;

`;