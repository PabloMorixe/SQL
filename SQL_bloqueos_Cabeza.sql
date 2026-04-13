--------------------
--Cabeza bloqueos
--------------------
SELECT db_name(er.database_id),
er.session_id,
es.original_login_name,
es.client_interface_name,
er.start_time,
er.status,
er.wait_type,
er.wait_resource,
SUBSTRING(st.text, (er.statement_start_offset/2)+1,
((CASE er.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE er.statement_end_offset
END - er.statement_start_offset)/2) + 1) AS statement_text,
er.*
FROM SYS.dm_exec_requests er
join sys.dm_exec_sessions es on (er.session_id = es.session_id)
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
where er.session_id in
(SELECT distinct(blocking_session_id) FROM SYS.dm_exec_requests WHERE blocking_session_id > 0)
and blocking_session_id = 0

--------------------
--lista bloqueos
--------------------

SELECT db_name(er.database_id),
er.session_id,
es.original_login_name,
es.client_interface_name,
er.start_time,
er.status,
er.wait_type,
er.wait_resource,
SUBSTRING(st.text, (er.statement_start_offset/2)+1,
((CASE er.statement_end_offset
WHEN -1 THEN DATALENGTH(st.text)
ELSE er.statement_end_offset
END - er.statement_start_offset)/2) + 1) AS statement_text,
er.*
FROM SYS.dm_exec_requests er
join sys.dm_exec_sessions es on (er.session_id = es.session_id)
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS st
where er.session_id in
(SELECT distinct(blocking_session_id) FROM SYS.dm_exec_requests WHERE blocking_session_id > 0)
and blocking_session_id = 0

--------------------
--BLoqueo query
--------------------
select [TExT],* from sysprocesses as sp
cross apply  sys.dm_exec_sql_text (sp.sql_handle) 
where spid = 71 or spid = 75


--------------------
--BLoqueos afectados
--------------------


SELECT 
     SessionID = s.Session_id,
     resource_type,   
     DatabaseName = DB_NAME(resource_database_id),
     request_mode,
     request_type,
     login_time,
     host_name,
     program_name,
     client_interface_name,
     login_name,
     nt_domain,
     nt_user_name,
     s.status,
     last_request_start_time,
     last_request_end_time,
     s.logical_reads,
     s.reads,
     request_status,
     request_owner_type,
     objectid,
     dbid,
     a.number,
     a.encrypted ,
     a.blocking_session_id,
     a.text       
FROM   
     sys.dm_tran_locks l
     JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id
     LEFT JOIN   
     (
         SELECT  *
         FROM    sys.dm_exec_requests r
         CROSS APPLY sys.dm_exec_sql_text(sql_handle)
     ) a ON s.session_id = a.session_id
WHERE  
     s.session_id > 50
     AND resource_database_id = DB_ID('TablerosCC') --> Modificar/comentar segun corresponda
	 
	 
	 
	 
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
	    DATEDIFF(MINUTE, r.start_time, GETDATE()) AS 'TiempoTranscurridoenMins'

	from sysprocesses as sp
cross apply  sys.dm_exec_sql_text (sp.sql_handle) 
JOIN
    sys.dm_exec_requests AS r ON sp.spid = r.session_id
where blocked > 0