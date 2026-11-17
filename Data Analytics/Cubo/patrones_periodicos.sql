WITH MesesConCompra AS (
    SELECT
        codigo_cliente,
        periodo,
        DATEFROMPARTS(
            CAST(LEFT(periodo, 4) AS INT),
            CAST(RIGHT(periodo, 2) AS INT),
            1
        ) AS fecha_compra
    FROM sales.fact_cliente_mes
    WHERE compro = 1
),

ComprasConAnterior AS (
    SELECT
        codigo_cliente,
        periodo,
        fecha_compra,

        LAG(fecha_compra) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_compra
        ) AS fecha_compra_anterior
    FROM MesesConCompra
),

Intervalos AS (
    SELECT
        codigo_cliente,
        periodo,
        fecha_compra,
        fecha_compra_anterior,

        DATEDIFF(
            MONTH,
            fecha_compra_anterior,
            fecha_compra
        ) AS intervalo_meses
    FROM ComprasConAnterior
    WHERE fecha_compra_anterior IS NOT NULL
),

ResumenCliente AS (
    SELECT
        codigo_cliente,

        COUNT(*) AS intervalos_observados,

        CAST(
            AVG(intervalo_meses * 1.0)
            AS DECIMAL(10,2)
        ) AS intervalo_promedio_meses,

        MIN(intervalo_meses) AS intervalo_minimo_meses,

        MAX(intervalo_meses) AS intervalo_maximo_meses,

        CAST(
            STDEV(intervalo_meses * 1.0)
            AS DECIMAL(10,2)
        ) AS desvio_intervalo_meses,

        SUM(CASE WHEN intervalo_meses = 1 THEN 1 ELSE 0 END)
            AS intervalos_1_mes,

        SUM(CASE WHEN intervalo_meses = 2 THEN 1 ELSE 0 END)
            AS intervalos_2_meses,

        SUM(CASE WHEN intervalo_meses = 3 THEN 1 ELSE 0 END)
            AS intervalos_3_meses,

        SUM(CASE WHEN intervalo_meses >= 4 THEN 1 ELSE 0 END)
            AS intervalos_4_meses_o_mas

    FROM Intervalos
    GROUP BY codigo_cliente
),

Clasificacion AS (
    SELECT
        *,

        CAST(
            intervalos_1_mes * 100.0 /
            NULLIF(intervalos_observados, 0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_1_mes,

        CAST(
            intervalos_2_meses * 100.0 /
            NULLIF(intervalos_observados, 0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_2_meses,

        CAST(
            intervalos_3_meses * 100.0 /
            NULLIF(intervalos_observados, 0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_3_meses,

        CASE

            /* Al menos 60% de sus intervalos son de 1 mes */
            WHEN intervalos_1_mes * 1.0 /
                 NULLIF(intervalos_observados,0) >= 0.60
                THEN 'Compra Mensual'

            /* Al menos 60% son cada 2 meses */
            WHEN intervalos_2_meses * 1.0 /
                 NULLIF(intervalos_observados,0) >= 0.60
                THEN 'Compra Bimestral'

            /* Al menos 60% son cada 3 meses */
            WHEN intervalos_3_meses * 1.0 /
                 NULLIF(intervalos_observados,0) >= 0.60
                THEN 'Compra Trimestral'

            ELSE 'Compra Irregular'

        END AS patron_compra

    FROM ResumenCliente

    /* Exigimos cierto historial */
    WHERE intervalos_observados >= 3
)

SELECT
    patron_compra,

    COUNT(*) AS cantidad_clientes,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS pct_clientes,

    CAST(
        AVG(intervalo_promedio_meses)
        AS DECIMAL(10,2)
    ) AS intervalo_promedio,

    CAST(
        AVG(desvio_intervalo_meses)
        AS DECIMAL(10,2)
    ) AS desvio_promedio

FROM Clasificacion

GROUP BY patron_compra

ORDER BY cantidad_clientes DESC;

---------------------------

/* ============================================================
   EL CUBO
   ANALISIS DE FRECUENCIA / PERIODICIDAD DE COMPRA

   Objetivo:
   Abrir los clientes clasificados como "Compra Irregular"
   y entender cuál es realmente su ciclo habitual de compra.
   ============================================================ */

WITH MesesConCompra AS (

    SELECT
        codigo_cliente,
        periodo,

        DATEFROMPARTS(
            CAST(LEFT(periodo, 4) AS INT),
            CAST(RIGHT(periodo, 2) AS INT),
            1
        ) AS fecha_compra

    FROM sales.fact_cliente_mes

    WHERE compro = 1
),

/* ------------------------------------------------------------
   Compra anterior de cada cliente
   ------------------------------------------------------------ */

ComprasConAnterior AS (

    SELECT
        codigo_cliente,
        periodo,
        fecha_compra,

        LAG(fecha_compra) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_compra
        ) AS fecha_compra_anterior

    FROM MesesConCompra
),

/* ------------------------------------------------------------
   Intervalo entre compras
   ------------------------------------------------------------ */

Intervalos AS (

    SELECT
        codigo_cliente,
        periodo,

        DATEDIFF(
            MONTH,
            fecha_compra_anterior,
            fecha_compra
        ) AS intervalo_meses

    FROM ComprasConAnterior

    WHERE fecha_compra_anterior IS NOT NULL
),

/* ------------------------------------------------------------
   Métricas básicas por cliente
   ------------------------------------------------------------ */

MetricasBase AS (

    SELECT
        codigo_cliente,

        COUNT(*) AS intervalos_observados,

        AVG(intervalo_meses * 1.0)
            AS intervalo_promedio_meses,

        MIN(intervalo_meses)
            AS intervalo_minimo_meses,

        MAX(intervalo_meses)
            AS intervalo_maximo_meses,

        STDEV(intervalo_meses * 1.0)
            AS desvio_intervalo_meses,

        SUM(CASE WHEN intervalo_meses = 1 THEN 1 ELSE 0 END)
            AS intervalos_1_mes,

        SUM(CASE WHEN intervalo_meses = 2 THEN 1 ELSE 0 END)
            AS intervalos_2_meses,

        SUM(CASE WHEN intervalo_meses = 3 THEN 1 ELSE 0 END)
            AS intervalos_3_meses,

        SUM(CASE WHEN intervalo_meses BETWEEN 4 AND 6 THEN 1 ELSE 0 END)
            AS intervalos_4_6_meses,

        SUM(CASE WHEN intervalo_meses > 6 THEN 1 ELSE 0 END)
            AS intervalos_mas_6_meses

    FROM Intervalos

    GROUP BY codigo_cliente
),

/* ------------------------------------------------------------
   Mediana del intervalo por cliente
   ------------------------------------------------------------ */

Medianas AS (

    SELECT DISTINCT
        codigo_cliente,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY intervalo_meses
        ) OVER (
            PARTITION BY codigo_cliente
        ) AS intervalo_mediano_meses,

        PERCENTILE_CONT(0.25) WITHIN GROUP (
            ORDER BY intervalo_meses
        ) OVER (
            PARTITION BY codigo_cliente
        ) AS percentil_25_intervalo,

        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY intervalo_meses
        ) OVER (
            PARTITION BY codigo_cliente
        ) AS percentil_75_intervalo

    FROM Intervalos
),

/* ------------------------------------------------------------
   Unimos métricas
   ------------------------------------------------------------ */

ResumenCliente AS (

    SELECT
        b.codigo_cliente,

        b.intervalos_observados,

        CAST(
            b.intervalo_promedio_meses
            AS DECIMAL(10,2)
        ) AS intervalo_promedio_meses,

        CAST(
            m.intervalo_mediano_meses
            AS DECIMAL(10,2)
        ) AS intervalo_mediano_meses,

        b.intervalo_minimo_meses,
        b.intervalo_maximo_meses,

        CAST(
            b.desvio_intervalo_meses
            AS DECIMAL(10,2)
        ) AS desvio_intervalo_meses,

        CAST(
            m.percentil_25_intervalo
            AS DECIMAL(10,2)
        ) AS percentil_25_intervalo,

        CAST(
            m.percentil_75_intervalo
            AS DECIMAL(10,2)
        ) AS percentil_75_intervalo,

        b.intervalos_1_mes,
        b.intervalos_2_meses,
        b.intervalos_3_meses,
        b.intervalos_4_6_meses,
        b.intervalos_mas_6_meses,

        CAST(
            b.intervalos_1_mes * 100.0 /
            NULLIF(b.intervalos_observados,0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_1_mes,

        CAST(
            b.intervalos_2_meses * 100.0 /
            NULLIF(b.intervalos_observados,0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_2_meses,

        CAST(
            b.intervalos_3_meses * 100.0 /
            NULLIF(b.intervalos_observados,0)
            AS DECIMAL(10,2)
        ) AS pct_intervalos_3_meses

    FROM MetricasBase b

    INNER JOIN Medianas m
        ON b.codigo_cliente = m.codigo_cliente

    WHERE b.intervalos_observados >= 3
),

/* ------------------------------------------------------------
   Reproducimos la clasificación anterior
   ------------------------------------------------------------ */

PatronOriginal AS (

    SELECT
        *,

        CASE

            WHEN pct_intervalos_1_mes >= 60
                THEN 'Compra Mensual'

            WHEN pct_intervalos_2_meses >= 60
                THEN 'Compra Bimestral'

            WHEN pct_intervalos_3_meses >= 60
                THEN 'Compra Trimestral'

            ELSE 'Compra Irregular'

        END AS patron_compra

    FROM ResumenCliente
),

/* ------------------------------------------------------------
   Abrimos solamente los IRREGULARES según su mediana
   ------------------------------------------------------------ */

Irregulares AS (

    SELECT
        *,

        CASE

            WHEN intervalo_mediano_meses <= 1
                THEN 'Habitualmente cada 1 mes'

            WHEN intervalo_mediano_meses <= 2
                THEN 'Habitualmente cada 2 meses'

            WHEN intervalo_mediano_meses <= 3
                THEN 'Habitualmente cada 3 meses'

            WHEN intervalo_mediano_meses <= 4
                THEN 'Habitualmente cada 4 meses'

            WHEN intervalo_mediano_meses <= 6
                THEN 'Habitualmente cada 5-6 meses'

            ELSE
                'Compra muy esporadica'

        END AS frecuencia_habitual

    FROM PatronOriginal

    WHERE patron_compra = 'Compra Irregular'
)

/* ============================================================
   RESULTADO
   ============================================================ */

SELECT
    frecuencia_habitual,

    COUNT(*) AS cantidad_clientes,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,2)
    ) AS pct_irregulares,

    CAST(
        AVG(intervalo_promedio_meses)
        AS DECIMAL(10,2)
    ) AS intervalo_promedio,

    CAST(
        AVG(intervalo_mediano_meses)
        AS DECIMAL(10,2)
    ) AS intervalo_mediano_promedio,

    CAST(
        AVG(desvio_intervalo_meses)
        AS DECIMAL(10,2)
    ) AS desvio_promedio,

    CAST(
        AVG(percentil_25_intervalo)
        AS DECIMAL(10,2)
    ) AS p25_promedio,

    CAST(
        AVG(percentil_75_intervalo)
        AS DECIMAL(10,2)
    ) AS p75_promedio

FROM Irregulares

GROUP BY frecuencia_habitual

ORDER BY
    CASE frecuencia_habitual
        WHEN 'Habitualmente cada 1 mes' THEN 1
        WHEN 'Habitualmente cada 2 meses' THEN 2
        WHEN 'Habitualmente cada 3 meses' THEN 3
        WHEN 'Habitualmente cada 4 meses' THEN 4
        WHEN 'Habitualmente cada 5-6 meses' THEN 5
        WHEN 'Compra muy esporadica' THEN 6
    END;







    /* ============================================================
   EL CUBO
   ESTADO DE INACTIVIDAD VS CICLO HABITUAL DE COMPRA

   Periodo base: 202608
   ============================================================ */

WITH MesesConCompra AS (

    SELECT
        codigo_cliente,
        periodo,

        DATEFROMPARTS(
            CAST(LEFT(periodo, 4) AS INT),
            CAST(RIGHT(periodo, 2) AS INT),
            1
        ) AS fecha_compra

    FROM sales.fact_cliente_mes

    WHERE compro = 1
      AND periodo <= '202608'
),

/* ============================================================
   1. CALCULAMOS INTERVALOS ENTRE COMPRAS
   ============================================================ */

ComprasConAnterior AS (

    SELECT
        codigo_cliente,
        periodo,
        fecha_compra,

        LAG(fecha_compra) OVER (
            PARTITION BY codigo_cliente
            ORDER BY fecha_compra
        ) AS fecha_compra_anterior

    FROM MesesConCompra
),

Intervalos AS (

    SELECT
        codigo_cliente,

        DATEDIFF(
            MONTH,
            fecha_compra_anterior,
            fecha_compra
        ) AS intervalo_meses

    FROM ComprasConAnterior

    WHERE fecha_compra_anterior IS NOT NULL
),

/* ============================================================
   2. MEDIANA Y P75 DEL CICLO DE CADA CLIENTE
   ============================================================ */

DistribucionIntervalos AS (

    SELECT DISTINCT
        codigo_cliente,

        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY intervalo_meses
        ) OVER (
            PARTITION BY codigo_cliente
        ) AS intervalo_mediano,

        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY intervalo_meses
        ) OVER (
            PARTITION BY codigo_cliente
        ) AS intervalo_p75,

        COUNT(*) OVER (
            PARTITION BY codigo_cliente
        ) AS intervalos_observados

    FROM Intervalos
),

/* ============================================================
   3. ÚLTIMA COMPRA HASTA EL PERÍODO BASE
   ============================================================ */

UltimaCompra AS (

    SELECT
        codigo_cliente,

        MAX(
            CASE
                WHEN compro = 1 THEN periodo
            END
        ) AS ultima_compra_periodo

    FROM sales.fact_cliente_mes

    WHERE periodo <= '202608'

    GROUP BY codigo_cliente
),

/* ============================================================
   4. MESES DESDE ÚLTIMA COMPRA
   ============================================================ */

SituacionActual AS (

    SELECT
        u.codigo_cliente,
        u.ultima_compra_periodo,

        DATEDIFF(
            MONTH,

            DATEFROMPARTS(
                CAST(LEFT(u.ultima_compra_periodo,4) AS INT),
                CAST(RIGHT(u.ultima_compra_periodo,2) AS INT),
                1
            ),

            CAST('20260801' AS DATE)

        ) AS meses_inactivo

    FROM UltimaCompra u

    WHERE u.ultima_compra_periodo IS NOT NULL
),

/* ============================================================
   5. ESTADO TRADICIONAL DEL CUBO
   ============================================================ */

EstadoCubo AS (

    SELECT
        *,

        CASE

            WHEN meses_inactivo = 0
                THEN 'Activo'

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

    FROM SituacionActual
),

/* ============================================================
   6. CRUZAMOS ESTADO ACTUAL CON CICLO HISTÓRICO
   ============================================================ */

EvaluacionCiclo AS (

    SELECT
        e.codigo_cliente,
        e.ultima_compra_periodo,
        e.meses_inactivo,
        e.estado_cubo,

        CAST(
            d.intervalo_mediano
            AS DECIMAL(10,2)
        ) AS ciclo_mediano,

        CAST(
            d.intervalo_p75
            AS DECIMAL(10,2)
        ) AS ciclo_p75,

        d.intervalos_observados,

        CAST(
            e.meses_inactivo /
            NULLIF(d.intervalo_mediano,0)
            AS DECIMAL(10,2)
        ) AS ciclos_transcurridos,

        CASE

            WHEN e.meses_inactivo <= d.intervalo_mediano
                THEN 'Dentro de ciclo'

            WHEN e.meses_inactivo <= d.intervalo_p75
                THEN 'Alerta de ciclo'

            WHEN e.meses_inactivo <= d.intervalo_p75 * 1.5
                THEN 'Atrasado'

            ELSE 'Muy atrasado'

        END AS situacion_ciclo

    FROM EstadoCubo e

    INNER JOIN DistribucionIntervalos d
        ON e.codigo_cliente = d.codigo_cliente

    /* Mantenemos el mismo mínimo de evidencia */
    WHERE d.intervalos_observados >= 3

),

/* ============================================================
   7. NOS CONCENTRAMOS EN LOS INACTIVOS
   ============================================================ */

Inactivos AS (

    SELECT *
    FROM EvaluacionCiclo

    WHERE estado_cubo IN (
        'En Pausa',
        'Infiel',
        'Dormido',
        'Reconquista',
        'Perdida Nivel 1',
        'Perdida Nivel 2'
    )
)

/* ============================================================
   RESULTADO FINAL
   ============================================================ */

SELECT
    estado_cubo,
    situacion_ciclo,

    COUNT(*) AS cantidad_clientes,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (
            PARTITION BY estado_cubo
        )
        AS DECIMAL(10,2)
    ) AS pct_dentro_estado,

    CAST(
        AVG(meses_inactivo * 1.0)
        AS DECIMAL(10,2)
    ) AS meses_inactivo_promedio,

    CAST(
        AVG(ciclo_mediano)
        AS DECIMAL(10,2)
    ) AS ciclo_mediano_promedio,

    CAST(
        AVG(ciclo_p75)
        AS DECIMAL(10,2)
    ) AS ciclo_p75_promedio,

    CAST(
        AVG(ciclos_transcurridos)
        AS DECIMAL(10,2)
    ) AS ciclos_transcurridos_promedio

FROM Inactivos

GROUP BY
    estado_cubo,
    situacion_ciclo

ORDER BY

    CASE estado_cubo
        WHEN 'En Pausa' THEN 1
        WHEN 'Infiel' THEN 2
        WHEN 'Dormido' THEN 3
        WHEN 'Reconquista' THEN 4
        WHEN 'Perdida Nivel 1' THEN 5
        WHEN 'Perdida Nivel 2' THEN 6
    END,

    CASE situacion_ciclo
        WHEN 'Dentro de ciclo' THEN 1
        WHEN 'Alerta de ciclo' THEN 2
        WHEN 'Atrasado' THEN 3
        WHEN 'Muy atrasado' THEN 4
    END;