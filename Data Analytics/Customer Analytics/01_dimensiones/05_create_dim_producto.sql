DROP TABLE IF EXISTS sales.dim_producto;
CREATE TABLE sales.dim_producto
(
    codigo_producto VARCHAR(50) PRIMARY KEY,
    nombre_producto VARCHAR(250),
    nombre_linea VARCHAR(100),
    producto_etico BIT,
    fecha_primera_venta DATE,
    fecha_ultima_venta DATE,
    clientes_distintos INT,
    facturas_distintas INT,
    unidades_vendidas DECIMAL(19,4),
    venta_total_historica DECIMAL(19,4),
    ticket_promedio DECIMAL(19,4),
    clientes_etica INT,
    penetracion_clientes DECIMAL(10,4),
    ranking_facturacion INT
);


CREATE INDEX IX_dim_producto_linea
ON sales.dim_producto(nombre_linea);

CREATE INDEX IX_dim_producto_etico
ON sales.dim_producto(producto_etico);

CREATE INDEX IX_dim_producto_ranking
ON sales.dim_producto(ranking_facturacion);