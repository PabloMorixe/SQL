sp_configure 'allow updates',1
go
reconfigure with override
go

update sysusers set sid=SUSER_SID(name) 
	where not SUSER_SID(name) is null

update sysusers set sid=SUSER_SID(SUBSTRING(name,2,255)) 
	where not SUSER_SID(SUBSTRING(name,2,255)) is null
	and (status & 16) != 0 and substring(name,1,1) = '\'

go

sp_configure 'allow updates',0
go
reconfigure with override
go


--EXEC sp_dropalias 'sis_rvpadminnyldbo'
--EXEC sp_addalias 'Victoria', 'DBO'

Para los usuarios de seguridad hay que aplicar los sp 
********************************************************
Actualmente, el grupo que corresponde al sector de Seguridad Informática es HLAH\IT_SEC_MSSQL.

En la master agregar los siguientes SCRIPTS:

\\fsbdc4050\lan$\Bases de Datos\Scripts SqlServer\Scripts_Instalacion_2000

	Sp_addrolemember
	Sp_droprolemember
	Sp_addalias
	Sp_dropalias

Agregar al Sector de Seguridad Informática con el rol de servidor de “Security Administrator” y en cada base de datos con los roles de “db_accessadmin” y “db_securityadmin”.

Agregar dichos roles en la base de datos Model, para que las siguientes bases hereden su configuración. 

Luego asignar en cada base(model primero ) y en el resto de las bases exceptuando la MASTER el siguiente script:

	grant insert,update on sysusers to [hlah\it_sec_mssql]
go
si hay problemas con los usuarios ej sysusers hay que dar 

	grant update to el usuario
	grant insert,update on sysusers to [hlah\NTDB08_DBMUSERS_DBO]

	deny insert,update on sysusers to [hlah\NTDB08_DBMUSERS_DBO]

	CORRER script que me paso Natalia

---------------------------------------------------------------
Para ver los usuarios

	sp_helpuser

---------------------------------------------------------------	
Para saber sobre que objetos tiene permisos un usuario

	exec sp_helprotect @username =   'SIS_AUTOSERVPOR'
	exec sp_helprotect @username = 'SIS_sicodoc'


--Problemas en los discos o servidores



