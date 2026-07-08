"use client";


import { useState } from "react";


export type SegmentoComparacion = {

    periodo:string;

    tipo_cliente:string;

    cantidad:number;

};



export function useComparacionSegmentos(){


    const [comparacion,setComparacion] =
        useState<SegmentoComparacion[]>([]);


    const [loading,setLoading] =
        useState(false);



    async function cargarComparacion(
        desde:string,
        hasta:string
    ){


        if(!desde || !hasta)
            return;



        try {


            setLoading(true);


            const response =
                await fetch(
                    "/api/comparacion-segmentos",
                    {
                        method:"POST",

                        headers:{
                            "Content-Type":"application/json"
                        },

                        body:JSON.stringify({
                            desde,
                            hasta
                        })
                    }
                );


            const json =
                await response.json();


            setComparacion(json);


        }
        finally {

            setLoading(false);

        }


    }



    return {

        comparacion,

        loading,

        cargarComparacion

    };


}