# Auto Field Moves

Auto Field Moves activates selected field moves when you walk into the thing
they affect. It keeps the game's checks, animation, sound, and map rules, but
skips the party-menu action and its textboxes.

Version: 1.1.4.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_auto_field_moves` release `.zip` through the **MODS** tab and
confirm it is enabled. You can add it to an existing save. The mod has no
options and requires no configuration.

By itself, the mod uses the normal field-move requirement: a party Pokémon
must know the relevant move and you must meet its usual badge and location
rules. If [HM Field Unlock](../jj_hm_field_unlock/README.md) is enabled too,
an eligible party species plus the HM and badge is enough instead.

## Contact actions

| Walk into | Result | Notes |
| --- | --- | --- |
| Water | Starts Surf and attempts to move onto the water tile. | You must not already be Surfing. |
| A cuttable tree, gym plant, or tall-grass tile | Uses Cut. | The target must pass the game's normal Cut check. |
| A pushable boulder | Activates Strength. | After activation, push boulders normally. |
| A dark cave | Uses Flash as the map is entered. | This is for dark maps such as Rock Tunnel. |

Fly is intentionally not automated. Open the party menu and choose Fly when
you want to travel by air.

## What stays the same

The mod does not grant moves, badges, or access through locations that reject
the field action. Restrictions such as Cycling Road and map-specific movement
rules remain in place. Strength activation is not a boulder push by itself;
after the activation effect ends, walk into the boulder again to push it.

When Flash is available on entering a dark cave, the mod records the lit state
and refreshes the cave lighting. Version 1.1.4 fixes a recursive activation
that could crash the game during that transition.

## Troubleshooting

If contact does nothing, face and walk into the target rather than choosing a
move from the party menu. Confirm that a party Pokémon meets the relevant
field requirement and that the target is one the base game accepts. If you use
HM Field Unlock, also check its HM, badge, and learnability requirements.

## For contributors

Read [LUA_GUIDE.md](LUA_GUIDE.md) for collision hooks, engine continuations,
map-entry lighting, and regression tests.

From the game repository root:

```
luajit mods/jj_auto_field_moves/tests/jj_auto_field_moves_test.lua
```

Then run `luajit tests/run_modkit.lua` before release.
