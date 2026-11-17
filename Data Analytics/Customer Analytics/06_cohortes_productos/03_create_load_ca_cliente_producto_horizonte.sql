DROP TABLE IF EXISTS sales.ca_cliente_producto_horizonte;

;WITH horizontes AS
(
    SELECT 1 AS horizonte
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
    UNION ALL SELECT 6
    UNION ALL SELECT 7
    UNION ALL SELECT 8
    UNION ALL SELECT 9
    UNION ALL SELECT 10
    UNION ALL SELECT 11
),

convertidos AS
(
    SELECT
        p.codigo_cliente,

        p.mes_conversion AS horizonte,
        p.mes_conversion,
        p.orden_cohorte,
        p.cohorte,
        p.ventana_adopcion,

        CAST('Convertido' AS varchar(20)) AS grupo_comparacion,

        p.mes_vida,
        p.periodo,

        p.codigo_producto,
        p.nombre_producto,
        p.linea,
        p.sector,
        p.categoria,
        p.nombre_pack,

        p.cantidad_producto,
        p.venta_producto,
        p.facturas_producto

    FROM sales.ca_cliente_producto_mes p

    WHERE
        p.orden_cohorte BETWEEN 1 AND 11

        -- Compras anteriores al mes de conversión
        AND p.mes_vida < p.mes_conversion

        -- Excluimos los productos Éticos
        AND p.es_producto_etico = 0
),

nunca_etico AS
(
    SELECT
        p.codigo_cliente,

        h.horizonte,
        CAST(NULL AS int) AS mes_conversion,
        p.orden_cohorte,
        p.cohorte,
        p.ventana_adopcion,

        CAST('Nunca Etico' AS varchar(20)) AS grupo_comparacion,

        p.mes_vida,
        p.periodo,

        p.codigo_producto,
        p.nombre_producto,
        p.linea,
        p.sector,
        p.categoria,
        p.nombre_pack,

        p.cantidad_producto,
        p.venta_producto,
        p.facturas_producto

    FROM sales.ca_cliente_producto_mes p

    CROSS JOIN horizontes h

    WHERE
        p.orden_cohorte = 99

        -- Igual exposición que el convertido
        AND p.mes_vida < h.horizonte

        -- Excluimos productos Éticos
        AND p.es_producto_etico = 0
)

SELECT *
INTO sales.ca_cliente_producto_horizonte
FROM
(
    SELECT * FROM convertidos

    UNION ALL

    SELECT * FROM nunca_etico
) x;


CREATE CLUSTERED INDEX IX_ca_cliente_producto_horizonte
ON sales.ca_cliente_producto_horizonte
(
    horizonte,
    grupo_comparacion,
    codigo_cliente,
    codigo_producto
);

CREATE NONCLUSTERED INDEX IX_ca_producto_horizonte
ON sales.ca_cliente_producto_horizonte
(
    horizonte,
    codigo_producto,
    grupo_comparacion
)
INCLUDE
(
    codigo_cliente,
    mes_vida,
    linea,
    venta_producto,
    cantidad_producto,
    facturas_producto
);


SELECT
    MIN(horizonte) AS horizonte_minimo,
    MAX(horizonte) AS horizonte_maximo,
    COUNT(*) AS filas,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    COUNT(DISTINCT codigo_producto) AS productos
FROM sales.ca_cliente_producto_horizonte;

SELECT
    horizonte,
    grupo_comparacion,
    COUNT(DISTINCT codigo_cliente) AS clientes,
    COUNT(DISTINCT codigo_producto) AS productos,
    SUM(venta_producto) AS venta_previa
FROM sales.ca_cliente_producto_horizonte
GROUP BY
    horizonte,
    grupo_comparacion
ORDER BY
    horizonte,
    grupo_comparacion;

    SELECT
    linea,
    COUNT(*) AS filas
FROM sales.ca_cliente_producto_horizonte
GROUP BY
    linea
ORDER BY
    linea;