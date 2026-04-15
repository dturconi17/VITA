import sql from "mssql";

const config = {
  user: "consulta_ventas",
  password: ".3e1JN$x[k7eB>UC<NTZ",
  server: "148.113.152.56",
  database: "SISVITA",
  options: {
    encrypt: false,
    trustServerCertificate: true,
  },
};

export async function getConnection() {
  try {
    const pool = await sql.connect(config);
    return pool;
  } catch (error) {
    console.error("Error conexión SQL Server:", error);
    throw error;
  }
}