[15:05] Villarruel Lorena Jaquelina
USE [AR_Supervielle_ICBanking]
GO
CREATE NONCLUSTERED INDEX [IDX_ Payment_EntId_Serializedticket]
ON [dbo].[Payment] ([EnterpriseId])
INCLUDE ([SerializedTicket])
WITH (Online = ON,RESUMABLE = ON);
GO

[15:05] Villarruel Lorena Jaquelina

ALTER INDEX [Payment_EntId_Serializedticket] ON [dbo].[Payment]
PAUSE;
GO

[15:05] Villarruel Lorena Jaquelina

ALTER INDEX [Payment_EntId_Serializedticket] ON [dbo].[Payment]
RESUME;
GO

[15:05] Villarruel Lorena Jaquelina
SELECT
name,
percent_complete,
state_desc,
last_pause_time,
page_count
FROM sys.index_resumable_operations;

