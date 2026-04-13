--Discos con Menos del 10% de espacio disponible				
select 	ServerUse as Ambiente, s.ServerName as Servidor, resource as DB, SpaceTotal as Espacio_Total
	, SpaceFree as Espacio_Libre, cast((SpaceFree/SpaceTotal)*100 as integer) as Porc_Espacio_Libre
from 	spaces sp inner join servers s on s.serverid=sp.serverid
where 	exists( select 1
	      from (Select serverid,max(collectdate) as maxdate from spaces group by serverid) t_max
	      where t_max.maxdate=sp.collectdate  and t_max.serverid=sp.serverid
			and t_max.maxdate>='20080701'
		)
	and ResType=1
	and SpaceTotal <> 0 
	and cast((SpaceFree/SpaceTotal)*100 as integer) <= 10
	and s.ServerUse in ('PROD','DESA')
order by ServerUse DESC, cast((SpaceFree/SpaceTotal)*100 as integer) , servername asc
---------------------------------------------------------------------------------------
---Crecimiento de las bases de datos comparando Mes actual y Mes anterior				
select 	ServerUse as Ambiente, s.servername as Servidor, sp1.resource as DB
	, cast((sp2.SpaceTotal-sp2.SpaceFree) as integer) as MB_Mes
	, cast((sp1.SpaceTotal-sp1.SpaceFree) as integer) as MB_MesAnterior
	, cast((sp2.SpaceTotal-sp2.SpaceFree) - (sp1.SpaceTotal-sp1.SpaceFree)as integer) as MBCrecimiento
	, cast((((sp2.SpaceTotal-sp2.SpaceFree) - (sp1.SpaceTotal-sp1.SpaceFree))/(sp1.SpaceTotal-sp1.SpaceFree)) *100 as integer) as Porc_Crecimiento
	, maxmin.maxdate as FechaMaxima
	, maxmin.mindate as FechaMinima
from 	(select serverid, max(collectdate) as maxdate, min(collectdate) as mindate
	 from spaces sp2 
	 where collectdate between cast(convert(varchar, dateadd(mm,-1,getdate()) - datepart(dd,getdate())+1,112) as datetime)
		and getdate()--and cast(convert(varchar,getdate() - datepart(dd,getdate()),112) as datetime)
	  group by serverid
	   ) MaxMin
	inner join spaces sp1  on sp1.serverid=maxmin.serverid and sp1.collectdate=maxmin.mindate
	inner join spaces sp2  on sp2.serverid=maxmin.serverid and sp2.collectdate=maxmin.maxdate and sp1.resource=sp2.resource
	inner join servers s	on s.serverid=maxmin.serverid
where 	sp1.restype=0
	and sp1.resource not in ('master','msdb','tempdb','model','pubs','northwind')
	and ServerUse in ('PROD','DESA')
order by ServerUse DESC, abs(cast((sp2.SpaceTotal-sp2.SpaceFree) - (sp1.SpaceTotal-sp1.SpaceFree)as integer)) desc
---------------------------------------------------------------------------------------

---Bases de datos con menos del 10% de espacio libre
select 	ServerUse as Ambiente, s.ServerName as Servidor, resource as DB, SpaceTotal as Espacio_Total
	, cast(SpaceFree as integer) as Espacio_Libre, cast((SpaceFree/SpaceTotal)*100 as integer) as Porc_Espacio_Libre
from 	spaces sp inner join servers s on s.serverid=sp.serverid
where 	exists( select 1
	      from (Select serverid,max(collectdate) as maxdate from spaces group by serverid) t_max
	      where t_max.maxdate=sp.collectdate  and t_max.serverid=sp.serverid
			and t_max.maxdate>='20080701'
		)
	and ResType=0
	and cast((SpaceFree/SpaceTotal)*100 as integer) <= 10
	and s.ServerUse in ('PROD','DESA')
order by ServerUse DESC, cast((SpaceFree/SpaceTotal)*100 as integer) , servername asc, resource asc

---------------------------------------------------------------------------------------
