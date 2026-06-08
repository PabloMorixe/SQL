-----------------------------------------------------
--CONFIGURACION DE SQL SERVER AUDIT (SQL Server 2008)
-----------------------------------------------------


--CREAR UN SERVER AUDIT
-----------------------
USE [master]

GO

CREATE SERVER AUDIT [AUDIT_TEST]
TO FILE 
(	FILEPATH = N'D:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA'
	,MAXSIZE = 10 MB
	,MAX_ROLLOVER_FILES = 20
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 10000
	,ON_FAILURE = CONTINUE
)

GO




--CREAR UN SERVER AUDIT SPECIFICATION
-------------------------------------
USE [master]

GO

CREATE SERVER AUDIT SPECIFICATION [AUDIT_TEST_SPEC]
FOR SERVER AUDIT [AUDIT_TEST]
ADD (FAILED_LOGIN_GROUP),
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (AUDIT_CHANGE_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (SERVER_STATE_CHANGE_GROUP),
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
ADD (SERVER_PERMISSION_CHANGE_GROUP),
ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP)

GO





--HABILITAR EL SERVER AUDIT
---------------------------
ALTER SERVER AUDIT AUDIT_TEST
WITH (STATE = ON)




--HABILITAR EL SERVER AUDIT SPECIFICATION
-----------------------------------------
ALTER SERVER AUDIT SPECIFICATION AUDIT_TEST_SPEC
WITH (STATE = ON)





--LEER UN ARCHIVO DE AUDITORIA
------------------------------
SELECT *
FROM fn_get_audit_file(
'D:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\AUDIT_TEST_978D024C-6F81-4A48-A1DA-057BB2FB0850_0_129337846650730000.sqlaudit',
default, default
)
WHERE server_principal_name = 'CENTRAL\GHAKIMIAN'





--LEER TODOS LOS ARCHIVOS DE AUDITORIA DE UNA CARPETA
-----------------------------------------------------
SELECT *
FROM fn_get_audit_file(
'D:\Program Files\Microsoft SQL Server\MSSQL10.MSSQLSERVER\MSSQL\DATA\*',
default, default
)
WHERE server_principal_name = 'CENTRAL\GHAKIMIAN'




--EJEMPLO CAMBIOS SOBRE UN OBJETO
-----------------------------------------
SELECT event_time, server_principal_name, database_name, schema_name, object_name, statement
FROM fn_get_audit_file(
'E:\SQLAUDIT\AUDIT_IGSQL04\ARCHIVADOS\*',
default, default
) AS A
WHERE  A.database_name = 'SPCP' AND A.object_name = 'ANALISIS_PAPEL'
ORDER BY event_time DESC