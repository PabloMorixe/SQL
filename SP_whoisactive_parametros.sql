  EXEC sp_whoisactive 
    @output_column_list = '[dd hh:mm:ss.mss][start_time][session_id][database_name][login_name][sql_text][wait_info][blocking_session_id][status][percent_complete][cpu][tempdb_allocations][tempdb_current][reads][writes][physical_reads][used_memory][open_tran_count][host_name][program_name][login_time][request_id][collection_time]',
    @sort_order = '[cpu] DESC'; 
---------
sp_whoisactive --         15,626,471
select * from sysprocesses where blocked > 0  or spid = 106
--
sp_whoisactive
    @delta_interval = 60 
	,@get_outer_command = 1
	,@get_plans = 1
	--,@Sort_order = 
	sp_whoisactive 
   @show_sleeping_spids = 2


	go
	sp_whoisactive @get_plans=2  
	go

	select * from sysprocesses where blocked > 0

	---
sp_whoisactive 

 328, @get_plans=2
go
 sp_who2 328
 --go

 sp_whoisactive 76,
    @delta_interval = 10 
	,@get_outer_command = 1
	,@get_plans = 1
