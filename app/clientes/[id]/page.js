export default function ClienteDetalle({ params }) {
  const { id } = params;

  return (
    <main style={{ padding: "20px", maxWidth: "500px", margin: "auto" }}>
      <h1>Detalle del Cliente</h1>

      <p><strong>ID:</strong> {id}</p>

      <div style={{ marginTop: "20px" }}>
        <h3>Farmacia {id}</h3>
        <p>Última visita: Hace X días</p>

        <button
          style={{
            width: "100%",
            padding: "15px",
            marginTop: "10px",
            backgroundColor: "black",
            color: "white",
            borderRadius: "10px",
          }}
        >
          Registrar visita
        </button>
      </div>
    </main>
  );
}