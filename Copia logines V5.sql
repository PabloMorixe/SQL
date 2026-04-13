
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
sp_configure 
EXEC sp_configure 'ad hoc distributed queries', 1
RECONFIGURE
GO

--PENDIENTE: chequear si esta corriendo el SP 
-- =============================================
-- Author:		Pablo Morixe
-- Create date: 20 enero 2022
-- Description: SP	Genera logines  en hexa
-- FINALIZADO OK
-- =============================================
IF OBJECT_ID(N'dbo.sp_GeneraLoginenHexa', N'P') IS NOT NULL  
   DROP procedure [dbo].[sp_GeneraLoginenHexa];  
GO
alter PROCEDURE [dbo].[sp_GeneraLoginenHexa]
	  AS
BEGIN
SET NOCOUNT ON

IF OBJECT_ID(N'dbo.LoginesExistentes', N'U') IS NOT NULL  DROP TABLE [dbo].[LoginesExistentes];  

CREATE TABLE [dbo].[LoginesExistentes](	[creacion] [nvarchar](1000) NULL) ON [PRIMARY]


SELECT N'CREATE LOGIN ['+sp.[name]+'] WITH PASSWORD=0x'+
    CONVERT(nvarchar(max), l.password_hash, 2)+N' HASHED, '+
    N'SID=0x'+CONVERT(nvarchar(max), sp.[sid], 2)+N';'
FROM master.sys.server_principals AS sp
INNER JOIN master.sys.sql_logins AS l ON sp.[sid]=l.[sid]
where l.principal_id > 288 --PENDIENTE VER SEGMENTO DE LOGINES: 
/*
where l.principal_id >  1 
and l.name not in (
'##MS_PolicyTsqlExecutionLogin##'
,'##MS_PolicyEventProcessingLogin##'
,'scriptexec'
,'usrSOTP'
,'usrSOTPdta'
)
*/
end
GO
--select * from master.sys.sql_logins

-- =============================================
-- Author:		Pablo Morixe
-- Create date: 20 enero 2022
-- Description:	Guarda logines que faltan en la instancia.
-- =============================================


IF OBJECT_ID(N'dbo.LoginesXCrear', N'U') IS NOT NULL DROP TABLE [dbo].[LoginesXCrear];  
GO
CREATE TABLE [dbo].[LoginesXCrear](	[creacion] [nvarchar](1000) NULL) ON [PRIMARY]
GO

--CARGO LOGINES EXISTENTES EN TABLA de la instancia local
INSERT INTO [dbo].[LoginesExistentes] 
Exec [sp_GeneraLoginenHexa] 
go
select * from [LoginesExistentes]


--CARGO LOGINES EXISTENTES EN TABLA de las instancias remotas.
--PENDIENTE: FALTA CURSOR DE INSTANCIAS. 

select a.* from openrowset('SQLNCLI', 'Server=sslabveeam-51;Trusted_Connection=yes;','SET NOCOUNT ON; INSERT INTO master.[dbo].[LoginesExistentes] 
Exec sp_GeneraLoginenHexa; SELECT * FROM MASTER.DBO.LoginesExistentes
') as a

reemplaza lo de arriba
------------------------------------------------------
-- cargo tablas de logines existentes en los otros nodos. 
DECLARE @BuscarInstancias nVARCHAR(max) 
declare @secundario nvarchar(50)

DECLARE Instancia CURSOR FOR 
SELECT replica_server_name 
FROM MASTER.sys.availability_replicas 
WHERE replica_server_name <> (select @@SERVERNAME)

OPEN Instancia  
FETCH NEXT FROM Instancia INTO @BuscarInstancias  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    
	 set @secundario = @BuscarInstancias
	 print @secundario
	 
	 
DECLARE  @cmd1 nVARCHAR(max) 
declare @secundario nvarchar(50)
set @secundario = 'sslabveeam-51'

set @cmd1 = 'select a.* from openrowset(''SQLNCLI'', ''Server='+@secundario+'
;Trusted_Connection=yes;''SET NOCOUNT ON; INSERT INTO master.[dbo].[LoginesExistentes] 
Exec sp_GeneraLoginenHexa; SELECT * FROM MASTER.DBO.LoginesExistentes
'') as a'

print @cmd1 



/**/
select a.* from openrowset('SQLNCLI', 'Server=sslabveeam-51;Trusted_Connection=yes;','SET NOCOUNT ON; INSERT INTO master.[dbo].[LoginesExistentes] 
Exec sp_GeneraLoginenHexa; SELECT * FROM MASTER.DBO.LoginesExistentes
') as a

select a.* from openrowset('SQLNCLI', Server=sslabveeam-51;Trusted_Connection=yes;'SET NOCOUNT ON; INSERT INTO master.[dbo].[LoginesExistentes] 
Exec sp_GeneraLoginenHexa; SELECT * FROM MASTER.DBO.LoginesExistentes
') as a




			--declare @secundario nvarchar(50)
			declare @cmd nvarchar(max)
			--	 set @secundario = 'sslabveeam-51'
				-- print @secundario 
				-- pENDIENTE: REEMPLAZAR POR OPENROWSET. 
				 set @cmd = '
			insert into [LoginesXCrear] 
			select b.* from master.dbo.LoginesExistentes a
			full outer join ['+@secundario+'].master.dbo.LoginesExistentes b
			on a.creacion = b.creacion 
			where a.creacion IS NULL  or
			b.creacion  IS NULL
			delete  from [LoginesXCrear] where creacion is NULL
			select * from [LoginesXCrear] '
			--print @cmd
			execute (@cmd)

      FETCH NEXT FROM Instancia INTO @BuscarInstancias 
END 

CLOSE Instancia  
DEALLOCATE Instancia 
------------------------------------------------------

-- select * from [LoginesExistentes]

--COMPARO LOS LOGINES QUE EXISTEN EN LOS NODOS SECUNDARIOS CONTRA EL ACTUAL, 
--Y DEJO LOS EXISTENTES EN LOS OTROS CARGADOS EN UNA TABLA LoginesXCrear
DECLARE @BuscarInstancias nVARCHAR(max) 
declare @secundario nvarchar(50)

DECLARE Instancia CURSOR FOR 
SELECT replica_server_name 
FROM MASTER.sys.availability_replicas 
WHERE replica_server_name <> (select @@SERVERNAME)

OPEN Instancia  
FETCH NEXT FROM Instancia INTO @BuscarInstancias  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    
	 set @secundario = @BuscarInstancias
	 print @secundario
	 
			--declare @secundario nvarchar(50)
			declare @cmd nvarchar(max)
			--	 set @secundario = 'sslabveeam-51'
				-- print @secundario 
				-- pENDIENTE: REEMPLAZAR POR OPENROWSET. 
				 set @cmd = '
			insert into [LoginesXCrear] 
			select b.* from master.dbo.LoginesExistentes a
			full outer join ['+@secundario+'].master.dbo.LoginesExistentes b
			on a.creacion = b.creacion 
			where a.creacion IS NULL  or
			b.creacion  IS NULL
			delete  from [LoginesXCrear] where creacion is NULL
			select * from [LoginesXCrear] '
			--print @cmd
			execute (@cmd)

      FETCH NEXT FROM Instancia INTO @BuscarInstancias 
END 

CLOSE Instancia  
DEALLOCATE Instancia 


/*
funciona joya
insert into [LoginesXCrear] 
select b.* from master.dbo.LoginesExistentes a
full outer join [sslabveeam-51].master.dbo.LoginesExistentes b
on a.creacion = b.creacion 
where a.creacion IS NULL  or
b.creacion  IS NULL
delete  from [LoginesXCrear] where creacion is NULL
select * from [LoginesXCrear] 
*/



-- =============================================
-- Author:		Pablo Morixe
-- Create date: 20 enero 2022
-- Description:	Ejecuta la creacion de los logines que haya en la tabla LoginesXCrear
-- =============================================

DECLARE @CrearLogin nVARCHAR(max) 

DECLARE logines CURSOR FOR 
select creacion
from [LoginesXCrear] 

OPEN logines  
FETCH NEXT FROM logines INTO @CrearLogin  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    
exec (@CrearLogin)

      FETCH NEXT FROM logines INTO @CrearLogin 
END 

CLOSE logines  
DEALLOCATE logines 

--

