[Español](README.es.md)

# si_class_announce (patched)

**Special Infected Class Announce** by Tabun and Forgetest, from L4D2-Competitive-Rework
(`addons/sourcemod/scripting/si_class_announce.sp`, version 1.0.6, upstream commit `f8df6a13`).

When the survivors leave the saferoom, survivors and spectators see the infected team's classes
(e.g. "Hunter, Smoker, Boomer, Charger"). Our `lef_round_start` panel also shows them before that.

## Our change (1.0.6-lef1)

It also adds that line to Ready-Up's panel, but one of its timers (started whenever someone joins
infected) called Ready-Up without checking that Ready-Up is loaded: "Native is not bound" in the error
log. Now it checks first. Nothing else changed.
