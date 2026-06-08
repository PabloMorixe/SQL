#***************************************************************************************************************************
#     LIBRERIAS SMO / SSIS USADAS
#***************************************************************************************************************************
#---------------------------------
# SQL SERVER 2017
#---------------------------------
Add-Type -AssemblyName "Microsoft.SqlServer.ManagedDTS, Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -ErrorAction Stop
$smoVersion = 14

cls

#***************************************************************************************************************************
#     FUNCION: Get-RelativePath
#     Obtiene el path relativo de un archivo/carpeta respecto a un path base
#***************************************************************************************************************************
function Get-RelativePath {
    param (
        [string]$BasePath,
        [string]$FullPath
    )

    $base = (Resolve-Path $BasePath).Path.TrimEnd('\')
    $full = (Resolve-Path $FullPath).Path

    return $full.Substring($base.Length).TrimStart('\')
}

#***************************************************************************************************************************
#     FUNCION: Get-ISPackage
#     Carga un paquete SSIS desde FILE SYSTEM
#***************************************************************************************************************************
function Get-ISPackage {
    param(
        [Parameter(Mandatory=$true)] [string]$path
    )

    Write-Verbose "Cargando paquete desde: $path"

    $app = New-Object "Microsoft.SqlServer.Dts.Runtime.Application"
    $name = [System.IO.Path]::GetFileNameWithoutExtension($path)

    if (Test-Path -LiteralPath $path) {
        $app.LoadPackage($path, $null) |
            Add-Member -MemberType NoteProperty -Name DisplayName -Value $name -PassThru
    }
    else {
        Write-Error "El paquete $path no existe"
    }
}

#***************************************************************************************************************************
#     FUNCION: Test-ISPath
#     Verifica si un PACKAGE o FOLDER existe en MSDB
#***************************************************************************************************************************
function Test-ISPath {
    param(
        [Parameter(Mandatory=$true)] [string]$path,
        [Parameter(Mandatory=$true)] [string]$serverName,
        [ValidateSet("Package", "Folder", "Any")] [string]$pathType='Any'
    )

    $serverName = $serverName -replace "\\.*"
    $app = New-Object "Microsoft.SqlServer.Dts.Runtime.Application"

    switch ($pathType) {
        'Package' { trap { $false; continue } $app.ExistsOnDtsServer($path,$serverName) }
        'Folder'  { trap { $false; continue } $app.FolderExistsOnDtsServer($path,$serverName) }
        'Any'     {
            $p = Test-ISPath $path $serverName 'Package'
            $f = Test-ISPath $path $serverName 'Folder'
            [bool]($p -bor $f)
        }
    }
}

#***************************************************************************************************************************
#     FUNCION: New-ISItem
#     Crea un FOLDER en MSDB
#***************************************************************************************************************************
function New-ISItem {
    param(
        [Parameter(Mandatory=$true)] [string]$parent,
        [Parameter(Mandatory=$true)] [string]$name,
        [Parameter(Mandatory=$true)] [string]$serverName
    )

    Write-Verbose "Creando folder MSDB: $parent\$name"
    $app = New-Object "Microsoft.SqlServer.Dts.Runtime.Application"
    $app.CreateFolderOnDtsServer($parent, $name, $serverName)
}

#***************************************************************************************************************************
#     FUNCION: Set-ISPackage
#     Sube un paquete a MSDB
#***************************************************************************************************************************
function Set-ISPackage {
    param(
        [Parameter(Mandatory=$true)] $package,
        [Parameter(Mandatory=$true)] [string]$path,
        [string]$serverName,
        [switch]$force
    )

    $serverName = $serverName -replace "\\.*"
    $app = New-Object "Microsoft.SqlServer.Dts.Runtime.Application"

    # Siempre sobreescribe (comportamiento original respetado)
    $app.SaveToDtsServer($package, $null, $path, $serverName)
}

#***************************************************************************************************************************
#     FUNCION PRINCIPAL: Copy-ISItemFileToSQL
#     Copia paquetes SSIS desde FILE SYSTEM a MSDB respetando estructura
#***************************************************************************************************************************
function Copy-ISItemFileToSQL {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)] [string]$path,
        [Parameter(Mandatory=$true)] [string]$destination,
        [Parameter(Mandatory=$true)] [string]$destinationServer,
        [switch]$recurse,
        [string]$include="*.dtsx",
        [string]$exclude=$null,
        [switch]$force,
        [ValidateScript({[Enum]::GetNames([Microsoft.SqlServer.Dts.Runtime.DTSProtectionLevel]) -ccontains $_ })]
        [string]$protectionLevel
    )

    $destinationServer = $destinationServer -replace "\\.*"

    # Obtiene archivos .dtsx (recursivo o no)
    $items = Get-ChildItem -Path $path -Include $include -Exclude $exclude -Recurse:$recurse -File
    $count = $items.Count
    $i = 0

    foreach ($item in $items) {
        $i++
        Write-Progress -Activity "Importando paquetes SSIS" `
                       -Status "Procesando $($item.Name)" `
                       -PercentComplete ($i / $count * 100)

        # Ruta relativa
        $relativePath = Get-RelativePath -BasePath $path -FullPath $item.FullName
        $relativeDir  = Split-Path $relativePath -Parent

        # Crear folders en MSDB si existen
        $current = $destination
        if ($relativeDir) {
            foreach ($folder in ($relativeDir -split '\\')) {
                $current = "$current\$folder"
                if (!(Test-ISPath $current $destinationServer 'Folder')) {
                    New-ISItem (Split-Path $current -Parent) $folder $destinationServer
                }
            }
        }

        # Cargar y subir paquete
        $package = Get-ISPackage $item.FullName
        if ($protectionLevel) {
            $package.ProtectionLevel = [Microsoft.SqlServer.Dts.Runtime.DTSProtectionLevel]$protectionLevel
        }

        $destPath = "$current\$($item.BaseName)"
        Set-ISPackage -package $package -path $destPath -serverName $destinationServer -force
    }
}

#***************************************************************************************************************************
#     MAIN
#***************************************************************************************************************************
Copy-ISItemFileToSQL `
    -path "C:\ImportarETL" `
    -include "*.dtsx" `
    -destination "msdb" `
    -destinationServer "localhost" `
    -recurse `
    -Verbose `
    -protectionLevel "DontSaveSensitive"

Move-Item C:\ImportarETL\*.dtsx     E:\SSIS\        -Force
Move-Item C:\ImportarETL\*.dtsconfig E:\SSIS.Config -Force
