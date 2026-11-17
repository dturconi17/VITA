export interface ResumenRetencion {
    clientes_mes:number;
    activos:number;
    perdidos:number;
    recuperados:number;
    clientes_mes_desde:number;
    retencion:number;
    recuperacion:number;
}


export interface ClienteMigracion {
  codigo_cliente: string;
  nombre_cliente: string;
  nombre_subgrupo: string;

  estado_origen: string;
  estado_destino: string;

  ciclo_origen: string;
  ciclo_destino: string;

  compro_origen: number;
  compro_destino: number;

  venta_origen: number;
  venta_destino: number;

  movimiento_compra: string;
}
