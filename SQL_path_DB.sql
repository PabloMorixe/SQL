declare cur_db cursor
 for select name from master..sysdatabases

declare @name varchar (60)

open cur_db

fetch next from cur_db into @name


while @@fetch_status=0
begin
--1
print( @name )

--2

--print('select name AS [NOMBRE DE ARCHIVO],filename AS PATH from ' + @name + '..sysfiles')
PRINT ('UNION ALL')
--BORRAR EL ULTIMO UNION ALL
--EL SEGUNDO RESULTADO PASARLO A UN EXCEL Y SEPARARLO PARA QUE QUEDE BIEN


fetch next from cur_db into @name

end

close cur_db
deallocate cur_db