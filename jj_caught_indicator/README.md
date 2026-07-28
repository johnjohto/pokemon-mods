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

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```
