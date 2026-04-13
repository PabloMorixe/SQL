/* ============================================================
   CARGA REAL por día de la semana (WhoIsActive snapshots)
   (Agrupado por fecha/hora LOCAL de Argentina, UTC-3)
   - Convierte métricas a numérico (remueve . y ,)
   - LAG() por (session_id, request_id) en hora LOCAL
   - Deltas positivos por captura
   - Score ponderado por día de semana y ranking
============================================================ */

USE SqlMant
GO

DECLARE 
    @DateFrom  datetime2(0) = DATEADD(DAY, -30, SYSUTCDATETIME()),  -- ventana (UTC)
    @DateTo    datetime2(0) = SYSUTCDATETIME(),
    @ExcludeSystemDBs bit = 1,

    -- Filtros opcionales (LIKE); dejá NULL para no excluir
    @LoginExcludePattern   nvarchar(200) = N'GSCORP\usrsqlservice',         -- ejemplo
    @ProgramExcludePattern nvarchar(200) = N'Microsoft® Windows® Operating System', -- sp_server_diagnostics
    @DBExcludePattern      nvarchar(200) = NULL;                            -- ej: N'tempdb'

/* Pesos del score (ajustables) */
DECLARE 
    @wCPU           float = 1.0,   -- ms CPU
    @wReads         float = 1.0,   -- logical reads
    @wWrites        float = 3.0,   -- logical writes
    @wPhysicalReads float = 6.0,   -- physical reads
    @wBlocked       float = 1000.0;-- penalización por muestra bloqueada

/* Zona horaria local: Buenos Aires (UTC-3, sin DST) */
DECLARE @TzOffsetMin int = -180;

SET DATEFIRST 1; -- Lunes=1
SET NOCOUNT ON;

/* ==================== 1) Fuente filtrada ==================== */
IF OBJECT_ID('tempdb..#S') IS NOT NULL DROP TABLE #S;

CREATE TABLE #S (
    session_id            int           NOT NULL,
    request_id            int           NULL,
    login_name            nvarchar(256) NULL,
    program_name          nvarchar(256) NULL,
    database_name         nvarchar(256) NULL,
    collection_time       datetime2(3)  NOT NULL, -- UTC
    CPU                   nvarchar(64)  NULL,     -- pueden venir con separadores
    reads                 nvarchar(64)  NULL,
    writes                nvarchar(64)  NULL,
    physical_reads        nvarchar(64)  NULL,
    blocking_session_id   int           NULL
);

INSERT INTO #S (
    session_id, request_id, login_name, program_name, database_name,
    collection_time, CPU, reads, writes, physical_reads, blocking_session_id
)
SELECT
    session_id,
    request_id,
    login_name,
    program_name,
    database_name,
    collection_time,
    CPU,
    reads,
    writes,
    physical_reads,
    blocking_session_id
FROM SqlMant.dbo.DBAWhoIsActive WITH (NOLOCK)
WHERE collection_time >= @DateFrom
  AND collection_time <  @DateTo
  AND (@ExcludeSystemDBs = 0 
       OR ISNULL(database_name,'') NOT IN ('master','model','msdb','tempdb'))
  AND (@LoginExcludePattern   IS NULL OR login_name   NOT LIKE @LoginExcludePattern)
  AND (@ProgramExcludePattern IS NULL OR program_name NOT LIKE @ProgramExcludePattern)
  AND (@DBExcludePattern      IS NULL OR database_name NOT LIKE @DBExcludePattern);

/* ==================== 2) Deltas materializados ==================== */
IF OBJECT_ID('tempdb..#Deltas') IS NOT NULL DROP TABLE #Deltas;

CREATE TABLE #Deltas (
    bucket_date_local date         NOT NULL,
    weekday_no        int          NOT NULL,
    weekday_name      nvarchar(30) NOT NULL,
    d_cpu_ms          bigint       NOT NULL,
    d_reads           bigint       NOT NULL,
    d_writes          bigint       NOT NULL,
    d_phys_reads      bigint       NOT NULL,
    blocked_flag      int          NOT NULL
);

WITH S AS (
    SELECT
        s.session_id,
        s.request_id,
        DATEADD(MINUTE, @TzOffsetMin, s.collection_time) AS ct_local, -- LOCAL

        -- Normalizar métricas -> BIGINT
        TRY_CAST(REPLACE(REPLACE(s.CPU,            '.', ''), ',', '') AS bigint) AS CPU_num,
        TRY_CAST(REPLACE(REPLACE(s.reads,          '.', ''), ',', '') AS bigint) AS reads_num,
        TRY_CAST(REPLACE(REPLACE(s.writes,         '.', ''), ',', '') AS bigint) AS writes_num,
        TRY_CAST(REPLACE(REPLACE(s.physical_reads, '.', ''), ',', '') AS bigint) AS phys_reads_num,

        s.blocking_session_id
    FROM #S AS s
),
X AS (
    SELECT
        S.*,
        LAG(S.CPU_num)        OVER (PARTITION BY S.session_id, S.request_id ORDER BY S.ct_local) AS prev_CPU_num,
        LAG(S.reads_num)      OVER (PARTITION BY S.session_id, S.request_id ORDER BY S.ct_local) AS prev_reads_num,
        LAG(S.writes_num)     OVER (PARTITION BY S.session_id, S.request_id ORDER BY S.ct_local) AS prev_writes_num,
        LAG(S.phys_reads_num) OVER (PARTITION BY S.session_id, S.request_id ORDER BY S.ct_local) AS prev_phys_reads_num
    FROM S
)
INSERT INTO #Deltas (bucket_date_local, weekday_no, weekday_name, d_cpu_ms, d_reads, d_writes, d_phys_reads, blocked_flag)
SELECT
    CAST(ct_local AS date)              AS bucket_date_local,
    DATEPART(WEEKDAY, ct_local)         AS weekday_no,
    DATENAME(WEEKDAY, ct_local)         AS weekday_name,

    CASE WHEN CPU_num        - ISNULL(prev_CPU_num,0)        > 0 THEN CPU_num        - ISNULL(prev_CPU_num,0)        ELSE 0 END,
    CASE WHEN reads_num      - ISNULL(prev_reads_num,0)      > 0 THEN reads_num      - ISNULL(prev_reads_num,0)      ELSE 0 END,
    CASE WHEN writes_num     - ISNULL(prev_writes_num,0)     > 0 THEN writes_num     - ISNULL(prev_writes_num,0)     ELSE 0 END,
    CASE WHEN phys_reads_num - ISNULL(prev_phys_reads_num,0) > 0 THEN phys_reads_num - ISNULL(prev_phys_reads_num,0) ELSE 0 END,

    CASE WHEN blocking_session_id IS NOT NULL THEN 1 ELSE 0 END
FROM X
WHERE prev_CPU_num IS NOT NULL 
   OR prev_reads_num IS NOT NULL 
   OR prev_writes_num IS NOT NULL
   OR prev_phys_reads_num IS NOT NULL;

/* ==================== 3) Ranking por día de semana ==================== */
;WITH AggDay AS (
    SELECT 
        weekday_no,
        weekday_name,
        SUM(d_cpu_ms)     AS cpu_ms_total,
        SUM(d_reads)      AS reads_total,
        SUM(d_writes)     AS writes_total,
        SUM(d_phys_reads) AS phys_reads_total,
        SUM(blocked_flag) AS blocked_samples,
        COUNT(*)          AS muestras,
        SUM(@wCPU * d_cpu_ms 
          + @wReads * d_reads 
          + @wWrites * d_writes 
          + @wPhysicalReads * d_phys_reads
          + @wBlocked * blocked_flag) AS score_total
    FROM #Deltas
    GROUP BY weekday_no, weekday_name
),
DatesPerWeekday AS (
    SELECT 
        DATEPART(WEEKDAY, bucket_date_local) AS weekday_no,
        COUNT(DISTINCT bucket_date_local)    AS fechas_observadas
    FROM #Deltas
    GROUP BY DATEPART(WEEKDAY, bucket_date_local)
)
SELECT 
    a.weekday_no,
    a.weekday_name,
    a.cpu_ms_total,
    a.reads_total,
    a.writes_total,
    a.phys_reads_total,
    a.blocked_samples,
    a.muestras,
    a.score_total,
    CAST(1.0 * a.score_total / NULLIF(d.fechas_observadas,0) AS float) AS score_promedio_por_fecha,
    RANK() OVER (ORDER BY CAST(1.0 * a.score_total / NULLIF(d.fechas_observadas,0) AS float) ASC) AS rank_menor_carga
FROM AggDay AS a
LEFT JOIN DatesPerWeekday AS d
  ON d.weekday_no = a.weekday_no
ORDER BY score_promedio_por_fecha ASC;

/* ==================== 4) (Opcional) detalle por fecha ==================== */
SELECT
    bucket_date_local                                    AS bucket_date,
    DATENAME(WEEKDAY, bucket_date_local)                 AS weekday_name,
    SUM(d_cpu_ms)      AS cpu_ms_total,
    SUM(d_reads)       AS reads_total,
    SUM(d_writes)      AS writes_total,
    SUM(d_phys_reads)  AS phys_reads_total,
    SUM(blocked_flag)  AS blocked_samples,
    SUM(@wCPU * d_cpu_ms 
      + @wReads * d_reads 
      + @wWrites * d_writes 
      + @wPhysicalReads * d_phys_reads
      + @wBlocked * blocked_flag) AS score_total_dia
FROM #Deltas
GROUP BY bucket_date_local
ORDER BY bucket_date_local;
