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

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_exp_bar/tests/jj_exp_bar_test.lua
```
