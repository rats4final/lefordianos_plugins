# Lite config: plugin picker

Tick what you want (`[x]`), untick what you don't (`[ ]`). My suggestions are pre-ticked:
bug fixes and quality-of-life are on, anything that **changes how the game plays** is off.

How to read the notes:
- **needs X**: requires another plugin or extension to be installed (they ship with the
  competitive repo).
- **ZoneMod tunes it**: ZoneMod changes this plugin's settings. In the lite config we'd use the
  plugin's own defaults unless you say otherwise; the note says what the default does.
- Where it lives: `optional/`, `fixes/`, `anticheat/` = `L4D2-Competitive-Rework/addons/sourcemod/plugins/<folder>/`;
  **Harry** = `L4D1_2-Plugins` (comes compiled); **MoYu** = `MoYu_Server_Stupid_Plugins/The Last Stand`
  (source only, we'd compile it with `build.sh`).

---

## 1. Required base (always on)

- [x] `left4dhooks`: the library almost everything below uses.
- [x] Extensions from the competitive repo: `sourcescramble`, `collisionhook`, `actions`,
      `builtinvotes`. Several fixes need one of these; installing all four is simplest.
- [x] `optional/l4d2lib`: helper library used by a few plugins.
- [x] SourceMod's base plugins: admin menu, bans, basic commands, comms, player commands, fun commands.
- [x] **`lef_teams_panel`** (ours): `!teams`, `!swapwith`, Team Management admin menu.

## 2. Bug fixes (from the competitive repo's `generalfixes.cfg`)

These fix engine/game bugs and keep the vanilla behaviour the game *meant* to have.

**Crashes, server stability, console**
- [x] `fixes/l4d2_null_cusercmd_fix`: prevents a lag-compensation server crash. *needs sourcescramble*
- [x] `fixes/l4d2_hltv_crash_fix`: blocks an exploit that crashes servers.
- [x] `fixes/command_buffer`: fixes "Cbuf_AddText: buffer overflow", which makes cvars silently reset to defaults.
- [x] `fixes/l4d2_script_cmd_swap`: safer replacement for the `script` command.
- [x] `fixes/l4d_console_spam`: hides useless errors in the server console.
- [x] `fixes/sv_consistency_fix`: fixes several `sv_consistency` issues.
- [x] `fixes/l4d2_fix_changelevel`: fixes problems when the map is changed by command/vote.
- [x] `fixes/l4d_votepoll_fix`: correct number of eligible voters in votes.
- [x] `fixes/bequiet`: hides "X changed name" / cvar-change spam, and stops spectators' chat
      reaching players during the round.
- [x] `fixes/l4d_skip_intro`: skip the intro cutscene on first maps so everyone can move right away.
- [ ] `fixes/TickrateFixes`: fixes door speed, fall damage, etc. **Only needed on 60/100 tick servers.**
- [ ] `fixes/l4d2_pistol_delay`: caps dual-pistol fire rate. **Only needed on high tickrate.**

**Survivors**
- [x] `fixes/firebulletsfix`: bullets come from the right spot (fixes shoot position).
- [x] `fixes/fix_fastmelee`: fixes melee swinging faster than it should.
- [x] `fixes/l4d2_melee_damage_control`: melee applies the correct damage to infected.
- [x] `fixes/l4d2_incap_fire_fix`: incapped survivors can shoot normally while holding shove.
- [x] `fixes/l4d2_sg552_zoom_fix`: SG552 zoom no longer gets the camera stuck.
- [x] `fixes/weapon_spawn_duplicate_fix`: weapon spawns can't be looted past their count.
- [x] `fixes/l4d_fix_rocket_jump`: some surfaces no longer launch survivors into the air.
- [x] `fixes/l4d_fix_stagger_dir`: survivors get staggered in the right direction.
- [x] `fixes/l4d2_shove_fix`: fixes shove direction. *needs actions*
- [x] `fixes/l4d_fix_common_shove`: commons can be shoved while crouching/falling/landing. *needs actions*
- [x] `fixes/l4d2_ellis_hunter_bandaid_fix`: Ellis' get-up after a hunter matches the other survivors.
- [x] `fixes/l4d_fix_deathfall_cam`: death-fall cameras can't lock your view permanently.
- [x] `optional/nodeathcamskip`: can't skip your death timer by going spectator.
- [x] `optional/l4d_return_thrown_items`: pills/adrenaline you tried to pass come back if the pass failed.

**Special Infected**
- [x] `fixes/l4d2_ai_damagefix`: AI SI take and deal damage like human SI.
- [x] `fixes/l4d_backjump_fix`: hunters can pounce off non-static props.
- [x] `fixes/l4d2_no_post_jockey_deadstops`: blocks the melee-spam deadstop exploit after a jockey ride.
- [x] `fixes/l4d2_jockeyed_ladder_fix`: jockeyed survivors stop sliding down ladders. *needs collisionhook*
- [x] `fixes/l4d2_jockey_hitbox_fix`: correct jockey hitbox while riding.
- [x] `fixes/l4d2_boomer_shenanigans`: boomers can't vomit while staggered by a shove.
- [x] `fixes/l4d2_boomer_ladder_fix`: boomer-on-ladder bug. *needs sourcescramble*
- [x] `fixes/l4d_vomit_trace_patch`: vomit isn't blocked by infected teammates. *needs sourcescramble*
- [x] `fixes/l4d_tongue_bend_fix`: tongues don't break for "bending too many times".
- [x] `fixes/l4d_tongue_block_fix`: infected teammates don't block a tongue. *needs collisionhook, sourcescramble*
- [x] `fixes/l4d_tongue_float_fix`: fixes instant-choke "floating" pulls.
- [x] `fixes/l4d2_fix_rocket_pull`: smoker pulls don't launch survivors upward.
- [x] `fixes/l4d2_charge_target_fix`: several charger target bugs.
- [x] `fixes/l4d2_spit_cooldown_frozen_fix`: spit cooldown no longer gets stuck.
- [x] `fixes/l4d2_spit_spread_patch`: fixes spit spreading wrongly. *needs sourcescramble, collisionhook. ZoneMod tunes it: default = no spit spread in saferooms, as vanilla intends.*
- [x] `fixes/l4d_fix_shove_duration`: SI don't get shoved by "nothing".
- [x] `fixes/l4d_fix_saferoom_ghostspawn`: ghosts can't spawn inside the saferoom.
- [x] `fixes/l4d_fix_finale_breakable`: SI can break finale-area props before the finale. *needs sourcescramble*
- [x] `fixes/l4d2_fix_firsthit`: SI first-hit classes stay consistent between halves.

**Tank and props**
- [x] `fixes/frozen_tank_fix`: tanks don't stay frozen in place.
- [x] `fixes/l4d_fix_punch_block`: commons don't block tank punches. *needs sourcescramble, collisionhook*
- [x] `fixes/l4d2_rock_trace_unblock`: SI don't block the rock hit check. *needs sourcescramble*
- [x] `fixes/l4d2_fix_tank_rock_handoff`: cancels a half-thrown rock when tank control passes.
- [x] `fixes/l4d2_tank_spawn_antirock_protect`: a new tank player isn't hit by a stray rock at spawn.
- [x] `fixes/l4d2_scripted_tank_stage_fix`: finales don't skip tank stages.
- [x] `fixes/l4d_fix_rotated_physblocker`: invisible blockers don't stop hittables wrongly.
- [x] `fixes/l4d_prop_touching_rules`: sane rules for props being pushed by players. *needs sourcescramble*
- [x] `fixes/l4d_fix_prop_los`: thin props block line of sight properly.
- [x] `fixes/l4d2_car_alarm_hittable_fix`: a hittable hitting an alarm car doesn't set it off; survivors touching it always do.
- [x] `fixes/l4d2_explosiondmg_prev`: stops explosion damage to infected from entities.

**Map flow and teams**
- [x] `fixes/l4d_consistent_escaperoute`: the escape route is the same for both teams. *needs sourcescramble*
- [x] `fixes/l4d2_fix_team_shuffle`: puts teams back automatically if they get scrambled on map change.
- [x] `fixes/l4d2_ladderblock`: players can't block others climbing a ladder.

**These are in `generalfixes.cfg` but change gameplay — your call**
- [ ] `fixes/l4d_static_punch_getup`: makes the tank-punch get-up a fixed length. **Default
      shortens it to half (0.5)**, which favours survivors. Can be set close to vanilla.
- [ ] `fixes/l4d2_jockey_jumpcap_patch`: jockeys can't cap with a normal jump in some situations (3 s block).
- [ ] `fixes/l4d2_tank_flying_incap`: survivors go flying on the punch that incaps them (vanilla just drops them).
- [ ] `fixes/l4d2_shadow_removal`: removes shadows so survivors can't see infected through walls.
      Arguably an exploit fix, but it does change what you see.
- [ ] `fixes/annoyance_exploit_fixes`: a bundle of anti-annoyance tweaks. *needs builtinvotes*
- [ ] `optional/l4d2_sound_manipulation`: can block heartbeat/incap sounds. **Default does nothing**;
      only useful if we set flags.

## 3. Anti-cheat
- [x] `anticheat/l4d2_noghostcheat`: ghost infected aren't sent to survivors' game, so wallhacks can't see them.
- [x] `optional/l4d2_block_autoaim`: removes controller aim-assist and an autoaim exploit.
- [x] `optional/l4d_texture_manager_block`: kicks players trying the "mat_hack" wallhack.
- [ ] `optional/l4d_thirdpersonshoulderblock`: kicks players using third-person to peek around corners.
- [x] `optional/lerpmonitor`: tracks players' lerp; can kick extreme values. *ZoneMod tunes it*
- [ ] `optional/ratemonitor`: tracks players' rate settings.

## 4. Quality of life and info (no balance change)
- [x] `optional/l4d2_tank_props_glow`: hittables glow while a tank is alive, and don't fade. *ZoneMod tunes colour/range*
- [x] `optional/l4d_tank_damage_announce`: who did how much damage to the tank.
- [x] `optional/l4d2_tank_announce`: chat message + sound when a tank spawns.
- [x] `optional/pill_passer`: pass pills/adrenaline with Reload.
- [x] `optional/current`: `!current` shows how far the survivors are (flow %).
- [x] `optional/coinflip`: `!coinflip` / `!roll`.
- [x] `optional/teamflip`: `!teamflip` picks a random team.
- [x] `optional/l4d2_stats`: skeets/crowns/levels printed to chat.
- [ ] `optional/l4d2_skill_detect`: the full skill detector (skeets, crowns, high pounces, etc.). Overlaps l4d2_stats.
- [ ] `optional/survivor_mvp`: survivor MVP at the end of the round.
- [ ] `optional/l4d2_playstats`: detailed round stats (MVP, accuracy, skills), kept across disconnects.
- [x] `optional/si_class_announce`: infected team sees which SI classes are up at round start.
- [x] `optional/l4d_common_ragdolls_be_gone`: dead commons' ragdolls vanish (less clutter, less lag).
- [x] `optional/caster_assister`: spectators can set their fly speed and move up/down.
- [ ] `optional/specrates`: low network rates for spectators (saves bandwidth).
- [x] `optional/autopause`: auto-pauses if a player crashes, and gives them their spot back. *needs pause.smx*
- [x] `optional/l4d2_ghost_warp`: ghost infected can warp to survivors with a command.
- [x] `optional/blocktrolls`: no calling votes while others are still loading.
- [x] `optional/l4d2_block_bot_pills`: bots can't use pills (stops them wasting yours). *needs actions*

## 5. Admin and server management
- [x] `optional/pause`: `!pause` with both teams readying up to unpause, admin force-pause. *needs builtinvotes*
- [x] `l4d_pause_message`: blocks pause commands when the server can't pause.
- [x] **Harry** `l4d_afk_commands`: `!spec`/`!survivors`/`!infected` with anti-abuse rules. **Chosen.**
- ~~`optional/playermanagement`~~: not used. It registers the same `!spec` commands as `l4d_afk_commands`.
- [x] **Ours (patched)** `l4d_tank_control_eq`: everyone on infected gets a turn as tank, in order.
      The original wouldn't load without Ready-Up even though it never uses it; our copy in
      `plugins/l4d_tank_control_eq` drops that requirement.
- [x] **Harry** `l4d2_spec_stays_spec` (MoYu has one too): spectators stay spectators on map change.
- [x] `optional/l4d2_setscores`: admins (or a vote) can fix the scores. *needs builtinvotes*
- [ ] `optional/slots_vote`: vote to change the number of slots. *needs builtinvotes*
- [ ] **Harry** `l4d2_vote_manager3`: control who may call the game's built-in votes.
- [ ] **Harry** `L4DVSAutoSpectateOnAFK`: moves AFK players to spectator after a while.
- [ ] **Harry** `l4d_kickloadstuckers`: kicks players stuck on "connecting".
- [ ] **Harry** `l4d_reservedslots`: admins can join a full server.
- [ ] **Harry** `savechat`: logs chat to a file.
- [ ] **Harry** `l4d2_mission_manager` + ACS: automatic campaign rotation, with a vote for the next campaign at the finale.

## 5b. Tank and witch every map, with flow % announced

Works **without Ready-Up and without confogl**. Ready-Up is optional for all of these.
- [x] **Ours** `lef_boss_spawns`: rolls a per-map chance for tank and witch (same for both teams),
      spawns second-half bosses on the first half's spot, and makes sure flows get announced.
- [x] `optional/witch_and_tankifier`: picks a tank and a witch spawn on every map, avoiding bad
      spots listed per map (108 maps covered in `configs/l4d2lib/mapinfo.txt`) and keeping the witch
      away from the tank. *needs l4d2lib*
- [x] `optional/l4d_boss_percent`: announces "Tank: 63%, Witch: 28%" when survivors leave the
      saferoom; `!boss` / `!tank` / `!witch` show it any time.
- [ ] `optional/l4d_boss_vote`: players can vote to set custom tank/witch flows. *needs builtinvotes*
- [ ] `optional/bossspawningfix`: makes versus boss spawns obey the `versus_*` cvars. *ZoneMod tunes it*
- Map files: `static_tank_map` / `static_witch_map` lines (maps with scripted tanks, where no
  extra tank should be added) come from ZoneMod's `shared_settings.cfg` and would go in our cfg.

## 5c. Scores and comebacks

- [x] **Ours** `lef_score_info`: explains the score: what each map is worth, the gap, what's
      needed to win the map / take the lead, and a map wins count. **Changes no points.**
- [ ] **Ours** `lef_comeback_bonus`: the team that's behind by 100+ earns +15% of the distance it
      covers, capped at the gap. **Changes points.** *needs `optional/l4d2_penalty_bonus`*

## 6. Extra fixes from Harry and MoYu (not in ZoneMod)
- [x] **Harry** `l4d_revive_reload_interrupt`: reviving no longer jams your weapon mid-reload.
- [x] **Harry** `l4d_switch_team_survivor_dead_fix`: switching to survivors no longer spawns you dead/incapped.
- [x] **Harry** `jockey_ride_team_switch_teleport_fix`: a jockey switching team mid-ride no longer teleports the survivor.
- [x] **Harry** `l4d_minigun_fly_fix`: blocks the minigun flying glitch.
- [x] **Harry** `l4d2_gascan_flame_fix`: gascans that sometimes wouldn't ignite now do.
- [x] **Harry** `l4d_witch_retreat_panic_fix`: a retreating witch doesn't come back when a horde starts.
- [x] **Harry** `l4d_ghost_spawn_exploit`: blocks a spawn-and-teleport ghost exploit.
- [x] **Harry** `l4d_exploit_dmg_block`: blocks damage exploits (e.g. throw a molotov, then switch teams).
- [x] **Harry** `l4d2_survivor_mourn_fix`: survivors can mourn L4D1 survivors on the L4D2 set.
- [x] **Harry** `l4d_shotgun_sound_fix`: shotguns have sound in third person.
- [x] **Harry** `l4d2_chainsaw_fix`: fixes a Linux server crash with chainsaws.
- [x] **MoYu** `l4d2_fix_common_flee`: sitting/lying commons don't get stuck when fleeing.
- [x] **MoYu** `l4d_fix_target_replace`: infected keep the right target when a survivor is replaced by a bot.
- [x] **MoYu** `l4d_spray_origin_fix`: sprays appear where they should.
- [ ] **Harry** `physics_object_pushfix`: walking into gascans/propane no longer pushes them.
- [ ] **Harry** `l4d_witch_bash_wandering`: shoving a wandering witch startles her (vanilla doesn't).

## 7. Gameplay and balance changes (ZoneMod's choices — off unless you want them)

**Survivors**
- [ ] `optional/l4d2_pickup`: picking up pills/melee doesn't switch your weapon; pick-ups get interrupted when incapped by spit/tank.
- [ ] `optional/l4dhots`: pills and adrenaline heal over time instead of instantly.
- [ ] `optional/starting_items`: everyone starts each round with items.
- [ ] `optional/nosaferoomkits`: removes saferoom medkits.
- [ ] `optional/l4d2_saferoom_item_remove`: removes extra saferoom items. *needs l4d2_saferoom_detect*
- [ ] `optional/l4d_weapon_limits`: limits how many of each weapon a team can carry.
- [ ] `optional/l4d2_weaponrules`: replaces weapon spawns by rules (e.g. T2 → T1).
- [ ] `optional/l4d2_weapon_attributes` + `l4d2_static_shotgun_spread`: changes weapon stats and shotgun spread.
- [ ] `optional/l4d2_magnum_incap`: incapped survivors with a magnum get pistols instead.
- [ ] `optional/l4d2_ladder_rambos`: survivors can shoot while on ladders.
- [ ] `optional/noteam_nudging`: survivors don't push each other.
- [ ] `optional/fix_engine`: blocks the ladder-speed glitch, no-fall-damage bug and health-boost glitch.
      (Mostly exploit fixes; on by default for 3 of them.)
- [ ] `optional/l4d2_nobhaps`: blocks bunny-hopping.
- [ ] `optional/temphealthfix`: correct temp health after hittable/ledge incaps.
- [ ] `optional/finalefix`: incapped survivors don't get full distance points when the rescue leaves.
- [ ] `optional/l4d2_melee_shenanigans`: shoves don't slow tank/charger; a punched survivor holding a melee switches to primary.

**Special Infected**
- [ ] `optional/l4d2_uniform_spit`: spit does a flat damage per second (*this is the reduced-spitter-damage one you didn't like*).
- [ ] `optional/l4d2_spitblock`: no spit damage in certain map spots.
- [ ] `optional/si_fire_immunity`: SI burn for less time (default: fire goes out after 1 s; tank can't burn).
- [ ] `optional/l4d_bash_kills`: SI can't be shoved to death.
- [ ] `optional/l4d_pounceprotect`: taking damage doesn't stop a hunter from pouncing.
- [ ] `optional/l4d2_hunter_no_deadstops`: hunters in the air can't be deadstopped by shoves.
- [ ] `optional/l4d2_m2_control_eq`: no instant re-pounce after a shove; shove penalty tweaks.
- [ ] `optional/l4d2_nobackjumps`: blocks hunter backjumps.
- [ ] `optional/l4d_jockey_ledgehang`: changes jockey recharge after a ledge-hang.
- [ ] `optional/l4d2_unsilent_jockey`: jockeys make sound constantly.
- [ ] `optional/l4d2_si_ffblock`: infected can't hurt each other.
- [ ] `optional/l4d2_si_staggers`: SI aren't staggered by other SI (boomer, charger, witch).
- [ ] `optional/l4d2_dominatorscontrol`: allows "quad caps" in native order.
- [ ] `optional/l4d2_fix_spawn_order`: fixed SI spawn rotation.
- [ ] `optional/l4d2_nospitterduringtank`: no spitter while a tank is up.
- [ ] `optional/despawn_health`: SI get health back when they despawn.
- [ ] `optional/l4d2_nosecondchances`: SI bots that were human-controlled with a cap don't die instantly.
- [ ] `optional/charger_incap_damage`: changes charger pound damage on incapped survivors.
- [ ] `optional/l4d2_getup_slide_fix` / `optional/l4d2_getup_fixes` / `optional/l4d2_godframes_control_merge`:
      get-up animations, god frames and friendly-fire rules. *ZoneMod tunes them heavily*
- [ ] `optional/staggersolver`: no inputs during stumbles.
- [ ] `optional/l4d2_tongue_timer`: changes smoker tongue cooldown in some cases.
- [ ] `optional/l4d2_uncommon_blocker`: removes uncommon infected.
- [ ] `optional/blockheatseekingchargers`: chargers don't "home in" after a survivor gets up.

**Tank and hordes**
- [ ] `optional/l4d2_hittable_control`: changes hittable damage. *ZoneMod tunes it heavily*
- [ ] `optional/l4d2_tank_damage_cvars`: per-attack tank damage.
- [ ] `optional/l4d2_tank_attack_control`: tank rock/punch choice tweaks.
- [ ] `optional/l4d2_tankrage`: tank keeps rage while survivors run back.
- [ ] `optional/checkpoint-rage-control`: tank loses rage while survivors hide in the saferoom.
- [ ] `optional/l4d_tank_rush`: no distance points while a tank is alive.
- [ ] `optional/l4d2_tank_horde_monitor`: changes infinite hordes during tank.
- [ ] `optional/l4d_tank_painfade`: tank's screen flashes red when hurt.
- [ ] `optional/l4d_tankpunchstuckfix`: punched survivors don't get stuck in the ceiling. (Close to a pure fix.)
- [ ] `optional/rock_stumble_block`: rocks don't vanish if the tank is stumbled mid-throw. (Close to a pure fix.)
- [ ] `optional/l4d2_bw_rock_hit`: rocks don't pass through black-and-white survivors. (Close to a pure fix.)
- [ ] `optional/smart_ai_rock`: AI tanks don't throw underhand rocks they can't aim.
- [ ] `optional/l4d2_profitless_ai_tank`: passing the tank to AI doesn't give a free respawn.
- [ ] `optional/boomer_horde_equalizer_refactored`: boomer hordes are the same size every time. *needs sourcescramble*
- [ ] `optional/l4d_equalise_alarm_cars`: the same cars are alarmed for both teams.
- [ ] `optional/l4d2_ledgeblock`: no ledge hanging on some maps.
- [ ] `optional/eq_finale_tanks`: changes how many tanks spawn in finales.
- [ ] `optional/l4d2_antibaiter`: forces a horde if infected wait too long to attack.
- [ ] `optional/l4d2_collision_adjustments`: rocks pass through commons, etc. *needs collisionhook*

## 8. Competitive-only (not suggested for the lite config)

These only make sense with ready-up / scoring / confogl, so they belong in the Vanilla+ match
mode if anywhere: `readyup`, `l4d2_hybrid_scoremod_zone`, `caster_system`, `spechud`,
`panel_text` (only adds text to the Ready-Up screen), `cfg_motd`, `confoglcompmod`, `match_vote`, `predictable_unloader`,
`l4d2_blind_infected`, `l4d2_map_transitions`, `l4d2_saferoom_detect`.

> **Ready-Up check (2026-10-01):** of every plugin here, only `l4d_tank_control_eq` (now patched,
> see section 5) and `panel_text` *require* Ready-Up. All the others just use it when it's there.
