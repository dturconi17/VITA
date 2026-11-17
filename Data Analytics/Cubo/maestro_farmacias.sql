WITH Clientes AS (

    SELECT
        codigo_cliente,

        SUM(
            CASE WHEN compro = 1 THEN 1 ELSE 0 END
        ) AS meses_con_compra_historicos,

        MIN(
            CASE WHEN compro = 1 THEN periodo END
        ) AS primera_compra_periodo,

        MAX(
            CASE WHEN compro = 1 THEN periodo END
        ) AS ultima_compra_periodo,

        MAX(
            CASE WHEN periodo = '202608' THEN compro ELSE 0 END
        ) AS compro_mes_actual,

        MAX(
            CASE WHEN periodo = '202607' THEN compro ELSE 0 END
        ) AS compro_mes_1,

        MAX(
            CASE WHEN periodo = '202606' THEN compro ELSE 0 END
        ) AS compro_mes_2

    FROM sales.fact_cliente_mes

    WHERE periodo <= '202608'

    GROUP BY codigo_cliente
),

Estado AS (

    SELECT
        *,

        CASE
            WHEN ultima_compra_periodo IS NULL THEN NULL

            ELSE DATEDIFF(
                MONTH,
                DATEFROMPARTS(
                    CAST(LEFT(ultima_compra_periodo,4) AS INT),
                    CAST(RIGHT(ultima_compra_periodo,2) AS INT),
                    1
                ),
                CAST('20260801' AS DATE)
            )
        END AS meses_inactivo

    FROM Clientes
),

Clasificacion AS (

    SELECT
        *,

        CASE

            /* =============================================
               NUNCA FUE CLIENTE
               ============================================= */

            WHEN meses_con_compra_historicos = 0
                THEN 'Prospecto'


            /* =============================================
               CLIENTE NUEVO
               Primera compra = mes analizado
               ============================================= */

            WHEN primera_compra_periodo = '202608'
                THEN 'Cliente Nuevo'


            /* =============================================
               ACTIVOS
               ============================================= */

            WHEN compro_mes_actual = 1
             AND compro_mes_1 = 1
             AND compro_mes_2 = 1
                THEN 'Activo Fiel'


            WHEN compro_mes_actual = 1
             AND (compro_mes_1 + compro_mes_2) = 1
                THEN 'Activo Casi Fiel'


            WHEN compro_mes_actual = 1
             AND compro_mes_1 = 0
             AND compro_mes_2 = 0
                THEN 'Activo Despierto'


            /* =============================================
               INACTIVOS
               ============================================= */

            WHEN meses_inactivo = 1
                THEN 'En Pausa'

            WHEN meses_inactivo BETWEEN 2 AND 3
                THEN 'Infiel'

            WHEN meses_inactivo BETWEEN 4 AND 6
                THEN 'Dormido'

            WHEN meses_inactivo BETWEEN 7 AND 11
                THEN 'Reconquista'

            WHEN meses_inactivo BETWEEN 12 AND 23
                THEN 'Perdida Nivel 1'

            WHEN meses_inactivo >= 24
                THEN 'Perdida Nivel 2'

        END AS estado_cubo

    FROM Estado
)

SELECT
    estado_cubo,

    COUNT(*) AS cantidad_farmacias,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS pct_farmacias

FROM Clasificacion

GROUP BY estado_cubo

ORDER BY
    CASE estado_cubo
        WHEN 'Cliente Nuevo' THEN 1
        WHEN 'Activo Fiel' THEN 2
        WHEN 'Activo Casi Fiel' THEN 3
        WHEN 'Activo Despierto' THEN 4
        WHEN 'En Pausa' THEN 5
        WHEN 'Infiel' THEN 6
        WHEN 'Dormido' THEN 7
        WHEN 'Reconquista' THEN 8
        WHEN 'Perdida Nivel 1' THEN 9
        WHEN 'Perdida Nivel 2' THEN 10
        WHEN 'Prospecto' THEN 11
    END;



    select * from sales.fact_cliente_mes



    SELECT
    COALESCE(
        NULLIF(UPPER(LTRIM(RTRIM(linea))), ''),
        'SIN LINEA'
    ) AS linea,

    COUNT(*) AS registros,

    COUNT(DISTINCT codigo_cliente) AS farmacias,

    COUNT(DISTINCT codigo_producto) AS productos_distintos

FROM sales.v_venta_total

WHERE estado_factura = 'V'
  AND nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
  AND fecha_factura < '2026-04-01'

GROUP BY
    COALESCE(
        NULLIF(UPPER(LTRIM(RTRIM(linea))), ''),
        'SIN LINEA'
    )

ORDER BY registros DESC;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'sales'
  AND TABLE_NAME = 'v_venta_total'
ORDER BY ORDINAL_POSITION;


WITH VentasDetalle AS (
    SELECT
        CONVERT(CHAR(6), fecha_factura, 112) AS periodo,

        COUNT(DISTINCT id_sale_invoice) AS facturas_detalle,

        SUM(COALESCE(total_venta, 0)) AS venta_detalle,

        SUM(COALESCE(total, 0)) AS total_detalle,

        SUM(COALESCE(descuento, 0)) AS descuento_detalle

    FROM sales.v_venta_total

    WHERE estado_factura = 'V'
      AND nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
      AND fecha_factura < '2026-04-01'

    GROUP BY CONVERT(CHAR(6), fecha_factura, 112)
),
VentasFactura AS (
    SELECT
        CONVERT(CHAR(6), fecha_factura, 112) AS periodo,

        COUNT(DISTINCT id_sale_invoice) AS facturas_cabecera,

        SUM(COALESCE(venta_total, 0)) AS venta_cabecera

    FROM sales.fact_invoice

    WHERE fecha_factura < '2026-04-01'

    GROUP BY CONVERT(CHAR(6), fecha_factura, 112)
)
SELECT
    COALESCE(d.periodo, f.periodo) AS periodo,

    d.facturas_detalle,
    f.facturas_cabecera,

    d.venta_detalle,
    f.venta_cabecera,

    d.venta_detalle - f.venta_cabecera AS diferencia_venta,

    d.total_detalle,
    d.descuento_detalle

FROM VentasDetalle d

FULL OUTER JOIN VentasFactura f
    ON d.periodo = f.periodo

ORDER BY COALESCE(d.periodo, f.periodo);


WITH Detalle AS (
    SELECT
        id_sale_invoice,
        SUM(COALESCE(total_venta, 0)) AS venta_detalle
    FROM sales.v_venta_total
    WHERE estado_factura = 'V'
      AND nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
      AND fecha_factura >= '2026-03-01'
      AND fecha_factura < '2026-04-01'
    GROUP BY id_sale_invoice
),
Cabecera AS (
    SELECT
        id_sale_invoice,
        SUM(COALESCE(venta_total, 0)) AS venta_cabecera
    FROM sales.fact_invoice
    WHERE fecha_factura >= '2026-03-01'
      AND fecha_factura < '2026-04-01'
    GROUP BY id_sale_invoice
)
SELECT
    CASE
        WHEN d.id_sale_invoice IS NOT NULL
         AND c.id_sale_invoice IS NOT NULL
            THEN 'En ambas'
        WHEN d.id_sale_invoice IS NOT NULL
            THEN 'Solo detalle'
        ELSE 'Solo cabecera'
    END AS origen,

    COUNT(*) AS cantidad_facturas,

    SUM(COALESCE(d.venta_detalle, 0)) AS venta_detalle,

    SUM(COALESCE(c.venta_cabecera, 0)) AS venta_cabecera,

    SUM(COALESCE(d.venta_detalle, 0))
      - SUM(COALESCE(c.venta_cabecera, 0)) AS diferencia

FROM Detalle d
FULL OUTER JOIN Cabecera c
    ON d.id_sale_invoice = c.id_sale_invoice

GROUP BY
    CASE
        WHEN d.id_sale_invoice IS NOT NULL
         AND c.id_sale_invoice IS NOT NULL
            THEN 'En ambas'
        WHEN d.id_sale_invoice IS NOT NULL
            THEN 'Solo detalle'
        ELSE 'Solo cabecera'
    END;

 