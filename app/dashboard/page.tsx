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

export default function Dashboard() {
  const [data, setData] = useState([]);
  const [kpis, setKpis] = useState(null);

  useEffect(() => {
    fetch("/api/ventas?dias=7&modo=dashboard")
      .then((res) => res.json())
      .then((data) => {
        setKpis(data.kpis);
        setData(data.series);
      });
  }, []);

  return (
    <main style={{ padding: "20px", maxWidth: "600px", margin: "auto" }}>
      <h1>Dashboard de Ventas</h1>

      {/* KPIs */}
      {kpis && (
        <div style={{ display: "flex", gap: "10px", marginTop: "20px" }}>
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
      <div style={{ marginTop: "30px" }}>
        <LineChart width={500} height={300} data={data}>
          <CartesianGrid />
          <XAxis dataKey="fecha" />
          <YAxis />
          <Tooltip />
          <Line type="monotone" dataKey="total_neto" />
        </LineChart>
      </div>
    </main>
  );
}

const card = {
  flex: 1,
  padding: "10px",
  border: "1px solid #ccc",
  borderRadius: "10px",
  textAlign: "center",
};