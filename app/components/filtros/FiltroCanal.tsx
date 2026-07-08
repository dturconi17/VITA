"use client";

import { useEffect, useState } from "react";

type Canal = {
  nombre_grupo: string;
};

type Props = {
  value: string;
  onChange: (value: string) => void;
};

export default function CanalFilter({ value, onChange }: Props) {
  const [canales, setCanales] = useState<Canal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    const fetchCanales = async () => {
      try {
        setLoading(true);

        const res = await fetch("/api/canales");
        const data = await res.json();

        setCanales(data);
      } catch (err) {
        setError("Error al cargar canales");
      } finally {
        setLoading(false);
      }
    };

    fetchCanales();
  }, []);

  if (loading) return <p>Cargando canales...</p>;
  if (error) return <p>{error}</p>;

  return (
    <div style={{ marginBottom: "1rem" }}>
      <label style={{ display: "block", marginBottom: "0.5rem" }}>
    
      </label>

      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{
          padding: "8px",
          borderRadius: "6px",
          border: "1px solid #ccc",
          minWidth: "220px",
        }}
      >
        <option value="">Todos los Canales</option>

        {canales.map((c) => (
          <option key={c.nombre_grupo} value={c.nombre_grupo}>
            {c.nombre_grupo}
          </option>
        ))}
      </select>
    </div>
  );
}