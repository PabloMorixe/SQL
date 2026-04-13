----------------
SELECT  --spid,
        --sp.[status],
       -- loginame [Login],
        --hostname, 
        --blocked BlkBy,
        sd.name DB_Name, 
        cmd Command,
       -- cpu CPUTime,
       -- physical_io DiskIO,
       -- last_batch LastBatch,
       -- [program_name] ProgramName 
       count(*) as cant
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
--WHERE blocked >0
--WHERE db_id(sd.name) >4
GROUP BY cmd,sd.name
order by 2 desc


--------

select 
--CANTIDAD TOTAL: 
(SELECT  
       -- sd.name DB_Name, 
      --  cmd Command,
     
       count(*) as cant
	   
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
)
------------------------

--cantidad de esperas que no son AWAITING COMMAND
(SELECT
count(*) as cant
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
--WHERE blocked >0
WHERE 
db_id(sd.name) >4
and 
sp.cmd not like '%AWAITING COMMAND%'
)

--////////////////////

--cantidad detectada * 100 / el total  
select cast(
(SELECT
count(*) as cant
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
--WHERE blocked >0
WHERE 
--db_id(sd.name) >4 and 
sp.cmd not like '%AWAITING COMMAND%'
) * 100 / 
--total 
(SELECT count(*) as cant FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
)  as decimal (18,2))as '%_NOAwaitingCommand'


