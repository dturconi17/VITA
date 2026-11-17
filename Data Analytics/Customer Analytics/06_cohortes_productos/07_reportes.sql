SELECT TOP 100
    horizonte,
    codigo_producto,
    nombre_producto,
    linea,
    sector,

    clientes_convertidos,
    convertidos_producto,
    penetracion_convertidos_pct,

    clientes_nunca,
    nunca_producto,
    penetracion_nunca_pct,

    diferencia_penetracion_pp,
    lift_vs_nunca

FROM sales.ca_producto_lift_horizonte

WHERE
    convertidos_producto >= 20
    AND penetracion_convertidos_pct >= 5
    AND diferencia_penetracion_pp >= 5

ORDER BY
    diferencia_penetracion_pp DESC,
    convertidos_producto DESC;


SELECT TOP 30 *
FROM sales.ca_producto_lift_horizonte
WHERE
    horizonte = 1
    AND convertidos_producto >= 15
ORDER BY
    diferencia_penetracion_pp DESC;    

SELECT TOP 30 *
FROM sales.ca_producto_lift_horizonte
WHERE
    horizonte = 2
    AND convertidos_producto >= 15
ORDER BY
    diferencia_penetracion_pp DESC;    

SELECT TOP 50 *
FROM sales.ca_producto_lift_horizonte
WHERE
    horizonte BETWEEN 3 AND 5
    AND convertidos_producto >= 10
ORDER BY
    horizonte,
    diferencia_penetracion_pp DESC;    

    DROP TABLE IF EXISTS sales.ca_producto_activador_resumen;

SELECT
    codigo_producto,
    MAX(nombre_producto) AS nombre_producto,
    MAX(linea) AS linea,
    MAX(sector) AS sector,
    MAX(categoria) AS categoria,

    COUNT(DISTINCT horizonte) AS horizontes_observados,

    SUM(
        CASE
            WHEN convertidos_producto >= 10
             AND diferencia_penetracion_pp >= 5
            THEN 1
            ELSE 0
        END
    ) AS horizontes_diferenciales,

    SUM(convertidos_producto) AS apariciones_convertidos,

    CAST(
        AVG(penetracion_convertidos_pct)
        AS decimal(12,4)
    ) AS penetracion_convertidos_promedio,

    CAST(
        AVG(penetracion_nunca_pct)
        AS decimal(12,4)
    ) AS penetracion_nunca_promedio,

    CAST(
        AVG(diferencia_penetracion_pp)
        AS decimal(12,4)
    ) AS diferencia_promedio_pp,

    CAST(
        AVG(
            CASE
                WHEN lift_vs_nunca IS NOT NULL
                 AND lift_vs_nunca <= 20
                THEN lift_vs_nunca
            END
        )
        AS decimal(12,4)
    ) AS lift_promedio,

    MAX(diferencia_penetracion_pp)
        AS diferencia_maxima_pp

INTO sales.ca_producto_activador_resumen

FROM sales.ca_producto_lift_horizonte

GROUP BY
    codigo_producto;

SELECT TOP 50
    *
FROM sales.ca_producto_activador_resumen
WHERE
    apariciones_convertidos >= 20
    AND horizontes_diferenciales >= 2
ORDER BY
    horizontes_diferenciales DESC,
    diferencia_promedio_pp DESC,
    apariciones_convertidos DESC;    




SELECT
    p.codigo_producto,
    MAX(p.nombre_producto) AS nombre_producto,
    MAX(p.linea) AS linea,
    MAX(p.sector) AS sector,
    MAX(p.categoria) AS categoria,

    COUNT(DISTINCT p.codigo_cliente) AS clientes,

    SUM(p.cantidad_producto) AS cantidad,

    SUM(p.venta_producto) AS venta

FROM sales.ca_cliente_producto_mes p

WHERE
    p.orden_cohorte BETWEEN 1 AND 11

    -- Primer mes de compra Ética
    AND p.mes_vida = p.mes_conversion

    -- Excluir productos Éticos
    AND p.es_producto_etico = 0

GROUP BY
    p.codigo_producto

ORDER BY
    clientes DESC;





SELECT
    codigo_producto,
    MAX(nombre_producto) nombre_producto,
    MAX(linea) linea,

    COUNT(DISTINCT codigo_cliente) clientes,

    SUM(cantidad_producto) cantidad,
    SUM(venta_producto) venta

FROM sales.ca_cliente_producto_mes

WHERE
    orden_cohorte = 1
    AND mes_vida = mes_conversion
    AND es_producto_etico = 1

GROUP BY
    codigo_producto

ORDER BY
    clientes DESC;