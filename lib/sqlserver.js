import sql from "mssql";

const config = {
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
