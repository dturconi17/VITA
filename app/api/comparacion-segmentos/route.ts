import { NextRequest, NextResponse } from "next/server";
import { getConnection } from "@/lib/sqlserver";
import {
  queryComparacionSegmentos
} from "@/lib/sql/comparacion-segmentos";


export async function POST(req: NextRequest) {

  try {
    const {
      desde,
      hasta
    } = await req.json();

    const pool = await getConnection();

    const result =
      await pool
        .request()
        .query(
          queryComparacionSegmentos(
            desde,
            hasta
          )
        );


    return NextResponse.json(
      result.recordset
    );

  } catch(error) {

    console.error(error);

    return NextResponse.json(
      {
        error:"Error obteniendo comparación de segmentos"
      },
      {
        status:500
      }
    );

  }

}