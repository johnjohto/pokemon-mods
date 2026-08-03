# EXP Bar

EXP Bar draws a one-pixel Gen 2-style experience bar under the active
Pokémon's HP bar during battle. It shows progress toward that Pokémon's next
level without opening the Summary screen.

Version: 1.1.1.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_exp_bar` release `.zip` through the **MODS** tab and enable it.
There are no save prerequisites or setup steps. The bar is hidden whenever the
player HUD is hidden, including Safari Zone scenes and trainer introductions.

## How the bar behaves

At battle start and when you switch Pokémon, the bar snaps to the active
Pokémon's current experience. After that Pokémon gains experience, the fill
animates to the new value. A level-up wraps the fill through the next level,
matching the way a Gen 2 bar behaves. A level 100 Pokémon shows a full bar.

The bar tracks the active battler only. EXP.ALL shares sent to other party
members do not move the bar while they are not active, and a switch updates the
bar to the new active Pokémon.

## Options

| Option | Default | Details |
| --- | --- | --- |
| EXP BAR | INK | **INK** uses the HUD's normal ink. **GEN 2 BLUE** uses blue. **HP MATCH** uses green, yellow, or red based on the active Pokémon's HP thresholds. |
| EXP BAR POS | BORDER | **BORDER** draws on the HUD's bottom border row. **GEN 2** places it one pixel higher. |

## Battle layouts and 3D-BTL

The classic 160 by 144 layout places the bar under the player HUD underline.
The widescreen layout, enabled with **OPTION → BATTLE LAYOUT → WIDE** in game
builds that provide it, places the bar inside the lower-right player status
box. The position option still shifts it by one pixel.

When Dramatic Shape Voxel Mod's **3D-BTL** mode is active, EXP Bar follows the
player HUD at the right edge of the 3D battle scene and scales with that HUD.

The bar hides during the Mimic selection panel and avoids the move-selection
panel where the panel would cover it. It also follows the classic battle HUD
shake.

## Troubleshooting

If the bar is not visible, check that the mod is enabled and that the current
screen is an ordinary battle with the player HUD showing. It will not appear in
the hidden-HUD scenes listed above. If it appears in the wrong style or height,
open the mod options and check EXP BAR and EXP BAR POS.

## For contributors

From the game repository root:

```
luajit mods/jj_exp_bar/tests/jj_exp_bar_test.lua
```

Then run `luajit tests/run_modkit.lua` before release.
