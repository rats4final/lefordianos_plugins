[English](CONNECTION.md)

# Problemas de conexión

Errores que aparecen al entrar al servidor, lo que averiguamos de cada uno y qué hacer. Casi todo se
aprendió en el servidor del dueño en octubre de 2026 (Windows, con el server en la misma PC donde juega
el dueño).

## "No Steam logon" / "STEAM validation rejected"

**Qué es:** el servidor le pide a Steam que confirme a cada jugador. Si Steam no contesta a tiempo,
echa al jugador. El 2026-10-03 echó a cuatro jugadores en el mismo segundo: el que perdió la conexión
con Steam fue el **servidor**, no cada jugador.

**Qué hicimos:** el l4dtoolz de lakwsh viene en el paquete lite con `sv_steam_bypass 1`, así el
servidor deja de preguntarle a Steam. Desde entonces no volvió. El costo está en
`cfg/server.example.cfg`: los SteamID ya no se verifican con Steam.

**Revisar que esté prendido:** en la consola del server, `plugin_print` muestra **L4DToolZ** y
`sv_steam_bypass` dice `1`.

### Lo que dicen el código del juego y nuestros logs (2026-10-08)

**Estado: la causa sigue siendo sospecha; el bypass evita los kicks.**

**Cómo funciona** (leído del `engine.dll` del server): cuando entra un jugador, el server revisa su
ticket de Steam en el momento (el log dice `STEAM USERID validated`) y le pide a los servidores de Steam
que lo confirmen. La respuesta de Steam llega después. Si es un "no", el server escribe
`STEAMAUTH: Client <nombre> received failure code <N>` y echa al jugador. Cuatro respuestas distintas
dan el mismo mensaje, "No Steam logon":

| Código | Respuesta de Steam |
|---|---|
| 1 | El jugador no está conectado a Steam |
| 6 | El juego del jugador canceló el ticket |
| 7 | El ticket ya se usó |
| 8 | El ticket no es válido (no es de una sesión de Steam que esté en línea ahora) |

(Código 2 = "does not own this game", 3 = "VAC banned", 4 = "being used in another location", 5 =
"Client timed out".) La única forma en que el motor no echa es el modo LAN (`sv_lan 1`, o si Steam no
carga). `-insecure` no ayuda: solo apaga VAC, a los jugadores se los sigue revisando.

**Lo que muestran nuestros logs** (`left4dead2/logs/`, del 2026-10-02 al 10-05):
- 14 kicks, **todos en una ventana de 52 minutos** (2026-10-03 23:13 a 10-04 00:05). Antes: ninguno
  (una noche entera con la instalación vieja de ZoneMod, 16 mapas, más las pruebas de la tarde).
  Después: tampoco, pero l4dtoolz se copió al server a las 00:02, así que desde ahí puede ser el bypass
  lo que los esconde.
- 13 de 14 fueron **código 8**, uno código 6.
- Llegaron en **tandas: hasta 6 jugadores en el mismo segundo, 1.5 a 2 minutos después de que empezaba
  un mapa** (mapa a las 23:13:00, kicks 23:14:32; 23:49:56 → 23:51:47; 23:55:22 → 23:56:53;
  00:03:28 → 00:05:20).
- Amigos en lugares distintos recibieron código 8 en el mismo momento, y también el dueño, que juega en
  la misma PC del server.

**Hacia dónde apunta (sospecha):** cuando a muchos jugadores sin relación entre sí les dicen "ticket
inválido" a la vez, el problema está **del lado del server en la conversación con Steam**: la conexión
del server con Steam (la PC y el internet del dueño) se cortó o se reconectó en esa ventana, y Steam dejó
de aceptar los tickets que tenía el server. Una caída corta de Steam se vería igual. No es un plugin
(ninguno de los nuestros toca la autenticación de Steam) ni el internet de los jugadores.

**Por qué ya no se puede ver:** con `sv_steam_bypass 1`, l4dtoolz toma el SteamID del ticket del jugador
y le dice al juego que es válido sin preguntarle a Steam, así que no hay respuesta que anotar. Lo único
que todavía muestra que el server perdió Steam es la consola: el motor escribe
`Connection to Steam servers lost.` y después `Connection to Steam servers successful.` Esas líneas van
solo a la consola, no a `logs/`. Para guardarlas, arranca el server con `-condebug` (escribe
`left4dead2/console.log`) y busca "Steam servers" ahí después de una noche con problemas.

## "Duplicate client connection" y después "STEAM validation rejected"

El servidor todavía tiene una conexión vieja de esa cuenta (se cerró el juego o el jugador volvió a
entrar muy rápido). Espera un minuto y reintenta, o búscala con `status` y échala con
`kickid <userid>`. El `UserID` del mensaje está en hexadecimal (`f` = 15).

## "Reservation request with bogus payload data" cuando el dueño inicia la sala

**Estado: sospecha fuerte, todavía no confirmada (2026-10-04).** Hay que seguir viéndolo en las
próximas partidas.

**Síntoma:** cuando el dueño (cuya PC también corre el server) crea la sala e inicia la partida, a
veces falla y a veces no. Cuando la inicia un amigo, funciona siempre. La consola del server muestra:

```
ReplyReservationRequest:  Reservation request with bogus payload data from 192.168.0.8:27005 [512 bytes]
```

**Lo que hace el código del juego** (leído del `engine.dll` del server):
1. El juego del líder de la sala le pide al server un número secreto (un "challenge"). El server
   elige uno y lo anota **para la IP que lo pidió** (solo la IP, no el puerto).
2. El juego del líder manda la reserva cerrada (cifrada) con ese número.
3. El server la abre con el número que tiene anotado **para la IP desde la que llegó la reserva** y
   busca una marca fija adentro (`0xFEEDBEEF`). Si no está: "bogus payload data". ("bogus payload size"
   es otra revisión: vacío, más de 1024 bytes, o no es múltiplo de 8.)

O sea, el error significa que la reserva llegó desde una IP distinta de la que recibió el número.

**Por qué al dueño:** la PC del dueño puede llegar al server por dos caminos: directo por la red
local (el server ve `192.168.0.8`), o saliendo a la IP pública y volviendo a entrar por el router (el
server ve otra dirección). A veces el juego pide el número por un camino y manda la reserva por el
otro: es una carrera, por eso falla a veces. Los amigos solo tienen el camino público, así que siempre
coincide.

**Lo que parece arreglarlo:** cerrarle el camino largo solo a la PC del dueño, para que el juego solo
pueda usar el local. PowerShell como administrador (con la IP pública del server, el "WAN IP" del router):

```powershell
New-NetFirewallRule -DisplayName "L4D2 bloquear vuelta por IP publica" -Direction Outbound -Protocol UDP -RemoteAddress <IP publica> -RemotePort 27016 -Action Block -Profile Any
```

A los amigos no les afecta (la regla solo existe en la PC del dueño). Windows no puede bloquear el
camino local en su lugar: su firewall no filtra el tráfico de una PC hacia sí misma. Primera prueba
(2026-10-04): no salió la línea "bogus", solo `-> Reservation cookie ...: reason ReplyReservationRequest`,
y el dueño entró.

**Si cambia la IP pública** (el proveedor puede cambiarla), hay que volver a crear la regla con la
nueva. **Si con la regla el dueño no puede entrar de ninguna forma**, se borra:

```powershell
Remove-NetFirewallRule -DisplayName "L4D2 bloquear vuelta por IP publica"
```

**Falta confirmar:** que "bogus" no vuelva en varias noches de juego con el dueño iniciando. Si vuelve,
anotar la IP después de "from" y los bytes.

**Otras cosas probadas:** `mm_dedicated_force_servers` con la IP pública funcionó un día y otro no
(cuadra con la carrera). Con la IP local, la sala queda solo para LAN y los amigos no pueden entrar.
El DMZ del router no hace falta para esto; dejarlo apagado.

## "La sesión ya no está disponible" con `connect`

Probablemente el server sigue apartado ("reservado") por una sala que no logró entrar. Espera más o
menos un minuto, o escribe `sv_cookie 0` en la consola del server (un comando de l4dtoolz que suelta
la reserva). Pon siempre el puerto: `connect <IP>:27016`; sin él, el juego busca el 27015.

## "Server is enforcing consistency for this file: addons/..."

**Estado: lo encontró el dueño (2026-10), el arreglo funciona.**

**Síntoma:** a un jugador lo echan al entrar con un mensaje como
`Server is enforcing consistency for this file: addons/bigwatnight.vpk` (el nombre cambia según la
campaña).

**Por qué:** el servidor corre con `sv_consistency 1` (en `server.cfg`), así que compara los archivos
de addons que carga el jugador con los suyos. La comparación va por **ruta**: si el servidor tiene la
campaña en una ruta y el jugador en otra (por ejemplo `addons/workshop/3122417079.vpk` del Workshop de
un lado, y un `addons/bigwatnight.vpk` copiado a mano del otro), no coincide y echa al jugador, aunque
sea la misma campaña.

**Arreglo:** usar **la misma ruta para el addon en el servidor y en el juego de cada jugador**. Lo más
fácil es que los dos usen la copia del Workshop (`addons/workshop/<id>.vpk`): los jugadores se
suscriben en el Workshop, y el servidor tiene el mismo archivo en `addons/workshop/`. Si un jugador
copió el archivo a mano, lo borra y se suscribe (o los dos usan el mismo nombre de archivo en `addons/`).

`sv_consistency 0` también evitaría que lo echen, pero entonces no se revisan los archivos de nadie
(entran modelos o materiales modificados, por ejemplo paredes transparentes). No recomendado.
