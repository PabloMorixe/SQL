sp_whoisactive
go
--###################################################################################################################
declare @login varchar(30)
declare @base varchar (30)

set @base = ''
set @login = ''

SELECT login_name ,COUNT(session_id) AS session_count   
FROM sys.dm_exec_sessions  
where login_name = @login
GROUP BY login_name

select  * from sys.dm_exec_sessions where nt_user_name  in (@login) order by host_name

select count(*) as cantidad_sesiones
	from sys.dm_exec_sessions where login_name =@login

	

select count(*) as cantidad_conexiones 
	from sys.dm_exec_connections  --where login_name = @login
	
SELECT 
    s.session_id,
    s.login_name,
    c.client_net_address,
    t.text AS sql_text
FROM 
    sys.dm_exec_sessions AS s
JOIN 
    sys.dm_exec_connections AS c ON s.session_id = c.session_id
CROSS APPLY 
    (SELECT text 
     FROM sys.dm_exec_sql_text(c.most_recent_sql_handle)) AS t
	 where s.login_name = @login


select  * from sys.dm_exec_sessions where nt_user_name not in ('PM43314adm') order by host_name
select  * from sys.dm_exec_connections where session_id > 50 order by client_net_address 

--###################################################################################################################
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
order by cant desc

--###################################################################################################################


USE master;
GO
SELECT creation_time ,cursor_id
,name ,c.session_id ,login_name,*
FROM sys.dm_exec_cursors(0) AS c
JOIN sys.dm_exec_sessions AS s
ON c.session_id = s.session_id
WHERE DATEDIFF(mi, c.creation_time, GETDATE()) > 5;
--###################################################################################################################
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

--###################################################################################################################
SELECT 
    *
FROM 
    sys.configurations

	order by name
	--###################################################################################################################
---------------------------
--Bloqueos por Pablo Morixe
---------------------------

	select 
	sp.blocked as SPIDBloqueador,
	[TExT] as QueryBloqueadora, 
	sp.spid as SPIDBloqueado, 
	sp.waittime , 
	lastwaittype, 
	db_name(sp.dbid) as BaseDeDatos,
	sp.status,
	sp.stmt_start,
	sp.hostname,
	sp.cmd,
	sp.nt_username,
	sp.loginame,
	    DATEDIFF(MINUTE, r.start_time, GETDATE()) AS 'TiempoTranscurrido'

	from sysprocesses as sp
cross apply  sys.dm_exec_sql_text (sp.sql_handle) 
JOIN
    sys.dm_exec_requests AS r ON sp.spid = r.session_id
where blocked > 0