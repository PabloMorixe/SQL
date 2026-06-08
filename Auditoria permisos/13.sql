-- Lista los permisos asignados a cada usuario o rol para cada base de datos
exec sp_msforeachdb '
use [?]
select ''Base de datos:''+ ''[?]'' as BD
select usu.name as usuario,
CASE issqlrole
         WHEN 0 THEN ''Usuario''
         WHEN 1 THEN ''Rol''
      END Tipo_principal,
obj.name as objeto
from 
sysusers usu,
sysobjects obj,
syspermissions permi
where 
permi.grantee=usu.uid and permi.id=obj.id
order by usu.name
'