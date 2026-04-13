use sqlmant
go




--POR FAVOR LEER BIEN ANTES DE EJECUTAR!!!!!!

-- COMO PREVIO A ESTE DESARROLLO HUBIERON INTENTOS FALLIDOS EN PONER EN FUNCIONAMIENTO ESTA ALERTA, LAS PRIMERAS LINEAS SON PARA EJECUTAR Y LIMPIAR OBJETOS NO UTILIZADOS. se debe ejecutar por unica vez 



/*  LOGICA: 
El script crea/actualiza la SP dbo.sp_BasesSinActividad_Upsert, que asegura la tabla e índice de control, 
captura de las DMVs las últimas sesiones de usuario por base (excluyendo ciertos logins) y hace upsert en
BasesSinActividad; luego arma un dataset por base con su “último login/última conexión” y calcula dias_sin_actividad;
si existe al menos una base con inactividad mayor a @UmbralDias y no se envió un reporte en los últimos @UmbralDias,
compone un HTML y lo envía por Database Mail, dejando traza en last_report_sent_at; por último, en msdb crea (o recrea)
un SQL Agent Job llamado DBA_BasesSinActividad que ejecuta la SP en la base SqlMant y agenda su corrida cada 1 minuto, 
todo referenciado por nombre (sin job_id).
--pablo.morixe@gmail.com

*/


------SECCION DROPEO DE ANTIGUOS OBJETOS----

--drop tablas
--drop table AlertarBasesSinActividad

--prod procedures
--drop procedure spSQLNova_AlertarBasesSinActividad
--drop procedure sp_noDBactivity_alert
--drop procedure sp_noDBactivity


--Stop y drop jobs
--EXEC msdb.dbo.sp_stop_job   @job_name = N'DBA_NoDBActivity_Monitor';
--EXEC msdb.dbo.sp_delete_job @job_name = N'DBA_NoDBActivity_Monitor';

--EXEC msdb.dbo.sp_stop_job   @job_name = N'DBA_SQLNova_AlertarBasesSinActividad';
--EXEC msdb.dbo.sp_delete_job @job_name = N'DBA_SQLNova_AlertarBasesSinActividad';

 
 -----TABLA DE CONTROL --- 
 
 --select * from [dbo].[BasesSinActividad]
  
 USE sqlmant;
GO

-- ============================================
-- SP de ingesta/actualización de actividad
-- ============================================
--CREATE OR
ALTER PROCEDURE dbo.sp_BasesSinActividad_Upsert
AS
BEGIN
  SET NOCOUNT ON;

  -- Crear la tabla solo si no existe
  IF OBJECT_ID(N'dbo.BasesSinActividad', N'U') IS NULL
  BEGIN
      CREATE TABLE [dbo].[BasesSinActividad](
          [ServerName]         nvarchar(128) NULL,   -- Server donde se recopila la data
          [host_name]          nvarchar(128) NULL,   -- desde donde viene la conexion
          [program_name]       nvarchar(128) NULL,   -- origen de la conexion
          [login_name]         nvarchar(128) NULL,   -- login utilizado
          [DB]                 nvarchar(128) NULL,   -- base a la que se conecta
          [capture_time]       datetime      NULL,   -- fecha de la conexion
          [last_report_sent_at] datetime     NULL    -- fecha/hora último envío del reporte
      ) ON [PRIMARY];
  END

  -- Crear el índice solo si no existe
  IF NOT EXISTS (
      SELECT 1
      FROM sys.indexes
      WHERE name = N'UX_BasesSinActividad_DB_Login'
        AND object_id = OBJECT_ID(N'dbo.BasesSinActividad')
  )
  BEGIN
      CREATE NONCLUSTERED INDEX [UX_BasesSinActividad_DB_Login]
      ON [dbo].[BasesSinActividad] ([DB], [login_name], [capture_time] DESC)
      INCLUDE ([host_name], [program_name], [ServerName]);
  END

  -- Captura y upsert (excluye ciertos logins)
  ;WITH Ses AS (
      SELECT
          @@SERVERNAME               AS ServerName,
          s.host_name,
          s.program_name,
          s.login_name,
          DB_NAME(s.database_id)     AS [DB],
          GETDATE()                  AS capture_time,
          ROW_NUMBER() OVER (
            PARTITION BY s.database_id, s.login_name
            ORDER BY s.last_request_end_time DESC, s.login_time DESC
          ) AS rn
      FROM sys.dm_exec_sessions s
      JOIN sys.dm_exec_connections c ON s.session_id = c.session_id
      WHERE s.is_user_process = 1
        AND s.session_id > 50
        AND s.database_id > 4
        AND DB_NAME(s.database_id) IS NOT NULL
        AND s.login_name NOT IN (
             N'gscorp\usrsqlserver', N'gscorp\pm43314adm', N'gscorp\sv51789adm',
             N'gscorp\LG88169ADM', N'scriptexec', N'gscorp\TB03260ADM',
             N'gscorp\pr67231adm', N'gscorp\mb47692adm', N'gscorp\LD52859ADM',
             N'gscorp\', N'gscorp\', N'gscorp\'      -- (entradas vacías mantenidas por compatibilidad)
        )
  )
  MERGE dbo.BasesSinActividad AS T
  USING (
      SELECT ServerName, host_name, program_name, login_name, [DB], capture_time
      FROM Ses WHERE rn = 1
  ) AS S
    ON T.[DB] = S.[DB]
   AND T.login_name = S.login_name
  WHEN MATCHED THEN
    UPDATE SET
      T.ServerName   = S.ServerName,
      T.host_name    = S.host_name,
      T.program_name = S.program_name,
      T.capture_time = S.capture_time
  WHEN NOT MATCHED THEN
    INSERT (ServerName, host_name, program_name, login_name, [DB], capture_time)
    VALUES (S.ServerName, S.host_name, S.program_name, S.login_name, S.[DB], S.capture_time);
END


-- ============================================
-- Reporte y envío por mail (con control de umbral y último envío)
-- ============================================
DECLARE @UmbralDias int = 30;   -- umbral de días para decidir si correr
DECLARE @profile_name sysname   = N'opesqladmin';
DECLARE @recipients  nvarchar(4000) = N'pablo.morixe@supervielle.com.ar';
DECLARE @instancia   sysname   = @@SERVERNAME;

IF OBJECT_ID('tempdb..#Res') IS NOT NULL DROP TABLE #Res;

;WITH Ultima AS (
    SELECT
        [DB],
        ServerName,
        host_name,
        program_name,
        login_name,
        capture_time,
        ROW_NUMBER() OVER (PARTITION BY [DB] ORDER BY capture_time DESC) AS rn
    FROM dbo.BasesSinActividad WITH (INDEX(UX_BasesSinActividad_DB_Login))
),
Ultima1 AS (
    SELECT [DB], login_name, host_name, program_name, capture_time
    FROM Ultima
    WHERE rn = 1
)
SELECT
    d.name AS [DB],
    COALESCE(u.login_name,   'N/A')                            AS ultimo_login,
    COALESCE(u.capture_time, CONVERT(datetime,'19000101',112)) AS ultima_conexion,
    COALESCE(u.host_name,    'N/A')                            AS host_name,
    COALESCE(u.program_name, 'N/A')                            AS program_name,
    DATEDIFF(day, COALESCE(u.capture_time, CONVERT(datetime,'19000101',112)), GETDATE()) AS dias_sin_actividad
INTO #Res
FROM sys.databases AS d
LEFT JOIN Ultima1 AS u
  ON u.[DB] = d.name
WHERE d.database_id > 4    -- solo DBs de usuario
  AND d.state = 0;         -- ONLINE

-- Último envío real considerado SOLO sobre las DBs que superan el umbral
DECLARE @last_report_sent_at datetime =
(
    SELECT MAX(last_report_sent_at)
    FROM dbo.BasesSinActividad
    WHERE [DB] IN (SELECT [DB] FROM #Res WHERE dias_sin_actividad > @UmbralDias)
);

IF EXISTS (SELECT 1 FROM #Res WHERE dias_sin_actividad > @UmbralDias)
   AND ( @last_report_sent_at IS NULL
         OR DATEDIFF(day, @last_report_sent_at, GETDATE()) >= @UmbralDias )
BEGIN
    DECLARE @html nvarchar(max) = N'';

    SET @html = @html + N'
    <style>
      table{border-collapse:collapse;font-family:Segoe UI,Arial,sans-serif;font-size:12px}
      th,td{border:1px solid #ccc;padding:6px 8px}
      th{background:#f3f3f3}
      tr:nth-child(even){background:#fafafa}
      .badge{padding:2px 6px;border-radius:10px;background:#eef;border:1px solid #ccd}
    </style>
    <h3>DBs sin conexiones recientes — Instancia: ' + REPLACE(CAST(@instancia AS nvarchar(128)),'<','&lt;') + N'</h3>
    <p>Umbral: <span class="badge">' + CAST(@UmbralDias AS nvarchar(10)) + N' día(s)</span></p>
    <table>
      <thead>
        <tr>
          <th>DB</th>
          <th>Último login</th>
          <th>Última conexión</th>
          <th>Host</th>
          <th>Programa</th>
          <th>Días sin actividad</th>
        </tr>
      </thead>
      <tbody>';

    -- Filas HTML (solo las que superan el umbral)
    SET @html = @html + (
        SELECT (
            SELECT
                N'<tr><td>' + r.[DB] + N'</td>' +
                N'<td>' + r.ultimo_login + N'</td>' +
                N'<td>' + CONVERT(varchar(19), r.ultima_conexion, 120) + N'</td>' +
                N'<td>' + r.host_name + N'</td>' +
                N'<td>' + r.program_name + N'</td>' +
                N'<td>' + CONVERT(varchar(10), r.dias_sin_actividad) + N'</td></tr>'
            FROM #Res AS r
            WHERE r.dias_sin_actividad > @UmbralDias
            ORDER BY r.dias_sin_actividad DESC, r.[DB]
            FOR XML PATH(''), TYPE
        ).value('.','nvarchar(max)')
    );

    SET @html = @html + N'</tbody></table>';
    SET @html = @html + N'<p style="color:#666;margin-top:8px">Generado: ' +
                 CONVERT(varchar(19), GETDATE(), 120) + N'</p>';

    DECLARE @subject nvarchar(400) =
        CONCAT(N'Alerta: Bases no utilizadas en ', CAST(SERVERPROPERTY('ServerName') AS nvarchar(128)));

    -- Envío por Database Mail
    EXEC msdb.dbo.sp_send_dbmail
         @profile_name = @profile_name,
         @recipients   = @recipients,

    @copy_recipients = 'base.datos@supervielle.com.ar',
         @subject      = @subject,
         @body         = @html,
         @body_format  = 'HTML';

    -- Marcar SOLO las DBs informadas
    UPDATE b
      SET last_report_sent_at = GETDATE()
    FROM dbo.BasesSinActividad AS b
    WHERE b.[DB] IN (SELECT [DB] FROM #Res WHERE dias_sin_actividad > @UmbralDias);
END
ELSE
BEGIN
    PRINT 'No se envía correo: sin DBs por encima del umbral o ya se notificó dentro del umbral.';
END
GO
go
-- ============================================
-- Creación/actualización del SQL Agent Job
-- ============================================
USE msdb;
GO

DECLARE 
  @JobName        sysname       = N'DBA_BasesSinActividad',
  @JobDesc        nvarchar(512) = N'Ejecuta dbo.sp_BasesSinActividad_Upsert',
  @Owner          sysname       = N'sa',
  @CategoryName   sysname       = N'[Uncategorized (Local)]',
  @StepName       sysname       = N'run sp_BasesSinActividad_Upsert',
  @DbName         sysname       = N'SqlMant',
  @Command        nvarchar(max) = N'EXEC dbo.sp_BasesSinActividad_Upsert;',
  @ScheduleName   sysname       = N'cada 1 minuto';

-- Categoría (si no existe)
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.syscategories WHERE name=@CategoryName AND category_class=1)
BEGIN
  EXEC msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=@CategoryName;
END

-- (Opcional) recrear limpio si ya existe
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name=@JobName)
BEGIN
  EXEC msdb.dbo.sp_delete_job @job_name=@JobName;
END

-- Crear/actualizar Job
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name=@JobName)
BEGIN
  EXEC msdb.dbo.sp_add_job
       @job_name = @JobName,
       @enabled = 1,
       @description = @JobDesc,
       @owner_login_name = @Owner,
       @category_name = @CategoryName;
END
ELSE
BEGIN
  EXEC msdb.dbo.sp_update_job
       @job_name = @JobName,
       @enabled = 1,
       @description = @JobDesc,
       @owner_login_name = @Owner,
       @category_name = @CategoryName;
END

-- Paso (add/update)
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobsteps 
           WHERE step_name=@StepName
             AND job_id IN (SELECT job_id FROM msdb.dbo.sysjobs WHERE name=@JobName))
BEGIN
  EXEC msdb.dbo.sp_update_jobstep
       @job_name = @JobName,
       @step_name = @StepName,
       @subsystem = N'TSQL',
       @database_name = @DbName,
       @command = @Command,
       @on_success_action = 1,  -- Quit with success
       @on_fail_action    = 2;  -- Quit with failure
END
ELSE
BEGIN
  EXEC msdb.dbo.sp_add_jobstep
       @job_name = @JobName,
       @step_name = @StepName,
       @subsystem = N'TSQL',
       @database_name = @DbName,
       @command = @Command,
       @on_success_action = 1,
       @on_fail_action    = 2;
END

-- Asegurar start_step_id=1
EXEC msdb.dbo.sp_update_job @job_name = @JobName, @start_step_id = 1;

-- Schedule por nombre (sin job_id)
DECLARE @TodayYYYYMMDD int = CAST(CONVERT(char(8), GETDATE(), 112) AS int);

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name=@ScheduleName)
BEGIN
  EXEC msdb.dbo.sp_add_schedule
       @schedule_name        = @ScheduleName,
       @enabled              = 1,
       @freq_type            = 4,            -- Diario
       @freq_interval        = 1,
       @freq_subday_type     = 4,            -- Minutos
       @freq_subday_interval = 1,            -- cada 1 minuto
       @active_start_date    = @TodayYYYYMMDD,
       @active_end_date      = 99991231,
       @active_start_time    = 0,
       @active_end_time      = 235959;
END
ELSE
BEGIN
  EXEC msdb.dbo.sp_update_schedule
       @name                 = @ScheduleName,
       @enabled              = 1,
       @freq_type            = 4,
       @freq_interval        = 1,
       @freq_subday_type     = 4,
       @freq_subday_interval = 1,
       @active_end_date      = 99991231,
       @active_start_time    = 0,
       @active_end_time      = 235959;
END

-- Vincular schedule al job (por nombre)
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobschedules js
    JOIN msdb.dbo.sysschedules s ON s.schedule_id = js.schedule_id
    JOIN msdb.dbo.sysjobs j ON j.job_id = js.job_id
    WHERE j.name = @JobName AND s.name = @ScheduleName
)
BEGIN
  EXEC msdb.dbo.sp_attach_schedule
       @job_name = @JobName,
       @schedule_name = @ScheduleName;
END

-- Servidor de destino por nombre
IF NOT EXISTS (
    SELECT 1 
    FROM msdb.dbo.sysjobservers js
    JOIN msdb.dbo.sysjobs j ON j.job_id = js.job_id
    WHERE j.name = @JobName
)
BEGIN
  EXEC msdb.dbo.sp_add_jobserver 
       @job_name = @JobName, 
       @server_name = N'(local)';
END

PRINT CONCAT('Job listo por nombre: ', @JobName);
GO
