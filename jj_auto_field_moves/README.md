# Auto Field Moves

Field moves fire on contact instead of from the party menu, with no
textboxes: the move just happens (you still get the animation, sound,
and white blink):

- Walk into **water** to surf straight on.
- Walk into **trees, gym plants, or tall grass** to cut them down.
- Walk into a **boulder** to activate STRENGTH (then push as usual).
- Step into a **dark cave** to light it with FLASH.

FLY stays in the party menu: it has no contact trigger.

All the normal rules still apply: you need a pokémon with the move and
the badge, and special cases like the Cycling Road still refuse. With
**jj_hm_field_unlock** installed, the wider rule (can learn + HM owned +
badge) applies here too, automatically.

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
luajit mods/jj_auto_field_moves/tests/jj_auto_field_moves_test.lua
```
