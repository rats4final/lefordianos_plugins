[English](BENEFITS.md)

# Qué te da la config lite

Un resumen simple de qué cambia en el servidor y por qué es mejor, agrupado según quién lo nota. Cada
plugin, uno por uno, está en [configs/lite/PLUGINS.md](../configs/lite/PLUGINS.md); qué se hizo y cuándo
está en [CHANGELOG.es.md](../CHANGELOG.es.md).

La regla detrás de cada elección: **versus vanilla, sin sus bugs ni molestias**. Los pocos cambios de
balance que elegimos a propósito están al final.

## Partidas justas

- **Mismo tank y witch para los dos equipos** (`lef_boss_spawns`): cada mapa sortea una vez si hay tank
  y/o witch (50% cada uno por defecto), y el segundo equipo recibe la misma respuesta **en el mismo
  lugar**. En vanilla un equipo podía tener el tank antes de una caída y el otro después.
- **Todos saben dónde salen**: el panel de inicio y el chat muestran "Tank: 63%, Witch: no hay", así el
  primer equipo no se sorprende con algo que el segundo ya sabe que viene.
- **Misma ruta de escape, mismos autos con alarma y mismas clases de primer golpe de los infectados para
  los dos equipos** (correcciones del repo competitivo).
- **Turnos de tank en orden** (`l4d_tank_control_eq`) y el tank se puede pasar a un compañero que lo
  quiera (`l4d_tank_pass`).
- **Equipos parejos**:
  - nadie puede unirse al equipo que ya tiene más humanos;
  - a los que entran y a los espectadores se les dice dónde hacen falta;
  - `!wait` mantiene cerrado el refugio hasta que entre un amigo;
  - una **mezcla balanceada** reparte a los habituales por igual.
- **Un ranking** (`!rank`, `!top`) por mapas ganados, que la mezcla balanceada usa cuando los jugadores
  tienen algunos mapas.
- **Los bots no son muertes gratis**: los bots sobrevivientes reciben 15% menos daño de los jugadores
  infectados.

## Menos bugs y exploits

Unas 80 correcciones del repo competitivo (el `generalfixes` de ZoneMod), Harry Potter, MoYu, Lux y
Silvers. Algunas que los jugadores van a notar:
- **Empujones, tambaleos y levantarse**: funcionan siempre igual, como la dirección del empujón, la del
  tambaleo y cómo se levanta Ellis.
- **Habilidades de los infectados**: las lenguas no se cortan ni flotan; chargers, jockeys y boomers
  pierden una docena de bugs.
- **Tank**: el tank no se congela; las rocas y golpes pegan a quien deben; los finales no se saltan
  etapas de tank.
- **Witch**: mantiene su objetivo correcto y no se traba.
- **Desfibriladores y objetos**: los desfibriladores no fallan; las pastillas mal pasadas vuelven; las
  armas no se pueden sacar de más.
- **Exploits bloqueados**: saltos cohete, teletransportes de fantasma, daño después de cambiar de
  equipo, granadas infinitas, revivir en el aire, el spam de deadstop después del jockey, y otros.
- **Estabilidad del servidor**: arreglos de crasheos, desbordes de buffer que reseteaban cvars sin
  avisar, spam de consola.

## Información mientras juegas

- `!score` explica el puntaje: cuánto vale este mapa, la diferencia y lo que todavía se puede.
- Reporte de daño al tank, MVP de sobrevivientes y estadísticas al final de cada ronda.
- **Quién hizo qué**: quién tiró una molotov o una bilis, quién explotó un bidón, quién desplegó munición,
  quién abrió el refugio y quién lo cerró dejando compañeros afuera, karma kills.
- **Aparición de witches**: se anuncia en el chat con su propio sonido (la música de la witch), distinto
  al del tank.
- **Recordatorios del tank**: mientras falta el tank, el chat recuerda dónde aparece cada 2 minutos, y
  avisa cuando los sobrevivientes se acercan.
- **Jugadas destacadas** en el chat: skeets, crowns, deadstops, pops, levels, death charges y más.
- **Quién votó**: después de cada votación, la lista de quién votó Sí y quién votó No.
- **Avisos, nunca castigos**: avisos a los que rushean, a los que se quedan atrás y a los infectados
  guardados mucho tiempo, y consejos para los que juegan de tank.

## Más fácil para todos

- **Inglés y español en todo**: los menús y mensajes siguen el idioma del juego de cada jugador, incluido
  el "Español - Latinoamérica" de Steam.

- **`!menu`**: todos los comandos para jugadores en un solo lugar, para que nadie tenga que memorizarlos.
- **`!votes`**: la pantalla de votación del propio juego para:
  - cambiar de mapa, reiniciar, elegir la próxima campaña;
  - mezclar o balancear equipos;
  - expulsar a un troll (con baneo de 5 minutos, como en vanilla);
  - mover a un AFK, silenciar la voz, el chat o ambos de alguien hasta que termine la ronda;
  - prender o apagar el modo T1, subir o bajar la probabilidad de tank/witch;
  - la voz entre equipos;
  - pausar (solo por votación, así los randoms no abusan).
- **Unirse a equipos**: `!survivors`, `!infected`, `!afk` con reglas razonables contra abusos. Los
  espectadores siguen de espectadores entre mapas.
- **Sin escenas de introducción** en los primeros mapas; **rotación de campañas**, con la próxima
  campaña votada en la pantalla de votación del juego (`!votes`) y mostrada con `!next`.
- **Quad caps** posibles (cuatro infectados que agarran a la vez), como en ZoneMod: un cambio elegido.
- Pasar pastillas con Recargar; los objetos golpeables brillan mientras hay tank; los cadáveres de los
  comunes desaparecen.

## Para los admins

- **`!admin`** tiene:
  - *Team Management*: mover, intercambiar, invertir, mezclar, mezcla balanceada, restaurar los equipos
    de la ronda pasada;
  - *Lefordianos*: hacer cualquier opción de votación al instante, forzar pausa/quitar pausa, aprobar o
    cancelar una votación.
- **`!heal` / `!restore`** deshacen el griefing: daño de equipo, derribos, muertes por compañeros y
  objetos perdidos.
- Ajustes por modo de juego en archivos simples (`cfg/sourcemod/gamemode_cvars/<modo>.cfg`), sin
  confogl.
- Mensajes del servidor y de conexión, con traducciones.

## Antitrampas

- **SMAC** y **Little Anti-Cheat** (Little Anti-Cheat al principio solo registra).
- **Ajustes del cliente**: revisa los 59 ajustes del cliente que revisa ZoneMod (brillo total, sin
  niebla, cambios a la linterna...).
- **Espiar y wallhacks**: bloquea mirar en tercera persona y el wallhack "mat_hack", y oculta a los
  infectados fantasma de los wallhacks.
- **Addons del workshop apagados** para todos (`l4d2_addons_eclipse 0`): algunos dan ventaja (mapas más
  claros, props transparentes). Los jugadores pierden sus skins en este servidor.
- **Baneos de Steam**: avisa a los admins cuando alguien que entra tiene baneos VAC, de juego o de
  comunidad. Solo mira baneos: ni horas ni perfil.

## Cambios de balance que elegimos a propósito

Estos cambian vanilla, así que se listan con honestidad. Cada uno se puede apagar en `PLUGINS.md` o en
su config:
- **Probabilidad de tank y witch**: 50% cada uno por mapa, igual para los dos equipos (vanilla usa sus propias
  probabilidades).
- **Bots sobrevivientes**: reciben 15% menos daño de los jugadores infectados.
- **Elecciones de juego de ZoneMod**:
  - sin bunny-hop, jockeys más ruidosos, orden fijo de aparición de infectados, sin spitter mientras hay
    tank;
  - los infectados recuperan vida al desaparecer;
  - autos con alarma iguales;
  - quad caps posibles (`l4d2_dominators 0`);
  - una horda forzada si los infectados esperan demasiado para atacar;
  - algunos ajustes del tank.
- **Cambios de mapas**: las correcciones de mapas de Stripper de ZoneMod (exploits bloqueados, lugares
  donde trabarse, algunos props y objetos), sin sus reworks especiales de eventos. Los tanks y witches
  programados se mantienen.
