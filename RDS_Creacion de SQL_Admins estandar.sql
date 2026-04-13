/*Creacion del usuario SQL Admins*/
/*###############################*/

create login [gscorp\SQL_admins] from windows with default_database=[master],default_language=[us_english];
GO

/*Creacion de permisos a nivel de ROL-SERVER*/
/*##########################################*/

ALTER SERVER ROLE [processadmin] ADD MEMBER [gscorp\SQL_admins]
GO
ALTER SERVER ROLE [setupadmin] ADD MEMBER [gscorp\SQL_admins]
GO


/*Asignacion de Permisos estandar a nivel de instancia*/
/*####################################################*/

use [master]
GO
GRANT ADMINISTER BULK OPERATIONS TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY CONNECTION TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY CREDENTIAL TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY EVENT SESSION TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY LINKED SERVER TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY LOGIN TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY SERVER AUDIT TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER ANY SERVER ROLE TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER SERVER STATE TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT ALTER TRACE TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT CREATE ANY DATABASE TO [gscorp\SQL_admins]
GO
use [master]
GO
use [master]
GO
GRANT VIEW ANY DATABASE TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT VIEW ANY DEFINITION TO [gscorp\SQL_admins]
GO
use [master]
GO
GRANT VIEW SERVER STATE TO [gscorp\SQL_admins]
GO

/*Asignacion de permisos a las base de sistema*/
/*############################################*/

USE [msdb]
GO
CREATE USER [gscorp\SQL_admins] FOR LOGIN [gscorp\SQL_admins]
GO
ALTER ROLE [SQLAgentUserRole] ADD MEMBER [gscorp\SQL_admins]
GO
USE [tempdb]
GO
CREATE USER [gscorp\SQL_admins] FOR LOGIN [gscorp\SQL_admins]
GO

--AL RESTO DE LAS BASE DE DATOS DE USUARIO, DEBEMOS DARLE DB_OWNER AL LOGIN SQL_ADMINS