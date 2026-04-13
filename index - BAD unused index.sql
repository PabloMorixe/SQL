SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id, 
  i.is_disabled, i.is_hypothetical, i.has_filter, i.fill_factor,
   user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
   user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
   FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
   INNER JOIN sys.indexes AS i WITH (NOLOCK)
   ON s.[object_id] = i.[object_id]
   AND i.index_id = s.index_id
   WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
   AND s.database_id = DB_ID()
   AND user_updates > (user_seeks + user_scans + user_lookups)
   AND i.index_id > 1
   ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC OPTION (RECOMPILE);

-- Unused Index Script
-- Original Author: Pinal Dave 
SELECT TOP 25
o.name AS ObjectName
, i.name AS IndexName
, i.index_id AS IndexID
, dm_ius.user_seeks AS UserSeek
, dm_ius.user_scans AS UserScans
, dm_ius.user_lookups AS UserLookups
, dm_ius.user_updates AS UserUpdates
, p.TableRows
, 'DROP INDEX ' + QUOTENAME(i.name)
+ ' ON ' + QUOTENAME(s.name) + '.'
+ QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS 'drop statement'
FROM sys.dm_db_index_usage_stats dm_ius
INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id 
AND dm_ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
AND dm_ius.database_id = DB_ID()
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
GO