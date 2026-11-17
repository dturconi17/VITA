/*==============================================================
PROYECTO: CUSTOMER ANALYTICS - LÍNEA ÉTICA
OBJETO: sales.ca_cliente

OBJETIVO:
Carga del dataset maestro por cliente.

CORTE:
Información anterior al 1 de abril de 2026.

MEJORAS:
- Diversidad histórica calculada desde el detalle.
- Productos Ética históricos.
- Productos No Ética históricos.
- Productos No Ética últimos 12 meses.
==============================================================*/

TRUNCATE TABLE sales.ca_cliente;
GO

WITH

/*==============================================================
1. PARÁMETROS TEMPORALES

Últimos 12 meses:
Desde el primer día del mes máximo menos 11 meses,
hasta la última fecha disponible.

Cartera actual:
Cliente con al menos una compra en los últimos 6 meses.
==============================================================*/

Parametros AS
(
    SELECT
        MAX(fecha_factura) AS fecha_fin_analisis,

        DATEFROMPARTS
        (
            YEAR(MAX(fecha_factura)),
            MONTH(MAX(fecha_factura)),
            1
        ) AS inicio_mes_maximo

    FROM sales.fact_invoice

    WHERE fecha_factura < '2026-04-01'
),

FechasAnalisis AS
(
    SELECT
        fecha_fin_analisis,

        DATEADD
        (
            MONTH,
            -11,
            inicio_mes_maximo
        ) AS fecha_inicio_12m,

        DATEADD
        (
            MONTH,
            -5,
            inicio_mes_maximo
        ) AS fecha_inicio_6m,

        CONCAT
        (
            YEAR(fecha_fin_analisis),

            RIGHT
            (
                '0'
                + CAST
                  (
                      MONTH(fecha_fin_analisis)
                      AS VARCHAR(2)
                  ),
                2
            )
        ) AS periodo_maximo_datos

    FROM Parametros
),

/*==============================================================
2. HISTÓRICO DESDE FACT_CLIENTE_MES

Contiene métricas acumulables:
- ventas
- facturas
- unidades
- meses activos

No se calculan productos históricos sumando productos mensuales.
==============================================================*/

HistoricoMensual AS
(
    SELECT
        codigo_cliente,

        SUM(venta_total)
            AS venta_historica,

        SUM(venta_etica)
            AS venta_etica_historica,

        SUM(venta_otras)
            AS venta_no_etica_historica,

        SUM(facturas)
            AS facturas_historicas,

        SUM(facturas_etica)
            AS facturas_etica_historicas,

        SUM(unidades)
            AS unidades_historicas,

        COUNT
        (
            CASE
                WHEN compro = 1
                THEN 1
            END
        ) AS meses_activos_historicos,

        COUNT
        (
            CASE
                WHEN compro_etica = 1
                THEN 1
            END
        ) AS meses_comprando_etica

    FROM sales.fact_cliente_mes

    GROUP BY
        codigo_cliente
),

/*==============================================================
3. DIVERSIDAD HISTÓRICA EXACTA

Se calcula directamente desde v_venta_total.

No corresponde sumar productos distintos mensuales porque
un mismo producto puede repetirse durante diferentes meses.
==============================================================*/

DiversidadHistorica AS
(
    SELECT
        v.codigo_cliente,

        ------------------------------------------------------
        -- Productos históricos totales
        ------------------------------------------------------

        COUNT
        (
            DISTINCT v.codigo_producto
        ) AS productos_historicos,

        ------------------------------------------------------
        -- Productos Ética históricos
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
        ) AS productos_etica_historicos,

        ------------------------------------------------------
        -- Productos No Ética históricos
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
        ) AS productos_no_etica_historicos,

        ------------------------------------------------------
        -- Líneas históricas
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
        ) AS lineas_historicas

    FROM sales.v_venta_total v

    WHERE v.estado_factura = 'V'

      AND
      
          v.nombre_vendedor
              <> 'ANA MARIA AGUILAR SUAREZ'
               

      AND v.fecha_factura < '2026-04-01'

    GROUP BY
        v.codigo_cliente
),

/*==============================================================
4. COMPORTAMIENTO ÚLTIMOS 12 MESES
==============================================================*/

Actual12m AS
(
    SELECT
        f.codigo_cliente,

        SUM(f.venta_total)
            AS venta_12m,

        SUM(f.venta_etica)
            AS venta_etica_12m,

        SUM(f.venta_otras)
            AS venta_no_etica_12m,

        SUM(f.facturas)
            AS facturas_12m,

        SUM(f.facturas_etica)
            AS facturas_etica_12m,

        SUM(f.unidades)
            AS unidades_12m,

        COUNT
        (
            CASE
                WHEN f.compro = 1
                THEN 1
            END
        ) AS meses_activos_12m

    FROM sales.fact_cliente_mes f

    CROSS JOIN FechasAnalisis p

    WHERE DATEFROMPARTS
          (
              f.año,
              f.mes,
              1
          )
          BETWEEN p.fecha_inicio_12m
              AND DATEFROMPARTS
                  (
                      YEAR(p.fecha_fin_analisis),
                      MONTH(p.fecha_fin_analisis),
                      1
                  )

    GROUP BY
        f.codigo_cliente
),

/*==============================================================
5. DIVERSIDAD EXACTA ÚLTIMOS 12 MESES
==============================================================*/

Diversidad12m AS
(
    SELECT
        v.codigo_cliente,

        ------------------------------------------------------
        -- Productos totales últimos 12 meses
        ------------------------------------------------------

        COUNT
        (
            DISTINCT v.codigo_producto
        ) AS productos_12m,

        ------------------------------------------------------
        -- Productos Ética últimos 12 meses
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
        ) AS productos_etica_12m,

        ------------------------------------------------------
        -- Productos No Ética últimos 12 meses
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
        ) AS productos_no_etica_12m,

        ------------------------------------------------------
        -- Líneas últimos 12 meses
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
        ) AS lineas_12m

    FROM sales.v_venta_total v

    CROSS JOIN FechasAnalisis p

    WHERE v.estado_factura = 'V'

      AND

          v.nombre_vendedor
              <> 'ANA MARIA AGUILAR SUAREZ'

      AND v.fecha_factura < '2026-04-01'

      AND CAST(v.fecha_hora_factura AS DATE)
          BETWEEN p.fecha_inicio_12m
              AND p.fecha_fin_analisis

    GROUP BY
        v.codigo_cliente
),

/*==============================================================
6. ACTIVIDAD ÚLTIMOS 6 MESES
==============================================================*/

Actividad6m AS
(
    SELECT
        f.codigo_cliente,

        CASE
            WHEN SUM(f.facturas) > 0
            THEN 1
            ELSE 0
        END AS compro_ultimos_6m

    FROM sales.fact_cliente_mes f

    CROSS JOIN FechasAnalisis p

    WHERE DATEFROMPARTS
          (
              f.año,
              f.mes,
              1
          )
          BETWEEN p.fecha_inicio_6m
              AND DATEFROMPARTS
                  (
                      YEAR(p.fecha_fin_analisis),
                      MONTH(p.fecha_fin_analisis),
                      1
                  )

    GROUP BY
        f.codigo_cliente
)

/*==============================================================
7. INSERT FINAL
==============================================================*/

INSERT INTO sales.ca_cliente
(
    codigo_cliente,
    canal,
    ciudad,
    zona_barrio,
    sucursal,
    vendedor,

    fecha_primer_compra,
    fecha_ultima_compra,
    periodo_alta,
    cohorte_año,
    cohorte_trimestre,
    antiguedad_meses,
    meses_activos_historicos,

    cliente_etica,
    fecha_primer_etica,
    fecha_ultima_etica,
    periodo_primer_etica,
    meses_hasta_etica,
    meses_comprando_etica,

    venta_historica,
    venta_etica_historica,
    venta_no_etica_historica,
    participacion_etica_historica,

    facturas_historicas,
    facturas_etica_historicas,
    ticket_promedio_historico,
    frecuencia_historica,

    productos_historicos,
    productos_etica_historicos,
    productos_no_etica_historicos,
    lineas_historicas,

    unidades_historicas,
    venta_mensual_promedio_historica,

    venta_12m,
    venta_etica_12m,
    venta_no_etica_12m,
    participacion_etica_12m,

    facturas_12m,
    facturas_etica_12m,
    ticket_promedio_12m,

    meses_activos_12m,
    frecuencia_12m,

    productos_12m,
    productos_etica_12m,
    productos_no_etica_12m,
    lineas_12m,

    unidades_12m,
    venta_mensual_promedio_12m,

    compro_ultimos_6m,
    cartera_actual,
    segmento_cartera,
    estado_cliente,

    periodo_maximo_datos,
    fecha_inicio_12m,
    fecha_fin_analisis
)

SELECT
    c.codigo_cliente,
    c.canal,
    c.ciudad,
    c.zona_barrio,
    c.sucursal,
    c.vendedor,

    c.fecha_primer_compra,
    c.fecha_ultima_compra,

    CONCAT
    (
        YEAR(c.fecha_primer_compra),

        RIGHT
        (
            '0'
            + CAST
              (
                  MONTH(c.fecha_primer_compra)
                  AS VARCHAR(2)
              ),
            2
        )
    ) AS periodo_alta,

    YEAR(c.fecha_primer_compra)
        AS cohorte_año,

    DATEPART
    (
        QUARTER,
        c.fecha_primer_compra
    ) AS cohorte_trimestre,

    c.antiguedad_meses,

    ISNULL
    (
        h.meses_activos_historicos,
        0
    ) AS meses_activos_historicos,

    c.cliente_etica,
    c.fecha_primer_etica,
    c.fecha_ultima_etica,

    CASE
        WHEN c.fecha_primer_etica IS NULL
        THEN NULL

        ELSE CONCAT
        (
            YEAR(c.fecha_primer_etica),

            RIGHT
            (
                '0'
                + CAST
                  (
                      MONTH(c.fecha_primer_etica)
                      AS VARCHAR(2)
                  ),
                2
            )
        )
    END AS periodo_primer_etica,

    CASE
        WHEN c.fecha_primer_etica IS NULL
        THEN NULL

        ELSE DATEDIFF
        (
            MONTH,
            c.fecha_primer_compra,
            c.fecha_primer_etica
        )
    END AS meses_hasta_etica,

    ISNULL
    (
        h.meses_comprando_etica,
        0
    ) AS meses_comprando_etica,

    ----------------------------------------------------------
    -- Histórico económico
    ----------------------------------------------------------

    ISNULL
    (
        h.venta_historica,
        0
    ) AS venta_historica,

    ISNULL
    (
        h.venta_etica_historica,
        0
    ) AS venta_etica_historica,

    ISNULL
    (
        h.venta_no_etica_historica,
        0
    ) AS venta_no_etica_historica,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                h.venta_etica_historica,
                0
            )
            /
            NULLIF
            (
                ISNULL
                (
                    h.venta_historica,
                    0
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS participacion_etica_historica,

    ISNULL
    (
        h.facturas_historicas,
        0
    ) AS facturas_historicas,

    ISNULL
    (
        h.facturas_etica_historicas,
        0
    ) AS facturas_etica_historicas,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                h.venta_historica,
                0
            )
            /
            NULLIF
            (
                ISNULL
                (
                    h.facturas_historicas,
                    0
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS ticket_promedio_historico,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                h.facturas_historicas,
                0
            )
            /
            NULLIF
            (
                CAST
                (
                    ISNULL
                    (
                        h.meses_activos_historicos,
                        0
                    )
                    AS DECIMAL(19,4)
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS frecuencia_historica,

    ----------------------------------------------------------
    -- Diversidad histórica exacta
    ----------------------------------------------------------

    ISNULL
    (
        dh.productos_historicos,
        0
    ) AS productos_historicos,

    ISNULL
    (
        dh.productos_etica_historicos,
        0
    ) AS productos_etica_historicos,

    ISNULL
    (
        dh.productos_no_etica_historicos,
        0
    ) AS productos_no_etica_historicos,

    ISNULL
    (
        dh.lineas_historicas,
        0
    ) AS lineas_historicas,

    ISNULL
    (
        h.unidades_historicas,
        0
    ) AS unidades_historicas,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                h.venta_historica,
                0
            )
            /
            NULLIF
            (
                CAST
                (
                    ISNULL
                    (
                        h.meses_activos_historicos,
                        0
                    )
                    AS DECIMAL(19,4)
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS venta_mensual_promedio_historica,

    ----------------------------------------------------------
    -- Últimos 12 meses
    ----------------------------------------------------------

    ISNULL
    (
        a.venta_12m,
        0
    ) AS venta_12m,

    ISNULL
    (
        a.venta_etica_12m,
        0
    ) AS venta_etica_12m,

    ISNULL
    (
        a.venta_no_etica_12m,
        0
    ) AS venta_no_etica_12m,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                a.venta_etica_12m,
                0
            )
            /
            NULLIF
            (
                ISNULL
                (
                    a.venta_12m,
                    0
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS participacion_etica_12m,

    ISNULL
    (
        a.facturas_12m,
        0
    ) AS facturas_12m,

    ISNULL
    (
        a.facturas_etica_12m,
        0
    ) AS facturas_etica_12m,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                a.venta_12m,
                0
            )
            /
            NULLIF
            (
                ISNULL
                (
                    a.facturas_12m,
                    0
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS ticket_promedio_12m,

    ISNULL
    (
        a.meses_activos_12m,
        0
    ) AS meses_activos_12m,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                a.facturas_12m,
                0
            )
            /
            NULLIF
            (
                CAST
                (
                    ISNULL
                    (
                        a.meses_activos_12m,
                        0
                    )
                    AS DECIMAL(19,4)
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS frecuencia_12m,

    ----------------------------------------------------------
    -- Diversidad últimos 12 meses
    ----------------------------------------------------------

    ISNULL
    (
        d.productos_12m,
        0
    ) AS productos_12m,

    ISNULL
    (
        d.productos_etica_12m,
        0
    ) AS productos_etica_12m,

    ISNULL
    (
        d.productos_no_etica_12m,
        0
    ) AS productos_no_etica_12m,

    ISNULL
    (
        d.lineas_12m,
        0
    ) AS lineas_12m,

    ISNULL
    (
        a.unidades_12m,
        0
    ) AS unidades_12m,

    ISNULL
    (
        CAST
        (
            ISNULL
            (
                a.venta_12m,
                0
            )
            /
            NULLIF
            (
                CAST
                (
                    ISNULL
                    (
                        a.meses_activos_12m,
                        0
                    )
                    AS DECIMAL(19,4)
                ),
                0
            )

            AS DECIMAL(19,4)
        ),
        0
    ) AS venta_mensual_promedio_12m,

    ----------------------------------------------------------
    -- Cartera
    ----------------------------------------------------------

    ISNULL
    (
        ac.compro_ultimos_6m,
        0
    ) AS compro_ultimos_6m,

    ISNULL
    (
        ac.compro_ultimos_6m,
        0
    ) AS cartera_actual,

    CASE
        WHEN ISNULL
             (
                 ac.compro_ultimos_6m,
                 0
             ) = 0
        THEN 'FUERA CARTERA ACTUAL'

        WHEN c.cliente_etica = 1
        THEN 'CARTERA ETICA'

        ELSE 'CARTERA NO ETICA'
    END AS segmento_cartera,

    c.estado_cliente,

    p.periodo_maximo_datos,
    p.fecha_inicio_12m,
    p.fecha_fin_analisis

FROM sales.dim_cliente c

LEFT JOIN HistoricoMensual h
    ON c.codigo_cliente = h.codigo_cliente

LEFT JOIN DiversidadHistorica dh
    ON c.codigo_cliente = dh.codigo_cliente

LEFT JOIN Actual12m a
    ON c.codigo_cliente = a.codigo_cliente

LEFT JOIN Diversidad12m d
    ON c.codigo_cliente = d.codigo_cliente

LEFT JOIN Actividad6m ac
    ON c.codigo_cliente = ac.codigo_cliente

CROSS JOIN FechasAnalisis p;
GO