PRINT '============================';
PRINT 'REBUILD CUSTOMER ANALYTICS';
PRINT '============================';

---------------------------------------
-- Dimensiones
---------------------------------------

TRUNCATE TABLE sales.dim_producto;
TRUNCATE TABLE sales.dim_cliente;
TRUNCATE TABLE sales.dim_tiempo;

:r .\01_dimensiones\02_load_dim_tiempo.sql
:r .\01_dimensiones\04_load_dim_cliente.sql
:r .\01_dimensiones\06_load_dim_producto.sql

---------------------------------------
-- Facts
---------------------------------------

TRUNCATE TABLE sales.fact_invoice;
TRUNCATE TABLE sales.fact_cliente_mes;

:r .\02_fact_tables\02_load_fact_invoice.sql
:r .\02_fact_tables\04_load_fact_cliente_mes.sql

PRINT 'REBUILD FINALIZADO';