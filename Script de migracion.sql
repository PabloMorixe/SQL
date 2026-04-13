USE Tableros

--SCRIPT MIGRACION DW-----
--TIENE QUE CORRERSE EN EL EQUIPO SSPR17DWH-01
--SE USA LA TABLA ctl.ctrl_registros_mig COMO PRINCIPAL PARA COMPARAR CANTIDAD DE REGISTROS POR TABLA/FECHA ENTRE AMBOS EQUIPOS
--SE CONTEMPLARON LOS CASOS EN LOS QUE NO HAY INFO EN EL DESTINO DE ALGUNA TABLA/FECHA. PARA  ESOS CASOS SE FORZO UN REGISTROS CON CERO CANTIDAD DE 
--REGISTROS, COSA DE QUE LA CONSULTA QUE VA A LOOPEAR PUEDA HACER JOIN EN LA TOTALIDAD DE LOS REGISTROS
--SE DEJO UNA TABLA DE LOG ctl.ctl_control_mig PARA SABER QUE Y CUANDO/CUANTO SE PROCESO CADA TABLA/MES, LA CUAL SE USA TAMBIEN PARA NO REPROCESAR DATOS (MARCA DE OK)

--SE DEJARON COMENTADOS LOS EXEC. EN SU LUGAR DEJE LOS SELECT DE LA VARIABLE @SQL, PARA QUE LO PUEDAN MIRAR Y VEAN LO QUE SE VA A PROCESAR CUANDO
--LO DEJEMOS PRODUCTIVO (DEBERIAMOS COMENTAR EL SELECT @SQL Y DESCOMENTAR LOS EXEC
--COMO MEJORA, HAY QUE AGREGARLE EL CONTROL DE ERRORES, PARA QUE EL PROCESO SIGA SI "ALGO" PINCHA. EL ERROR DEBERIA LOGUEARSE EN ctl.ctl_control_mig 



DECLARE @SQL NVARCHAR(MAX)
DECLARE @Rowcount bigint
DECLARE @FlagDetenerse as smallint 

Select @FlagDetenerse = FlagDetenerse from ctl.ControlDeProceso

--ARMADO DE TEMPORAL DEL LOOP DE TABLAS A PROCESAR
--Creo la temporal con un campo IDENTITY para usarlo en el loop
CREATE TABLE #temp_tables_Proc (ID INT IDENTITY(1,1), TableNameFormater nvarchar(350), CampoFecha varchar(50), Fecha int, Flag_Del smallint);

--Traigo todas las tablas/fecha pendientes de migrar (estado <> OK), ordenada por tabla/fecha
insert into #temp_tables_Proc (TableNameFormater, CampoFecha, Fecha, Flag_Del)
select 
		a.tabla, 
		a.campo_fecha, 
		a.fecha, 
		case 
			when b.cantidad > 0 then 1 
			else 0 
		end as  flag_Del
from 
			ctl.ctrl_registros_mig a
inner  join ctl.ctrl_registros_mig b
				on	a.tabla = b.tabla
				and a.fecha = b.fecha
where 
	a.entorno  = 'ssmcs-04'
and b.entorno  = 'SSPR17DWH-01'
and a.cantidad > b.cantidad  
and not exists (	select * --'E' 
					from ctl.ctl_control_mig c 
					where a.tabla = c.tabla 
					and a.fecha = c.fecha 
					and c.estado = 'OK'
				)
order by a.tabla, a.fecha
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--PROCESO: RECORRE LOOP DE TABLA Y FECHA
DECLARE		@FIN INT,
            @IDPROC INT,
            @NombreTabla NVARCHAR(350),
            @NombreColumnaFiltro VARCHAR(25),
			@fechaProc INT,
			@Inicio_Proc smalldatetime,
			@Fin_Proc smalldatetime,
			@Flag_Del smallint;

SELECT 
	@FIN = MAX(ID), 
	@IDPROC = 1 
FROM 
		#temp_tables_Proc

WHILE(@IDPROC <=  @FIN AND @FlagDetenerse = 0)
BEGIN
	begin try
		--------------------------------------------------------------------------------------------------------------------------------------
		-- Proceso 
		--------------------------------------------------------------------------------------------------------------------------------------
		BEGIN TRANSACTION;

			--Loc ambie de lugar !!!
			SET @Inicio_Proc = getdate();
			SET @Fin_Proc = @Inicio_Proc
			 
			SELECT @NombreTabla = TableNameFormater, @NombreColumnaFiltro = CampoFecha , @fechaProc = fecha, @Flag_Del = Flag_Del 
			FROM #temp_tables_Proc 
			WHERE id = @IDPROC

                    
			--PARA  LOS CASOS DE QUE LA CANTIDAD DEL DESTINO SEA MAYOR A CERO PERO MENOR A LA DE ORIGEN, TENGO QUE BORRAR EL PERIODO
			IF @Flag_Del = 1
			BEGIN
				--BEGIN TRANSACTION; -- No hace falta esta transaccion anidada !!!!
				SET @SQL = 'DELETE FROM tableros.' + @NombreTabla + ' WHERE ' + @NombreColumnaFiltro + ' = ' + cast(@fechaProc AS VARCHAR(60))		
				--   EXEC sp_executesql @SQL
				select @SQL 
				--COMMIT TRANSACTION;
			END

			SET @SQL = 'INSERT INTO tableros.' + @NombreTabla + ' SELECT * FROM [ssmcs-04].Tableros.' + @NombreTabla + ' WHERE ' + @NombreColumnaFiltro + ' = ' + cast(@fechaProc AS VARCHAR(60))
                           
			--   EXEC sp_executesql @SQL
			select @SQL 

			SET @Rowcount = @@ROWCOUNT
			SET @Fin_Proc = getdate();

			print 'Se proceso mes: ' + cast(@fechaProc as NVARCHAR(20)) + '. Cantidad de reg: ' + CAST(@Rowcount as nvarchar(50)) + ' de la tabla: ' + @NombreTabla
	
			--INSERTO REGISTRO DE CONTROL
			SET @SQL = 'INSERT INTO tableros.ctl.ctl_control_mig VALUES ('''+  @NombreTabla + ''', ' + convert(varchar,@fechaProc) + ',''' + convert(varchar,@Inicio_Proc,114) + ''',''' + convert(varchar,@Fin_Proc,114) + ''',''OK'''+ ')'	
			--  EXEC sp_executesql @SQL
			select @SQL 

			SET @IDPROC  = @IDPROC  + 1  

		COMMIT TRANSACTION;

		Select @FlagDetenerse = FlagDetenerse from ctl.ControlDeProceso

		--------------------------------------------------------------------------------------------------------------------------------------

	end try
	begin catch
		rollback		
		print 'Se produjo un error en el proceso del mes: ' + cast(@fechaProc as NVARCHAR(20)) + ' de la tabla: ' + @NombreTabla;
		print 
			  'Error:'     + cast(coalesce(ERROR_NUMBER(),'') as nvarchar(20)) 
			+' Severidad:' + cast(coalesce(ERROR_SEVERITY(),'') as nvarchar(20)) 
			+' Estado:'    + cast(coalesce(ERROR_STATE(),'') as nvarchar(20)) 
			+' Mensaje:'   + cast(coalesce(ERROR_MESSAGE(),'') as nvarchar(max));
			 
		SET @SQL = 'INSERT INTO tableros.ctl.ctl_control_mig VALUES ('''+  @NombreTabla + ''', ' + convert(varchar,@fechaProc) + ',''' + convert(varchar,@Inicio_Proc,114) + ''',''' + convert(varchar,@Fin_Proc,114) + ''',''ER'''+ ')';
	end catch
END
drop table #temp_tables_Proc;

/*
Create table ctl.ControlDeProceso
(
	FlagDetenerse smallint
)

Insert into ctl.ControlDeProceso values (0)
-- Esto indica que no se detiene
update ctl.ControlDeProceso SET FlagDetenerse = 0

--Esto indica que se debe detener
update ctl.ControlDeProceso SET FlagDetenerse = 1

*/
