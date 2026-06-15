import { NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";
import { queryFiltros } from "@/lib/sql/ticket-promedio/filtros";


export async function GET() {
  try {
    const pool = await getConnection();

    const result = await pool
      .request()
      .query(queryFiltros);

    const data = result.recordset[0];

    return NextResponse.json({
      clientes: JSON.parse(data.clientes || "[]"),
      vendedores: JSON.parse(data.vendedores || "[]"),
      ciudades: JSON.parse(data.ciudades || "[]"),
      anios: JSON.parse(data.anios || "[]"),
    });

  } catch (error) {
    console.error("Error filtros:", error);



    return NextResponse.json(
      { error: "Error obteniendo filtros" },
      { status: 500 }
    );
  }
}