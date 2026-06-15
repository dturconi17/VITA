"use client";

import { useRef } from "react";
import { useState, useEffect } from "react";
import type { CSSProperties } from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
} from "recharts";
import html2pdf from "html2pdf.js";

//type Cliente = {
//  nombre_cliente: string;
//};

type Vendedor = {
  nombre_vendedor: string;
};

type Ciudad = {
  ciudad_cliente: string;
};

type Segmento = {
  nombre: string;
  desde: number;
  hasta: number | null;
};

type Anio = {
  anio: number;
};

type ResumenSegmento = {
  nombre: string;
  clientes: number;
  facturacion: number;
};




export default function SegmentacionClientesPage() {

const [openSegments, setOpenSegments] = useState<Record<number, boolean>>({});
//const [clientes, setClientes] = useState<Cliente[]>([]);
const [vendedores, setVendedores] = useState<Vendedor[]>([]);
const [ciudades, setCiudades] = useState<Ciudad[]>([]);
const [anios, setAnios] = useState<Anio[]>([]);

const [configOpen, setConfigOpen] = useState(false);

const pdfRef = useRef<HTMLDivElement>(null);

const toggleConfig = () => {
  setConfigOpen((prev) => !prev);
};

const toggleSegment = (index: number) => {
  setOpenSegments((prev) => ({
    ...prev,
    [index]: !prev[index],
  }));
};

const [anio, setAnio] = useState("2026");
//const [cliente, setCliente] = useState("");
const [vendedor, setVendedor] = useState("");
const [ciudad, setCiudad] = useState("");

const [kpis, setKpis] = useState({
  facturacion: 0,
  clientes: 0,
  transacciones: 0,
  ticket_promedio: 0,
});

const [datosClientes, setDatosClientes] = useState<
  { nombre_cliente: string; facturacion: number }[]
>([]);

const getColor = (pct: number) => {
  if (pct >= 50) return "#16a34a"; // verde fuerte
  if (pct >= 25) return "#eab308"; // amarillo
  return "#64748b"; // gris
};

const [resumenSegmentos, setResumenSegmentos] = useState<ResumenSegmento[]>([]);

const [segmentos, setSegmentos] = useState<Segmento[]>([
  {
    nombre: "VIP",
    desde: 250000,
    hasta: null,
  },
  {
    nombre: "Premium",
    desde: 200000,
    hasta: 249999,
  },
  {
    nombre: "Alto",
    desde: 150000,
    hasta: 199999,
  },
  {
    nombre: "Medio",
    desde: 100000,
    hasta: 149999,
  },
  {
    nombre: "Bajo",
    desde: 50000,
    hasta: 99999,
  },
  {
    nombre: "Muy Bajo",
    desde: 0,
    hasta: 49999,
  },
]);

const agregarSegmento = () => {

  setSegmentos([
    ...segmentos,
    {
      nombre: "Nuevo",
      desde: 0,
      hasta: null,
    },
  ]);

};

const guardarConfiguracion = () => {

    console.log(segmentos);

    alert("Configuración capturada correctamente.");

};


const cargarKPIs = async () => {
  try {
    const params = new URLSearchParams({
      anio,
      //cliente,
      vendedor,
      ciudad,
    });

    const res = await fetch(`/api/ticket-promedio/kpis?${params}`);

    if (!res.ok) {
      throw new Error("Error obteniendo KPIs");
    }

    const data = await res.json();

    setKpis({
      facturacion: Number(data.facturacion ?? 0),
      clientes: Number(data.clientes ?? 0),
      transacciones: Number(data.transacciones ?? 0),
      ticket_promedio: Number(data.ticket_promedio ?? 0),
    });

  } catch (error) {
    console.error("Error cargando KPIs:", error);
  }
};
const cargarSegmentos = async () => {
  try {
    const params = new URLSearchParams({
      anio,
      //cliente,
      vendedor,
      ciudad,
    });

    const res = await fetch(
      `/api/ticket-promedio/segmentos?${params}`
    );

    if (!res.ok) {
      throw new Error("Error obteniendo segmentos");
    }

    const data = await res.json();

    setDatosClientes(data);

  } catch (error) {
    console.error(error);
  }
};



const calcularSegmentacion = () => {

  const resumen = segmentos.map((s) => ({
    nombre: s.nombre,
    clientes: 0,
    facturacion: 0,
  }));

  datosClientes.forEach((cliente) => {

    const segmento = segmentos.find((s) => {

      if (s.hasta === null) {
        return cliente.facturacion >= s.desde;
      }

      return (
        cliente.facturacion >= s.desde &&
        cliente.facturacion <= s.hasta
      );

    });

    if (!segmento) return;

    const r = resumen.find((x) => x.nombre === segmento.nombre);

    if (!r) return;

    r.clientes += 1;
    r.facturacion += cliente.facturacion;

  });

  setResumenSegmentos(resumen);

};


const descargarPDF = () => {
  if (!pdfRef.current) return;

  const opt: any = {
    margin: [10, 10, 10, 10],
    filename: `segmentacion-clientes-${anio}.pdf`,
    image: { type: "jpeg", quality: 0.98 },
    html2canvas: {
  scale: 3, // mejor calidad para gráficos
},
    jsPDF: {
      unit: "mm",
      format: "a4",
      orientation: "portrait",
    },
    pagebreak: {
      mode: ["avoid-all", "css", "legacy"],
    },
  };

  html2pdf()
    .set(opt)
    .from(pdfRef.current)
    .save();
};


const opt: any = {
  margin: [10, 10, 10, 10],
  filename: `segmentacion-clientes-${anio}.pdf`,
  image: { type: "jpeg", quality: 0.98 },
  html2canvas: {
    scale: 2,
    useCORS: true,
    scrollY: 0,
  },
  jsPDF: {
    unit: "mm",
    format: "a4",
    orientation: "portrait",
  },
  pagebreak: {
    mode: ["avoid-all", "css", "legacy"],
  },
};


const totalClientes = resumenSegmentos.reduce(
  (acc, s) => acc + s.clientes,
  0
);

const totalFacturacion = resumenSegmentos.reduce(
  (acc, s) => acc + s.facturacion,
  0
);

useEffect(() => {

  fetch("/api/ticket-promedio/filtros")
    .then((res) => res.json())
    .then((data) => {
      setVendedores(data.vendedores || []);
      setCiudades(data.ciudades || []);
      setAnios(data.anios || []);
    })
    .catch(console.error);

}, []);

useEffect(() => {
  cargarKPIs();
  cargarSegmentos();
}, [anio, vendedor, ciudad]);


useEffect(() => {
  if (datosClientes.length === 0) return;
  calcularSegmentacion();
}, [datosClientes, segmentos]);
  
  return (
  <main
  ref={pdfRef}
  style={{
    padding: "20px",
    background: "#fff",
    minHeight: "100vh",
    color: "#0f172a",
    fontFamily: "Arial",
  }}
>

<div className="no-print">
<button
  onClick={descargarPDF}
  style={{
    background: "#16a34a",
    color: "white",
    padding: "10px 16px",
    border: "none",
    borderRadius: "8px",
    cursor: "pointer",
    fontWeight: 600,
    marginBottom: "15px",
  }}
>
  Descargar PDF (test)
</button>
</div>

<h1 style={title}>

Segmentación de Clientes

</h1>

    {/* ===================== */}
    {/* FILTROS */}
    {/* ===================== */}

 <div style={card}>
  <h3 style={{ marginBottom: 15 }}>Filtros</h3>

  <div
    style={{
      display: "grid",
      gridTemplateColumns: "repeat(3, 1fr)",
      gap: "20px",
      alignItems: "end",
    }}
  >
    {/* AÑO */}
    <div style={filterItem}>
      <label style={label}>Año</label>
      <select value={anio} onChange={(e) => setAnio(e.target.value)} style={select}>
        {anios.map((a) => (
          <option key={a.anio} value={a.anio}>
            {a.anio}
          </option>
        ))}
      </select>
    </div>

    {/* VENDEDOR */}
    <div style={filterItem}>
      <label style={label}>Vendedor</label>
      <select value={vendedor} onChange={(e) => setVendedor(e.target.value)} style={select}>
        <option value="">Todos</option>
          {vendedores.map((v, index) => (
            <option
              key={`${v.nombre_vendedor}-${index}`}
              value={v.nombre_vendedor}
            >
              {v.nombre_vendedor}
            </option>
          ))}
      </select>
    </div>

    {/* CIUDAD */}
    <div style={filterItem}>
      <label style={label}>Ciudad</label>
      <select value={ciudad} onChange={(e) => setCiudad(e.target.value)} style={select}>
        <option value="">Todas</option>
        {ciudades.map((c) => (
          <option key={c.ciudad_cliente} value={c.ciudad_cliente}>
            {c.ciudad_cliente}
          </option>
        ))}
      </select>
    </div>
  </div>
</div>

    {/* ===================== */}
    {/* KPIs */}
    {/* ===================== */}

    <div style={kpiContainer}>

      <div style={kpiCard}>
        <h4
style={{
color:"#64748b",
fontWeight:500,
marginBottom:8
}}
>

Facturación

</h4>

<h2
  style={{
    fontSize: 32,
    margin: 0,
    color: "#0f172a",
  }}
>
  {kpis.facturacion.toLocaleString("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 0,
  })}
</h2>
      </div>

      <div style={kpiCard}>
        <h4>Clientes</h4>
        <h2>{kpis.clientes.toLocaleString("es-AR")}</h2>
      </div>

      <div style={kpiCard}>
        <h4>Transacciones</h4>
        <h2>{kpis.transacciones.toLocaleString("es-AR")}</h2>
      </div>

      <div style={kpiCard}>
        <h4>Ticket Promedio</h4>
        <h2>
  {kpis.ticket_promedio.toLocaleString("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 2,
  })}
</h2>
      </div>

    </div>

    {/* ===================== */}
    {/* CONFIGURACIÓN SEGMENTOS */}
    {/* ===================== */}

<div
  style={{
    ...card,
    background: "linear-gradient(135deg, #eff6ff, #f8fafc)",
    border: "1px solid #bfdbfe",
  }}
>

  {/* HEADER COLAPSABLE */}
  <div
    onClick={toggleConfig}
    style={{
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      cursor: "pointer",
      userSelect: "none",
    }}
  >
    <h3 style={{ margin: 0 }}>Configuración de Segmentos</h3>
    <span style={{ fontSize: 18 }}>
      {configOpen ? "▲" : "▼"}
    </span>
  </div>

  {/* CONTENIDO */}
  {configOpen && (
    <>
      {segmentos.map((s, index) => (
        <div
          key={index}
          style={{
            border: "1px solid #e2e8f0",
            borderRadius: "10px",
            marginTop: "12px",
            padding: "12px",
          }}
        >
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr 1fr",
              gap: "12px",
            }}
          >
            {/* NOMBRE */}
            <input
              value={s.nombre}
              onChange={(e) => {
                const copia = [...segmentos];
                copia[index].nombre = e.target.value;
                setSegmentos(copia);
              }}
              style={input}
            />

            {/* DESDE */}
            <input
              type="number"
              value={s.desde}
              onChange={(e) => {
                const copia = [...segmentos];
                copia[index].desde = Number(e.target.value);
                setSegmentos(copia);
              }}
              style={input}
            />

            {/* HASTA */}
            <input
              type="number"
              value={s.hasta ?? ""}
              placeholder="Sin límite"
              onChange={(e) => {
                const copia = [...segmentos];
                copia[index].hasta =
                  e.target.value === "" ? null : Number(e.target.value);
                setSegmentos(copia);
              }}
              style={input}
            />
          </div>
        </div>
      ))}

      {/* BOTONES */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          marginTop: 20,
        }}
      >
        <button style={secondaryButton} onClick={agregarSegmento}>
          Agregar Segmento
        </button>

        <button style={primaryButton} onClick={guardarConfiguracion}>
          Guardar Configuración
        </button>
      </div>
    </>
  )}

</div>


<div style={card}>

<h3>Resumen por Segmento</h3>

<table style={table}>

<thead style={thead}>
  <tr>
    <th style={th}>Segmento</th>
    <th style={th}>Clientes</th>
    <th style={th}>% Clientes</th>
    <th style={th}>Facturación</th>
    <th style={th}>% Facturación</th>
  </tr>
</thead>

<tbody>
  {resumenSegmentos.map((s, index) => {
    const pctClientes =
      totalClientes > 0 ? (s.clientes / totalClientes) * 100 : 0;

    const pctFacturacion =
      totalFacturacion > 0 ? (s.facturacion / totalFacturacion) * 100 : 0;

    return (
      <tr key={index} style={index % 2 === 0 ? rowStyle : rowAlt}>
        
        {/* SEGMENTO */}
        <td style={tdLeft}>{s.nombre}</td>

        {/* CLIENTES */}
        <td style={tdRight}>
          <div>{s.clientes.toLocaleString("es-AR")}</div>

          {/* BAR STYLE POWER BI */}
          <div
            style={{
              height: 6,
              background: "#e2e8f0",
              borderRadius: 4,
              marginTop: 6,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${pctClientes}%`,
                height: "100%",
                background: getColor(pctClientes),
                borderRadius: 4,
              }}
            />
          </div>

          <div
            style={{
              fontSize: 11,
              color: getColor(pctClientes),
              fontWeight: 600,
              marginTop: 3,
            }}
          >
            {pctClientes.toFixed(1)}%
          </div>
        </td>

        {/* % CLIENTES (opcional lo podés borrar si querés compacto) */}
        <td style={tdRight}>
          <span style={{ color: getColor(pctClientes), fontWeight: 600 }}>
            {pctClientes.toFixed(1)}%
          </span>
        </td>

        {/* FACTURACIÓN */}
        <td style={tdRight}>
          <div>
            {s.facturacion.toLocaleString("es-AR", {
              style: "currency",
              currency: "ARS",
              maximumFractionDigits: 0,
            })}
          </div>

          <div
            style={{
              height: 6,
              background: "#e2e8f0",
              borderRadius: 4,
              marginTop: 6,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${pctFacturacion}%`,
                height: "100%",
                background: getColor(pctFacturacion),
                borderRadius: 4,
              }}
            />
          </div>

          <div
            style={{
              fontSize: 11,
              color: getColor(pctFacturacion),
              fontWeight: 600,
              marginTop: 3,
            }}
          >
            {pctFacturacion.toFixed(1)}%
          </div>
        </td>

        {/* % FACTURACIÓN */}
        <td style={tdRight}>
          <span style={{ color: getColor(pctFacturacion), fontWeight: 600 }}>
            {pctFacturacion.toFixed(1)}%
          </span>
        </td>
      </tr>
    );
  })}
</tbody>

</table>

</div>


<div
  style={{
    display: "grid",
    gridTemplateColumns: "1fr 1fr",
    gap: "20px",
  }}
>
  {/* PIE */}
  <div style={card}>
    <h3>Clientes por Segmento</h3>

    <ResponsiveContainer width="100%" height={350}>
      <PieChart>
        <Pie
  data={resumenSegmentos}
  dataKey="clientes"
  nameKey="nombre"
  outerRadius={110}
  labelLine={false}
>

  <Tooltip
  formatter={(value) =>
  typeof value === "number"
    ? new Intl.NumberFormat("es-AR", {
        style: "currency",
        currency: "ARS",
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value)
    : value
}
/>

          {resumenSegmentos.map((_, index) => (
            <Cell
              key={index}
              fill={COLORS[index % COLORS.length]}
            />
          ))}
        </Pie>
        <Tooltip />
      </PieChart>
    </ResponsiveContainer>
  </div>

  {/* BAR */}
  <div style={card}>
    <h3>Facturación por Segmento</h3>

    <ResponsiveContainer width="100%" height={350}>
      <BarChart data={resumenSegmentos}>
  <CartesianGrid strokeDasharray="3 3" />

  <XAxis
    dataKey="nombre"
    angle={-15}
    textAnchor="end"
    interval={0}
  />

  <YAxis
    tickFormatter={(value) =>
      new Intl.NumberFormat("es-AR", {
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value)
    }
  />

  <Tooltip
    formatter={(value) =>
  typeof value === "number"
    ? new Intl.NumberFormat("es-AR", {
        style: "currency",
        currency: "ARS",
        notation: "compact",
        maximumFractionDigits: 1,
      }).format(value)
    : value
}
  />

  <Bar dataKey="facturacion" radius={[6, 6, 0, 0]}>
    {resumenSegmentos.map((_, index) => (
      <Cell key={index} fill={COLORS[index % COLORS.length]} />
    ))}
  </Bar>
</BarChart>
    </ResponsiveContainer>
  </div>
</div>
  </main>
);}

const COLORS = [  "#2563eb",  "#16a34a",  "#ea580c",  "#9333ea",  "#eab308",  "#ef4444",  "#14b8a6",];

const input: CSSProperties = {
  width: "90%",
  padding: "10px 12px",
  borderRadius: "8px",
  border: "1px solid #cbd5e1",
  background: "#fff",
  fontSize: "14px",
  outline: "none",
};

const primaryButton: CSSProperties = {
background:"#2563eb",
color:"white",
padding:"10px 22px",
border:"none",
borderRadius:"8px",
cursor:"pointer",
fontWeight:600,
fontSize:"14px",
};

const secondaryButton: CSSProperties = {
background:"#fff",
color:"#1e293b",
padding:"10px 22px",
border:"1px solid #cbd5e1",
borderRadius:"8px",
cursor:"pointer",
fontWeight:600,
fontSize:"14px",
};

const card: CSSProperties = {
  background: "#fff",
  padding: "24px",
  borderRadius: "14px",
  marginBottom: "22px",
  boxShadow: "0 2px 10px rgba(15,23,42,.08)",
  border: "1px solid #e5e7eb",
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

const kpiCard: CSSProperties = {
    background:"#fff",
    borderRadius:"14px",
    padding:"20px",
    border:"1px solid #e2e8f0",
    boxShadow:"0 2px 8px rgba(0,0,0,.05)",
    transition:"0.2s",
}; 

const title: CSSProperties = {
    fontSize: 34,
    marginBottom: 25,
    color: "#0f172a",
    fontWeight: 700,
};

const filterItem: CSSProperties = {
  display: "flex",
  flexDirection: "column",
  gap: "6px",
};

const label: CSSProperties = {
  fontSize: "13px",
  fontWeight: 600,
  color: "#475569",
};

const select: CSSProperties = {
  height: "42px",
  borderRadius: "10px",
  border: "1px solid #cbd5e1",
  background: "#fff",
  padding: "0 12px",
  fontSize: "14px",
  outline: "none",
  transition: "all 0.2s",
};