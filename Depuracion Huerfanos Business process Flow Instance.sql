/* DEBE BORRAR 4527692 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from BusinessProcessFlowInstanceBase a
	left join OpportunityBase b (nolock) on b.OpportunityId = a.Entity1Id and b.ProcessId = a.ProcessId where b.OpportunityId is null --4527692  >> 

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END
GO
/* DEBE BORRAR 421745 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from new_bpf_86a48da7b2d1447ab8f3b495a413bcf8Base a 
	left join OpportunityBase b (nolock) on b.OpportunityId = a.bpf_opportunityid and b.ProcessId = a.ProcessId where b.OpportunityId is null --421745  >> 

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END
go
/* DEBE BORRAR 159058 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from new_bpf_7bf390ffda6544dab13132660b8847daBase a 
	left join OpportunityBase b (nolock) on b.OpportunityId = a.bpf_opportunityid and b.ProcessId = a.ProcessId where b.OpportunityId is null --159058  

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END
go
/* DEBE BORRAR 94893 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from new_bpf_ed16fcc47e014572aede1da27204016fBase a 
	left join OpportunityBase b (nolock) on b.OpportunityId = a.bpf_opportunityid and b.ProcessId = a.ProcessId where b.OpportunityId is null --94893  

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END
go
/* DEBE BORRAR 15330050 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from new_bpf_13761294138f415e98fceb9e74ee4121Base a 
	left join OpportunityBase b (nolock) on b.OpportunityId = a.bpf_opportunityid and b.ProcessId = a.ProcessId where b.OpportunityId is null --15330050  

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END
go
/* DEBE BORRAR 16005761 registros */
SET NOCOUNT ON DECLARE @Deleted_Rows INT SET @Deleted_Rows = 1
WHILE (@Deleted_Rows > 0)
BEGIN
    DELETE TOP (50000) a
    from BusinessProcessFlowInstanceBase a 
	left join OpportunityBase b (nolock) on b.OpportunityId = a.Entity1Id and b.ProcessId = a.ProcessId where b.OpportunityId is null --16005761  

    set @Deleted_Rows = @@ROWCOUNT
    WAITFOR DELAY '00:00:01'

END