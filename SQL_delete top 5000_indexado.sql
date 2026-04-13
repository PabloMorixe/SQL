USE nombrebd;
SET QUOTED_IDENTIFIER ON;

DECLARE @selected_Rows INT;
DECLARE @waitfor VARCHAR(8);
DECLARE @minID INT;
DECLARE @dateChosen DATE; -- Fecha elegida para filtrar
DECLARE @batchSize INT = 5000; -- Tamaño del lote

-- Configuración inicial
SET @selected_Rows = 1;
SET @waitfor = '00:00:01'; -- Tiempo de espera entre lotes
SET @dateChosen = 'YYYY-MM-DD'; -- Cambia esto por la fecha deseada

-- Obtener el ID mínimo para la fecha elegida
SELECT @minID = MIN(ID)
FROM [dbo].[lTABLA]
WHERE Fecha = @dateChosen;

-- Verificar si hay registros para eliminar
IF @minID IS NULL
BEGIN
    PRINT 'No hay registros para la fecha elegida.';
    RETURN;
END

-- Bucle para eliminar registros en lotes
WHILE (@selected_Rows > 0)
BEGIN
    BEGIN TRANSACTION;
    DELETE TOP (@batchSize)
    FROM [dbo].[lTABLA]
    WHERE ID >= @minID AND Fecha = @dateChosen;

    -- Actualizar el número de filas afectadas
    SELECT @selected_Rows = @@ROWCOUNT;

    -- Actualizar el ID mínimo para el siguiente lote
    SELECT @minID = MIN(ID)
    FROM [dbo].[lTABLA]
    WHERE ID > @minID AND Fecha = @dateChosen;

    COMMIT TRANSACTION;

    -- Esperar antes de continuar al siguiente lote
    WAITFOR DELAY @waitfor;
END

PRINT 'Eliminación completada.';


----------------------
use nombrebd
                SET QUOTED_IDENTIFIER ON
                DECLARE @selected_Rows INT
                declare @waitfor varchar(5)
                SET @selected_Rows = 1;
                set @waitfor='00:00:01';
                WHILE (@selected_Rows > 0)
                BEGIN
                               BEGIN TRAN       
                                    delete top(5000)
                                       FROM [dbo].[lTABLA] where XXXXXX;


                               select @selected_Rows = @@ROWCOUNT
                               COMMIT TRAN                
                               WAITFOR DELAY @waitfor
                END
----------------------------

select

    'USE Personas

SET QUOTED_IDENTIFIER ON
DECLARE @selected_rows INT
DECLARE @fecha_hasta = DATEADD(year, -1, GETDATE())
SET @selected_rows = 1;
SET @wait_for = ''00:00:01'';
WHILE (@selected_rows > 0)
BEGIN
    BEGIN TRAN
       DELETE TOP(5000)
       FROM [dbo].[' + TABLE_NAME + ']
       WHERE id < (SELECT MIN(id) + 5000 FROM [dbo].[' + TABLE_NAME + '])
       AND fecha_evento < @fecha_hasta;

       SELECT @selected_rows = @@ROWCOUNT
    COMMIT TRAN
    WAITFOR DELAY @wait_for
END
'


    from INFORMATION_SCHEMA.TABLES
where TABLE_NAME like '%_HIST';
 
 
 
 ---------------
 SET QUOTED_IDENTIFIER ON;
 
CREATE PROCEDURE sp_depuracionTablaRegistries
    @daysAgo INT
AS
BEGIN
-- DECLARE    @daysAgo INT
	DECLARE @selected_Rows INT
    DECLARE @waitfor VARCHAR(5)
  	DECLARE @rows INT 
    SET @selected_Rows = 1;
	SET @selected_Rows = 1;
    SET @waitfor = '00:00:01';
	SET @daysAgo = GETDATE() - 36;
    WHILE (@selected_Rows > 0)
    BEGIN
        BEGIN TRAN
            DELETE TOP (5000)
            FROM [DPF].[dbo].[BETransactionLogs_old]
            WHERE requesttimestamp < @daysAgo;
 
            SELECT @selected_Rows = @@ROWCOUNT;
        COMMIT TRAN;
 
        WAITFOR DELAY @waitfor;
    END
END;