"use client";
import { useEffect, useState } from "react";

export default function VentasPage() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch("/api/ventas")
      .then((res) => res.json())
      .then((data) => setData(data));
  }, []);

  return (
    <main style={{ padding: "20px", maxWidth: "500px", margin: "auto" }}>
      <h1>Ventas del día</h1>

      {data ? (
        <div style={{ marginTop: "20px" }}>
          <p>Facturas: {data.cnt_facturas}</p>
          <p>Transacciones: {data.transacciones}</p>
          <p>Total Bruto: {data.total_bruto}</p>
          <p>Total Neto: {data.total_neto}</p>
          <p>Descuento: {data.total_descuento}</p>
        </div>
      ) : (
        <p>Cargando...</p>
      )}
    </main>
  );
}