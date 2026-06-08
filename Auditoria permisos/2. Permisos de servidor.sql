SELECT SP.name, P.*
FROM SYS.server_permissions P
INNER JOIN SYS.server_principals SP
ON P.grantee_principal_id = SP.principal_id