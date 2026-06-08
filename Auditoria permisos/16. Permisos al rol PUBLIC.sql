USE epm_sistemas
GO


--CONSULTA LOS PERMISOS QUE TIENE ASIGNADOS EL ROL PUBLIC EN LA BD ACTUAL
SELECT U.NAME, O.name, O.type, CASE P.action
                                          WHEN 26 THEN 'REFERENCES'
                                          WHEN 178 THEN 'CREATE FUNCTION'
                                          WHEN 193 THEN 'SELECT'
                                          WHEN 195 THEN 'INSERT'
                                          WHEN 196 THEN 'DELETE'
                                          WHEN 197 THEN 'UPDATE'
                                          WHEN 198 THEN 'CREATE TABLE'
                                          WHEN 203 THEN 'CREATE DATABASE'
                                          WHEN 207 THEN 'CREATE VIEW'
                                          WHEN 222 THEN 'CREATE PROCEDURE'
                                          WHEN 224 THEN 'EXECUTE'
                                          WHEN 228 THEN 'BACKUP DATABASE'
                                          WHEN 233 THEN 'CREATE DEFAULT'
                                          WHEN 235 THEN 'BACKUP LOG'
                                          WHEN 236 THEN 'CREATE RULE'
                                          END AS [PERM], U.createdate, U.updatedate
FROM sysprotects P
INNER JOIN sysusers U
ON P.uid = U.uid
INNER JOIN sysobjects O
ON P.id = O.id
WHERE P.uid = 0
AND O.type <> 'S'
AND O.name NOT LIKE 'sys%'
AND O.name NOT LIKE 'sync%'
AND O.name NOT LIKE 'dt_%'





--AUDITA LA CANTIDAD DE PERMISOS ASIGNADOS AL ROL PUBLIC EN TODAS LAS BD DE LA INSTANCIA
EXEC sp_msforeachdb 'USE ?;
SELECT DB_NAME() AS [Database], COUNT(*) AS [PublicPermissionCount]
FROM sysprotects P
INNER JOIN sysusers U
ON P.uid = U.uid
INNER JOIN sysobjects O
ON P.id = O.id
WHERE P.uid = 0
AND O.type <> ''S''
AND O.name NOT LIKE ''sys%''
AND O.name NOT LIKE ''sync%''
AND O.name NOT LIKE ''dt_%'''