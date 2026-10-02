[English](README.md)

# si_class_announce (parchado)

**Special Infected Class Announce** de Tabun y Forgetest, del repo L4D2-Competitive-Rework
(`addons/sourcemod/scripting/si_class_announce.sp`, versión 1.0.6, commit `f8df6a13`).

Cuando los sobrevivientes salen del refugio, los sobrevivientes y espectadores ven las clases del equipo
infectado (ej. "Hunter, Smoker, Boomer, Charger"). Nuestro panel de `lef_round_start` también las
muestra antes de eso.

## Nuestro cambio (1.0.6-lef1)

También agrega esa línea al panel de Ready-Up, pero uno de sus temporizadores (que arranca cuando alguien
se une a infectados) llamaba a Ready-Up sin revisar que estuviera cargado: "Native is not bound" en el
log de errores. Ahora revisa primero. Nada más cambió.
