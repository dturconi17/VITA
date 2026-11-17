
import { NextRequest, NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";
import { queryRetencion } from "@/lib/sql/reporte-retencion";

export async function POST(req: NextRequest) {
  try {
    const { desde, hasta } = await req.json();

    // Validar períodos YYYYMM
    const regex = /^\d{6}$/;

    if (
      typeof desde !== "string" ||
      typeof hasta !== "string" ||
      !regex.test(desde) ||
      !regex.test(hasta) ||
      desde.slice(4) < "01" ||
      desde.slice(4) > "12" ||
      hasta.slice(4) < "01" ||
      hasta.slice(4) > "12" ||
      desde >= hasta
    ) {
      return NextResponse.json(
        { error: "Períodos inválidos o mal ordenados." },
        { status: 400 }
      );
    }

    const pool = await getConnection();

    const result = await pool
      .request()
      .input("desde", desde)
      .input("hasta", hasta)
      .query(queryRetencion);

    // Devolver todas las farmacias
    return NextResponse.json({
      clientes: result.recordset
    });

  } catch (error) {
    console.error("Error migración clientes:", error);

    return NextResponse.json(
      { error: "Error obteniendo migración de clientes." },
      { status: 500 }
    );
  }
}
