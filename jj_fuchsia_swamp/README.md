# Fuchsia Swamp

Fuchsia Swamp is an optional Surf-gated quest reached through a hidden cove on
Route 19. It adds a custom map, wild encounters, three reclamation-crew
battles, a four-Pokémon capstone battle, a rest hut, and repeatable solo move
lessons.

Version: 1.0.0.

## Prerequisites and installation

You need gen1recomp v0.1.39 or newer. The manifest also accepts the game's
`0.0.0-dev` source placeholder and rejects unsupported release versions. Follow
the [root installation guide](../README.md#before-you-install-a-mod), import
the `jj_fuchsia_swamp` release `.zip` through the **MODS** tab, and confirm the
mod is enabled.

Start from a save that can Surf and reach Route 19. The mod does not hand out
Surf, remove badges, or provide a shortcut to the cove. Back up a save before
installing or updating this content mod because its quest progress is stored in
the save's `jj_fuchsia_swamp` mod-data bucket.

## Find the quest

Speak with the Fuchsia City youngster for a hint, then travel to Route 19 and
look for the hidden cove in the open water. Surf through the cove entrance to
reach the swamp. The area has separated grass clearings and low-rate wild
encounters with level 30 to 34 Paras, Venonat, Gloom, and Grimer.

The Route 19 entrance and the swamp connection work in both directions. The
swamp host is in the clearing near the hut. Three reclamation crews stand in
different clearings. Talk to each one and win its battle:

- Dredger: level 37 Golduck and level 38 Machoke.
- Surveyor: level 37 Sandslash and level 38 Graveler.
- Pump Tech: level 38 Magnemite and level 39 Electrode.

After all three sites are cleared, speak to the host for the fixed battle:
level 40 Muk, level 41 Golem, level 42 Slowbro, and level 44 Snorlax. The host
opens the hut after the battle and warps you there on victory.

## Rest and return

The hut's rest point becomes available after the host is defeated. It can heal
the party, offer lessons, and ask whether you want to ride back to Fuchsia.
Choosing the return option warps to Fuchsia City. Completed crew sites and the
host battle are saved, so returning to the swamp does not reset the quest.

Losing a swamp battle heals the party, applies the normal blackout money loss,
and returns you to Fuchsia. Losing a tutor trial returns you to the hut. Prior
completed sites remain completed.

## Repeatable move lessons

The hut offers Body Slam, Rock Slide, Sludge, and Rest to any species. Choose a
lesson, then choose a healthy party Pokémon. That Pokémon fights alone against
the matching level 30 species, with the opponent one level above the selected
Pokémon, capped at level 55. Switching is not allowed.

Winning teaches the selected move. If the Pokémon has fewer than four moves,
the move is added directly. If it already has four, use the normal move-forget
screen or keep the old moves. A Pokémon that already knows the lesson is
refused before the trial. The lessons can be repeated for other Pokémon.

## Troubleshooting

If the cove is not visible, confirm that Surf works in the base game and that
you are checking Route 19's open water rather than the city shoreline. If the
host refuses to battle, one or more crew flags are still incomplete. If the hut
does not offer a lesson, defeat the host first. If a lesson refuses a Pokémon,
check that it is conscious and does not already know the move.

## Developer tutorials

[TUTORIAL.md](TUTORIAL.md) is a complete tour of the map, reciprocal map
connections, encounters, private quest flags, battle wrappers, tutor command,
tests, and packaging. [NPC_TEXT_GUIDE.md](NPC_TEXT_GUIDE.md) focuses on safely
changing an existing NPC's text after preparing local generated game data.

## For contributors

Read [LUA_GUIDE.md](LUA_GUIDE.md) for the map, quest state, battles, custom
commands, tutor, save migration, and tests.

From the game repository root:

```
luajit mods/jj_fuchsia_swamp/tests/jj_fuchsia_swamp_test.lua
luajit tests/run_modkit.lua
```

The focused suite checks map loading, Surf reachability, scripts, flags,
dialogue, battles, palettes, tutor scaling, and save migration.
