--informa schema,table name, index_id, ix_name, key_ordinal(numero de orden de las columnas para componer el ix), nombre de la columna

select 
		SCHEMA_NAME(tb.schema_id),
		tb.name as table_name,
		ix.index_id,
		ix.name as index_name,
		key_ordinal,
		c.name as column_name		
from 
		sys.tables tb
join	sys.indexes ix
		on tb.object_id = ix.object_id
join sys.index_columns as ic
	on tb.object_id = ic.object_id
	and ix.index_id = ic.index_id
join syscolumns  as c
	on ic.column_id = c.colid
	and ic.object_id = c.id
where 
		is_included_column = 0 
--and		tb.name = 'ft_rv_cliente'
and		tb.name = 'dtc_tarjeta_credito'
order by 
		table_name,
		ix.index_id,
		index_name,
		key_ordinal
--ft_rv_cliente.PK__ft_rv_cl__21D760F449A09C3E