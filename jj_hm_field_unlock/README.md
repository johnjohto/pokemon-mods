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
luajit mods/jj_hm_field_unlock/tests/jj_hm_field_unlock_test.lua
```
