import { NextRequest, NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";

import { queryTicketPromedioSegmentos } from "@/lib/sql/ticket-promedio/segmentos";
import { buildFiltrosReporte } from "@/lib/sql/filtros";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);

    const anio = searchParams.get("anio") || "";
    const cliente = searchParams.get("cliente") || "";
    const vendedor = searchParams.get("vendedor") || "";
    const ciudad = searchParams.get("ciudad") || "";

    const filtros = await buildFiltrosReporte({
      anio,
      cliente,
      vendedor,
      ciudad,
      supervision: "",
      supabase: null,
    });

    const sql = queryTicketPromedioSegmentos.replace("{{FILTROS}}", filtros);

    const pool = await getConnection();

    const result = await pool.request().query(sql);

    console.log(result.recordset);

    return NextResponse.json(result.recordset);

  } catch (error) {
    console.error(error);

    return NextResponse.json(
      { error: "Error obteniendo KPIs" },
      { status: 500 }
    );
  }
}