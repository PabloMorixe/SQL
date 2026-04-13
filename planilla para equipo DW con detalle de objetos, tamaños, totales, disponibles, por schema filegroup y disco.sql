--planilla para equipo DW con detalle de objetos, tamaños, totales, disponibles, por schema filegroup y disco 

use tableros

go


SELECT DS.name AS DataSpaceName
,f.physical_name
,AU.type_desc AS AllocationDesc
,AU.total_pages / 128 AS TotalSizeMB
,AU.used_pages / 128 AS UsedSizeMB
,AU.data_pages / 128 AS DataSizeMB
,SCH.name AS SchemaName
,OBJ.type_desc AS ObjectType
,OBJ.name AS ObjectName
,IDX.type_desc AS IndexType
,IDX.name AS IndexName
FROM sys.data_spaces AS DS
INNER JOIN sys.allocation_units AS AU
ON DS.data_space_id = AU.data_space_id
INNER JOIN sys.partitions AS PA
ON (AU.type IN (1, 3)
AND AU.container_id = PA.hobt_id)
OR
(AU.type = 2
AND AU.container_id = PA.partition_id)
JOIN sys.database_files f
on AU.data_space_id = f.data_space_id
INNER JOIN sys.objects AS OBJ
ON PA.object_id = OBJ.object_id
INNER JOIN sys.schemas AS SCH
ON OBJ.schema_id = SCH.schema_id
LEFT JOIN sys.indexes AS IDX
ON PA.object_id = IDX.object_id
AND PA.index_id = IDX.index_id
--WHERE f.file_id IN (13,14) AND AU.total_pages > 0 -- Look at specific files, could also filter on file group
ORDER BY AU.total_pages desc -- Order by size
  --DS.name
  --  ,SCH.name

 --      –,OBJ.name

  --     –,IDX.name