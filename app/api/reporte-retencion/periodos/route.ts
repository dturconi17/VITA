import { NextResponse } from "next/server";

import { getConnection } from "@/lib/sqlserver";

import { queryPeriodos } from "@/lib/sql/reporte-retencion-periodos";

export async function GET() {

    try {

        const pool = await getConnection();

        const result = await pool
            .request()
            .query(queryPeriodos);

        return NextResponse.json(result.recordset);

    }

    catch (error) {

        console.error(error);

        return NextResponse.json(
            {
                error: "Error obteniendo períodos."
            },
            {
                status: 500
            }
        );

    }

}