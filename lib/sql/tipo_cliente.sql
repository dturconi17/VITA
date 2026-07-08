DROP TABLE IF EXISTS sales.crm_segmentacion_aux;


CREATE TABLE sales.crm_segmentacion_aux
(
    codigo_cliente varchar(20),
    periodo CHAR(7),
    consumo INT,
    actual VARCHAR(30),
    historia VARCHAR(30),
    realidad VARCHAR(30),
    tipo_cliente VARCHAR(30),
    accion VARCHAR(30)
);

INSERT INTO sales.crm_segmentacion_aux
(
    codigo_cliente,
    periodo,
    consumo,
    actual,
    historia,
    realidad,
    tipo_cliente,
    accion
)
SELECT
    d.codigo_cliente,
    '2023-01' AS periodo,
    d.[2023-01] AS consumo,
    m.actual,
    m.historia,
    m.realidad,
    m.tipo_cliente,
    m.accion
FROM sales.crm_dinamica d
INNER JOIN sales.crm_matriz_clientes m
ON
m.mes_5 = d.[2022-08]
AND m.mes_4 = d.[2022-09]
AND m.mes_3 = d.[2022-10]
AND m.mes_2 = d.[2022-11]
AND m.mes_1 = d.[2022-12]
AND m.mes_0 = d.[2023-01];


select * from sales.crm_segmentacion_aux

truncate table sales.crm_segmentacion_aux



DECLARE @SQL NVARCHAR(MAX);


;WITH Periodos AS
(
    SELECT 
        DATEFROMPARTS(2023,1,1) periodo

    UNION ALL

    SELECT 
        DATEADD(MONTH,1,periodo)

    FROM Periodos

    WHERE periodo < '2026-06-01'
)


SELECT 
    @SQL =
    STRING_AGG(
        CAST(

'
INSERT INTO sales.crm_segmentacion_aux
(
    codigo_cliente,
    periodo,
    consumo,
    actual,
    historia,
    realidad,
    tipo_cliente,
    accion
)

SELECT

    d.codigo_cliente,

    ''' + CONVERT(char(7),periodo,120) + ''',

    d.[' + CONVERT(char(7),periodo,120) + '],

    m.actual,
    m.historia,
    m.realidad,
    m.tipo_cliente,
    m.accion


FROM sales.crm_dinamica d


INNER JOIN sales.crm_matriz_clientes m

ON

m.mes_5 = d.[' + CONVERT(char(7),DATEADD(MONTH,-5,periodo),120) + ']

AND m.mes_4 = d.[' + CONVERT(char(7),DATEADD(MONTH,-4,periodo),120) + ']

AND m.mes_3 = d.[' + CONVERT(char(7),DATEADD(MONTH,-3,periodo),120) + ']

AND m.mes_2 = d.[' + CONVERT(char(7),DATEADD(MONTH,-2,periodo),120) + ']

AND m.mes_1 = d.[' + CONVERT(char(7),DATEADD(MONTH,-1,periodo),120) + ']

AND m.mes_0 = d.[' + CONVERT(char(7),periodo,120) + ']

' AS NVARCHAR(MAX))
,
CHAR(10)
)

FROM Periodos

OPTION (MAXRECURSION 100);


PRINT LEFT(@SQL,4000);


EXEC sp_executesql @SQL;


SELECT 
    periodo,
    COUNT(*) cantidad_clientes
FROM sales.crm_segmentacion_aux
GROUP BY periodo
ORDER BY periodo;

SELECT COUNT(*) registros_sin_matriz
FROM sales.crm_segmentacion_aux
WHERE actual IS NULL
   OR historia IS NULL
   OR realidad IS NULL
   OR tipo_cliente IS NULL
   OR accion IS NULL;

select *
FROM sales.crm_segmentacion_aux   where codigo_cliente = '50352'



DECLARE @Columnas NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);


SELECT 
    @Columnas =
    STRING_AGG(
        CAST(
        '
MAX(CASE WHEN periodo = ''' + periodo + ''' THEN consumo END) AS [' + periodo + '_consumo],

MAX(CASE WHEN periodo = ''' + periodo + ''' THEN actual END) AS [' + periodo + '_actual],

MAX(CASE WHEN periodo = ''' + periodo + ''' THEN historia END) AS [' + periodo + '_historia],

MAX(CASE WHEN periodo = ''' + periodo + ''' THEN realidad END) AS [' + periodo + '_realidad],

MAX(CASE WHEN periodo = ''' + periodo + ''' THEN tipo_cliente END) AS [' + periodo + '_tipo_cliente],

MAX(CASE WHEN periodo = ''' + periodo + ''' THEN accion END) AS [' + periodo + '_accion]
'
        AS NVARCHAR(MAX)),
        ','
    )

FROM
(
    SELECT DISTINCT periodo
    FROM sales.crm_segmentacion_aux
) p;



SET @SQL = '

SELECT

codigo_cliente,

' + @Columnas + '

INTO sales.crm_dinamica_segmentada

FROM sales.crm_segmentacion_aux

GROUP BY

codigo_cliente
';



PRINT LEFT(@SQL,4000);


EXEC sp_executesql @SQL;



select * FROM sales.crm_dinamica_segmentada