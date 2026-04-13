SELECT
    db.name AS DBName,
    type_desc AS FileType,
    Physical_Name AS Location
FROM 
    sys.master_files mf
INNER JOIN 
    sys.databases db ON db.database_id = mf.database_id 

	where db.database_id > 4 
	and  db.name <> 'SQLMANt'
	and Physical_Name like 'j:\%'
	or Physical_Name like 'i:\%'