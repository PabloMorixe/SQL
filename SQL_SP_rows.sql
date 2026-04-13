USE [sqlmant]
GO

/****** Object:  StoredProcedure [dbo].[sp_rows]    Script Date: 13/4/2026 17:05:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- 2. Ahora aplicamos el ALTER con toda tu lógica
CREATE PROCEDURE [dbo].[sp_rows]  
	@DBName SYSNAME = NULL, -- Si es NULL, usa la DB actual

    @Top INT = NULL        -- Opcional: limitar resultados


AS

BEGIN

    SET NOCOUNT ON;

 

    -- Si no se pasa DBName, tomamos la base de datos actual

    IF @DBName IS NULL SET @DBName = DB_NAME();

 

    -- Validar que la base de datos existe para evitar inyección SQL

    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DBName)

    BEGIN

        RAISERROR('La base de datos [%s] no existe o no es accesible.', 16, 1, @DBName);

        RETURN;

    END

 

    DECLARE @SQL NVARCHAR(MAX);

 

    -- Construimos el query dinámico apuntando a la DB seleccionada

    SET @SQL = N'

    SELECT TOP (ISNULL(@InnerTop, 1000000))

        TableName,

        [RowCount],

        [Size_MB],

        [Unused_MB],

        [Total_MB]

    FROM (

        SELECT

            TableName   = s.name + ''.'' + t.name

            ,[RowCount] = SUM(p.rows)

            ,Size_MB    = CAST((SUM(a.data_pages) * 8) / 1024.0 AS DECIMAL(18,2))

            ,Unused_MB  = CAST(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.0 AS DECIMAL(18,2))

            ,Total_MB   = CAST((SUM(a.total_pages) * 8) / 1024.0 AS DECIMAL(18,2))

        FROM ' + QUOTENAME(@DBName) + '.sys.tables t

        INNER JOIN ' + QUOTENAME(@DBName) + '.sys.schemas s ON t.schema_id = s.schema_id

        INNER JOIN ' + QUOTENAME(@DBName) + '.sys.indexes i ON t.object_id = i.object_id

        INNER JOIN ' + QUOTENAME(@DBName) + '.sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id

        INNER JOIN ' + QUOTENAME(@DBName) + '.sys.allocation_units a ON p.partition_id = a.container_id

        WHERE t.is_ms_shipped = 0

          AND i.index_id IN (0, 1)

        GROUP BY s.name, t.name

    ) AS t

    ORDER BY Total_MB DESC;';

 

    -- Ejecutamos pasando el parámetro @Top internamente

    EXEC sp_executesql @SQL, N'@InnerTop INT', @InnerTop = @Top;

END
GO


