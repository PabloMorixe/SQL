

--compara los indices de dos bases de acuerdo a la cantidad de columnas que los componen. 
with nuevo as
		(
			SELECT 
				tb.create_date,
				schema_name(schema_id) +'.' + tb.name as N_table,				 
				count(*) as cantidad
			FROM 
				 tableros.sys.indexes  ix
				 inner join  sys.tables tb
				 on ix.object_id = tb.object_id
			group by 
				tb.create_date,
				schema_name(schema_id) +'.' + tb.name
		), 
viejo as
	(
		select 
			*
		from openquery( 
			[SSMCS-04],
			'
				SELECT 
					schema_name(schema_id) +''.'' + tb.name as N_table,				 
					count(*) as cantidad
				FROM 
					 tableros.sys.indexes  ix
					 inner join  sys.tables tb
					 on ix.object_id = tb.object_id
				group by 					
					schema_name(schema_id) +''.'' + tb.name
			'
			)

	)
Select  
			viejo.N_table,
			nuevo.N_table,
			viejo.cantidad,
			nuevo.cantidad,
			nuevo.create_date

from 
					viejo 
full outer join		nuevo 
				on viejo.N_table = nuevo.N_table
where 
	(viejo.N_table is not NULL and nuevo.N_table  is null)
OR  (viejo.N_table is NULL and nuevo.N_table  is NOT null)
or	viejo.cantidad <> nuevo.cantidad


--		or		
--		)
--		and VIEJO.V_TBL_name is not null

order by 
			viejo.N_table,
			nuevo.N_table

