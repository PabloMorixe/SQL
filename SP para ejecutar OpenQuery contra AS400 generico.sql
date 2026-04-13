Create Procedure dbo.SP_EJECUTAR_SQL_JDE
(
	@SQL varchar(3000)
)
As

BEGIN
	Set @SQL = Replace(@SQL, '''', '''''')

	Set @SQL = 'select * from OpenQuery(BAIRES1,''' + @SQL + ''')'

	execute(@SQL)

END

