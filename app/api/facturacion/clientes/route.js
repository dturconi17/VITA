import { NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";
import { queryClientes } from "@/lib/sql/facturacion/clientes";

export async function GET() {
  try {
    const pool = await getConnection();

    const result = await pool
      .request()
      .query(queryClientes);

    return NextResponse.json(result.recordset);

  } catch (error) {
    console.error(error);

    return NextResponse.json(
      { error: "Error obteniendo clientes" },
      { status: 500 }
    );
  }
}