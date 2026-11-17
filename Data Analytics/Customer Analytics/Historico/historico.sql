
/* ============================================================
   EL CUBO - MAESTRO HISTORICO MENSUAL DE CLIENTES
   Fuente: sales.v_venta_total
   Periodo: julio 2022 - octubre 2026
   Universo: grupo FARMACIAS, clientes en dim_cliente
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;


IF OBJECT_ID('sales.maestro_cliente_mes', 'U') IS NOT NULL
BEGIN
    THROW 50001,
        'La tabla sales.maestro_cliente_mes ya existe. No se reemplazo.',
        1;
END;

DECLARE @Inicio DATE = '20220701';
DECLARE @FinExclusivo DATE = '20261101';

/* 1. Extraer ventas validas y autorizadas */

SELECT
    v.codigo_cliente,
    v.id_sale_invoice,
    v.fecha_factura,
    DATEFROMPARTS(
        YEAR(v.fecha_factura),
        MONTH(v.fecha_factura), 1
    ) AS fecha_mes,

    NULLIF(LTRIM(RTRIM(v.nombre_cliente)), '')
        AS nombre_cliente,

    NULLIF(LTRIM(RTRIM(v.nombre_subgrupo)), '')
        AS nombre_subgrupo,

    COALESCE(
        NULLIF(UPPER(LTRIM(RTRIM(v.linea))), ''),
        'SIN LINEA'
    ) AS linea,

    COALESCE(v.total_venta, 0) AS venta,
    COALESCE(v.cantidad, 0) AS unidades,
    v.codigo_producto

INTO #ventas

FROM sales.v_venta_total v

WHERE v.fecha_factura >= @Inicio
  AND v.fecha_factura < @FinExclusivo
  AND v.estado_factura = 'V'
  AND (
      v.nombre_vendedor IS NULL
      OR v.nombre_vendedor <> 'ANA MARIA AGUILAR SUAREZ'
  )
  AND UPPER(LTRIM(RTRIM(v.nombre_grupo))) = 'FARMACIAS'
  AND EXISTS (
      SELECT 1
      FROM sales.dim_cliente d
      WHERE d.codigo_cliente = v.codigo_cliente
  );

CREATE CLUSTERED INDEX IX_ventas
ON #ventas(codigo_cliente, fecha_mes);

/* 2. Agregacion mensual, incluyendo lineas */

SELECT
    codigo_cliente,
    fecha_mes,

    SUM(venta) AS venta_total,
    SUM(CONVERT(BIGINT, unidades)) AS unidades,

    COUNT(DISTINCT id_sale_invoice) AS facturas,
    COUNT(DISTINCT codigo_producto) AS productos_distintos,
    COUNT(DISTINCT linea) AS lineas_distintas,

    SUM(CASE WHEN linea = 'ETICO'
             THEN venta ELSE 0 END) AS venta_etico,

    SUM(CASE WHEN linea = 'OTC'
             THEN venta ELSE 0 END) AS venta_otc,

    SUM(CASE WHEN linea IN ('GENÉRICO', 'GENERICO')
             THEN venta ELSE 0 END) AS venta_generico,

    SUM(CASE WHEN linea IN ('COSMÉTICA', 'COSMETICA')
             THEN venta ELSE 0 END) AS venta_cosmetica,

    SUM(CASE WHEN linea = 'SERVICIOS FARMACEUTICOS'
             THEN venta ELSE 0 END) AS venta_servicios,

    SUM(CASE WHEN linea = 'HOGAR'
             THEN venta ELSE 0 END) AS venta_hogar,

    MAX(CASE WHEN linea = 'ETICO'
             THEN 1 ELSE 0 END) AS flag_etico,

    MAX(CASE WHEN linea = 'OTC'
             THEN 1 ELSE 0 END) AS flag_otc,

    MAX(CASE WHEN linea IN ('GENÉRICO', 'GENERICO')
             THEN 1 ELSE 0 END) AS flag_generico,

    MAX(CASE WHEN linea IN ('COSMÉTICA', 'COSMETICA')
             THEN 1 ELSE 0 END) AS flag_cosmetica,

    MAX(CASE WHEN linea = 'SERVICIOS FARMACEUTICOS'
             THEN 1 ELSE 0 END) AS flag_servicios,

    MAX(CASE WHEN linea = 'HOGAR'
             THEN 1 ELSE 0 END) AS flag_hogar

INTO #ventas_mes

FROM #ventas
GROUP BY codigo_cliente, fecha_mes;

CREATE UNIQUE CLUSTERED INDEX IX_ventas_mes
ON #ventas_mes(codigo_cliente, fecha_mes);

/* 3. Datos de identificacion y primera compra observada */

WITH Identificacion AS (
    SELECT
        codigo_cliente,
        nombre_cliente,
        nombre_subgrupo,
        fecha_factura,
        id_sale_invoice,
        ROW_NUMBER() OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_factura DESC, id_sale_invoice DESC
        ) AS rn
    FROM #ventas
)
SELECT
    v.codigo_cliente,
    MIN(v.fecha_mes) AS primer_mes_compra,
    MAX(CASE WHEN i.rn = 1
             THEN i.nombre_cliente END) AS nombre_cliente,
    MAX(CASE WHEN i.rn = 1
             THEN i.nombre_subgrupo END) AS subgrupo_actual
INTO #clientes
FROM #ventas v
LEFT JOIN Identificacion i
    ON v.codigo_cliente = i.codigo_cliente
   AND i.rn = 1
GROUP BY v.codigo_cliente;

CREATE UNIQUE CLUSTERED INDEX IX_clientes
ON #clientes(codigo_cliente);

/* 4. Calendario de 52 meses */

;WITH N AS (
    SELECT TOP (DATEDIFF(MONTH, @Inicio, @FinExclusivo))
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
SELECT
    DATEADD(MONTH, n, @Inicio) AS fecha_mes
INTO #calendario
FROM N;

/* 5. Panel completo cliente x mes */

SELECT
    c.codigo_cliente,
    c.nombre_cliente,
    c.subgrupo_actual,
    c.primer_mes_compra,
    cal.fecha_mes,

    CONVERT(CHAR(6), cal.fecha_mes, 112) AS periodo,

    YEAR(cal.fecha_mes) AS anio,
    MONTH(cal.fecha_mes) AS mes,

    CASE WHEN vm.facturas > 0 THEN 1 ELSE 0 END AS compro,

    COALESCE(vm.venta_total, 0) AS venta_total,
    COALESCE(vm.unidades, 0) AS unidades,
    COALESCE(vm.facturas, 0) AS facturas,
    COALESCE(vm.productos_distintos, 0) AS productos_distintos,
    COALESCE(vm.lineas_distintas, 0) AS lineas_distintas,

    COALESCE(vm.venta_etico, 0) AS venta_etico,
    COALESCE(vm.venta_otc, 0) AS venta_otc,
    COALESCE(vm.venta_generico, 0) AS venta_generico,
    COALESCE(vm.venta_cosmetica, 0) AS venta_cosmetica,
    COALESCE(vm.venta_servicios, 0) AS venta_servicios,
    COALESCE(vm.venta_hogar, 0) AS venta_hogar,

    COALESCE(vm.flag_etico, 0) AS flag_etico,
    COALESCE(vm.flag_otc, 0) AS flag_otc,
    COALESCE(vm.flag_generico, 0) AS flag_generico,
    COALESCE(vm.flag_cosmetica, 0) AS flag_cosmetica,
    COALESCE(vm.flag_servicios, 0) AS flag_servicios,
    COALESCE(vm.flag_hogar, 0) AS flag_hogar

INTO #panel

FROM #clientes c
CROSS JOIN #calendario cal
LEFT JOIN #ventas_mes vm
    ON vm.codigo_cliente = c.codigo_cliente
   AND vm.fecha_mes = cal.fecha_mes

WHERE cal.fecha_mes >= c.primer_mes_compra;

CREATE UNIQUE CLUSTERED INDEX IX_panel
ON #panel(codigo_cliente, fecha_mes);

/* 6. Calculos historicos con funciones de ventana */

;WITH Ventanas AS (
    SELECT
        p.*,

        LAG(compro, 1, 0) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
        ) AS compro_mes_anterior,

        LAG(compro, 2, 0) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
        ) AS compro_hace_2_meses,

        SUM(compro) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS meses_con_compra_3m,

        SUM(compro) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS meses_con_compra_6m,

        SUM(venta_total) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS venta_6m,

        MAX(CASE WHEN compro = 1
                 THEN fecha_mes END) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS ultimo_mes_compra,

        LAG(flag_etico, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_etico_anterior,

        LAG(flag_otc, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_otc_anterior,

        LAG(flag_generico, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_generico_anterior,

        LAG(flag_cosmetica, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_cosmetica_anterior,

        LAG(flag_servicios, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_servicios_anterior,

        LAG(flag_hogar, 1, 0) OVER (
            PARTITION BY codigo_cliente ORDER BY fecha_mes
        ) AS flag_hogar_anterior

    FROM #panel p
),
Indicadores AS (
    SELECT
        *,

        DATEDIFF(
            MONTH, ultimo_mes_compra, fecha_mes
        ) AS meses_desde_ultima_compra,

        CASE WHEN compro = 1
                  AND fecha_mes = primer_mes_compra
             THEN 1 ELSE 0 END AS cliente_nuevo,

        CASE WHEN compro = 1
                  AND fecha_mes > primer_mes_compra
                  AND compro_mes_anterior = 0
             THEN 1 ELSE 0 END AS reactivado,

        CASE WHEN compro = 0
                  AND compro_mes_anterior = 1
             THEN 1 ELSE 0 END AS perdio_actividad,

        CASE WHEN
            (flag_etico = 1 AND flag_etico_anterior = 0)
            OR (flag_otc = 1 AND flag_otc_anterior = 0)
            OR (flag_generico = 1 AND flag_generico_anterior = 0)
            OR (flag_cosmetica = 1 AND flag_cosmetica_anterior = 0)
            OR (flag_servicios = 1 AND flag_servicios_anterior = 0)
            OR (flag_hogar = 1 AND flag_hogar_anterior = 0)
             THEN 1 ELSE 0 END AS incorporo_linea,

        CASE WHEN
            (flag_etico = 0 AND flag_etico_anterior = 1)
            OR (flag_otc = 0 AND flag_otc_anterior = 1)
            OR (flag_generico = 0 AND flag_generico_anterior = 1)
            OR (flag_cosmetica = 0 AND flag_cosmetica_anterior = 1)
            OR (flag_servicios = 0 AND flag_servicios_anterior = 1)
            OR (flag_hogar = 0 AND flag_hogar_anterior = 1)
             THEN 1 ELSE 0 END AS dejo_de_comprar_linea

    FROM Ventanas
),
Estados AS (
    SELECT
        *,

        CASE
            WHEN cliente_nuevo = 1
                THEN 'Cliente Nuevo'

            WHEN compro = 1
                 AND compro_mes_anterior = 1
                 AND compro_hace_2_meses = 1
                THEN 'Activo Fiel'

            WHEN compro = 1
                 AND (
                     compro_mes_anterior = 1
                     OR compro_hace_2_meses = 1
                 )
                THEN 'Activo Casi Fiel'

            WHEN compro = 1
                THEN 'Activo Despierto'

            WHEN meses_desde_ultima_compra = 1
                THEN 'En Pausa'

            WHEN meses_desde_ultima_compra BETWEEN 2 AND 3
                THEN 'Infiel'

            WHEN meses_desde_ultima_compra BETWEEN 4 AND 6
                THEN 'Dormido'

            WHEN meses_desde_ultima_compra BETWEEN 7 AND 11
                THEN 'Reconquista'

            WHEN meses_desde_ultima_compra BETWEEN 12 AND 23
                THEN 'Perdida Nivel 1'

            WHEN meses_desde_ultima_compra >= 24
                THEN 'Perdida Nivel 2'

            ELSE 'Sin clasificar'
        END AS estado_cubo

    FROM Indicadores
)
SELECT
    codigo_cliente,
    nombre_cliente,
    CAST('FARMACIAS' AS VARCHAR(30)) AS nombre_grupo,
    subgrupo_actual AS nombre_subgrupo,

    periodo,
    fecha_mes,
    anio,
    mes,
    primer_mes_compra,
    ultimo_mes_compra,

    CAST(compro AS BIT) AS compro,
    CAST(venta_total AS DECIMAL(19,4)) AS venta_total,
    unidades,
    facturas,
    productos_distintos,
    lineas_distintas,

    CAST(
        CASE WHEN facturas > 0
             THEN venta_total / facturas
             ELSE 0 END
        AS DECIMAL(19,4)
    ) AS ticket_promedio,

    CAST(venta_etico AS DECIMAL(19,4)) AS venta_etico,
    CAST(venta_otc AS DECIMAL(19,4)) AS venta_otc,
    CAST(venta_generico AS DECIMAL(19,4)) AS venta_generico,
    CAST(venta_cosmetica AS DECIMAL(19,4)) AS venta_cosmetica,
    CAST(venta_servicios AS DECIMAL(19,4))
        AS venta_servicios_farmaceuticos,
    CAST(venta_hogar AS DECIMAL(19,4)) AS venta_hogar,

    CAST(flag_etico AS BIT) AS flag_etico,
    CAST(flag_otc AS BIT) AS flag_otc,
    CAST(flag_generico AS BIT) AS flag_generico,
    CAST(flag_cosmetica AS BIT) AS flag_cosmetica,
    CAST(flag_servicios AS BIT)
        AS flag_servicios_farmaceuticos,
    CAST(flag_hogar AS BIT) AS flag_hogar,

    meses_con_compra_3m,
    meses_con_compra_6m,
    CAST(venta_6m AS DECIMAL(19,4)) AS venta_6m,
    meses_desde_ultima_compra,

    CAST(cliente_nuevo AS BIT) AS cliente_nuevo,
    CAST(reactivado AS BIT) AS reactivado,
    CAST(perdio_actividad AS BIT) AS perdio_actividad,
    CAST(incorporo_linea AS BIT) AS incorporo_linea,
    CAST(dejo_de_comprar_linea AS BIT)
        AS dejo_de_comprar_linea,

    estado_cubo,

    LAG(estado_cubo) OVER (
        PARTITION BY codigo_cliente
        ORDER BY fecha_mes
    ) AS estado_anterior,

    CAST(
        CASE
            WHEN cliente_nuevo = 1 THEN 1
            WHEN compro = 1
                 AND compro_mes_anterior = 1
                 AND compro_hace_2_meses = 1
            THEN 1 ELSE 0
        END AS BIT
    ) AS flag_nuevo_o_fiel

INTO sales.maestro_cliente_mes
FROM Estados;

CREATE UNIQUE CLUSTERED INDEX IX_maestro_cliente_mes
ON sales.maestro_cliente_mes(codigo_cliente, fecha_mes);

CREATE INDEX IX_maestro_periodo_estado
ON sales.maestro_cliente_mes(periodo, estado_cubo);

PRINT 'Maestro historico creado correctamente.';


select * from sales.maestro_cliente_mes



/* ============================================================
   EL CUBO - CICLO HISTORICO DE COMPRA
   Tabla: sales.maestro_cliente_mes
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* 1. Agregar columnas si no existen */

IF COL_LENGTH('sales.maestro_cliente_mes', 'ciclo_mediano_meses') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD ciclo_mediano_meses DECIMAL(10,2) NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'ciclo_p75_meses') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD ciclo_p75_meses DECIMAL(10,2) NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'intervalos_observados') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD intervalos_observados INT NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'ciclos_transcurridos') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD ciclos_transcurridos DECIMAL(10,2) NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'situacion_ciclo') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD situacion_ciclo VARCHAR(40) NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'flag_fuera_ciclo') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD flag_fuera_ciclo BIT NULL;

IF COL_LENGTH('sales.maestro_cliente_mes', 'flag_alerta_ciclo') IS NULL
    ALTER TABLE sales.maestro_cliente_mes
    ADD flag_alerta_ciclo BIT NULL;


/* 2. Identificar meses con compra e intervalos */

IF OBJECT_ID('tempdb..#intervalos') IS NOT NULL
    DROP TABLE #intervalos;

;WITH Compras AS (
    SELECT
        codigo_cliente,
        fecha_mes,
        LAG(fecha_mes) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_mes
        ) AS compra_anterior
    FROM sales.maestro_cliente_mes
    WHERE compro = 1
)
SELECT
    codigo_cliente,
    fecha_mes,
    DATEDIFF(MONTH, compra_anterior, fecha_mes)
        AS intervalo_meses
INTO #intervalos
FROM Compras
WHERE compra_anterior IS NOT NULL;

CREATE CLUSTERED INDEX IX_intervalos
ON #intervalos(codigo_cliente, fecha_mes);


/* 3. Calcular percentiles historicos en cada mes
      con compra, usando solo intervalos conocidos */

IF OBJECT_ID('tempdb..#ciclo_compras') IS NOT NULL
    DROP TABLE #ciclo_compras;

;WITH Distribucion AS (
    SELECT
        base.codigo_cliente,
        base.fecha_mes,

        COUNT(*) OVER (
            PARTITION BY base.codigo_cliente, base.fecha_mes
        ) AS intervalos_observados,

        PERCENTILE_CONT(0.50) WITHIN GROUP (
            ORDER BY hist.intervalo_meses
        ) OVER (
            PARTITION BY base.codigo_cliente, base.fecha_mes
        ) AS ciclo_mediano,

        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY hist.intervalo_meses
        ) OVER (
            PARTITION BY base.codigo_cliente, base.fecha_mes
        ) AS ciclo_p75

    FROM #intervalos base

    INNER JOIN #intervalos hist
        ON hist.codigo_cliente = base.codigo_cliente
       AND hist.fecha_mes <= base.fecha_mes
)
SELECT DISTINCT
    codigo_cliente,
    fecha_mes,
    intervalos_observados,
    CAST(ciclo_mediano AS DECIMAL(10,2))
        AS ciclo_mediano_meses,
    CAST(ciclo_p75 AS DECIMAL(10,2))
        AS ciclo_p75_meses
INTO #ciclo_compras
FROM Distribucion;

CREATE UNIQUE CLUSTERED INDEX IX_ciclo_compras
ON #ciclo_compras(codigo_cliente, fecha_mes);


/* 4. Propagar el ultimo ciclo conocido
      a cada mes del historico */

IF OBJECT_ID('tempdb..#ciclo_mes') IS NOT NULL
    DROP TABLE #ciclo_mes;

SELECT
    m.codigo_cliente,
    m.fecha_mes,
    c.intervalos_observados,
    c.ciclo_mediano_meses,
    c.ciclo_p75_meses
INTO #ciclo_mes
FROM sales.maestro_cliente_mes m
OUTER APPLY (
    SELECT TOP (1)
        cc.intervalos_observados,
        cc.ciclo_mediano_meses,
        cc.ciclo_p75_meses
    FROM #ciclo_compras cc
    WHERE cc.codigo_cliente = m.codigo_cliente
      AND cc.fecha_mes <= m.fecha_mes
    ORDER BY cc.fecha_mes DESC
) c;

CREATE UNIQUE CLUSTERED INDEX IX_ciclo_mes
ON #ciclo_mes(codigo_cliente, fecha_mes);


/* 5. Actualizar el maestro */

UPDATE m
SET
    m.intervalos_observados =
        COALESCE(c.intervalos_observados, 0),

    m.ciclo_mediano_meses =
        CASE
            WHEN c.intervalos_observados >= 3
            THEN c.ciclo_mediano_meses
            ELSE NULL
        END,

    m.ciclo_p75_meses =
        CASE
            WHEN c.intervalos_observados >= 3
            THEN c.ciclo_p75_meses
            ELSE NULL
        END,

    m.ciclos_transcurridos =
        CASE
            WHEN c.intervalos_observados >= 3
             AND c.ciclo_mediano_meses > 0
            THEN CAST(
                1.0 * m.meses_desde_ultima_compra
                / c.ciclo_mediano_meses
                AS DECIMAL(10,2)
            )
            ELSE NULL
        END,

    m.situacion_ciclo =
        CASE
            WHEN COALESCE(c.intervalos_observados, 0) < 3
                THEN 'Sin historial suficiente'

            WHEN m.meses_desde_ultima_compra
                 <= c.ciclo_mediano_meses
                THEN 'Dentro de ciclo'

            WHEN m.meses_desde_ultima_compra
                 <= c.ciclo_p75_meses
                THEN 'Alerta de ciclo'

            WHEN m.meses_desde_ultima_compra
                 <= 1.5 * c.ciclo_p75_meses
                THEN 'Atrasado'

            ELSE 'Muy atrasado'
        END,

    m.flag_fuera_ciclo =
        CASE
            WHEN c.intervalos_observados >= 3
             AND m.meses_desde_ultima_compra
                 > 1.5 * c.ciclo_p75_meses
                THEN 1
            WHEN c.intervalos_observados >= 3
             AND m.meses_desde_ultima_compra
                 > c.ciclo_p75_meses
                THEN 1
            ELSE 0
        END,

    m.flag_alerta_ciclo =
        CASE
            WHEN c.intervalos_observados >= 3
             AND m.meses_desde_ultima_compra
                 > c.ciclo_mediano_meses
             AND m.meses_desde_ultima_compra
                 <= c.ciclo_p75_meses
                THEN 1
            ELSE 0
        END

FROM sales.maestro_cliente_mes m

INNER JOIN #ciclo_mes c
    ON m.codigo_cliente = c.codigo_cliente
   AND m.fecha_mes = c.fecha_mes;

PRINT 'Ciclo historico calculado correctamente.';


select *
FROM sales.maestro_cliente_mes where codigo_cliente = 'C1000247023' order by periodo asc