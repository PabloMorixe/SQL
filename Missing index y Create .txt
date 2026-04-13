----------------------------------------------------------
----- Querying the plan cache for missing indexes --------
----------------------------------------------------------
IF OBJECT_ID('tempdb..#MissingIndexTable') IS NOT NULL DROP Table #MissingIndexTable
SELECT
 -- @DBName  as db_name,
  dbs.name  as db_name,
  mid.statement as table_name,
  IsNull(mid.equality_columns, '') as equality_columns, 
  IsNull(mid.inequality_columns, '') as inequality_columns,
  IsNull(mid.included_columns, '') as included_columns,
  migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS overal_impact_value,
  'CREATE INDEX [NCIX_' + REPLACE(REPLACE(REPLACE(mid.equality_columns, '[', ''), ']',''),',','_')+ ']' 
  + ' ON ' + mid.statement
  + ' (' + ISNULL (mid.equality_columns,'')
  + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
  + ISNULL (mid.inequality_columns, '')
  + ')'
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement

into  #MissingIndexTable
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
LEFT OUTER JOIN sys.databases dbs ON mid.database_id=dbs.database_id
WHERE migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) > 1000 and dbs.database_id > 4
select * from #MissingIndexTable
----------------------------------------------------------
--------