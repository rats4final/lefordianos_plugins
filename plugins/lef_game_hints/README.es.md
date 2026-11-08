[English](README.md)

# lef_game_hints — Lefordianos Game Hints (avisos de juego)

Avisos y consejos amistosos durante la ronda. **Nada de esto castiga a nadie**: solo habla.
Left 4 Dead 2.

## Rushear y quedarse atrás (sobrevivientes)

Un sobreviviente muy **adelantado** del equipo, o muy **atrás**, recibe un aviso en el chat y en el cuadro
de avisos; los demás sobrevivientes también se enteran (`lef_hints_pace_tell_team`). Las distancias son
una parte del largo del mapa, como en el `no-rushing` de Harry Potter (que teletransporta y mata; nosotros
solo avisamos).

Sin avisos:
- para el **último sobreviviente en pie** (hace lo que tenga que hacer, como correr al refugio);
- mientras hay un **tank** (escapar está bien);
- durante los **finales**, y por 90 s después de un **evento de pánico** (alarmas, gauntlets: correr es la
  idea);
- dentro del refugio final.

## Guardar un infectado (versus)

- Un infectado especial **vivo mucho tiempo sin atacar** (`lef_hints_hold_time`, 60 s) recibe un
  recordatorio. Atacar o usar su habilidad reinicia el reloj.
- Un **fantasma que podría aparecer** y no lo hace, por `lef_hints_ghost_time` (60 s), recibe un
  recordatorio. Solo cuentan los segundos en que de verdad puede aparecer.
- `lef_hints_hold_tell_team 1` también avisa al equipo infectado (apagado por defecto: guardarlo para un
  ataque en equipo está bien).

## Ataquen juntos (versus)

- Una vez por mapa, cuando los supervivientes salen del refugio (primera mitad), el equipo infectado
  recibe el consejo: ataquen juntos, uno solo casi nunca logra nada.
- Un **smoker, hunter, jockey o charger** que entró solo y murió rápido recibe un aviso privado, como
  máximo una vez por ronda. "Solo y rápido" es todo esto junto: lo mató un superviviente antes de
  `lef_hints_solo_time` (15 s) desde que apareció, hizo menos de `lef_hints_solo_damage` (10) de daño, no
  agarró a nadie, ningún compañero infectado vivo a menos de `lef_hints_solo_range` (1200 unidades) ni
  golpeando a un superviviente en los últimos 5 s, ningún superviviente caído ni atrapado, y ningún tank.
- **Los boomers y spitters nunca cuentan**, ni las muertes que no causó un superviviente (caídas,
  suicidios): sacrificar uno para rotar el orden de aparición ("kill boom") es una táctica de verdad.

## Consejos para el tank (versus)

Quien pasa a ser tank recibe una línea sobre su equipo (todavía reapareciendo → esperar; listo → avisar el
ataque en el chat) y consejos al azar: evitar zonas abiertas, golpear objetos, rocas para los que están
lejos, no perseguir dentro del refugio... El equipo infectado se entera de quién es el tank.

## Ajustes

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_hints_pace` | 1 | Avisos de rushear / quedarse atrás |
| `lef_hints_rush_distance` | 0.12 | Adelante del siguiente compañero por esta parte del mapa |
| `lef_hints_behind_distance` | 0.15 | Atrás del compañero más cercano por esta parte del mapa |
| `lef_hints_pace_tell_team` | 1 | También avisar a los demás sobrevivientes |
| `lef_hints_panic_grace` | 90 | Segundos sin avisos después de un evento de pánico |
| `lef_hints_hold` | 1 | Recordatorios de guardar un infectado |
| `lef_hints_hold_time` | 60 | Segundos vivo sin atacar |
| `lef_hints_ghost_time` | 60 | Segundos como fantasma pudiendo aparecer |
| `lef_hints_hold_tell_team` | 0 | También avisar al equipo infectado |
| `lef_hints_solo` | 1 | Consejo y aviso de atacar juntos |
| `lef_hints_solo_time` | 15 | Solo: murió antes de estos segundos desde que apareció |
| `lef_hints_solo_damage` | 10 | Solo: hizo menos daño que esto |
| `lef_hints_solo_range` | 1200 | Solo: ningún compañero infectado tan cerca |
| `lef_hints_tank_tips` | 1 | Consejos para el tank |
| `lef_hints_tank_tip_count` | 1 | Consejos al azar por tank |
| `lef_hints_cooldown` | 30 | Segundos entre avisos al mismo jugador |

Los consejos y avisos están en `translations/lef_game_hints.phrases.txt` (inglés y español), fáciles de
cambiar.

## Necesita

[Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
