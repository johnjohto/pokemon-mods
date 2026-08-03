# Caught Indicator

Caught Indicator places a small Poké Ball mark beside a wild Pokémon's name
when that species is already registered as caught in your Pokédex. It is a
battle HUD change only. Catching, Pokédex data, trainer battles, and link
battles continue to work as in the base game.

Version: 1.4.0.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_caught_indicator` release `.zip` through the **MODS** tab and
enable it. You can use the mod with an existing save. The optional widescreen
placement requires gen1recomp v0.1.31 or newer; older engines retain the
classic placement.

## Read the mark

The mark appears only in wild battles. A mark means the species is already
owned in the Pokédex. No mark means the species is not registered as owned yet.
Ghosts and the old man's tutorial battle do not receive a mark. Trainer and
link battles never receive one because their Pokémon cannot be caught.

## Options

| Option | Default | Details |
| --- | --- | --- |
| CAUGHT ICON | GEN 2 | **GEN 2** is a filled top with a small glint. **GEN 1** is an open-ball outline. Both are 8 by 8 pixels. |
| LAST BALL | On | Colors a mark for a species caught while this mod was installed. |
| ICON SHAKE | On | Makes the mark move with the classic enemy HUD shake. |

LAST BALL uses red for a Poké Ball, blue for a Great Ball, yellow for an Ultra
Ball, purple for a Master Ball, and green for a Safari Ball. Gen 1 saves
ownership but not the capture ball, so starters, gifts, trades, existing
Pokédex entries, and catches made while the mod was disabled keep the normal
HUD ink. A later successful catch while the mod is installed records that ball
for the species. Turn LAST BALL off to use normal HUD ink for every mark.

The mark dims with the battle's white screen flash. In the classic layout,
ICON SHAKE controls whether it follows the shaken enemy name. In widescreen,
the status box is outside the shaken picture area, so the mark is already still
regardless of the option.

## Layouts and upgrades

In the classic 160 by 144 layout, the mark sits beside the enemy name. In the
widescreen layout, choose **OPTION → BATTLE LAYOUT → WIDE** and the mark moves
to the immediate right of the enemy HP bar so it does not cover the name or
picture. Upgrading from 1.0.0 changes the icon's appearance because that
release had a single unconditional mark and did not have these shape and ball
options.

## Troubleshooting

If no mark appears, test a wild species you have already caught and make sure
the mod is enabled. A starter or gift may be owned but cannot have a recorded
LAST BALL color, which is expected. If the mark is present but not colored,
check LAST BALL and whether the relevant catch occurred after installation.

## For contributors

From the game repository root:

```
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```

Then run `luajit tests/run_modkit.lua` before release.
