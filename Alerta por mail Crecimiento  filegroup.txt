--Query envia mail de alerta por espacio en fileGroup. 

DECLARE
@EmailSubject varchar(100),
@TextTitle varchar(100),
@SubTextTitle varchar(100),
@TableHTML nvarchar(max),
@Body nvarchar(max),
@DBName varchar(50),
@ServerName varchar(50),
@texto1 varchar(100),
@Alerta int  

Set @Alerta =  '10'
select @ServerName = @@servername
SET @DBName = ''
SET @EmailSubject = 'Alerta espacio Filegroup en servidor ' + @ServerName + ' '
SET @TextTitle = 'Alerta espacio Filegroup en servidor ' + @ServerName + ' '
SET @SubTextTitle = 'Revisar los espacios disponibles en disco '
set @texto1 = 'El umbral esta seteado en '+ CAST(@Alerta as varchar(100))+'%'
SET @TableHTML =
'<html>'+
'<head><style>'+
-- Data cells styles / font size etc
'td {border:1px solid #ddd;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:10pt}'+
'</style></head>'+
'<body>'+
-- TextTitle style
'<div style="margin-top:15px; margin-left:15px; margin-bottom:15px; font-weight:bold; font-size:13pt; font-family:calibri;">' + @TextTitle +'</div>' +
-- SubTextTitle style
'<div style="margin-top:15px; margin-left:15px; margin-bottom:15px; font-weight:bold; font-size:10pt; font-family:calibri;">' + @SubTextTitle +'</div>'  +
-- Umbral text style
'<div style="margin-top:15px; margin-left:15px; margin-bottom:15px; font-weight:bold; font-size:10pt; font-family:calibri;">' + @texto1 +'</div>'  +



-- Color and columns names
'<div style="font-family:Calibri; "><table>'+'<tr bgcolor=#00881d>'+
'<td align=left><font face="calibri" color=White><b>Database Name</b></font></td>'+ -- Database Name
'<td align=left><font face="calibri" color=White><b>Filegroup Name</b></font></td>'+ -- Filegroup Name
'<td align=center><font face="calibri" color=White><b>Percent Free </b></font></td>'+ -- Percent Free 
'<td align=right><font face="calibri" color=White><b>DisponibleGB</b></font></td>'+ -- DisponibleGB
'</tr></div>'


if OBJECT_ID(N'tempdb..#PocoEspacio') IS NOT NULL 
drop table #PocoEspacio


Create table #PocoEspacio(
dbname varchar(50),
FilegroupName varchar(50),
PercentFree int,
DisponibleGB decimal
)


--parseo 
DECLARE @command nvarchar(4000)
select @command = 'USE [?] 

insert into #PocoEspacio    

select 
    dbname,
    coalesce(f.name, ''TLog'') as FilegroupName,
  --  Size/128000.0 as UsedSizeGb,
  --  spaceused/128000.0 as SpaceUsedGb,
    (1.0 - 1.0*spaceused/Size) * 100 as PercentFree,
	(Size - spaceused)/128.00 as DisponibleGB 
from   
    (select  db_name() as dbname, 
     groupid,      
    sum(size) as Size, 
    SUM(Fileproperty (NAME, ''SpaceUsed'')) as spaceused
    from sys.sysfiles
    group by groupid) e
LEFT OUTER JOIN sys. filegroups f
ON e.groupid = f. data_space_id
'
--ejecucion
--print @command
exec sp_MSforeachdb @command 

/*
--filtro y alerta
select *from #PocoEspacio 
where PercentFree < 12
--and PercentFree < 16
and dbname not in ('master','model','msdb','sqlmant')
order by PercentFree desc

*/

SELECT @Body =(
SELECT
td = dbname,
td = FilegroupName,
td = PercentFree,
td = DisponibleGB
/*
,td = inequality_columns,
td = included_columns,
td = CONVERT(DECIMAL(16,2),overal_impact_value)
*/


FROM #PocoEspacio
where PercentFree < @Alerta and DisponibleGB < 10000
and dbname not in ('master','model','msdb','sqlmant')
ORDER BY PercentFree desc-- CONVERT(DECIMAL(16,2), overal_impact_value) desc
for XML raw('tr'), elements)

SET @body = REPLACE(@body, '<td>', '<td align=left><font face="calibri">')
SET @tableHTML = @tableHTML + @body + '</table></div></body></html>'
SET @tableHTML = '<div style="color:Black; font-size:8pt; font-family:Calibri; width:auto;">' + @tableHTML + '</div>'

if (select count(*) FROM #PocoEspacio where PercentFree < @Alerta and dbname not in ('master','model','msdb','sqlmant') and DisponibleGB < 10000 ) > 0
exec msdb.dbo.sp_send_dbmail
@profile_name = 'opesqladmin',
@recipients = 'base.datos@supervielle.com.ar; monitoreoTI@supervielle.com.ar',
--@Copy_recipients = 'COEData&AdvancedAnalytics@supervielle.com.ar',
--@Copy_recipients = 'MobileBanking@supervielle.com.ar',
--@recipients = 'pablo.morixe@supervielle.com.ar',
@body = @tableHTML,
@subject = @emailSubject,
@body_format = 'HTML'

