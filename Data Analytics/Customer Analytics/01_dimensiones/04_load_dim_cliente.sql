TRUNCATE TABLE sales.dim_cliente;

INSERT INTO sales.dim_cliente
(
    codigo_cliente,
    canal,
    ciudad,
    zona_barrio,
    sucursal,
    vendedor,
    fecha_primer_compra,
    fecha_ultima_compra,
    mes_primer_compra,
    mes_ultima_compra,
    antiguedad_meses,
    cantidad_facturas,
    venta_total_historica,
    unidades_historicas,
    productos_distintos,
    lineas_distintas,
    cliente_etica,
    fecha_primer_etica,
    fecha_ultima_etica,
    venta_etica_historica,
    porcentaje_etica,
    meses_comprando_etica,
    estado_cliente
)

SELECT
    v.codigo_cliente,
    MAX(v.nombre_grupo) AS canal,
    MAX(v.ciudad_cliente) AS ciudad,
    MAX(v.zona_barrio) AS zona_barrio,
    MAX(v.sucursal_cliente) AS sucursal,
    MAX(v.nombre_vendedor) AS vendedor,
    -- Primera compra
    MIN(CAST(v.fecha_hora_factura AS DATE)) 
        AS fecha_primer_compra,
    -- Última compra
    MAX(CAST(v.fecha_hora_factura AS DATE))
        AS fecha_ultima_compra,
    -- Mes primera compra
    FORMAT(
        MIN(v.fecha_hora_factura),
        'yyyy-MM'
    )
        AS mes_primer_compra,
    -- Mes última compra
    FORMAT(
        MAX(v.fecha_hora_factura),
        'yyyy-MM'
    )
        AS mes_ultima_compra,
    -- Antigüedad meses
    DATEDIFF
        (
        MONTH,
        MIN(CAST(v.fecha_hora_factura AS DATE)),
        CAST(GETDATE() AS DATE)
        )
        AS antiguedad_meses,
    -- Facturas
    COUNT(DISTINCT v.id_sale_invoice)
        AS cantidad_facturas,
    -- Venta total
    SUM(v.total_venta)
        AS venta_total_historica,
    -- Unidades
    SUM(v.cantidad)
        AS unidades_historicas,
    -- Productos distintos
    COUNT(DISTINCT v.codigo_producto)
        AS productos_distintos,
    -- Líneas distintas
    COUNT(DISTINCT v.linea)
        AS lineas_distintas,
    ------------------------------------------------
    -- LINEA ETICA
    ------------------------------------------------
    CASE 
        WHEN SUM
        (
            CASE
                WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
                THEN 1
                ELSE 0
            END
        ) > 0
        THEN 1
        ELSE 0
    END AS cliente_etica,
    -- Primera compra ética
    MIN
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
            THEN CAST(v.fecha_hora_factura AS DATE)
        END
    )
        AS fecha_primer_etica,
    -- Última compra ética
    MAX
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
            THEN CAST(v.fecha_hora_factura AS DATE)
        END
    )
        AS fecha_ultima_etica,
    -- Venta ética
    CAST
    (
    SUM
    (
        CASE
            WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
            THEN v.total_venta
            ELSE 0
        END
    ) AS DECIMAL(19,4)
    ) AS venta_etica_historica,
    -- Participación ética
    CAST
    (
        SUM
        (
            CASE
                WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
                THEN v.total_venta
                ELSE 0
            END
        )
        /
        NULLIF(SUM(v.total_venta),0)
        AS DECIMAL(19,4)
    )
        AS porcentaje_etica,
    -- Meses comprando ética
    COUNT
    (
        DISTINCT
        CASE
        WHEN UPPER(LTRIM(RTRIM(v.linea)))='ETICO'
        THEN v.[Año-mes]
        END
    )
        AS meses_comprando_etica,
    ------------------------------------------------
    -- ESTADO CLIENTE
    ------------------------------------------------
    CASE
        WHEN DATEDIFF
        (
            DAY,
            MAX(v.fecha_hora_factura),
            GETDATE()
        ) <= 90
        THEN 'ACTIVO'
        WHEN DATEDIFF
        (
            DAY,
            MAX(v.fecha_hora_factura),
            GETDATE()
        ) <=180
        THEN 'INACTIVO'
        WHEN DATEDIFF
        (
            DAY,
            MAX(v.fecha_hora_factura),
            GETDATE()
        ) <=365
        THEN 'DORMIDO'
        ELSE 'PERDIDO'
    END AS estado_cliente
FROM sales.v_venta_total v
WHERE estado_factura='V'
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
and fecha_factura < '2026-04-01'
GROUP BY
    v.codigo_cliente;

--ACTIVO <=90 días
--INACTIVO 91-180
--DORMIDO 181-365
--PERDIDO >365

/*==============================================================
VALIDACION
==============================================================*/

SELECT
COUNT(*) clientes
FROM sales.dim_cliente;


SELECT
SUM(venta_total_historica)
FROM sales.dim_cliente;

SELECT
COUNT(*)
FROM sales.dim_cliente
WHERE codigo_cliente IS NULL;

SELECT
COUNT(*)
FROM sales.dim_cliente
WHERE fecha_primer_compra>fecha_ultima_compra;