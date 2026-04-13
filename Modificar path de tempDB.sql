USE master



ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = 'E:\SQLData\tempdb.mdf')

go

ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'F:\SQLLog\templog.ldf')

go