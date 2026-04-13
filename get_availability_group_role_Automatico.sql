declare @servername varchar(max);

set @servername  =  (select @@SERVERNAME);


declare @SQL varchar(max);


select @SQL = '

CREATE FUNCTION [dbo].[is_primary_node_of_'+@servername+']()
RETURNS bit
AS
BEGIN;
  DECLARE @PrimaryReplica sysname; 

  SELECT
                @PrimaryReplica = hags.primary_replica
  FROM          sys.dm_hadr_availability_group_states hags
  INNER JOIN    sys.availability_groups ag 
                ON ag.group_id = hags.group_id
  WHERE 
            ag.name = '''+ @servername +''';

  IF UPPER(@PrimaryReplica) =  UPPER(@@SERVERNAME)
    RETURN 1; -- primary

    RETURN 0; -- not primary
END; 
'
Exec (@SQL)

declare @servername varchar(max);

set @servername  =  (select @@SERVERNAME);


declare @SQL varchar(max);


select @SQL = '
USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[is_primary_node_of_'+


@servername


+']()
RETURNS bit
AS
BEGIN;
  DECLARE @PrimaryReplica sysname; 

  SELECT
                @PrimaryReplica = hags.primary_replica
  FROM          sys.dm_hadr_availability_group_states hags
  INNER JOIN    sys.availability_groups ag 
                ON ag.group_id = hags.group_id
  WHERE 
            ag.name = 
			
'''+ @servername +''';

  IF UPPER(@PrimaryReplica) =  UPPER(@@SERVERNAME)
    RETURN 1; -- primary

    RETURN 0; -- not primary
END; 

 
GO'


Exec @SQL

