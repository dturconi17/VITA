"use client";

import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";


type KPIs = {
  facturacion_2023_24: number;
  facturacion_2024_25: number;
  facturacion_2025_26: number;
  facturacion_2026_27: number;
  transacciones_2023_24: number;
  transacciones_2024_25: number;
  transacciones_2025_26: number;
  transacciones_2026_27: number;
  };

type Cliente = {
  nombre_cliente: string;
};

type Evolucion = {
  "año-mes": string;
  total_venta: number;
};

export default function FacturacionPage() {
  const [kpis, setKpis] = useState<KPIs | null>(null);
  const [loading, setLoading] = useState(true);
  const [clienteSeleccionado, setClienteSeleccionado] = useState("");
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [evolucion, setEvolucion] = useState<Evolucion[]>([]);  

useEffect(() => {
  obtenerClientes();
}, []);

useEffect(() => {
  obtenerKPIs();
}, [clienteSeleccionado]);

useEffect(() => {
  obtenerEvolucion();
}, [clienteSeleccionado]);

  async function obtenerClientes() {
  try {

    const res = await fetch("/api/facturacion/clientes");

    const data = await res.json();

    console.log(data);
   

    setClientes(data);

  } catch (error) {
    console.error(error);
  }
}

  async function obtenerKPIs() {

  try {

    const res = await fetch(
      `/api/facturacion/kpis?cliente=${encodeURIComponent(clienteSeleccionado)}`
    );

    const data = await res.json();

    console.log("STATUS:", res.status);
    console.log("DATA:", data);

    if (!res.ok) {
      throw new Error(data.error || "Error API");
    }

    setKpis(data);

  } catch (error) {

    console.error("ERROR KPIS:", error);

  } finally {

    setLoading(false);

  }
}


  async function obtenerEvolucion() {

    if (!clienteSeleccionado) {
      setEvolucion([]);
      return;
    }

    try {

      const res = await fetch(
        `/api/facturacion/evolucion?cliente=${encodeURIComponent(clienteSeleccionado)}`
      );

      const data = await res.json();

      setEvolucion(data);

    } catch (error) {
      console.error(error);
    }
  }

  function formatearMoneda(valor: number) {
    return new Intl.NumberFormat("es-AR", {
      style: "currency",
      currency: "ARS",
      maximumFractionDigits: 0,
    }).format(valor || 0);
  }

function calcularVariacion(actual: number, anterior: number) {

  if (!anterior || anterior === 0) {

  if (actual > 0) {
    return 100;
  }

  return 0;
}

  return ((actual - anterior) / anterior) * 100;
}

function obtenerColorVariacion(valor: number) {

  if (valor > 0) {
    return "#22c55e";
  }

  if (valor < 0) {
    return "#ef4444";
  }

  return "#6b7280";
}


const growth_2024_25 = calcularVariacion(
  kpis?.facturacion_2024_25 || 0,
  kpis?.facturacion_2023_24 || 0
);

const growth_2025_26 = calcularVariacion(
  kpis?.facturacion_2025_26 || 0,
  kpis?.facturacion_2024_25 || 0
);

const growth_2026_27 = calcularVariacion(
  kpis?.facturacion_2026_27 || 0,
  kpis?.facturacion_2025_26 || 0
);


const growth_trx_2024_25 = calcularVariacion(
  kpis?.transacciones_2024_25 || 0,
  kpis?.transacciones_2023_24 || 0
);

const growth_trx_2025_26 = calcularVariacion(
  kpis?.transacciones_2025_26 || 0,
  kpis?.transacciones_2024_25 || 0
);

const growth_trx_2026_27 = calcularVariacion(
  kpis?.transacciones_2026_27 || 0,
  kpis?.transacciones_2025_26 || 0
);


if (loading) {
  return (
    <div style={{ padding: "30px" }}>
      Cargando dashboard...
    </div>
  );
}

return (
    <div style={container}>
      
      <div style={{ marginBottom: "30px" }}>
        <h1 style={title}>
          Dashboard de Facturación
        </h1>

        <p style={subtitle}>
          Indicadores generales de facturación
        </p>
      </div>

      <div style={{ marginBottom: "20px" }}>
  
  <select
    value={clienteSeleccionado}
    onChange={(e) => setClienteSeleccionado(e.target.value)}
    style={{
      padding: "10px",
      borderRadius: "8px",
      minWidth: "300px",
      border: "1px solid #d1d5db",
    }}
  >
    <option value="">
      Todos los clientes
    </option>

    {clientes.map((cliente) => (
      <option
        key={cliente.nombre_cliente}
        value={cliente.nombre_cliente}
      >
        {cliente.nombre_cliente}
      </option>
    ))}
  </select>
</div>

<div style={grid}>

  {/* TAM 2023/2024 */}

  <div
    style={{
      ...card,
      borderTop: "5px solid #9ca3af",
    }}
  >

    <div style={cardLabel}>
      Facturación TAM 2023/2024
    </div>

    <div style={cardValue}>
      {formatearMoneda(kpis?.facturacion_2023_24 || 0)}
    </div>

  </div>

  {/* TAM 2024/2025 */}

  <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_2024_25)}`,
    }}
  >

    <div style={cardLabel}>
      Facturación TAM 2024/2025
    </div>

    <div style={cardValue}>
      {formatearMoneda(kpis?.facturacion_2024_25 || 0)}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_2024_25),
      }}
    >
      {growth_2024_25 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_2024_25).toFixed(1)}%
    </div>

  </div>

  {/* TAM 2025/2026 */}

  <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_2025_26)}`,
    }}
  >

    <div style={cardLabel}>
      Facturación TAM 2025/2026
    </div>

    <div style={cardValue}>
      {formatearMoneda(kpis?.facturacion_2025_26 || 0)}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_2025_26),
      }}
    >
      {growth_2025_26 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_2025_26).toFixed(1)}%
    </div>

  </div>

  {/* TAM 2026/2027 */}

  <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_2026_27)}`,
    }}
  >

    <div style={cardLabel}>
      Facturación TAM 2026/2027
    </div>

    <div style={cardValue}>
      {formatearMoneda(kpis?.facturacion_2026_27 || 0)}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_2026_27),
      }}
    >
      {growth_2026_27 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_2026_27).toFixed(1)}%
    </div>

  </div>

  {/* TRX 2023/2024 */}

  <div
    style={{
      ...card,
      borderTop: "5px solid #9ca3af",
    }}
  >

    <div style={cardLabel}>
      Transacciones TAM 2023/2024
    </div>

    <div style={cardValue}>
      {formatearMoneda(kpis?.transacciones_2023_24 || 0)}
    </div>

  </div>

  {/* TRX 2024/2025 */}


  <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_trx_2024_25)}`,
    }}
  >

    <div style={cardLabel}>
      Transacciones TAM 2024/2025
    </div>

    <div style={cardValue}>
      {kpis?.transacciones_2024_25 || 0}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_trx_2024_25),
      }}
    >
      {growth_trx_2024_25 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_trx_2024_25).toFixed(1)}%
    </div>

  </div>




  {/* TRX 2025/2026 */}

  <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_trx_2025_26)}`,
    }}
  >

    <div style={cardLabel}>
      Transacciones TAM 2025/2026
    </div>

    <div style={cardValue}>
      {kpis?.transacciones_2025_26 || 0}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_trx_2025_26),
      }}
    >
      {growth_trx_2025_26 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_trx_2025_26).toFixed(1)}%
    </div>

  </div>

  {/* TRX 2026/2027 */}

    <div
    style={{
      ...card,
      borderTop: `5px solid ${obtenerColorVariacion(growth_trx_2026_27)}`,
    }}
  >

    <div style={cardLabel}>
      Transacciones TAM 2026/2027
    </div>

    <div style={cardValue}>
      {kpis?.transacciones_2026_27 || 0}
    </div>

    <div
      style={{
        marginTop: "8px",
        fontWeight: "bold",
        color: obtenerColorVariacion(growth_trx_2026_27),
      }}
    >
      {growth_trx_2026_27 >= 0 ? "▲" : "▼"}{" "}
      {Math.abs(growth_trx_2026_27).toFixed(1)}%
    </div>

  </div>

</div>

{clienteSeleccionado && (
  <div
    style={{
      background: "white",
      padding: "20px",
      borderRadius: "10px",
      marginTop: "30px",
      boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
    }}
  >
    <h2
      style={{
        marginBottom: "20px",
        fontSize: "20px",
        fontWeight: "bold",
      }}
    >
      Evolución Mensual
    </h2>

    <div style={{ width: "100%", height: 400 }}>
      
      <ResponsiveContainer>
        
          <LineChart data={evolucion}>

            <CartesianGrid stroke="#eee" />

            <XAxis dataKey="año-mes" />

            <YAxis
              tickFormatter={(value) =>
                `$${(value).toFixed(0)}`
              }
            />

            <Tooltip
              formatter={(value: number) => [
                formatearMoneda(value),
                "Facturación",
              ]}
            />



            <Line
              type="monotone"
              dataKey="total_venta"
              stroke="#2563eb"
              strokeWidth={3}
              dot={false}
            />

          </LineChart>

      </ResponsiveContainer>

    </div>
  </div>
)}

    </div>
  );
}

/* ESTILOS */

const container = {
  padding: "30px",
  background: "#f3f4f6",
  minHeight: "100vh",
};

const title = {
  fontSize: "32px",
  fontWeight: "bold",
  color: "#111827",
};

const subtitle = {
  color: "#6b7280",
  marginTop: "5px",
  marginBottom: "30px",
};

const grid = {
  display: "grid",
  gridTemplateColumns: "repeat(4, 1fr)",
  gap: "20px",
};



const card = {
  background: "white",
  padding: "16px",
  borderRadius: "12px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
  transition: "all 0.2s ease",
  cursor: "pointer",
};

const cardLabel = {
  color: "#6b7280",
  fontSize: "14px",
  marginBottom: "10px",
};

const cardValue = {
  fontSize: "32px",
  fontWeight: "bold",
  color: "#111827",
};

const table = {
  width: "100%",
  borderCollapse: "collapse" as const,
  background: "white",
  marginTop: "30px",
  borderRadius: "10px",
  overflow: "hidden",
};

const thead = {
  background: "#1f2937",
  color: "white",
};

const kpiContainer = {
  display: "grid",
  gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
  gap: "15px",
  marginBottom: "20px",
};

const kpiCard = {
  background: "white",
  padding: "15px",
  borderRadius: "10px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
};

const th = {
  padding: "12px",
};

const tdLeft = {
  padding: "10px",
  textAlign: "left" as const,
};

const tdRight = {
  padding: "10px",
  textAlign: "right" as const,
};

const rowStyle = {
  borderBottom: "1px solid #ddd",
};

const rowAlt = {
  background: "#f9f9f9",
};