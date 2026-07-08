"use client";

import Filtros from "./components/Filtros";
import KPICards from "./components/KPICards";

import { useRetencion } from "./hooks/useRetencion";

import ComparacionSegmentos from "./components/ComparacionSegmentos";

import { useComparacionSegmentos } 
from "./hooks/useComparacionSegmentos";

export default function ReporteRetencionPage() {
  const {
  comparacion,
  cargarComparacion
  } = useComparacionSegmentos();
  
  const {
    data,
    periodos,

    desde,
    hasta,

    setDesde,
    setHasta,

    recargar,

    loading,
    error,
  } = useRetencion();

  return (
    <div style={{ padding: 30 }}>

      <h1 style={{ marginBottom: 30 }}>
        Reporte de Retención de Clientes
      </h1>

<Filtros
  periodos={periodos}
  desde={desde}
  hasta={hasta}
  setDesde={setDesde}
  setHasta={setHasta}
  consultar={() => {

    recargar();

    cargarComparacion(
      desde,
      hasta
    );

  }}
/>

      {loading && (
        <p>Cargando información...</p>
      )}

      {error && (
        <p style={{ color: "red" }}>
          {error}
        </p>
      )}

      {data && (
        <>
          <KPICards
  resumen={data}
  desde={desde}
  hasta={hasta}
/>
        </>
      )}

    {
      comparacion.length > 0 && (

        <ComparacionSegmentos

          data={comparacion}

          desde={desde}

          hasta={hasta}

        />

      )
    }

    </div>
  );
}