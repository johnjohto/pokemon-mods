# Caught Indicator

A pokeball icon appears next to a wild pokémon's name in battle if its
species is already registered as caught in your Pokédex, like Pokémon
Gold/Silver and later. No more checking the dex before deciding whether
to weaken it or run.

- Wild battles only: trainer and link battles get no icon (their pokémon
  can't be caught anyway).
- Ghosts and the old man's tutorial battle get no icon either.
- The icon rides the enemy HUD, so it shakes and slides with the name it
  sits next to.
- Purely visual: catching, the dex, and everything else play as vanilla.

## Options

A **CAUGHT ICON** row in the options menu picks the mark: **GEN 2**
(default — a filled top with a glint at the upper left over an open lower
half, the classic red-top silhouette in one bit) or **BALL** (the open
pokeball outline that 1.0.0 drew). Both are 8×8 and drawn in the HUD's
own ink, so either recolors with the rest of the screen.

Upgrading from 1.0.0 changes the mark you see, since that release drew
the outline unconditionally. Pick **BALL** to keep it.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```
