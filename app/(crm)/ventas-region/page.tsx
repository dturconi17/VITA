"use client";

import type { CSSProperties } from "react";
import { useEffect, useState } from "react";
import FiltroCanal from "@/app/components/filtros/FiltroCanal";

import {
  PieChart, Pie, Cell, Tooltip,
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  ResponsiveContainer, LineChart, Line
} from "recharts";

export default function VentasRegionPage() {

  // ✅ PRIMERO estados
  const [data, setData] = useState<any[]>([]);
  const [meses, setMeses] = useState<number[]>([4,5,6,7,8,9,10,11]);
  const [canal, setCanal] = useState("todo");

  // ✅ FETCH CORRECTO
useEffect(() => {
  const query = meses.join(",");

  fetch(
    `/api/ventas?modo=region&meses=${query}&canal=${encodeURIComponent(canal)}`
  )
    .then((res) => res.json())
    .then((data) => {
      console.log("REGION:", data);
      setData(data);
    })
    .catch((err) => console.error(err));

}, [meses, canal]);
  // =========================
  // HELPERS
  // =========================

  const money = (n: number) =>
    `$ ${n.toLocaleString("es-AR", {
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    })}`;

  const crecimiento = (a: number, b: number) =>
    a ? (((b - a) / a) * 100).toFixed(1) : "0";

  const diferencia = (a: number, b: number) => b - a;

  const colorCrec = (value: number) =>
    value > 0 ? "green" : value < 0 ? "red" : "gray";

  // =========================
  // TOTALES
  // =========================

  const totales = data.reduce(
    (acc, row) => {
      acc.tam_2324 += row.tam_2324;
      acc.tam_2425 += row.tam_2425;
      acc.tam_2526 += row.tam_2526;
      return acc;
    },
    { tam_2324: 0, tam_2425: 0, tam_2526: 0 }
  );

  const crecTotal1 = Number(crecimiento(totales.tam_2324, totales.tam_2425));
  const crecTotal2 = Number(crecimiento(totales.tam_2425, totales.tam_2526));

  // =========================
  // DATA GRAFICOS
  // =========================

  const sorted = [...data].sort((a, b) => b.tam_2526 - a.tam_2526);
  const top5 = sorted.slice(0, 5);
  const others = sorted.slice(5);

  const COLORS = [
    "#0088FE", "#00C49F", "#FFBB28",
    "#FF8042", "#8884d8", "#82ca9d"
  ];

  const colorMap: Record<string, string> = {};

  data.forEach((r, i) => {
    const hue = (i * 137) % 360; // golden angle → mejor distribución
    colorMap[r.region] = `hsl(${hue}, 65%, 55%)`;
  });

  // =========================
  // PIE DATA
  // =========================

  const buildPie = (key: "tam_2324" | "tam_2425" | "tam_2526") => [
    ...top5.map((row) => ({
      name: row.region,
      value: row[key],
    })),
    ...(others.length
      ? [{
          name: "Otros",
          value: others.reduce((acc, r) => acc + r[key], 0),
        }]
      : []),
  ];

  const dataChart2324 = buildPie("tam_2324");
  const dataChart2425 = buildPie("tam_2425");
  const dataChart2526 = buildPie("tam_2526");

  const total2324 = dataChart2324.reduce((a, d) => a + d.value, 0);
  const total2425 = dataChart2425.reduce((a, d) => a + d.value, 0);
  const total2526 = dataChart2526.reduce((a, d) => a + d.value, 0);

  // =========================
  // BARS / LINE
  // =========================

  const dataBarVentas = data
    .map((r) => ({ region: r.region, ventas: r.tam_2526 }))
    .sort((a, b) => b.ventas - a.ventas);

  const dataBarCrec = data.map((r) => ({
    region: r.region,
    crecimiento: Number(crecimiento(r.tam_2425, r.tam_2526)),
  }))
   .sort((a, b) => b.crecimiento - a.crecimiento);
  

  const dataLine = [
    { periodo: "23/24", valor: totales.tam_2324 },
    { periodo: "24/25", valor: totales.tam_2425 },
    { periodo: "25/26", valor: totales.tam_2526 },
  ];

  // =========================
  // UI
  // =========================

  const grid = {
    display: "grid",
    gridTemplateColumns: "repeat(2, 1fr)",
    gap: "20px"
  };

  return (
    <main style={{ padding: "20px", background: "#f1f5f9" }}>
      <h1>Ventas por Región</h1>

      {/* ========================= */}
      {/* FILTRO MESES */}
      {/* ========================= */}
      <div style={{ marginBottom: "20px" }}>
        <h4>Filtrar por mes</h4>

        <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
          {[1,2,3,4,5,6,7,8,9,10,11,12].map((m) => (
            <button
              key={m}
              onClick={() => {
                if (meses.includes(m)) {
                  setMeses(meses.filter(x => x !== m));
                } else {
                  setMeses([...meses, m]);
                }
              }}
              style={{
                padding: "8px 12px",
                borderRadius: "8px",
                border: "none",
                cursor: "pointer",
                background: meses.includes(m) ? "#0088FE" : "#ddd",
                color: meses.includes(m) ? "white" : "black",
              }}
            >
              {m}
            </button>
          ))}

          <button onClick={() => setMeses([1,2,3,4,5,6,7,8,9,10,11,12])}>
            Todos
          </button>

          <button onClick={() => setMeses([])}>
            Limpiar
          </button>
        </div>
        <div>
          <FiltroCanal
            value={canal}
            onChange={setCanal}
          />

        </div>
      </div>

      {/* ========================= */}
      {/* GRID */}
      {/* ========================= */}
      
{data.length > 0 && (


<div style={gridCharts}>

    {/* ========================= */}
    {/* 🔵 FILA 1 - COL 1 (3 TORTAS HORIZONTALES) */}
    {/* ========================= */}
    <div style={card}>
      <h3>Participación TAM</h3>

      <div style={{ display: "flex", gap: "10px", justifyContent: "space-between" }}>

        {/* 23/24 */}
        <div style={{ textAlign: "center" }}>
          <h5>23/24</h5>
          <PieChart width={320} height={320}>
            <Pie
              data={dataChart2324}
              dataKey="value"
              nameKey="name"
              innerRadius={60}
              outerRadius={150}
              labelLine={false}   // 👈 ESTO SACA LAS LÍNEAS
              label={({ cx, cy, midAngle = 0, innerRadius = 0, outerRadius = 0, percent = 0 }) => {
                const RADIAN = Math.PI / 180;
                const radius = innerRadius + (outerRadius - innerRadius) * 0.5;

                const x = cx + radius * Math.cos(-midAngle * RADIAN);
                const y = cy + radius * Math.sin(-midAngle * RADIAN);

                return (
                  percent > 0.05 && (
                    <text
                      x={x}
                      y={y}
                      fill="white"
                      textAnchor="middle"
                      dominantBaseline="central"
                      fontSize={12}
                      fontWeight="bold"
                    >
                      {(percent * 100).toFixed(1)}%
                    </text>
                  )
                );
              }}
            >
              {dataChart2324.map((entry, i) => (
                <Cell
                  key={i}
                  fill={colorMap[entry.name] || COLORS[i % COLORS.length]}
                />
              ))}
            </Pie>
            <Tooltip
  formatter={(value) =>
    `${((Number(value ?? 0) / total2324) * 100).toFixed(1)}%`
  }
/>
          </PieChart>
        </div>

        {/* 24/25 */}
        <div style={{ textAlign: "center" }}>
          <h5>24/25</h5>
          <PieChart width={320} height={320}>
                        <Pie
              data={dataChart2425}
              dataKey="value"
              nameKey="name"
              innerRadius={60}
              outerRadius={150}
              labelLine={false}   // 👈 ESTO SACA LAS LÍNEAS
              label={({ cx, cy, midAngle = 0, innerRadius = 0, outerRadius = 0, percent = 0 }) => {
                const RADIAN = Math.PI / 180;
                const radius = innerRadius + (outerRadius - innerRadius) * 0.5;

                const x = cx + radius * Math.cos(-midAngle * RADIAN);
                const y = cy + radius * Math.sin(-midAngle * RADIAN);

                return (
                  percent > 0.05 && (
                    <text
                      x={x}
                      y={y}
                      fill="white"
                      textAnchor="middle"
                      dominantBaseline="central"
                      fontSize={12}
                      fontWeight="bold"
                    >
                      {(percent * 100).toFixed(1)}%
                    </text>
                  )
                );
              }}
            >
              {dataChart2425.map((entry, i) => (
                <Cell
                  key={i}
                  fill={colorMap[entry.name] || COLORS[i % COLORS.length]}
                />
              ))}
            </Pie>
            <Tooltip
  formatter={(value) =>
    `${((Number(value ?? 0) / total2425) * 100).toFixed(1)}%`
  }
/>
          </PieChart>
        </div>

        {/* 25/26 */}
        <div style={{ textAlign: "center" }}>
          <h5>25/26</h5>
          <PieChart width={320} height={320}>
                        <Pie
              data={dataChart2526}
              dataKey="value"
              nameKey="name"
              innerRadius={60}
              outerRadius={150}
              labelLine={false}   // 👈 ESTO SACA LAS LÍNEAS
              label={({ cx, cy, midAngle = 0, innerRadius = 0, outerRadius = 0, percent = 0 }) => {
                const RADIAN = Math.PI / 180;
                const radius = innerRadius + (outerRadius - innerRadius) * 0.5;

                const x = cx + radius * Math.cos(-midAngle * RADIAN);
                const y = cy + radius * Math.sin(-midAngle * RADIAN);

                return (
                  percent > 0.05 && (
                    <text
                      x={x}
                      y={y}
                      fill="white"
                      textAnchor="middle"
                      dominantBaseline="central"
                      fontSize={12}
                      fontWeight="bold"
                    >
                      {(percent * 100).toFixed(1)}%
                    </text>
                  )
                );
              }}
            >
              {dataChart2526.map((entry, i) => (
                <Cell
                  key={i}
                  fill={colorMap[entry.name] || COLORS[i % COLORS.length]}
                />
              ))}
            </Pie>
            <Tooltip
              formatter={(value) =>
                `${((Number(value ?? 0) / total2526) * 100).toFixed(1)}%`
              }
            />
          </PieChart>
        </div>

      </div>
    </div>

    {/* ========================= */}
    {/* 📊 FILA 1 - COL 2 */}
    {/* ========================= */}
    <div style={card}>
      <h3>Ventas por Región</h3>

      <ResponsiveContainer width="100%" height={350}>
        <BarChart data={dataBarVentas}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="region" />
          <YAxis tick={{ fontSize: 12 }} />
          <Tooltip formatter={(v) => money(Number(v ?? 0))} />
          <Bar dataKey="ventas" fill="#0088FE" />
        </BarChart>
      </ResponsiveContainer>
    </div>

    {/* ========================= */}
    {/* 📊 FILA 2 - COL 1 */}
    {/* ========================= */}
    <div style={card}>
      <h3>Crecimiento %</h3>

      <ResponsiveContainer width="100%" height={350}>
        <BarChart data={dataBarCrec}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="region" />
          <YAxis />
          <Tooltip />
          <Bar dataKey="crecimiento" fill="#00C49F" />
        </BarChart>
      </ResponsiveContainer>
    </div>

    {/* ========================= */}
    {/* 📈 FILA 2 - COL 2 */}
    {/* ========================= */}
    <div style={card}>
      <h3>Evolución TAM</h3>

      <ResponsiveContainer width="100%" height={350}>
        <LineChart data={dataLine}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="periodo" />
          <YAxis tick={{ fontSize: 12 }}/>
          <Tooltip formatter={(v) => money(Number(v ?? 0))} />
          <Line
            type="monotone"
            dataKey="valor"
            stroke="#FF8042"
            strokeWidth={3}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>

  </div>
)}
      {/* 📋 TABLA */}
      {data.length > 0 ? (
        <table style={table}>
          <thead>
            <tr style={thead}>
              <th style={th}>Región</th>
              <th style={th}>TAM 23/24</th>
              <th style={th}>TAM 24/25</th>
              <th style={th}>TAM 25/26</th>
              <th style={th}>Crec. 24 vs 23</th>
              <th style={th}>Crec. 25 vs 24</th>
              <th style={th}>Dif. 24 vs 23</th>
              <th style={th}>Dif. 25 vs 24</th>
            </tr>
          </thead>

          <tbody>
            {data.map((row, i) => {
              const crec1 = Number(crecimiento(row.tam_2324, row.tam_2425));
              const crec2 = Number(crecimiento(row.tam_2425, row.tam_2526));
              const dif1 = diferencia(row.tam_2324, row.tam_2425);
              const dif2 = diferencia(row.tam_2425, row.tam_2526);

              return (
                <tr key={i} style={i % 2 === 0 ? rowStyle : rowAlt}>
                  <td style={tdLeft}>{row.region}</td>
                  <td style={tdRight}>{money(row.tam_2324)}</td>
                  <td style={tdRight}>{money(row.tam_2425)}</td>
                  <td style={tdRight}>{money(row.tam_2526)}</td>

                  <td style={{ ...tdRight, color: colorCrec(crec1) }}>
                    {crec1}% {crec1 > 0 ? "▲" : crec1 < 0 ? "▼" : ""}
                  </td>

                  <td style={{ ...tdRight, color: colorCrec(crec2) }}>
                    {crec2}% {crec2 > 0 ? "▲" : crec2 < 0 ? "▼" : ""}
                  </td>

                  <td style={{ ...tdRight, color: colorCrec(dif1) }}>
                    {money(dif1)}
                  </td>

                  <td style={{ ...tdRight, color: colorCrec(dif2), borderRight: "none" }}>
                    {money(dif2)}
                  </td>
                </tr>
              );
            })}
          </tbody>

          <tfoot>
            <tr style={thead}>
              <td style={tdLeft}>TOTAL</td>
              <td style={tdRight}>{money(totales.tam_2324)}</td>
              <td style={tdRight}>{money(totales.tam_2425)}</td>
              <td style={tdRight}>{money(totales.tam_2526)}</td>

              <td style={{ ...tdRight, color: colorCrec(crecTotal1) }}>
                {crecTotal1}%
              </td>

              <td style={{ ...tdRight, color: colorCrec(crecTotal2) }}>
                {crecTotal2}%
              </td>

              <td style={tdRight}>
                {money(diferencia(totales.tam_2324, totales.tam_2425))}
              </td>

              <td style={{ ...tdRight, borderRight: "none" }}>
                {money(diferencia(totales.tam_2425, totales.tam_2526))}
              </td>
            </tr>
          </tfoot>
        </table>
      ) : (
        <p>Cargando...</p>
      )}
    </main>
  );
}

/* 🎨 ESTILOS */

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