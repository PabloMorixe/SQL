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

cls

# ------------------------------------------ Get-ISPackage ------------------------------------------ 
function Get-ISPackage
{
    param(
        [Parameter(Mandatory=$true)] [string]$path
    )

    Write-Verbose "Get-ISPackage path:$path serverName:$serverName"
    $app = new-object ("Microsoft.SqlServer.Dts.Runtime.Application") 
    $name =  ($path -split '\\')[($path -split '\\').count -1]
    $name = $name -replace ".dtsx"
    if (Test-Path -literalPath $path)
    { 
        $app.LoadPackage($path, $null) | add-Member -memberType noteProperty -name DisplayName -value $name -passthru 
        Write-Verbose "Get-ISPackage LOADED CARGOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"
    }
    else
    { 
        Write-Error "Package $path does not exist  - NO EXISTSE EL PATHHHHHHHHHHHHHHH" 
    }    
} 
# ------------------------------------------ Get-ISPackage ------------------------------------------ 




# ------------------------------------------ Test-ISPackage ------------------------------------------ 
function Test-ISPath
{
    param(
    [Parameter(Mandatory=$true)] [string]$path,
    [Parameter(Mandatory=$true)] [string]$serverName,
    [Parameter(Mandatory=$true)] [ValidateSet("Package", "Folder", "Any")] [string]$pathType='Any'
    )

    #If serverName contains instance i.e. server\instance, convert to just servername:
    $serverName = $serverName -replace "\\.*"

    Write-Verbose "Test-ISPath path:$path serverName:$serverName pathType:$pathType"

    #Note: Don't specify instance name

    $app = new-object ("Microsoft.SqlServer.Dts.Runtime.Application") 

    switch ($pathType)
    {
        'Package' { trap { $false; continue } $app.ExistsOnDtsServer($path,$serverName) }
        'Folder'  { trap { $false; continue } $app.FolderExistsOnDtsServer($path,$serverName) }
        'Any'     { $p=Test-ISPath $path $serverName 'Package'; $f=Test-ISPath $path $serverName 'Folder'; [bool]$($p -bor $f)}
    }

} 
# ------------------------------------------ Test-ISPackage ------------------------------------------ 




# ------------------------------------------ Set-ISPackage ------------------------------------------ 
function Set-ISPackage
{
    param(
    [Parameter(Mandatory=$true)] $package,
    [Parameter(Mandatory=$true)] [string]$path,
    [Parameter(ParameterSetName="server")] [ValidateNOTNullOrEmpty()] [string]$serverName,
    [switch]$force
    )

    #If serverName contains instance i.e. server\instance, convert to just servername:
    if ($serverName)
    {   
        $serverName = $serverName -replace "\\.*" 
    }

    Write-Verbose "Set-ISPackage package:$($package.Name) path:$path serverName:$serverName"

    $app = new-object ("Microsoft.SqlServer.Dts.Runtime.Application") 

    #SQL Server Store
    if ($PSCmdlet.ParameterSetName -eq "server")
    { 
     #   if ((Test-ISPath $path $serverName 'Package') ) #si existe el paquete lo pisa
        if (!(Test-ISPath $path $serverName 'Package') -or $($force)) #si  existe el paquete sale por el ELSE
        { $app.SaveToDtsServer($package, $null, $path, $serverName) } # Sube el paquete.
        else
         { $app.SaveToDtsServer($package, $null, $path, $serverName) } # Sube el paquete.
        #{ throw "Package $path already exists on server $serverName" } # sale por error de duplicidad.
    }
    #File Store
    else
    { 
        if (!(Test-Path -literalPath $path) -or $($force))
        { $app.SaveToXml($path, $package, $null) }
        else
        { throw "Package $path already exists" }
    }
    
} 

# ------------------------------------------ Set-ISPackage ------------------------------------------ 




function Copy-ISItemFileToSQL
{
    [CmdletBinding(SupportsShouldProcess=$true)] 
    param(
        [Parameter(Mandatory=$true)] [string]$path,
        [Parameter(Mandatory=$true)] [string]$destination,
        [Parameter(Mandatory=$true)] [string]$destinationServer,
        [switch]$recurse,
        [ValidateNOTNullOrEmpty()] [string]$include="*",
        [string]$exclude=$null,
        [switch]$force,
        [hashtable]$connectionInfo,
        #Valid values are: DontSaveSensitive, EncryptSensitiveWithUserKey, EncryptSensitiveWithPassword, EncryptAllWithPassword, EncryptAllWithUserKey, ServerStorage
        [ValidateScript({[Enum]::GetNames([Microsoft.SqlServer.Dts.Runtime.DTSProtectionLevel]) -ccontains $_ })] [string]$protectionLevel
    )

    #If destinationServer contains instance i.e. server\instance, convert to just servername:
    $destinationServer = $destinationserver -replace "\\.*"

    Write-Verbose "Copy-ISItemFileToSQL path:$path destination:$destination destinationServer$desinationServer recurse:$($recurse.IsPresent) include:$include exclude:$exclude"

    
    # -------------------------------------------------   Copy-ISChildItemFileToSQL -------------------------------------------------
    function Copy-ISChildItemFileToSQL
    {
        param(
            $item, 
            [string]$path, 
            [string]$destination, 
            [string]$destinationServer, 
            [switch]$force, 
            [hashtable]$connectionInfo
        )
        #$parentPath = Split-Path $item.FullName -parent | Split-Path -leaf
        #$itemPath = $parentPath -replace "$([system.io.path]::getpathroot($item.FullName) -replace '\\','\\')"
        $itemPath =  "\" + $item.FullName  -replace ($path -replace "\\","\\") -replace $item.Name
        Write-Verbose "itemPath:$itemPath"
        $folder = $destination + $itemPath
        Write-Verbose "folder:$folder"

        if ($item.PSIsContainer)
        {
            $testPath = $($folder + $item.Name) -replace "\\\\","\"
            Write-Verbose "testPath:$testPath"
            if (!(Test-ISPath $testPath $destinationServer 'Folder'))
            {
                New-ISItem $Folder $item.Name $destinationServer
            }
        }
        else 
        {
            $destPath = $($folder + $item.BaseName) -replace "\\\\","\"
            $package = Get-ISPackage $item.FullName

            if ($package)
            {
                if ($connectionInfo)
                { 
                    Set-ISConnectionString $package $connectionInfo 
                }
      

                if ($protectionLevel)
                { 
                    $package.ProtectionLevel = [Microsoft.SqlServer.Dts.Runtime.DTSProtectionLevel]$protectionLevel 
                }
                if ($force)
                { 
                    Set-ISPackage  -package $package -path $destPath -serverName $destinationServer -force 
                }
                else
                { 
                    Set-ISPackage  -package $package -path $destPath -serverName $destinationServer 
                }
            }
        }

    } 
    # -------------------------------------------------   Copy-ISChildItemFileToSQL -------------------------------------------------


    if (Test-Path $path)
    { 
        # Solo carpeta actual y recursivamente los hijos
        if ($recurse)
        {
            $items = Get-ChildItem -path $path -include $include -exclude $exclude -recurse
            $count = $items | Measure-Object | Select Count
            foreach ($item in $items)
            { 
                if ($PSCmdlet.ShouldProcess("item: $($item.FullName) path: $path destination: $destination destinationServer: $destinationServer force: $($force.IsPresent)", "Copy-ISItemFileToSQL"))
                {
                    $i++
                    Write-Progress -activity "Copying Items..." -status "Copying $($item.Name)" -percentcomplete ($i/$count.count*100) 
                    if ($force)
                    { 
                        Copy-ISChildItemFileToSQL -item $item -path $path -destination $destination -destinationServer $destinationServer -force -connectionInfo $connectionInfo 
                    }
                    else
                    { 
                        Copy-ISChildItemFileToSQL -item $item -path $path -destination $destination -destinationServer $destinationServer        -connectionInfo $connectionInfo 
                    }
                }
            }
        }
        else
        #Incluye solocarpeta actual
        {
            $items = Get-ChildItem -path $path -include $include -exclude $exclude
            $count = $items | Measure-Object | Select Count
            foreach ($item in  $items)
            {
                if ($PSCmdlet.ShouldProcess("item: $($item.FullName) path: $path destination: $destination destinationServer: $destinationServer force: $($force.IsPresent)", "Copy-ISItemFileToSQL"))
                {
                    $i++
                    Write-Progress -activity "Copying Items..." -status "Copying $($item.Name)" -percentcomplete ($i/$count.count*100) 
                    if ($force)
                    { 
                            Copy-ISChildItemFileToSQL -item $item -path $path -destination $destination -destinationServer $destinationServer -force -connectionInfo $connectionInfo 
                    }
                    else
                    { 
                        Copy-ISChildItemFileToSQL -item $item -path $path -destination $destination -destinationServer $destinationServer          -connectionInfo $connectionInfo 
                    }
                }
            }
        }
    }
    else
    { throw "Package $path does not exist" }

} #Copy-ISItemFileToSQL

#***************************************************************************************************************************
#    MAIN
#***************************************************************************************************************************
copy-isitemfiletosql -path "C:\ImportarETL_SSPR17DWH\*" -include "*.dtsx" -destination "msdb" -destinationServer "localhost"  -Verbose -protectionLevel "DontSaveSensitive"

Move-Item C:\ImportarETL_SSPR17DWH\*.dtsx e:\ssis\ -Force
Move-Item C:\ImportarETL_SSPR17DWH\*.dtsconfig E:\SSIS.Config\ -Force


