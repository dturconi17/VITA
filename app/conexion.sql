--select * from dw.fact_ventas where fecha_registro > '2026-04-14'

select count(distinct(nro_fac_ndc)) as cnt_facturas, count(*) as transacciones, 
sum(total_bruto) total_bruto, sum(descuento) total_descuento, 
sum(total_neto) total_neto, sum(costo_venta) costo_venta, sum(monto_iva) iva, sum(monto_itr) itr, sum(monto_ieh) ieh 
from dw.fact_ventas where fecha = '2026-04-13'


select *
from dw.fact_ventas where fecha = '2026-04-13' and documento = 1000153