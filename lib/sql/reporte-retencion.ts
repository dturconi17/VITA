
export const queryRetencion = `
WITH Origen AS (
    SELECT
        codigo_cliente,
        nombre_cliente,
        nombre_subgrupo,
        estado_cubo,
        situacion_ciclo,
        compro,
        venta_total
    FROM sales.maestro_cliente_mes
    WHERE periodo = @desde
),
Destino AS (
    SELECT
        codigo_cliente,
        nombre_cliente,
        nombre_subgrupo,
        estado_cubo,
        situacion_ciclo,
        compro,
        venta_total
    FROM sales.maestro_cliente_mes
    WHERE periodo = @hasta
)
SELECT
    COALESCE(d.codigo_cliente, o.codigo_cliente)
        AS codigo_cliente,

    COALESCE(d.nombre_cliente, o.nombre_cliente)
        AS nombre_cliente,

    COALESCE(d.nombre_subgrupo, o.nombre_subgrupo)
        AS nombre_subgrupo,

    CASE
        WHEN o.codigo_cliente IS NULL
            THEN 'Sin registro'
        ELSE COALESCE(o.estado_cubo, 'Sin clasificacion')
    END AS estado_origen,

    CASE
        WHEN d.codigo_cliente IS NULL
            THEN 'Sin registro'
        ELSE COALESCE(d.estado_cubo, 'Sin clasificacion')
    END AS estado_destino,

    CASE
        WHEN o.codigo_cliente IS NULL
            THEN 'Sin registro'
        ELSE COALESCE(o.situacion_ciclo, 'Sin clasificacion')
    END AS ciclo_origen,

    CASE
        WHEN d.codigo_cliente IS NULL
            THEN 'Sin registro'
        ELSE COALESCE(d.situacion_ciclo, 'Sin clasificacion')
    END AS ciclo_destino,

    CAST(COALESCE(o.compro, 0) AS INT)
        AS compro_origen,

    CAST(COALESCE(d.compro, 0) AS INT)
        AS compro_destino,

    COALESCE(o.venta_total, 0)
        AS venta_origen,

    COALESCE(d.venta_total, 0)
        AS venta_destino,

    CASE
        WHEN o.codigo_cliente IS NULL
            THEN 'Ingreso al historico'

        WHEN d.codigo_cliente IS NULL
            THEN 'Salida del universo'

        WHEN o.compro = 1 AND d.compro = 1
            THEN 'Continua comprando'

        WHEN o.compro = 0 AND d.compro = 1
            THEN 'Reactivado'

        WHEN o.compro = 1 AND d.compro = 0
            THEN 'Dejo de comprar'

        ELSE 'Continua sin comprar'
    END AS movimiento_compra

FROM Origen o

FULL OUTER JOIN Destino d
    ON o.codigo_cliente = d.codigo_cliente

ORDER BY codigo_cliente;
`;
