# Running Shoes

Hold **B** while you walk and the player runs: a tile takes half the
frames, and the legs cycle twice as fast to match, so the speed reads as
running rather than as the world scrolling faster.

- Walking only. The bicycle is already the fast option and is left at its
  vanilla speed; surfing is untouched too.
- Nothing else changes pace. Wild encounters, poison damage, daycare EXP
  and the Repel counter all tick once per tile, so running covers ground
  faster without shifting a single rate.
- Ledge hops keep their vanilla arc, and scripted movement — the escort
  out of Pallet, Oak's lab, every cutscene — never runs.
- B stays free everywhere it already did: in the overworld vanilla only
  reads the d-pad, A and START, so nothing is shadowed.

## Options

A **RUN SPEED** row in the options menu picks the pace: **2X** (default),
**1.5X**, or **OFF**. **RUN BUTTON** picks how it triggers: **HOLD B**
(default) or **ALWAYS**, which runs whenever you walk and needs no button
at all.

Whatever the speed, one tile is always one full leg cycle, so the walk
animation stays in step with the feet and alternates the same way vanilla
does.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_running_shoes/tests/jj_running_shoes_test.lua
```
