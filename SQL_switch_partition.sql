--ALERTA! SE ENCONTRARON ERRORES AL ANALIZAR EL CODIGO SQL!
CREATE PROCEDURE switchoff @daystoretain INT
AS
BEGIN
	DECLARE @partNumbmax INT
	DECLARE @Maxid BIGINT

	SELECT @Maxid = max(id)
	FROM [audit_bff]
	WHERE fecha < getdate() - @daystoretain

	PRINT @maxid --SELECT * FROM FileGroupDetai
		l

	SELECT @partNumbmax = max(partition_number)
	FROM FileGroupDetail
	WHERE range_value < (@Maxid)
		AND pf_name = 'PF_audit_bff' --select * from audit_bff    print @partNumbmax    SELECT * FROM FileGroupDetail     declare @mergeRange bigint      WHIL
		E(@partNumbmax > 0)

	BEGIN --print 'begin'     --print @partNumbmax     -- limpio switch table     truncate table audit_bff_switch     --switcheo     ALTER TABLE audit_bff SWITCH PARTITION @partNumbmax TO audit_bff_switch     --mergeo      select 
		TOP 1 @mergeRange = cast(range_value AS BIGINT)
		FROM FileGroupDetail
		WHERE pf_name = 'PF_audit_bff'
			AND partition_number = @partNumbmax --print @mergeRange     ALTER PARTITION FUNCTION PF_audit_bff() MERGE RANGE (@mergeRange)       SET @partNumbmax=(s
			elect max(partition_number)
		FROM FileGroupDetail
		WHERE range_value < @Maxid
			AND pf_name = 'PF_audit_bff' )
	END
END
