# Lua guide: Fuchsia Swamp

Fuchsia Swamp is the largest content mod in this repository. It combines map
data, map connections, encounters, scripts, trainer records, custom sprites,
save migration, custom commands, battles, and a repeatable tutor. Read this
guide with [TUTORIAL.md](TUTORIAL.md), which explains the same patterns in a
longer, example-led form.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Registers all content and owns the quest, battle, hut, and tutor flow. |
| `route19_blocks.lua` | Supplies the complete patched Route 19 block array. |
| `tutor.lua` | Holds lesson data and pure tutor helpers. |
| `tests/jj_fuchsia_swamp_test.lua` | Loads the mod and checks maps, scripts, battles, text, state, and tutor behavior. |

## `tutor.lua`

`Tutor.lessons` is data, not control flow. Each row names a move, menu label,
trainer ID, opponent species, and victory text. Add a lesson by adding a row,
then register its trainer in `main.lua` through the existing loop.

`levelFor(mon)` converts the selected Pokémon's level to the trial level. It
adds one and clamps the result between 30 and 55. `knows` scans the moves list
before a battle so the tutor never asks a Pokémon to relearn its move.
`lessonMenuBounds` is a UI rectangle sized for the longest current label.
`lossDestination` returns the hut for a failed hut trial and Fuchsia for a
failed swamp battle.

## `main.lua`, registration and battles

The entry function defines map IDs, Shrek's four movesets, and battle-end text.
It registers a custom overworld sprite and trainer portrait, then registers the
three crew trainers, the host, and one level-30 trial trainer per lesson. Crew
trainers reuse base portraits through `basePic`; custom art uses the mod asset
and a ROM palette source supported by the gated engine version.

`finishQuestBattle` owns losses. It heals the party, applies the normal blackout
money divisor, emits `world.blacked_out`, chooses the hut or Fuchsia
destination, and starts the warp. A win calls the ordinary `afterBattle` path.
This keeps the optional detour from stranding the player and never clears a
completed site.

`siteScript` builds the shared crew interaction: check a mod-private flag,
show the introductory text, run the custom battle command, set the flag only
after a win, and show the after text on later visits. The map's host script
checks all three site flags before starting its four-Pokémon battle. Winning
sets `shrek_defeated` and warps to the hut.

The Fuchsia City youngster script is a guidance-only replacement. The hut
script handles rest, first-visit tutor explanation, lesson command, and the
optional return to Fuchsia.

## Custom commands and runner control

The tutor command is `foreground` and `blocking` because it owns multiple
screens. It pushes the lesson menu and yields. A callback stores the choice and
resumes the runner. It then pushes a party picker, validates a healthy selected
Pokémon, rejects a known move, temporarily replaces `ctx.save.party` with one
member, and starts a normal trainer battle. The battle callback restores the
original party on every result before resuming.

After a win, the command appends the move when fewer than four slots exist. At
four slots it opens the engine's move-learn screen and reports whether the old
moves were kept. `activeTrial` supplies the chosen level and species to the
`trainer.party` hook without extending the engine's trainer schema.

The custom battle command follows the same callback pattern for crew and host
battles. It sets `ctx.lastCheck` so ordinary script rows can use
`jump_if_false`, then delegates loss handling to `finishQuestBattle`.

## Map and save data

The map is 10 blocks wide by 27 blocks high. Water fills the array, and helper
calls carve grass islands. `route19_blocks.lua` replaces the entire Route 19
block table and opens the hidden Surf cove. The new map connects west to Route
19, while the patch adds Route 19's east connection back to the swamp. Encounter
data registers level 30 through 34 grass slots.

On `map.entered`, the mod copies missing values from the legacy `jj_shrek`
save bucket into `jj_fuchsia_swamp`, then creates the current bucket and marks
`visited`. Quest flags use `mod:` script fields or the mod-data bucket, so the
mod does not collide with unrelated story flags.

## Test tour

The test loads the mod with the same SDK used by the other suites, checks the
manifest version gate, trainer records, sprite palettes, map dimensions,
reciprocal connections, reachable Surf seam, encounters, every crew script,
host gating, textbox pagination, loss destinations, tutor scaling, move
learning, temporary-party restoration, and save migration.

Run the focused suite and then the full suite from the game checkout:

```
luajit mods/jj_fuchsia_swamp/tests/jj_fuchsia_swamp_test.lua
luajit tests/run_modkit.lua
```

## Safe extension points

Add quest state under the mod namespace. Use `siteScript` for another identical
crew gate and a bespoke script for different dialogue. Always restore temporary
party data in `battle.onFinish`, including a loss. Keep block data in
`route19_blocks.lua`, and test both directions of every map connection. A new
engine capability belongs in `manifest.json` and the focused loader test.
