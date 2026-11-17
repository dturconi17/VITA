WITH Patrones AS (
    SELECT
        codigo_cliente,

        MAX(CASE WHEN periodo = '202608' AND compro = 1 THEN 1 ELSE 0 END) AS [202608],
        MAX(CASE WHEN periodo = '202607' AND compro = 1 THEN 1 ELSE 0 END) AS [202607],
        MAX(CASE WHEN periodo = '202606' AND compro = 1 THEN 1 ELSE 0 END) AS [202606],
        MAX(CASE WHEN periodo = '202605' AND compro = 1 THEN 1 ELSE 0 END) AS [202605],
        MAX(CASE WHEN periodo = '202604' AND compro = 1 THEN 1 ELSE 0 END) AS [202604],
        MAX(CASE WHEN periodo = '202603' AND compro = 1 THEN 1 ELSE 0 END) AS [202603],
        MAX(CASE WHEN periodo = '202602' AND compro = 1 THEN 1 ELSE 0 END) AS [202602],
        MAX(CASE WHEN periodo = '202601' AND compro = 1 THEN 1 ELSE 0 END) AS [202601],
        MAX(CASE WHEN periodo = '202512' AND compro = 1 THEN 1 ELSE 0 END) AS [202512],
        MAX(CASE WHEN periodo = '202511' AND compro = 1 THEN 1 ELSE 0 END) AS [202511],
        MAX(CASE WHEN periodo = '202510' AND compro = 1 THEN 1 ELSE 0 END) AS [202510],
        MAX(CASE WHEN periodo = '202509' AND compro = 1 THEN 1 ELSE 0 END) AS [202509]

    FROM sales.fact_cliente_mes

    WHERE periodo BETWEEN '202509' AND '202608'

    GROUP BY codigo_cliente
)

SELECT
    [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603],
    [202602],
    [202601],
    [202512],
    [202511],
    [202510],
    [202509],

    COUNT(*) AS cantidad_clientes

FROM Patrones

GROUP BY
    [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603],
    [202602],
    [202601],
    [202512],
    [202511],
    [202510],
    [202509]

ORDER BY
      [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603],
    [202602],
    [202601],
    [202512],
    [202511],
    [202510],
    [202509]

---6 Columnas

WITH Patrones AS (
    SELECT
        codigo_cliente,

        MAX(CASE WHEN periodo = '202608' AND compro = 1 THEN 1 ELSE 0 END) AS [202608],
        MAX(CASE WHEN periodo = '202607' AND compro = 1 THEN 1 ELSE 0 END) AS [202607],
        MAX(CASE WHEN periodo = '202606' AND compro = 1 THEN 1 ELSE 0 END) AS [202606],
        MAX(CASE WHEN periodo = '202605' AND compro = 1 THEN 1 ELSE 0 END) AS [202605],
        MAX(CASE WHEN periodo = '202604' AND compro = 1 THEN 1 ELSE 0 END) AS [202604],
        MAX(CASE WHEN periodo = '202603' AND compro = 1 THEN 1 ELSE 0 END) AS [202603]
        
    FROM sales.fact_cliente_mes

    WHERE periodo BETWEEN '202509' AND '202608'

    GROUP BY codigo_cliente
)

SELECT
    [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603],
    COUNT(*) AS cantidad_clientes

FROM Patrones

GROUP BY
    [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603]

ORDER BY
      [202608],
    [202607],
    [202606],
    [202605],
    [202604],
    [202603]