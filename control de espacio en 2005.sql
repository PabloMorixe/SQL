DBCC SQLPERF ( LOGSPACE )  can tell you the log size and used size.

    sp_spaceused  for space used/reserved in data files, not for log files.

    Perfmon.exe to view the database size and log size:

        SQL Server: Databases Object

            Data File(s) Size (KB)

            Log File(s) Size (KB)

            Log File(s) Used Size (KB)

