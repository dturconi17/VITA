/*==============================================================
PROYECTO: CUSTOMER ANALYTICS - LÍNEA ÉTICA
OBJETO: sales.ca_cliente

OBJETIVO:
Dataset analítico maestro con una fila por cliente.

GRANULARIDAD:
1 fila = 1 cliente
==============================================================*/

DROP TABLE IF EXISTS sales.ca_cliente;
GO

CREATE TABLE sales.ca_cliente
(
    /*----------------------------------------------------------
      IDENTIFICACIÓN
    ----------------------------------------------------------*/

    codigo_cliente VARCHAR(50) NOT NULL,
    canal VARCHAR(100) NULL,
    ciudad VARCHAR(100) NULL,
    zona_barrio VARCHAR(100) NULL,
    sucursal VARCHAR(100) NULL,
    vendedor VARCHAR(150) NULL,

    /*----------------------------------------------------------
      CICLO DE VIDA Y COHORTES
    ----------------------------------------------------------*/

    fecha_primer_compra DATE NULL,
    fecha_ultima_compra DATE NULL,

    periodo_alta CHAR(6) NULL,
    cohorte_año SMALLINT NULL,
    cohorte_trimestre TINYINT NULL,

    antiguedad_meses INT NULL,
    meses_activos_historicos INT NOT NULL DEFAULT 0,

    /*----------------------------------------------------------
      CLASIFICACIÓN LÍNEA ÉTICA
    ----------------------------------------------------------*/

    cliente_etica BIT NOT NULL DEFAULT 0,

    fecha_primer_etica DATE NULL,
    fecha_ultima_etica DATE NULL,

    periodo_primer_etica CHAR(6) NULL,
    meses_hasta_etica INT NULL,
    meses_comprando_etica INT NOT NULL DEFAULT 0,

    /*----------------------------------------------------------
      COMPORTAMIENTO HISTÓRICO
    ----------------------------------------------------------*/

    venta_historica DECIMAL(19,4) NOT NULL DEFAULT 0,
    venta_etica_historica DECIMAL(19,4) NOT NULL DEFAULT 0,
    venta_no_etica_historica DECIMAL(19,4) NOT NULL DEFAULT 0,

    participacion_etica_historica DECIMAL(19,4) NOT NULL DEFAULT 0,

    facturas_historicas INT NOT NULL DEFAULT 0,
    facturas_etica_historicas INT NOT NULL DEFAULT 0,

    ticket_promedio_historico DECIMAL(19,4) NOT NULL DEFAULT 0,

    frecuencia_historica DECIMAL(19,4) NOT NULL DEFAULT 0,

    productos_historicos INT NOT NULL DEFAULT 0,
    lineas_historicas INT NOT NULL DEFAULT 0,
    unidades_historicas DECIMAL(19,4) NOT NULL DEFAULT 0,
    productos_etica_historicos INT not NULL default 0,
    productos_no_etica_historicos INT not null default 0,
    productos_no_etica_12m INT not NULL default 0,
    venta_mensual_promedio_historica DECIMAL(19,4)
        NOT NULL DEFAULT 0,

    /*----------------------------------------------------------
      COMPORTAMIENTO ACTUAL - ÚLTIMOS 12 MESES
    ----------------------------------------------------------*/

    venta_12m DECIMAL(19,4) NOT NULL DEFAULT 0,
    venta_etica_12m DECIMAL(19,4) NOT NULL DEFAULT 0,
    venta_no_etica_12m DECIMAL(19,4) NOT NULL DEFAULT 0,

    participacion_etica_12m DECIMAL(19,4) NOT NULL DEFAULT 0,

    facturas_12m INT NOT NULL DEFAULT 0,
    facturas_etica_12m INT NOT NULL DEFAULT 0,

    ticket_promedio_12m DECIMAL(19,4) NOT NULL DEFAULT 0,

    meses_activos_12m INT NOT NULL DEFAULT 0,
    frecuencia_12m DECIMAL(19,4) NOT NULL DEFAULT 0,

    productos_12m INT NOT NULL DEFAULT 0,
    productos_etica_12m INT NOT NULL DEFAULT 0,
    lineas_12m INT NOT NULL DEFAULT 0,
    unidades_12m DECIMAL(19,4) NOT NULL DEFAULT 0,

    venta_mensual_promedio_12m DECIMAL(19,4)
        NOT NULL DEFAULT 0,

    /*----------------------------------------------------------
      CARTERA ACTUAL
    ----------------------------------------------------------*/

    compro_ultimos_6m BIT NOT NULL DEFAULT 0,
    cartera_actual BIT NOT NULL DEFAULT 0,
    segmento_cartera VARCHAR(30) NULL,
    estado_cliente VARCHAR(30) NULL,

    /*----------------------------------------------------------
      CONTROL DEL PERÍODO ANALÍTICO
    ----------------------------------------------------------*/

    periodo_maximo_datos CHAR(6) NOT NULL,
    fecha_inicio_12m DATE NOT NULL,
    fecha_fin_analisis DATE NOT NULL,

    /*----------------------------------------------------------
      AUDITORÍA
    ----------------------------------------------------------*/

    fecha_carga DATETIME2 NOT NULL
        CONSTRAINT DF_ca_cliente_fecha_carga
        DEFAULT SYSDATETIME(),

    CONSTRAINT PK_ca_cliente
        PRIMARY KEY CLUSTERED (codigo_cliente)
);
GO

/*==============================================================
ÍNDICES
==============================================================*/

CREATE INDEX IX_ca_cliente_etica
ON sales.ca_cliente(cliente_etica);
GO

CREATE INDEX IX_ca_cliente_cartera_actual
ON sales.ca_cliente(cartera_actual);
GO

CREATE INDEX IX_ca_cliente_segmento_cartera
ON sales.ca_cliente(segmento_cartera);
GO

CREATE INDEX IX_ca_cliente_cohorte
ON sales.ca_cliente(periodo_alta);
GO

CREATE INDEX IX_ca_cliente_canal
ON sales.ca_cliente(canal);
GO

CREATE INDEX IX_ca_cliente_vendedor
ON sales.ca_cliente(vendedor);
GO