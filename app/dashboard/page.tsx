"use client";
import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";

// 🔹 Tipos
type KPIs = {
  cnt_facturas: number;
  transacciones: number;
  total_neto: number;
};

type Serie = {
  fecha: string;
  total_neto: number;
};

export default function Dashboard() {
  const [data, setData] = useState<Serie[]>([]);
  const [kpis, setKpis] = useState<KPIs | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/ventas?dias=7&modo=dashboard")
      .then((res) => res.json())
      .then((resData: { kpis: KPIs; series: Serie[] }) => {
        setKpis(resData.kpis);
        setData(resData.series);
      })
      .catch((error) => {
        console.error("Error cargando datos:", error);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return (
    <>
      <h1>Dashboard de Ventas</h1>

      {/* Loading */}
      {loading && <p>Cargando datos...</p>}

      {/* KPIs */}
      {kpis && (
        <div style={kpiContainer}>
          <div style={card}>
            <p>Facturas</p>
            <h2>{kpis.cnt_facturas}</h2>
          </div>

          <div style={card}>
            <p>Transacciones</p>
            <h2>{kpis.transacciones}</h2>
          </div>

          <div style={card}>
            <p>Total Neto</p>
            <h2>{kpis.total_neto}</h2>
          </div>
        </div>
      )}

      {/* Gráfico */}
      {!loading && (
        <div style={{ marginTop: "30px" }}>
          <LineChart width={500} height={300} data={data}>
            <CartesianGrid />
            <XAxis dataKey="fecha" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="total_neto" />
          </LineChart>
        </div>
      )}
    </>
  );
}

// 🎨 Estilos tipados correctamente
const kpiContainer: React.CSSProperties = {
  display: "flex",
  gap: "10px",
  marginTop: "20px",
};

const card: React.CSSProperties = {
  flex: 1,
  padding: "15px",
  border: "1px solid #ccc",
  borderRadius: "10px",
  textAlign: "center",
};