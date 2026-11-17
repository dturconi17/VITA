DROP TABLE IF EXISTS sales.dim_tiempo;

CREATE TABLE sales.dim_tiempo
(
    fecha DATE PRIMARY KEY,
    periodo CHAR(6) NOT NULL,
    año INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    año_mes CHAR(7) NOT NULL,
    año_mes_num INT NOT NULL,
    trimestre INT NOT NULL,
    semana_año INT NOT NULL,
    dia INT NOT NULL,
    dia_semana INT NOT NULL,
    nombre_dia VARCHAR(20) NOT NULL,
    inicio_mes DATE NOT NULL,
    fin_mes DATE NOT NULL,
    es_fin_mes BIT NOT NULL,
    tam VARCHAR(50) NULL
);

CREATE INDEX IX_dim_tiempo_año
ON sales.dim_tiempo(año);

CREATE UNIQUE INDEX IX_dim_tiempo_periodo
ON sales.dim_tiempo(periodo);