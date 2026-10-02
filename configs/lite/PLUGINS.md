# Lite config: plugin picker · Config lite: selector de plugins

> One file in both languages, so the ticks stay in one place. Each item has the English line first
> and the Spanish line (*ES*) under it.
> Un solo archivo en ambos idiomas, para que las marcas estén en un solo lugar. Cada ítem tiene
> primero la línea en inglés y debajo la línea en español (*ES*).

Tick what you want (`[x]`), untick what you don't (`[ ]`). My suggestions are pre-ticked: bug fixes
and quality-of-life are on, anything that **changes how the game plays** is off.
*ES: Marca lo que quieras (`[x]`) y desmarca lo que no (`[ ]`). Mis sugerencias ya vienen marcadas:
las correcciones de bugs y las mejoras de comodidad están activadas; todo lo que **cambia cómo se
juega** está desactivado.*

How to read the notes · *Cómo leer las notas*:
- **needs X**: requires another plugin or extension to be installed (they ship with the competitive repo).
  *ES: **needs X** = necesita otro plugin o extensión instalado (vienen con el repo competitivo).*
- **ZoneMod tunes it**: ZoneMod changes this plugin's settings. In the lite config we'd use the
  plugin's own defaults unless you say otherwise; the note says what the default does.
  *ES: **ZoneMod tunes it** = ZoneMod cambia la configuración de este plugin. En la config lite
  usaríamos los valores por defecto del plugin salvo que digas lo contrario; la nota dice qué hace
  el valor por defecto.*
- Where it lives: `optional/`, `fixes/`, `anticheat/` = `L4D2-Competitive-Rework/addons/sourcemod/plugins/<folder>/`;
  **Harry** = `L4D1_2-Plugins` (comes compiled); **MoYu** = `MoYu_Server_Stupid_Plugins/The Last Stand`
  (source only, we'd compile it with `build.sh`).
  *ES: Dónde está: `optional/`, `fixes/`, `anticheat/` = `L4D2-Competitive-Rework/addons/sourcemod/plugins/<carpeta>/`;
  **Harry** = `L4D1_2-Plugins` (ya viene compilado); **MoYu** = `MoYu_Server_Stupid_Plugins/The Last Stand`
  (solo código fuente, lo compilaríamos con `build.sh`).*

---

## 1. Required base (always on) · Base requerida (siempre activa)

- [x] `left4dhooks`: the library almost everything below uses.
  *ES: la librería que usa casi todo lo de abajo.*
- [x] Extensions from the competitive repo: `sourcescramble`, `collisionhook`, `actions`,
      `builtinvotes`. Several fixes need one of these; installing all four is simplest.
  *ES: extensiones del repo competitivo. Varias correcciones necesitan alguna; instalar las cuatro es lo más simple.*
- [x] `optional/l4d2lib`: helper library used by a few plugins.
  *ES: librería auxiliar que usan algunos plugins.*
- [x] SourceMod's base plugins: admin menu, bans, basic commands, comms, player commands, fun commands.
  *ES: plugins base de SourceMod: menú de admin, baneos, comandos básicos, chat/voz, comandos de jugador, comandos divertidos.*
- [x] **`lef_teams_panel`** (ours): `!teams`, `!swapwith`, Team Management admin menu.
  *ES: (nuestro) `!teams`, `!swapwith` y el menú de admin "Gestión de equipos".*

## 2. Bug fixes (from the competitive repo's `generalfixes.cfg`) · Correcciones de bugs (del `generalfixes.cfg` del repo competitivo)

These fix engine/game bugs and keep the vanilla behaviour the game *meant* to have.
*ES: Corrigen bugs del motor/juego y mantienen el comportamiento vanilla que el juego *debería* tener.*

**Crashes, server stability, console · Crasheos, estabilidad del servidor, consola**
- [x] `fixes/l4d2_null_cusercmd_fix`: prevents a lag-compensation server crash. *needs sourcescramble*
  *ES: evita un crasheo del servidor relacionado con la compensación de lag.*
- [x] `fixes/l4d2_hltv_crash_fix`: blocks an exploit that crashes servers.
  *ES: bloquea un exploit que crashea servidores.*
- [x] `fixes/command_buffer`: fixes "Cbuf_AddText: buffer overflow", which makes cvars silently reset to defaults.
  *ES: corrige "Cbuf_AddText: buffer overflow", que hace que los cvars vuelvan a su valor por defecto sin avisar.*
- [x] `fixes/l4d2_script_cmd_swap`: safer replacement for the `script` command.
  *ES: reemplazo más seguro del comando `script`.*
- [x] `fixes/l4d_console_spam`: hides useless errors in the server console.
  *ES: oculta errores inútiles en la consola del servidor.*
- [x] `fixes/sv_consistency_fix`: fixes several `sv_consistency` issues.
  *ES: corrige varios problemas de `sv_consistency`.*
- [x] `fixes/l4d2_fix_changelevel`: fixes problems when the map is changed by command/vote.
  *ES: corrige problemas al cambiar de mapa por comando o votación.*
- [x] `fixes/l4d_votepoll_fix`: correct number of eligible voters in votes.
  *ES: cuenta bien cuántos jugadores pueden votar.*
- [x] `fixes/bequiet`: hides "X changed name" / cvar-change spam, and stops spectators' chat
      reaching players during the round.
  *ES: oculta el spam de "X cambió de nombre" y cambios de cvars, y evita que el chat de los
  espectadores llegue a los jugadores durante la ronda.*
- [x] `fixes/l4d_skip_intro`: skip the intro cutscene on first maps so everyone can move right away.
  *ES: salta la escena de introducción en los primeros mapas para que todos se puedan mover de inmediato.*
- [ ] `fixes/TickrateFixes`: fixes door speed, fall damage, etc. **Only needed on 60/100 tick servers.**
  *ES: corrige velocidad de puertas, daño por caída, etc. **Solo hace falta en servidores de 60/100 tick.***
- [ ] `fixes/l4d2_pistol_delay`: caps dual-pistol fire rate. **Only needed on high tickrate.**
  *ES: limita la cadencia de las pistolas dobles. **Solo hace falta con tickrate alto.***

**Survivors · Supervivientes**
- [x] `fixes/firebulletsfix`: bullets come from the right spot (fixes shoot position).
  *ES: las balas salen del lugar correcto (corrige la posición de disparo).*
- [ ] `fixes/fix_fastmelee`: fixes melee swinging faster than it should.
  *ES: corrige el arma cuerpo a cuerpo golpeando más rápido de lo debido.*
- [x] `fixes/l4d2_melee_damage_control`: melee applies the correct damage to infected.
  *ES: el cuerpo a cuerpo hace el daño correcto a los infectados.*
- [ ] `fixes/l4d2_incap_fire_fix`: incapped survivors can shoot normally while holding shove.
  *ES: los supervivientes caídos pueden disparar normal mientras mantienen el empujón.*
- [x] `fixes/l4d2_sg552_zoom_fix`: SG552 zoom no longer gets the camera stuck.
  *ES: el zoom de la SG552 ya no traba la cámara.*
- [x] `fixes/weapon_spawn_duplicate_fix`: weapon spawns can't be looted past their count.
  *ES: no se pueden sacar más armas de un punto de las que tiene.*
- [x] `fixes/l4d_fix_rocket_jump`: some surfaces no longer launch survivors into the air.
  *ES: algunas superficies ya no lanzan a los supervivientes por el aire.*
- [x] `fixes/l4d_fix_stagger_dir`: survivors get staggered in the right direction.
  *ES: los supervivientes se tambalean hacia la dirección correcta.*
- [x] `fixes/l4d2_shove_fix`: fixes shove direction. *needs actions*
  *ES: corrige la dirección del empujón.*
- [x] `fixes/l4d_fix_common_shove`: commons can be shoved while crouching/falling/landing. *needs actions*
  *ES: se puede empujar a los infectados comunes mientras se agachan, caen o aterrizan.*
- [x] `fixes/l4d2_ellis_hunter_bandaid_fix`: Ellis' get-up after a hunter matches the other survivors.
  *ES: Ellis tarda lo mismo que los demás en levantarse después de un hunter.*
- [x] `fixes/l4d_fix_deathfall_cam`: death-fall cameras can't lock your view permanently.
  *ES: las cámaras de caída mortal ya no te dejan la vista trabada para siempre.*
- [x] `optional/nodeathcamskip`: can't skip your death timer by going spectator.
  *ES: no puedes saltarte el tiempo de muerte pasándote a espectador.*
- [x] `optional/l4d_return_thrown_items`: pills/adrenaline you tried to pass come back if the pass failed.
  *ES: si fallas al pasar pastillas/adrenalina, te las devuelve.*

**Special Infected · Infectados especiales**
- [x] `fixes/l4d2_ai_damagefix`: AI SI take and deal damage like human SI.
  *ES: los SI controlados por la IA reciben y hacen daño igual que los humanos.*
- [x] `fixes/l4d_backjump_fix`: hunters can pounce off non-static props.
  *ES: los hunters pueden saltar desde objetos que no son fijos.*
- [x] `fixes/l4d2_no_post_jockey_deadstops`: blocks the melee-spam deadstop exploit after a jockey ride.
  *ES: bloquea el exploit de spamear golpes para hacer deadstop después de un jockey.*
- [x] `fixes/l4d2_jockeyed_ladder_fix`: jockeyed survivors stop sliding down ladders. *needs collisionhook*
  *ES: los supervivientes montados por un jockey dejan de resbalar por las escaleras.*
- [x] `fixes/l4d2_jockey_hitbox_fix`: correct jockey hitbox while riding.
  *ES: hitbox correcta del jockey mientras monta.*
- [x] `fixes/l4d2_boomer_shenanigans`: boomers can't vomit while staggered by a shove.
  *ES: los boomers no pueden vomitar mientras están aturdidos por un empujón.*
- [x] `fixes/l4d2_boomer_ladder_fix`: boomer-on-ladder bug. *needs sourcescramble*
  *ES: bug del boomer en escaleras.*
- [x] `fixes/l4d_vomit_trace_patch`: vomit isn't blocked by infected teammates. *needs sourcescramble*
  *ES: el vómito no lo bloquean los compañeros infectados.*
- [x] `fixes/l4d_tongue_bend_fix`: tongues don't break for "bending too many times".
  *ES: las lenguas no se cortan por "doblarse demasiadas veces".*
- [x] `fixes/l4d_tongue_block_fix`: infected teammates don't block a tongue. *needs collisionhook, sourcescramble*
  *ES: los compañeros infectados no bloquean la lengua.*
- [x] `fixes/l4d_tongue_float_fix`: fixes instant-choke "floating" pulls.
  *ES: corrige los jalones que dejan al superviviente "flotando" y ahorcado al instante.*
- [x] `fixes/l4d2_fix_rocket_pull`: smoker pulls don't launch survivors upward.
  *ES: los jalones del smoker no lanzan a los supervivientes hacia arriba.*
- [x] `fixes/l4d2_charge_target_fix`: several charger target bugs.
  *ES: varios bugs de objetivo del charger.*
- [x] `fixes/l4d2_spit_cooldown_frozen_fix`: spit cooldown no longer gets stuck.
  *ES: el tiempo de recarga del escupitajo ya no se traba.*
- [x] `fixes/l4d2_spit_spread_patch`: fixes spit spreading wrongly. *needs sourcescramble, collisionhook. ZoneMod tunes it: default = no spit spread in saferooms, as vanilla intends.*
  *ES: corrige el ácido esparciéndose mal. Por defecto no se esparce en los cuartos seguros, como pretende el juego vanilla.*
- [x] `fixes/l4d_fix_shove_duration`: SI don't get shoved by "nothing".
  *ES: los SI no reciben empujones de "la nada".*
- [ ] `fixes/l4d_fix_saferoom_ghostspawn`: ghosts can't spawn inside the saferoom.
  *ES: los fantasmas no pueden aparecer dentro del cuarto seguro.*
- [x] `fixes/l4d_fix_finale_breakable`: SI can break finale-area props before the finale. *needs sourcescramble*
  *ES: los SI pueden romper objetos de la zona del final antes de que empiece.*
- [x] `fixes/l4d2_fix_firsthit`: SI first-hit classes stay consistent between halves.
  *ES: las clases de SI del primer ataque son las mismas en ambas mitades.*

**Tank and props · Tank y objetos**
- [x] `fixes/frozen_tank_fix`: tanks don't stay frozen in place.
  *ES: los tanks no se quedan congelados en su lugar.*
- [x] `fixes/l4d_fix_punch_block`: commons don't block tank punches. *needs sourcescramble, collisionhook*
  *ES: los comunes no bloquean los golpes del tank.*
- [x] `fixes/l4d2_rock_trace_unblock`: SI don't block the rock hit check. *needs sourcescramble*
  *ES: los SI no bloquean la detección de impacto de la roca.*
- [x] `fixes/l4d2_fix_tank_rock_handoff`: cancels a half-thrown rock when tank control passes.
  *ES: cancela una roca a medio lanzar cuando el control del tank pasa a otro.*
- [x] `fixes/l4d2_tank_spawn_antirock_protect`: a new tank player isn't hit by a stray rock at spawn.
  *ES: el nuevo jugador tank no recibe una roca perdida al aparecer.*
- [x] `fixes/l4d2_scripted_tank_stage_fix`: finales don't skip tank stages.
  *ES: los finales no se saltan las etapas de tank.*
- [x] `fixes/l4d_fix_rotated_physblocker`: invisible blockers don't stop hittables wrongly.
  *ES: los bloqueadores invisibles no frenan mal los objetos golpeables.*
- [x] `fixes/l4d_prop_touching_rules`: sane rules for props being pushed by players. *needs sourcescramble*
  *ES: reglas sensatas para objetos empujados por jugadores.*
- [x] `fixes/l4d_fix_prop_los`: thin props block line of sight properly.
  *ES: los objetos delgados bloquean bien la línea de visión.*
- [x] `fixes/l4d2_car_alarm_hittable_fix`: a hittable hitting an alarm car doesn't set it off; survivors touching it always do.
  *ES: un objeto golpeado contra un auto con alarma no la activa; si un superviviente lo toca, siempre la activa.*
- [x] `fixes/l4d2_explosiondmg_prev`: stops explosion damage to infected from entities.
  *ES: evita daño por explosión de entidades a los infectados.*

**Map flow and teams · Flujo del mapa y equipos**
- [x] `fixes/l4d_consistent_escaperoute`: the escape route is the same for both teams. *needs sourcescramble*
  *ES: la ruta de escape es la misma para ambos equipos.*
- [x] `fixes/l4d2_fix_team_shuffle`: puts teams back automatically if they get scrambled on map change.
  *ES: reacomoda los equipos solo si se mezclan al cambiar de mapa.*
- [x] `fixes/l4d2_ladderblock`: players can't block others climbing a ladder.
  *ES: nadie puede bloquear a otros que suben una escalera.*

**These are in `generalfixes.cfg` but change gameplay — your call · Están en `generalfixes.cfg` pero cambian el juego; tú decides**
- [ ] `fixes/l4d_static_punch_getup`: makes the tank-punch get-up a fixed length. **Default
      shortens it to half (0.5)**, which favours survivors. Can be set close to vanilla.
  *ES: hace que levantarse de un golpe de tank dure siempre lo mismo. **Por defecto lo acorta a la
  mitad (0.5)**, lo que favorece a los supervivientes. Se puede ajustar cerca de vanilla.*
- [ ] `fixes/l4d2_jockey_jumpcap_patch`: jockeys can't cap with a normal jump in some situations (3 s block).
  *ES: los jockeys no pueden atrapar con un salto normal en algunas situaciones (bloqueo de 3 s).*
- [x] `fixes/l4d2_tank_flying_incap`: survivors go flying on the punch that incaps them (vanilla just drops them).
  *ES: los supervivientes salen volando con el golpe que los derriba (en vanilla solo caen).*
- [ ] `fixes/l4d2_shadow_removal`: removes shadows so survivors can't see infected through walls.
      Arguably an exploit fix, but it does change what you see.
  *ES: quita las sombras para que los supervivientes no vean infectados a través de paredes.
  Casi una corrección de exploit, pero cambia lo que se ve.*
- [ ] `fixes/annoyance_exploit_fixes`: a bundle of anti-annoyance tweaks. *needs builtinvotes*
  *ES: un paquete de ajustes contra molestias.*
- [ ] `optional/l4d2_sound_manipulation`: can block heartbeat/incap sounds. **Default does nothing**;
      only useful if we set flags.
  *ES: puede bloquear los sonidos de latido/caída. **Por defecto no hace nada**; solo sirve si lo configuramos.*

## 3. Anti-cheat · Antitrampas
- [x] `anticheat/l4d2_noghostcheat`: ghost infected aren't sent to survivors' game, so wallhacks can't see them.
  *ES: los infectados en modo fantasma no se envían al juego de los supervivientes, así los wallhacks no los ven.*
- [x] `optional/l4d2_block_autoaim`: removes controller aim-assist and an autoaim exploit.
  *ES: quita la asistencia de apuntado del control y un exploit de autoaim.*
- [x] `optional/l4d_texture_manager_block`: kicks players trying the "mat_hack" wallhack.
  *ES: expulsa a quien intente el wallhack "mat_hack".*
- [x] `optional/l4d_thirdpersonshoulderblock`: kicks players using third-person to peek around corners.
  *ES: expulsa a quien use tercera persona para mirar detrás de las esquinas.*
- [x] `optional/lerpmonitor`: tracks players' lerp; can kick extreme values. *ZoneMod tunes it*
  *ES: vigila el lerp de los jugadores; puede expulsar valores extremos.*
- [x] `optional/ratemonitor`: tracks players' rate settings.
  *ES: vigila la configuración de rate de los jugadores.*
- [x] **SMAC** (srcdslab fork, `sm-plugin-SMAC`): SourceMod Anti-Cheat. Use the modules that support
      L4D2 (aimbot, commands, eyetest, l4d2 fixes, cvars, client, rcon...). Includes the Feb 2025 fix
      that stops false bans for `fog_enable` (Harry's SMAC fork doesn't have it).
  *ES: (fork de srcdslab) SourceMod Anti-Cheat. Usar los módulos que soportan L4D2. Incluye el arreglo
  de feb. de 2025 que evita baneos falsos por `fog_enable` (el fork de SMAC de Harry no lo tiene).*
- [x] **Little Anti-Cheat** (srcdslab fork, `sm-plugin-lilac`): the most maintained fork (35 commits
      ahead of the original: bug fixes, safer SQL, translations). **Start with `lilac_ban 0`** (log
      only) for a couple of weeks to check for false positives, e.g. bunny-hop detection with `l4d2_nobhaps`.
  *ES: (fork de srcdslab) el fork más mantenido (35 commits por delante del original). **Empezar con
  `lilac_ban 0`** (solo registra) un par de semanas para ver falsos positivos, por ejemplo el detector
  de bunny-hop junto con `l4d2_nobhaps`.*

## 4. Quality of life and info (no balance change) · Comodidad e información (sin cambiar el balance)
- [x] `optional/l4d2_tank_props_glow`: hittables glow while a tank is alive, and don't fade. *ZoneMod tunes colour/range*
  *ES: los objetos golpeables brillan mientras hay un tank vivo y no desaparecen.*
- [x] `optional/l4d_tank_damage_announce`: who did how much damage to the tank.
  *ES: quién le hizo cuánto daño al tank.*
- [x] `optional/l4d2_tank_announce`: chat message + sound when a tank spawns.
  *ES: mensaje en el chat + sonido cuando aparece un tank.*
- [x] `optional/pill_passer`: pass pills/adrenaline with Reload.
  *ES: pasa pastillas/adrenalina con la tecla de recargar.*
- [x] `optional/current`: `!current` shows how far the survivors are (flow %).
  *ES: `!current` muestra cuánto avanzaron los supervivientes (% del mapa).*
- [x] `optional/coinflip`: `!coinflip` / `!roll`.
  *ES: `!coinflip` (cara o cruz) / `!roll` (dado).*
- [x] `optional/teamflip`: `!teamflip` picks a random team.
  *ES: `!teamflip` elige un equipo al azar.*
- [ ] `optional/l4d2_stats`: skeets/crowns/levels printed to chat.
  *ES: skeets, crowns y levels en el chat.*
- [x] `optional/l4d2_skill_detect`: the full skill detector (skeets, crowns, high pounces, etc.). Overlaps l4d2_stats.
  *ES: el detector completo de jugadas (skeets, crowns, saltos altos, etc.). Se superpone con l4d2_stats.*
- [x] `optional/survivor_mvp`: survivor MVP at the end of the round.
  *ES: el MVP de los supervivientes al final de la ronda.*
- [x] `optional/l4d2_playstats`: detailed round stats (MVP, accuracy, skills), kept across disconnects.
  *ES: estadísticas detalladas de la ronda (MVP, precisión, jugadas), aunque alguien se desconecte.*
- [x] `optional/si_class_announce`: infected team sees which SI classes are up at round start.
  *ES: el equipo infectado ve qué clases de SI tiene al empezar la ronda.*
- [x] `optional/l4d_common_ragdolls_be_gone`: dead commons' ragdolls vanish (less clutter, less lag).
  *ES: los cuerpos de los comunes muertos desaparecen (menos desorden, menos lag).*
- [x] `optional/caster_assister`: spectators can set their fly speed and move up/down.
  *ES: los espectadores pueden ajustar su velocidad de vuelo y moverse arriba/abajo.*
- [x] `optional/specrates`: low network rates for spectators (saves bandwidth).
  *ES: rates de red bajos para espectadores (ahorra ancho de banda).*
- [ ] `optional/autopause`: auto-pauses if a player crashes, and gives them their spot back. *needs pause.smx*
  *ES: pausa sola si a un jugador se le cierra el juego, y le devuelve su lugar.*
- [x] `optional/l4d2_ghost_warp`: ghost infected can warp to survivors with a command.
  *ES: los infectados en modo fantasma pueden teletransportarse a los supervivientes con un comando.*
- [x] `optional/blocktrolls`: no calling votes while others are still loading.
  *ES: no se pueden iniciar votaciones mientras otros todavía están cargando.*
- [x] `optional/l4d2_block_bot_pills`: bots can't use pills (stops them wasting yours). *needs actions*
  *ES: los bots no pueden usar pastillas (así no las desperdician).*

## 5. Admin and server management · Administración del servidor
- [x] `optional/pause`: `!pause` with both teams readying up to unpause, admin force-pause. *needs builtinvotes*
  *ES: `!pause`; para reanudar ambos equipos tienen que estar listos; los admins pueden forzar la pausa.*
- [x] `l4d_pause_message`: blocks pause commands when the server can't pause.
  *ES: bloquea los comandos de pausa cuando el servidor no puede pausar.*
- [x] **Harry** `l4d_afk_commands`: `!spec`/`!survivors`/`!infected` with anti-abuse rules. **Chosen.**
  *ES: `!spec`/`!survivors`/`!infected` con reglas contra abusos. **Elegido.***
- ~~`optional/playermanagement`~~: not used. It registers the same `!spec` commands as `l4d_afk_commands`.
  *ES: no se usa. Registra los mismos comandos `!spec` que `l4d_afk_commands`.*
- [x] **Ours (patched)** `l4d_tank_control_eq`: everyone on infected gets a turn as tank, in order.
      The original wouldn't load without Ready-Up even though it never uses it; our copy in
      `plugins/l4d_tank_control_eq` drops that requirement.
  *ES: (nuestro, parchado) todos los infectados tienen su turno de tank, en orden. El original no
  cargaba sin Ready-Up aunque nunca lo usa; nuestra copia en `plugins/l4d_tank_control_eq` quita
  ese requisito.*
- [x] **Harry** `l4d_tank_pass`: the player who gets the tank can pass it to a teammate (`!pass`,
      the other player must accept); admins can force it. Works alongside the tank rotation.
      Suggested: `l4d_tank_pass_count 1`.
  *ES: quien recibe el tank se lo puede pasar a un compañero (`!pass`, el otro tiene que aceptar);
  los admins pueden forzarlo. Funciona junto con la rotación de tank. Sugerido: `l4d_tank_pass_count 1`.*
- [x] **Ours** `lef_saferoom_doors`: announces who opened the start saferoom door and who closed the
      end one with teammates still outside.
  *ES: (nuestro) anuncia quién abrió la puerta del refugio inicial y quién cerró la final con
  compañeros todavía afuera.*
- [x] **Ours** `lef_t1_mode`: switchable T1-only weapons mode (cvar, admin or `!t1` vote); the list of
      replaced weapons is configurable. Scout, AWP, grenade launcher and M60 stay by default.
  *ES: (nuestro) modo solo armas T1 que se prende y apaga (cvar, admin o votación `!t1`); la lista de
  armas reemplazadas se configura. Scout, AWP, lanzagranadas y M60 se quedan por defecto.*
- [x] **Harry** `cannounce` (`Sourcemod-Plugins`): custom connect/disconnect messages (with country, if wanted).
  *ES: mensajes propios de conexión/desconexión (con país, si se quiere).*
- [x] **Harry** `smd_advertisements` (`Sourcemod-Plugins`): rotating server messages with translations
      (rules, Discord, commands like `!teams`, `!t1`, `!bosses`).
  *ES: mensajes del servidor que van rotando, con traducciones (reglas, Discord, comandos como
  `!teams`, `!t1`, `!bosses`).*
- [x] **Harry** `l4d2_spec_stays_spec` (MoYu has one too): spectators stay spectators on map change.
  *ES: (MoYu también tiene uno) los espectadores siguen siendo espectadores al cambiar de mapa.*
- [x] **Ours** `lef_admin_restore`: `!heal` and `!restore` (undo team damage, incaps, team kills
      and lost items), with admin heads-ups. Replaces Harry Potter's `admin_hp`.
  *ES: (nuestro) `!heal` y `!restore` (deshace daño de equipo, derribos, muertes por compañeros y
  objetos perdidos), con avisos a los admins. Reemplaza el `admin_hp` de Harry Potter.*
- [x] **Harry** `gamemode-based_configs`: runs `cfg/sourcemod/gamemode_cvars/<mode>.cfg` on map start
      and whenever the game mode changes (`versus.cfg`, `coop.cfg`, `realism.cfg`, `mutation12.cfg`...).
      Per-mode settings without confogl. **Note:** it doesn't undo a mode's settings, so every mode
      file should set the same list of cvars.
  *ES: ejecuta `cfg/sourcemod/gamemode_cvars/<modo>.cfg` al cargar el mapa y cada vez que cambia el
  modo de juego (`versus.cfg`, `coop.cfg`, `realism.cfg`, `mutation12.cfg`...). Configuración por
  modo sin confogl. **Ojo:** no deshace lo que puso otro modo, así que cada archivo de modo debería
  configurar la misma lista de cvars.*
- [x] `optional/l4d2_setscores`: admins (or a vote) can fix the scores. *needs builtinvotes*
  *ES: los admins (o una votación) pueden corregir los puntajes.*
- [ ] `optional/slots_vote`: vote to change the number of slots. *needs builtinvotes*
  *ES: votación para cambiar la cantidad de lugares del servidor.*
- [ ] **Harry** `l4d2_vote_manager3`: control who may call the game's built-in votes.
  *ES: controla quién puede iniciar las votaciones propias del juego.*
- [ ] **Harry** `L4DVSAutoSpectateOnAFK`: moves AFK players to spectator after a while.
  *ES: pasa a espectador a quien esté AFK un rato.*
- [ ] **Harry** `l4d_kickloadstuckers`: kicks players stuck on "connecting".
  *ES: expulsa a los jugadores trabados en "conectando".*
- [ ] **Harry** `l4d_reservedslots`: admins can join a full server.
  *ES: los admins pueden entrar aunque el servidor esté lleno.*
- [ ] **Harry** `savechat`: logs chat to a file.
  *ES: guarda el chat en un archivo.*
- [x] **Harry** `l4d2_mission_manager` + ACS: automatic campaign rotation, with a vote for the next campaign at the finale.
  *ES: rotación automática de campañas, con votación de la siguiente campaña en el final.*

## 5b. Tank and witch every map, with flow % announced · Tank y witch en cada mapa, con el % anunciado

Works **without Ready-Up and without confogl**. Ready-Up is optional for all of these.
*ES: Funciona **sin Ready-Up y sin confogl**. Ready-Up es opcional para todos estos.*
- [x] **Ours** `lef_boss_spawns`: rolls a per-map chance for tank and witch (same for both teams),
      spawns second-half bosses on the first half's spot, and makes sure flows get announced.
  *ES: (nuestro) sortea por mapa si hay tank y witch (igual para ambos equipos), hace aparecer a los
  jefes de la segunda mitad en el mismo lugar que en la primera y se asegura de que se anuncie el %.*
- [x] `optional/witch_and_tankifier`: picks a tank and a witch spawn on every map, avoiding bad
      spots listed per map (108 maps covered in `configs/l4d2lib/mapinfo.txt`) and keeping the witch
      away from the tank. *needs l4d2lib*
  *ES: elige dónde aparecen el tank y la witch en cada mapa, evitando lugares malos listados por mapa
  (108 mapas en `configs/l4d2lib/mapinfo.txt`) y manteniendo a la witch lejos del tank.*
- [x] `optional/l4d_boss_percent`: announces "Tank: 63%, Witch: 28%" when survivors leave the
      saferoom; `!boss` / `!tank` / `!witch` show it any time.
  *ES: anuncia "Tank: 63%, Witch: 28%" cuando los supervivientes salen del cuarto seguro; `!boss` /
  `!tank` / `!witch` lo muestran en cualquier momento.*
- [ ] `optional/l4d_boss_vote`: players can vote to set custom tank/witch flows. *needs builtinvotes*
  *ES: los jugadores pueden votar para poner el % del tank/witch que quieran.*
- [ ] `optional/bossspawningfix`: makes versus boss spawns obey the `versus_*` cvars. *ZoneMod tunes it*
  *ES: hace que la aparición de jefes en versus respete los cvars `versus_*`.*
- Map files: `static_tank_map` / `static_witch_map` lines (maps with scripted tanks, where no
  extra tank should be added) come from ZoneMod's `shared_settings.cfg` and would go in our cfg.
  *ES: Archivos de mapas: las líneas `static_tank_map` / `static_witch_map` (mapas con tanks
  programados, donde no se debe agregar otro) vienen del `shared_settings.cfg` de ZoneMod e irían
  en nuestra cfg.*

## 5c. Scores and comebacks · Puntajes y remontadas

- [x] **Ours** `lef_score_info`: explains the score: what each map is worth, the gap, what's
      needed to win the map / take the lead, and a map wins count. **Changes no points.**
  *ES: (nuestro) explica el puntaje: cuánto vale cada mapa, la diferencia, qué hace falta para ganar
  el mapa o pasar adelante, y un conteo de mapas ganados. **No cambia ningún punto.***
- [ ] **Ours** `lef_comeback_bonus`: the team that's behind by 100+ earns +15% of the distance it
      covers, capped at the gap. **Changes points.** *needs `optional/l4d2_penalty_bonus`*
  *ES: (nuestro) el equipo que va perdiendo por 100+ gana +15% de la distancia que recorre, sin pasar
  de la diferencia. **Cambia los puntos.***

## 6. Extra fixes from Harry and MoYu (not in ZoneMod) · Correcciones extra de Harry y MoYu (no están en ZoneMod)
- [x] **Harry** `l4d_revive_reload_interrupt`: reviving no longer jams your weapon mid-reload.
  *ES: levantar a un compañero ya no te traba el arma a mitad de la recarga.*
- [x] **Harry** `l4d_switch_team_survivor_dead_fix`: switching to survivors no longer spawns you dead/incapped.
  *ES: pasarte a supervivientes ya no te hace aparecer muerto o caído.*
- [x] **Harry** `jockey_ride_team_switch_teleport_fix`: a jockey switching team mid-ride no longer teleports the survivor.
  *ES: si un jockey cambia de equipo mientras monta, el superviviente ya no se teletransporta.*
- [x] **Harry** `l4d_minigun_fly_fix`: blocks the minigun flying glitch.
  *ES: bloquea el glitch de volar con la ametralladora fija.*
- [x] **Harry** `l4d2_gascan_flame_fix`: gascans that sometimes wouldn't ignite now do.
  *ES: los bidones de gasolina que a veces no se encendían ahora sí lo hacen.*
- [x] **Harry** `l4d_witch_retreat_panic_fix`: a retreating witch doesn't come back when a horde starts.
  *ES: una witch que se retira no vuelve cuando empieza una horda.*
- [x] **Harry** `l4d_ghost_spawn_exploit`: blocks a spawn-and-teleport ghost exploit.
  *ES: bloquea un exploit de aparecer y teletransportarse como fantasma.*
- [x] **Harry** `l4d_exploit_dmg_block`: blocks damage exploits (e.g. throw a molotov, then switch teams).
  *ES: bloquea exploits de daño (por ejemplo, tirar una molotov y cambiarse de equipo).*
- [x] **Harry** `l4d2_survivor_mourn_fix`: survivors can mourn L4D1 survivors on the L4D2 set.
  *ES: los supervivientes pueden lamentar la muerte de los de L4D1 en el grupo de L4D2.*
- [ ] **Harry** `l4d_shotgun_sound_fix`: shotguns have sound in third person.
  *ES: las escopetas tienen sonido en tercera persona.*
- [x] **Harry** `l4d2_chainsaw_fix`: fixes a Linux server crash with chainsaws.
  *ES: corrige un crasheo de servidores Linux con la motosierra.*
- [x] **MoYu** `l4d2_fix_common_flee`: sitting/lying commons don't get stuck when fleeing.
  *ES: los comunes sentados/acostados no se traban al huir.*
- [x] **MoYu** `l4d_fix_target_replace`: infected keep the right target when a survivor is replaced by a bot.
  *ES: los infectados mantienen el objetivo correcto cuando un bot reemplaza a un superviviente.*
- [x] **MoYu** `l4d_spray_origin_fix`: sprays appear where they should.
  *ES: los sprays aparecen donde deben.*
- [ ] **Harry** `physics_object_pushfix`: walking into gascans/propane no longer pushes them.
  *ES: caminar contra bidones/garrafas de propano ya no los empuja.*
- [ ] **Harry** `l4d_witch_bash_wandering`: shoving a wandering witch startles her (vanilla doesn't).
  *ES: empujar a una witch que camina la asusta (en vanilla no).*

## 6b. New sources (added 2026-10-01) · Fuentes nuevas (agregadas el 2026-10-01)

Where they live: **Lux** = `Left-4-fix`; **Silvers** = `Various_Scripts_Collection` (or its own repo
folder); **AM** = `from_alliedmodders`. `dhooks` is built into SourceMod 1.12.
*ES: Dónde están: **Lux** = `Left-4-fix`; **Silvers** = `Various_Scripts_Collection` (o su propia
carpeta de repo); **AM** = `from_alliedmodders`. `dhooks` ya viene incluido en SourceMod 1.12.*

**Fixes (LuxLuma's Left-4-fix, updated July 2026) · Correcciones (Left-4-fix de LuxLuma, actualizado en julio de 2026)**
- [x] **Lux** `Defib_Fix`: defibs no longer fail or revive the wrong person.
  *ES: el desfibrilador ya no falla ni revive a la persona equivocada.*
- [x] **Lux** `Witch_Target_patch`: the witch goes after the right survivor.
  *ES: la witch persigue al superviviente correcto.*
- [x] **Lux** `witch_prevent_target_loss`: the witch doesn't randomly lose her target.
  *ES: la witch no pierde su objetivo al azar.*
- [x] **Lux** `Witch_Double_Startle_Fix`: a wandering witch doesn't play her startle twice.
  *ES: una witch que camina no se asusta dos veces.*
- [x] **Lux** `stop_air_revive`: can't revive in mid-air to dodge fall damage (exploit).
  *ES: no se puede revivir en el aire para evitar el daño por caída (exploit).*
- [x] **Lux** `survivor_afk_fix`: fixes the game's own "go AFK" function.
  *ES: corrige la función de "irse AFK" del propio juego.*
- [x] **Lux** `witch_pipebomb_exploit_fix_&_death_optmizer`: a pipe bomb + horde can't delete the
      witch; also stops sending far-away zombie deaths to players (less network traffic).
  *ES: una bomba casera + horda ya no puede borrar a la witch; además no envía a los jugadores las
  muertes de zombis lejanos (menos tráfico de red).*
- [ ] **Lux** `l4d2_changelevel`: cleaner map changes than `sm_map` (needed by MoYu's
      `vote_custom_campaigns`). Overlaps the competitive repo's `l4d2_fix_changelevel`.
  *ES: cambios de mapa más limpios que `sm_map` (lo necesita `vote_custom_campaigns` de MoYu). Se
  superpone con `l4d2_fix_changelevel` del repo competitivo.*
- [ ] **Lux** `physics_object_pushfix`: same job as Harry's in section 6; pick one.
  *ES: hace lo mismo que el de Harry de la sección 6; elige uno.*
- [ ] **Lux** `Hunter_pounce_alignment_fix`: L4D1-style hunter alignment on pounce. *Changes gameplay a little.*
  *ES: alineación del hunter al saltar como en L4D1. **Cambia un poco el juego.***
- [ ] **Lux** `Charger_Collision_patch`: chargers can bowl more survivors and hit the same one
      again. *Changes gameplay.* *needs sourcescramble*
  *ES: el charger puede arrollar a más supervivientes y golpear otra vez al mismo. **Cambia el juego.***
- [ ] **Lux** `witch_allow_in_safezone`: a witch can chase into the saferoom. *Changes gameplay.*
  *ES: la witch puede perseguir dentro del cuarto seguro. **Cambia el juego.***

**Fixes and tools (Silvers' collection, updated Sept 2026) · Correcciones y herramientas (colección de Silvers, actualizada en sept. de 2026)**
- [x] **Silvers** `l4d_exploit_fixes`: blocks damage from idle, disconnected or team-switched players
      (e.g. throw a molotov, then go spectator). Overlaps Harry's `l4d_exploit_dmg_block`; pick one.
  *ES: bloquea el daño de jugadores ausentes, desconectados o que cambiaron de equipo (por ejemplo,
  tirar una molotov y pasarse a espectador). Se superpone con `l4d_exploit_dmg_block` de Harry; elige uno.*
- [x] **Silvers** `l4d_unlimited_grenades_fix`: blocks an infinite-grenades exploit.
  *ES: bloquea un exploit de granadas infinitas.*
- [x] **Silvers** `l4d_witch_stumble_fix`: the witch can't get stuck stumbling forever after an explosion.
  *ES: la witch no se queda tambaleando para siempre después de una explosión.*
- [x] **Silvers** `l4d_transition_level`: if the round doesn't end after the saferoom door closes,
      survivors are moved to the middle of the room so it does.
  *ES: si la ronda no termina al cerrar la puerta del cuarto seguro, mueve a los supervivientes al
  centro del cuarto para que termine.*
- [x] **Silvers** `l4d_lagged_movement`: stops plugins fighting over player speed (needed if several
      plugins change speed).
  *ES: evita que los plugins se peleen por la velocidad del jugador (necesario si varios la cambian).*
- [x] **Silvers** `l4d_heartbeat`: black-and-white fixes; our `lef_admin_restore` works through it.
      (Newer than Harry's copy.)
  *ES: correcciones del estado blanco y negro; nuestro `lef_admin_restore` trabaja a través de él.
  (Más nuevo que la copia de Harry.)*
- [ ] **Silvers** `l4d2_vs_rematch`: hides the "rematch?" vote panel at the end of a versus campaign.
  *ES: oculta el panel de votación de "¿revancha?" al final de una campaña versus.*
- [ ] **Silvers** `l4d_item_equip`: being handed pills/adrenaline doesn't switch your weapon to them.
  *ES: cuando te pasan pastillas/adrenalina, no te cambia el arma a ellas.*
- [x] **Silvers** `plugin_updates_checker`: tells you which plugins have newer versions. *Server maintenance.*
  *ES: te dice qué plugins tienen versiones más nuevas. *Mantenimiento del servidor.**
- [ ] **Silvers** `sm_configs`: keeps your config values when a plugin update changes its cfg file.
  *ES: conserva tus valores cuando una actualización de plugin cambia su archivo cfg.*
- [x] Silvers' visual extras (`l4d_fire_glow`, `l4d_explosive_flash`, `l4d_glare`, `Dynamic_Light`,
      `l4d_dsp_effects`, ...) and Lux's `Enhanced_Throwables`: lights and effects. Nice, but extra
      light changes what both teams can see.
  *ES: extras visuales de Silvers y el `Enhanced_Throwables` de Lux: luces y efectos. Lindos, pero
  más luz cambia lo que ambos equipos pueden ver.*

**Info and QoL (AlliedModders) · Información y comodidad (AlliedModders)**
- [x] **AM** `l4d_throwable_announcer` (Mart): "X threw a bile bomb / molotov / pipe bomb".
  *ES: "X tiró una bomba de bilis / molotov / bomba casera".*
- [x] **AM** `l4d_explosion_announcer` (Mart): "X blew up the gascan / propane / car". Also handy for
      spotting who blew something up next to the team.
  *ES: "X hizo explotar el bidón / propano / auto". También sirve para ver quién hizo explotar algo al
  lado del equipo.*
- [x] **AM** `l4d2_pack_deploy_announce` (Mart): "X deployed incendiary ammo".
  *ES: "X desplegó munición incendiaria".*
- [ ] **AM** `l4d_announce_healer` (NoroHime): shows the health of whoever you heal, revive, pass
      pills to, or aim at.
  *ES: muestra la vida de a quien curas, levantas, le pasas pastillas o apuntas.*
- [x] **AM** `l4d_pipebomb_ignore` (Silvers): bots keep shooting while a pipe bomb is out (better bots).
  *ES: los bots siguen disparando mientras hay una bomba casera (bots mejores).*
- [x] **Silvers** `Vote_Mode`: vote to switch game mode (coop, realism, versus, mutations). Uses a menu
      vote, not the game's vote screen. Pairs well with `gamemode-based_configs` (section 5).
  *ES: votación para cambiar el modo de juego (coop, realismo, versus, mutaciones). Usa una votación
  por menú, no la pantalla de votación del juego. Combina bien con `gamemode-based_configs` (sección 5).*

**Looked at, not suggested · Revisados, no sugeridos**
- `Console_Spam_Patches`: already in section 2 (the competitive repo's copy is newer).
  *ES: ya está en la sección 2 (la copia del repo competitivo es más nueva).*
- `Dissolve_Infected`: cosmetic; the competitive repo's ragdoll remover covers the useful part.
  *ES: cosmético; el que quita los cuerpos del repo competitivo cubre la parte útil.*
- pan0s' `l4d2_srs` (stats & ranking): needs three more plugins plus a GeoIP extension, and runs
  database queries in a way that can make the server stutter. Good as a reference for the
  "balanced teams" idea, not to run.
  *ES: (estadísticas y ranking) necesita tres plugins más y una extensión GeoIP, y hace consultas a la
  base de datos de una forma que puede trabar el servidor. Sirve de referencia para la idea de
  "equipos balanceados", no para usarlo.*
- pan0s' `l4d2_menu`: a 93-line `!menu` that lists commands; we'd rather make our own help menu.
  *ES: un `!menu` de 93 líneas que lista comandos; preferimos hacer nuestro propio menú de ayuda.*
- Mart's `l4d2_scripted_hud`: a tool, not something to run as-is. See IDEAS ("on-screen info").
  *ES: una herramienta, no algo para usar tal cual. Ver IDEAS ("información en pantalla").*

## 7. Gameplay and balance changes (ZoneMod's choices — off unless you want them) · Cambios de juego y balance (elecciones de ZoneMod; desactivados salvo que los quieras)

> Decided 2026-10-02: the ones ticked here use **ZoneMod's values**, not each plugin's defaults.
> *ES: Decidido el 2026-10-02: los que están marcados aquí usan **los valores de ZoneMod**, no los
> valores por defecto de cada plugin.*

**Survivors · Supervivientes**
- [ ] `optional/l4d2_pickup`: picking up pills/melee doesn't switch your weapon; pick-ups get interrupted when incapped by spit/tank.
  *ES: agarrar pastillas/cuerpo a cuerpo no te cambia el arma; recoger se interrumpe si te derriba el ácido o el tank.*
- [ ] `optional/l4dhots`: pills and adrenaline heal over time instead of instantly.
  *ES: las pastillas y la adrenalina curan de a poco en vez de al instante.*
- [ ] `optional/starting_items`: everyone starts each round with items.
  *ES: todos empiezan cada ronda con objetos.*
- [ ] `optional/nosaferoomkits`: removes saferoom medkits.
  *ES: quita los botiquines del cuarto seguro.*
- [ ] `optional/l4d2_saferoom_item_remove`: removes extra saferoom items. *needs l4d2_saferoom_detect*
  *ES: quita los objetos extra del cuarto seguro.*
- [ ] `optional/l4d_weapon_limits`: limits how many of each weapon a team can carry.
  *ES: limita cuántas armas de cada tipo puede llevar un equipo.*
- [ ] `optional/l4d2_weaponrules`: replaces weapon spawns by rules (e.g. T2 → T1).
  *ES: reemplaza armas según reglas (por ejemplo, T2 → T1).*
- [ ] `optional/l4d2_weapon_attributes` + `l4d2_static_shotgun_spread`: changes weapon stats and shotgun spread.
  *ES: cambia las estadísticas de las armas y la dispersión de las escopetas.*
- [ ] `optional/l4d2_magnum_incap`: incapped survivors with a magnum get pistols instead.
  *ES: los supervivientes caídos con magnum reciben pistolas en su lugar.*
- [ ] `optional/l4d2_ladder_rambos`: survivors can shoot while on ladders.
  *ES: los supervivientes pueden disparar en las escaleras.*
- [ ] `optional/noteam_nudging`: survivors don't push each other.
  *ES: los supervivientes no se empujan entre sí.*
- [ ] `optional/fix_engine`: blocks the ladder-speed glitch, no-fall-damage bug and health-boost glitch.
      (Mostly exploit fixes; on by default for 3 of them.)
  *ES: bloquea el glitch de velocidad en escaleras, el bug de no recibir daño por caída y el glitch de
  aumento de vida. (Casi todo correcciones de exploits; 3 vienen activadas por defecto.)*
- [x] `optional/l4d2_nobhaps`: blocks bunny-hopping.
  *ES: bloquea el bunny-hop.*
- [ ] `optional/temphealthfix`: correct temp health after hittable/ledge incaps.
  *ES: vida temporal correcta después de caer por un objeto golpeado o un borde.*
- [ ] `optional/finalefix`: incapped survivors don't get full distance points when the rescue leaves.
  *ES: los supervivientes caídos no reciben todos los puntos de distancia cuando se va el rescate.*
- [ ] `optional/l4d2_melee_shenanigans`: shoves don't slow tank/charger; a punched survivor holding a melee switches to primary.
  *ES: los empujones no frenan al tank/charger; un superviviente golpeado con un arma cuerpo a cuerpo en la mano pasa al arma principal.*

**Special Infected · Infectados especiales**
- [ ] `optional/l4d2_uniform_spit`: spit does a flat damage per second (*this is the reduced-spitter-damage one you didn't like*).
  *ES: el ácido hace un daño fijo por segundo (*es el del daño reducido de la spitter que no te gustó*).*
- [ ] `optional/l4d2_spitblock`: no spit damage in certain map spots.
  *ES: sin daño de ácido en ciertos lugares del mapa.*
- [ ] `optional/si_fire_immunity`: SI burn for less time (default: fire goes out after 1 s; tank can't burn).
  *ES: los SI se queman por menos tiempo (por defecto el fuego se apaga en 1 s; el tank no se quema).*
- [ ] `optional/l4d_bash_kills`: SI can't be shoved to death.
  *ES: no se puede matar a los SI a empujones.*
- [x] `optional/l4d_pounceprotect`: taking damage doesn't stop a hunter from pouncing.
  *ES: recibir daño no impide que el hunter salte.*
- [ ] `optional/l4d2_hunter_no_deadstops`: hunters in the air can't be deadstopped by shoves.
  *ES: a los hunters en el aire no se les puede hacer deadstop con empujones.*
- [ ] `optional/l4d2_m2_control_eq`: no instant re-pounce after a shove; shove penalty tweaks.
  *ES: no hay salto instantáneo después de un empujón; ajustes a la penalidad del empujón.*
- [ ] `optional/l4d2_nobackjumps`: blocks hunter backjumps.
  *ES: bloquea los saltos hacia atrás del hunter.*
- [ ] `optional/l4d_jockey_ledgehang`: changes jockey recharge after a ledge-hang.
  *ES: cambia la recarga del jockey después de dejar a alguien colgando de un borde.*
- [x] `optional/l4d2_unsilent_jockey`: jockeys make sound constantly.
  *ES: los jockeys hacen ruido todo el tiempo.*
- [ ] `optional/l4d2_si_ffblock`: infected can't hurt each other.
  *ES: los infectados no se pueden hacer daño entre sí.*
- [ ] `optional/l4d2_si_staggers`: SI aren't staggered by other SI (boomer, charger, witch).
  *ES: los SI no se tambalean por otros SI (boomer, charger, witch).*
- [x] `optional/l4d2_dominatorscontrol`: allows "quad caps" in native order.
  *ES: permite "quad caps" en el orden nativo.*
- [x] `optional/l4d2_fix_spawn_order`: fixed SI spawn rotation.
  *ES: rotación fija de aparición de SI.*
- [x] `optional/l4d2_nospitterduringtank`: no spitter while a tank is up.
  *ES: no hay spitter mientras hay un tank.*
- [x] `optional/despawn_health`: SI get health back when they despawn.
  *ES: los SI recuperan vida cuando vuelven a ser fantasmas.*
- [x] `optional/l4d2_nosecondchances`: SI bots that were human-controlled with a cap don't die instantly.
  *ES: los bots SI que eran controlados por un humano y tenían a alguien atrapado no mueren al instante.*
- [ ] `optional/charger_incap_damage`: changes charger pound damage on incapped survivors.
  *ES: cambia el daño de los golpes del charger a supervivientes caídos.*
- [x] `optional/l4d2_getup_slide_fix` / `optional/l4d2_getup_fixes` / `optional/l4d2_godframes_control_merge`:
      get-up animations, god frames and friendly-fire rules. *ZoneMod tunes them heavily*
  *ES: animaciones de levantarse, frames de invulnerabilidad y reglas de fuego amigo.*
- [ ] `optional/staggersolver`: no inputs during stumbles.
  *ES: sin controles mientras te tambaleas.*
- [ ] `optional/l4d2_tongue_timer`: changes smoker tongue cooldown in some cases.
  *ES: cambia la recarga de la lengua del smoker en algunos casos.*
- [ ] `optional/l4d2_uncommon_blocker`: removes uncommon infected.
  *ES: quita los infectados poco comunes.*
- [ ] `optional/blockheatseekingchargers`: chargers don't "home in" after a survivor gets up.
  *ES: los chargers no "persiguen" a un superviviente después de que se levanta.*

**Tank and hordes · Tank y hordas**
- [ ] `optional/l4d2_hittable_control`: changes hittable damage. *ZoneMod tunes it heavily*
  *ES: cambia el daño de los objetos golpeables.*
- [ ] `optional/l4d2_tank_damage_cvars`: per-attack tank damage.
  *ES: daño del tank por tipo de ataque.*
- [x] `optional/l4d2_tank_attack_control`: tank rock/punch choice tweaks.
  *ES: ajustes a cómo el tank elige entre roca y golpe.*
- [x] `optional/l4d2_tankrage`: tank keeps rage while survivors run back.
  *ES: el tank no pierde furia mientras los supervivientes corren hacia atrás.*
- [ ] `optional/checkpoint-rage-control`: tank loses rage while survivors hide in the saferoom.
  *ES: el tank pierde furia mientras los supervivientes se esconden en el cuarto seguro.*
- [ ] `optional/l4d_tank_rush`: no distance points while a tank is alive.
  *ES: no se ganan puntos de distancia mientras hay un tank vivo.*
- [ ] `optional/l4d2_tank_horde_monitor`: during infinite-horde events, the horde pauses while a tank
      is up; if survivors push ahead to skip the tank it comes back, stronger the further they go.
      **Undecided:** random players need it explained or they'll rush; idea: make it switchable and
      announce the rule when it's on (see IDEAS).
  *ES: en eventos de horda infinita, la horda se pausa mientras hay un tank; si los supervivientes
  avanzan para saltarse el tank vuelve, más fuerte cuanto más avanzan. **Sin decidir:** hay que
  explicárselo a los randoms o van a rushear; idea: que se pueda prender y apagar y que anuncie la
  regla cuando está activo (ver IDEAS).*
- [ ] `optional/l4d_tank_painfade`: tank's screen flashes red when hurt.
  *ES: la pantalla del tank se pone roja al recibir daño.*
- [x] `optional/l4d_tankpunchstuckfix`: punched survivors don't get stuck in the ceiling. (Close to a pure fix.)
  *ES: los supervivientes golpeados no se quedan trabados en el techo. (Casi una corrección pura.)*
- [x] `optional/rock_stumble_block`: rocks don't vanish if the tank is stumbled mid-throw. (Close to a pure fix.)
  *ES: las rocas no desaparecen si el tank se tambalea a mitad del lanzamiento. (Casi una corrección pura.)*
- [x] `optional/l4d2_bw_rock_hit`: rocks don't pass through black-and-white survivors. (Close to a pure fix.)
  *ES: las rocas no atraviesan a supervivientes en blanco y negro. (Casi una corrección pura.)*
- [x] `optional/smart_ai_rock`: AI tanks don't throw underhand rocks they can't aim.
  *ES: los tanks de la IA no lanzan rocas por abajo que no pueden apuntar.*
- [ ] `optional/l4d2_profitless_ai_tank`: passing the tank to AI doesn't give a free respawn.
  *ES: pasarle el tank a la IA no te da una reaparición gratis.*
- [x] `optional/boomer_horde_equalizer_refactored`: the boomer's horde is a fixed size per survivor
      vomited, instead of depending on how many zombies were already nearby (in vanilla the same
      boom can bring 10 zombies to one team and 30 to the other). *needs sourcescramble*
  *ES: la horda del boomer tiene un tamaño fijo por superviviente vomitado, en vez de depender de
  cuántos zombis había cerca (en vanilla el mismo vómito puede traer 10 zombis a un equipo y 30 al otro).*
- [x] `optional/l4d_equalise_alarm_cars`: the same cars are alarmed for both teams.
  *ES: los mismos autos tienen alarma para ambos equipos.*
- [ ] `optional/l4d2_ledgeblock`: no ledge hanging on some maps.
  *ES: en algunos mapas no se puede quedar colgado de los bordes.*
- [ ] `optional/eq_finale_tanks`: changes how many tanks spawn in finales.
  *ES: cambia cuántos tanks aparecen en los finales.*
- [x] `optional/l4d2_antibaiter`: forces a horde if infected wait too long to attack.
  *ES: fuerza una horda si los infectados esperan demasiado para atacar.*
- [x] `optional/l4d2_collision_adjustments`: rocks pass through commons, etc. *needs collisionhook*
  *ES: las rocas atraviesan a los comunes, etc.*

## 8. Competitive-only (not suggested for the lite config) · Solo competitivo (no sugerido para la config lite)

These only make sense with ready-up / scoring / confogl, so they belong in the Vanilla+ match
mode if anywhere: `readyup`, `l4d2_hybrid_scoremod_zone`, `caster_system`, `spechud`,
`panel_text` (only adds text to the Ready-Up screen), `cfg_motd`, `confoglcompmod`, `match_vote`, `predictable_unloader`,
`l4d2_blind_infected`, `l4d2_map_transitions`, `l4d2_saferoom_detect`.
*ES: Estos solo tienen sentido con ready-up / sistema de puntaje / confogl, así que, si van en
algún lado, es en el modo Vanilla+: `readyup`, `l4d2_hybrid_scoremod_zone`, `caster_system`,
`spechud`, `panel_text` (solo agrega texto a la pantalla de Ready-Up), `cfg_motd`, `confoglcompmod`,
`match_vote`, `predictable_unloader`, `l4d2_blind_infected`, `l4d2_map_transitions`, `l4d2_saferoom_detect`.*

> **Ready-Up check (2026-10-01):** of every plugin here, only `l4d_tank_control_eq` (now patched,
> see section 5) and `panel_text` *require* Ready-Up. All the others just use it when it's there.
> *ES: **Revisión de Ready-Up (2026-10-01):** de todos los plugins de aquí, solo `l4d_tank_control_eq`
> (ya parchado, ver sección 5) y `panel_text` *requieren* Ready-Up. Los demás solo lo usan si está.*
