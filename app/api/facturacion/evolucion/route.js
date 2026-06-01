import { NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";
import { queryEvolucionCliente } from "@/lib/sql/facturacion/evolucion";

export async function GET(req) {

  try {

    const { searchParams } = new URL(req.url);

    const cliente = searchParams.get("cliente");

    if (!cliente) {
      return NextResponse.json([]);
    }

    const pool = await getConnection();

    const result = await pool
      .request()
      .input("cliente", cliente)
      .query(queryEvolucionCliente);

    return NextResponse.json(result.recordset);

  } catch (error) {

    console.error(error);

    return NextResponse.json(
      { error: "Error obteniendo evolución" },
      { status: 500 }
    );
  }
}