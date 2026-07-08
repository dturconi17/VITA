create table sales.crm_matriz_clientes 
(mes_5	int,
mes_4	int,
mes_3	int,
mes_2	int,
mes_1	int,
mes_0	int,
actual	varchar(30),
historia	varchar(30),
realidad	varchar(30),
tipo_cliente	varchar(30),
accion	varchar(30)
)

insert into sales.crm_matriz_clientes values (1,1,1,1,1,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (1,1,1,1,1,0,'Cliente','Cliente','No Consume','Fiel Inactivo','Activar')
insert into sales.crm_matriz_clientes values (1,1,1,1,0,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (1,1,1,1,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,1,1,0,1,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (1,1,1,0,1,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,1,1,0,0,1,'Cliente','Cliente','Consume','Reactivado','Retener')
insert into sales.crm_matriz_clientes values (1,1,1,0,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,1,0,1,1,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (1,1,0,1,1,0,'Cliente','Cliente','No Consume','Itinerante','Activar')
insert into sales.crm_matriz_clientes values (1,1,0,1,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,1,0,1,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,1,0,0,1,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,1,0,0,1,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,1,0,0,0,1,'Cliente','Cliente','Consume','Reconquista','Retener')
insert into sales.crm_matriz_clientes values (1,1,0,0,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,0,1,1,1,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (1,0,1,1,1,0,'Cliente','Cliente','No Consume','Fiel Inactivo','Activar')
insert into sales.crm_matriz_clientes values (1,0,1,1,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,0,1,1,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,0,1,0,1,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,0,1,0,1,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,0,1,0,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,0,1,0,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (1,0,0,1,1,1,'Cliente','No Cliente','Consume','Reactivado','Retener')
insert into sales.crm_matriz_clientes values (1,0,0,1,1,0,'Cliente','No Cliente','No Consume','Itinerante','Activar')
insert into sales.crm_matriz_clientes values (1,0,0,1,0,1,'Cliente','No Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (1,0,0,1,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (1,0,0,0,1,1,'Cliente','No Cliente','Consume','Reconquista','Retener')
insert into sales.crm_matriz_clientes values (1,0,0,0,1,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (1,0,0,0,0,1,'Cliente','No Cliente','Consume','Cliente Nuevo','Retener')
insert into sales.crm_matriz_clientes values (1,0,0,0,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,1,1,1,1,1,'Cliente','Cliente','Consume','Fiel','Retener')
insert into sales.crm_matriz_clientes values (0,1,1,1,1,0,'Cliente','Cliente','No Consume','Fiel Inactivo','Activar')
insert into sales.crm_matriz_clientes values (0,1,1,1,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,1,1,1,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,1,1,0,1,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,1,1,0,1,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,1,1,0,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,1,1,0,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,1,0,1,1,1,'Cliente','No Cliente','Consume','Reactivado','Retener')
insert into sales.crm_matriz_clientes values (0,1,0,1,1,0,'Cliente','No Cliente','No Consume','Itinerante','Activar')
insert into sales.crm_matriz_clientes values (0,1,0,1,0,1,'Cliente','No Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,1,0,1,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,1,0,0,1,1,'Cliente','No Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,1,0,0,1,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,1,0,0,0,1,'Cliente','No Cliente','Consume','Reconquista','Retener')
insert into sales.crm_matriz_clientes values (0,1,0,0,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,0,1,1,1,1,'Cliente','Cliente','Consume','Reactivado','Retener')
insert into sales.crm_matriz_clientes values (0,0,1,1,1,0,'Cliente','Cliente','No Consume','Inactivo','Activar')
insert into sales.crm_matriz_clientes values (0,0,1,1,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,0,1,1,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,0,1,0,1,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,0,1,0,1,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,0,1,0,0,1,'Cliente','Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,0,1,0,0,0,'No Cliente','Cliente','No Consume','','Reconquistar')
insert into sales.crm_matriz_clientes values (0,0,0,1,1,1,'Cliente','No Cliente','Consume','Reconquista','Retener')
insert into sales.crm_matriz_clientes values (0,0,0,1,1,0,'Cliente','No Cliente','No Consume','Inactivo','Activar')
insert into sales.crm_matriz_clientes values (0,0,0,1,0,1,'Cliente','No Cliente','Consume','Itinerante','Retener')
insert into sales.crm_matriz_clientes values (0,0,0,1,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,0,0,0,1,1,'Cliente','No Cliente','Consume','Cliente Nuevo','Retener')
insert into sales.crm_matriz_clientes values (0,0,0,0,1,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')
insert into sales.crm_matriz_clientes values (0,0,0,0,0,1,'Cliente','No Cliente','Consume','Cliente Nuevo','Retener')
insert into sales.crm_matriz_clientes values (0,0,0,0,0,0,'No Cliente','No Cliente','No Consume','','Modelo Originacion')


select * from sales.crm_matriz_clientes

select * from sales.crm_dinamica


SELECT
d.codigo_cliente,
d.[2022-08],
d.[2022-09],
d.[2022-10],
d.[2022-11],
d.[2022-12],
d.[2023-01],
m.actual,
m.historia,
m.realidad,
m.tipo_cliente,
m.accion
FROM sales.crm_dinamica d
INNER JOIN sales.crm_matriz_clientes m
ON
m.mes_5 = d.[2022-08]
AND m.mes_4 = d.[2022-09]
AND m.mes_3 = d.[2022-10]
AND m.mes_2 = d.[2022-11]
AND m.mes_1 = d.[2022-12]
AND m.mes_0 = d.[2023-01]
