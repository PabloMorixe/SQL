DBCC OPENTRAN ( managfile )    WITH TABLERESULTS ,  NO_INFOMSGS

SELECT * FROM sys.sysprocesses WHERE  open_tran = 1

--
--xp_readerrorlog
--sp_readerrorlog
select * from sysprocesses where dbid > 4
SELECT name, snapshot_isolation_state, is_read_committed_snapshot_on
FROM sys.databases


DBCC useroptions

SELECT DISTINCT 'KILL ''' + CONVERT(VARCHAR(50),request_owner_guid) + ''';'
FROM   sys.dm_tran_locks
WHERE  request_session_id = -3
AND    resource_database_id = DB_ID('DB_name del bloqueo')



