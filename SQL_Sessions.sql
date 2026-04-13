select  * from sys.dm_exec_sessions where nt_user_name not in ('PM43314adm') order by host_name
select  * from sys.dm_exec_connections where session_id > 50 order by client_net_address 


select count(*) from sys.dm_exec_sessions -- sesiones
select count(*) from sys.dm_exec_connections -- conexiones

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
WHERE db_id(sd.name) >4
GROUP BY cmd,sd.name
order by 2 desc




USE master;
GO
SELECT creation_time ,cursor_id
,name ,c.session_id ,login_name,*
FROM sys.dm_exec_cursors(0) AS c
JOIN sys.dm_exec_sessions AS s
ON c.session_id = s.session_id
WHERE DATEDIFF(mi, c.creation_time, GETDATE()) > 5;

--[13:03] Jose Alvarez (Guest)
SELECT s.*
FROM sys.dm_exec_sessions AS s
WHERE EXISTS
(
SELECT *
FROM sys.dm_tran_session_transactions AS t
WHERE t.session_id = s.session_id
)
AND NOT EXISTS
(
SELECT *
FROM sys.dm_exec_requests AS r
WHERE r.session_id = s.session_id
);