SELECT DISTINCT dovs.logical_volume_name AS NombreLogico,
dovs.volume_mount_point AS Disco,
CONVERT(INT,(dovs.available_bytes/1048576.0)/1024.0) AS EspacioLibreGB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
ORDER BY EspacioLibreGB ASC
GO