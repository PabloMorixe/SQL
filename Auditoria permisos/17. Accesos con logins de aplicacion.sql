SELECT MIN(starttime), MAX(starttime)
FROM TRACE..TRAZAS



--Accesos con herramientas de desarrollo usando logins de Aplicación
--para todo el período auditado disponible
SELECT EventClass, NTUserName, NTDomainName, HostName, ApplicationName, LoginName, Starttime, ServerName
FROM TRACE..TRAZAS
WHERE EVENTCLASS = 14 AND
        ((APPLICATIONNAME = 'SQL Query Analyzer') OR
        (APPLICATIONNAME LIKE 'MS SQLEM%') OR
        (APPLICATIONNAME LIKE 'Analizador de consultas SQL%') OR
        (APPLICATIONNAME = 'Administrador corporativo de SQL Server') OR
        (APPLICATIONNAME = 'Visual Basic') OR
        (APPLICATIONNAME LIKE 'Microsoft SQL Server %') OR
        (APPLICATIONNAME LIKE 'Microsoft_ Query'))
AND ApplicationName <> 'Microsoft SQL Server VSS Writer'
AND ApplicationName <> 'Microsoft SQL Server JDBC Driver'
AND ApplicationName <> 'Microsoft SQL Server Analysis Services'
AND LoginName NOT IN('CENTRAL\ghakimian', 
					 'CENTRAL\mcitterio', 
					 'CENTRAL\cchimale', 
					 'CENTRAL\mayer', 
					 'CENTRAL\ccmartinez', 
					 'CENTRAL\cepeda',
					 'CENTRAL\cgarat',
					 'CENTRAL\ctoledo',
					 'CENTRAL\DGuevara',
					 'CENTRAL\DSALAS',
					 'CENTRAL\HDACOSTA',
					 'CENTRAL\LACISNEROS',
					 'CENTRAL\LJPORCAL',
					 'CENTRAL\TEJERINA',
					 'CENTRAL\MABAL',
					 'CENTRAL\cuadri',
					 'CENTRAL\IGEMMSA1',
					 'CENTRAL\JHFUENTES',
					 'CENTRAL\ROLDAN',
					 'CENTRAL\jherrera',
					 'CENTRAL\GDawidiuk',
					 'CENTRAL\EBazterrica',
					 'CENTRAL\emorana',
					 'CENTRAL\BAlday',
					 'CENTRAL\FItaliano',
					 'CENTRAL\SACCA',
					 'CENTRAL\FESCUTARY',
					 'CENTRAL\XSerantes',
					 'CENTRAL\SVITALE',
					 'CENTRAL\EVila',
					 'CENTRAL\scardino',
					 'CENTRAL\ABoniscontro',
					 'CENTRAL\APallavidini',
					 'CENTRAL\FCACERES',
					 'CENTRAL\subeid',
					 'CENTRAL\oliver',
					 'central\castellr',
					 'CENTRAL\jcledesma',
					 'CENTRAL\dcalbosa',
					 'CENTRAL\DJaime',
					 'CENTRAL\mcasco',
					 'CENTRAL\FGodoy',
					 'CENTRAL\ldevescovi',
					 'CENTRAL\wmoreno',
					 'CENTRAL\VLina',
					 'SOPORTE_EMMSA',
					 'CENTRAL\JOtero',
					 'CENTRAL\EMiremont',
					 'CENTRAL\MRapallini',
					 'CENTRAL\JYEDRO',
					 'CENTRAL\JESalinas',
					 'CENTRAL\RNGomez',
					 'CENTRAL\ddignazi',
					 'CENTRAL\Rodrigom',
					 'CENTRAL\DTolaba',
					 'CENTRAL\CDiSimone',
					 'CENTRAL\JavQuiroga',
					 'CENTRAL\HRegazzoni',
					 'CENTRAL\MArias',
					 'CENTRAL\ANosenzo',
					 'CENTRAL\MReyes',
					 'CENTRAL\ATorres',
					 'CENTRAL\ARegina',
					 'CENTRAL\FBosnjak',
					 'CENTRAL\CLepez',
					 'CENTRAL\FBrizzi',
					 'CENTRAL\MaCastro')
--AND STARTTIME > getdate()
ORDER BY STARTTIME