sp_whoisactive 68, 
    @delta_interval = 5
	,@get_outer_command = 1
	,@get_plans = 1
	--,@Sort_order = 
	go
	sp_whoisactive @get_plans=2  
	go



EXEC sp_WhoIsActive 68,
    @find_block_leaders = 1,
	 @delta_interval = 5,
    @sort_order = '[blocked_session_count] DESC'

sp_whoisactive --         15,626,471
select * from sysprocesses where blocked > 0  or spid = 106
--
sp_whoisactive
    @delta_interval = 60 
	,@get_outer_command = 1
	,@get_plans = 1
	--,@Sort_order = 
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
