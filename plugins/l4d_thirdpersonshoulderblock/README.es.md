[English](README.md)

# l4d_thirdpersonshoulderblock (parchado)

**Thirdpersonshoulder Block** de Don, del repo L4D2-Competitive-Rework
(`addons/sourcemod/scripting/l4d_thirdpersonshoulderblock.sp`, versión 1.5). Cada pocos segundos revisa si
algún jugador de un equipo tiene la cámara en tercera persona (`c_thirdpersonshoulder`), que deja mirar por
encima de las esquinas. Con `l4d_tpsblock_action 1` (por defecto) lo pasa a espectadores; con 0, lo expulsa.

## Nuestro cambio (1.5-lef1)

El original solo decía "Para poder jugar ingrese c_thirdpersonshoulder 0 en su consola" en el chat, justo
cuando lo movía, así que la gente no sabía **por qué** estaba en espectadores. Ahora al jugador se le dice
en el chat **y en el cuadro de pantalla** que es porque tiene la tercera persona activada (o su juego oculta
esa cvar), qué escribir (`c_thirdpersonshoulder 0`) y cómo volver (`!survivors` / `!infected`). Frases en
inglés y español en `translations/`.

Nada más cambió.
