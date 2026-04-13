declare @login varchar(30)
declare @base varchar (30)

set @base = 'api_notificaciones'
set @login = ''

--sqlmant.dbo.sp_whoisactive

--select * from sysprocesses   where
--loginame = 'usrApiNoti'
--or dbid = db_id('api_aprobaciones_operaciones')


--Query para obtener la cantidad de Hilos/sesiones activas para un login, usando vista dinamica.
SELECT login_name ,COUNT(session_id) AS session_count   
FROM sys.dm_exec_sessions  
where login_name = @login 
GROUP BY login_name
--
select  * from sys.dm_exec_sessions where nt_user_name  in (@login) order by host_name

select count(*) as cantidad_sesiones
	from sys.dm_exec_sessions  where database_id = DB_ID(@base)

select *--count(*) as cantidad_conexiones 
	from sys.dm_exec_connections  where database_id = DB_ID(@base)

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


SELECT 
    *
FROM 
    sys.configurations

	order by name




