SELECT DISTINCT
    codigo_cliente,
    CONVERT(char(7), fecha_factura, 120) AS periodo
INTO sales.crm_aux_dinamica
FROM sales.v_venta_total
WHERE estado_factura = 'V'
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
group by CODIGO_CLIENTE,CONVERT(char(7), fecha_factura, 120);
DECLARE @Columnas NVARCHAR(MAX);

SELECT @Columnas =
STRING_AGG(
    CONCAT(
        'MAX(CASE WHEN periodo = ''',
        periodo,
        ''' THEN 1 ELSE 0 END) AS [',
        periodo,
        ']'
    ),
    ','
) WITHIN GROUP (ORDER BY periodo)
FROM (
    SELECT DISTINCT periodo
    FROM sales.crm_aux_dinamica
) AS p;

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = '
IF OBJECT_ID(''sales.crm_dinamica'', ''U'') IS NOT NULL
    DROP TABLE sales.crm_dinamica;

SELECT
    codigo_cliente,
        ' + @Columnas + '
        into sales.crm_dinamica
FROM sales.crm_aux_dinamica
GROUP BY
    codigo_cliente
    
';

EXEC sp_executesql @SQL;

drop table sales.crm_aux_dinamica