# Auto Field Moves

Field moves fire on contact instead of from the party menu:

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

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_auto_field_moves/tests/jj_auto_field_moves_test.lua
```
