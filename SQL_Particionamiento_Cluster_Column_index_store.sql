--como manejar tablas sin pk ascendente --https://techcommunity.microsoft.com/t5/sql-server-support-blog/dealing-with-unique-columns-when-using-table-partitioning/ba-p/333995
----------------------------------------------------------------------------
--Dropeo funcion y schema de particionamiento
----------------------------------------------------------------------------
/*
USE [master]
GO

GO
ALTER DATABASE [bff-mobile-individuos] ADD FILEGROUP [AuditFilegroup]
GO

ALTER DATABASE [bff-mobile-individuos] 
ADD FILE ( NAME = N'bff-mobile-individuos5', 
FILENAME = N'I:\MSSQL2K19\MSSQL15.MSSQLSERVER\MSSQL\Data\bff-mobile-individuos5.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) 
TO FILEGROUP [AuditFilegroup]
GO

ALTER DATABASE [bff-mobile-individuos] 
ADD FILE ( NAME = N'bff-mobile-individuos6', 
FILENAME = N'I:\MSSQL2K19\MSSQL15.MSSQLSERVER\MSSQL\Data\bff-mobile-individuos6.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
TO FILEGROUP [AuditFilegroup]
GO

*/
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------


--
-- SSLABVEEAM-51
-- use [AR_Supervielle_Individuos_ICHB]
-- 


-- drop PARTITION SCHEME PS_BETransactionLogs
-- drop PARTITION FUNCTION PF_BETransactionLogs

----------------------------------------------------------------------------
-- 1- Crear funcion de particionado por el tipo de dato del campo a particionar
----------------------------------------------------------------------------
CREATE PARTITION FUNCTION PF_BETransactionLogs (bigint) 
AS RANGE RIGHT FOR VALUES 
() 
GO
----------------------------------------------------------------------------
-- 2- Crear schema de particiones
----------------------------------------------------------------------------
CREATE PARTITION SCHEME PS_BETransactionLogs
AS PARTITION PF_BETransactionLogs
--ALL TO ([AuditFilegroup]) --PRIMARY
ALL TO ([PRIMARY])
GO 

-----------------------------------------------------------------------------
-- 3- Creacion de tabla a particionar -- T1, original.
----------------------------------------------------------------------------

CREATE TABLE [dbo].[BETransactionLogs](
	[BETransactionLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[ResponseDate] [datetime] NULL,
	[UserId] [int] NOT NULL,
	[BETransactionStatusId] [int] NOT NULL,
	[MessegeRequest] [xml] NOT NULL,
	[MessageResponse] [xml] NULL,
	[BETransactionId] [int] NOT NULL,
 CONSTRAINT [PK_BETransactionLogs] PRIMARY KEY  NONCLUSTERED 
(
	[BETransactionLogId] ASC
)
) ON [PS_BETransactionLogs] (BETransactionLogId)
GO


---use [AR_Supervielle_Individuos_ICHB]
/*
CREATE NONCLUSTERED INDEX IXFK_BETransactionLogs_BETransactions
ON dbo.BETransactionLogs (BETransactionLogId)
WITH (DROP_EXISTING = ON)
ON [PS_BETransactionLogs] (BETransactionLogId);
*/


CREATE NONCLUSTERED INDEX [IXFK_BETransactionLogs_BETransactions] ON [dbo].[BETransactionLogs]
(
	[BETransactionId] ASC
)ON [PS_BETransactionLogs] (BETransactionLogId)
GO


/*

CREATE NONCLUSTERED INDEX [IXFK_BETransactionLogs_BETransactionsStatus] ON [dbo].[BETransactionLogs]
(
	[BETransactionStatusId] ASC
)ON [PS_BETransactionLogs] (BETransactionLogId)
GO

CREATE NONCLUSTERED INDEX [IXFK_BETransactionLogs_Users] ON [dbo].[BETransactionLogs]
(
	[UserId] ASC
)ON [PS_BETransactionLogs] (BETransactionLogId)
GO

CREATE NONCLUSTERED INDEX [IXQ_BETransactionLogs_RequestDate] ON [dbo].[BETransactionLogs]
(
	[RequestDate] ASC
)
INCLUDE([BETransactionId]) 
ON [PS_BETransactionLogs] (BETransactionLogId)
GO

ALTER TABLE [dbo].[BETransactionLogs]  WITH CHECK ADD  CONSTRAINT [FK_BETransactionLogs_BETransactions] FOREIGN KEY([BETransactionId])
REFERENCES [dbo].[BETransactions] ([BETransactionId])
GO

ALTER TABLE [dbo].[BETransactionLogs] CHECK CONSTRAINT [FK_BETransactionLogs_BETransactions]
GO

ALTER TABLE [dbo].[BETransactionLogs]  WITH CHECK ADD  CONSTRAINT [FK_BETransactionLogs_BETransactionsStatus] FOREIGN KEY([BETransactionStatusId])
REFERENCES [dbo].[BETransactionsStatus] ([BETransactionsStatusId])
GO

ALTER TABLE [dbo].[BETransactionLogs] CHECK CONSTRAINT [FK_BETransactionLogs_BETransactionsStatus]
GO

ALTER TABLE [dbo].[BETransactionLogs]  WITH CHECK ADD  CONSTRAINT [FK_BETransactionLogs_Users] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO

ALTER TABLE [dbo].[BETransactionLogs] CHECK CONSTRAINT [FK_BETransactionLogs_Users]
GO

*/





----------------------------------------------------------------------------------------------------------
-- Crea particionamiento inicial
--------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------
----------------------------------------------------------------------------
------------------------------------------------------------
-- 4- --Look at how this is mapped out now
------------------------------------------------------------
 --  VISTA -- select * from FileGroupDetail
   
CREATE VIEW FileGroupDetail
AS
SELECT  pf.name AS pf_name ,
        ps.name AS partition_scheme_name ,
        p.partition_number ,
        ds.name AS partition_filegroup ,	
        pf.type_desc AS pf_type_desc ,
        pf.fanout AS pf_fanout ,
        pf.boundary_value_on_right ,
        OBJECT_NAME(si.object_id) AS object_name ,
        rv.value AS range_value ,
        SUM(CASE WHEN si.index_id IN ( 1, 0 ) THEN p.rows
                    ELSE 0
            END) AS num_rows ,
        SUM(dbps.reserved_page_count) * 8 / 1024. AS reserved_mb_all_indexes ,
        SUM(CASE ISNULL(si.index_id, 0)
                WHEN 0 THEN 0
                ELSE 1
            END) AS num_indexes
FROM    sys.destination_data_spaces AS dds
        JOIN sys.data_spaces AS ds ON dds.data_space_id = ds.data_space_id
        JOIN sys.partition_schemes AS ps ON dds.partition_scheme_id = ps.data_space_id
        JOIN sys.partition_functions AS pf ON ps.function_id = pf.function_id
        LEFT JOIN sys.partition_range_values AS rv ON pf.function_id = rv.function_id
                                                        AND dds.destination_id = CASE pf.boundary_value_on_right
                                                                                    WHEN 0 THEN rv.boundary_id
                                                                                    ELSE rv.boundary_id + 1
                                                                                END
        LEFT JOIN sys.indexes AS si ON dds.partition_scheme_id = si.data_space_id
        LEFT JOIN sys.partitions AS p ON si.object_id = p.object_id
                                            AND si.index_id = p.index_id
                                            AND dds.destination_id = p.partition_number
        LEFT JOIN sys.dm_db_partition_stats AS dbps ON p.object_id = dbps.object_id
                                                        AND p.partition_id = dbps.partition_id
GROUP BY ds.name ,
        p.partition_number ,
        pf.name ,
        pf.type_desc ,
        pf.fanout ,
        pf.boundary_value_on_right ,
        ps.name ,
        si.object_id ,
        rv.value;
GO

-- select * from sys.partition_range_values


------------------------------------------------------------------------------------------------------
-- 5- Agregar particion de 5kk de registros.
------------------------------------------------------------------------------------------------------
--drop procedure Split_BETransactionLogs
--parametrizar eL TAMAÑO DE LAS PARTICIONES 
--declare @cantregpart int 
--set @cantregpart = 100 

CREATE procedure Split_BETransactionLogs @cantregpart int
AS

BEGIN
	Declare @CurrentSplitValue bigint; 
	set @CurrentSplitValue = (SELECT cast(coalesce(max(range_value),0) as bigint) FROM FileGroupDetail where pf_name = 'PF_BETransactionLogs' ) + @cantregpart
	ALTER PARTITION SCHEME   PS_BETransactionLogs   NEXT USED [primary];
	ALTER PARTITION FUNCTION PF_BETransactionLogs() SPLIT RANGE(@CurrentSplitValue);
END
GO

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--Look at how this is mapped out now
SELECT *
FROM FileGroupDetail
where pf_name = 'PF_BETransactionLogs';
GO
----------------------------------------------------------------------------
----------------------------------------------------------------------------
SELECT name,type_desc, fanout, boundary_value_on_right, create_date 
FROM sys.partition_functions;
GO

----------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
-- 6- Crear tabla de switch partition            ---- T2, tabla intermedia de switch. Identica a la original T1, pero con CCI
--    Crear tabla switch con mismo CCI e indices. 
-------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE [dbo].[BETransactionLogs_switch](
	[BETransactionLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[ResponseDate] [datetime] NULL,
	[UserId] [int] NOT NULL,
	[BETransactionStatusId] [int] NOT NULL,
	[MessegeRequest] [xml] NOT NULL,
	[MessageResponse] [xml] NULL,
	[BETransactionId] [int] NOT NULL,
 CONSTRAINT [PK_BETransactionLogs_switch] PRIMARY KEY NONCLUSTERED 
(
	[BETransactionLogId] ASC
)
) ON [PRIMARY] 
GO



-----------------------
-- 7- JOB generacion de particiones diariamente abajo esta el SP:_ execute [dbo].[generapart] 50, 500
-----------------------
--select * from FileGroupDetail
--exec generapart 50
--go
	
-----------------------------------------------------------------------------------------------------
	 
--	 execute [dbo].[generapart] 10, 50
	 
   Create procedure generapart @cantPart int ,@cantregpart int   
   AS  
  
   BEGIN  
  
    declare @Maxid bigint  
    declare @crearpart int    
  
    select @Maxid  = max(BETransactionLogId) from [BETransactionLogs]   
    SELECT @crearpart =  @cantPart-count(*)  
    FROM FileGroupDetail   
    where range_value > @Maxid  
    print @crearpart  
  
    while (@crearpart > 0)  
     begin  
      PRINT @crearpart  
      set @crearpart -=1  
      exec Split_BETransactionLogs @cantregpart                               
     end  
   end
	 
	 
-----  JOB de switcheo--- 

-- execute [dbo].[switchoff] 35

Create procedure [dbo].[switchoff] @daystoretain int
			as
			begin 
			DECLARE @partNumbmax INT 
			declare @Maxid bigint
			select  @Maxid =  max(BETransactionLogId) from [BETransactionLogs] where RequestDate < getdate() - @daystoretain 
					print @maxid
					--SELECT * FROM FileGroupDetail
			select @partNumbmax = max(partition_number) from FileGroupDetail where range_value < (@Maxid) and pf_name = 'PF_BETransactionLogs'   
			--select * from audit_bff
			print @partNumbmax
			SELECT * FROM FileGroupDetail

			declare @mergeRange bigint 

			WHILE ( @partNumbmax > 0)
			BEGIN
				--print 'begin'
				--print @partNumbmax
				-- limpio switch table
				truncate table BETransactionLogs_switch
				--switcheo
				ALTER TABLE BETransactionLogs SWITCH PARTITION @partNumbmax TO BETransactionLogs_switch
				--mergeo

				select top 1 @mergeRange = cast(range_value as bigint) FROM FileGroupDetail where pf_name = 'PF_BETransactionLogs' and partition_number = @partNumbmax
				--print @mergeRange
				ALTER PARTITION FUNCTION PF_BETransactionLogs() MERGE RANGE (@mergeRange) 

				SET @partNumbmax=(select max(partition_number) from FileGroupDetail where range_value < @Maxid  and pf_name = 'PF_BETransactionLogs')
	    

			END
			end
GO



-------------------------------------------------------------------------------------
-- 8- Creacion de tabla Final con campo varchar, particionada y CCI.  -- T3 Final
-------------------------------------------------------------------------------------
--drop table [BETransactionLogs_CCI]
--TRUNCATE TAble BETransactionLogs_CCI
CREATE TABLE [dbo].[BETransactionLogs_CCI](
	[BETransactionLogId] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestDate] [datetime] NOT NULL,
	[ResponseDate] [datetime] NULL,
	[UserId] [int] NOT NULL,
	[BETransactionStatusId] [int] NOT NULL,
	[MessegeRequest]  varchar(max) NOT NULL,
	[MessageResponse]  varchar(max) NULL,
	[BETransactionId] [int] NOT NULL,
 CONSTRAINT [PK_BETransactionLogs_CCI] PRIMARY KEY  NONCLUSTERED 
(
	[BETransactionLogId] ASC
)
) ON [PS_BETransactionLogs] (BETransactionLogId)
GO



CREATE CLUSTERED COLUMNSTORE INDEX [cix_BETransactionLogs_CCI] ON [dbo].[BETransactionLogs_CCI] 
WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PS_BETransactionLogs](BETransactionLogId)
GO



-----------------------
--- Consultas
-----------------------

select * from FileGroupDetail
where object_name = 'BETransactionLogs'


select * from [dbo].[BETransactionLogs_switch]


select * from  [dbo].[BETransactionLogs_CCI]


-- execute CopySwitchToCCI

-- truncate table BETransactionLogs_CCI


-----------------------
--- JOBS de ejecucion de solucion. 
-----------------------
USE [msdb]
GO

/****** Object:  Job [HBI_particiones]    Script Date: 1/6/2023 15:12:17 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/6/2023 15:12:17 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'HBI_particiones', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'GSCORP\PM43314adm', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [genera part]    Script Date: 1/6/2023 15:12:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'genera part', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute [dbo].[generapart] 20, 50', 
		@database_name=N'AR_Supervielle_Individuos_ICHB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [switch OFF]    Script Date: 1/6/2023 15:12:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'switch OFF', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute [dbo].[switchoff] 2

', 
		@database_name=N'AR_Supervielle_Individuos_ICHB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CopySwitchToCCI]    Script Date: 1/6/2023 15:12:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CopySwitchToCCI', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute CopySwitchToCCI', 
		@database_name=N'AR_Supervielle_Individuos_ICHB', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Diario', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230530, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, 
		@schedule_uid=N'd9bad80f-b075-496d-93a0-22b99cba5459'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


