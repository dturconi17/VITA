
"use client";

import { useCallback, useEffect, useState } from "react";
import type { ClienteMigracion } from "../types";

export function useRetencion() {
  const [periodos, setPeriodos] = useState<string[]>([]);
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [data, setData] = useState<ClienteMigracion[] | null>(
    null
  );

  // Obtener períodos disponibles
  useEffect(() => {
    async function cargarPeriodos() {
      try {
        const response = await fetch(
          "/api/reporte-retencion/periodos"
        );

        if (!response.ok) {
          throw new Error("Error obteniendo períodos");
        }

        const json: { periodo: string }[] =
          await response.json();

        const disponibles = json
          .map((x) => String(x.periodo))
          .sort()
          .reverse();

        setPeriodos(disponibles);

        // Seleccionar los dos meses más recientes
        if (disponibles.length >= 2) {
          setDesde(disponibles[1]);
          setHasta(disponibles[0]);
        }
      } catch (err) {
        console.error(err);
        setError("No fue posible cargar los períodos.");
      }
    }

    cargarPeriodos();
  }, []);

  // Consultar migración
  const cargarReporte = useCallback(async () => {
    if (!desde || !hasta) {
      setError("Seleccioná ambos períodos.");
      return;
    }

    if (desde >= hasta) {
      setError(
        "El período Desde debe ser anterior al período Hasta."
      );
      return;
    }

    try {
      setLoading(true);
      setError("");
      setData(null);

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

      const json = await response.json();

      if (!response.ok) {
        throw new Error(
          json.error || "Error obteniendo migración."
        );
      }

      // Validar que la API devuelva un array
      if (!Array.isArray(json.clientes)) {
        console.error(
          "Respuesta inesperada de la API:",
          json
        );

        throw new Error(
          "La API no devolvió un listado válido de clientes."
        );
      }

      setData(json.clientes);

    } catch (err) {
      console.error(err);

      setError(
        err instanceof Error
          ? err.message
          : "No fue posible obtener el reporte."
      );
    } finally {
      setLoading(false);
    }
  }, [desde, hasta]);

  return {
    data,
    periodos,
    desde,
    hasta,
    setDesde,
    setHasta,
    recargar: cargarReporte,
    loading,
    error,
  };
}
