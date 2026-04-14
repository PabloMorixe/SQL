DESDE SSMS 

--crea arbol de carpetas. 
--1 EJECUTAR LA SALIDA DE ESTA QUERY EN UN CMD
WITH FOLDERS AS
(
    SELECT
        CAST('E:\SSIS_EXPORT\' + PF.foldername AS VARCHAR(MAX)) AS FolderPath,
        PF.folderid,
        PF.parentfolderid
    FROM msdb.dbo.sysssispackagefolders PF
    WHERE PF.parentfolderid IS NULL

    UNION ALL

    SELECT
        CAST(F.FolderPath + '\' + PF.foldername AS VARCHAR(MAX)) AS FolderPath,
        PF.folderid,
        PF.parentfolderid
    FROM msdb.dbo.sysssispackagefolders PF
    JOIN FOLDERS F ON PF.parentfolderid = F.folderid
)
SELECT DISTINCT
    'mkdir "' + FolderPath + '"' AS cmd
FROM FOLDERS
WHERE FolderPath <> 'E:\SSIS_EXPORT\Data Collector';

2)  Exportar ETLS: 

--exporta por folder
--2 EJECUTAR LA SALIDA DE ESTA QUERY EN UN CMD


WITH FOLDERS AS
(
    SELECT
        CAST('\'+PF.foldername AS VARCHAR(MAX)) AS SSISPath,
        CAST('E:\SSIS_EXPORT\' + PF.foldername AS VARCHAR(MAX)) AS FilePath,
        PF.folderid,
        PF.parentfolderid
    FROM msdb.dbo.sysssispackagefolders PF
    WHERE PF.parentfolderid IS NULL

    UNION ALL

    SELECT
        CAST(F.SSISPath + '\' + PF.foldername AS VARCHAR(MAX)) AS SSISPath,
        CAST(F.FilePath + '\' + PF.foldername AS VARCHAR(MAX)) AS FilePath,
        PF.folderid,
        PF.parentfolderid
    FROM msdb.dbo.sysssispackagefolders PF
    JOIN FOLDERS F ON PF.parentfolderid = F.folderid
),
PACKAGES AS
(
    SELECT
        name AS PackageName,
        folderid
    FROM msdb.dbo.sysssispackages
)
SELECT
    'dtutil /sourceserver ' + @@SERVERNAME +
    ' /SQL "' + F.SSISPath + '\' + P.PackageName +
    '" /copy file;"' + F.FilePath + '\' + P.PackageName + '.dtsx"' AS cmd
FROM FOLDERS F
JOIN PACKAGES P ON P.folderid = F.folderid
WHERE F.SSISPath <> '\Data Collector';

