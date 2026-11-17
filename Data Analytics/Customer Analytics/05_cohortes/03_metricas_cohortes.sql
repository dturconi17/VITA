/* ============================================================
   03_resumen_cohortes.sql

   Objetivo:
   Generar una tabla resumen con una fila por cohorte,
   utilizando únicamente clientes con 12 meses completos.

   Fuente:
   sales.ca_cliente_metricas_12m

   Salida:
   sales.ca_cohortes_resumen
   ============================================================ */

DROP TABLE IF EXISTS sales.ca_cohortes_resumen;

;WITH base_valida AS (

    SELECT
        codigo_cliente,
        cohorte,
        orden_cohorte,

        venta_total_12m,
        venta_etica_12m,
        venta_otras_12m,
        participacion_etica_pct,

        ticket_promedio_12m,

        facturas_12m,
        unidades_12m,

        meses_con_compra_12m,
        recurrencia_12m,

        max_productos_distintos_mes,
        max_lineas_distintas_mes

    FROM sales.ca_cliente_metricas_12m

    WHERE ventana_12m_completa = 1
),

/* ============================================================
   PROMEDIOS Y CANTIDAD DE CLIENTES
   ============================================================ */

promedios AS (

    SELECT
        cohorte,
        orden_cohorte,

        COUNT(*) AS clientes,

        AVG(
            CAST(venta_total_12m AS decimal(18, 2))
        ) AS venta_promedio,

        AVG(
            CAST(venta_etica_12m AS decimal(18, 2))
        ) AS venta_etica_promedio,

        AVG(
            CAST(venta_otras_12m AS decimal(18, 2))
        ) AS venta_otras_promedio,

        AVG(
            CAST(participacion_etica_pct AS decimal(18, 2))
        ) AS participacion_etica_promedio,

        AVG(
            CAST(ticket_promedio_12m AS decimal(18, 2))
        ) AS ticket_promedio,

        AVG(
            CAST(facturas_12m AS decimal(18, 2))
        ) AS facturas_promedio,

        AVG(
            CAST(unidades_12m AS decimal(18, 2))
        ) AS unidades_promedio,

        AVG(
            CAST(meses_con_compra_12m AS decimal(18, 2))
        ) AS meses_activos_promedio,

        AVG(
            CAST(recurrencia_12m AS decimal(18, 4))
        ) AS recurrencia_promedio,

        AVG(
            CAST(max_productos_distintos_mes AS decimal(18, 2))
        ) AS productos_promedio,

        AVG(
            CAST(max_lineas_distintas_mes AS decimal(18, 2))
        ) AS lineas_promedio

    FROM base_valida

    GROUP BY
        cohorte,
        orden_cohorte
),

/* ============================================================
   MEDIANA DE VENTAS POR COHORTE

   PERCENTILE_CONT es una función de ventana, por lo que se
   calcula en un nivel separado del GROUP BY.
   ============================================================ */

medianas_base AS (

    SELECT
        cohorte,
        orden_cohorte,

        PERCENTILE_CONT(0.5)
            WITHIN GROUP (
                ORDER BY venta_total_12m
            )
            OVER (
                PARTITION BY cohorte, orden_cohorte
            ) AS mediana_venta

    FROM base_valida
),

medianas AS (

    SELECT
        cohorte,
        orden_cohorte,
        MAX(mediana_venta) AS mediana_venta

    FROM medianas_base

    GROUP BY
        cohorte,
        orden_cohorte
)

/* ============================================================
   MATERIALIZACIÓN
   ============================================================ */

SELECT
    p.cohorte,
    p.orden_cohorte,
    p.clientes,

    p.venta_promedio,

    CAST(
        m.mediana_venta
        AS decimal(18, 2)
    ) AS mediana_venta,

    p.venta_etica_promedio,
    p.venta_otras_promedio,
    p.participacion_etica_promedio,

    p.ticket_promedio,
    p.facturas_promedio,
    p.unidades_promedio,

    p.meses_activos_promedio,
    p.recurrencia_promedio,

    p.productos_promedio,
    p.lineas_promedio

INTO sales.ca_cohortes_resumen

FROM promedios p

INNER JOIN medianas m
    ON p.cohorte = m.cohorte
   AND p.orden_cohorte = m.orden_cohorte;

CREATE UNIQUE CLUSTERED INDEX UX_ca_cohortes_resumen_orden
ON sales.ca_cohortes_resumen (orden_cohorte);
