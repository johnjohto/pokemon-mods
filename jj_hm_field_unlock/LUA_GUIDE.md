# Lua guide: HM Field Unlock

This mod changes one rule in the field-move eligibility path. It does not teach
moves, alter battle movesets, or implement a second field-move system.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Finds HM items, checks eligibility, wraps the overworld rule, and adds missing party actions. |
| `tests/jj_hm_field_unlock_test.lua` | Checks the rule, Bag and PC storage, party-menu injection, and battle isolation. |

## `main.lua`, from top to bottom

The entry function imports `OverworldController` and `FieldDefaults`, then
stores the live game when `game.ready` fires. `hmCache` is built lazily by
scanning `data.items`: an item whose `machine.kind` is `HM` maps its move to the
HM item ID. Lazy construction avoids reading data before the game loader has
finished. The cache is safe because the data set does not change during play.

`ownsHm` accepts an item count in `save.inventory` or `save.pcItems`. It uses a
count greater than zero, so a stale zero entry does not qualify. `badgeOwned`
reads the engine's `hmBadges` constants. `canLearn` checks the selected
species' `tmhm` list, not its current moves.

`firstLearner` is the central rule. It rejects non-HM moves, a missing badge, a
missing HM, and a party with no eligible species. It returns the first matching
party Pokémon, including a fainted one, because the vanilla field rule ignores
HP. Keeping this rule in one function prevents activation and menu display from
drifting apart.

The wrapper around `Overworld.partyKnows` calls the original method first. A
Pokémon that already knows the move keeps the normal result. If the original
method finds nothing, the wrapper applies `firstLearner` using the stored game.
The exported `canUse` function gives sibling mods, especially Auto Field Moves,
the same rule without reaching into private locals.

The `FIELD` table pairs move IDs with the engine's existing party-menu action
IDs. The `ui.party.submenu` wrapper starts with the vanilla items, then exits
for battles, missing overworld context, or no live game. It applies location
filters for Fly and Flash, avoids duplicate known moves, checks species
learnability, and appends the vanilla action. The action itself is not custom;
the engine still performs its normal field validation and effect.

## Test tour

The test pins known species from the fixture data, then checks each requirement
separately. It removes the HM, moves the HM to PC storage, removes the badge,
and supplies a species that cannot learn Surf. It verifies `partyKnows` and the
submenu agree, that FLY and FLASH obey location rules, and that battle context
does not receive the overworld-only actions.

Run it from the game checkout:

```
luajit mods/jj_hm_field_unlock/tests/jj_hm_field_unlock_test.lua
```

## Safe extension points

Use `firstLearner` for any new caller. Do not duplicate the HM, badge, or
learnability checks in another mod. If upstream adds an eligibility hook, move
the rule there and retain the exported function as a compatibility seam. Keep
the battle guard in the submenu wrapper: field eligibility must never grant a
battle move.
