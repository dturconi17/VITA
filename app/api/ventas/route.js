import { getConnection } from "../../../lib/sqlserver";
import { createClient } from "@supabase/supabase-js";
import { buildFiltroVendedores } from "@/lib/sql/filtros";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// =====================================
// 🟣 FILTRO VENDEDOR
// =====================================
export function buildFiltroVendedor(vendedor) {
  if (!vendedor || vendedor === "todo") return "";

  const limpio = vendedor
    .trim()
    .replace(/'/g, "''")
    .toUpperCase();

  return `
    AND UPPER(LTRIM(RTRIM(v.nombre_vendedor))) 
    COLLATE Latin1_General_CI_AI = '${limpio}'
  `;
}

// =====================================
// 🚀 API
// =====================================
export async function GET(req) {
  try {
    const { searchParams } = new URL(req.url);

    const modo = searchParams.get("modo");

    const supervision = searchParams.get("supervision") || "todo";
    const vendedor = searchParams.get("vendedor") || "todo";

    // 🔥 filtros dinámicos
    const filtroSupervision = await buildFiltroVendedores({
      supabase,
      supervision,
    });

    const filtroVendedor = buildFiltroVendedor(vendedor);

    const filtroFinal = `
      ${filtroSupervision}
      ${filtroVendedor}
    `;

    const pool = await getConnection();

    // =====================================================
    // 🟣 CLIENTES POR MES (TAM)
    // =====================================================
    if (modo === "clientes") {
      console.log("Ejecutando consulta de clientes por mes con filtro:", filtroFinal);
      const result = await pool.request().query(`
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
            ${filtroFinal}
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
      `);

      return Response.json(result.recordset);
    }

    // =====================================================
    // 🟢 STICKINESS
    // =====================================================
    if (modo === "stickiness") {
      const result = await pool.request().query(`
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
          FROM sales.v_venta_total v
          WHERE 
            v.estado_factura = 'V'
            ${filtroFinal}
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
            p.mes_num,
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

          GROUP BY p.TAM, p.orden, p.mes_label, p.anio_real, p.mes_num
        )

        SELECT
          TAM,
          orden,
          mes_label,
          anio_real,
          DATEFROMPARTS(anio_real, mes_num, 1) as fecha_orden,
          ISNULL(stickiness, 0) as stickiness
        FROM stickiness_calc
        ORDER BY orden, fecha_orden
      `);

      return Response.json(result.recordset);
    }

    // =====================================================
    // 🟡 RETENCIÓN TAM
    // =====================================================
    if (modo === "retencion_tam") {
      const result = await pool.request().query(`
        WITH tams AS (
          SELECT
            TAM,
            TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT) as anio_inicio,
            ROW_NUMBER() OVER (
              ORDER BY TRY_CAST(LEFT(SUBSTRING(TAM, 5, 9), 4) AS INT)
            ) as orden_tam
          FROM (
            SELECT DISTINCT 
              UPPER(LTRIM(RTRIM(TAM))) as TAM
            FROM sales.v_venta_total v
            WHERE estado_factura = 'V'
            ${filtroFinal}
          ) t
        ),

        clientes_tam AS (
          SELECT DISTINCT
            UPPER(LTRIM(RTRIM(TAM))) as TAM,
            codigo_cliente
          FROM sales.v_venta_total v
          WHERE estado_factura = 'V'
          ${filtroFinal}
        ),

        retencion AS (
          SELECT
            tcurr.TAM,
            tcurr.orden_tam,

            (
              SELECT COUNT(DISTINCT codigo_cliente)
              FROM clientes_tam
              WHERE TAM = tprev.TAM
            ) as clientes_prev,

            (
              SELECT COUNT(DISTINCT p.codigo_cliente)
              FROM clientes_tam p
              INNER JOIN clientes_tam c
                ON p.codigo_cliente = c.codigo_cliente
              WHERE p.TAM = tprev.TAM
                AND c.TAM = tcurr.TAM
            ) as retenidos,

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
        ORDER BY orden_tam
      `);

      return Response.json(result.recordset);
    }














    
    // =====================================================
    // 🔴 REGION
    // =====================================================
    if (modo === "region") {
      const result = await pool.request().query(`
        SELECT 
          r.region,
          ISNULL(SUM(CASE WHEN v.TAM = 'TAM 2023/2024' THEN v.total_venta END), 0) as tam_2324,
          ISNULL(SUM(CASE WHEN v.TAM = 'TAM 2024/2025' THEN v.total_venta END), 0) as tam_2425,
          ISNULL(SUM(CASE WHEN v.TAM = 'TAM 2025/2026' THEN v.total_venta END), 0) as tam_2526
        FROM (
          SELECT DISTINCT ciudad_cliente as region
          FROM sales.v_venta_total
        ) r
        LEFT JOIN sales.v_venta_total v
          ON r.region = v.ciudad_cliente
          AND v.estado_factura = 'V'
        GROUP BY r.region
        ORDER BY r.region
      `); 

      return Response.json(result.recordset);
    }

    // =====================================================
    // 🔹 KPIs
    // =====================================================
    const kpisResult = await pool.request().query(`
      SELECT 
        COUNT(DISTINCT(nro_fac_ndc)) as cnt_facturas,
        COUNT(*) as transacciones,
        SUM(total_neto) as total_neto
      FROM dw.fact_ventas
      ${filtro}
    `);

    if (modo !== "dashboard") {
      return Response.json(kpisResult.recordset[0]);
    }

    // =====================================================
    // 🔹 SERIES
    // =====================================================
    const seriesResult = await pool.request().query(`
      SELECT 
        CAST(fecha as date) as fecha,
        SUM(total_neto) as total_neto
      FROM dw.fact_ventas
      ${filtro}
      GROUP BY CAST(fecha as date)
      ORDER BY fecha
    `);

    return Response.json({
      kpis: kpisResult.recordset[0],
      series: seriesResult.recordset,
    });

  } catch (error) {
    console.error(error);
    return Response.json(
      { error: error.message },
      { status: 500 }
    );
  }
}