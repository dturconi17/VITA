/*==============================================================
TABLA: sales.ca_cliente_idc

Descripción:
Índice de Desarrollo Comercial por cliente.

Escala:
0 a 100.

Componentes:
- Productos históricos:       30 %
- Frecuencia histórica:       25 %
- Venta mensual histórica:    25 %
- Meses activos históricos:   20 %
==============================================================*/

IF OBJECT_ID('sales.ca_cliente_idc', 'U') IS NOT NULL
BEGIN
    DROP TABLE sales.ca_cliente_idc;
END;

CREATE TABLE sales.ca_cliente_idc
(
    codigo_cliente                VARCHAR(100) NOT NULL,
    cliente_etica                 BIT NULL,
    venta_mensual_historica       DECIMAL(19,4) NOT NULL,
    frecuencia_historica          DECIMAL(19,4) NOT NULL,
    productos_historicos          INT NOT NULL,
    meses_activos_historicos      INT NOT NULL,
    score_venta_mensual           DECIMAL(19,4) NOT NULL,
    score_frecuencia              DECIMAL(19,4) NOT NULL,
    score_productos               DECIMAL(19,4) NOT NULL,
    score_meses_activos           DECIMAL(19,4) NOT NULL,
    idc                           DECIMAL(19,4) NOT NULL,
    segmento_idc                  VARCHAR(30) NOT NULL,
    fecha_corte                   DATE NOT NULL,
    fecha_actualizacion           DATETIME2 NOT NULL,
    CONSTRAINT PK_ca_cliente_idc
        PRIMARY KEY (codigo_cliente)
);