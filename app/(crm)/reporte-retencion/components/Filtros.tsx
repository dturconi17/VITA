"use client";

type Props = {
  periodos: string[];
  desde: string;
  hasta: string;
  setDesde: (v: string) => void;
  setHasta: (v: string) => void;
  consultar: () => void;
};

export default function Filtros({
  periodos,
  desde,
  hasta,
  setDesde,
  setHasta,
  consultar,
}: Props) {
  return (
    <div
      style={{
        display: "flex",
        gap: 20,
        alignItems: "end",
        marginBottom: 25,
        padding: "15px 20px",
        background: "#ffffff",
        borderRadius: 12,
        boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
      }}
    >
      <div>
        <label
          style={{
            display: "block",
            marginBottom: 6,
            fontSize: 14,
            fontWeight: 600,
            color: "#334155",
          }}
        >
          Desde
        </label>

        <select
          value={desde}
          onChange={(e) => setDesde(e.target.value)}
          style={{
            padding: "8px 12px",
            borderRadius: 8,
            border: "1px solid #cbd5e1",
            fontSize: 14,
            minWidth: 130,
            background: "#fff",
            cursor: "pointer",
          }}
        >
          <option value="">
            Seleccione...
          </option>

          {periodos.map((p) => (
            <option key={p} value={p}>
              {p}
            </option>
          ))}
        </select>
      </div>


      <div>
        <label
          style={{
            display: "block",
            marginBottom: 6,
            fontSize: 14,
            fontWeight: 600,
            color: "#334155",
          }}
        >
          Hasta
        </label>

        <select
          value={hasta}
          onChange={(e) => setHasta(e.target.value)}
          style={{
            padding: "8px 12px",
            borderRadius: 8,
            border: "1px solid #cbd5e1",
            fontSize: 14,
            minWidth: 130,
            background: "#fff",
            cursor: "pointer",
          }}
        >
          <option value="">
            Seleccione...
          </option>

          {periodos.map((p) => (
            <option key={p} value={p}>
              {p}
            </option>
          ))}
        </select>
      </div>


      <button
        onClick={consultar}
        style={{
          height: 38,
          padding: "0 24px",
          borderRadius: 8,
          border: "none",
          background: "#2563eb",
          color: "#ffffff",
          fontSize: 14,
          fontWeight: 600,
          cursor: "pointer",
          transition: "all 0.2s ease",
          boxShadow: "0 2px 5px rgba(37,99,235,0.3)",
        }}

        onMouseEnter={(e) => {
          e.currentTarget.style.background = "#1d4ed8";
        }}

        onMouseLeave={(e) => {
          e.currentTarget.style.background = "#2563eb";
        }}
      >
        Consultar
      </button>

    </div>
  );
}