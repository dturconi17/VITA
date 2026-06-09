"use client";

import { useState, useEffect } from "react";
import type { CSSProperties } from "react";

export default function SegmentacionClientesPage() {

const [anio, setAnio] = useState("2026");
const [cliente, setCliente] = useState("");
const [vendedor, setVendedor] = useState("");
const [ciudad, setCiudad] = useState("");

  return (
  <main style={{ padding: "20px", background: "#f3f4f6" }}>

    <h1>Segmentación de Clientes</h1>

    {/* ===================== */}
    {/* FILTROS */}
    {/* ===================== */}

    <div style={card}>

      <h3>Filtros</h3>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4,1fr)",
          gap: "15px",
        }}
      >

        <div>
          <label>Año</label>

          <select
            value={anio}
            onChange={(e) => setAnio(e.target.value)}
            style={input}
          >
            <option>2026</option>
            <option>2025</option>
            <option>2024</option>
          </select>
        </div>

        <div>
          <label>Cliente</label>

          <select
            value={cliente}
            onChange={(e) => setCliente(e.target.value)}
            style={input}
          >
           <option value="">Todos</option>
          </select>
        </div>

        <div>
          <label>Vendedor</label>

          <select
            value={vendedor}
            onChange={(e) => setVendedor(e.target.value)}
            style={input}
          >
            <option value="">Todos</option>
          </select>
        </div>

        <div>
          <label>Ciudad</label>

          <select
            value={ciudad}
            onChange={(e) => setCiudad(e.target.value)}
            style={input}
          >
            <option value="">Todos</option>
          </select>
        </div>

      </div>

    </div>

    {/* ===================== */}
    {/* KPIs */}
    {/* ===================== */}

    <div style={kpiContainer}>

      <div style={kpiCard}>
        <h4>Facturación</h4>
        <h2>$0</h2>
      </div>

      <div style={kpiCard}>
        <h4>Clientes</h4>
        <h2>0</h2>
      </div>

      <div style={kpiCard}>
        <h4>Transacciones</h4>
        <h2>0</h2>
      </div>

      <div style={kpiCard}>
        <h4>Ticket Promedio</h4>
        <h2>$0</h2>
      </div>

    </div>

    {/* ===================== */}
    {/* CONFIGURACIÓN SEGMENTOS */}
    {/* ===================== */}

    <div style={card}>
      <h3>Configuración de Segmentos</h3>
    </div>

    {/* ===================== */}
    {/* TABLA */}
    {/* ===================== */}

    <table style={table}>

    </table>

  </main>
);}

const input: CSSProperties = {
  width: "100%",
  marginTop: "5px",
  padding: "8px",
  borderRadius: "6px",
  border: "1px solid #d1d5db",
};

const gridCharts : CSSProperties = {
  display: "grid",
  gridTemplateColumns: "repeat(2, 1fr)",
  gap: "20px",
  marginBottom: "40px",
};

const card : CSSProperties = {
  background: "white",
  padding: "20px",
  borderRadius: "12px",
  boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
  textAlign: "center" as const,
};

const table : CSSProperties = {
  width: "100%",
  borderCollapse: "collapse",
  background: "white",
  borderRadius: "12px",
  overflow: "hidden",
  boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
};

const thead : CSSProperties = {
  background: "#0f172a",
  color: "white",
};

const th : CSSProperties = {
  padding: "14px",
  fontSize: "16px",
  fontWeight: "bold",
  textAlign: "center" as const,
  borderRight: "1px solid #444",
};

const tdLeft : CSSProperties = {
  padding: "12px",
  textAlign: "left" as const,
  borderRight: "1px solid #ddd",
};

const tdRight : CSSProperties = {
  padding: "12px",
  textAlign: "right" as const,
  borderRight: "1px solid #ddd",
};

const rowStyle : CSSProperties = {
  borderBottom: "1px solid #e5e7eb",
};

const rowAlt : CSSProperties = {
  background: "#f9fafb",
  borderBottom: "1px solid #e5e7eb",
};

const kpiContainer : CSSProperties = {
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
  gap: "15px",
  marginBottom: "20px",
};

const kpiCard : CSSProperties = {
  background: "white",
  padding: "15px",
  borderRadius: "10px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
};  