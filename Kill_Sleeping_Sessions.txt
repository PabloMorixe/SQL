DECLARE @user_spid INT
DECLARE CurSPID CURSOR FAST_FORWARD
FOR
       SELECT session_id 
       FROM sys.dm_exec_sessions 
       WHERE status = N'sleeping' 
       AND open_transaction_count = 0  
       AND is_user_process = 1
       AND session_id <>@@spid
       AND DATEDIFF(SECOND,last_request_start_time,GETDATE()) > 30 
       AND login_name = 'MonitoreoPrueba'
OPEN CurSPID
FETCH NEXT FROM CurSPID INTO @user_spid
WHILE (@@FETCH_STATUS=0)
BEGIN
PRINT 'Killing '+CONVERT(VARCHAR,@user_spid)
EXEC('KILL '+@user_spid)
FETCH NEXT FROM CurSPID INTO @user_spid
END
CLOSE CurSPID
DEALLOCATE CurSPID
GO