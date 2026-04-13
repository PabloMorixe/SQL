habilita tabla:

EXECUTE sys.sp_cdc_enable_table  

    @source_schema = N'dbo'  

  , @source_name = N'tablename'  

  , @role_name = N'NULL';  

GO  


chequea que tablas estan habilitadas: 

SELECT [name], is_tracked_by_cdc  
  FROM sys.tables 
  GO   

SELECT [name], is_cdc_enabled FROM sys.databases       
  GO