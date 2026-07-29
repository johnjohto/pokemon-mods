# EXP Bar

Shows a Gen 2-style experience bar under the player HP bar in battle, so
you can see your active Pokémon's progress toward its next level without
opening the summary screen.

- The bar fills as your active battler gains EXP, wrapping through
  level-ups like Gold/Silver.
- Battle start and switch-ins snap to the current value; only EXP gains
  animate.
- EXP.ALL shares to the rest of the party don't move the bar — it tracks
  the active battler only, like Gen 2.
- Level 100 Pokémon show a full bar. Hidden anywhere the player HUD is
  hidden (Safari Zone, trainer intros).

## Options

An **EXP BAR** row in the options menu picks the fill style: **INK**
(default, matches every palette), **GEN 2 BLUE**, or **HP MATCH** (follows
the HP bar's green/yellow/red thresholds). **EXP BAR POS** picks the
height: **BORDER** (default, rides the HUD's bottom border row) or
**GEN 2** (one pixel higher).

## Battle layouts

Both of the engine's battle layouts are supported. In the classic
160×144 one the bar rides the player HUD's underline row, as it always
has. In the widescreen layout (**OPTION → BATTLE LAYOUT → WIDE**, added
in gen1recomp v0.1.31) the player's status is a box on the lower right
whose three interior rows are all taken — name, HP bar, HP numbers — so
the bar sits just inside that box's bottom frame row, spanning its inner
width. **EXP BAR POS** still shifts it a pixel either way.

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
luajit mods/jj_exp_bar/tests/jj_exp_bar_test.lua
```
