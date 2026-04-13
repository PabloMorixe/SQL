

sp_configure 'allow updates',1
go
reconfigure with override
go

alter procedure sp_addalias
    @loginame       sysname,    -- name of the pretender
    @name_in_db     sysname     -- user to whom to alias the login
as
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
	set nocount on
	declare @sid        varbinary(85),
            @targuid    smallint,
            @newuid     smallint,
            @status     smallint,
            @dbname     sysname

    -- CHECK PERMISSIONS --
    create table #Trace_Status (TraceFlag int, Status int)
	DBCC TRACESTATUS('no_output', 4650) with NO_INFOMSGS
	if @@rowcount > 0
	begin
		insert into #Trace_Status exec('DBCC TRACESTATUS(4650) WITH NO_INFOMSGS')
	end
       
    if (not is_member('db_owner') = 1) and not exists (select * from #Trace_Status where TraceFlag = 4650 and Status = 1) 
	and (not is_member('db_securityadmin') = 1)
	begin
		drop table #Trace_Status
		raiserror(15247,-1,-1)
		return (1)
	end

	drop table #Trace_Status

    -- DISALLOW USER TRANSACTION --
	set implicit_transactions off
	IF (@@trancount > 0)
	begin
		raiserror(15002,-1,-1,'sp_addalias')
		return (1)
	end

    -- VALIDATE LOGIN NAME (OBTAIN SID) --
    select @status = CASE WHEN charindex('\', @loginame) > 0 THEN 12 ELSE 0 END
    if @status = 0
        select @sid = suser_sid(@loginame)          -- sql user
    -- retry sql user as nt with dflt domain
    if @sid is null
    begin
        select @sid = get_sid('\U'+@loginame, NULL) -- nt user
        if @sid is null
        begin
            if @status = 0
                raiserror(15007,-1,-1,@loginame)
            else
                raiserror(15401,-1,-1,@loginame)
            return (1)
        end
        select @status = 12
    end
    -- PREVENT USE OF CERTAIN LOGINS --
	else if @sid = 0x1
	begin
		raiserror(15405, -1, -1, @loginame)
		return (1)
	end

    -- VALIDATE NAME-IN-DB (OBTAIN TARGET UID) --
    select @targuid = uid from sysusers where name = @name_in_db
                        and (issqluser = 1 or isntuser = 1)
						and uid NOT IN (3,4)	-- INFORMATION_SCHEMA, system_function_schema
    if @targuid is null
	begin
		raiserror(15008,-1,-1,@name_in_db)
		return (1)
	end

    -- ERROR IF LOGIN ALREADY IN DATABASE --
    if exists (select sid from sysusers where sid = @sid)
    begin

        -- ERROR IF ALREADY ALIASED --
        if exists (select sid from sysusers where sid = @sid and isaliased = 1)
	    begin
		    raiserror(15022,-1,-1)
		    return (1)
	    end

        -- ERROR: LOGIN ALREADY A USER --
        select @name_in_db = name, @dbname = db_name() from sysusers where sid = @sid
        raiserror(15278,-1,-1,@loginame,@name_in_db,@dbname)
        return (1)
    end

    -- ALTER NAME TO AVOID CONFLICTS IN NAME SPACE --
    select @loginame = '\' + @loginame
    if user_id(@loginame) is not null
    begin
	    raiserror(15023,-1,-1,@loginame)
        return (1)
    end

    -- OBTAIN NEW UID (RESERVE 1-4) --
    if user_name(5) IS NULL
        select @newuid = 5
    else
		select @newuid = min(uid)+1 from sysusers
            where uid >= 5 and uid < (16384 - 1)    -- stay in users range
                and user_name(uid+1) is null        -- uid not in use
    if @newuid is null
	begin
		raiserror(15065,-1,-1)
		return (1)
	end

    -- INSERT SYSUSERS ROW --
    insert into sysusers select
        @newuid, @status | 16, @loginame, @sid, 0x00,
                getdate(), getdate(), @targuid, NULL

    -- FINALIZATION: PRINT/RETURN SUCCESS --
    if @@error <> 0
        return (1)
    raiserror(15340,-1,-1)
    return (0) -- sp_addalias

go
sp_configure 'allow updates',0
go
reconfigure with override
go