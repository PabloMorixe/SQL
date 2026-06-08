--CONSULTAR LINKED SERVERS A PARTIR DE UN LOGIN
SELECT S.name, remote_name, data_source, catalog, SP.name, SP.type_desc
FROM sys.linked_logins LL
INNER JOIN sys.servers S
ON LL.server_id = S.server_id
INNER JOIN sys.server_principals SP
ON LL.local_principal_id = SP.principal_id
