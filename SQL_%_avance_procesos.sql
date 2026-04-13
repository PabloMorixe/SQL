  ----------------
  --Opcion 1
  ----------------

sELECT percent_complete, estimated_completion_time
  FROM sys.dm_exec_requests
  WHERE percent_complete > 0
  
  ----------------
  --Opcion 2 
  ----------------
  
SELECT
    dm_er.session_id id_Sesion,
    dm_er.command Comando,
    CONVERT(NUMERIC(6, 2), dm_er.percent_complete) AS [Porcentaje Completedo],
    CONVERT(VARCHAR(20), Dateadd(ms, dm_er.estimated_completion_time, Getdate()),20) AS [Tiempo Estimado Finalizacion],
    CONVERT(NUMERIC(6, 2), dm_er.estimated_completion_time / 1000.0 / 60.0) AS [Minutos pendientes]
FROM
    sys.dm_exec_requests dm_er
WHERE  
    dm_er.command IN ( 'RESTORE VERIFYON', 'RESTORE DATABASE','BACKUP DATABASE','RESTORE LOG','BACKUP LOG', 'RESTORE HEADERON' )


  ----------------
  --Opcion 3
  ----------------

/*


SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete, dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time 
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE')


*/

  ----------------
  --Opcion 4
  ----------------
  SELECT command,
            s.text,
            start_time,
            percent_complete,
            CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
                  + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
                  + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.command in ('RESTORE DATABASE', 'BACKUP DATABASE', 'RESTORE LOG', 'BACKUP LOG')

  ----------------
  --Opcion 5
  ----------------

SELECT
dm_er.session_id id_Sesion,
dm_er.command Comando,
CONVERT(NUMERIC(6, 2), dm_er.percent_complete) AS [Porcentaje Completado],
CONVERT(VARCHAR(20), Dateadd(ms, dm_er.estimated_completion_time, Getdate()),20) AS [Tiempo Estimado Finalizacion],
CONVERT(NUMERIC(6, 2), dm_er.estimated_completion_time / 1000.0 / 60.0) AS [Minutos pendientes]
FROM
sys.dm_exec_requests dm_er
WHERE
dm_er.command IN ( 'UPDATE STATISTIC','ALTER INDEX','DBCC','DbccFilesCompact','RESTORE VERIFYON', 'RESTORE DATABASE','BACKUP DATABASE','RESTORE LOG','BACKUP LOG', 'RESTORE HEADERON' )
