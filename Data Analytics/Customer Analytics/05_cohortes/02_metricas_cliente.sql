/* ============================================================
   02_metricas_12m.sql

   Objetivo:
   Calcular las métricas comerciales de cada cliente durante
   sus primeros 12 meses de vida comercial.

   Fuente:
   sales.fact_cliente_mes
   sales.ca_cliente_cohortes

   Salida:
   sales.ca_cliente_metricas_12m
   ============================================================ */

DROP TABLE IF EXISTS sales.ca_cliente_metricas_12m;

;WITH base_12m AS (

    SELECT
        c.codigo_cliente,
        c.fecha_inicio_cliente,
        c.mes_conversion,
        c.orden_cohorte,
        c.cohorte,
        c.ventana_12m_completa,

        DATEFROMPARTS(
            f.año,
            f.mes,
            1
        ) AS fecha_mes,

        DATEDIFF(
            MONTH,
            c.fecha_inicio_cliente,
            DATEFROMPARTS(
                f.año,
                f.mes,
                1
            )
        ) AS mes_vida,

        COALESCE(f.venta_total, 0) AS venta_total,
        COALESCE(f.venta_etica, 0) AS venta_etica,
        COALESCE(f.venta_otras, 0) AS venta_otras,

        COALESCE(f.descuento_total, 0) AS descuento_total,
        COALESCE(f.unidades, 0) AS unidades,

        COALESCE(f.facturas, 0) AS facturas,
        COALESCE(f.facturas_etica, 0) AS facturas_etica,
        COALESCE(f.facturas_no_etica, 0) AS facturas_no_etica,

        COALESCE(f.ticket_maximo, 0) AS ticket_maximo,
        COALESCE(f.ticket_minimo, 0) AS ticket_minimo,

        COALESCE(f.productos_distintos, 0) AS productos_distintos,
        COALESCE(f.productos_etica, 0) AS productos_etica,
        COALESCE(f.productos_no_etica, 0) AS productos_no_etica,

        COALESCE(f.lineas_distintas, 0) AS lineas_distintas,

        COALESCE(f.compro, 0) AS compro,
        COALESCE(f.compro_etica, 0) AS compro_etica,
        COALESCE(f.compro_no_etica, 0) AS compro_no_etica

    FROM sales.ca_cliente_cohortes c

    INNER JOIN sales.fact_cliente_mes f
        ON c.codigo_cliente = f.codigo_cliente

    WHERE DATEDIFF(
            MONTH,
            c.fecha_inicio_cliente,
            DATEFROMPARTS(
                f.año,
                f.mes,
                1
            )
          ) BETWEEN 0 AND 11
),

metricas_cliente AS (

    SELECT
        codigo_cliente,
        fecha_inicio_cliente,
        mes_conversion,
        orden_cohorte,
        cohorte,
        ventana_12m_completa,

        SUM(venta_total) AS venta_total_12m,
        SUM(venta_etica) AS venta_etica_12m,
        SUM(venta_otras) AS venta_otras_12m,

        SUM(descuento_total) AS descuento_total_12m,
        SUM(unidades) AS unidades_12m,

        SUM(facturas) AS facturas_12m,
        SUM(facturas_etica) AS facturas_etica_12m,
        SUM(facturas_no_etica) AS facturas_no_etica_12m,

        COUNT(
            DISTINCT CASE
                WHEN compro = 1
                THEN mes_vida
            END
        ) AS meses_con_compra_12m,

        COUNT(
            DISTINCT CASE
                WHEN compro_etica = 1
                THEN mes_vida
            END
        ) AS meses_con_compra_etica_12m,

        COUNT(
            DISTINCT CASE
                WHEN compro_no_etica = 1
                THEN mes_vida
            END
        ) AS meses_con_compra_no_etica_12m,

        MAX(ticket_maximo) AS ticket_maximo_12m,

        MIN(
            CASE
                WHEN ticket_minimo > 0
                THEN ticket_minimo
            END
        ) AS ticket_minimo_12m,

        MAX(productos_distintos) AS max_productos_distintos_mes,

        MAX(productos_etica) AS max_productos_etica_mes,

        MAX(productos_no_etica) AS max_productos_no_etica_mes,

        MAX(lineas_distintas) AS max_lineas_distintas_mes

    FROM base_12m

    GROUP BY
        codigo_cliente,
        fecha_inicio_cliente,
        mes_conversion,
        orden_cohorte,
        cohorte,
        ventana_12m_completa
)

SELECT
    codigo_cliente,
    fecha_inicio_cliente,
    mes_conversion,
    orden_cohorte,
    cohorte,
    ventana_12m_completa,

    venta_total_12m,
    venta_etica_12m,
    venta_otras_12m,

    CAST(
        100.0 * venta_etica_12m
        / NULLIF(venta_total_12m, 0)
        AS decimal(10, 2)
    ) AS participacion_etica_pct,

    descuento_total_12m,
    unidades_12m,

    facturas_12m,
    facturas_etica_12m,
    facturas_no_etica_12m,

    CAST(
        venta_total_12m
        / NULLIF(facturas_12m, 0)
        AS decimal(18, 2)
    ) AS ticket_promedio_12m,

    ticket_maximo_12m,
    ticket_minimo_12m,

    meses_con_compra_12m,
    meses_con_compra_etica_12m,
    meses_con_compra_no_etica_12m,

    CAST(
        meses_con_compra_12m / 12.0
        AS decimal(10, 4)
    ) AS recurrencia_12m,

    CAST(
        venta_total_12m
        / NULLIF(meses_con_compra_12m, 0)
        AS decimal(18, 2)
    ) AS venta_promedio_mes_activo,

    CAST(
        facturas_12m
        / NULLIF(meses_con_compra_12m, 0)
        AS decimal(18, 2)
    ) AS facturas_promedio_mes_activo,

    max_productos_distintos_mes,
    max_productos_etica_mes,
    max_productos_no_etica_mes,
    max_lineas_distintas_mes

INTO sales.ca_cliente_metricas_12m

FROM metricas_cliente;