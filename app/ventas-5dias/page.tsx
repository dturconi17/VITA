"use client";
import { useEffect, useState } from "react";

export default function Ventas5Dias() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch("/api/ventas?dias=5")
      .then((res) => res.json())
      .then((data) => setData(data));
  }, []);

  return (
    <main style={{ padding: "20px", maxWidth: "500px", margin: "auto" }}>
      <h1>Ventas últimos 5 días</h1>

      {data ? (
        <div>
          <p>Facturas: {data.cnt_facturas}</p>
          <p>Transacciones: {data.transacciones}</p>
          <p>Total Neto: {data.total_neto}</p>
        </div>
      ) : (
        <p>Cargando...</p>
      )}
    </main>
  );
}