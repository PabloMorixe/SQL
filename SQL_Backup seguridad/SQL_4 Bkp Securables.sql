/**** GENERA UNA LISTA DE SCRIPTS PARA REGENERAR PERMISOS EN LA DB ACTIVA ****/

SELECT N'IF EXISTS ( SELECT [name] FROM sys.database_principals WHERE [name] = N''' + DPR.[name] + N''') ' +
       CASE DP.[state]
         WHEN 'G' THEN N'GRANT '
         WHEN 'D' THEN N'DENY '
         WHEN 'R' THEN N'REVOKE '
         WHEN 'W' THEN N'GRANT '
       END +
       DP.[permission_name] COLLATE latin1_general_cs_as +
       CASE DP.[class]
         -- Si es la base de datos
         WHEN 0 THEN N''
         -- Si es un objeto
         WHEN 1 THEN N' ON ' + QUOTENAME(SCH.[name]) + N'.' + QUOTENAME(OBJ.[name]) +
                     CASE WHEN DP.[minor_id] <> 0
                       -- Si es una columna
                       THEN N' (' + COL.[name] + ') '
                       ELSE N''
                     END
         -- Si es un schema
         WHEN 3 THEN N' ON SCHEMA:: ' + QUOTENAME(SCH2.[name])
         -- Si es un user
         -- WHEN 4 THEN N' ON ' ......
         ELSE QUOTENAME(SCH.[name]) + N'.' + QUOTENAME(OBJ.[name]) -- VER PARA AMPLIAR SCRIPT
       END + N' TO ' + QUOTENAME(DPR.[name]) +
       CASE WHEN DP.[state] = 'W'
         THEN N' WITH GRANT OPTION;'
         ELSE N';'
       END as [Query de restauracion de securables]
FROM sys.database_permissions AS DP
LEFT JOIN sys.objects AS OBJ ON DP.[major_id] = OBJ.[object_id]
LEFT JOIN sys.schemas AS SCH ON OBJ.[schema_id] = SCH.[schema_id]
LEFT JOIN sys.schemas AS SCH2 ON SCH2.[schema_id] = DP.[major_id]
INNER JOIN sys.database_principals AS DPR ON DP.[grantee_principal_id] = DPR.[principal_id]
LEFT JOIN sys.columns AS COL ON COL.[object_id] = DP.[minor_id]
WHERE DP.[grantee_principal_id] NOT IN (0,2,3)   --> Excluyendo public, guest, INFORMATION_SCHEMA
  AND DP.[permission_name] <> 'CONNECT'          --> Se excluyen los permisos de conexión, ya garantizados por el CREATE USER

/*
-- ADICIONAL PARA VERIFICAR PERMISOS GUEST Y PUBLICOS --

SELECT CASE DP.[state]
         WHEN 'G' THEN N'GRANT '
         WHEN 'D' THEN N'DENY '
         WHEN 'R' THEN N'REVOKE '
         WHEN 'W' THEN N'GRANT '
       END +
       DP.[permission_name] COLLATE latin1_general_cs_as +
       CASE DP.[class]
         -- Si es la base de datos
         WHEN 0 THEN N''
         -- Si es un objeto
         WHEN 1 THEN N' ON ' + QUOTENAME(SCH.[name]) + N'.' + QUOTENAME(OBJ.[name]) +
                     CASE WHEN DP.[minor_id] <> 0
                       -- Si es una columna
                       THEN N' (' + COL.[name] + ') '
                       ELSE N''
                     END
         -- Si es un schema
         WHEN 3 THEN N' ON SCHEMA:: ' + QUOTENAME(SCH2.[name])
         -- Si es un user
         -- WHEN 4 THEN N' ON ' ......
         ELSE QUOTENAME(SCH.[name]) + N'.' + QUOTENAME(OBJ.[name]) -- VER PARA AMPLIAR SCRIPT
       END + N' TO ' + QUOTENAME(DPR.[name]) +
       CASE WHEN DP.[state] = 'W'
         THEN N' WITH GRANT OPTION;'
         ELSE N';'
       END as [Query de restauracion de securables]
FROM sys.database_permissions AS DP
LEFT JOIN sys.objects AS OBJ ON DP.[major_id] = OBJ.[object_id]
LEFT JOIN sys.schemas AS SCH ON OBJ.[schema_id] = SCH.[schema_id]
LEFT JOIN sys.schemas AS SCH2 ON SCH2.[schema_id] = DP.[major_id]
INNER JOIN sys.database_principals AS DPR ON DP.[grantee_principal_id] = DPR.[principal_id]
LEFT JOIN sys.columns AS COL ON COL.[object_id] = DP.[minor_id]
WHERE DP.[grantee_principal_id] IN (0,2,3)   --> public, guest, INFORMATION_SCHEMA
GO
*/