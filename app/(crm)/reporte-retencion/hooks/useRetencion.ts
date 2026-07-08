"use client";

import { useEffect, useState } from "react";
import { ResumenRetencion } from "../types";

export function useRetencion() {
    const [periodos, setPeriodos] = useState<string[]>([]);
    const [desde, setDesde] = useState("");
    const [hasta, setHasta] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");
    const [data, setData] = useState<ResumenRetencion | null>(null);


    async function cargarPeriodos() {

        try {
            const response = await fetch(
                "/api/reporte-retencion/periodos"
            );

            if (!response.ok)
                throw new Error("Error obteniendo períodos");


            const json = await response.json();


            // SQL Server devuelve [{periodo:"2024-01"}]
            setPeriodos(
                json.map((x: { periodo: string }) => x.periodo)
            );


        } catch (err) {

            console.error(err);

            setError("No fue posible cargar los períodos.");

        }

    }


    async function cargarReporte() {

        if (!desde || !hasta) return;


        try {

            setLoading(true);

            setError("");


            const response = await fetch(
                "/api/reporte-retencion",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        desde,
                        hasta,
                    }),
                }
            );


            if (!response.ok)
                throw new Error("Error obteniendo reporte.");


            const json = await response.json();


            setData(json.resumen);


        } catch (err) {

            console.error(err);

            setError(
                "No fue posible obtener el reporte."
            );


        } finally {

            setLoading(false);

        }

    }


    useEffect(() => {

        cargarPeriodos();

    }, []);



    return {
        data,
        periodos,
        loading,
        error,
        desde,
        hasta,
        setDesde,
        setHasta,
        recargar: cargarReporte,
    };
}