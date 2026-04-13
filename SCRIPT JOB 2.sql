	sp_who2 active

		--Estado de la sesión. Valores posibles:
                              --Running: está ejecutando una o varias solicitudes actualmente

                              --Sleeping: no está ejecutando solicitudes actualmente

                              --Dormant:la sesión se ha restablecido debido a que la agrupación de conexiones está ahora                                       -- en estado previo al inicio de sesión.

	kill 55
      --kill 150 with statusonly --si da 0 no esta haciendo nada
                                   ojo en el Proa02 utilizan BCp.exe para matar el proceso de tarjetas hay q ingresar al                                         servidor y matar el proceso

	select 'kill ' + cast(spid as varchar(3)) from master..sysprocesses
	where loginame='backupsan' --realiza la conversion porque spid es smallint y p unirlo a kill tiene q ser literal

	dbcc inputbuffer (42)

	sp_lock -- para ver q proceso que esta bloqueado muestra información acerca de 
                   todos los bloqueos mantenidos en una instancia 

	sp_blocked
		--sp del hsbc que se bloqueo TIPOS DE BLOQUEOS
******************************************************************************************

------------------------------------------------
Problemas de performances



 Se debe de analizar el query con el plan de ejecucion , luego boton derecho MANAGE INDEX

sp_updatestats


Para saber el nombre del programa


	SELECT     *
		FROM         sysprocesses
		WHERE     (spid = 84)

Para reindezar

	DBCC DBREINDEX('Customers','PK_Customers')
• 	DBCC DBREINDEX('Customers','',100)


Problemas con le BCP 

	EJ : Proceso de BCP colgado en el servidor PROA02

	HAY que ver en el servidor si esta corriendo el proceso BCP.EXE

	Si es asi hay que hacerle un kill
***************************************************************************************
PARA SABER QUIEN MATA LOS PROCESOS

nbtstat -a l0326zd72027f1a
           hostname 


***************************************************************************************

Para LIBERAR espacio de logs en la base de datos (dump = volcado)

	dump transaction database_name with no_log
	dump transaction comisionesmax with truncate_only
	checkpoint

	dbcc freeproccache: libera las tablas actualmente usadas y sus buffers Use DBCC 
                             FREEPROCCACHE to clear the procedure cache. Freeing the procedure cache would cause, 
	                     for example, an ad-hoc SQL statement to be recompiled rather than reused from the 	cache.

	DBCC DROPCLEANBUFFERS (to test queries with a cold buffer cache without shutting 	                                                             down and restarting the server.)

        Borra y despeja las tablas no usadas en memoria y realiza de nuevo la planificacion.
	equivalente a bajar y subir sql server.

        ---------------------
	dbcc freeproccache
	DBCC DROPCLEANBUFFERS

DBCC SHRINKDATABASE (AdventureWorks, TRUNCATEONLY)
 
DBCC SHRINKFILE (MiBase_Log, 3000)
 
1-      USE MiBase
2-      CHECKPOINT
3-      EXEC sp_addumpdevice 'disk', 'CopiaMiBase', 'd:\LogMiBase.bak'
4-      BACKUP DATABASE MiBase TO CopiaMiBase
5-      BACKUP LOG MiBase WITH TRUNCATE_ONLY
6-      DBCC SHRINKFILE (MiBase_Log, 100)
 
DUMP TRANSACTION nombre BD WITH TRUNCATE_ONLY 


*****************************************************************************************

Para ver el tAMAÑO de las TABLA
-------------------------------
	select * from sysindexes order by rows desc

	select * from sysobjects where id=1598628738

sp_spaceused

 Para saber el nombre del programa
 ---------------------------------

	SELECT     *
		FROM         sysprocesses
		WHERE     (spid = 84)

 Para probar los puertos de los svr SQL
 --------------------------------------
	telnet ip 1433

 Para ver las tablas de un usuario
 ---------------------------------
	sp_tables @table_owner='dbo'

 Para crear una tabla
 --------------------

	create table NOMBRETABLA(
  NOMBRECAMPO1 TIPODEDATO,
  ...
  NOMBRECAMPON TIPODEDATO);

	if object_id('usuarios') is not null
  	drop table usuarios;
ejemplo de foreing key

create table ejemplo
(part_nmbr int primary key,
part_seg_nombre char (30),
part_apellido char (30))

create table ejemplo_b
(order_nmbr int,
part_nmbr int foreign key references ejemplo(part_nmbr)
on delete no action,--no borra cascade borraria todo
part_seg_nombre char (30),
part_apellido char (30))

 Para ver la estructura de una tabla
 -----------------------------------

	sp_columns nombre_de_la_base;

---------------------------------------------------------------------------------
Para borrar un archivo de bd y mandar la informacion de el archivo 2 al archivo 1
*********************************************************************************


DBCC SHRINKFILE (BEHBKP001_1_Data,EMPTYFILE)


ALTER DATABASE behbkp001 
REMOVE FILE BEHBKP001_1_Data


****************************************************************************************

Para arregla bases de datos sospechosas
---------------------------------------

	hay que ir a la master y cambiar el esta a 28 

	SELECT     status, *
                            FROM         sysdatabases

solucion
	update sysdatabases set status = 28 where name = 'nombre de base'
	

****************************************************************************************
Para ver errores en Sql (registro de errores de SQL Server)


	select name, dbid, mode, status from sysdatabases where dbid = db_id('msdb')

****************************************************************************************

Para abrir el MONITOR

	perfmon.msc
	
	PerfMon.exe

	/*RID = Bloqueo en una única fila de una tabla identificada por un identificador de 	fila (RID).
	KEY = Bloqueo en un índice que protege un intervalo de claves en transacciones 	serializables.
	PAG = Bloqueo en una página de datos o de índices.
	EXT = Bloqueo en una extensión.
	TAB = Bloqueo en toda una tabla, incluidos todos los datos y los índices.
	DB = Bloqueo en una base de datos.
	FIL = Bloqueo en un archivo de base de datos.
	APP = Bloqueo en un recurso especificado por la aplicación.
	MD = Bloqueos de metadatos o información de catálogo.
	HBT = Bloqueo en un índice de montón o de árbol b. Esta información está incompleta 	en SQL Server 2005.
	AU = Bloqueo en una unidad de asignación. Esta información está incompleta en SQL 	Server 2005.
	*/
Seleccionar contador del equipo
	\\NTFSDB05
OBJETO DE RENDIMIENTO
	PHYSICALDISK
		CURRENT DISK QUEUE LENGTH


***************************************************************************************

Para ver los triggers que hay en una tabla
------------------------------------------

		select * from sysobjects
	where xtype = 'tr'

Para habilitar o deshabilitar triggers
--------------------------------------

	alter table nombre_de_tabla 
	| { ENABLE | DISABLE } TRIGGER 
        	{ ALL | trigger_name [ ,...n ] } 

ej
	ALTER TABLE nombre_de_tabla ENABLE TRIGGER nombre_de_trigger

	ALTER TABLE trig_example DISABLE TRIGGER trig1

Para crear un TRIGGER
***********************
ej:
	create table mi_tabla
	(a int null,
	b int null)

	create trigger mi_des
	on mi_tabla
	for insert
	as
	if update(b)
	print 'La columna b fue modificada'
	go

	insert mi_tabla (a, b)
	values ( 1, 2)

****************************************************************************************
BEGIN Y COMMIT TRANSACTION

EJ

	declare @trans varchar(20)

	select @trans = 'MiTransaccion'

	begin transaction @trans
	go
	use pubs
	go
	update mi_tabla
	set a = a + 3
	go

	commit transaction mitransaccion

	select * from mi_tabla

*************************************************
Aca veo los nombres de las bases de datos
-----------------------------------------

	select * from sysdatabases

Aca podes ver el nombre del archivo y donde esta ubicado
--------------------------------------------------------

	select 'select * from ' + name+'..sysfiles' from sysdatabases

****************************************************************************************

si hay problemas con los USUARIOS ej sysusers hay que dar 
---------------------------------------------------------
	grant update to el usuario
        grant insert,update on sysusers to [hlah\NTDB08_DBMUSERS_DBO]

        deny insert,update on sysusers to [hlah\NTDB08_DBMUSERS_DBO]

	CORRER script que me paso Natalia

Para ver los usuarios

	sp_helpuser

	
Para saber sobre que OBJETOS tiene permisos un usuario
------------------------------------------------------


	exec sp_helprotect @username =   'SIS_AUTOSERVPOR'
	exec sp_helprotect @username = 'SIS_sicodoc'

  Como se deben de dar permisos

GRANT SELECT, INSERT, DELETE, UPDATE  ON Operadores TO sis_banca--usuario

****************************************************************************************

Para buscar los logins
----------------------

	sp_helplogins

	select name from master..syslogins


****************************************************************************************

-----------------------------------------------------------------------------------------------------------------------
	POLITICAS SQL SERVER
******************************************
ej:
Gabriel:
	Logramos dar de alta el (art148vwncdb) , debido en parte a unas restricciones halladas en la local policy  de la account "dmmxctl\sqlserver".  Al darlas de alta en la cuenta, pudimos resetear la misma y asignarla correctamente con el xp_cmdshell.
	Habría que resetear el usuario proxy

        ***********************************************************  
	La cuenta debería tener los siguientes POLITICAS activadas:
        ***********************************************************     

• Act as Part of the Operating System = SeTcbPrivilege 
• Bypass Traverse Checking = SeChangeNotify 
• Lock Pages In Memory = SeLockMemory 
• Log on as a Batch Job = SeBatchLogonRight 
• Log on as a Service = SeServiceLogonRight 
• Replace a Process Level Token = SeAssignPrimaryTokenPrivilege 

------------------------------------------------------------------------------------------------------------------------

Para registrar un exe
----------------------

 regserver nombre.exe

para registrar una dll
----------------------
	REGSVR32 c:\windows\system\Dao350.dll 

		Los parámetros opcionales [/u] [/s] significan lo siguiente: 

		[/u] - lo utilizamos cuando queremos "desregistrar" una DLL (o un .ocx en 	vez de 	registrarlo). 

		[/s] - modo "silencioso" - no despliega los mensajes durante la operación. 



*****************************************************************************************

Para verificar las Bases de Datos
----------------------------------
 	exec sp_helpdb nombre_base

verificar si no estan en estado sospechoso
	DBCC CHECKDB ('GESPREV',REPAIR_REBUILD)WITH ALL_ERRORMSGS

	DBCC CHECKDB ('GESPREV', repair_allow_data_loss) WITH ALL_ERRORMSGS

DBCC CHECKDB 
    ( 'database_name' 
            [ , NOINDEX 
                | { REPAIR_ALLOW_DATA_LOSS 
                    | REPAIR_FAST 
                    | REPAIR_REBUILD 
                    } ] 
    )    [ WITH { [ ALL_ERRORMSGS ] 
                    [ , [ NO_INFOMSGS ] ] 
                    [ , [ TABLOCK ] ] 
                    [ , [ ESTIMATEONLY ] ] 
                    [ , [ PHYSICAL_ONLY ] ] 
                    } 
        ] 

****************************************************************************************

Para saber el ultimo backup de una base de datos
------------------------------------------------
	select type,database_name, max(backup_finish_date)last_backup 
	from msdb..backupset 
	where type = 'I' and database_name = 'AGP' GROUP BY type,database_name

****************************************************************************************

Para sacar los nombres de las bases de datos
--------------------------------------------
	select name from master..sysdatabases

Para sacar donde se estan guardando los backup de las bases (EL PATH)
-----------------------------------------------------------
	select name,filename from master..sysfiles
	'select ' + @name + ' name,filename from ' + @name + '..sysfiles'
****************************************************************************************

Como hacer un restore
 --------------------
	RESTORE DATABASE BENEFICIOS 

	FROM DISK = '\\ARD003FWNCDB\e$\BAKntfs4052\bak1'
        WITH MOVE 'BENEFICIOS_Data' TO 'k:\SQL2000\BENEFICIOS_Data.MDF',
        MOVE 'BENEFICIOS2_Data' TO 'k:\SQL2000\BENEFICIOS2_Data.ndf',
        MOVE 'BENEFICIOS1_Data' TO 'k:\SQL2000\BENEFICIOS1_Data.NDF',
        MOVE 'BENEFICIOS_Log' TO 'k:\SQL2000\BENEFICIOS_Log.LDF'

Ejemplo de backup
           ------
	(SE CORRE DENTRO DE LA MASTER)
	job backupmsdb en el FS1000145	

	BACKUP DATABASE [msdb] TO [BUMSDB] WITH  INIT ,  NOUNLOAD ,  NAME = N'backupmsdb ',
          NOSKIP ,  STATS = 10,  NOFORMAT 

posible path
	\\ARD003FWNCDB\d$\SQL2000\MSSQL\BACKUP


 SCRIPT DE BACKUP a disco
 ------------------------

ej: job Ntfb4065 "DBA: Backup Adintar Full"

Solapa general

  Step name: Backup Adintar
  Type     : Transact -SQL SCRIPT (TSQL)
  Database :master


	declare @fecha varchar(10)

	set @fecha=convert(varchar,getdate(),112) 

	exec('BACKUP DATABASE Adintar to disk = ''N:\Backup_Adintar\BUAdintar_f_' +  @fecha + '.bak'' WITH INIT')



BACKUP DATABASE [master] TO [BUMASTER] WITH  INIT ,  NOUNLOAD ,  NAME = N'master backup',  SKIP ,  STATS = 10,  NOFORMAT



***************************************************************************************


Problemas en las SUCURSALES se vinculan con el servidor FS1000126 BASE CFUcentral y en la sucursal CFU

                 ----------
	Verificar el funcionamiento de job: 'CFU: Transmisión SST a Sucursales' 
        Hay que verificar los siguentes jobs

	CFU: Chequeo Autoservicios

   			/*if (select count(*) from master..sysprocesses where sid =SUSER_SID('db2admin')) != 2 
	                 raiserror ('Error con CFU Autoservicios. Bajar y levantar el flujo CFU en el broker del servidor                          NTFSMQS01',19,127) WITH LOG,NOWAIT
                         */
                        if (select count(*) from master..sysprocesses where sid=SUSER_SID('SIS_CFU')
                        and program_name = '') != 2
                              --	raiserror ('prueba',19,127) WITH LOG,NOWAIT
	                raiserror ('Error con CFU Autoservicios. Bajar y levantar el flujo CFU en el broker del servidor                         arp005fuc2ap',19,127) WITH LOG,NOWAIT

	CFU: Transmisión SST a Sucursales-- este es el que pasa la informacion a las sucursales

	CFU: Corre Sql en CFU SucursalesHSBC -- para cargar scritps en las sucursales

	CFU: Corre Sql en CFU Sucursales --para cargar scritps en las sucursales


Re: ERROR EXESUC-CFU SUCURSAL MENDOZA
---------------------------------------
	use cfucentral
	GO
	select * from sucursal
	where Suc_Nombre = 'caballito'

	SELECT Moneda,* FROM TEMPCFU--SI FUNCIONA TIENE QUE SE T80 no 080
	WHERE Sucursal = 042
	ORDER BY Fecha


	Marcelo O. PEREYRA

	1) LAN SUPPORT deberá reiniciar el servicio BrisNt,  y borre la carpeta "COMPONENTS" 
        en la carpeta WDBIN.
        2) reinciar Brisnt.
        3) Volver a probar y avisarme para que yo lo vea desde aca.

Para ver el excel de las Sucursales MIRA EL FILES Configuración de Odbc - en mis documentos - script
                         **********  

\\fsbdc4050\lan$\Bases de Datos\Listado Sucursales\Listado_Sucursales_Integradas_Ene2007.xls

       **********************************************
       *clave KATA(N°DE SUCURSAL) KATA063 EJ ONCE   *
       *                                            *
       **********************************************

 
Direccion para conectarse a las Sucursales

	\\srmaster\SOFT\Radmin\batchs\RADsr.vbs

cuando aparece la pantalla de adminstrados precionar code y ingresar

Software:Remote Administrator 2.1

Serial: 
08US9A95I+lKa9nbOLXqv0V8xqdDvKGcNcTpN2wV11iSqOCVuA6A5KKZRHc5GVMIybWomK6rNwoj8mYy8LXRFi23




***************************************************************************************

Usuario Remoto Y Utilizacion del cmdshell
-----------------------------------------

Como correr un sp con un Usuario Remoto antes el usuario debe de estar dado de alta

	ej: si necesito un usuario remoto de 
	ard147vwncdb -128 al fs1000128 4066
        tareas a realizar :
	en el servidor  128 en Security/ remote del servidor 4066 y se marca solo rpc nada mas
       	en el servidor 4066 en Security/ remote se agrega el servers 128 hay que dar de alta el 
        usuario del svr 4066 marcando el rpc con check de clave luego se puede probar con el comando 
        EXECUTE FS1000128.MASTER.DBO.SP_WHO

SI NECESITO CORRER  xp_cmdshell se marca el usuario en este store
                      
SI SE NECESITA QUE UN USUARIO ACCEDA A OTRA BASES DE OTRO SERVIDOR HAY QUE IR A linked server en la solapa Security

Para dar el permiso de ejecucion de xp_cmdshell
---------------------------------------------------
         con mi usuario sa le doy el permiso

         grant EXECUTE on xp_cmdshell to UsuarioBdd SOBRE MASTER Y 
             
               DARLE PERMISOS DE EJECUCION AL USUARIOS SOBRE EL EXTENDED SP XP_CMDSHELL  
               INGESAR AL SERVIDOR Y VERIFICAR QUE EXISTA EL USUARIOS LOCAL SQLAGENTCMDEXEC POR LAS 
               DUDAS RESETEAR LA CLAVE CON LA MISMA QUE HAY EN EL EXCEL LUEGO en el SQLAGENT HAY QUE
               IR A PROPIEDADES Y VERIFICAR EN LA SOLAPA JOB SYSTEM Y RESETEAR LA CLAVE  

Para utilizar el Command Shell = cmdshell
---------------------------------------------------  
	 Crea un shell de comandos de Windows y lo pasa a una cadena para ejecutarlo. Los
 	 resultados se devuelven como filas de texto.

 EXEC xp_cmdshell 'dir *.exe';
GO

 Para verlo en un servidor que no tenes permisos, usá  con su SA en query analyzer:
------------------------------------------------------------------------------
  xp_cmdshell 'dir \\callweb\c$'	

  xp_cmdshell 'dir d:\SISTEMAS\Law2003\Dts\log\job003*.*'

Hacés type (comando sistema operativo)

  xp_cmdshell 'type d:\SISTEMAS\Law2003\Dts\log\job003.ReporteRespuestasProcesadas.log'


ejemplos 

exec xp_cmdshell 'set'--te dice COMO QUE USUARIO TE LOGEAS

exec xp_cmdshell 'DTSRun /V 55AE8CA8-D92B-43A8-AC2E-4468B19DD7C5 /E /N "DailyImportAdintar" /S'

exec master..xp_cmdshell 'osql -E -S sr0000030000071 -d bnl_homebank -Q "select * from Descod"'


CON AUTENTICACION DE CLAVE
 
	exec xp_cmdshell 'osql -E -S sr0000030000071 -d adintar -Q "SELECT count(*) from t_hbk_credit_cards"'

SIN AUTENTICACION DE CLAVE
	
   exec xp_cmdshell 'osql -U dba_el -P EZHSBC -S sr0000030000071 -d adintar -Q "SELECT count(*) from t_hbk_credit_cards"'

vER LA VERSION DEL DTS QN QUE VERSION DE SQL SE GRABO

	SELECT versionid,* FROM SYSDTSPACKAGES WHERE NAME='DailyImportAdintar'



***************************************************************************************

Para ver el SORT ORDER

	SP_HELPSORT

Como CAMBIAR la Collation

	SELECT COLLATIONPROPERTY('Latin1_General_CS_AI', 'codepage')

***************************************************************************************


Para realizar ESTADISTICAS y reindex de las bases ejemplo que Me paso Natalia
***************************************************************************************

	sp_updatestats

--REINDEX
declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(''' + user_name(o.uid) + '.'  + o.name + ''',' + i.name + ')' as ejecucion
	from 	sysindexes i inner join sysobjects o on i.id=o.id
	where o.xtype='U' and indid not in(0,255) 

open curDBIndex 

fetch next from curDBIndex into @ejecucion

while @@FETCH_STATUS=0
begin
	exec(@ejecucion)	
	fetch next from curDBIndex into @ejecucion
end

close curDBIndex
deallocate curDBIndex

--HELPSTATS
declare @name varchar(60)
declare cur_obj cursor for select name from sysobjects where xtype='U'
open cur_obj

fetch next from cur_obj into @name

while @@FETCH_STATUS=0
begin
	print @name
	exec('sp_helpstats ' + @name )
	fetch next from cur_obj into @name
end
close cur_obj
deallocate cur_obj

*****************************************

	Cambiar el nombre servidor de Sql 
*****************************************

	sp_helpserver -- esto te muestra los link remotos

        sp_dropserver arp0140vwncdb

        sp_addserver arp140vwncdb,local

select @@servername

*************************************

	Cambiar el nombre a una base
*************************************

	sp_renamedb  @dbname =  'old_name' ,  @newname =  'new_name'
********************************************************************************************
Configuracion de un ODBC
                    ----
*************************
	HERRAMIENTAS ADMINISTRATIVAS - ORIGENES DE DATOS (ODBC) - SOLAPA SYSTEM DSN - ADD
	SQL SERVER- NOMBRE DEL SERVIDOR - 


***********************************************************************************************************
Para sacar la Proyeccion de crecimiento de las bases 
	
		
      se tiene que correr un sp sp_evol_consumo_espacios_x_bd_x_mes bd , servidor -- esta en el ntfsdb4070

************************************************************************************************************
Para configurar un job para ejecutar DTS por nombre y no por id

DTSRun /E /N "xxxxx" /S

************************************************************************************************************
	
Ejemplo de como armar una fecha

insert into hsbc_usuarios_x_dia
select cant_user=count(distinct UL_USER),UL_DATE from SEC_USER_LOG(nolock) where
ul_date =  substring(convert(varchar(10),getdate(),112),1,4) + '/' + 
                substring(convert(varchar(10),getdate(),112),5,2) + '/' + 
                 substring(convert(varchar(10),getdate(),112),7,2) 
group by UL_DATE

************************************************************************************************************

Para Agregar un campo a un tabla

	ALTER TABLE NOVEDADINF ADD NOV_FEC_PRE INT NOT NULL DEFAULT 0

ALTER TABLE NOMBRETABLA 
{[ADD (COLUMNA [,COLUMNA]…)] 
[MODIFY (COLUMNA [,COLUMNA]…)] 
[ADD CONSTRAINT RESTRICCION] 
[DROP CONSTRAINT RESTRICCION]}; 
************************************************************************************************************

  BCP


**********************************************************************************************************

Transferir en formato TEXTO (separado por tabuladores -t\t):

OUT (de SQLServer a TXT)
exec master..xp_cmdshell 'bcp  "base..tabla" out "unidad:\destino.txt" -Udba_xx  -Pclave -Sservidor -c -t\t -r\n '

IN (de TXT a SQLServer)
exec master..xp_cmdshell 'bcp  "base..tabla" in  "unidad:\origen.txt"  -Udba_xx  -Pclave -Sservidor -c -e "unidad:\archivo_error.err" -t\t -r\n -b10000'


Transferir en formato BINARIO

OUT (de SQLServer a TXT)
bcp  "base..tabla" out "unidad:\destino.txt" -Udba_xx  -Pclave -Sservidor -n -e "unidad:\archivo_error.err"

IN (de TXT a SQLServer)
bcp  "base..tabla"  in "unidad:\origen.txt" -Udba_xx -Pclave -Sservidor -n -e "unidad:\archivo_error.err"

ejemplo
-------

Por favor, necesito que se ejecute el siguiente BCP en la base ADWRK del NTFS4065. 
Este bcp solo inserta datos en la nueva tabla que se esta creando, para poder analizar un incidente productivo de ADINTAR.

Create de la tabla temporal, donde debe volcarse el archivo adjunto

Archivo de formato (fmt) correspondiente al bcp.

Archivo de entrada para el bcp


xp_cmdshell bcp  "ADWRK..tmp_debitos_err_al_08042008" in "c:\BCP\Tc con debito y forma pago 2.txt" -Uxxxx -Pxxxx -SNTFS4065  -f "c:\BCP\tmp_debitos_err_al_08042008.fmt" -e "C:\BCP\CTR.err"

**********************************************************************************************************
Problemas con le BCP 

EJ : Proceso de BCP colgado en el servidor PROA02

HAY que ver en el servidor si esta corriendo el proceso BCP.EXE

Si es asi hay que hacerle un kill



***********************************************************************************************************

 Creacion de una funcion
-------------------------

 CREATE FUNCTION [ nombrePropietario. ] nombreFunción
 ( [ { @nombreParámetro tipoDatosParámetroEscalar [ = predeterminado ] } [
 ,...n ] ] )
 RETURNS tipoDatosDevoluciónEscalar
 [ WITH < opciónFunción > [,...n] ]
 [ AS ]
 BEGIN
 cuerpoFunción
 RETURN expresiónEscalar
 END

ejemplo:

USE Northwind
GO

CREATE FUNCTION PRUEBA
(@MIENTRADA nvarchar(30))

RETURNS nvarchar(30) --retorna el valor de la variable y La cláusula RETURNS especifica el tipo de datos

BEGIN                -- La función se define en un bloque BEGIN y END

IF @MIENTRADA IS NULL
SET @MIENTRADA = 'No HAY NADA'

RETURN @MIENTRADA -- 
END


SELECT LastName, City, dbo.prueba(Region) AS pepe,
Country
FROM dbo.Employees


resultado:

LastName             City            resultado                      Country         
-------------------- --------------- ------------------------------ --------------- 
Davolio              Seattle         WA                             USA
Fuller               Tacoma          WA                             USA
Leverling            Kirkland        WA                             USA
Peacock              Redmond         WA                             USA
Buchanan             London          No HAY NADA                    UK
Suyama               London          No HAY NADA                    UK
King                 London          No HAY NADA                    UK
Callahan             Seattle         WA                             USA
Dodsworth            London          No HAY NADA                    UK

*******************************************************************************************

Tablas de sistemas a consultar

	syslogins master    Contiene una fila por cada cuenta de inicio de
                            sesión que puede conectarse a SQL Server.
	sysmessages master  Contiene una fila por cada error o advertencia del
                            sistema que SQL Server puede devolver.
	sysdatabases master Contiene una fila por cada base de datos de un
                            servidor SQL Server.
	sysusers    Todas   Contiene una fila por cada usuario de Windows 2000,
                            grupo de Windows 2000, usuario de SQL Server o
                            función de SQL Server de una base de datos.
	sysobjects Todas    Contiene una fila por cada objeto de una base
                            de datos.
********************************************************************************************

Problema de SqlDumpExceptionHandler: Process 69 generated fatal exception c0000005 
	EXCEPTION_ACCESS_VIOLATION. SQL Server is terminating this process..

SP_SACLBA_OBTENERDELEGACION   : hay un link server SP_SACLBA

	
********************************************************************************************

Arreglo del dts
Convert

select CONVERT(varchar(255),'\\ARP008FWCnAP\ColdView-LogFiles\IndexerBackup\cvi_file_md_hist_'+Convert(varchar(14),GETDATE(),112)+'.txt')

********************************************************************************************
 SCRIPT DE BACKUP

BACKUP DATABASE [master] TO [BUMASTER] WITH  INIT ,  NOUNLOAD ,  NAME = N'master backup',  SKIP ,  STATS = 10,  NOFORMAT


*********************************************************************************************
Print

use siniestros
go
 
print '**********************************************'
print '               Generador Scripts'
print '               -----------------'
print ''
print 'Proyecto : 200803'
print 'Programa : Sql_Manager'
print 'Version  : 1.0.0'
print '**********************************************'
print ''
go

print ''
print '**********************************************'
print 'Comienza Generacion de SP a Implementar'
print '**********************************************'
go

print 'Alter sp_es_fam'
go

**********************************************************************************************

Server NTBKBR01
****************

	Error de concurrencia 
	This SQL Server has been optimized for 8 concurrent queries. This limit has been exceeded by 1 queries and         performance may be adversely affected.

*********************************************************************************************
select server,ambiente,tipo_de_backup,nombre_bd,count(*) from bkp
group by server,ambiente,tipo_de_backup,nombre_bd
having count(*) > 1


set rowcount 0  
begin tran
delete from bkp where server='ntfsdb01' and ambiente='p' and tipo_de_backup='full' and nombre_bd='INFORMACIONGERENCIAL'
commit

********************************************************************************************
error SP_SACLBA_OBTENERDELEGACION

*********************************************************************************************

Para restaurar la base de datos MASTER

REBUILDM.EXE

ojo hay que copiar este path \\fsbdc4050\soft$\Bases de Datos\SQLserver2000\x86\DATA

sqlservr.exe –c -m


declare @pepe sysname
declare @pepe2 sysname
set @pepe = 'd:\MSSQL2000\MSSQL\data\master.mdf'

print @pepe
print reverse(@pepe)
set @pepe2 = reverse(@pepe)
print reverse(left(@pepe2,charindex('\',@pepe2)-1))
********************************************
Sucursales

\\fsbdc4050\lan$\Bases de datos\Scripts SqlServer\Logines_cfucorhomaydba

********************************************
Script de Depuracion
----------------------

SET NOCOUNT ON
set rowcount 1000
declare @fechadesde varchar(14)
declare @r int
set @fechadesde = Convert(varchar(14),dateadd(m,-6,GETDATE()),111)

	begin
		set @r=1000
		while @r=1000
                  begin
		     delete from sec_user_log where ul_date< @fechadesde
	             set @r=@@ROWCOUNT                  
		     checkpoint                     
                  end
	end	
set rowcount 0
*********************************************
Para saber donde esta el SERVER

xp_cmdshell 'net config workstation'
*********************************************

job 

sp_send_smtp_mail 'alarmas@ledesma.com.ar', 'gscardino@ledesma.com.ar', 'Falla - Proceso BackUp Log OLAP (CLSQL05)', 'El DTS ''Backup Log OLAP - CLSQL05'' Finalizo con ERROR'


***************************************
maquina de Sebastian
\\10.1.1.68\scan


*****************************************************************************
antivirus
lo borra luego lo instala del \\ACNT09\vphome
file .xdb
F:\PUBLIC\cliente.sav\10.1\SAV

*****************************************************************************

Telefono Emmsa

Maria SOl 58611
	
*****************************************************************************

ADMINISTRACION DE cLUSTER IBM

http://10.1.201.50/

USERID
PASSW0RD

******************************************************************************
CLSQL05
	ACBL0501
	ACBL0502
		ACCL05
CLSQL04
	ACBL0401
	ACBL0402
		ACCL04

******************************************************************************
Info Util

Administración Central: allí se protegen los datos del mismo sitio y de los
	servidores de Depósito Alcorta, Depósito Retiro Norte, Sucursal Bahía Blanca,
	Sucursal Mendoza Azúcar, Sucursal Mendoza Papel, Sucursal Rosario y Sucursal
	Tucumán. En total, se respalda la información contenida en 42 recursos.
Glucovil: allí se protegen los datos del mismo sitio y del servidor de la Planta
	de Cuadernos y Repuestos. En total, se respalda la información contenida en 4
	recursos.
Ingenio: allí se protegen los datos del mismo sitio solamente. En total, se
	respalda la información contenida en 21 recursos.
	Cada uno de los tres servidores contiene una instalación de IBM Tivoli Storage
	Manager 5.2 configurado con las correspondientes políticas que citaremos más
	adelante y su correspondiente conexión al medio de almacenamiento definitivo
	que en todos los casos son las cintas magnéticas.
	Los agentes son los equipos a ser respaldados o backupeados. Los mismos

******************************************************************************

telefonos 4378-1555 int 1344 o 1343

*****************************************************************************

Dificultad con Levicom - ordenes de compra

 web: http://www.levicom.com.ar/ donde no tengo usuario

AVOCENT: https://10.1.201.10 / DONDE NO TENGO USUARIO

		Aca Sebastian entro y fue a ACNT05

		Aplicacion EdcTotal 5.7

		luego verifique en el svr CLSQL04 : la dts :bNexus_txt (la cual se ejecuta cada 30 minutos)

Paso a seguir segun Ricardo H.Nuñez Dpto. Sistemas int.: 1016

	Por favor fijate si el proceso EDC Total se esta ejecutando y la DTS esta funcionando
	porque me estan reclamando estas que te adjunto que son de ayer a las 6 de la tarde.

	Los pasos son los siguientes:
	1) si el EDC Total esta funcionando 
	2) Habira que ver si la DTS esta funcionando 
	3) Ver en el sitio si estas ordenes figuran leidas o NO, si estan leidas, avisame (yo no tengo internet)
	 y las reclamo a Levicom para que las desmarque.
	servidor CLSQL04  se ejecuta la DTS bnexus txt

********************************************************************************









