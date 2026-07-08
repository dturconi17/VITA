import { NextRequest, NextResponse } from "next/server";

import { getConnection } from "@/lib/sqlserver";

import { queryRetencion } from "@/lib/sql/reporte-retencion";

export async function POST(req: NextRequest) {

    try {

        const { desde, hasta } = await req.json();

        const pool = await getConnection();

        const result = await pool
            .request()
            .query(queryRetencion(desde, hasta));

        return NextResponse.json({

            resumen: result.recordset[0]

        });

    }

    catch (error) {

        console.error(error);

        return NextResponse.json(
            {
                error: "Error obteniendo reporte."
            },
            {
                status: 500
            }
        );

    }

}