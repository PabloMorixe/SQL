#***************************************************************************************************************************
#     LIBRERIAS smo USADAS
#***************************************************************************************************************************
#---------------------------
#sql SERVER 2016
#---------------------------
#Add-Type -AssemblyName "Microsoft.SqlServer.ManagedDTS, Version=13.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop; $smoVersion = 13

#---------------------------
# sql SERVER 2017
#---------------------------
Add-Type -AssemblyName "Microsoft.SqlServer.ManagedDTS, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop; $smoVersion = 14

#***************************************************************************************************************************


#Move-Item C:\ImportarETL\*.dtsx C:\ImportarETLDestino -Force 




$Date = get-date

$source = "C:\ImportarETL\"
$destination = "C:\ImportarETLDestino\"
$Date = get-date
$items = Get-ChildItem -Path $source #-Recurse | Where-Object {$_.LastWriteTime -lt (Get-Date) -and ($_.PSisContainer -eq $true) }


foreach($item in $items)
{


try
{
$copiedItems=Copy-Item "$source\$item" -Destination $destination -Force -Recurse -PassThru 
"$([DateTime]::Now)" + "`t$source\$item`t is copied onto $destination"| out-file c:\copied.txt -Append
}
catch
{
"$source\$item"+": " + $_.Exception.message | Out-File c:\Notcopied.txt -Append
}
}
