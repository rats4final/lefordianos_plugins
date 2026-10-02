[English](README.md)

# l4d2_tank_horde_monitor (parchado: interruptor y recordatorio de la regla)

**L4D2 Tank Horde Monitor** de Derpduck, basado en `l4d2_horde_equaliser` de Visor, del
L4D2-Competitive-Rework (versión 1.3.1).

## Qué hace

Durante los **eventos de horda infinita** (crescendos, carreras), cuando aparece un tank la horda **se
pausa**, así los supervivientes pelean contra el tank y no contra tank + horda sin fin. Si los
supervivientes avanzan para saltarse el tank, la horda vuelve, más fuerte cuanto más avanzan, hasta su
fuerza completa. El chat lo explica cuando pasa: "la horda se pausó por el tank, avanzar 12.5% la hace
volver", después el % que falta, después la fuerza. Funciona solo; no necesita confogl.

## Nuestro cambio

Los jugadores randoms no conocen la regla y suelen rushear, así que:

- **Interruptor:** `l4d2_tank_horde_monitor_enable` (por defecto `1`). Con `0` el juego se comporta
  como vanilla (la horda sigue llegando durante el tank). Se aplica desde el próximo tank.
- **Recordatorio de la regla:** `l4d2_tank_horde_monitor_hint` (por defecto `1`). Mientras el plugin
  está activo, una vez por ronda cuando los supervivientes salen del refugio: "Regla: si aparece un
  tank durante un evento de horda, la horda se pausa. Avanzar para saltarse el tank la hace volver, más
  fuerte cuanto más avancen." (En inglés y español, en nuestro propio `lef_tank_horde_monitor.phrases.txt`
  para no tocar el archivo original.)

No se cambió nada más; la versión es `1.3.1-lef1`. Mismo nombre de archivo, así que reemplaza al original
directamente. Está planeada una votación para prenderlo/apagarlo en nuestro menú `!votes`.

Necesita Left4DHooks y la gamedata `l4d2_zombiemanager.txt` del repo competitivo (Windows y Linux).
