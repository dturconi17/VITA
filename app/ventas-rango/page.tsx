"use client";
import { useState } from "react";

export default function VentasRango() {
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");
  const [data, setData] = useState(null);

  const consultar = () => {
    fetch(`/api/ventas?desde=${desde}&hasta=${hasta}`)
      .then((res) => res.json())
      .then((data) => setData(data));
  };

  return (
    <main style={{ padding: "20px", maxWidth: "500px", margin: "auto" }}>
      <h1>Ventas por rango</h1>

      <label>Desde:</label>
      <input
        type="date"
        value={desde}
        onChange={(e) => setDesde(e.target.value)}
        style={{ width: "100%", marginBottom: "10px" }}
      />

      <label>Hasta:</label>
      <input
        type="date"
        value={hasta}
        onChange={(e) => setHasta(e.target.value)}
        style={{ width: "100%", marginBottom: "10px" }}
      />

      <button
        onClick={consultar}
        style={{
          width: "100%",
          padding: "15px",
          backgroundColor: "black",
          color: "white",
          borderRadius: "10px",
        }}
      >
        Consultar
      </button>

      {data && (
        <div style={{ marginTop: "20px" }}>
          <p>Facturas: {data.cnt_facturas}</p>
          <p>Transacciones: {data.transacciones}</p>
          <p>Total Neto: {data.total_neto}</p>
        </div>
      )}
    </main>
  );
}