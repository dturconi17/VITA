DROP TABLE IF EXISTS sales.fact_invoice;


CREATE TABLE sales.fact_invoice
(
    id_sale_invoice BIGINT PRIMARY KEY,
    codigo_cliente VARCHAR(50),
    fecha_factura DATE,
    periodo char(6),
    año_mes CHAR(7),
    canal VARCHAR(100),
    vendedor VARCHAR(150),
    ciudad VARCHAR(100),
    sucursal VARCHAR(100),
    venta_total DECIMAL(19,4),
    descuento_total DECIMAL(19,4),
    unidades_total DECIMAL(19,4),
    cantidad_lineas INT,
    productos_distintos INT,
    lineas_distintas INT,
    tiene_etica BIT,
    venta_etica DECIMAL(19,4),
    unidades_etica DECIMAL(19,4),
    productos_etica INT,
    porcentaje_etica DECIMAL(10,4),
    productos_no_etica INT,
    venta_no_etica DECIMAL(19,4)
);


CREATE INDEX IX_fact_invoice_cliente
ON sales.fact_invoice(codigo_cliente);

CREATE INDEX IX_fact_invoice_periodo
ON sales.fact_invoice(periodo);

CREATE INDEX IX_fact_invoice_etica
ON sales.fact_invoice(tiene_etica);