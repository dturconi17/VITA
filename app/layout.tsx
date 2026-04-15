import "./globals.css";
import Link from "next/link";

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <body style={{ margin: 0 }}>
        <div style={container}>
          
          {/* SIDEBAR */}
          <aside style={sidebar}>
            <div style={logoContainer}>
              <img src="/vita2.jfif" alt="Logo" style={{ height: "100px" }} />
              <h3>CRM Ventas</h3>
            </div>

            <nav style={menu}>
              <Link href="/" style={link}>🏠 Home</Link>
              <Link href="/dashboard" style={link}>📊 Dashboard</Link>
              <Link href="/ventas" style={link}>📈 Ventas</Link>
              <Link href="/ventas-5dias" style={link}>⏱ Últimos 5 días</Link>
              <Link href="/ventas-rango" style={link}>📅 Rango de fechas</Link>
            </nav>
          </aside>

          {/* CONTENIDO */}
          <main style={content}>
            {children}
          </main>

        </div>
      </body>
    </html>
  );
}

const container = {
  display: "flex",
  height: "100vh",
};

const sidebar = {
  width: "220px",
  backgroundColor: "#111",
  color: "white",
  padding: "20px",
  display: "flex",
  flexDirection: "column",
};

const logoContainer = {
  marginBottom: "30px",
  textAlign: "center",
};

const menu = {
  display: "flex",
  flexDirection: "column",
  gap: "15px",
};

const link = {
  color: "white",
  textDecoration: "none",
  padding: "10px",
  borderRadius: "8px",
  display: "block",
};

const content = {
  flex: 1,
  padding: "20px",
  overflowY: "auto",
};