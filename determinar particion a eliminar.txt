SELECT 
	schema_name(t.schema_id) as schemaname,
	t.name as tablename,
	p.[partition_number]
	,p.rows
	,r.value,
	pf.name as partitionfunction,
	case
		when pf.boundary_value_on_right = 0 then 'LEFT'
		ELSE 'RIGHT'
	end as Boundary
FROM 
			sys.tables t
INNER JOIN	sys.partitions p ON p.[object_id] = t.[object_id]
INNER JOIN	sys.indexes i ON p.[object_id] = i.[object_id] AND p.[index_id] = i.[index_id]
INNER JOIN	sys.data_spaces ds ON i.[data_space_id] = ds.[data_space_id]
INNER JOIN	sys.partition_schemes ps ON ds.[data_space_id] = ps.[data_space_id]
INNER JOIN	sys.partition_functions pf ON ps.[function_id] = pf.[function_id]
LEFT JOIN	sys.partition_range_values AS r ON pf.[function_id] = r.[function_id] AND r.[boundary_id] = p.[partition_number]
where
		p.[rows] > 0
and		i.index_id in (0,1)
--and		r.[value] <= @fechahasta
--and		r.[value] > @fechadesde
and		t.schema_id = SCHEMA_ID('dbo')
and		t.[name] = 'ft_saldos_ope_mmed'
ORDER BY
 
	p.[partition_number] asc	
	go
-----------------------------------------------------
	select count(*) from FT_SALDOS_OPE_MMED
	where id_tie_mes = 200809

