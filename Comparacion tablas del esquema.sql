use tableros ;

declare @schema_id_origen int;
declare @schema_id_destino int;
declare @schema_name sysname = 'dwm';

Select @schema_id_origen  = schema_id  from [SSMCS-04].tableros.sys.schemas where [name] like @schema_name;
Select @schema_id_destino = schema_id from tableros.sys.schemas where [name] like @schema_name;

/*
select 
		@schema_id_origen as schema_id_origen, 
		@schema_id_destino as schema_id_destino;
*/






;with tablasDestino as
(
	SELECT 
		o.name AS [ObjectName], 
		SUM(p.Rows) AS filas 
	FROM 
				 tableros.sys.partitions AS p WITH (NOLOCK)
	INNER	JOIN tableros.sys.tables AS o WITH (NOLOCK)
					ON p.object_id = o.object_id
	WHERE 
		schema_id = @schema_id_destino
		and index_id < 2 --ignore the partitions from the non-clustered index if any
	GROUP BY  
		o.name
),
tablasOrigen as 
(
	SELECT 
		o.name AS [ObjectName], 
		SUM(p.Rows) AS filas 
	FROM 
				 [SSMCS-04].tableros.sys.partitions AS p WITH (NOLOCK)
	INNER	JOIN [SSMCS-04].tableros.sys.tables AS o WITH (NOLOCK)
					ON p.object_id = o.object_id
	WHERE 
		schema_id = @schema_id_origen 
		and index_id < 2 --ignore the partitions from the non-clustered index if any
	GROUP BY  
		o.name
)
select 
	o.ObjectName as tablaorigen,
	o.filas as filasorigen,
	d.ObjectName as tabladestino,
	d.filas as filasdeatino,
	o.filas - d.filas as filasDiferencia

from tablasDestino as D
full outer join tablasOrigen as O
		on o.ObjectName = D.ObjectName;











