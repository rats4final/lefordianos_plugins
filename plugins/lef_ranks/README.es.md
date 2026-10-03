[English](README.md)

# lef_ranks — Lefordianos Ranks (ranking)

Un ranking para nuestras partidas de versus, hecho para armar **equipos parejos**. Left 4 Dead 2.

## Cómo funcionan los puntos

Todos empiezan con **1000 puntos** (Elo, como en el ajedrez, adaptado a equipos):

- Cuando termina un **mapa** (las dos mitades), gana el equipo con más puntos en ese mapa. Sus jugadores
  suman puntos y los que perdieron restan.
- Ganarle a un equipo más fuerte da más puntos que ganarle a uno más débil; perder contra uno más fuerte
  quita menos.
- Los jugadores nuevos se mueven más rápido (`lef_ranks_k_new` 40) en sus primeros 20 mapas, para que
  encuentren su nivel pronto; después, `lef_ranks_k_settled` (20).
- Solo cuenta el **resultado del mapa**, no el daño ni las muertes: eso es lo que importa para equipos
  parejos, y no se puede inflar.
- Un mapa solo cuenta con al menos **2 humanos por lado** (así las partidas con bots no cuentan), y quien
  jugó en los dos lados durante un mapa no cuenta para ese mapa.

## Comandos

| Comando | Qué muestra |
|---|---|
| `!rank` / `!rank <jugador>` | Puntos, mapas jugados, ganados, perdidos y puesto en la tabla |
| `!top` | Los 10 mejores (con al menos `lef_ranks_min_games` mapas, 5) |

Después de cada mapa, cada jugador ve su cambio en el chat ("Mapa ganado: +14 puntos, ahora 1032").

## Mezcla balanceada

La mezcla balanceada de `lef_teams_panel` usa estos puntos para quien tiene al menos 5 mapas que cuenten
(`lef_teams_ranked_games`), y el nivel del roster para los demás (nivel 3 = 1000 puntos, cada nivel 100
puntos). Así empieza con el roster y se vuelve más precisa cuanto más juegan.

## Ajustes

| Cvar | Por defecto | Qué hace |
|---|---|---|
| `lef_ranks_start` | 1000 | Puntos iniciales |
| `lef_ranks_k_new` | 40 | Cuánto mueve un mapa los puntos de un jugador nuevo |
| `lef_ranks_k_settled` | 20 | Cuánto mueve un mapa los puntos de un jugador establecido |
| `lef_ranks_settled_games` | 20 | Mapas después de los cuales un jugador está establecido |
| `lef_ranks_min_players` | 2 | Humanos necesarios por lado para que un mapa cuente |
| `lef_ranks_min_games` | 5 | Mapas necesarios para aparecer en `!top` |
| `lef_ranks_announce` | 1 | Avisarle a cada jugador su cambio después de un mapa |

## Dónde se guarda y cuánto cuesta

Usa la base de datos de SourceMod: la entrada `lef_ranks` de `configs/databases.cfg` si la agregas (ej.
MySQL), si no `storage-local`, el archivo SQLite que SourceMod ya tiene
(`addons/sourcemod/data/sqlite/sourcemod-local.sq3`). Las consultas corren en segundo plano: una escritura
chica por jugador por mapa y una lectura cuando alguien entra. Prácticamente no consume nada.

Necesita [Left4DHooks](https://forums.alliedmods.net/showthread.php?t=321696).
