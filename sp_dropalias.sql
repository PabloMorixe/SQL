sp_configure 'allow updates',1
go
reconfigure with override
go

alter procedure sp_dropalias
    @loginame   sysname     -- login who is currently aliased
as
    -- SETUP RUNTIME OPTIONS / DECLARE VARIABLES --
	set nocount on
	declare @sid        varbinary(85)

    -- CHECK PERMISSIONS --
    if (not is_member('db_securityadmin') = 1) and
       (not is_member('db_owner') = 1)
	begin
		raiserror(15247,-1,-1)
		return (1)
	end

    -- DISALLOW USER TRANSACTION --
	set implicit_transactions off
	IF (@@trancount > 0)
	begin
		raiserror(15002,-1,-1,'sp_dropalias')
		return (1)
	end

	-- VALIDATE LOGIN NAME (OBTAIN SID) --
	if charindex('\', @loginame) = 0
		select @sid = suser_sid(@loginame)          -- sql user
	if @sid is null
	begin
		select @sid = get_sid('\U'+@loginame, NULL) -- nt user
		if @sid is null
			begin
			-- Check directly for alias in sysusers
			SELECT @sid = sid FROM sysusers WHERE isaliased = 1 AND name = '\'+@loginame
			if @sid is null
			begin
				if charindex('\', @loginame) = 0
				raiserror(15007,-1,-1,@loginame)
				else
				raiserror(15401,-1,-1,@loginame)
				return (1)
			end
		end
	end

    -- DELETE THE ALIAS (IF ANY) --
    delete from sysusers where sid = @sid and isaliased = 1

    -- ERROR IF NO ROW DELETED --
    if @@rowcount = 0
    begin
		raiserror(15134,-1,-1)
		return (1)
    end

    -- FINALIZATION: PRINT/RETURN SUCCESS --
	raiserror(15492,-1,-1)
	return (0) -- sp_dropalias



go
sp_configure 'allow updates',0
go
reconfigure with override
go
