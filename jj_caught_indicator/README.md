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
half, the classic red-top silhouette in one bit) or **GEN 1** (a small
open ball, all outline). Both are 8×8 and drawn in the HUD's own ink, so
either recolors with the rest of the screen.

Upgrading from 1.0.0 changes the mark you see, since that release drew
one icon unconditionally and neither option is a pixel match for it.

## Battle layouts

Both of the engine's battle layouts are supported. In the classic 160×144
one the mark sits under the foe's name. In the widescreen layout
(**OPTION → BATTLE LAYOUT → WIDE**, added in gen1recomp v0.1.31) the foe's
status box draws its *name* exactly where that mark used to go, so the
icon moves to the immediate right of the foe's HP bar, clear of the box
and of the enemy's picture.

Older engines are unaffected: the mod asks whether the battle is wide
before assuming it can be, so it keeps working on versions that have no
widescreen layout at all.

## Install

Download the `.zip` from the release and, **without unzipping it**, drag it
onto the game's start screen — or open the **MODS** tab there and press
*Import mod .zip*. It installs itself and comes up enabled.

Unzipping it next to `gen1recomp.exe` does not work: a released build is not
portable, so the game never reads that folder and the mod silently never
appears. See the [root README](../README.md#install) for the folder to use
if you would rather place it by hand.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```
