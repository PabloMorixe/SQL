--CORRIO EN DBALOG DEL FS1000127
SET NOCOUNT ON
CREATE TABLE #PUBLICA (
SERVER VARCHAR(30),
BASE VARCHAR(50),
PUBLICACION VARCHAR(50),
tabla_publ VARCHAR(50),
SUBSCRIPTOR VARCHAR(50),
BASEDESTINO VARCHAR(50),
tabla_subs varchar (50))
declare @base varchar(30)
declare prueba scroll cursor for select name from master.dbo.sysdatabases where category=1
open prueba
fetch first from prueba into @base
while (@@fetch_status)=0
  begin
   INSERT INTO #PUBLICA
   select 'SERVER'=@@servername,'BASE'=@base,'publicacion'=syspublications.name,'tabla_publ'=sysarticles.name ,
          'subscriptor'=srvname,dest_db,'tabla_subs'=sysarticles.name 
     from syspublications,sysarticles,syssubscriptions,master..sysservers  where
       sysarticles.pubid=syspublications.pubid and master..sysservers.srvid=syssubscriptions.srvid
       and sysarticles.artid=syssubscriptions.artid
   fetch next from prueba into @base
  end
deallocate prueba
SELECT * FROM #PUBLICA
DROP TABLE #PUBLICA