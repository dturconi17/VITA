
import { NextRequest, NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";

export async function POST(req: NextRequest) {
  try {
    const { desde, hasta } = await req.json();

    const periodoValido = (p: unknown) =>
      typeof p === "string" &&
      /^\d{6}$/.test(p) &&
      p.slice(4) >= "01" &&
      p.slice(4) <= "12";

    if (
      !periodoValido(desde) ||
      !periodoValido(hasta) ||
      desde > hasta
    ) {
      return NextResponse.json(
        { error: "Períodos inválidos." },
        { status: 400 }
      );
    }

    const pool = await getConnection();

    const result = await pool
      .request()
      .input("desde", desde)
      .input("hasta", hasta)
      .query(`
        SELECT
          periodo,
          COALESCE(
            estado_cubo,
            'Sin clasificación'
          ) AS estado,
          COUNT(DISTINCT codigo_cliente) AS cantidad
        FROM sales.maestro_cliente_mes
        WHERE periodo BETWEEN @desde AND @hasta
        GROUP BY
          periodo,
          COALESCE(
            estado_cubo,
            'Sin clasificación'
          )
        ORDER BY periodo, estado;
      `);

    return NextResponse.json({
      datos: result.recordset,
    });
  } catch (error) {
    console.error("Error evolución clientes:", error);

    return NextResponse.json(
      { error: "No fue posible obtener la evolución." },
      { status: 500 }
    );
  }
}
