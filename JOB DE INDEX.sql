STEP 1 DBMARKET - OWNER SQL_NC

declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(' + o.name + ',' + i.name + ')' as ejecucion
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

STEP 2 DBMUSERS

declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(' + o.name + ',' + i.name + ')' as ejecucion
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

STEP3 DBMWORK

declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(' + o.name + ',' + i.name + ')' as ejecucion
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

STEP 4 INFO_0707
declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(' + o.name + ',' + i.name + ')' as ejecucion
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

STEP5 PROA_ANALYTICS

declare @ejecucion varchar(100)
declare curDBIndex cursor for 
	select 	'dbcc dbreindex(' + o.name + ',' + i.name + ')' as ejecucion
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



