CREATE OR ALTER PROCEDURE sales.sp_reporte_retencion_clientes
(
    @Desde VARCHAR(7),
    @Hasta  VARCHAR(7)
)
AS
BEGIN

    SET NOCOUNT ON;

    -------------------------------------------------------------------
    -- Validaciones
    -------------------------------------------------------------------

    IF COL_LENGTH('sales.crm_dinamica', @Desde) IS NULL
    BEGIN
        RAISERROR('El período Desde no existe en sales.crm_dinamica.',16,1);
        RETURN;
    END

    IF COL_LENGTH('sales.crm_dinamica', @Hasta) IS NULL
    BEGIN
        RAISERROR('El período Hasta no existe en sales.crm_dinamica.',16,1);
        RETURN;
    END

    -------------------------------------------------------------------
    -- SQL dinámico
    -------------------------------------------------------------------

    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    SELECT

        codigo_cliente,
        nombre_cliente,

        ' + QUOTENAME(@Desde) + ' AS estado_desde,

        ' + QUOTENAME(@Hasta) + ' AS estado_hasta,

        CASE

            WHEN ' + QUOTENAME(@Desde) + ' = 1
             AND ' + QUOTENAME(@Hasta) + ' = 1
                THEN ''Activo''

            WHEN ' + QUOTENAME(@Desde) + ' = 1
             AND ' + QUOTENAME(@Hasta) + ' = 0
                THEN ''Perdido''

            WHEN ' + QUOTENAME(@Desde) + ' = 0
             AND ' + QUOTENAME(@Hasta) + ' = 1
                THEN ''Recuperado''

            ELSE ''Inactivo''

        END AS estado

    FROM sales.crm_dinamica

    ORDER BY nombre_cliente;
    ';

    EXEC sp_executesql @SQL;

END
GO

EXEC sales.sp_reporte_retencion_clientes
    @Desde='2024-01',
    @Hasta='2025-06';

    SELECT *
FROM sys.procedures
WHERE name = 'sp_reporte_retencion_clientes';

SELECT SUSER_NAME() AS UsuarioSQL;

SELECT USER_NAME() AS UsuarioBD;

GRANT EXECUTE ON OBJECT::sales.sp_reporte_retencion_clientes TO [crm_consultor];

EXEC sales.sp_reporte_retencion_clientes
    @Desde = '2024-01',
    @Hasta = '2025-06';


EXECUTE AS USER = USER_NAME();

EXEC sales.sp_reporte_retencion_clientes
    @Desde = '2024-01',
    @Hasta = '2025-06';

REVERT;

SELECT
    name,
    SCHEMA_NAME(schema_id) AS esquema,
    USER_NAME(principal_id) AS propietario
FROM sys.procedures
WHERE name = 'sp_reporte_retencion_clientes';

EXEC sales.sp_reporte_retencion_clientes '2024-01','2025-06';