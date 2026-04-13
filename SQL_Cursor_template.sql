Crear un Cursor

Con este truco sabrás construir un cursor paso a paso. Debemos recordar que no hay que abusar de los cursores ya que son costosos para el servidor SQL Server.

-- Declaramos una Variable donde se guardará los ID’s

DECLARE @Variable numeric


DECLARE NombreDelCursor CURSOR FAST_FORWARD
FOR

-- Realizamos la consulta que queremos guardar en la variable

SELECT
[ID]
FROM
[Tabla]
With(NoLock)

-- Abrimos el cursor
OPEN NombreDelCursor

FETCH NEXT FROM NombreDelCursor INTO
@ Variable

WHILE (@@FETCH_STATUS <> -1)
BEGIN
IF (@@FETCH_STATUS <> -2)
BEGIN

-- Hacemos un print para ver que la variable es correcta (Solo es a nivel de comentario, para probar que funciona, cuando funcione quitamos esta linea del print @Variable
print @ Variable

--Realizar las tareas deseadas, como updatear los usuarios, caducarlos, etc… (Podemos llamar a otros storeds…)

UPDATE
Tabla
With(RowLock)
SET
Estado=2
WHERE
IdUsuario=@Variable
END

--Accedemos al siguiente registro del cursor
FETCH NEXT FROM NombreDelCursor INTO
@ Variable
END

--Cerramos el cursor
CLOSE NombreDelCursor

-- lo sacamos de la memoria
DEALLOCATE NombreDelCursor