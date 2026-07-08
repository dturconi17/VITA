"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";

import {
  SegmentoComparacion
} from "../hooks/useComparacionSegmentos";


type Props = {

  data: SegmentoComparacion[];

  desde: string;

  hasta: string;

};



export default function ComparacionSegmentos({

  data,

  desde,

  hasta,

}: Props) {


  const datosDesde =
    data.filter(
      x => x.periodo === "Desde"
    );


  const datosHasta =
    data.filter(
      x => x.periodo === "Hasta"
    );



function Grafico({

  titulo,

  datos,

  color

}: {

  titulo:string;

  datos:SegmentoComparacion[];

  color:string;

}) {


    return (

      <div
        style={{
          flex:1,
          height:350,
          background:"#fff",
          padding:20,
          borderRadius:12,
          boxShadow:"0 2px 8px rgba(0,0,0,0.08)"
        }}
      >

        <h3>
          {titulo}
        </h3>


        <ResponsiveContainer
          width="100%"
          height="90%"
        >

          <BarChart
            data={datos}
          >

            <CartesianGrid
              strokeDasharray="3 3"
            />


            <XAxis
              dataKey="tipo_cliente"
            />


            <YAxis/>


            <Tooltip/>


            <Bar
                dataKey="cantidad"
                fill={color}
                />

          </BarChart>


        </ResponsiveContainer>


      </div>

    );

  }



  return (

    <div
      style={{
        display:"flex",
        gap:25,
        marginTop:30
      }}
    >

<Grafico
  titulo={`Distribución ${desde}`}
  datos={datosDesde}
  color="#2563eb"
/>


<Grafico
  titulo={`Distribución ${hasta}`}
  datos={datosHasta}
  color="#16a34a"
/>


    </div>

  );

}