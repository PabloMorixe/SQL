/*  IO Table  */
 
Select db_name(d.database_id) as database_name,
  quotename(object_schema_name(d.object_id, d.database_id)) + N'.' + quotename(object_name(d.object_id, d.database_id)) as object_name,
  d.page_io_latch_wait_count,
  d.page_io_latch_wait_in_ms,
  d.range_scans,
  d.index_lookups,
  case when mid.database_id is null then 'N' else 'Y' end as missing_index_identified
from (select
	database_id,
	object_id,
	row_number() over (partition by database_id order by sum(page_io_latch_wait_in_ms) desc) as row_number,
	sum(page_io_latch_wait_count) as page_io_latch_wait_count,
	sum(page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms,
	sum(range_scan_count) as range_scans,
	sum(singleton_lookup_count) as index_lookups
   from sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL)
   where page_io_latch_wait_count > 0
   group by database_id, object_id ) as d
  left join (select distinct database_id, object_id from sys.dm_db_missing_index_details) as mid
   on mid.database_id = d.database_id and mid.object_id = d.object_id
where d.row_number <= 20 --and db_name(d.database_id)= 'master'
order by page_io_latch_wait_in_ms desc