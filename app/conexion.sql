--select * from dw.fact_ventas where fecha_registro > '2026-04-14'

select count(distinct(nro_fac_ndc)) as cnt_facturas, count(*) as transacciones, 
sum(total_bruto) total_bruto, sum(descuento) total_descuento, 
sum(total_neto) total_neto, sum(costo_venta) costo_venta, sum(monto_iva) iva, sum(monto_itr) itr, sum(monto_ieh) ieh 
from dw.fact_ventas where fecha = '2026-04-13'


select division, 
sum(case when gestion = 2024 then total_bruto end) bruto,
sum(case when gestion = 2024 then total_neto end) neto
from dw.fact_ventas
where gestion = 2024
group by division

select gestion, sum(total_bruto)
from dw.fact_ventas
group by gestion


select top 200 * from sales.v_venta_total
select distinct(nombre_vendedor) from sales.v_venta_total
select [año-mes], TAM, sum(total_venta) from sales.v_venta_total where estado_entrega = 'SI' group by [año-mes], tam order by tam asc

select ciudad_cliente, cast(sum(total_venta) as int)
from sales.v_venta_total where 
--estado_entrega = 'SI' and 
estado_factura = 'V'
and TAM = 'TAM 2023/2024' 
and [año-mes] in  ('2023-4','2023-5','2023-6','2023-7','2023-8','2023-9','2023-10','2023-11') 
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
group by ciudad_cliente

select ciudad_cliente as Region, 
cast(sum(case when TAM = 'TAM 2023/2024' then total_venta else 0 end) as int) as TAM_2324,
cast(sum(case when TAM = 'TAM 2024/2025' then total_venta else 0 end) as int) as TAM_2425,
cast(sum(case when TAM = 'TAM 2025/2026' then total_venta else 0 end) as int) as TAM_2425
from sales.v_venta_total where 
--estado_entrega = 'SI' and 
estado_factura = 'V'
and nombre_vendedor not in ('ANA MARIA AGUILAR SUAREZ')
and mes in (4,5,6,7,8,9,10,11)
group by ciudad_cliente


select top 100 * from sales.v_venta_total


select ciudad_cliente, cast(sum(total_venta) as int), cast(sum(total) as int)
from sales.v_venta_total 
where 
--estado_entrega = 'SI' and 
estado_factura = 'V'
and TAM = 'TAM 2025/2026' 
and [año-mes] in  ('2025-4','2025-5','2025-6','2025-7','2025-8','2025-9','2025-10','2025-11') 
group by ciudad_cliente

select top 100 * 
from sales.v_ventas

select min([año-mes]), MAX([año-mes])
from sales.v_ventas

select min([año-mes]), MAX([año-mes])
from sales.v_ventas_total

select min([año-mes]), MAX([año-mes])
from sales.v_venta_total

select count(distinct(codigo_cliente)), count(distinct(nombre_cliente))
from sales.v_venta_total 
where 
estado_factura = 'V'
and TAM = 'TAM 2024/2025' 
and [año-mes] = '2024-4'


select codigo_cliente, nombre_cliente, count(*) cantidad
from sales.v_venta_total 
where 
estado_factura = 'V'
and TAM = 'TAM 2024/2025' 
and [año-mes] = '2024-4'
group by codigo_cliente, nombre_cliente
order by codigo_cliente desc

select top 100 *
from sales.v_venta_total


select count(distinct(codigo_cliente)), count(distinct(nombre_cliente))
from sales.v_venta_total 
where 
estado_factura = 'V'
and TAM = 'TAM 2024/2025' 
and [año-mes] = '2024-4'


WITH base AS (
SELECT
    v.TAM,
    LEFT(v.[año-mes], 4) + '-' +
    RIGHT('0' + SUBSTRING(v.[año-mes], 6, 2), 2) as anio_mes,
    v.codigo_cliente
    , CAST(SUBSTRING(v.[año-mes], 6, 2) AS INT) as mes_num
  FROM sales.v_venta_total v
  WHERE 
    v.estado_factura = 'V'
    AND v.TAM IN (
    'TAM 2022/2023',  
    'TAM 2023/2024',
      'TAM 2024/2025',
      'TAM 2025/2026'
    )
),

clientes_mes AS (
  SELECT
    TAM,
    anio_mes,
    COUNT(DISTINCT codigo_cliente) as clientes
  FROM base
  GROUP BY TAM, anio_mes
),

ordenado AS (
  SELECT
    TAM,
    anio_mes,
    clientes,
    CASE 
  WHEN mes_num >= 4 THEN mes_num - 3
  ELSE mes_num + 9
END as mes_tam as mes_tam
  FROM clientes_mes
)

SELECT
  mes_tam,
  MAX(CASE WHEN TAM = 'TAM 2022/2023' THEN clientes END) as tam_2223,
  MAX(CASE WHEN TAM = 'TAM 2023/2024' THEN clientes END) as tam_2324,
  MAX(CASE WHEN TAM = 'TAM 2024/2025' THEN clientes END) as tam_2425,
  MAX(CASE WHEN TAM = 'TAM 2025/2026' THEN clientes END) as tam_2526

FROM ordenado
GROUP BY mes_tam
ORDER BY mes_tam



select DISTINCT([año-mes])
FROM sales.v_venta_total
  WHERE estado_factura = 'V'
    AND TAM = 'TAM 2022/2023'
  
WITH abril AS (
  SELECT DISTINCT codigo_cliente
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
    AND TAM = 'TAM 2022/2023'
    AND [año-mes] = '2022-7'
),

mayo AS (
  SELECT DISTINCT codigo_cliente
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
    AND TAM = 'TAM 2022/2023'
    AND [año-mes] = '2022-8'
),

SELECT 
  'Agosto' AS mes,
  COUNT(DISTINCT m.codigo_cliente) * 1.0 / 
  NULLIF(COUNT(DISTINCT a.codigo_cliente), 0) * 100 AS stickiness
FROM abril a
LEFT JOIN mayo m
  ON a.codigo_cliente = m.codigo_cliente;


WITH meses_base AS (
  SELECT 1 as orden, 'Abril 2022' as mes_label, '2022-4' as anio_mes UNION ALL
  SELECT 2, 'Mayo 2022', '2022-5' UNION ALL
  SELECT 3, 'Junio 2022', '2022-6' UNION ALL
  SELECT 4, 'Julio 2022', '2022-7' UNION ALL
  SELECT 5, 'Agosto 2022', '2022-8' UNION ALL
  SELECT 6, 'Septiembre 2022', '2022-9' UNION ALL
  SELECT 7, 'Octubre 2022', '2022-10' UNION ALL
  SELECT 8, 'Noviembre 2022', '2022-11' UNION ALL
  SELECT 9, 'Diciembre 2022', '2022-12' UNION ALL
  SELECT 10, 'Enero 2023', '2023-1' UNION ALL
  SELECT 11, 'Febrero 2023', '2023-2' UNION ALL
  SELECT 12, 'Marzo 2023', '2023-3'
),

clientes_mes AS (
  SELECT DISTINCT
    codigo_cliente,
    [año-mes] as anio_mes
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
    AND TAM = 'TAM 2022/2023'
),

pares AS (
  SELECT
    m.orden,
    m.mes_label,
    m.anio_mes,
    LAG(m.anio_mes) OVER (ORDER BY m.orden) as mes_anterior
  FROM meses_base m
),

stickiness_calc AS (
  SELECT
    p.orden,
    p.mes_label,
    'TAM 2022/2023' as TAM,

    COUNT(DISTINCT curr.codigo_cliente) * 1.0 /
    NULLIF(COUNT(DISTINCT prev.codigo_cliente), 0) * 100 as stickiness

  FROM pares p

  LEFT JOIN clientes_mes prev
    ON prev.anio_mes = p.mes_anterior

  LEFT JOIN clientes_mes curr
    ON curr.anio_mes = p.anio_mes
    AND curr.codigo_cliente = prev.codigo_cliente

  GROUP BY p.orden, p.mes_label
)

SELECT
  TAM,
  mes_label as mes,
  ISNULL(stickiness, 0) as stickiness
FROM stickiness_calc
ORDER BY orden;


WITH base AS (
          SELECT DISTINCT
            v.codigo_cliente,
            CASE 
              WHEN CAST(SUBSTRING(v.[año-mes], 6, 2) AS INT) >= 4 
              THEN CAST(SUBSTRING(v.[año-mes], 6, 2) AS INT) - 3
              ELSE CAST(SUBSTRING(v.[año-mes], 6, 2) AS INT) + 9
            END AS mes_tam
          FROM sales.v_venta_total v
          WHERE v.estado_factura = 'V'
        ),

        clientes_mes AS (
          SELECT DISTINCT mes_tam, codigo_cliente
          FROM base
        ),

        retencion AS (
          SELECT
            curr.mes_tam AS mes,
            COUNT(DISTINCT prev.codigo_cliente) AS clientes_prev,
            COUNT(DISTINCT CASE 
              WHEN prev.codigo_cliente IS NOT NULL THEN curr.codigo_cliente 
            END) AS retenidos
          FROM clientes_mes curr
          LEFT JOIN clientes_mes prev
            ON curr.codigo_cliente = prev.codigo_cliente
            AND prev.mes_tam = curr.mes_tam - 1
          GROUP BY curr.mes_tam
        )

        SELECT
          mes,
          CASE 
            WHEN clientes_prev = 0 THEN 0
            ELSE (retenidos * 1.0 / clientes_prev) * 100
          END AS stickiness
        FROM retencion
        ORDER BY mes


WITH meses_base AS (
  SELECT 1 as orden, 'Abril' as mes_label, 4 as mes_num UNION ALL
  SELECT 2, 'Mayo', 5 UNION ALL
  SELECT 3, 'Junio', 6 UNION ALL
  SELECT 4, 'Julio', 7 UNION ALL
  SELECT 5, 'Agosto', 8 UNION ALL
  SELECT 6, 'Septiembre', 9 UNION ALL
  SELECT 7, 'Octubre', 10 UNION ALL
  SELECT 8, 'Noviembre', 11 UNION ALL
  SELECT 9, 'Diciembre', 12 UNION ALL
  SELECT 10, 'Enero', 1 UNION ALL
  SELECT 11, 'Febrero', 2 UNION ALL
  SELECT 12, 'Marzo', 3
),

tams AS (
  SELECT 'TAM 2022/2023' as TAM, 2022 as anio_inicio, 1 as orden_tam UNION ALL
  SELECT 'TAM 2023/2024', 2023, 2 UNION ALL
  SELECT 'TAM 2024/2025', 2024, 3 UNION ALL
  SELECT 'TAM 2025/2026', 2025, 4
),

clientes_mes AS (
  SELECT DISTINCT
    TAM,
    codigo_cliente,
    CAST(SUBSTRING([año-mes], 6, 2) AS INT) as mes_num
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
),

base_completa AS (
  SELECT
    t.TAM,
    t.orden_tam,
    t.anio_inicio,
    m.orden,
    m.mes_label,
    m.mes_num,

    -- 🔥 calculamos el año real
    CASE 
      WHEN m.mes_num >= 4 THEN t.anio_inicio
      ELSE t.anio_inicio + 1
    END as anio_real

  FROM tams t
  CROSS JOIN meses_base m
),

pares AS (
  SELECT
    b.*,

    CASE 
      WHEN b.mes_num = 4 THEN 3
      WHEN b.mes_num = 1 THEN 12
      ELSE b.mes_num - 1
    END as mes_prev,

    CASE 
      WHEN b.mes_num = 4 THEN b.orden_tam - 1
      ELSE b.orden_tam
    END as tam_prev

  FROM base_completa b
),

stickiness_calc AS (
  SELECT
    p.TAM,
    p.orden,
    p.mes_label,
    p.anio_real,

    COUNT(DISTINCT curr.codigo_cliente) * 1.0 /
    NULLIF(COUNT(DISTINCT prev.codigo_cliente), 0) * 100 as stickiness

  FROM pares p

  LEFT JOIN tams tprev
    ON tprev.orden_tam = p.tam_prev

  LEFT JOIN clientes_mes prev
    ON prev.TAM = tprev.TAM
    AND prev.mes_num = p.mes_prev

  LEFT JOIN clientes_mes curr
    ON curr.TAM = p.TAM
    AND curr.mes_num = p.mes_num
    AND curr.codigo_cliente = prev.codigo_cliente

  GROUP BY p.TAM, p.orden, p.mes_label, p.anio_real
)

SELECT
  TAM,
  orden,
  mes_label,
  anio_real,

  -- 🔥 clave para ordenar
  DATEFROMPARTS(anio_real, 
    CASE 
      WHEN mes_label = 'Enero' THEN 1
      WHEN mes_label = 'Febrero' THEN 2
      WHEN mes_label = 'Marzo' THEN 3
      WHEN mes_label = 'Abril' THEN 4
      WHEN mes_label = 'Mayo' THEN 5
      WHEN mes_label = 'Junio' THEN 6
      WHEN mes_label = 'Julio' THEN 7
      WHEN mes_label = 'Agosto' THEN 8
      WHEN mes_label = 'Septiembre' THEN 9
      WHEN mes_label = 'Octubre' THEN 10
      WHEN mes_label = 'Noviembre' THEN 11
      WHEN mes_label = 'Diciembre' THEN 12
    END,
  1) as fecha_orden,

  ISNULL(stickiness, 0) as stickiness

FROM stickiness_calc
ORDER BY fecha_orden;


WITH meses_base AS (
  SELECT 1 as orden, 'Abril' as mes_label, 4 as mes_num UNION ALL
  SELECT 2, 'Mayo', 5 UNION ALL
  SELECT 3, 'Junio', 6 UNION ALL
  SELECT 4, 'Julio', 7 UNION ALL
  SELECT 5, 'Agosto', 8 UNION ALL
  SELECT 6, 'Septiembre', 9 UNION ALL
  SELECT 7, 'Octubre', 10 UNION ALL
  SELECT 8, 'Noviembre', 11 UNION ALL
  SELECT 9, 'Diciembre', 12 UNION ALL
  SELECT 10, 'Enero', 1 UNION ALL
  SELECT 11, 'Febrero', 2 UNION ALL
  SELECT 12, 'Marzo', 3
),

tams AS (
  SELECT 'TAM 2022/2023' as TAM, 2022 as anio_inicio, 1 as orden_tam UNION ALL
  SELECT 'TAM 2023/2024', 2023, 2 UNION ALL
  SELECT 'TAM 2024/2025', 2024, 3 UNION ALL
  SELECT 'TAM 2025/2026', 2025, 4
),

clientes_mes AS (
  SELECT DISTINCT
    TAM,
    codigo_cliente,
    CAST(SUBSTRING([año-mes], 6, 2) AS INT) as mes_num
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
),

base_completa AS (
  SELECT
    t.TAM,
    t.orden_tam,
    t.anio_inicio,
    m.orden,
    m.mes_label,
    m.mes_num,
    CASE 
      WHEN m.mes_num >= 4 THEN t.anio_inicio
      ELSE t.anio_inicio + 1
    END as anio_real
  FROM tams t
  CROSS JOIN meses_base m
),

pares AS (
  SELECT
    b.*,
    CASE 
      WHEN b.mes_num = 4 THEN 3
      WHEN b.mes_num = 1 THEN 12
      ELSE b.mes_num - 1
    END as mes_prev,
    CASE 
      WHEN b.mes_num = 4 THEN b.orden_tam - 1
      ELSE b.orden_tam
    END as tam_prev
  FROM base_completa b
),

stickiness_calc AS (
  SELECT
    p.TAM,
    p.orden,
    p.mes_label,
    p.anio_real,

    COUNT(DISTINCT curr.codigo_cliente) * 1.0 /
    NULLIF(COUNT(DISTINCT prev.codigo_cliente), 0) * 100 as stickiness

  FROM pares p

  LEFT JOIN tams tprev
    ON tprev.orden_tam = p.tam_prev

  LEFT JOIN clientes_mes prev
    ON prev.TAM = tprev.TAM
    AND prev.mes_num = p.mes_prev

  LEFT JOIN clientes_mes curr
    ON curr.TAM = p.TAM
    AND curr.mes_num = p.mes_num
    AND curr.codigo_cliente = prev.codigo_cliente

  GROUP BY p.TAM, p.orden, p.mes_label, p.anio_real
),

-- 🔥 NUEVO: TOTAL CLIENTES POR TAM
clientes_total AS (
  SELECT
    TAM,
    COUNT(DISTINCT codigo_cliente) as total_clientes
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
  GROUP BY TAM
)

-- 🔵 RESULTADO FINAL
SELECT
  TAM,
  orden,
  mes_label,
  anio_real,

  DATEFROMPARTS(anio_real, 
    CASE 
      WHEN mes_label = 'Enero' THEN 1
      WHEN mes_label = 'Febrero' THEN 2
      WHEN mes_label = 'Marzo' THEN 3
      WHEN mes_label = 'Abril' THEN 4
      WHEN mes_label = 'Mayo' THEN 5
      WHEN mes_label = 'Junio' THEN 6
      WHEN mes_label = 'Julio' THEN 7
      WHEN mes_label = 'Agosto' THEN 8
      WHEN mes_label = 'Septiembre' THEN 9
      WHEN mes_label = 'Octubre' THEN 10
      WHEN mes_label = 'Noviembre' THEN 11
      WHEN mes_label = 'Diciembre' THEN 12
    END,
  1) as fecha_orden,

  ISNULL(stickiness, 0) as stickiness,
  NULL as total_clientes

FROM stickiness_calc

UNION ALL

-- 🔥 FILA TOTAL
SELECT
  TAM,
  99 as orden,
  'TOTAL' as mes_label,
  NULL as anio_real,
  NULL as fecha_orden,
  NULL as stickiness,
  total_clientes
FROM clientes_total

ORDER BY TAM, fecha_orden, orden;


WITH meses_base AS (
  SELECT 1 as orden, 'Abril' as mes_label, 4 as mes_num UNION ALL
  SELECT 2, 'Mayo', 5 UNION ALL
  SELECT 3, 'Junio', 6 UNION ALL
  SELECT 4, 'Julio', 7 UNION ALL
  SELECT 5, 'Agosto', 8 UNION ALL
  SELECT 6, 'Septiembre', 9 UNION ALL
  SELECT 7, 'Octubre', 10 UNION ALL
  SELECT 8, 'Noviembre', 11 UNION ALL
  SELECT 9, 'Diciembre', 12 UNION ALL
  SELECT 10, 'Enero', 1 UNION ALL
  SELECT 11, 'Febrero', 2 UNION ALL
  SELECT 12, 'Marzo', 3
),

tams AS (
  SELECT
    TAM,
    TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT) as anio_inicio,
    ROW_NUMBER() OVER (
      ORDER BY TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT)
    ) as orden_tam
  FROM (
    SELECT DISTINCT LTRIM(RTRIM(TAM)) as TAM
    FROM sales.v_venta_total
    WHERE estado_factura = 'V'
  ) t
),

clientes_mes AS (
  SELECT DISTINCT
    TAM,
    codigo_cliente,
    CAST(SUBSTRING([año-mes], 6, 2) AS INT) as mes_num
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
),

base_completa AS (
  SELECT
    t.TAM,
    t.orden_tam,
    t.anio_inicio,
    m.orden,
    m.mes_label,
    m.mes_num,
    CASE 
      WHEN m.mes_num >= 4 THEN t.anio_inicio
      ELSE t.anio_inicio + 1
    END as anio_real
  FROM tams t
  CROSS JOIN meses_base m
),

pares AS (
  SELECT
    b.*,
    CASE 
      WHEN b.mes_num = 4 THEN 3
      WHEN b.mes_num = 1 THEN 12
      ELSE b.mes_num - 1
    END as mes_prev,
    CASE 
      WHEN b.mes_num = 4 THEN b.orden_tam - 1
      ELSE b.orden_tam
    END as tam_prev
  FROM base_completa b
),

stickiness_calc AS (
  SELECT
    p.TAM,
    p.orden,
    p.mes_label,
    p.anio_real,

    COUNT(DISTINCT curr.codigo_cliente) * 1.0 /
    NULLIF(COUNT(DISTINCT prev.codigo_cliente), 0) * 100 as stickiness

  FROM pares p

  LEFT JOIN tams tprev
    ON tprev.orden_tam = p.tam_prev

  LEFT JOIN clientes_mes prev
    ON prev.TAM = tprev.TAM
    AND prev.mes_num = p.mes_prev

  LEFT JOIN clientes_mes curr
    ON curr.TAM = p.TAM
    AND curr.mes_num = p.mes_num
    AND curr.codigo_cliente = prev.codigo_cliente

  GROUP BY p.TAM, p.orden, p.mes_label, p.anio_real
),
-- 🔥 NUEVO: TOTAL CLIENTES POR TAM
clientes_total AS (
  SELECT
    TAM,
    COUNT(DISTINCT codigo_cliente) as total_clientes
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
  GROUP BY TAM
)
, clientes_tam AS (
  SELECT DISTINCT
    TAM,
    codigo_cliente
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
),

retencion_tam AS (
  SELECT
    tcurr.TAM,
    tcurr.orden_tam,

    -- 🔥 TOTAL TAM ANTERIOR (SIEMPRE EXISTE SI HAY DATOS)
    (
      SELECT COUNT(DISTINCT codigo_cliente)
      FROM clientes_tam
      WHERE TAM = tprev.TAM
    ) as clientes_prev,

    -- 🔥 INTERSECCION REAL
    (
      SELECT COUNT(DISTINCT p.codigo_cliente)
      FROM clientes_tam p
      INNER JOIN clientes_tam c
        ON p.codigo_cliente = c.codigo_cliente
      WHERE p.TAM = tprev.TAM
        AND c.TAM = tcurr.TAM
    ) as retenidos

  FROM tams tcurr

  LEFT JOIN tams tprev
    ON tprev.orden_tam = tcurr.orden_tam - 1
),
retencion_final AS (
  SELECT
    TAM,
    CASE 
      WHEN clientes_prev IS NULL THEN NULL
      WHEN clientes_prev = 0 THEN 0
      ELSE (retenidos * 1.0 / clientes_prev) * 100
    END as retencion
  FROM retencion_tam
)

-- 🔵 RESULTADO FINAL
SELECT
  TAM,
  orden,
  mes_label,
  anio_real,

  DATEFROMPARTS(anio_real, 
    CASE 
      WHEN mes_label = 'Enero' THEN 1
      WHEN mes_label = 'Febrero' THEN 2
      WHEN mes_label = 'Marzo' THEN 3
      WHEN mes_label = 'Abril' THEN 4
      WHEN mes_label = 'Mayo' THEN 5
      WHEN mes_label = 'Junio' THEN 6
      WHEN mes_label = 'Julio' THEN 7
      WHEN mes_label = 'Agosto' THEN 8
      WHEN mes_label = 'Septiembre' THEN 9
      WHEN mes_label = 'Octubre' THEN 10
      WHEN mes_label = 'Noviembre' THEN 11
      WHEN mes_label = 'Diciembre' THEN 12
    END,
  1) as fecha_orden,

  ISNULL(stickiness, 0) as stickiness,
  NULL as total_clientes

FROM stickiness_calc

UNION ALL

-- 🔥 FILA TOTAL + RETENCION TAM
SELECT
  t.TAM,
  99 as orden,
  'TOTAL' as mes_label,
  NULL as anio_real,
  NULL as fecha_orden,
  r.retencion as stickiness,   -- 👈 reutilizamos columna
  t.total_clientes
FROM clientes_total t
LEFT JOIN retencion_final r
  ON t.TAM = r.TAM














SELECT DISTINCT TAM, LEN(TAM)
FROM sales.v_venta_total
ORDER BY TAM



select distinct(codigo_cliente) from sales.v_venta_total
where TAM = 'TAM 2026/2027'





WITH tams AS (
  SELECT
    TAM,
    TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT) as anio_inicio,
    ROW_NUMBER() OVER (
      ORDER BY TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT)
    ) as orden_tam
  FROM (
    SELECT DISTINCT 
      UPPER(LTRIM(RTRIM(TAM))) as TAM   -- 👈 NORMALIZADO
    FROM sales.v_venta_total
    WHERE estado_factura = 'V'
  ) t
),

clientes_tam AS (
  SELECT DISTINCT
    UPPER(LTRIM(RTRIM(TAM))) as TAM,   -- 👈 NORMALIZADO
    codigo_cliente
  FROM sales.v_venta_total
  WHERE estado_factura = 'V'
),

retencion AS (
  SELECT
    tcurr.TAM,
    tcurr.orden_tam,

    -- total TAM anterior
    (
      SELECT COUNT(DISTINCT codigo_cliente)
      FROM clientes_tam
      WHERE TAM = tprev.TAM
    ) as clientes_prev,

    -- intersección
    (
      SELECT COUNT(DISTINCT p.codigo_cliente)
      FROM clientes_tam p
      INNER JOIN clientes_tam c
        ON p.codigo_cliente = c.codigo_cliente
      WHERE p.TAM = tprev.TAM
        AND c.TAM = tcurr.TAM
    ) as retenidos,

    -- total actual
    (
      SELECT COUNT(DISTINCT codigo_cliente)
      FROM clientes_tam
      WHERE TAM = tcurr.TAM
    ) as total_actual

  FROM tams tcurr

  LEFT JOIN tams tprev
    ON tprev.orden_tam = tcurr.orden_tam - 1
)

SELECT
  TAM,
  orden_tam,
  total_actual,

  CASE 
    WHEN clientes_prev IS NULL THEN NULL
    WHEN clientes_prev = 0 THEN 0
    ELSE (retenidos * 1.0 / clientes_prev) * 100
  END as retencion_vs_anterior

FROM retencion
ORDER BY orden_tam;


select distinct(nombre_vendedor) from sales.v_venta_total



WITH tams AS (
          SELECT 'TAM 2022/2023' as TAM, 2022 as anio_inicio UNION ALL
          SELECT 'TAM 2023/2024', 2023 UNION ALL
          SELECT 'TAM 2024/2025', 2024 UNION ALL
          SELECT 'TAM 2025/2026', 2025
        ),

        meses AS (
          SELECT 1 as mes_tam, 4 as mes UNION ALL
          SELECT 2, 5 UNION ALL
          SELECT 3, 6 UNION ALL
          SELECT 4, 7 UNION ALL
          SELECT 5, 8 UNION ALL
          SELECT 6, 9 UNION ALL
          SELECT 7, 10 UNION ALL
          SELECT 8, 11 UNION ALL
          SELECT 9, 12 UNION ALL
          SELECT 10, 1 UNION ALL
          SELECT 11, 2 UNION ALL
          SELECT 12, 3
        ),

        calendario AS (
          SELECT
            t.TAM,
            m.mes_tam,
            CASE 
              WHEN m.mes >= 4 THEN t.anio_inicio
              ELSE t.anio_inicio + 1
            END as anio,
            m.mes
          FROM tams t
          CROSS JOIN meses m
        ),

        base AS (
          SELECT
            v.TAM,
            CAST(LEFT(v.[año-mes],4) AS INT) as anio,
            CAST(SUBSTRING(v.[año-mes],6,2) AS INT) as mes,
            v.codigo_cliente
          FROM sales.v_venta_total v
          WHERE 
            v.estado_factura = 'V'
             AND UPPER(LTRIM(RTRIM(v.nombre_vendedor)))
    COLLATE Latin1_General_CI_AI = 'ABEL DIMAS ALI LIPA'
            AND v.TAM IN (
              'TAM 2022/2023',  
              'TAM 2023/2024',
              'TAM 2024/2025',
              'TAM 2025/2026'
            )
        ),

        clientes_mes AS (
          SELECT TAM, anio, mes, COUNT(DISTINCT codigo_cliente) as clientes
          FROM base
          GROUP BY TAM, anio, mes
        ),

        final AS (
          SELECT c.mes_tam, c.TAM, ISNULL(cm.clientes, 0) as clientes
          FROM calendario c
          LEFT JOIN clientes_mes cm
            ON cm.TAM = c.TAM
            AND cm.anio = c.anio
            AND cm.mes = c.mes
        )

        SELECT
          mes_tam,
          MAX(CASE WHEN TAM = 'TAM 2022/2023' THEN clientes END) as tam_2223,
          MAX(CASE WHEN TAM = 'TAM 2023/2024' THEN clientes END) as tam_2324,
          MAX(CASE WHEN TAM = 'TAM 2024/2025' THEN clientes END) as tam_2425,
          MAX(CASE WHEN TAM = 'TAM 2025/2026' THEN clientes END) as tam_2526
        FROM final
        GROUP BY mes_tam
        ORDER BY mes_tam

select top 100 * 
from sales.v_venta_total where 
--estado_entrega = 'SI' and 
estado_factura = 'V'

SELECT
codigo_cliente, nombre_cliente, TAM, [año-mes], total_venta
from sales.v_venta_total
WHERE estado_factura = 'V'


WITH ventas AS (
    SELECT
        codigo_cliente,
        nombre_cliente,
        TAM,
        [año-mes],
        SUM(total_venta) total_mes
    FROM sales.v_venta_total
    WHERE estado_factura = 'V'
    GROUP BY
        codigo_cliente,
        nombre_cliente,
        TAM,
        [año-mes]
)

SELECT *
FROM ventas


SELECT
    codigo_cliente,
    nombre_cliente,
    TAM,
    [año-mes],
    SUM(total_venta) total_venta
FROM sales.v_venta_total
WHERE estado_factura = 'V'
GROUP BY
    codigo_cliente,
    nombre_cliente,
    TAM,
    [año-mes]

    SELECT
    SUM(total_venta) total_facturacion,
    COUNT(DISTINCT codigo_cliente) clientes_activos,
    AVG(total_venta) ticket_promedio
FROM sales.v_venta_total
WHERE estado_factura = 'V'
AND TAM = 'TAM 2024/2025'


SELECT DISTINCT
    nombre_cliente
FROM sales.v_venta_total
WHERE estado_factura = 'V' 
and nombre_cliente IS NOT NULL 
and nombre_cliente <> '' 
and nombre_cliente NOT LIKE '%PRUEBA%'
and TAM in ('TAM 2024/2025','TAM 2025/2026)
ORDER BY nombre_cliente


SELECT
    *
FROM sales.v_venta_total
WHERE estado_factura = 'V'
AND TAM = 'TAM 2024/2025' and nombre_cliente = 'ABIGAIL CONTRERAS OLIVERA - FARMACIA  LEANDRO' order by id_sale_invoice desc





SELECT
  SUM(CASE WHEN TAM = 'TAM 2023/2024' THEN total_venta ELSE 0 END) AS facturacion_2023_24,
  SUM(CASE WHEN TAM = 'TAM 2024/2025' THEN total_venta ELSE 0 END) AS facturacion_2024_25,
  SUM(CASE WHEN TAM = 'TAM 2025/2026' THEN total_venta ELSE 0 END) AS facturacion_2025_26,
  COUNT(DISTINCT CASE WHEN TAM = 'TAM 2023/2024' THEN id_sale_invoice END) AS transacciones_2023_24,
  COUNT(DISTINCT CASE WHEN TAM = 'TAM 2024/2025' THEN id_sale_invoice END) AS transacciones_2024_25,
  COUNT(DISTINCT CASE WHEN TAM = 'TAM 2025/2026' THEN id_sale_invoice END) AS transacciones_2025_26
FROM sales.v_venta_total
WHERE estado_factura = 'V' and nombre_cliente like 'ADELA ALVARADO FLORES - FARMACIA %'


select 
  SUM(CASE WHEN Año = 2026 THEN total_venta ELSE 0 END) AS facturacion_2026,
  SUM(CASE WHEN Año = 2025 THEN total_venta ELSE 0 END) AS facturacion_2025,
  SUM(CASE WHEN Año = 2024 THEN total_venta ELSE 0 END) AS facturacion_2024,
  COUNT(DISTINCT CASE WHEN Año = 2026 THEN id_sale_invoice END) AS transacciones_2026,
  COUNT(DISTINCT CASE WHEN Año = 2025 THEN id_sale_invoice END) AS transacciones_2025,
  COUNT(DISTINCT CASE WHEN Año = 2024 THEN id_sale_invoice END) AS transacciones_2024
FROM sales.v_venta_total
WHERE estado_factura = 'V'
and nombre_cliente like 'ADELA ALVARADO FLORES - FARMACIA %'
and nombre_vendedor = 'ADOLFO CONDORI MENDEZ'


select *
FROM sales.v_venta_total
WHERE estado_factura = 'V' and nombre_cliente like 'ADELA ALVARADO FLORES - FARMACIA %' and año = 2025

'

SELECT
    YEAR(fecha_factura) AS anio,
    nombre_cliente,
    nombre_vendedor,
    ciudad_cliente,
    SUM(total_venta) AS facturacion
INTO sales.crm_ticket_promedio
FROM sales.v_venta_total
WHERE estado_factura = 'V'
GROUP BY
    YEAR(fecha_factura),
    nombre_cliente,
    nombre_vendedor,
    ciudad_cliente

select * from sales.crm_ticket_promedio


  SELECT 
    (SELECT DISTINCT nombre_cliente FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY nombre_cliente FOR JSON PATH) AS clientes,
    (SELECT DISTINCT nombre_vendedor FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY nombre_vendedor FOR JSON PATH) AS vendedores,
    (SELECT DISTINCT ciudad_cliente FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY ciudad_cliente FOR JSON PATH) AS ciudades,
    (SELECT DISTINCT YEAR(fecha_factura) AS anio FROM sales.v_venta_total WHERE estado_factura = 'V' ORDER BY anio DESC FOR JSON PATH) AS anios
  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER


  SELECT top 100 *
    FROM sales.v_venta_total v
WHERE v.estado_factura='V'


      AND UPPER(LTRIM(RTRIM(v.nombre_vendedor)))
      COLLATE Latin1_General_CI_AI = 'ABEL DIMAS ALI LIPA'
    
    AND YEAR(v.fecha_factura) = 2026
  
      AND UPPER(LTRIM(RTRIM(v.ciudad_cliente)))
      COLLATE Latin1_General_CI_AI =
      'EL ALTO'


SELECT
    v.nombre_cliente,
   id_sale_invoice, ciudad_cliente, fecha_factura, total_venta
FROM sales.v_venta_total v
WHERE v.estado_factura='V'

      AND UPPER(LTRIM(RTRIM(v.nombre_vendedor)))
      COLLATE Latin1_General_CI_AI = 'ABEL DIMAS ALI LIPA'
    
    AND YEAR(v.fecha_factura) = 2026
  
      AND UPPER(LTRIM(RTRIM(v.ciudad_cliente)))
      COLLATE Latin1_General_CI_AI =
      'EL ALTO'
    
GROUP BY
v.nombre_cliente
ORDER BY
facturacion DESC