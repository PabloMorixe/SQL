select * from dbo.Servers
ORDER BY ServerName ASC
insert into Servers (ServerName,ServerUse,Product,Version,Descrip,LogSpace,Monitoring,UpdateUsage,UserName,Password,PrimaryFunc)      
values ('NTFSDB02TES','TEST', 'SQL Server 2000', '8.0', 'Test','1', '1', '1',NULL,NULL, 'DB')