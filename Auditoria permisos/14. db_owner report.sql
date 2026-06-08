-- Lista los roles y los miembros de cada rol para cada base de datos
exec sp_msforeachdb '
use [?]
select ''Base de datos:''+ ''[?]'' as BD
select roles.name as Rol,usuarios.name as miembro
from
(select * from sysusers where issqlrole=1) roles,
(select * from sysusers where issqlrole<>1) usuarios,
sysmembers membresia
where roles.uid=membresia.groupuid and usuarios.uid=memberuid
order by roles.name
'



-- Usar este
exec sp_msForEachDb ' use [?] 
select db_name() as [database_name], r.[name] as [role], p.[name] as [member] from  
    sys.database_role_members m 
join 
    sys.database_principals r on m.role_principal_id = r.principal_id 
join 
    sys.database_principals p on m.member_principal_id = p.principal_id 
where 
    r.name = ''db_owner'''