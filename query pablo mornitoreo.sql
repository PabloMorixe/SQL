/* CANTIDAD DE SESIONES CONECTADAS, CON SU ESTADO, SERVIDOR Y LOGIN */
SELECT  
         rtrim(sd.name) AS DB_Name, 
		 rtrim (hostname) [Hostname],
		 rtrim (loginame) [Login],
		 rtrim(cmd) AS [Command],       
	     count(*) as [cant]
FROM master.dbo.sysprocesses sp 
JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
WHERE db_id(sd.name) >4
GROUP BY cmd,sd.name,hostname,loginame
order by 2 desc
/*-------------------------------------------------------------------------------------*/

/*VER EL ORIGEN DE LOS BLOQUEOS*/
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

/*-------------------------------------------------------------------------------------*/


/*VER TODAS LAS SESIONES BLOQUEADAS POR LA SESION DE LA QUERY ANTERIOR*/
	SELECT  spid,
			sp.[status],
			loginame [Login],
			hostname, 
			blocked BlkBy,
			sd.name DBName, 
			cmd Command,
			cpu CPUTime,
			physical_io DiskIO,
			last_batch LastBatch,
			[program_name] ProgramName,
			(select text from sys.dm_exec_sql_text(sp.sql_handle)) as command, 
			r.wait_time, r.wait_type,r.last_wait_type,r.total_elapsed_time--,r.dop  
	FROM master.dbo.sysprocesses sp 
	JOIN master.dbo.sysdatabases sd ON sp.dbid = sd.dbid
	left join sys.dm_exec_requests AS r
	on r.session_id =spid
	WHERE blocked >0
	order by cpu desc

/*-------------------------------------------------------------------------------------*/

/*PROCEDIMIENTO PARA OBTENER ESPACIO DE DISCO (SO) Y ESPACIO DE DATAFILE (QUE TENGA EL AUTOGROWTH HABILITADO */
CREATE TABLE #FileSize
(dbName NVARCHAR(128),       
    DBFreeSpaceMB DECIMAL(10,2),
	unidad NVARCHAR(10),
	nameFileGroups NVARCHAR(128)
);
/* OBTENGO TODOS LOS DATAFILES POR CADA BBDD Y QUE TENGA AUTOGROWTH (growth !=0) HABILITADO */    
INSERT INTO #FileSize(dbName, DBFreeSpaceMB,unidad,nameFileGroups)
exec sp_msforeachdb 
'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'')
begin
 use [?]
 SELECT  a.NAME AS [dbName],
		 CONVERT(DECIMAL (12, 2), Round ((a. SIZE - Fileproperty (a. NAME, ''SpaceUsed'')) / 128.000, 2)) AS [DBFreeSpaceMB],       
		SUBSTRING(a.filename,0,4) AS [unidad], b.name
FROM sys.sysfiles a
LEFT OUTER JOIN sys. filegroups b ON a.groupid = b. data_space_id
where CONVERT(DECIMAL (12, 2), Round ((a. SIZE - Fileproperty (a. NAME, ''SpaceUsed'')) / 128.000, 2)) < 30 and growth !=0;
end';

/* CRUZO EL RESULTADO ANTERIOR CON EL ESPACIO DE FILESYSTEM DEL SERVIDOR, CON LA CONDICION Servfree_size_GB < 40 (ESTE CAMPO DEBERIA SER VARIABLE EN DYNATRACE) */
SELECT rtrim(fs.dbname) as DataFile
	   ,fs.DBFreeSpaceMB
       ,ss.Servfree_size_GB as SpaceDiskGB
	   ,ss.disk_mount_point as FileSystem
	   ,case  
		when fs.nameFileGroups IS NULL THEN 'LOG'
		ELSE fs.nameFileGroups
	   END AS FileGroupName
FROM #FileSize fs , (
Select Distinct
volume_mount_point [disk_mount_point],
logical_volume_name as [logical drive name],
convert (decimal(18,2),total_bytes/1073741824.0) as [total size in GB],
cast(cast(available_bytes as float)/ cast(total_bytes as float)as decimal(18,2)) *100 as [space free %]
,convert (decimal(18,2),available_bytes/1073741824.0) as [Servfree_size_GB]
from sys.master_files
cross apply sys.dm_os_volume_stats(database_id,file_id)
) as ss
where ss.disk_mount_point = fs.unidad and ss.Servfree_size_GB < 40
order by 1 asc;

DROP TABLE #FileSize;

/*-------------------------------------------------------------------------------------*/
/* QUERYS PARA CHEQUEAR EL ESTADO DEL AON */
/* 1- != HEALTHY */ 
/* EJEMPLO DE SALIDA: SSTS19HBE-01	HEALTHY
                       SSTS19HBE-51	HEALTHY */
 select  ar.replica_server_name,gs.synchronization_health_desc
 from sys.availability_replicas ar
 inner join sys.availability_group_listeners gl
 on ar.group_id = gl.group_id
 inner join  sys.dm_hadr_availability_group_states gs
 on gl.group_id = gs.group_id
 inner join sys.availability_replicas avr
 on gs.group_id = avr.group_id
 inner join sys.dm_hadr_availability_replica_states ars
 on ars.replica_id = ar.replica_id
 WHERE gs.synchronization_health_desc != 'HEALTHY'
  group by ar.replica_server_name, gl.dns_name,gs.primary_recovery_health_desc,
  gs.synchronization_health_desc, avr.availability_mode_desc,ars.role_desc,
  avr.failover_mode_desc
  order by ar.replica_server_name 

/* 2- != SYNCHRONIZED */ 
/* EJEMPLO DE SALIDA: 
SSTS19HBE-01	AR_Supervielle_eFactoring	            SSTS19HBEAG	SYNCHRONIZED	HEALTHY
SSTS19HBE-01	AR_Supervielle_ICBanking	            SSTS19HBEAG	SYNCHRONIZED	HEALTHY
SSTS19HBE-01	AR_Supervielle_ICBanking_aspnetdb	    SSTS19HBEAG	SYNCHRONIZED	HEALTHY
SSTS19HBE-01	AR_Supervielle_ICBanking_eFactoring01	SSTS19HBEAG	SYNCHRONIZED	HEALTHY
*/
SELECT 
	 ar.replica_server_name
	,adc.database_name
	,ag.name AS ag_name
	,drs.synchronization_state_desc	
	,drs.synchronization_health_desc	
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc ON drs.group_id = adc.group_id AND drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag  ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar ON drs.group_id = ar.group_id AND drs.replica_id = ar.replica_id
where drs.synchronization_state_desc NOT IN ('SYNCHRONIZED') 
ORDER BY
	 ag.name
	,ar.replica_server_name
	,adc.database_name;