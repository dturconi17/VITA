"use client";

import { ResumenRetencion } from "../types";

type Props = {
  resumen: ResumenRetencion;
  desde: string;
  hasta: string;
};

export default function KPICards({
  resumen,
  desde,
  hasta,
}: Props) {
 const cards = [
  {
    titulo: `Clientes ${desde}`,
    valor: resumen.clientes_mes_desde,
  },
  {
    titulo: `Clientes ${hasta}`,
    valor: resumen.clientes_mes,
  },
  {
    titulo: "Se mantienen",
    valor: resumen.activos,
  },
  {
    titulo: "Attrition",
    valor: resumen.perdidos,
  },
  {
    titulo: "Clientes Nuevos",
    valor: resumen.recuperados,
  },
];

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(5,1fr)",
        gap: 15,
        marginBottom: 25,
      }}
    >
      {cards.map((c) => (
        <div
          key={c.titulo}
          style={{
            border: "1px solid #ddd",
            borderRadius: 8,
            padding: 20,
            textAlign: "center",
          }}
        >
          <h3>{c.titulo}</h3>

          <h1>
  {(c.valor ?? 0).toLocaleString()}
</h1>
        </div>
      ))}
    </div>
  );
}