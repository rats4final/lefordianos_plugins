[English](README.md)

# l4d2_playstats (parchado)

**Player Statistics** de Tabun y A1m`, del repo L4D2-Competitive-Rework
(`addons/sourcemod/scripting/l4d2_playstats.sp`, versión 1.1.4, commit `f8df6a13`).

Estadísticas al final de la ronda (MVP, precisión, jugadas, fuego amigo), aunque los jugadores se
desconecten.

## Nuestro cambio (1.1.4-lef1)

Las tablas se escriben en la consola en bloques de 4 KB, como máximo 10, de 4 filas cada uno. Listan a
cada jugador registrado en la sesión (hasta 64, incluidos los que ya se fueron), así que después de una
noche larga la tabla de fuego amigo necesitaba un bloque 11: "Array index out-of-bounds (index 10, limit
10)". Ahora hay lugar para 32 bloques (`MAXCHUNKS`), suficiente para 64 jugadores más los encabezados.
Nada más cambió.
