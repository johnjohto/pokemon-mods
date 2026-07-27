# HM Field Unlock

HMs work in the field without being taught. If a party pokémon *can
learn* the move, having the HM in your bag or PC box plus the required
badge is enough:

- **CUT** — Cascade Badge + HM01
- **FLY** — Thunder Badge + HM02
- **SURF** — Soul Badge + HM03
- **STRENGTH** — Rainbow Badge + HM04
- **FLASH** — Boulder Badge + HM05

The party menu shows these moves on any pokémon that can learn them, so
you can see the rule working. Battle is unchanged: using the move in a
fight still requires teaching it with the HM.

Pairs with **jj_auto_field_moves**: when both are installed, walking into
water, trees, boulders, and dark caves works under this wider rule too.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_hm_field_unlock/tests/jj_hm_field_unlock_test.lua
```
