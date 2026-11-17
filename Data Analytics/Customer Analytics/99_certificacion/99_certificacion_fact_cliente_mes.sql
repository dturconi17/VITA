/*==============================================================
  CERTIFICACION FACT_CLIENTE_MES
  Proyecto: Customer Analytics - Línea Ética
==============================================================*/

PRINT '========================================';
PRINT '1. REGISTROS FACT_CLIENTE_MES';
PRINT '========================================';

SELECT
    COUNT(*) AS registros
FROM sales.fact_cliente_mes;



PRINT '========================================';
PRINT '2. CLIENTES';
PRINT '========================================';

SELECT
    COUNT(DISTINCT codigo_cliente) AS clientes_fact_cliente_mes
FROM sales.fact_cliente_mes;

SELECT
    COUNT(DISTINCT codigo_cliente) AS clientes_dim_cliente
FROM sales.dim_cliente;



PRINT '========================================';
PRINT '3. PERIODOS';
PRINT '========================================';

SELECT DISTINCT
    periodo
FROM sales.fact_cliente_mes
ORDER BY periodo;



PRINT '========================================';
PRINT '4. VENTA TOTAL';
PRINT '========================================';

SELECT
    SUM(venta_total) AS venta_fact_cliente_mes
FROM sales.fact_cliente_mes;

SELECT
    SUM(venta_total) AS venta_fact_invoice
FROM sales.fact_invoice;



PRINT '========================================';
PRINT '5. VENTA ETICA';
PRINT '========================================';

SELECT
    SUM(venta_etica) AS venta_etica_fact_cliente_mes
FROM sales.fact_cliente_mes;

SELECT
    SUM(venta_etica) AS venta_etica_fact_invoice
FROM sales.fact_invoice;



PRINT '========================================';
PRINT '6. FACTURAS';
PRINT '========================================';

SELECT
    SUM(facturas) AS facturas_fact_cliente_mes
FROM sales.fact_cliente_mes;

SELECT
    COUNT(*) AS facturas_fact_invoice
FROM sales.fact_invoice;



PRINT '========================================';
PRINT '7. FACTURAS ETICAS';
PRINT '========================================';

SELECT
    SUM(facturas_etica) AS facturas_etica_fact_cliente_mes
FROM sales.fact_cliente_mes;

SELECT
    SUM(CASE WHEN tiene_etica = 1 THEN 1 ELSE 0 END) AS facturas_etica_fact_invoice
FROM sales.fact_invoice;



PRINT '========================================';
PRINT '8. CLIENTES-MES CON COMPRA';
PRINT '========================================';

SELECT
    COUNT(*) AS cliente_mes_fact_cliente_mes
FROM sales.fact_cliente_mes
WHERE compro = 1;

SELECT
    COUNT(*) AS cliente_mes_fact_invoice
FROM
(
    SELECT
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        ) AS periodo
    FROM sales.fact_invoice
    GROUP BY
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        )
) t;



PRINT '========================================';
PRINT '9. CLIENTES-MES CON ETICA';
PRINT '========================================';

SELECT
    COUNT(*) AS cliente_mes_etica_fact_cliente_mes
FROM sales.fact_cliente_mes
WHERE compro_etica = 1;

SELECT
    COUNT(*) AS cliente_mes_etica_fact_invoice
FROM
(
    SELECT
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        ) periodo
    FROM sales.fact_invoice
    WHERE tiene_etica = 1
    GROUP BY
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        )
) t;



PRINT '========================================';
PRINT '10. PRODUCTOS';
PRINT '========================================';

SELECT
    SUM(productos_distintos) productos,
    SUM(productos_etica) productos_etica
FROM sales.fact_cliente_mes;



PRINT '========================================';
PRINT '11. PRODUCTOS ETICA > PRODUCTOS';
PRINT '========================================';

SELECT *
FROM sales.fact_cliente_mes
WHERE productos_etica > productos_distintos;



PRINT '========================================';
PRINT '12. VENTA ETICA > VENTA TOTAL';
PRINT '========================================';

SELECT *
FROM sales.fact_cliente_mes
WHERE venta_etica > venta_total;



PRINT '========================================';
PRINT '13. TICKET';
PRINT '========================================';

SELECT TOP (100)
    codigo_cliente,
    periodo,
    venta_total,
    facturas,
    ticket_promedio,
    CASE
        WHEN facturas = 0 THEN NULL
        ELSE venta_total / facturas
    END AS ticket_calculado
FROM sales.fact_cliente_mes
WHERE facturas > 0;


PRINT '========================================';
PRINT '14. CLIENTES SIN COMPRA';
PRINT '========================================';

SELECT
    COUNT(*) clientes_sin_compra
FROM sales.fact_cliente_mes
WHERE compro = 0;



PRINT '========================================';
PRINT '15. DUPLICADOS';
PRINT '========================================';

SELECT
    codigo_cliente,
    periodo,
    COUNT(*) cantidad
FROM sales.fact_cliente_mes
GROUP BY
    codigo_cliente,
    periodo
HAVING COUNT(*) > 1;



PRINT '========================================';
PRINT '16. CERTIFICACION FINAL';
PRINT '========================================';

WITH FacturasMes AS
(
    SELECT
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        ) periodo,
        SUM(venta_total) venta_total
    FROM sales.fact_invoice
    GROUP BY
        codigo_cliente,
        CONCAT(
            YEAR(fecha_factura),
            RIGHT('0'+CAST(MONTH(fecha_factura) AS varchar(2)),2)
        )
)
SELECT
    COUNT(*) registros,
    SUM(venta_total) venta
FROM FacturasMes;
SELECT
    COUNT(*) registros,
    SUM(venta_total) venta
FROM sales.fact_cliente_mes
WHERE compro = 1;

PRINT '========================================';
PRINT 'CERTIFICACION IDC';
PRINT '========================================';



SELECT
    MIN(idc) AS idc_minimo,
    MAX(idc) AS idc_maximo,
    AVG(idc) AS idc_promedio
FROM sales.ca_cliente_idc;

SELECT *
FROM sales.ca_cliente_idc
WHERE idc IS NULL
   OR score_productos IS NULL
   OR score_frecuencia IS NULL
   OR score_venta_mensual IS NULL
   OR score_meses_activos IS NULL;


SELECT TOP 50
    codigo_cliente,
    cliente_etica,
    idc,
    segmento_idc,

    score_productos,
    score_frecuencia,
    score_venta_mensual,
    score_meses_activos,

    productos_historicos,
    frecuencia_historica,
    venta_mensual_historica,
    meses_activos_historicos

FROM sales.ca_cliente_idc

ORDER BY idc DESC;

PRINT '========================================';
PRINT 'FIN CERTIFICACION';
PRINT '========================================';


SELECT
    COUNT(*) AS filas_con_diferencia
FROM sales.fact_cliente_mes
WHERE ABS
(
    venta_total - venta_etica - venta_otras
) > 0.01;

SELECT
    COUNT(*) AS filas_con_diferencia
FROM sales.fact_cliente_mes
WHERE productos_distintos
      <> productos_etica + productos_no_etica;


SELECT TOP 100
    codigo_cliente,
    periodo,
    productos_distintos,
    productos_etica,
    productos_no_etica,
    productos_etica + productos_no_etica,
    venta_total, venta_etica, venta_otras
FROM sales.fact_cliente_mes
WHERE (
    venta_total - venta_etica - venta_otras
) > 0.01
ORDER BY periodo DESC;      


SELECT
    COUNT(*) AS facturas_con_diferencia,
    SUM
    (
        ABS
        (
            ISNULL(venta_total, 0)
            - ISNULL(venta_etica, 0)
            - ISNULL(venta_no_etica, 0)
        )
    ) AS diferencia_absoluta_total,
    MIN
    (
        ISNULL(venta_total, 0)
        - ISNULL(venta_etica, 0)
        - ISNULL(venta_no_etica, 0)
    ) AS diferencia_minima,

    MAX
    (
        ISNULL(venta_total, 0)
        - ISNULL(venta_etica, 0)
        - ISNULL(venta_no_etica, 0)
    ) AS diferencia_maxima
FROM sales.fact_invoice
WHERE ABS
(
    ISNULL(venta_total, 0)
    - ISNULL(venta_etica, 0)
    - ISNULL(venta_no_etica, 0)
) > 0.01
AND fecha_factura < '2026-04-01';


SELECT TOP 100
    id_sale_invoice,
    codigo_cliente,
    fecha_factura,

    venta_total,
    venta_etica,
    venta_no_etica,

    venta_etica + venta_no_etica
        AS venta_reconstruida,

    venta_total
    - venta_etica
    - venta_no_etica
        AS diferencia

FROM sales.fact_invoice

WHERE ABS
(
    ISNULL(venta_total, 0)
    - ISNULL(venta_etica, 0)
    - ISNULL(venta_no_etica, 0)
) > 0.01

AND fecha_factura < '2026-04-01'

ORDER BY ABS
(
    ISNULL(venta_total, 0)
    - ISNULL(venta_etica, 0)
    - ISNULL(venta_no_etica, 0)
) DESC;


SELECT
    COUNT(*) AS clientes_con_diferencia
FROM sales.ca_cliente
WHERE productos_historicos
      <>
      productos_etica_historicos
      +
      productos_no_etica_historicos;

SELECT
    COUNT(*) AS clientes_con_diferencia
FROM sales.ca_cliente
WHERE productos_12m
      <>
      productos_etica_12m
      +
      productos_no_etica_12m;      


SELECT TOP 100
    codigo_cliente,

    productos_historicos,
    productos_etica_historicos,
    productos_no_etica_historicos,

    productos_etica_historicos
    + productos_no_etica_historicos
        AS productos_reconstruidos

FROM sales.ca_cliente

WHERE productos_historicos
      <>
      productos_etica_historicos
      +
      productos_no_etica_historicos

ORDER BY codigo_cliente;

SELECT
    cliente_etica,
    COUNT(*) AS clientes,
    AVG
    (
        CAST
        (
            productos_historicos
            AS DECIMAL(19,4)
        )
    ) AS productos_promedio_total,

    AVG
    (
        CAST
        (
            productos_etica_historicos
            AS DECIMAL(19,4)
        )
    ) AS productos_promedio_etica,

    AVG
    (
        CAST
        (
            productos_no_etica_historicos
            AS DECIMAL(19,4)
        )
    ) AS productos_promedio_no_etica

FROM sales.ca_cliente

GROUP BY
    cliente_etica

ORDER BY
    cliente_etica DESC;


select * from  sales.dim_cliente
select * from  sales.dim_producto
select * from  sales.fact_invoice
select * from  sales.fact_cliente_mes
select * from  sales.ca_cliente
select * from  sales.ca_cliente_idc


