--select db_name(dbid),* from sysprocesses where loginame like '%pruebas%'
select db_name(dbid),* from sysprocesses order by cpu desc 
select hostname, db_name(dbid),hostname, loginame, * from sysprocesses where spid > 50 order by 5
--select db_name(dbid),* from sysprocesses where blocked > 0 order by blocked
go
sp_whoisactive @get_plans=2   
go
sp_who2  57




select * from master..sysprocesses where sesion_id = 57

use master 
go
select [TExT],* from sysprocesses as SP
cross apply  sys.dm_exec_sql_text (sp.[sql_handle])  
--where text like 'opera'
where sp.sid = 57


select *--distinct(diadesde), 
--diadesde,id_proceso,diadesde,DiaHasta,orden, tipo, base, esquema, nombre,flg_critico,flg_hecho,inicio,fin
--,convert(int,(fin), 108) as duracionint
--,convert(varchar,(fin), 108) as duracionvarchar
--,max(fin)
from ctl.ctl_proc_list_running
 where 
id_proceso like '%RUN_DIARIO_DW_e'
--and Nombre like '%EXEC_JOB_DIARIO_DW_CAMPAING'
and DiaDesde = 20190731
--and  flg_critico = 1
order by orden

select * from Tableros.ctl.ctl_proc_list_running r where id_proceso = 'RUN_DIARIO_DW_E2' and DiaDesde = 20190731 and nombre in ('UPD_DCL_PERSONA','UPD_DCL_PERSONA_SEGMENTO_2018','EXEC_JOB_DIARIO_DW_E2_RV')



select *
from DWABM.dbo.log_etl
where proceso = 'LDR_DTC_TARJETA_CREDITO'
order by FecInicio desc


SELECT session_id, blocking_session_id,text
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
WHERE session_id > 50