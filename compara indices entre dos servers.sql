--compara indices entre dos servers
with sspr17dwh01 as
		(
			SELECT 
				schema_name(schema_id) +'.' + tb.name +'.' + coalesce(ix.name,'') as N_IX_name				 
			FROM 
				 tableros.sys.indexes  ix
				 inner join  sys.tables tb
				 on ix.object_id = tb.object_id
		), 
ssmcs04 as
	(
		select 
			*
		from openquery( [SSMCS-04],
		'

		SELECT 			
			schema_name(schema_id) +''.'' + tb.name +''.'' +coalesce(ix.name,'''') as V_IX_name
		FROM 
			 tableros.sys.indexes  ix
			 inner join  sys.tables tb
			 on ix.object_id = tb.object_id'
			)
	)
Select  
			ssmcs04.V_IX_name,
			sspr17dwh01.N_IX_name
from 
					ssmcs04 
full outer join		sspr17dwh01 
				on ssmcs04.V_IX_name = sspr17dwh01.N_IX_name 
where 
	(ssmcs04.V_IX_name is not NULL and sspr17dwh01.N_IX_name  is null)
OR  (ssmcs04.V_IX_name is NULL and sspr17dwh01.N_IX_name  is NOT null)--		or		
--		)
--		and ssmcs04.V_TBL_name is not null
order by 
			ssmcs04.V_IX_name,
			sspr17dwh01.N_IX_name
/*
SELECT 
    tb.name as N_TBL_name,
	coalesce(ix.name,'') as N_IX_name

FROM 
     tableros.sys.indexes  ix
	 inner join  sys.tables tb
	 on ix.object_id = tb.object_id
order by 
	
	N_TBL_name,
	N_IX_name 
*/


