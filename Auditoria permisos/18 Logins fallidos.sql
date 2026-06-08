SELECT EventClass, NTUserName, NTDomainName, HostName, ApplicationName, LoginName, Starttime, ServerName
FROM TRACE..TRAZAS
WHERE EVENTCLASS = 20
AND Starttime > getdate()-10