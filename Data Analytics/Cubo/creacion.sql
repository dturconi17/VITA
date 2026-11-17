/* ============================================================
   EL CUBO - FACTURACION MENSUAL POR LINEA
   Universo: Canal FARMACIA
   Corte: Marzo 2026
   ============================================================ */

IF OBJECT_ID('sales.fact_cliente_linea_mes', 'U') IS NULL
BEGIN
    CREATE TABLE sales.fact_cliente_linea_mes (
        codigo_cliente VARCHAR(50) NOT NULL,
        periodo CHAR(6) NOT NULL,
        linea VARCHAR(100) NOT NULL,

        venta_total DECIMAL(19,4) NOT NULL DEFAULT 0,
        unidades BIGINT NOT NULL DEFAULT 0,
        facturas INT NOT NULL DEFAULT 0,
        productos_distintos INT NOT NULL DEFAULT 0,
        compro BIT NOT NULL DEFAULT 0,

        CONSTRAINT PK_fact_cliente_linea_mes
        PRIMARY KEY (codigo_cliente, periodo, linea)
    );
END;
GO

/* ============================================================
   CARGA DE INFORMACION
   ============================================================ */

TRUNCATE TABLE sales.fact_cliente_linea_mes;

WITH FacturasFarmacia AS (
    SELECT DISTINCT
        id_sale_invoice
    FROM sales.fact_invoice
    WHERE fecha_factura < '2026-04-01'
),
DetalleFarmacia AS (
    SELECT
        v.codigo_cliente,
        CONVERT(CHAR(6), v.fecha_factura, 112) AS periodo,

        COALESCE(
            NULLIF(UPPER(LTRIM(RTRIM(v.linea))), ''),
            'SIN LINEA'
        ) AS linea,

        v.id_sale_invoice,
        v.codigo_producto,
        v.cantidad,
        v.total_venta

    FROM sales.v_venta_total v

    INNER JOIN FacturasFarmacia f
        ON v.id_sale_invoice = f.id_sale_invoice

    INNER JOIN sales.dim_cliente c
        ON v.codigo_cliente = c.codigo_cliente

    WHERE v.estado_factura = 'V'
      AND v.nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
      AND v.fecha_factura < '2026-04-01'
)
INSERT INTO sales.fact_cliente_linea_mes (
    codigo_cliente,
    periodo,
    linea,
    venta_total,
    unidades,
    facturas,
    productos_distintos,
    compro
)
SELECT
    codigo_cliente,
    periodo,
    linea,

    SUM(COALESCE(total_venta, 0)) AS venta_total,

    SUM(COALESCE(cantidad, 0)) AS unidades,

    COUNT(DISTINCT id_sale_invoice) AS facturas,

    COUNT(DISTINCT codigo_producto) AS productos_distintos,

    CAST(
        CASE
            WHEN COUNT(DISTINCT id_sale_invoice) > 0
            THEN 1
            ELSE 0
        END AS BIT
    ) AS compro

FROM DetalleFarmacia

GROUP BY
    codigo_cliente,
    periodo,
    linea;
GO

SELECT
    periodo,
    SUM(venta_total) AS venta_lineas,
    COUNT(DISTINCT codigo_cliente) AS farmacias,
    COUNT(*) AS combinaciones_farmacia_linea
FROM sales.fact_cliente_linea_mes
GROUP BY periodo
ORDER BY periodo;

WITH Lineas AS (
    SELECT
        codigo_cliente,
        periodo,
        SUM(venta_total) AS venta_lineas
    FROM sales.fact_cliente_linea_mes
    GROUP BY codigo_cliente, periodo
)

DELETE l
FROM sales.fact_cliente_linea_mes l
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.dim_cliente c
    WHERE c.codigo_cliente = l.codigo_cliente
);


WITH Lineas AS (
    SELECT
        codigo_cliente,
        periodo,
        SUM(venta_total) AS venta_total
    FROM sales.fact_cliente_linea_mes
    GROUP BY codigo_cliente, periodo
)
SELECT
    m.periodo,

    SUM(m.venta_total) AS venta_fact_cliente_mes,

    SUM(COALESCE(l.venta_total, 0)) AS venta_por_lineas,

    SUM(m.venta_total)
        - SUM(COALESCE(l.venta_total, 0)) AS diferencia

FROM sales.fact_cliente_mes m

LEFT JOIN Lineas l
    ON m.codigo_cliente = l.codigo_cliente
   AND m.periodo = l.periodo

WHERE m.periodo <= '202603'

GROUP BY m.periodo
ORDER BY m.periodo;

WITH Lineas AS (
    SELECT
        codigo_cliente,
        periodo,
        SUM(venta_total) AS venta_total
    FROM sales.fact_cliente_linea_mes
    GROUP BY codigo_cliente, periodo
),
Comparacion AS (
    SELECT
        l.codigo_cliente,
        l.periodo,
        l.venta_total,

        CASE
            WHEN m.codigo_cliente IS NULL THEN 1
            ELSE 0
        END AS fuera_maestro

    FROM Lineas l

    LEFT JOIN sales.fact_cliente_mes m
        ON l.codigo_cliente = m.codigo_cliente
       AND l.periodo = m.periodo
)
SELECT
    periodo,

    COUNT(DISTINCT CASE
        WHEN fuera_maestro = 1
        THEN codigo_cliente
    END) AS farmacias_fuera_maestro,

    SUM(CASE
        WHEN fuera_maestro = 1
        THEN venta_total
        ELSE 0
    END) AS venta_fuera_maestro,

    COUNT(DISTINCT CASE
        WHEN fuera_maestro = 0
        THEN codigo_cliente
    END) AS farmacias_en_maestro,

    SUM(CASE
        WHEN fuera_maestro = 0
        THEN venta_total
        ELSE 0
    END) AS venta_en_maestro

FROM Comparacion

GROUP BY periodo
ORDER BY periodo;


WITH Lineas AS (
    SELECT
        codigo_cliente,
        periodo,
        SUM(venta_total) AS venta_total
    FROM sales.fact_cliente_linea_mes
    GROUP BY codigo_cliente, periodo
),
FueraMaestro AS (
    SELECT l.*
    FROM Lineas l
    WHERE NOT EXISTS (
        SELECT 1
        FROM sales.fact_cliente_mes m
        WHERE m.codigo_cliente = l.codigo_cliente
          AND m.periodo = l.periodo
    )
),
Resumen AS (
    SELECT
        codigo_cliente,
        COUNT(*) AS meses_fuera_maestro,
        MIN(periodo) AS primer_periodo_fuera,
        MAX(periodo) AS ultimo_periodo_fuera,
        SUM(venta_total) AS venta_total_fuera
    FROM FueraMaestro
    GROUP BY codigo_cliente
)
SELECT
    r.codigo_cliente,
    r.meses_fuera_maestro,
    r.primer_periodo_fuera,
    r.ultimo_periodo_fuera,
    r.venta_total_fuera,
    CASE
        WHEN d.codigo_cliente IS NULL THEN 'NO'
        ELSE 'SI'
    END AS existe_dim_cliente,
    d.mes_primer_compra
FROM Resumen r
LEFT JOIN sales.dim_cliente d
    ON r.codigo_cliente = d.codigo_cliente
ORDER BY r.venta_total_fuera DESC;