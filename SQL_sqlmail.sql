Una vez que lo tengas, configura la cuenta para el usuario que corre el servicio de SQL Agent y SQL Server y has
 pruebas de enviar mail desde Outlook

Si eso sale bien entonces configura SQL Mail para que tome esa cuenta de mail (que sea la misma cuenta de windows 
no es suficiente), eso lo encuentras en las propiedades del SQL Agent y en Support Services->SQL Mail->Propiedades
 en tu servidor (en el Enterprise Manager)

Si todo ha salido bien debes de poder usar el boton Test y obtener un mensaje exitoso, y enviar mails de la manera 
tradicional.

En el peor de los casos tienes la alternativa de instalar un mail por SMTP, mucho más sencillo de trabajar, pero
 más complicado de integrar al no ser parte del SQL Server.
Hola Mithrandir:
Ya tengo configurado todo para el SQL Mail..ya pude realizar el TEST y si tengo comunicacion(me llego el correo de
 prueba) Gracias...
pero ahora biene lo bueno jee, como le hago para que me lleguen alertas, en mi caso, de los LOGS cuando estos
 llegan a su maximo tamaño (limitado) o antes de que esto suceda?
en el Enterprise Manager, cree una nueva alerta de tipo
 "SQL Server event alert" con el numero de error 9002 (log full) y que revisa una base de datos especifica y que
 le deberia enviar el correo de alerta al Operador, pero estube trabajando con la base de datos para hacer crecer 
el log y aun cuando llego al límite no recibi el correo.
Operador-Correo electronico al que el SQL mail le enviara la alerta.
SQL AGENT- Start
Distributed Trans...-start

no se que mas haga falta por configurar... 
Saludos
Haz la prueba de configurar un JOB que avise al operador cuando termine, si te llega sin problemas es que el Agent 
ya tiene la sesión de mail funcionando sin problemas.

Si es el caso entonces prueba con diferentes tipos de alertas, quizá simplemente la has creado/configurado mal.
 También activa que envíe un net send a tu máquina, de esa manera sabrás que el aviso se genera con el alert y es
 el mail donde se atora.

*******************************************
SQL Server 2000 al igual que su versiones anteriores 6.5 y 7.0 tiene incorporado un servicio de mensajería o de 
mail que es muy sencillo de configurar y utilizar. Con este servicio de correo podemos añadir prestaciones a
nuestro servidor SQL Server y a nuestras bases de datos, utilizandolo para enviar mensajes desde nuestros propios 
programas asociados a una base de datos a través de Storeds Procedures.   
 
     
  Configuración

La instalación es sencilla, el SQL Mail es parte del sistema del SQL Server y por lo tanto se instala cuando 
instalas el SQL Server (imagen 1). 

SQL Mail para su funcionamiento requiere tener instalado el Microsoft Outlook porque para enviar mails utiliza 
una cuenta de correo de Microsoft Outlook. 

*******************************************

tecnologia@ceicomgroup.com

Para configurarlo hay que seguir los siguientes pasos:

1. Asociar una cuenta de correo del Outlook 2000 a través de las propiedades del SQL Server Agent (imagen 2).
2. Asociar la misma cuenta de correo a través del SQL Mail (imagen 3)

Probamos la cuenta pulsando el botón “test” y con esto ya tenemos el SQL Mail configurado y listo para trabajar.

¿ Como trabaja y que podemos hacer con SQL Mail ?.

SQL Mail tiene asociados en la base de datos Master 7 Extended Procedures, de ellos el más utilizado es el 
xp_sendmail utilizado para enviar mails.

- xp_startmail : Inicializa el SQL Mail.
- xp_stopmail : Lo detiene.
- xp_findnextmsg : Se utiliza con sp_processmail para procesar mensajes de correo en el buzón de SQL Mail.
- xp_readmail : Lee mensajes del buzón de correo.
- xp_deletemail: Borra un mail con un id especifico.
- xp_sendmail : Envía un mensaje
- sp_processmail : Utiliza procedimientos almacenados extendidos (xp_findnextmessage, xp_readmail y xp_deletemail)
para procesar mensajes de correo de entrada.

Estos Extended Procedures almacenados en la base de datos Master podemos utilizarlos desde cualquier base de datos 
siempre que los llamemos correctamente desde nuestros Storeds Procedures en nuestra base de datos, por ejemplo, si 
tengo una base de datos llamada UTILES y un Stored Procedure de esa base de datos quiere utilizar el envió de mails debería hacerlo de la siguiente manera:

Master.dbo.xp_sendmail

Ejemplo de envio :

Create Procedure Enviar_mails
As 
Exec master.dbo.xp_sendmail 
@recipients = ‘email@detino.com’, 
@subject = 'titulo del mensaje',
@message = ‘cuerpo del mensaje’
 
