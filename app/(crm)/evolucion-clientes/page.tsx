
"use client";

import { useEffect, useMemo, useState } from "react";

type Registro = {
    periodo: string;
    estado: string;
    cantidad: number;
};

const ORDEN = [
    "Cliente Nuevo",
    "Activo Fiel",
    "Activo Casi Fiel",
    "Activo Despierto",
    "En Pausa",
    "Infiel",
    "Dormido",
    "Reconquista",
    "Perdida Nivel 1",
    "Perdida Nivel 2",
];

const COLORES_ESTADOS: Record<string, string> = {
    "Cliente Nuevo": "#06b6d4",
    "Activo Fiel": "#16a34a",
    "Activo Casi Fiel": "#2563eb",
    "Activo Despierto": "#8b5cf6",
    "En Pausa": "#f59e0b",
    "Infiel": "#f97316",
    "Dormido": "#64748b",
    "Reconquista": "#14b8a6",
    "Perdida Nivel 1": "#ef4444",
    "Perdida Nivel 2": "#991b1b",
    "Sin clasificación": "#94a3b8",
};

const nf = new Intl.NumberFormat("es-AR");

function nombreMes(periodo: string) {
    if (!/^\d{6}$/.test(periodo)) return periodo;

    const fecha = new Date(
        Number(periodo.slice(0, 4)),
        Number(periodo.slice(4, 6)) - 1,
        1
    );

    return new Intl.DateTimeFormat("es-AR", {
        month: "short",
        year: "2-digit",
    }).format(fecha);
}

function GraficoEstado({
    estado,
    registros,
    meses,
}: {
    estado: string;
    registros: Registro[];
    meses: string[];
}) {
    const cantidades = meses.map(mes => {
        const registro = registros.find(
            r => r.periodo === mes && r.estado === estado
        );

        return Number(registro?.cantidad ?? 0);
    });

    const maximo = Math.max(1, ...cantidades);
    const color = COLORES_ESTADOS[estado] ?? "#64748b";
    const primero = cantidades[0] ?? 0;
    const ultimo = cantidades[cantidades.length - 1] ?? 0;

    const variacion =
        primero > 0
            ? (ultimo / primero - 1) * 100
            : null;

    return (
        <section style={{
            background: "#fff",
            border: "1px solid #e2e8f0",
            borderRadius: 14,
            padding: 22,
            minWidth: 0,
        }}>
            <h2 style={{
                fontSize: 17,
                margin: "0 0 18px",
            }}>
                {estado}
            </h2>

            <div style={{
                display: "flex",
                alignItems: "end",
                gap: 12,
                height: 280,
                overflowX: "auto",
                paddingBottom: 8,
            }}>
                {meses.map((mes, i) => (
                    <div
                        key={mes}
                        style={{
                            minWidth: 55,
                            flex: "1 0 55px",
                            height: "100%",
                            display: "flex",
                            flexDirection: "column",
                            justifyContent: "flex-end",
                            alignItems: "center",
                            gap: 6,
                        }}
                    >
                        <span style={{
                            fontSize: 11,
                            fontWeight: 600,
                        }}>
                            {nf.format(cantidades[i])}
                        </span>

                        <div style={{
                            height: `${cantidades[i] / maximo * 75
                                }%`,
                            width: "75%",
                            minHeight: cantidades[i] > 0 ? 3 : 0,
                            background: color,
                            borderRadius: "5px 5px 0 0",
                        }} />

                        <span style={{
                            fontSize: 11,
                            color: "#64748b",
                            whiteSpace: "nowrap",
                        }}>
                            {nombreMes(mes)}
                        </span>
                    </div>
                ))}
            </div>

            <div style={{
                display: "flex",
                justifyContent: "space-between",
                gap: 10,
                borderTop: "1px solid #e2e8f0",
                paddingTop: 14,
                marginTop: 10,
                fontSize: 12,
            }}>
                <div>
                    <div style={{ color: "#64748b" }}>
                        Inicio
                    </div>
                    <strong>{nf.format(primero)}</strong>
                </div>

                <div>
                    <div style={{ color: "#64748b" }}>
                        Final
                    </div>
                    <strong>{nf.format(ultimo)}</strong>
                </div>

                <div>
                    <div style={{ color: "#64748b" }}>
                        Variación
                    </div>
                    <strong style={{
                        color: variacion === null
                            ? "#64748b"
                            : variacion >= 0
                                ? "#16a34a"
                                : "#dc2626",
                    }}>
                        {variacion === null
                            ? "N/D"
                            : `${variacion > 0 ? "+" : ""}${variacion.toFixed(1)}%`}
                    </strong>
                </div>
            </div>
        </section>
    );
}

export default function EvolucionClientesPage() {
    const [periodos, setPeriodos] = useState<string[]>([]);
    const [desde, setDesde] = useState("");
    const [hasta, setHasta] = useState("");
    const [rangoConsultado, setRangoConsultado] = useState<{
        desde: string;
        hasta: string;
    } | null>(null);
    const [datos, setDatos] = useState<Registro[]>([]);
    const [consultado, setConsultado] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    useEffect(() => {
        async function cargarPeriodos() {
            try {
                const response = await fetch(
                    "/api/reporte-retencion/periodos"
                );

                if (!response.ok) {
                    throw new Error("Error cargando períodos.");
                }

                const json: { periodo: string }[] =
                    await response.json();

                const lista = json
                    .map(x => String(x.periodo))
                    .sort()
                    .reverse();

                setPeriodos(lista);

                if (lista.length >= 2) {
                    setDesde(lista[Math.min(5, lista.length - 1)]);
                    setHasta(lista[0]);
                }
            } catch (err) {
                console.error(err);
                setError("No fue posible cargar los períodos.");
            }
        }

        cargarPeriodos();
    }, []);

    async function consultar() {
        if (!desde || !hasta) return;

        const desdeConsulta = desde;
        const hastaConsulta = hasta;

        setLoading(true);
        setError("");
        setConsultado(false);

        try {
            const response = await fetch(
                "/api/evolucion-clientes",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({ desde, hasta }),
                }
            );

            const json = await response.json();

            if (!response.ok) {
                throw new Error(
                    json.error ?? "Error obteniendo evolución."
                );
            }

            if (!Array.isArray(json.datos)) {
                throw new Error("Respuesta inválida de la API.");
            }

            setDatos(
                json.datos.map((r: Registro) => ({
                    periodo: String(r.periodo).trim(),
                    estado: String(r.estado).trim(),
                    cantidad: Number(r.cantidad) || 0,
                }))
            );

            setRangoConsultado({
                desde: desdeConsulta,
                hasta: hastaConsulta,
            });

            setConsultado(true);

            console.log(
                "Clientes nuevos:",
                json.datos.filter(
                    (r: { estado: string }) =>
                        r.estado === "Cliente Nuevo"
                )
            );

        } catch (err) {
            setError(
                err instanceof Error
                    ? err.message
                    : "Error consultando datos."
            );
        } finally {
            setLoading(false);
        }
    }

    const meses = useMemo(() => {
        if (!rangoConsultado) return [];

        return periodos
            .filter(
                p =>
                    p >= rangoConsultado.desde &&
                    p <= rangoConsultado.hasta
            )
            .sort();
    }, [periodos, rangoConsultado]);

    const estados = useMemo(() => {
        const presentes = Array.from(
            new Set(datos.map(d => d.estado))
        );

        return [
            ...ORDEN.filter(e => presentes.includes(e)),
            ...presentes.filter(e => !ORDEN.includes(e)).sort(),
        ];
    }, [datos]);

    return (
        <main style={{
            padding: 30,
            background: "#f8fafc",
            minHeight: "100vh",
            color: "#0f172a",
        }}>
            <h1 style={{
                fontSize: 28,
                marginBottom: 8,
            }}>
                Evolución de Clientes
            </h1>

            <p style={{
                color: "#64748b",
                marginBottom: 24,
            }}>
                Cantidad mensual de farmacias por estado comercial.
            </p>

            <div style={{
                display: "flex",
                gap: 14,
                alignItems: "end",
                flexWrap: "wrap",
                padding: 20,
                borderRadius: 12,
                background: "#fff",
                border: "1px solid #e2e8f0",
                marginBottom: 25,
            }}>
                <label>
                    Desde
                    <select
                        value={desde}
                        onChange={e => setDesde(e.target.value)}
                        style={{
                            display: "block",
                            padding: 9,
                            marginTop: 6,
                            border: "1px solid #cbd5e1",
                            borderRadius: 7,
                        }}
                    >
                        {periodos.map(p => (
                            <option key={p} value={p}>
                                {p}
                            </option>
                        ))}
                    </select>
                </label>

                <label>
                    Hasta
                    <select
                        value={hasta}
                        onChange={e => setHasta(e.target.value)}
                        style={{
                            display: "block",
                            padding: 9,
                            marginTop: 6,
                            border: "1px solid #cbd5e1",
                            borderRadius: 7,
                        }}
                    >
                        {periodos.map(p => (
                            <option key={p} value={p}>
                                {p}
                            </option>
                        ))}
                    </select>
                </label>

                <button
                    onClick={consultar}
                    disabled={loading || !desde || !hasta || desde > hasta}
                    style={{
                        background: "#2563eb",
                        color: "#fff",
                        padding: "10px 20px",
                        border: "none",
                        borderRadius: 7,
                        cursor: "pointer",
                    }}
                >
                    {loading ? "Consultando..." : "Consultar"}
                </button>
            </div>

            {error && (
                <p style={{ color: "#dc2626" }}>{error}</p>
            )}

            {consultado && (
                <>
                    <p style={{
                        color: "#64748b",
                        marginBottom: 16,
                    }}>
                        {meses.length} períodos analizados ·{" "}
                        {estados.length} estados comerciales
                        {" · "}
                        Desde {rangoConsultado?.desde}
                        {" hasta "}
                        {rangoConsultado?.hasta}
                    </p>

                    <div style={{
                        display: "grid",
                        gridTemplateColumns: "minmax(0, 1fr)",
                        gap: 20,
                    }}>
                        {estados.map(estado => (
                            <GraficoEstado
                                key={estado}
                                estado={estado}
                                registros={datos}
                                meses={meses}
                            />
                        ))}
                    </div>

                    {datos.length === 0 && (
                        <p>No se encontraron datos para el rango seleccionado.</p>
                    )}
                </>
            )}
        </main>
    );
}
