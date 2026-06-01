import { NextResponse } from "next/server";
import sql from "mssql";

import { getConnection } from "@/lib/sqlserver";
import { queryKPIs } from "@/lib/sql/facturacion/kpis";

export async function GET(req) {

  try {

    const { searchParams } = new URL(req.url);

    const cliente = searchParams.get("cliente");

    const pool = await getConnection();

    const request = pool.request();

    let query = queryKPIs;

    // SOLO si viene cliente
    if (cliente && cliente !== "") {

      query += `
        AND nombre_cliente = @cliente
      `;

      request.input(
        "cliente",
        sql.VarChar,
        cliente
      );
    }

    console.log(query);

    const result = await request.query(query);

    return NextResponse.json(
      result.recordset[0]
    );

  } catch (error) {

    console.error(error);

    return NextResponse.json(
      {
        error: error.message,
      },
      {
        status: 500,
      }
    );
  }
}