import { getConnection } from "../../../lib/sqlserver";

export async function GET(req) {
  try {
    const { searchParams } = new URL(req.url);

    const dias = searchParams.get("dias");
    const desde = searchParams.get("desde");
    const hasta = searchParams.get("hasta");
    const modo = searchParams.get("modo"); // 👈 clave nueva

    const pool = await getConnection();

    // 🔹 Construir filtro dinámico
    let filtro = "";

    if (desde && hasta) {
      filtro = `WHERE fecha BETWEEN '${desde}' AND '${hasta}'`;
    } else if (dias) {
      filtro = `WHERE fecha >= DATEADD(day, -${dias}, GETDATE())`;
    } else {
      filtro = `WHERE fecha >= DATEADD(day, -1, GETDATE())`;
    }

    // 🔹 KPIs (SIEMPRE)
    const kpisResult = await pool.request().query(`
      SELECT 
        COUNT(DISTINCT(nro_fac_ndc)) as cnt_facturas,
        COUNT(*) as transacciones,
        SUM(total_neto) as total_neto
      FROM dw.fact_ventas
      ${filtro}
    `);

    // 🔹 Si NO es dashboard → devolver solo KPIs (compatibilidad)
    if (modo !== "dashboard") {
      return Response.json(kpisResult.recordset[0]);
    }

    // 🔹 Serie (solo para dashboard)
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
    return Response.json({ error: "Error" }, { status: 500 });
  }
}