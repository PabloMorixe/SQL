

--select  @cantdb  select count(name) from master..sysdatabases

declare @cantdb  int


SELECT --top (select count(name) from master..sysdatabases where dbid > 4) 
    bs.database_name,
    bs.backup_start_date,
	bs.backup_finish_date,
	bs.name,
	bs.description,
    bmf.physical_device_name
	--bs.*
FROM
    msdb.dbo.backupmediafamily bmf
    JOIN
    msdb.dbo.backupset bs ON bs.media_set_id = bmf.media_set_id


	where database_name not in ('Master','model','msdb','tempdb','sqlmant')
	order by 2 desc
	
	----
	SELECT TOP (10000) s.database_name
,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken
,s.backup_start_date
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,CASE s.[type] WHEN 'D'
THEN 'Full'
WHEN 'I'
THEN 'Differential'
WHEN 'L'
THEN 'Transaction Log'
END AS BackupType
,s.server_name
,s.recovery_model
FROM msdb.dbo.backupset s
INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
WHERE s.database_name = 'bff-mobile-individuos'
--AND s.[type] = 'D'
ORDER BY backup_start_date DESC
,backup_finish_date
	