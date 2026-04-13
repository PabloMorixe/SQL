

SELECT a.fileid,
       CONVERT(DECIMAL(12, 2), Round(a .size / 128.000, 2)) AS [FILESIZEINMB],
       CONVERT(DECIMAL(12, 2), Round(Fileproperty (a. NAME, 'SpaceUsed') / 128.000, 2)) AS [SPACEUSEDINMB],
       CONVERT(DECIMAL (12, 2), Round ((a. SIZE - Fileproperty (a. NAME, 'SpaceUsed')) / 128.000, 2)) AS [FREESPACEINMB],
       a.NAME AS [DATABASENAME],
       a.filename AS [FILENAME],
       b .NAME
FROM sys. sysfiles a
LEFT OUTER JOIN sys. filegroups b ON a.groupid = b. data_space_id