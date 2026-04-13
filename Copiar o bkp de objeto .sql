

Declare @sql1 NVarchar(MAX)

Select @sql1 = Replace(definition, 'sppablo', 'sppablo2')

 From sys.sql_modules

Print (@sql1) 

EXEC (@sql1)