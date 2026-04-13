create database EjemploParticionamiento
go

use EjemploParticionamiento
go


------------------------------------------------------------------------------------------------------
--
--Create a schema for "partition helper" objects
--
------------------------------------------------------------------------------------------------------

CREATE SCHEMA [PartHelper] AUTHORIZATION dbo;
GO

------------------------------------------------------------------------------------------------------
--
-- Create a view to see partition information by filegroup
--
------------------------------------------------------------------------------------------------------

CREATE VIEW [PartHelper].FileGroupDetail
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

------------------------------------------------------------------------------------------------------
--
-- Create a view to see partition information by object
--
------------------------------------------------------------------------------------------------------

CREATE VIEW [PartHelper].ObjectDetail	
AS
SELECT  SCHEMA_NAME(so.schema_id) AS schema_name ,
        OBJECT_NAME(p.object_id) AS object_name ,
        p.partition_number ,
        p.data_compression_desc ,
        dbps.row_count ,
        dbps.reserved_page_count * 8 / 1024. AS reserved_mb ,
        si.index_id ,
        CASE WHEN si.index_id = 0 THEN '(heap!)'
                ELSE si.name
        END AS index_name ,
        si.is_unique ,
        si.data_space_id ,
        mappedto.name AS mapped_to_name ,
        mappedto.type_desc AS mapped_to_type_desc ,
        partitionds.name AS partition_filegroup ,
        pf.name AS pf_name ,
        pf.type_desc AS pf_type_desc ,
        pf.fanout AS pf_fanout ,
        pf.boundary_value_on_right ,
        ps.name AS partition_scheme_name ,
        rv.value AS range_value
FROM    sys.partitions p
JOIN    sys.objects so
        ON p.object_id = so.object_id
            AND so.is_ms_shipped = 0
LEFT JOIN sys.dm_db_partition_stats AS dbps
        ON p.object_id = dbps.object_id
            AND p.partition_id = dbps.partition_id
JOIN    sys.indexes si
        ON p.object_id = si.object_id
            AND p.index_id = si.index_id
LEFT JOIN sys.data_spaces mappedto
        ON si.data_space_id = mappedto.data_space_id
LEFT JOIN sys.destination_data_spaces dds
        ON si.data_space_id = dds.partition_scheme_id
            AND p.partition_number = dds.destination_id
LEFT JOIN sys.data_spaces partitionds
        ON dds.data_space_id = partitionds.data_space_id
LEFT JOIN sys.partition_schemes AS ps
        ON dds.partition_scheme_id = ps.data_space_id
LEFT JOIN sys.partition_functions AS pf
        ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values AS rv
        ON pf.function_id = rv.function_id
            AND dds.destination_id = CASE pf.boundary_value_on_right
                                        WHEN 0 THEN rv.boundary_id
                                        ELSE rv.boundary_id + 1
                                    END
GO



------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--
--   ACA empieza el particionamiento
--
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--
-- objetos para realizar el particionamiento
--
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------



/*
drop proc [marts].Split_Mart_Saldos_Ope_mes
drop PARTITION SCHEME PS_Mart_Saldos_Ope_mes
drop PARTITION FUNCTION PF_Mart_Saldos_Ope_mes
*/

------------------------------------------------------------------------------------------------------
--
-- PARTITION FUNCTION PF_Mart_Saldos_Ope_mes
--
------------------------------------------------------------------------------------------------------

CREATE PARTITION FUNCTION PF_log_bff(datetime)
AS RANGE RIGHT FOR VALUES();
GO
 

------------------------------------------------------------------------------------------------------
--
-- PARTITION SCHEME PS_Mart_Saldos_Ope_mes
--
------------------------------------------------------------------------------------------------------

CREATE PARTITION SCHEME PS_log_bff
AS PARTITION PF_log_bff ALL TO ([primary]);
GO



------------------------------------------------------------------------------------------------------
--
-- PROC Split_log_bff
---
------------------------------------------------------------------------------------------------------

CREATE PROC Split_log_bff
	@SplitValue datetime
AS
BEGIN
	--Usa control de errores del principal
	ALTER PARTITION SCHEME   PS_log_bff   NEXT USED [primary];
	ALTER PARTITION FUNCTION PF_log_bff() SPLIT RANGE(@SplitValue);
END
GO
--pruebas
create table log_bff
(
	fecha datetime,
	id int,
	dato varchar(500)
)

----------------------------------------------------------------------------------------------------------
--
-- Crea particionamiento inicial
--
------------------------------------------------------------------------------------------------------
declare @PartNum int = 0;
DECLARE @StartDate date = '20220601';
Declare @CurrentSplitValue datetime;

While @PartNum <= 90
begin

	set @CurrentSplitValue = dateadd (dd, @PartNum, @StartDate	);
	exec Split_log_bff @CurrentSplitValue
	print @CurrentSplitValue
	set @PartNum += 1;
end
GO

----------------------------------------------------------------------------------------------------------

-- TEST particiones

--Here's how we see the partition function
SELECT name,type_desc, fanout, boundary_value_on_right, create_date 
FROM sys.partition_functions;
GO


------------------------------------------------------------------------------------------------------
--
-- Particiona la tabla !!!
--
------------------------------------------------------------------------------------------------------

--drop table log_bff
--go

create table log_bff
(
	fecha datetime,
	id int,
	dato varchar(500),
	index ccs_log_bff clustered columnstore
)
ON PS_log_bff([fecha]);
GO







--Estimacion para [marts].[Mart_Saldos_Ope_mes]
SELECT 
	$PARTITION.PF_log_bff(fecha) AS PartitionNumber, 
	COUNT(*) AS ProjectedCount
FROM [log_bff]
GROUP BY $PARTITION.PF_log_bff(fecha)
ORDER BY PartitionNumber;





insert into log_bff values('20220103',1,'hola' )
insert into log_bff values('20220603',2,'hola' )
insert into log_bff values('20220602',3,'hola' )
insert into log_bff values('20220603',4,'hola' )
insert into log_bff values('20220603',5,'hola' )

--Look at how this is mapped out now
SELECT *
FROM [PartHelper].FileGroupDetail
where pf_name = 'PF_log_bff';
GO



declare @PartNum int = 1;
DECLARE @StartDate date = '20220830';
Declare @CurrentSplitValue datetime;

While @PartNum <= 5
begin

	set @CurrentSplitValue = dateadd (dd, @PartNum, @StartDate	);
	exec Split_log_bff @CurrentSplitValue
	print @CurrentSplitValue
	set @PartNum += 1;
end
GO





--Estimacion para [marts].[Mart_Saldos_Ope_mes]
SELECT 
	$PARTITION.PF_log_bff(fecha) AS PartitionNumber, 
	COUNT(*) AS ProjectedCount
FROM [log_bff]
GROUP BY $PARTITION.PF_log_bff(fecha)
ORDER BY PartitionNumber;





insert into log_bff values('20220831',6,'hola' )


--Look at how this is mapped out now
SELECT *
FROM [PartHelper].FileGroupDetail
where pf_name = 'PF_log_bff';
GO










------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
SELECT *
FROM [PartHelper].ObjectDetail
WHERE object_name='log_bff'
order by partition_number;




drop table log_bff_switch
go

create table log_bff_switch
(
	fecha datetime,
	id int,
	dato varchar(500),
	index ccs_log_bff clustered columnstore
)
ON [primary];
GO


SELECT *
FROM [PartHelper].FileGroupDetail
where pf_name = 'PF_log_bff';
GO

ALTER TABLE log_bff SWITCH PARTITION 2 TO log_bff_switch



truncate table log_bff_switch

ALTER PARTITION FUNCTION PF_log_bff() MERGE RANGE('20220602')



