DROP TABLE IF EXISTS sales.fact_cliente_mes;
GO

CREATE TABLE sales.fact_cliente_mes
(
    --------------------------------------------------------------------------
    -- Clave técnica
    --------------------------------------------------------------------------
    id_cliente_mes BIGINT IDENTITY(1,1) NOT NULL,

    --------------------------------------------------------------------------
    -- Clave de negocio
    --------------------------------------------------------------------------
    codigo_cliente VARCHAR(50) NOT NULL,
    periodo CHAR(6) NOT NULL,
    año_mes CHAR(7) NOT NULL,
    año SMALLINT NOT NULL,
    mes TINYINT NOT NULL,
    meses_desde_inicio SMALLINT NULL,

    --------------------------------------------------------------------------
    -- Venta mensual
    --------------------------------------------------------------------------
    venta_total DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_venta_total DEFAULT 0,

    venta_etica DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_venta_etica DEFAULT 0,

    venta_otras DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_venta_otras DEFAULT 0,

    descuento_total DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_descuento_total DEFAULT 0,

    unidades DECIMAL(18,2) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_unidades DEFAULT 0,

    --------------------------------------------------------------------------
    -- Facturación
    --------------------------------------------------------------------------
    facturas INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_facturas DEFAULT 0,

    facturas_etica INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_facturas_etica DEFAULT 0,

    facturas_no_etica INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_facturas_no_etica DEFAULT 0,

    --------------------------------------------------------------------------
    -- Ticket
    --------------------------------------------------------------------------
    ticket_promedio DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_ticket_promedio DEFAULT 0,

    ticket_maximo DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_ticket_maximo DEFAULT 0,

    ticket_minimo DECIMAL(19,4) NOT NULL
        CONSTRAINT DF_fact_cliente_mes_ticket_minimo DEFAULT 0,

    --------------------------------------------------------------------------
    -- Diversidad mensual exacta
    --------------------------------------------------------------------------
    productos_distintos INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_productos_distintos DEFAULT 0,

    productos_etica INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_productos_etica DEFAULT 0,

    productos_no_etica INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_productos_no_etica DEFAULT 0,

    lineas_distintas INT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_lineas_distintas DEFAULT 0,

    --------------------------------------------------------------------------
    -- Indicadores
    --------------------------------------------------------------------------
    compro BIT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_compro DEFAULT 0,

    compro_etica BIT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_compro_etica DEFAULT 0,

    compro_no_etica BIT NOT NULL
        CONSTRAINT DF_fact_cliente_mes_compro_no_etica DEFAULT 0,

    --------------------------------------------------------------------------
    -- Auditoría
    --------------------------------------------------------------------------
    fecha_carga DATETIME2 NOT NULL
        CONSTRAINT DF_fact_cliente_mes_fecha_carga
        DEFAULT SYSDATETIME(),

    --------------------------------------------------------------------------
    -- Restricciones
    --------------------------------------------------------------------------
    CONSTRAINT PK_fact_cliente_mes
        PRIMARY KEY CLUSTERED
        (
            id_cliente_mes
        ),

    CONSTRAINT UK_fact_cliente_mes
        UNIQUE
        (
            codigo_cliente,
            periodo
        ),

    CONSTRAINT CK_fact_cliente_mes_mes
        CHECK
        (
            mes BETWEEN 1 AND 12
        ),

    CONSTRAINT CK_fact_cliente_mes_ventas
        CHECK
        (
            venta_total >= 0
            AND venta_etica >= 0
            AND venta_otras >= 0
        ),

    CONSTRAINT CK_fact_cliente_mes_facturas
        CHECK
        (
            facturas >= 0
            AND facturas_etica >= 0
            AND facturas_no_etica >= 0
        ),

    CONSTRAINT CK_fact_cliente_mes_productos
        CHECK
        (
            productos_distintos >= 0
            AND productos_etica >= 0
            AND productos_no_etica >= 0
        )
);
GO

/******************************************************************************
Índices
******************************************************************************/

CREATE INDEX IX_fact_cliente_mes_periodo
ON sales.fact_cliente_mes
(
    periodo
)
INCLUDE
(
    venta_total,
    venta_etica,
    venta_otras,
    facturas,
    productos_distintos
);
GO

CREATE INDEX IX_fact_cliente_mes_periodo_etica
ON sales.fact_cliente_mes
(
    periodo,
    compro_etica
)
INCLUDE
(
    codigo_cliente,
    venta_total,
    venta_etica,
    facturas,
    productos_etica
);
GO

CREATE INDEX IX_fact_cliente_mes_cartera_etica
ON sales.fact_cliente_mes
(
    compro_etica,
    periodo
)
INCLUDE
(
    codigo_cliente,
    venta_total,
    venta_etica,
    venta_otras
);
GO


EXEC sys.sp_addextendedproperty
    @name = N'Descripcion',
    @value = N'Feature Store mensual por cliente utilizado por Customer Analytics',
    @level0type = N'SCHEMA',
    @level0name = N'sales',
    @level1type = N'TABLE',
    @level1name = N'fact_cliente_mes';
GO

EXEC sys.sp_addextendedproperty
    @name = N'Descripcion',
    @value = N'Cantidad de productos distintos de Línea Ética comprados por el cliente durante el mes',
    @level0type = N'SCHEMA',
    @level0name = N'sales',
    @level1type = N'TABLE',
    @level1name = N'fact_cliente_mes',
    @level2type = N'COLUMN',
    @level2name = N'productos_etica';
GO

EXEC sys.sp_addextendedproperty
    @name = N'Descripcion',
    @value = N'Cantidad de productos distintos fuera de Línea Ética comprados por el cliente durante el mes',
    @level0type = N'SCHEMA',
    @level0name = N'sales',
    @level1type = N'TABLE',
    @level1name = N'fact_cliente_mes',
    @level2type = N'COLUMN',
    @level2name = N'productos_no_etica';
GO