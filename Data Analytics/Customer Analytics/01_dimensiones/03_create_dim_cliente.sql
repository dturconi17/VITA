DROP TABLE IF EXISTS sales.dim_cliente;

CREATE TABLE sales.dim_cliente
(
    codigo_cliente VARCHAR(50) PRIMARY KEY,
    canal VARCHAR(100),
    ciudad VARCHAR(100),
    zona_barrio VARCHAR(100),
    sucursal VARCHAR(100),
    vendedor VARCHAR(150),
    fecha_primer_compra DATE,
    fecha_ultima_compra DATE,
    mes_primer_compra CHAR(7),
    mes_ultima_compra CHAR(7),
    antiguedad_meses INT,
    cantidad_facturas INT,
    venta_total_historica DECIMAL(19,4),
    unidades_historicas DECIMAL(19,4),
    productos_distintos INT,
    lineas_distintas INT,
    cliente_etica BIT,
    fecha_primer_etica DATE,
    fecha_ultima_etica DATE,
    venta_etica_historica DECIMAL(19,4),
    porcentaje_etica DECIMAL(10,4),
    meses_comprando_etica INT,
    estado_cliente VARCHAR(30),
    health_score DECIMAL(10,2) NULL,
    cdi DECIMAL(10,2) NULL,
    segmento VARCHAR(50) NULL,
    riesgo_abandono VARCHAR(50) NULL,
    potencial_etica VARCHAR(50) NULL
);


CREATE INDEX IX_dim_cliente_estado
ON sales.dim_cliente(estado_cliente);

CREATE INDEX IX_dim_cliente_etica
ON sales.dim_cliente(cliente_etica);

CREATE INDEX IX_dim_cliente_canal
ON sales.dim_cliente(canal);