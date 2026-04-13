--como manejar tablas sin pk ascendente --https://techcommunity.microsoft.com/t5/sql-server-support-blog/dealing-with-unique-columns-when-using-table-partitioning/ba-p/333995
----------------------------------------------------------------------------
--Dropeo funcion y schema de particionamiento
----------------------------------------------------------------------------
drop PARTITION SCHEME PS_audit_bff
drop PARTITION FUNCTION PF_audit_bff

----------------------------------------------------------------------------
--crear funcion de particionado por el tipo de dato del campo a particionar
----------------------------------------------------------------------------
CREATE PARTITION FUNCTION PF_audit_bff (bigint) 
AS RANGE RIGHT FOR VALUES 
() 
GO
----------------------------------------------------------------------------
--crear schema de particiones
----------------------------------------------------------------------------
CREATE PARTITION SCHEME PS_audit_bff
AS PARTITION PF_audit_bff
ALL TO ([PRIMARY])
GO 
-----------------------------------------------------------------------------
--creacion de tabla a particionar
----------------------------------------------------------------------------
--drop table [audit_bff]
--TRUNCATE TAble audit_bff
create TABLE [dbo].[audit_bff](
	[id_persona] [varchar](30) NOT NULL,
	[fecha] [datetime] NOT NULL,
	[x_usuario] [varchar](50) NULL,
	[x_canal] [varchar](50) NULL,
	[http_metodo] [varchar](30) NULL,
	[uri] [varchar](255) NULL,
	[id_sesion] [varchar](30) NULL,
	[estado] [varchar](20) NULL,
	[id_dispositivo] [int] NULL,
	[observaciones] [varchar](max) NULL,
	[error_origen] [varchar](100) NULL,
	[error_codigo] [varchar](100) NULL,
	[error_detalle] [varchar](max) NULL,
	[ip_local] [varchar](25) NULL,
	[ip_remota] [varchar](25) NULL,
	[ip] [varchar](25) NULL,
	[x_real_ip] [varchar](25) NULL,
	[x_original_forwarded_for] [varchar](255) NULL,
	[ID] bigint IDENTITY(1,1) NOT NULL,
	[respuesta] [varchar](max) NULL,
	[version_app] [varchar](10) NULL,
	[sistema_operativo] [varchar](50) NULL,
	[duracion] [varchar](10) NULL,
	[duracion_milisegundos] [bigint] NULL,
	index cix_audit_bff clustered columnstore 
) ON PS_audit_bff (id)
GO


--crear PK original. sobre campo ID NONCLUSTERED
 ALTER TABLE [dbo].[audit_bff] ADD PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,  IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, 
OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON PS_audit_bff(id)
GO


ALTER TABLE [dbo].[audit_bff]  WITH CHECK ADD  CONSTRAINT [FK_audit_bff_Dispositivo_tp] FOREIGN KEY([id_dispositivo])
REFERENCES [dbo].[dispositivo] ([id])
GO

ALTER TABLE [dbo].[audit_bff] CHECK CONSTRAINT [FK_audit_bff_Dispositivo_tp]
GO
------------------------------------------------------------------------------------------------------
-- Agregar particion de 5kk de registros.
------------------------------------------------------------------------------------------------------
--drop procedure Split_audit_bff
--parametrizar eL TAMAÑO DE LAS PARTICIONES 
declare @cantregpart int 
set @cantregpart = 1000 
create procedure Split_audit_bff @cantregpart int
	
AS

BEGIN

Declare @CurrentSplitValue bigint; 
	set @CurrentSplitValue = (SELECT cast(coalesce(max(range_value),0) as bigint) FROM FileGroupDetail where pf_name = 'PF_audit_bff' ) + @cantregpart
	ALTER PARTITION SCHEME   PS_audit_bff   NEXT USED [primary];
	ALTER PARTITION FUNCTION PF_audit_bff() SPLIT RANGE(@CurrentSplitValue);
END
GO

----------------------------------------------------------------------------------------------------------
-- Crea particionamiento inicial
--------------------------------------------------------------------------------------------------------
--declare @PartNum int = 0;
--Declare @CurrentSplitValue bigint;

--While @PartNum <= 40
--begin
--	set @CurrentSplitValue = (select max(ID) from audit_bff)
--	exec Split_audit_bff @CurrentSplitValue
--	print @CurrentSplitValue
--	set @PartNum += 1;
--end
--GO
----------------------------------------------------------------------------
----------------------------------------------------------------------------
------------------------------------------------------------
-- 6- --Look at how this is mapped out now
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

select * from sys.partition_range_values
----------------------------------------------------------------------------
----------------------------------------------------------------------------
--Look at how this is mapped out now
SELECT *
FROM FileGroupDetail
where pf_name = 'PF_audit_bff';
GO
----------------------------------------------------------------------------
----------------------------------------------------------------------------
SELECT name,type_desc, fanout, boundary_value_on_right, create_date 
FROM sys.partition_functions;
GO

----------------------------------------------------------------------------
----------------------------------------------------------------------------
--5 crear tabla de switch partition --crear tabla switch con mismo CCI e indices. 

CREATE TABLE [dbo].[audit_bff_switch](
	[id_persona] [varchar](30) NOT NULL,
	[fecha] [datetime] NOT NULL,
	[x_usuario] [varchar](50) NULL,
	[x_canal] [varchar](50) NULL,
	[http_metodo] [varchar](30) NULL,
	[uri] [varchar](255) NULL,
	[id_sesion] [varchar](30) NULL,
	[estado] [varchar](20) NULL,
	[id_dispositivo] [int] NULL,
	[observaciones] [varchar](max) NULL,
	[error_origen] [varchar](100) NULL,
	[error_codigo] [varchar](100) NULL,
	[error_detalle] [varchar](max) NULL,
	[ip_local] [varchar](25) NULL,
	[ip_remota] [varchar](25) NULL,
	[ip] [varchar](25) NULL,
	[x_real_ip] [varchar](25) NULL,
	[x_original_forwarded_for] [varchar](255) NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[respuesta] [varchar](max) NULL,
	[version_app] [varchar](10) NULL,
	[sistema_operativo] [varchar](50) NULL,
	[duracion] [varchar](10) NULL,
	[duracion_milisegundos] [bigint] NULL,
PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)
GO
CREATE CLUSTERED COLUMNSTORE INDEX [cix_audit_bff_switch] ON [dbo].[audit_bff_switch] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
GO
ALTER TABLE [dbo].[audit_bff_switch]  WITH CHECK ADD  CONSTRAINT [FK_audit_bff_switch_Dispositivo_tp] FOREIGN KEY([id_dispositivo])
REFERENCES [dbo].[dispositivo] ([id])
GO
ALTER TABLE [dbo].[audit_bff_switch] CHECK CONSTRAINT [FK_audit_bff_switch_Dispositivo_tp]
GO



-----------------------
--generaqcion de particiones
-----------------------

create procedure generapart @cantPart int
	AS

BEGIN
	--declare @cantPart int = 50
	declare @Maxid bigint
	declare @crearpart int  

    select @Maxid  = max(id) from [audit_bff] 
    SELECT @crearpart =  @cantPart-count(*)
	FROM FileGroupDetail 
	where range_value > @Maxid
	print @crearpart

	while (@crearpart > 0)
		begin
			PRINT @crearpart
			set @crearpart -=1
			exec Split_audit_bff @cantregpart = 1000
		end
end
	 
-----  CREAR sp PART SWITCH CON PARAMETROS DE   --- 
-- agregar date add
Create procedure switchoff 
as
begin 
DECLARE @partNumbmax INT 
declare @Maxid bigint
declare @daystoretain int  = 3 --dias a retener 
select  @Maxid =  max(id) from [audit_bff] where fecha < getdate() - @daystoretain 
--print @maxid
--SELECT * FROM FileGroupDetail
select @partNumbmax = max(partition_number) from FileGroupDetail where range_value < (@Maxid) and pf_name = 'PF_audit_bff'   
--select * from audit_bff
print @partNumbmax

declare @mergeRange bigint 

WHILE ( @partNumbmax > 0)
BEGIN
	--print 'begin'
	--print @partNumbmax
    -- limpio switch table
    truncate table audit_bff_switch
    --switcheo
	ALTER TABLE audit_bff SWITCH PARTITION @partNumbmax TO audit_bff_switch
	--mergeo

	select top 1 @mergeRange = cast(range_value as bigint) FROM FileGroupDetail where pf_name = 'PF_audit_bff' and partition_number = @partNumbmax
	--print @mergeRange
	ALTER PARTITION FUNCTION PF_audit_bff() MERGE RANGE (@mergeRange) 

	SET @partNumbmax=(select max(partition_number) from FileGroupDetail where range_value < @Maxid  and pf_name = 'PF_audit_bff')
END
end
-----




