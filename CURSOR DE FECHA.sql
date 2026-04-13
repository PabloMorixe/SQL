declare fecha cursor
 for select 
substring(convert(varchar(10),getdate(),112),1,4) + '/' + 
                substring(convert(varchar(10),getdate(),112),5,2) + '/' + 
                 substring(convert(varchar(10),getdate(),112),7,2) 
/*select cast(year(getdate()) as varchar) + '/' +
'0' + cast(month(getdate())as varchar) + '/' +
cast(day(getdate())as varchar)
*/
declare @fecha_GET
 varchar (11)

open fecha
fetch next from fecha into @fecha_GET

while @@fetch_status=0
begin
select cant_user=count(distinct UL_USER),cant_hits=COUNT(*),UL_DATE --into HSBC_USUARIOS_X_DIA 
from SEC_USER_LOG(nolock)
WHERE UL_DATE = @fecha_GET
group by ul_date
order by ul_date
--select COUNT(distinct UL_USER)AS TOTAL_DE_USERS_CONECTADOS,UL_DATE from SEC_USER_LOG(nolock)
--WHERE UL_DATE = @fecha_GET
--GROUP BY UL_DATE
--order by UL_DATE desc
print @fecha_GET

fetch next from fecha into @fecha_GET

end 
close fecha
deallocate fecha