/* ============================================================
   01_base_cohortes.sql

   Objetivo:
   Clasificar a cada cliente por el momento de su primera
   compra Ética durante sus primeros 12 meses de vida comercial.

   Definición:
   mes_vida = 0  -> primer mes con compra observado
   mes_vida = 1  -> mes calendario siguiente
   ...
   mes_vida = 11 -> último mes incluido

   Importante:
   La tabla puede no contener filas para meses sin compra.
   Por eso la cobertura se valida con fechas calendario.
   ============================================================ */

DROP TABLE IF EXISTS sales.ca_cliente_cohortes;

;WITH base AS (

    SELECT
        codigo_cliente,

        DATEFROMPARTS(
            año,
            mes,
            1
        ) AS fecha_mes,

        meses_desde_inicio,

        COALESCE(venta_total, 0) AS venta_total,
        COALESCE(venta_etica, 0) AS venta_etica,
        COALESCE(venta_otras, 0) AS venta_otras,

        COALESCE(facturas, 0) AS facturas,
        COALESCE(facturas_etica, 0) AS facturas_etica,
        COALESCE(facturas_no_etica, 0) AS facturas_no_etica,

        COALESCE(ticket_promedio, 0) AS ticket_promedio,

        COALESCE(productos_distintos, 0) AS productos_distintos,
        COALESCE(productos_etica, 0) AS productos_etica,
        COALESCE(productos_no_etica, 0) AS productos_no_etica,

        COALESCE(lineas_distintas, 0) AS lineas_distintas,

        compro,
        compro_etica,
        compro_no_etica

    FROM sales.fact_cliente_mes

    WHERE codigo_cliente IS NOT NULL
      AND año IS NOT NULL
      AND mes IS NOT NULL
),

/* ============================================================
   PRIMER MES CON COMPRA DE CADA CLIENTE
   ============================================================ */

inicio_cliente AS (

    SELECT
        codigo_cliente,
        MIN(fecha_mes) AS fecha_inicio_cliente

    FROM base

    WHERE compro = 1
       OR venta_total > 0
       OR facturas > 0

    GROUP BY
        codigo_cliente
),

/* ============================================================
   PANEL REBASADO
   mes_vida = 0 corresponde a la primera compra observada
   ============================================================ */

panel_rebasado AS (

    SELECT
        b.*,
        i.fecha_inicio_cliente,

        DATEDIFF(
            MONTH,
            i.fecha_inicio_cliente,
            b.fecha_mes
        ) AS mes_vida

    FROM base b

    INNER JOIN inicio_cliente i
        ON b.codigo_cliente = i.codigo_cliente

    WHERE b.fecha_mes >= i.fecha_inicio_cliente
),

/* ============================================================
   PRIMER MES ÉTICO EN LOS PRIMEROS 12 MESES
   ============================================================ */

primera_etica AS (

    SELECT
        codigo_cliente,
        MIN(mes_vida) AS mes_conversion

    FROM panel_rebasado

    WHERE mes_vida BETWEEN 0 AND 11
      AND (
            compro_etica = 1
         OR venta_etica > 0
         OR facturas_etica > 0
      )

    GROUP BY
        codigo_cliente
),

/* ============================================================
   ÚLTIMO MES DISPONIBLE EN LA BASE
   ============================================================ */

limite_base AS (

    SELECT
        MAX(fecha_mes) AS fecha_maxima

    FROM base
),

/* ============================================================
   INFORMACIÓN DE COBERTURA
   ============================================================ */

cobertura_cliente AS (

    SELECT
        p.codigo_cliente,
        p.fecha_inicio_cliente,

        MAX(p.fecha_mes) AS ultimo_mes_con_registro,

        COUNT(
            DISTINCT CASE
                WHEN p.mes_vida BETWEEN 0 AND 11
                THEN p.mes_vida
            END
        ) AS meses_con_registro_12m,

        COUNT(
            DISTINCT CASE
                WHEN p.mes_vida BETWEEN 0 AND 11
                 AND p.compro = 1
                THEN p.mes_vida
            END
        ) AS meses_con_compra_12m

    FROM panel_rebasado p

    GROUP BY
        p.codigo_cliente,
        p.fecha_inicio_cliente
),

/* ============================================================
   CLASIFICACIÓN FINAL
   ============================================================ */

clientes_cohorte AS (

    SELECT
        c.codigo_cliente,
        c.fecha_inicio_cliente,

        e.mes_conversion,

        COALESCE(
            e.mes_conversion,
            99
        ) AS orden_cohorte,

        CASE
            WHEN e.mes_conversion = 0
                THEN 'Nacido Etico'

            WHEN e.mes_conversion BETWEEN 1 AND 11
                THEN CONCAT(
                    'Convertido mes ',
                    e.mes_conversion
                )

            ELSE 'Nunca Etico'
        END AS cohorte,

        DATEADD(
            MONTH,
            11,
            c.fecha_inicio_cliente
        ) AS ultimo_mes_ventana_12m,

        c.ultimo_mes_con_registro,
        c.meses_con_registro_12m,
        c.meses_con_compra_12m,

        CASE
            WHEN DATEADD(
                    MONTH,
                    11,
                    c.fecha_inicio_cliente
                 ) <= l.fecha_maxima
                THEN 1
            ELSE 0
        END AS ventana_12m_completa

    FROM cobertura_cliente c

    LEFT JOIN primera_etica e
        ON c.codigo_cliente = e.codigo_cliente

    CROSS JOIN limite_base l
)

/* ============================================================
   MATERIALIZACIÓN DE LA TABLA
   ============================================================ */

SELECT
    codigo_cliente,
    fecha_inicio_cliente,
    mes_conversion,
    orden_cohorte,
    cohorte,
    ultimo_mes_ventana_12m,
    ultimo_mes_con_registro,
    meses_con_registro_12m,
    meses_con_compra_12m,
    ventana_12m_completa

INTO sales.ca_cliente_cohortes

FROM clientes_cohorte;

CREATE UNIQUE CLUSTERED INDEX UX_ca_cliente_cohortes_codigo
ON sales.ca_cliente_cohortes (codigo_cliente);


SELECT COUNT(*) AS cantidad_clientes
FROM sales.ca_cliente_cohortes;

SELECT
    codigo_cliente,
    COUNT(*) AS cantidad_registros

FROM sales.ca_cliente_cohortes

GROUP BY
    codigo_cliente

HAVING COUNT(*) > 1;