TRUNCATE TABLE sales.dim_tiempo;


WITH calendario AS
(
    SELECT 
        CAST('2023-01-01' AS DATE) AS fecha
    UNION ALL
    SELECT 
        DATEADD(DAY,1,fecha)
    FROM calendario
    WHERE fecha < '2030-12-31'
)
INSERT INTO sales.dim_tiempo
(
    fecha,
    periodo,
    año,
    mes,
    nombre_mes,
    año_mes,
    año_mes_num,
    trimestre,
    semana_año,
    dia,
    dia_semana,
    nombre_dia,
    inicio_mes,
    fin_mes,
    es_fin_mes
)
SELECT
fecha,
CONCAT(
    YEAR(fecha),
    RIGHT('0'+CAST(MONTH(fecha) AS VARCHAR(2)),2)
),
YEAR(fecha),
MONTH(fecha),
DATENAME(MONTH,fecha),
FORMAT(fecha,'yyyy-MM'),
YEAR(fecha)*100 + MONTH(fecha),
DATEPART(QUARTER,fecha),
DATEPART(WEEK,fecha),
DAY(fecha),
DATEPART(WEEKDAY,fecha),
DATENAME(WEEKDAY,fecha),
DATEFROMPARTS(
YEAR(fecha),
MONTH(fecha),
1),
EOMONTH(fecha),
CASE 
WHEN fecha = EOMONTH(fecha)
THEN 1
ELSE 0
END
FROM calendario
ORDER BY fecha
OPTION (MAXRECURSION 0);

/*==============================================================
VALIDACION
==============================================================*/
SELECT 
fecha,
COUNT(*)
FROM sales.dim_tiempo
GROUP BY fecha
HAVING COUNT(*)>1;

