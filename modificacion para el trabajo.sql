create table mitabla
(control int,
tiempo datetime)


insert into mitabla (control, tiempo) 
values (2, getdate())

select * from mitabla 

select dateadd(hh, +1 ,getdate())

DELETE mitabla from mitabla where control < 4 

/*pruebas 

while
if 
*/
declare @num int
set @num = 0
set @num = @num +1
print @num