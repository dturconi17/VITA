import { getConnection } from "@/lib/sqlserver";
import { queryFiltros } from "@/lib/sql/filtros/canales";

export async function GET() {
  try {
    const pool = await getConnection();

    const result = await pool.request().query(queryFiltros);

    return Response.json(result.recordset);
  } catch (error: any) {
    console.error(error);

    return Response.json(
      { error: error.message },
      { status: 500 }
    );
  }
}