declare cur_db cursor
 for select name from master..sysdatabases

declare @name varchar (60)

open cur_db

fetch next from cur_db into @name


while @@fetch_status=0
begin

print('select ' + @name + ' name,filename from ' + @name + '..sysfiles')


fetch next from cur_db into @name

end

close cur_db
deallocate cur_db

--select  + 'Base de Datos: '+ 'master' +' '+'Path: '+ filename from BCON001_General..sysfiles