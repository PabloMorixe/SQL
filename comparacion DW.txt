with nuevo as
(
select 
	s.name as esquema,
	t.name as tabla,
	count(*) as particiones,
	sum( case when p.data_compression = 1 then 1 else 0 end) as part_1_Comprimidas,
	sum( case when p.data_compression = 2 then 1 else 0 end) as part_2_Comprimidas,
	sum(p.rows) as rows,
	sum(a.total_pages)/128 as MBytes	
from tableros.sys.partitions p with(nolock)
join tableros.sys.tables t     with(nolock)		   on t.object_id = p.object_id
join tableros.sys.schemas s with(nolock) on s.schema_id = t.schema_id
JOIN tableros.sys.allocation_units a  with(nolock)  ON a.container_id = p.partition_id
where p.index_id in (0,1)
group by
	s.name,
	t.name
)
select 
	viejo.*,
	nuevo.* ,
	viejo.rows - nuevo.rows as diffRows,
	viejo.Mbytes -nuevo.MBytes as diffMBytes
from openquery( [SSMCS-04],
'
select 
	s.name as esquema,
	t.name as tabla,
	count(*) as particiones,
	sum( case when p.data_compression = 1 then 1 else 0 end) as part_1_Comprimidas,
	sum( case when p.data_compression = 2 then 1 else 0 end) as part_2_Comprimidas,
	sum(p.rows) as rows,
	sum(a.total_pages)/128 as MBytes	
from tableros.sys.partitions p with(nolock)
join tableros.sys.tables t     with(nolock)		   on t.object_id = p.object_id
join tableros.sys.schemas s with(nolock) on s.schema_id = t.schema_id
JOIN tableros.sys.allocation_units a  with(nolock)  ON a.container_id = p.partition_id
where p.index_id in (0,1)
group by
	s.name,
	t.name
'
) AS viejo
full outer join nuevo on viejo.tabla = nuevo.tabla and nuevo.esquema = viejo.esquema
--where  viejo.tabla like 'FT_OPE_TRANSACCION'
order by 
	viejo.MBytes desc,
	viejo.tabla