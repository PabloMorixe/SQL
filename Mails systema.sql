--Detener servicio
USE msdb ;
GO

EXECUTE dbo.sysmail_stop_sp ;
GO
USE msdb ;
GO
--inciiar servicio
EXECUTE dbo.sysmail_start_sp ;
GO
--Consultar cola de mails 
select  sent_status, * from msdb.dbo.sysmail_allitems where send_request_date > '2022-07-10' and sent_status <> 'sent'
--tabla de envíos fallidos
select * from msdb.dbo.sysmail_faileditems where send_request_date > '2022-07-10'

--sp que depura la cola de mails.
exec sysmail_delete_mailitems_sp @sent_status = 'sent'

IMPORTANTE: NO SE RECOMIENDA ELIMINAR REGISTROS MANUALMENTE DE LAS TABLAS INVOLUCRADAS. 
