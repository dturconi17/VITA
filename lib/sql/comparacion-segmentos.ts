export function queryComparacionSegmentos(
  desde: string,
  hasta: string
) {

  const regex = /^\d{4}-\d{2}$/;

  if (!regex.test(desde) || !regex.test(hasta)) {
    throw new Error("Período inválido");
  }


  return `

SELECT
    'Desde' AS periodo,
    [${desde}_tipo_cliente] AS tipo_cliente,
    COUNT(*) AS cantidad
FROM sales.crm_dinamica_segmentada
where len([${desde}_tipo_cliente]) > 0
GROUP BY
    [${desde}_tipo_cliente]

UNION ALL

SELECT
    'Hasta' AS periodo,
    [${hasta}_tipo_cliente] AS tipo_cliente,
    COUNT(*) AS cantidad
FROM sales.crm_dinamica_segmentada
where len([${hasta}_tipo_cliente]) > 0

GROUP BY
    [${hasta}_tipo_cliente]
ORDER BY

    periodo,

    cantidad DESC;

`;

}