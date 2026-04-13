GET_availability node, 

La primera parte, genera la funcion en la master. 
la segunda parte , es el step que valida la corrida. 

----------------------------------
--FUNCION
----------------------------------
e
declare @nombreInstancia varchar(50)
set @nombreInstancia = (SELECT top 1 name FROM sys.availability_groups)
 
 declare @funcionName varchar(100)
	set @funcionName = 'is_primary_node_of_'+@nombreInstancia



IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''+@funcionName+'') 
AND type IN ('U', 'FN', 'IF', 'TF', 'P'))
begin
	set @funcionName = 'drop function is_primary_node_of_'+@nombreInstancia

	execute ( @funcionName) 
end

declare @funcion nvarchar(max)
set @funcion = '
CREATE FUNCTION [dbo].[is_primary_node_of_'+@nombreInstancia+']()  
RETURNS bit  
AS  
BEGIN;  
  DECLARE @PrimaryReplica sysname;   
  
  SELECT  
                @PrimaryReplica = hags.primary_replica  
  FROM          sys.dm_hadr_availability_group_states hags  
  INNER JOIN    sys.availability_groups ag   
                ON ag.group_id = hags.group_id  
  WHERE   
            ag.name = ''+@nombreInstancia+'';  
  
  IF UPPER(@PrimaryReplica) =  UPPER(@@SERVERNAME)  
    RETURN 1; -- primary  
  
    RETURN 0; -- not primary  
END;   
  
   



'

texecute (@funcion)
----------------------------------
--STEP
----------------------------------
----get_availability_group_role
-- Detect if this instance's role is a Primary Replica.
--- If this instance's role is NOT a Primary Replica stop the job so that it does not go on to the next job step


declare @nombreInstancia varchar(50)
set @nombreInstancia = (SELECT name FROM sys.availability_groups)
 
 declare @funcionName varchar(100)
	set @funcionName = 'master.dbo.is_primary_node_of_'+@nombreInstancia

	



DECLARE @rc int; 
EXEC @rc = @funcionName;

IF @rc = 0
BEGIN;
    DECLARE @name sysname;
    SELECT  @name = (SELECT name FROM msdb.dbo.sysjobs WHERE job_id = CONVERT(uniqueidentifier, $(ESCAPE_NONE(JOBID))));
    
    EXEC msdb.dbo.sp_stop_job @job_name = @name;
    PRINT 'Stopped the job since this is not a Primary Replica';
END;