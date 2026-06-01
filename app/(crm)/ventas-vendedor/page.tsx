"use client";

import type { CSSProperties } from "react";
import { useEffect, useState } from "react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, BarChart, Bar
} from "recharts";

type Vendedor = {
  codigo_vendedor: string;
  nombre_vendedor: string;
};

export default function ClientesPage() {

  const [data, setData] = useState<any[]>([]);
  const [stickinessData, setStickinessData] = useState<any[]>([]);
  const [retencionTAM, setRetencionTAM] = useState<any[]>([]);

  const desde = "2024-01";
  const hasta = "2024-12";

  const [vendedores, setVendedores] = useState<Vendedor[]>([]);
  const [vendedorSeleccionado, setVendedorSeleccionado] = useState("todo");

  // =========================
  // FETCH DATA
  // =========================
  useEffect(() => {

    const controller = new AbortController();

    const params = new URLSearchParams({
      vendedor: vendedorSeleccionado, // ✅ FIX
      desde,
      hasta,
    });

    const fetchData = async (modo: string) => {
      const res = await fetch(`/api/ventas?modo=${modo}&${params.toString()}`, {
        signal: controller.signal,
      });

      if (!res.ok) throw new Error(`Error en ${modo}`);

      return res.json();
    };

    Promise.all([
      fetchData("clientes"),
      fetchData("stickiness"),
      fetchData("retencion_tam"),
    ])
      .then(([clientes, stickiness, retencion]) => {
        setData(Array.isArray(clientes) ? clientes : []);
        setStickinessData(Array.isArray(stickiness) ? stickiness : []);
        setRetencionTAM(Array.isArray(retencion) ? retencion : []);
      })
      .catch((err) => {
        if (err.name !== "AbortError") console.error(err);
      });

    return () => controller.abort();

  }, [desde, hasta, vendedorSeleccionado]);

  // =========================
  // FETCH VENDEDORES
  // =========================
  useEffect(() => {
    fetch("/api/vendedores")
      .then(res => res.json())
      .then(res => setVendedores(res))
      .catch(console.error);
  }, []);

  // =========================
  // HELPERS
  // =========================
  const formatNumber = (n: number | null | undefined) =>
    (n ?? 0).toLocaleString("es-AR");

  const crecimiento = (a: number, b: number) =>
    a ? ((b - a) / a) * 100 : 0;

  const nombreMesTAM = (m: number) => {
    const meses = [
      "Abr", "May", "Jun", "Jul", "Ago", "Sep",
      "Oct", "Nov", "Dic", "Ene", "Feb", "Mar"
    ];
    return meses[m - 1];
  };


  const colorCrec = (value: number) =>
    value > 0 ? "green" : value < 0 ? "red" : "gray";

  const formatPercent = (v: number | null) =>
  v === null || v === undefined
    ? "-"
    : `${v.toFixed(2)}%`;

  // =========================
  // DATA
  // =========================
  const dataOrdenada = [...data].sort(
    (a, b) => Number(a.mes_tam) - Number(b.mes_tam)
  );

  const kpisFinal = Array.isArray(retencionTAM)
    ? [...retencionTAM]
        .sort((a, b) => Number(a.orden_tam) - Number(b.orden_tam))
        .map((r, i, arr) => {
          const prev = arr[i - 1]?.total_actual;

          return {
            TAM: r.TAM,
            total_clientes: r.total_actual,
            crecimiento: prev
              ? ((r.total_actual - prev) / prev) * 100
              : null,
            retencion: r.retencion_vs_anterior,
          };
        })
    : [];

  const dataLine = dataOrdenada.map((r) => ({
    periodo: nombreMesTAM(r.mes_tam),
    tam_2223: r.tam_2223,
    tam_2324: r.tam_2324,
    tam_2425: r.tam_2425,
    tam_2526: r.tam_2526,
  }));

  const dataBar = dataOrdenada.map((r) => ({
    mes: nombreMesTAM(r.mes_tam),
    clientes: r.tam_2526,
  }));

  const dataStickiness = Array.isArray(stickinessData)
    ? [...stickinessData]
        .sort(
          (a, b) =>
            new Date(a.fecha_orden).getTime() -
            new Date(b.fecha_orden).getTime()
        )
        .map((r) => ({
          mes: `${r.mes_label} ${r.anio_real}`,
          stickiness: Number(r.stickiness),
        }))
    : [];

  // =========================
  // UI
  // =========================
  return (
    <main style={{ padding: "20px" }}>

      {/* FILTRO VENDEDORES */}
      <div style={{ marginBottom: "20px" }}>
        <label style={{ marginRight: "10px" }}>Vendedor:</label>

        <select
          value={vendedorSeleccionado}
          onChange={(e) => setVendedorSeleccionado(e.target.value)}
          style={{ padding: "6px", borderRadius: "6px" }}
        >
          <option value="todo">Todos</option>

          {vendedores.map((v) => (
            <option key={v.codigo_vendedor} value={v.nombre_vendedor}>
              {v.nombre_vendedor}
            </option>
          ))}
        </select>
      </div>

      <h1>Clientes por Mes</h1>

  <div style={kpiContainer}>
  {kpisFinal.map((t, i) => (
    <div key={i} style={kpiCard}>
      
      <div style={{ fontSize: "14px", color: "#6b7280" }}>
        {t.TAM}
      </div>

      <div style={{ fontSize: "26px", fontWeight: "bold" }}>
        {(t.total_clientes || 0).toLocaleString("es-AR")}
      </div>

      {/* crecimiento */}
      <div
        style={{
          fontSize: "12px",
          color:
            typeof t.crecimiento === "number"
              ? t.crecimiento > 0
                ? "green"
                : t.crecimiento < 0
                ? "red"
                : "gray"
              : "gray",
        }}
      >
        {typeof t.crecimiento === "number"
          ? `${t.crecimiento.toFixed(1)}% ${
              t.crecimiento > 0 ? "▲" : t.crecimiento < 0 ? "▼" : ""
            }`
          : "-"}
      </div>

      {/* 🔥 retención */}
      <div
        style={{
          fontSize: "12px",
          fontWeight: "bold",
          color:
            typeof t.retencion === "number"
              ? t.retencion > 50
                ? "green"
                : t.retencion > 30
                ? "orange"
                : "red"
              : "gray",
        }}
      >
        {typeof t.retencion === "number"
          ? `Retención: ${t.retencion.toFixed(1)}%`
          : "-"}
      </div>

    </div>
  ))}
</div>

      {/* STICKINESS */}
      <div style={card}>
        <h3>Stickiness de Clientes (MoM)</h3>

        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={dataStickiness}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="mes" />
            <YAxis domain={[0, 100]} />
            <Tooltip
              formatter={(v) => `${Number(v ?? 0).toFixed(1)}%`}
            />

            <Line
              type="monotone"
              dataKey="stickiness"
              stroke="#6366f1"
              strokeWidth={3}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* GRAFICOS */}
      {data.length > 0 && (
        <div style={grid}>

          {/* EVOLUCION */}
          <div style={card}>
            <h3>Evolución de Clientes</h3>

            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={dataLine}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="periodo" />
                <YAxis />
                <Tooltip />

                <Line dataKey="tam_2223" stroke="#a78bfa" />
                <Line dataKey="tam_2324" stroke="#6366f1" />
                <Line dataKey="tam_2425" stroke="#22c55e" />
                <Line dataKey="tam_2526" stroke="#f97316" />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* BARRAS */}
          <div style={card}>
            <h3>Clientes por Mes</h3>

            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={dataBar}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="mes" />
                <YAxis />
                <Tooltip
                   formatter={(v) => `${Number(v ?? 0).toFixed(1)}%`}
/>
                <Bar dataKey="clientes" fill="#0088FE" />
              </BarChart>
            </ResponsiveContainer>
          </div>

        </div>
      )}

      {/* TABLA */}
      {data.length > 0 && (
        <table style={table}>
  <thead style={thead}>
    <tr>
      <th style={{ ...th, borderRight: "2px solid #ccc" }}>Mes</th>

      <th style={{ ...th, borderRight: "2px solid #ccc" }}>TAM 22/23</th>

      <th style={{ ...th, borderRight: "2px solid #ccc" }}>TAM 23/24</th>
      <th style={{ ...th, borderRight: "2px solid #ccc" }}>Δ</th>

      <th style={{ ...th, borderRight: "2px solid #ccc" }}>TAM 24/25</th>
      <th style={{ ...th, borderRight: "2px solid #ccc" }}>Δ</th>

      <th style={{ ...th, borderRight: "2px solid #ccc" }}>TAM 25/26</th>
      <th style={{ ...th, borderRight: "2px solid #ccc" }}>Δ</th>
    </tr>
  </thead>

  <tbody>
    {dataOrdenada.map((row, i) => {
      const c1 = Number(crecimiento(row.tam_2223, row.tam_2324));
      const c2 = Number(crecimiento(row.tam_2324, row.tam_2425));
      const c3 = Number(crecimiento(row.tam_2425, row.tam_2526));

      return (
        <tr key={i} style={i % 2 === 0 ? rowStyle : rowAlt}>
          <td style={{ ...tdLeft, borderRight: "2px solid #ccc" }}>{nombreMesTAM(row.mes_tam)}</td>

          <td style={{ ...tdRight, borderRight: "2px solid #ccc" }}>{formatNumber(row.tam_2223)}</td>

          <td style={{ ...tdRight, borderRight: "2px solid #ccc" }}>{formatNumber(row.tam_2324)}</td>
          <td style={{ ...tdRight, borderRight: "2px solid #ccc", color: colorCrec(c1) }}>
  {formatPercent(c1)} {c1 > 0 ? "▲" : c1 < 0 ? "▼" : ""}
</td>

          <td style={{ ...tdRight, borderRight: "2px solid #ccc" }}>{formatNumber(row.tam_2425)}</td>
           <td style={{ ...tdRight, borderRight: "2px solid #ccc", color: colorCrec(c2) }}>
  {formatPercent(c2)} {c2 > 0 ? "▲" : c2 < 0 ? "▼" : ""}
          </td>

          <td style={{ ...tdRight, borderRight: "2px solid #ccc" }}>{formatNumber(row.tam_2526)}</td>
          <td style={{ ...tdRight, borderRight: "2px solid #ccc", color: colorCrec(c3) }}>
  {formatPercent(c3)} {c3 > 0 ? "▲" : c3 < 0 ? "▼" : ""}
          </td>
        </tr>
      );
    })}
  </tbody>
</table>
      )}
    </main>
  );
}

/* ESTILOS */

const grid : CSSProperties = {
  display: "grid",
  gridTemplateColumns: "repeat(2, 1fr)",
  gap: "20px",
};

const card : CSSProperties = {
    background: "white",
  padding: "15px",
  borderRadius: "10px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
};

const table : CSSProperties = {
  width: "100%",
  borderCollapse: "collapse",
  background: "white",
  marginTop: "30px",
};

const thead : CSSProperties = {
  background: "#1f2937",
  color: "white",
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

const th : CSSProperties = { padding: "12px" };
const tdLeft : CSSProperties = { padding: "10px", textAlign: "left" as const };
const tdRight : CSSProperties = { padding: "10px", textAlign: "right" as const };

const rowStyle : CSSProperties = { borderBottom: "1px solid #ddd" };
const rowAlt : CSSProperties = { background: "#f9f9f9" };