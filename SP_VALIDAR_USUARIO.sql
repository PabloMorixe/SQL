COMPROBACION DE VALIDACION DE USUARIOS CONTRA NOVEL
---------------------------------------------------

declare @var as int	
exec @var = sp_validar_usuario_so "login","password",'NW'
select @var