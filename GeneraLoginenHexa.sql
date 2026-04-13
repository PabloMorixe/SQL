USE [master]
GO

/****** Object:  StoredProcedure [dbo].[GeneraLoginenHexa]    Script Date: 21/7/2022 16:37:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Pablo Morixe
-- Create date: 20 enero 2022
-- Description: SP	Genera logines  en hexa
-- FINALIZADO OK
-- =============================================
CREATE PROCEDURE [dbo].[GeneraLoginenHexa]
	  AS
BEGIN
SELECT N'CREATE LOGIN ['+sp.[name]+'] WITH PASSWORD=0x'+
    CONVERT(nvarchar(max), l.password_hash, 2)+N' HASHED, '+
    N'SID=0x'+CONVERT(nvarchar(max), sp.[sid], 2)+N';'
FROM master.sys.server_principals AS sp
INNER JOIN master.sys.sql_logins AS l ON sp.[sid]=l.[sid]
where l.principal_id > 288
/*
where l.principal_id >  1 
and l.name not in (
'##MS_PolicyTsqlExecutionLogin##'
,'##MS_PolicyEventProcessingLogin##'
,'scriptexec'
,'usrSOTP'
,'usrSOTPdta'
)
*/

end
GO


