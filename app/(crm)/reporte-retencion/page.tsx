
"use client";

import { useMemo, useState } from "react";
import Filtros from "./components/Filtros";
import { useRetencion } from "./hooks/useRetencion";
import type { ClienteMigracion } from "./types";

const ESTADOS = [
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

const CICLOS = [
  "Dentro de ciclo",
  "Alerta de ciclo",
  "Atrasado",
  "Muy atrasado",
  "Sin historial suficiente",
];

const nf = new Intl.NumberFormat("es-AR");

type Vista = "comercial" | "ciclo";
type CampoOrigen = "estado_origen" | "ciclo_origen";
type CampoDestino = "estado_destino" | "ciclo_destino";

function normalizar(valor: unknown): string {
  if (valor === null || valor === undefined || valor === "") {
    return "Sin registro";
  }
  return String(valor);
}

function porcentaje(n: number, total: number): string {
  return total > 0
    ? `${(n / total * 100).toFixed(1)}%`
    : "0,0%";
}

function mesLegible(periodo: string): string {
  if (!/^\d{6}$/.test(periodo)) return periodo;

  const fecha = new Date(
    Number(periodo.slice(0, 4)),
    Number(periodo.slice(4, 6)) - 1,
    1
  );

  return new Intl.DateTimeFormat("es-AR", {
    month: "long",
    year: "numeric",
  }).format(fecha);
}

function Tarjeta({
  titulo,
  valor,
  subtitulo,
}: {
  titulo: string;
  valor: string;
  subtitulo?: string;
}) {
  return (
    <div
      style={{
        background: "#fff",
        padding: 18,
        border: "1px solid #e2e8f0",
        borderRadius: 12,
      }}
    >
      <div style={{ fontSize: 13, color: "#64748b" }}>
        {titulo}
      </div>

      <div
        style={{
          fontSize: 27,
          fontWeight: 700,
          marginTop: 8,
          color: "#0f172a",
        }}
      >
        {valor}
      </div>

      {subtitulo && (
        <div
          style={{
            fontSize: 12,
            color: "#64748b",
            marginTop: 5,
          }}
        >
          {subtitulo}
        </div>
      )}
    </div>
  );
}

function Barra({
  valor,
  total,
  color,
}: {
  valor: number;
  total: number;
  color: string;
}) {
  return (
    <div
      style={{
        width: "100%",
        height: 13,
        borderRadius: 8,
        overflow: "hidden",
        background: "#e2e8f0",
      }}
    >
      <div
        style={{
          width: `${total > 0 ? valor / total * 100 : 0}%`,
          height: "100%",
          background: color,
          borderRadius: 8,
          transition: "width 0.2s ease",
        }}
      />
    </div>
  );
}

function AnalisisMigracion({
  clientes,
  desde,
  hasta,
  vista,
}: {
  clientes: ClienteMigracion[];
  desde: string;
  hasta: string;
  vista: Vista;
}) {
  const [seleccionado, setSeleccionado] = useState<string | null>(
    null
  );

  const campoOrigen: CampoOrigen =
    vista === "comercial" ? "estado_origen" : "ciclo_origen";

  const campoDestino: CampoDestino =
    vista === "comercial" ? "estado_destino" : "ciclo_destino";

  const orden = vista === "comercial" ? ESTADOS : CICLOS;

  // Solo clientes que tienen registro en el mes Hasta.
  const clientesDestino = clientes.filter(
    c => normalizar(c[campoDestino]) !== "Sin registro"
  );

  const totalDestino = clientesDestino.length;

  const categorias = Array.from(
    new Set(
      clientesDestino.map(c => normalizar(c[campoDestino]))
    )
  );

  const categoriasOrdenadas = [
    ...orden.filter(x => categorias.includes(x)),
    ...categorias.filter(x => !orden.includes(x)).sort(),
  ];

  const destinos = categoriasOrdenadas.map(estado => {
    const grupo = clientesDestino.filter(
      c => normalizar(c[campoDestino]) === estado
    );

    return {
      estado,
      cantidad: grupo.length,
      clientes: grupo,
    };
  });

  // Al cambiar la vista o los períodos, se elige el primer
  // estado disponible si no hay una selección válida.
  const activo =
    destinos.find(d => d.estado === seleccionado) ??
    destinos[0] ??
    null;

  const totalSeleccionado = activo?.cantidad ?? 0;

  const origenes = activo
    ? Array.from(
      new Set(
        activo.clientes.map(c =>
          normalizar(c[campoOrigen])
        )
      )
    )
    : [];

  const origenesOrdenados = [
    ...orden.filter(x => origenes.includes(x)),
    ...origenes.filter(x => !orden.includes(x)).sort(),
  ];

  const desglose = origenesOrdenados.map(estado => ({
    estado,
    cantidad: activo
      ? activo.clientes.filter(
        c => normalizar(c[campoOrigen]) === estado
      ).length
      : 0,
  }));

  const permanecen = desglose.find(
    d => d.estado === activo?.estado
  )?.cantidad ?? 0;

  const migraron = totalSeleccionado - permanecen;

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns:
          "repeat(auto-fit, minmax(min(100%, 380px), 1fr))",
        gap: 20,
        marginTop: 22,
        alignItems: "start",
      }}
    >
      {/* MES DESTINO */}
      <section
        style={{
          background: "#fff",
          border: "1px solid #e2e8f0",
          borderRadius: 14,
          padding: 22,
        }}
      >
        <div
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: "#64748b",
            textTransform: "uppercase",
          }}
        >
          Mes Hasta · Destino
        </div>

        <h2
          style={{
            fontSize: 21,
            margin: "7px 0",
            textTransform: "capitalize",
          }}
        >
          {mesLegible(hasta)}
        </h2>

        <p style={{ color: "#64748b", fontSize: 13 }}>
          {nf.format(totalDestino)} farmacias.
          Seleccioná un estado para analizar su origen.
        </p>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 10,
            marginTop: 22,
          }}
        >
          {destinos.map(d => {
            const estaSeleccionado =
              activo?.estado === d.estado;

            return (
              <button
                key={d.estado}
                type="button"
                onClick={() => setSeleccionado(d.estado)}
                style={{
                  textAlign: "left",
                  background: estaSeleccionado
                    ? "#f0fdf4"
                    : "#fff",
                  border: estaSeleccionado
                    ? "2px solid #16a34a"
                    : "1px solid #e2e8f0",
                  borderRadius: 10,
                  padding: 13,
                  cursor: "pointer",
                  color: "#0f172a",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    gap: 12,
                    alignItems: "center",
                    marginBottom: 9,
                  }}
                >
                  <strong style={{ fontSize: 13 }}>
                    {d.estado}
                  </strong>

                  <span
                    style={{
                      fontSize: 13,
                      whiteSpace: "nowrap",
                      fontWeight: 600,
                    }}
                  >
                    {nf.format(d.cantidad)}
                    {" · "}
                    {porcentaje(d.cantidad, totalDestino)}
                  </span>
                </div>

                <Barra
                  valor={d.cantidad}
                  total={totalDestino}
                  color={
                    estaSeleccionado ? "#16a34a" : "#94a3b8"
                  }
                />
              </button>
            );
          })}
        </div>

        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginTop: 20,
            paddingTop: 15,
            borderTop: "1px solid #e2e8f0",
            fontWeight: 700,
          }}
        >
          <span>Total destino</span>
          <span>{nf.format(totalDestino)} · 100%</span>
        </div>
      </section>

      {/* MES ORIGEN */}
      <section
        style={{
          background: "#fff",
          border: "1px solid #e2e8f0",
          borderRadius: 14,
          padding: 22,
        }}
      >
        <div
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: "#64748b",
            textTransform: "uppercase",
          }}
        >
          Mes Desde · Origen
        </div>

        <h2
          style={{
            fontSize: 21,
            margin: "7px 0",
            textTransform: "capitalize",
          }}
        >
          {mesLegible(desde)}
        </h2>

        {activo ? (
          <>
            <p style={{ color: "#64748b", fontSize: 13 }}>
              ¿Cómo estaban clasificadas las{" "}
              <strong>{nf.format(activo.cantidad)}</strong>{" "}
              farmacias que terminaron en{" "}
              <strong>{activo.estado}</strong>?
            </p>

            <div
              style={{
                display: "flex",
                flexDirection: "column",
                gap: 18,
                marginTop: 24,
              }}
            >
              {desglose.map(d => {
                const mismoEstado =
                  d.estado === activo.estado;

                return (
                  <div key={d.estado}>
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: 10,
                        fontSize: 13,
                        marginBottom: 8,
                      }}
                    >
                      <span>{d.estado}</span>

                      <strong style={{ whiteSpace: "nowrap" }}>
                        {nf.format(d.cantidad)}
                        {" · "}
                        {porcentaje(
                          d.cantidad,
                          totalSeleccionado
                        )}
                      </strong>
                    </div>

                    <Barra
                      valor={d.cantidad}
                      total={totalSeleccionado}
                      color={
                        mismoEstado ? "#16a34a" : "#f59e0b"
                      }
                    />
                  </div>
                );
              })}
            </div>

            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 12,
                marginTop: 28,
              }}
            >
              <div
                style={{
                  padding: 14,
                  borderRadius: 10,
                  background: "#f0fdf4",
                }}
              >
                <div style={{ fontSize: 12 }}>
                  Mismo estado
                </div>
                <strong style={{ fontSize: 21 }}>
                  {porcentaje(
                    permanecen,
                    totalSeleccionado
                  )}
                </strong>
                <div style={{ fontSize: 12 }}>
                  {nf.format(permanecen)} farmacias
                </div>
              </div>

              <div
                style={{
                  padding: 14,
                  borderRadius: 10,
                  background: "#fffbeb",
                }}
              >
                <div style={{ fontSize: 12 }}>
                  Otro estado o sin registro
                </div>
                <strong style={{ fontSize: 21 }}>
                  {porcentaje(
                    migraron,
                    totalSeleccionado
                  )}
                </strong>
                <div style={{ fontSize: 12 }}>
                  {nf.format(migraron)} farmacias
                </div>
              </div>
            </div>

            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                borderTop: "1px solid #e2e8f0",
                paddingTop: 15,
                marginTop: 22,
                fontWeight: 700,
              }}
            >
              <span>Total seleccionado</span>
              <span>
                {nf.format(totalSeleccionado)} · 100%
              </span>
            </div>
          </>
        ) : (
          <p>No hay farmacias para el período elegido.</p>
        )}
      </section>
    </div>
  );
}

export default function ReporteRetencionPage() {
  const {
    data,
    periodos,
    desde,
    hasta,
    setDesde,
    setHasta,
    recargar,
    loading,
    error,
  } = useRetencion();

  const [vista, setVista] = useState<Vista>("comercial");

  const resumen = useMemo(() => {
    if (!data) return null;

    const conDestino = data.filter(
      c => c.estado_destino !== "Sin registro"
    );

    const conAmbos = conDestino.filter(
      c => c.estado_origen !== "Sin registro"
    );
    const cambios = conAmbos.filter(
      c => c.estado_origen !== c.estado_destino
    ).length;

    const contar = (movimiento: string) =>
      data.filter(
        c => c.movimiento_compra === movimiento
      ).length;

    return {
      totalDestino: conDestino.length,
      comparables: conAmbos.length,
      cambios,
      permanecen: conAmbos.length - cambios,
      ingresos: conDestino.length - conAmbos.length,
      reactivados: contar("Reactivado"),
      dejaron: contar("Dejo de comprar"),
    };
  }, [data]);

  return (
    <div
      style={{
        padding: 30,
        background: "#f8fafc",
        minHeight: "100vh",
        color: "#0f172a",
      }}
    >
      <h1 style={{ fontSize: 28, marginBottom: 8 }}>
        Migración de Clientes
      </h1>

      <p
        style={{
          color: "#64748b",
          marginBottom: 25,
        }}
      >
        Análisis interactivo de la evolución comercial
        y los ciclos de consumo.
      </p>

      <Filtros
        periodos={periodos}
        desde={desde}
        hasta={hasta}
        setDesde={setDesde}
        setHasta={setHasta}
        consultar={recargar}
      />

      {loading && <p>Cargando información...</p>}

      {error && (
        <p style={{ color: "#dc2626" }}>{error}</p>
      )}

      {data && resumen && (
        <>
          <div
            style={{
              display: "grid",
              gridTemplateColumns:
                "repeat(auto-fit, minmax(175px, 1fr))",
              gap: 14,
              marginTop: 24,
            }}
          >
            <Tarjeta
              titulo="Farmacias en destino"
              valor={nf.format(resumen.totalDestino)}
            />

            <Tarjeta
              titulo="Cambian de estado"
              valor={nf.format(resumen.cambios)}
              subtitulo={porcentaje(
                resumen.cambios,
                resumen.comparables
              ) + " de las comparables"}
            />

            <Tarjeta
              titulo="Mantienen su estado"
              valor={nf.format(resumen.permanecen)}
              subtitulo={porcentaje(
                resumen.permanecen,
                resumen.comparables
              ) + " de las comparables"}
            />

            <Tarjeta
              titulo="Ingresos al histórico"
              valor={nf.format(resumen.ingresos)}
              subtitulo={porcentaje(
                resumen.ingresos,
                resumen.totalDestino
              ) + " del destino"}
            />

            <Tarjeta
              titulo="Reactivadas"
              valor={nf.format(resumen.reactivados)}
            />

            <Tarjeta
              titulo="Dejaron de comprar"
              valor={nf.format(resumen.dejaron)}
            />
          </div>

          <div
            style={{
              display: "flex",
              gap: 10,
              marginTop: 28,
              flexWrap: "wrap",
            }}
          >
            <button
              type="button"
              onClick={() => setVista("comercial")}
              style={{
                padding: "11px 18px",
                borderRadius: 8,
                cursor: "pointer",
                border: "none",
                background:
                  vista === "comercial"
                    ? "#0f172a"
                    : "#e2e8f0",
                color:
                  vista === "comercial"
                    ? "#fff"
                    : "#334155",
              }}
            >
              Estados comerciales
            </button>

            <button
              type="button"
              onClick={() => setVista("ciclo")}
              style={{
                padding: "11px 18px",
                borderRadius: 8,
                cursor: "pointer",
                border: "none",
                background:
                  vista === "ciclo"
                    ? "#0f172a"
                    : "#e2e8f0",
                color:
                  vista === "ciclo"
                    ? "#fff"
                    : "#334155",
              }}
            >
              Ciclos de consumo
            </button>
          </div>

          <AnalisisMigracion
            key={`${vista}-${desde}-${hasta}`}
            clientes={data}
            desde={desde}
            hasta={hasta}
            vista={vista}
          />
        </>
      )}
    </div>
  );
}
