set nocount on

select SERVER=@@servername,TYPE=case when type = 'd' then 'FULL' 
                     ELSE 'DIF'
                    END ,
database_name,FECHA=max(backup_finish_date)from msdb..backupset where type  in ('d','i')  and
database_name in (select name from master..sysdatabases)
group by database_name,type
order by database_name