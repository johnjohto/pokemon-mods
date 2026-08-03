# Running Shoes

Running Shoes makes overworld movement faster without speeding up systems that
count completed tiles. At the default setting, hold B while walking to cross a
tile in half the normal frames. Wild encounters, poison damage, daycare
experience, and the Repel counter still advance once per tile.

Version: 1.1.1.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_running_shoes` release `.zip` through the **MODS** tab, confirm
that it is enabled, and load or start a save. You can use it with an existing
save. Open the game's mod options to adjust its settings.

## Basic use

The default is **RUN SPEED: 2X** and **RUN BUTTON: HOLD B**. In the overworld,
hold B and a direction to run on foot. Release B to walk normally. The mod does
not make scripted movement run, so cutscenes and escorted movement keep their
usual pace. Ledge hops also keep their normal movement.

By default, the bicycle and Surf remain at vanilla speed. Configure their rows
separately if you want faster travel in those modes.

## Options

| Option | Choices | Meaning |
| --- | --- | --- |
| RUN SPEED | 2X, 1.5X, OFF | Sets the on-foot multiplier. At 2X, foot travel matches the bicycle's usual step length. |
| RUN BUTTON | HOLD B, TOGGLE, ALWAYS | Chooses how faster movement begins. |
| BIKE SPEED | VANILLA, MATCH RUN, 1.5X, 2X | Sets the bicycle multiplier when the chosen trigger is active. |
| SURF SPEED | VANILLA, MATCH RUN, 1.5X, 2X | Sets the Surf multiplier when the chosen trigger is active. |

With **HOLD B**, keep B held to use an eligible faster setting. With
**TOGGLE**, tap B in the free-roam overworld once to turn faster movement on
and again to turn it off. The toggle is not saved, so loading a save returns it
to off. Tapping B in a menu or battle cannot flip it. With **ALWAYS**, every
eligible movement mode uses its configured multiplier without holding B.

**MATCH RUN** uses the selected on-foot multiplier. It is useful for the
bicycle because it preserves its two-to-one advantage over a runner. Surf is
checked before bicycle state, so a step on water follows **SURF SPEED**.

## What the mod does not change

The game still handles each completed tile normally. Faster movement does not
make wild encounters rarer, alter poison or Repel counting, or accelerate
daycare experience. The visual walk cycle is accelerated with the movement so
the sprite does not slide between tiles.

## Troubleshooting

If you are not moving faster, check **RUN SPEED** and whether your selected
trigger is active. **OFF** and **VANILLA** deliberately preserve normal speed.
For bicycle or Surf travel, change the matching row as well; changing RUN SPEED
alone affects only foot travel. Faster movement is not expected during a menu,
battle, or scripted scene.

## For contributors

From the game repository root:

```
luajit mods/jj_running_shoes/tests/jj_running_shoes_test.lua
```

Then run `luajit tests/run_modkit.lua` before release.
