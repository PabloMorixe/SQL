dim Sfolder
dim sdir
dim sfinal
dim sfecha

sfecha = cstr(now)
sfecha = mid(sfecha,7,4) + mid (sfecha,4,2) + left(sfecha,2) + mid(sfecha,12,2) + mid(sfecha,15,2) + mid(sfecha,18,2)
sfinal = "E:\BackupSitios\Interfaces" + sfecha
sfolder = "E:\AerolineasArgentinas\Interfaces"
sdir = "E:\BackupSitios\Interfaces"
Set FSO = CreateObject ("Scripting.FileSystemObject")
fso.CopyFolder sfolder, sdir, True
fso.movefolder sdir,sfinal
set fso = nothing

ACTIVEX SCRIPT

VISUAL BASIC SCRIPT


dim Sfolder
dim sdir
dim sfinal
dim sfecha

sfecha = cstr(now)
sfecha = mid(sfecha,7,4) + mid (sfecha,4,2) + left(sfecha,2) + mid(sfecha,12,2) + mid(sfecha,15,2) + mid(sfecha,18,2)
sfinal = "\\ARACSMS10\BackupSitios\AracsWORK" + sfecha
sfolder = "C:\inetpub\wwwroot\aracswork"
Set FSO = CreateObject ("Scripting.FileSystemObject")
fso.CopyFolder sfolder, sfinal, True
Set FSO = nothing


