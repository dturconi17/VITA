/*==============================================================
CARGA: sales.ca_cliente_idc

El índice utiliza PERCENT_RANK para evitar que clientes extremos
distorsionen la escala.

Fecha máxima considerada:
31 de marzo de 2026.
==============================================================*/

TRUNCATE TABLE sales.ca_cliente_idc;

WITH Base AS
(
    SELECT
        codigo_cliente,

        CAST
        (
            ISNULL(cliente_etica, 0)
            AS BIT
        ) AS cliente_etica,

        CAST
        (
            ISNULL(venta_mensual_promedio_historica, 0)
            AS DECIMAL(19,4)
        ) AS venta_mensual_historica,

        CAST
        (
            ISNULL(frecuencia_historica, 0)
            AS DECIMAL(19,4)
        ) AS frecuencia_historica,

        CAST
        (
            ISNULL(productos_historicos, 0)
            AS INT
        ) AS productos_historicos,

        CAST
        (
            ISNULL(meses_activos_historicos, 0)
            AS INT
        ) AS meses_activos_historicos

    FROM sales.ca_cliente
),

Percentiles AS
(
    SELECT
        codigo_cliente,
        cliente_etica,

        venta_mensual_historica,
        frecuencia_historica,
        productos_historicos,
        meses_activos_historicos,

        PERCENT_RANK() OVER
        (
            ORDER BY venta_mensual_historica
        ) AS percentil_venta,

        PERCENT_RANK() OVER
        (
            ORDER BY frecuencia_historica
        ) AS percentil_frecuencia,

        PERCENT_RANK() OVER
        (
            ORDER BY productos_historicos
        ) AS percentil_productos,

        PERCENT_RANK() OVER
        (
            ORDER BY meses_activos_historicos
        ) AS percentil_meses_activos

    FROM Base
),

Scores AS
(
    SELECT
        codigo_cliente,
        cliente_etica,

        venta_mensual_historica,
        frecuencia_historica,
        productos_historicos,
        meses_activos_historicos,

        CAST
        (
            percentil_venta * 100
            AS DECIMAL(19,4)
        ) AS score_venta_mensual,

        CAST
        (
            percentil_frecuencia * 100
            AS DECIMAL(19,4)
        ) AS score_frecuencia,

        CAST
        (
            percentil_productos * 100
            AS DECIMAL(19,4)
        ) AS score_productos,

        CAST
        (
            percentil_meses_activos * 100
            AS DECIMAL(19,4)
        ) AS score_meses_activos

    FROM Percentiles
),

Indice AS
(
    SELECT
        *,

        CAST
        (
              score_productos      * 0.30
            + score_frecuencia     * 0.25
            + score_venta_mensual  * 0.25
            + score_meses_activos  * 0.20

            AS DECIMAL(10,2)
        ) AS idc

    FROM Scores
)

INSERT INTO sales.ca_cliente_idc
(
    codigo_cliente,
    cliente_etica,
    venta_mensual_historica,
    frecuencia_historica,
    productos_historicos,
    meses_activos_historicos,
    score_venta_mensual,
    score_frecuencia,
    score_productos,
    score_meses_activos,
    idc,
    segmento_idc,
    fecha_corte,
    fecha_actualizacion
)
SELECT
    codigo_cliente,
    cliente_etica,
    venta_mensual_historica,
    frecuencia_historica,
    productos_historicos,
    meses_activos_historicos,
    score_venta_mensual,
    score_frecuencia,
    score_productos,
    score_meses_activos,
    idc,
    CASE
        WHEN idc >= 80 THEN 'Desarrollo muy alto'
        WHEN idc >= 60 THEN 'Desarrollo alto'
        WHEN idc >= 40 THEN 'Desarrollo medio'
        WHEN idc >= 20 THEN 'Desarrollo bajo'
        ELSE 'Desarrollo inicial'
    END AS segmento_idc,
    CAST('2026-03-31' AS DATE) AS fecha_corte,
    SYSDATETIME() AS fecha_actualizacion
FROM Indice;
