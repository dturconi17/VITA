/*==============================================================
PROYECTO: CUSTOMER ANALYTICS - LÍNEA ÉTICA
OBJETO: sales.fact_cliente_mes

OBJETIVO:
Carga mensual por cliente con métricas de venta,
facturación, diversidad e indicadores de adopción.

CORTE DE INFORMACIÓN:
Hasta el 31 de marzo de 2026.
==============================================================*/

TRUNCATE TABLE sales.fact_cliente_mes;
GO

WITH

/*==============================================================
1. MESES DISPONIBLES

Se limita el universo al período válido anterior al cambio
de códigos de clientes de abril de 2026.
==============================================================*/

Meses AS
(
    SELECT DISTINCT

        CONCAT
        (
            YEAR(fecha_factura),
            RIGHT
            (
                '0' + CAST(MONTH(fecha_factura) AS VARCHAR(2)),
                2
            )
        ) AS periodo,

        año_mes,

        YEAR(fecha_factura) AS año,

        MONTH(fecha_factura) AS mes

    FROM sales.fact_invoice

    WHERE fecha_factura < '2026-04-01'
),

/*==============================================================
2. MESES ORDENADOS
==============================================================*/

MesesOrdenados AS
(
    SELECT
        periodo,
        año_mes,
        año,
        mes,

        ROW_NUMBER() OVER
        (
            ORDER BY periodo
        ) AS meses_desde_inicio

    FROM Meses
),

/*==============================================================
3. UNIVERSO CLIENTE X MES

Genera una fila para cada cliente desde su primer mes
de compra hasta marzo de 2026.

Esto permite conservar también los meses sin compra.
==============================================================*/

BaseClienteMes AS
(
    SELECT
        c.codigo_cliente,
        m.periodo,
        m.año_mes,
        m.año,
        m.mes,
        m.meses_desde_inicio

    FROM sales.dim_cliente c

    CROSS JOIN MesesOrdenados m

    WHERE m.periodo >=
        CONCAT
        (
            LEFT(c.mes_primer_compra, 4),

            RIGHT
            (
                '0'
                +
                SUBSTRING(c.mes_primer_compra, 6, 2),
                2
            )
        )
),

/*==============================================================
4. MÉTRICAS ECONÓMICAS Y DE FACTURACIÓN MENSUALES

fact_invoice debe tener una fila por factura.

Una factura puede contener simultáneamente productos Ética
y productos No Ética. Por eso puede contarse en ambos grupos.
==============================================================*/

FacturasMes AS
(
    SELECT
        codigo_cliente,

        CONCAT
        (
            YEAR(fecha_factura),

            RIGHT
            (
                '0' + CAST(MONTH(fecha_factura) AS VARCHAR(2)),
                2
            )
        ) AS periodo,

        ------------------------------------------------------
        -- Venta
        ------------------------------------------------------

        SUM
        (
            ISNULL(venta_total, 0)
        ) AS venta_total,

        SUM
        (
            ISNULL(venta_etica, 0)
        ) AS venta_etica,

        SUM
        (
            ISNULL(venta_no_etica, 0)
        ) AS venta_otras,

        SUM
        (
            ISNULL(descuento_total, 0)
        ) AS descuento_total,

        SUM
        (
            ISNULL(unidades_total, 0)
        ) AS unidades,

        ------------------------------------------------------
        -- Facturación
        ------------------------------------------------------

        COUNT
        (
            DISTINCT id_sale_invoice
        ) AS facturas,

        COUNT
        (
            DISTINCT
            CASE
                WHEN ISNULL(venta_etica, 0) > 0
                THEN id_sale_invoice
            END
        ) AS facturas_etica,

        COUNT
        (
            DISTINCT
            CASE
                WHEN ISNULL(venta_no_etica, 0) > 0
                THEN id_sale_invoice
            END
        ) AS facturas_no_etica,

        ------------------------------------------------------
        -- Ticket total de la factura
        ------------------------------------------------------

        AVG
        (
            CAST
            (
                ISNULL(venta_total, 0)
                AS DECIMAL(19,4)
            )
        ) AS ticket_promedio,

        MAX
        (
            ISNULL(venta_total, 0)
        ) AS ticket_maximo,

        MIN
        (
            ISNULL(venta_total, 0)
        ) AS ticket_minimo

    FROM sales.fact_invoice

    WHERE fecha_factura < '2026-04-01'

    GROUP BY
        codigo_cliente,

        CONCAT
        (
            YEAR(fecha_factura),

            RIGHT
            (
                '0' + CAST(MONTH(fecha_factura) AS VARCHAR(2)),
                2
            )
        )
),

/*==============================================================
5. MÉTRICAS DE PRODUCTOS MENSUALES

Se calculan desde el detalle para obtener diversidad exacta.

productos_distintos:
Todos los SKU diferentes comprados durante el mes.

productos_etica:
SKU de Línea Ética.

productos_no_etica:
SKU de cualquier otra línea.

Los productos con línea NULL o vacía se consideran
No Ética para no perderlos del total.
==============================================================*/

ProductosMes AS
(
    SELECT
        v.codigo_cliente,

        CONCAT
        (
            YEAR(v.fecha_factura),

            RIGHT
            (
                '0' + CAST(MONTH(v.fecha_factura) AS VARCHAR(2)),
                2
            )
        ) AS periodo,

        ------------------------------------------------------
        -- Productos totales
        ------------------------------------------------------

        COUNT
        (
            DISTINCT v.codigo_producto
        ) AS productos_distintos,

        ------------------------------------------------------
        -- Productos Ética
        ------------------------------------------------------

        COUNT
        (
            DISTINCT
            CASE
                WHEN UPPER
                (
                    LTRIM
                    (
                        RTRIM
                        (
                            ISNULL(v.linea, '')
                        )
                    )
                ) = 'ETICO'
                THEN v.codigo_producto
            END
        ) AS productos_etica,

        ------------------------------------------------------
        -- Productos No Ética
        ------------------------------------------------------

        COUNT
        (
            DISTINCT
            CASE
                WHEN UPPER
                (
                    LTRIM
                    (
                        RTRIM
                        (
                            ISNULL(v.linea, '')
                        )
                    )
                ) <> 'ETICO'
                THEN v.codigo_producto
            END
        ) AS productos_no_etica,

        ------------------------------------------------------
        -- Líneas distintas
        ------------------------------------------------------

        COUNT
        (
            DISTINCT NULLIF
            (
                UPPER
                (
                    LTRIM
                    (
                        RTRIM
                        (
                            ISNULL(v.linea, '')
                        )
                    )
                ),
                ''
            )
        ) AS lineas_distintas

    FROM sales.v_venta_total v

    WHERE v.estado_factura = 'V'

      AND
         v.nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'


      AND v.fecha_factura < '2026-04-01'

    GROUP BY
        v.codigo_cliente,

        CONCAT
        (
            YEAR(v.fecha_factura),

            RIGHT
            (
                '0' + CAST(MONTH(v.fecha_factura) AS VARCHAR(2)),
                2
            )
        )
)

/*==============================================================
6. INSERT FINAL
==============================================================*/

INSERT INTO sales.fact_cliente_mes
(
    codigo_cliente,
    periodo,
    año_mes,
    año,
    mes,
    meses_desde_inicio,

    venta_total,
    venta_etica,
    venta_otras,
    descuento_total,
    unidades,

    facturas,
    facturas_etica,
    facturas_no_etica,

    ticket_promedio,
    ticket_maximo,
    ticket_minimo,

    productos_distintos,
    productos_etica,
    productos_no_etica,
    lineas_distintas,

    compro,
    compro_etica,
    compro_no_etica
)

SELECT
    b.codigo_cliente,
    b.periodo,
    b.año_mes,
    b.año,
    b.mes,
    b.meses_desde_inicio,

    ----------------------------------------------------------
    -- Ventas
    ----------------------------------------------------------

    ISNULL(f.venta_total, 0)
        AS venta_total,

    ISNULL(f.venta_etica, 0)
        AS venta_etica,

    ISNULL(f.venta_otras, 0)
        AS venta_otras,

    ISNULL(f.descuento_total, 0)
        AS descuento_total,

    ISNULL(f.unidades, 0)
        AS unidades,

    ----------------------------------------------------------
    -- Facturación
    ----------------------------------------------------------

    ISNULL(f.facturas, 0)
        AS facturas,

    ISNULL(f.facturas_etica, 0)
        AS facturas_etica,

    ISNULL(f.facturas_no_etica, 0)
        AS facturas_no_etica,

    ----------------------------------------------------------
    -- Ticket
    ----------------------------------------------------------

    ISNULL(f.ticket_promedio, 0)
        AS ticket_promedio,

    ISNULL(f.ticket_maximo, 0)
        AS ticket_maximo,

    ISNULL(f.ticket_minimo, 0)
        AS ticket_minimo,

    ----------------------------------------------------------
    -- Productos
    ----------------------------------------------------------

    ISNULL(p.productos_distintos, 0)
        AS productos_distintos,

    ISNULL(p.productos_etica, 0)
        AS productos_etica,

    ISNULL(p.productos_no_etica, 0)
        AS productos_no_etica,

    ISNULL(p.lineas_distintas, 0)
        AS lineas_distintas,

    ----------------------------------------------------------
    -- Indicadores
    ----------------------------------------------------------

    CASE
        WHEN ISNULL(f.facturas, 0) > 0
        THEN 1
        ELSE 0
    END AS compro,

    CASE
        WHEN ISNULL(f.facturas_etica, 0) > 0
        THEN 1
        ELSE 0
    END AS compro_etica,

    CASE
        WHEN ISNULL(f.facturas_no_etica, 0) > 0
        THEN 1
        ELSE 0
    END AS compro_no_etica

FROM BaseClienteMes b

LEFT JOIN FacturasMes f
    ON b.codigo_cliente = f.codigo_cliente
   AND b.periodo = f.periodo

LEFT JOIN ProductosMes p
    ON b.codigo_cliente = p.codigo_cliente
   AND b.periodo = p.periodo;
GO