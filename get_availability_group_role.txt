--get_availability_group_role
-- Detect if this instance's role is a Primary Replica.
-- If this instance's role is NOT a Primary Replica stop the job so that it does not go on to the next job step
DECLARE @rc int; 
EXEC @rc = master.dbo.is_primary_node_of_SSPR16BPMAG;

IF @rc = 0
BEGIN;
    DECLARE @name sysname;
    SELECT  @name = (SELECT name FROM msdb.dbo.sysjobs WHERE job_id = CONVERT(uniqueidentifier, $(ESCAPE_NONE(JOBID))));
    
    EXEC msdb.dbo.sp_stop_job @job_name = @name;
    PRINT 'Stopped the job since this is not a Primary Replica';
END;