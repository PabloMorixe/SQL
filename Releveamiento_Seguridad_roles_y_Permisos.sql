/* 
				El script arma un inventario de accesos a SQL Server en dos niveles:
				Nivel base de datos

				Nivel servidor
				y lo deja todo en una sola tabla temporal #DB_Permissions para que después lo puedas exportar / filtrar.
				
				1) Tabla temporal de trabajo
				CREATE TABLE #DB_Permissions (...)
				Crea una tabla temporal donde se va a guardar todo:
				InstanceName → nombre de la instancia (SERVERPROPERTY('ServerName'))
				DatabaseName → nombre de la base (o (SERVER_LEVEL) si es a nivel servidor)
				PrincipalName → usuario o grupo dentro de la DB / servidor
				PrincipalType → tipo de principal (SQL_USER, WINDOWS_USER, WINDOWS_GROUP, SQL_LOGIN, etc.)
				LoginName / LoginType → login de servidor asociado, si existe
				IsADGroup → 1 si es grupo de AD (WINDOWS_GROUP)
				IsGGAUM / IsGGAUR → 1 si el nombre matchea GGAUM_DB-% o GGAUR_DB-%
				RoleName → rol (de base o de servidor)
				PermissionType / PermissionName → GRANT/DENY y nombre del permiso
				ObjectType / ObjectName → qué tipo de objeto y cuál (DB, tabla, endpoint, etc.)
				
				2) Recorrido de todas las bases de usuario
				Construye dinámicamente un bloque T-SQL que se ejecuta en cada base de datos ONLINE de usuario:
				FROM sys.databases
				WHERE database_id > 4  -- excluye master, model, msdb, tempdb
				  AND state = 0        -- solo ONLINE
				Y para cada base hace dos cosas:
				2.1 Membresía de roles de base de datos
				Bloque 1.1:
				FROM sys.database_role_members drm
				JOIN sys.database_principals role_principal
				JOIN sys.database_principals member_principal
				LEFT JOIN master.sys.server_principals sp
				Inserta en #DB_Permissions:
				qué usuario/grupo (member_principal) pertenece a qué rol de base (role_principal, ej. db_datareader, db_datawriter, etc.),
				qué login de servidor tiene asociado (si lo hay),
				marca si es AD (IsADGroup),
				y si respeta nomenclatura GGAUM_DB-% o GGAUR_DB-%.
				Esto te dice, por base, quién pertenece a qué rol de base de datos.
				2.2 Permisos explícitos a nivel DB / objeto

				Bloque 1.2:
				FROM sys.database_permissions perm
				JOIN sys.database_principals dp
				LEFT JOIN master.sys.server_principals sp
				LEFT JOIN sys.schemas s


				Inserta:
				permisos GRANT/DENY asignados directamente a usuarios/grupos (no vía rol),
				a nivel base (class = 0), objeto (class = 1 → tabla, vista, proc) o esquema (class = 3),
				con el nombre del objeto (DB, tabla, esquema).
				Esto te dice, por base, qué permisos directos tiene cada usuario/grupo.

				3) Roles a nivel servidor
				Después del bloque dinámico por bases, agrega la parte de servidor.
				3.1 Membresía de roles de servidor
				FROM sys.server_role_members rm
				JOIN sys.server_principals role_principal
				JOIN sys.server_principals member_principal
				Inserta filas con:
				DatabaseName = '(SERVER_LEVEL)' como marcador,
				quién es miembro de roles como sysadmin, securityadmin, etc.,
				marca AD / GGAUM / GGAUR.
				Esto te dice qué logins tienen roles de servidor, incluso si no tienen usuario en ninguna base.
				
				4) Permisos explícitos a nivel servidor
				FROM sys.server_permissions perm
				JOIN sys.server_principals sp
				LEFT JOIN sys.endpoints ep
				LEFT JOIN sys.server_principals sp2
				
				Inserta filas con:
				permisos GRANT/DENY a nivel servidor,
				tipo de permiso (CONTROL SERVER, VIEW ANY DATABASE, etc.),
				sobre qué objeto: SERVER, ENDPOINT o LOGIN.
				De nuevo, DatabaseName = '(SERVER_LEVEL)' marca que es permisos de servidor, no de base.



*/
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
IF OBJECT_ID('tempdb..#DB_Permissions') IS NOT NULL
    DROP TABLE #DB_Permissions;

CREATE TABLE #DB_Permissions
(
    InstanceName    sysname       NOT NULL,
    DatabaseName    sysname       NOT NULL,
    PrincipalName   sysname       NOT NULL,       -- Usuario o grupo dentro de la DB / servidor
    PrincipalType   nvarchar(60)  NOT NULL,       -- SQL_USER, WINDOWS_USER, WINDOWS_GROUP, SQL_LOGIN, etc.
    LoginName       sysname       NULL,           -- Login en el servidor (cuando aplica)
    LoginType       nvarchar(60)  NULL,           -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP, etc.
    IsADGroup       bit           NULL,           -- 1 = Grupo AD (WINDOWS_GROUP)
    IsGGAUM         bit           NULL,           -- 1 = GGAUM_DB-*
    IsGGAUR         bit           NULL,           -- 1 = GGAUR_DB-*
    RoleName        sysname       NULL,           -- Rol de DB o de servidor
    PermissionType  nvarchar(60)  NULL,           -- GRANT / DENY
    PermissionName  nvarchar(60)  NULL,           -- SELECT, INSERT, CONTROL SERVER, etc.
    ObjectType      nvarchar(60)  NULL,           -- DATABASE, OBJECT_OR_COLUMN, SERVER, ENDPOINT, etc.
    ObjectName      sysname       NULL            -- Nombre de objeto o DB
);

DECLARE @InstanceName sysname;
SET @InstanceName = CAST(SERVERPROPERTY('ServerName') AS sysname);

DECLARE @SQL nvarchar(MAX) = N'';

-------------------------------------------------------------------------------
-- 1) Generar dinámicamente el script para cada base de datos de usuario
-------------------------------------------------------------------------------
SELECT @SQL = @SQL + '
USE ' + QUOTENAME(name) + ';
------------------------------------------------------------
-- 1.1) Membresía de roles de base de datos
------------------------------------------------------------
INSERT INTO #DB_Permissions
(
    InstanceName,
    DatabaseName,
    PrincipalName,
    PrincipalType,
    LoginName,
    LoginType,
    IsADGroup,
    IsGGAUM,
    IsGGAUR,
    RoleName,
    PermissionType,
    PermissionName,
    ObjectType,
    ObjectName
)
SELECT
    @InstanceName                         AS InstanceName,
    DB_NAME()                             AS DatabaseName,
    member_principal.name                 AS PrincipalName,
    member_principal.type_desc            AS PrincipalType,
    sp.name                               AS LoginName,
    sp.type_desc                          AS LoginType,
    CASE WHEN sp.type_desc = ''WINDOWS_GROUP'' THEN 1 ELSE 0 END AS IsADGroup,
    CASE WHEN member_principal.name LIKE ''GGAUM_DB-%'' THEN 1 ELSE 0 END AS IsGGAUM,
    CASE WHEN member_principal.name LIKE ''GGAUR_DB-%'' THEN 1 ELSE 0 END AS IsGGAUR,
    role_principal.name                   AS RoleName,
    NULL                                  AS PermissionType,
    NULL                                  AS PermissionName,
    NULL                                  AS ObjectType,
    NULL                                  AS ObjectName
FROM sys.database_role_members drm
JOIN sys.database_principals role_principal
    ON drm.role_principal_id = role_principal.principal_id
JOIN sys.database_principals member_principal
    ON drm.member_principal_id = member_principal.principal_id
LEFT JOIN master.sys.server_principals sp
    ON member_principal.sid = sp.sid
WHERE role_principal.type = ''R''      -- Solo roles
  AND member_principal.type IN (''S'',''U'',''G''); -- SQL_USER, WINDOWS_USER, WINDOWS_GROUP

------------------------------------------------------------
-- 1.2) Permisos explícitos a nivel DB / objeto
------------------------------------------------------------
INSERT INTO #DB_Permissions
(
    InstanceName,
    DatabaseName,
    PrincipalName,
    PrincipalType,
    LoginName,
    LoginType,
    IsADGroup,
    IsGGAUM,
    IsGGAUR,
    RoleName,
    PermissionType,
    PermissionName,
    ObjectType,
    ObjectName
)
SELECT
    @InstanceName                           AS InstanceName,
    DB_NAME()                               AS DatabaseName,
    dp.name                                 AS PrincipalName,
    dp.type_desc                            AS PrincipalType,
    sp.name                                 AS LoginName,
    sp.type_desc                            AS LoginType,
    CASE WHEN sp.type_desc = ''WINDOWS_GROUP'' THEN 1 ELSE 0 END AS IsADGroup,
    CASE WHEN dp.name LIKE ''GGAUM_DB-%'' THEN 1 ELSE 0 END AS IsGGAUM,
    CASE WHEN dp.name LIKE ''GGAUR_DB-%'' THEN 1 ELSE 0 END AS IsGGAUR,
    NULL                                    AS RoleName,
    perm.state_desc                         AS PermissionType,
    perm.permission_name                    AS PermissionName,
    perm.class_desc                         AS ObjectType,
    CASE 
        WHEN perm.class = 0 THEN DB_NAME()
        WHEN perm.class = 1 THEN OBJECT_NAME(perm.major_id)
        WHEN perm.class = 3 THEN s.name
        ELSE NULL
    END                                      AS ObjectName
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN master.sys.server_principals sp
    ON dp.sid = sp.sid
LEFT JOIN sys.schemas s
    ON perm.class = 3 AND perm.major_id = s.schema_id
WHERE dp.type IN (''S'',''U'',''G''); -- SQL_USER, WINDOWS_USER, WINDOWS_GROUP
'
FROM sys.databases
WHERE database_id > 4            -- Excluye master, model, msdb, tempdb
  AND state = 0;                 -- Solo bases ONLINE

-------------------------------------------------------------------------------
-- Ejecutar el bloque dinámico por base de datos
-------------------------------------------------------------------------------
EXEC sys.sp_executesql
    @SQL,
    N'@InstanceName sysname',
    @InstanceName = @InstanceName;

-------------------------------------------------------------------------------
-- 2) ROLES A NIVEL SERVIDOR (sysadmin, securityadmin, etc.)
-------------------------------------------------------------------------------
INSERT INTO #DB_Permissions
(
    InstanceName,
    DatabaseName,
    PrincipalName,
    PrincipalType,
    LoginName,
    LoginType,
    IsADGroup,
    IsGGAUM,
    IsGGAUR,
    RoleName,
    PermissionType,
    PermissionName,
    ObjectType,
    ObjectName
)
SELECT
    @InstanceName                           AS InstanceName,
    N'(SERVER_LEVEL)'                       AS DatabaseName,   -- marcador nivel servidor
    member_principal.name                   AS PrincipalName,
    member_principal.type_desc              AS PrincipalType,  -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
    member_principal.name                   AS LoginName,
    member_principal.type_desc              AS LoginType,
    CASE WHEN member_principal.type_desc = 'WINDOWS_GROUP' THEN 1 ELSE 0 END AS IsADGroup,
    CASE WHEN member_principal.name LIKE 'GGAUM_DB-%' THEN 1 ELSE 0 END AS IsGGAUM,
    CASE WHEN member_principal.name LIKE 'GGAUR_DB-%' THEN 1 ELSE 0 END AS IsGGAUR,
    role_principal.name                     AS RoleName,       -- sysadmin, securityadmin, etc.
    NULL                                    AS PermissionType,
    NULL                                    AS PermissionName,
    N'SERVER_ROLE'                          AS ObjectType,
    NULL                                    AS ObjectName
FROM sys.server_role_members rm
JOIN sys.server_principals role_principal
    ON rm.role_principal_id = role_principal.principal_id
JOIN sys.server_principals member_principal
    ON rm.member_principal_id = member_principal.principal_id
WHERE role_principal.type = 'R'                 -- roles de servidor
  AND member_principal.type IN ('S','U','G');   -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP

-------------------------------------------------------------------------------
-- 3) PERMISOS EXPLÍCITOS A NIVEL SERVIDOR
-------------------------------------------------------------------------------
INSERT INTO #DB_Permissions
(
    InstanceName,
    DatabaseName,
    PrincipalName,
    PrincipalType,
    LoginName,
    LoginType,
    IsADGroup,
    IsGGAUM,
    IsGGAUR,
    RoleName,
    PermissionType,
    PermissionName,
    ObjectType,
    ObjectName
)
SELECT
    @InstanceName                           AS InstanceName,
    N'(SERVER_LEVEL)'                       AS DatabaseName,    -- marcador nivel servidor
    sp.name                                 AS PrincipalName,
    sp.type_desc                            AS PrincipalType,   -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP
    sp.name                                 AS LoginName,
    sp.type_desc                            AS LoginType,
    CASE WHEN sp.type_desc = 'WINDOWS_GROUP' THEN 1 ELSE 0 END AS IsADGroup,
    CASE WHEN sp.name LIKE 'GGAUM_DB-%' THEN 1 ELSE 0 END AS IsGGAUM,
    CASE WHEN sp.name LIKE 'GGAUR_DB-%' THEN 1 ELSE 0 END AS IsGGAUR,
    NULL                                    AS RoleName,
    perm.state_desc                         AS PermissionType,   -- GRANT / DENY
    perm.permission_name                    AS PermissionName,   -- CONTROL SERVER, VIEW ANY DATABASE, etc.
    perm.class_desc                         AS ObjectType,       -- SERVER, ENDPOINT, LOGIN, etc.
    CASE 
        WHEN perm.class_desc = 'SERVER'   THEN N'(SERVER)'
        WHEN perm.class_desc = 'ENDPOINT' THEN ep.name
        WHEN perm.class_desc = 'LOGIN'    THEN sp2.name
        ELSE NULL
    END                                      AS ObjectName
FROM sys.server_permissions perm
JOIN sys.server_principals sp
    ON perm.grantee_principal_id = sp.principal_id
LEFT JOIN sys.endpoints ep
    ON perm.class_desc = 'ENDPOINT'
   AND perm.major_id = ep.endpoint_id
LEFT JOIN sys.server_principals sp2
    ON perm.class_desc = 'LOGIN'
   AND perm.major_id = sp2.principal_id
WHERE sp.type IN ('S','U','G'); -- SQL_LOGIN, WINDOWS_LOGIN, WINDOWS_GROUP

-------------------------------------------------------------------------------
-- 4) Resultado final ordenado
-------------------------------------------------------------------------------
SELECT
    InstanceName,
    DatabaseName,
    PrincipalName,
    PrincipalType,
    LoginName,
    LoginType,
    IsADGroup,
    IsGGAUM,
    IsGGAUR,
    RoleName,
    PermissionType,
    PermissionName,
    ObjectType,
    ObjectName
FROM #DB_Permissions
ORDER BY
    InstanceName,
    DatabaseName,
    PrincipalName,
    RoleName,
    PermissionName,
    ObjectType,
    ObjectName;
