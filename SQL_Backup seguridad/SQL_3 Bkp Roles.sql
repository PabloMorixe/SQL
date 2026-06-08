/*** CREA DOS LISTADOS DE QUERIES PARA REGENERAR LOS ROLES ***/

-- 1) SCRIPTS DE CREACION

SELECT N'CREATE ROLE ' + QUOTENAME(DP1.[name]) + N' ' +
       N'AUTHORIZATION ' + QUOTENAME(DP3.[name]) as [QUERY DE CREACION]
FROM sys.database_principals DP1
INNER JOIN sys.database_principals DP3 on DP3.[principal_id] = DP1.[owning_principal_id]
WHERE DP1.[type] = 'R'
AND DP1.[is_fixed_role] = 0
AND DP1.[principal_id] > 0
GO

-- 2) SCRIPTS DE ASIGNACION A ROLES

SELECT N'IF EXISTS ( SELECT [name] FROM sys.database_principals WHERE [name] = N''' + DP2.[name] + N''') ' +
       N'EXEC sp_addrolemember ''' + DP1.[name] + N''', ''' + DP2.[name] + N''';' as [QUERY DE ASIGNACION]
FROM sys.database_principals DP1
INNER JOIN sys.database_role_members SRM on SRM.[role_principal_id] = DP1.[principal_id]
INNER JOIN sys.database_principals DP2 on DP2.[principal_id] = SRM.[member_principal_id]
WHERE DP1.[type] = 'R'
AND DP2.[name] <> 'dbo'
--AND DP1.[is_fixed_role] = 0  --> No comentar si se buscan solo los roles de usuario
AND DP1.[principal_id] > 0
GO


/*
-- LISTADO DE ROLES Y MIEMBROS --

SELECT DP1.[name] as [ROLES], DP2.[name] as [MIEMBROS]
FROM sys.database_principals DP1
INNER JOIN sys.database_role_members SRM on SRM.[role_principal_id] = DP1.[principal_id]
INNER JOIN sys.database_principals DP2 on DP2.[principal_id] = SRM.[member_principal_id]
WHERE DP1.[type] = 'R'
--AND DP1.[is_fixed_role] = 0  --> No comentar si se buscan solo los roles de usuario
AND DP1.[principal_id] > 0
ORDER BY DP1.[name] ASC
*/