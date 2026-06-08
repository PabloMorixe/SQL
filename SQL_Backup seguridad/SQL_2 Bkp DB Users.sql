/*** CREA UN LISTADO DE QUERIES PARA REGENERAR LOS USERS ***/

SELECT CASE WHEN SP.[name] IS NOT NULL
         THEN N''
         ELSE N'IF EXISTS ( SELECT [name] FROM master.sys.server_principals WHERE [name] = N''' + DP.[name] + N''' ) '
       END +
       N'CREATE USER ' + QUOTENAME(DP.[name]) + N' ' +
       CASE WHEN SP.[name] IS NOT NULL
         THEN N'FOR ' + 
              CASE DP.[type]
                WHEN 'S' THEN N'LOGIN ' + QUOTENAME(SP.[name])
                WHEN 'U' THEN N'LOGIN ' + QUOTENAME(SP.[name])
                WHEN 'G' THEN N'LOGIN ' + QUOTENAME(SP.[name])
                WHEN 'C' THEN N'CERTIFICATE ' + QUOTENAME(SP.[name])
                WHEN 'K' THEN N'ASYMMETRIC KEY ' + QUOTENAME(SP.[name])
                ELSE N''
              END
         ELSE N'WITHOUT LOGIN'
       END +
       -- COMENTAR ESTE 'CASE' SI JODEN LOS SCHEMAS --
       CASE WHEN DP.[default_schema_name] IS NOT NULL
         THEN N' WITH DEFAULT_SCHEMA = ' + QUOTENAME(DP.[default_schema_name])
         ELSE N''
       END +
       -----------------------------------------------
       N';' as [QUERY DE MAPEOS A LOGIN]
FROM sys.database_principals DP
LEFT JOIN master.sys.server_principals SP on SP.[sid] = DP.[sid] --> INNER JOIN si no se desea mantener Users huerfanos
WHERE DP.[principal_id] > 4
AND DP.[type] IN ('S','U','G','C','K')
GO