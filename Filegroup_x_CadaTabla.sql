------------------------------------------------------------------------------------------------------------------------------
-- Detalle: Este script lista todos las tablas de una BD y su correspondiente Filegroup --
-- Gustavo Herrera para Sql Server Tips - http://gherrerasqlserver.blogspot.com/ --
------------------------------------------------------------------------------------------------------------------------------


SELECT
o.[name] AS 'TABLE',
f.[name] AS 'FILE_GROUP'
FROM sys.indexes i
inner JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.objects o
ON i.[object_id] = o.[object_id]
WHERE 
o.type = 'U' and
i.type < 2
Order by O.name
GO