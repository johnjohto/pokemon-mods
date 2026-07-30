# Building a self-contained side quest mod

Fuchsia Swamp is deliberately small enough to read end-to-end, but complete
enough to demonstrate a real content mod: a connected custom map, quest
progress, trainer battles, a rest point, and a repeatable reward loop. This
guide explains those patterns so you can adapt them for a different optional
area.

## Start with the smallest vertical slice

The entry point, `main.lua`, returns a function that receives `mod`. Keep the
first version narrow: register one map, make it load, and test its connection
before adding story content. This mod's first useful slice was:

1. Register `JJ_SHREK_SWAMP` with an existing tileset.
2. Patch Route 19 with a reciprocal east/west map connection.
3. Register encounters and a map-entered event.
4. Assert that a player can Surf from a reachable Route 19 shore to the map
   seam.

That order matters. A battle script cannot rescue a map that is unreachable,
and a state machine is much easier to debug once the player can enter and
leave the area normally.

## Understand map coordinates before authoring a layout

Map definitions use **blocks**, while objects, warps, and movement use
**cells**. One block is a 4x4-tile metatile and occupies 2x2 movement cells.

```lua
width = 10, height = 27, -- blocks
objects = {
  { x = 8, y = 49, ... }, -- cells
}
```

The `grassIsland(left, top, right, bottom)` helper in `main.lua` writes block
IDs into a rectangular `blocks` array. The index formula is:

```lua
blocks[y * SWAMP_WIDTH + x + 1] = GRASS
```

Lua arrays start at one, so the `+ 1` is required. Keep helpers like this near
the map definition; they make a hand-authored layout readable and avoid large,
error-prone numeric tables.

Use a native tileset when possible. This mod uses `OVERWORLD`, block `67` for
water, and block `11` for encounter grass. Reusing it preserves collision,
water animation, and palette behavior without creating art or engine work.

## Connect a custom map in both directions

A custom area needs both halves of its connection:

```lua
-- On the new map
connections = { west = { map = "ROUTE_19", offset = 0 } }

-- Patched onto the existing map
mod.content.maps:patch("ROUTE_19", {
  blocks = require("mods.jj_fuchsia_swamp.route19_blocks"),
  connections = { east = { map = MAP, offset = 0 } },
})
```

The Route 19 block patch creates a cove whose water is reachable from land.
Do not treat a visual connection as enough: test the player path to a
surfable edge and the return path from the new map. `waterEdgeReachable` in
`tests/jj_fuchsia_swamp_test.lua` is a useful breadth-first-search example.

## Keep quest state private and recoverable

Script flags with a `mod:` prefix live in the current mod's save namespace:

```lua
{ "check_flag", "mod:site_dredger" }
{ "set_field", "mod:site_dredger", true }
```

Use a small, explicit set of flags for each gate. Fuchsia Swamp records the
three crew sites, the final battle, whether the area was visited, and whether
the tutor rules have been explained. This prevents optional content from
changing unrelated story flags.

When renaming a mod ID, migrate the old `save.modData` bucket on map entry.
`migrateLegacySave()` copies only missing keys, so new progress wins and an
older local build can still read its old bucket. Treat migrations as data
preservation, not as a place to rewrite quest logic.

## Wrap battles when default defeat handling is not right

The map scripts call the `jj_fuchsia_swamp:battle` command instead of the
engine's bare battle verb. That command builds a trainer battle, sets
`battle.endBattleText`, and owns `battle.onFinish`.

This is the right seam when a quest needs special loss handling. Here,
`finishQuestBattle` heals the party, applies the normal blackout money loss,
and warps a defeated player to Fuchsia. Tutor trials instead use
`Tutor.lossDestination` to return the player to the hut. The map scripts can
still use normal `jump_if_false` logic because the command sets `ctx.lastCheck`
to whether the player won.

For an NPC that unlocks after several fights, keep the script declarative:

```lua
{ "check_flag", "mod:site_dredger" },
{ "jump_if_false", "waiting" },
-- check the other sites
{ "jj_fuchsia_swamp:battle", "OPP_JJ_SHREK", 1 },
{ "set_field", "mod:shrek_defeated", true },
```

The `siteScript` helper removes repetition from the three crew encounters.
Use a helper when scripts share structure; keep bespoke dialogue in the call
site so it remains easy to edit.

## Build a foreground command for multi-screen interactions

The tutor sequence is more than a map-script menu: it selects a lesson,
selects a party member, runs a one-Pokémon battle, and teaches a move. It is
therefore registered as a `foreground` and `blocking` command.

Its control-flow pattern is:

1. Push a menu and `runner:yield()`.
2. Have each callback save the choice and `runner:resume()`.
3. Validate the choice before changing save data.
4. Run the battle and resume the same runner from `battle.onFinish`.
5. Restore temporary state before applying the reward.

For a no-switch trial, the command temporarily sets `ctx.save.party` to the
chosen Pokémon, then restores the original table in `onFinish`. This keeps
the normal battle UI and avoids creating a second battle system. Always
restore temporary save state on **every** battle result before resuming.

`tutor.lua` keeps the lesson data separate from UI code. Each lesson defines
its move, label, trainer record, opponent species, and victory line. Add a
lesson by extending that table rather than branching the command.

## Reuse base art safely

Crew trainers use `basePic` to point at native trainer portraits instead of
shipping duplicate base-game assets. The swamp host uses mod-owned portrait
and overworld files, with the same `paletteSource` for its walking sprite,
main trainer record, and trial trainer records.

Custom trainer portrait palettes and `basePic` require the engine support
introduced by upstream PR #434. If your mod depends on a new engine feature,
say so in its release gate and do not publish a player-facing release until a
compatible game build exists.

## Make visual and gameplay regressions testable

Run the focused test while iterating:

```powershell
luajit mods/jj_fuchsia_swamp/tests/jj_fuchsia_swamp_test.lua
```

Then run the whole mod suite before release:

```powershell
luajit tests/run_modkit.lua
```

The Fuchsia Swamp test shows several useful techniques:

- Load a mod through `T.sdk.loadMod` and assert it has no loader errors.
- Use `MapLoader.load` to test real water, grass, walkability, and map
  connections.
- Replay talk scripts with a mocked battle command to verify every victory
  writes the intended flag and unlocks the final encounter.
- Check textbox pagination for every battle-end and tutor line.
- Check trainer records, palettes, party hooks, and lesson scaling directly.

Prefer a test that captures the player-visible rule over a test that only
checks that Lua executed. For example, the Auto Field Moves regression test
sets a stale facing direction and confirms a rightward water bump still
starts Surf.

## Package only after the engine gate is clear

The repository helper packages one mod and uploads its ZIP:

```bash
tools/release.sh jj_fuchsia_swamp
```

On Windows without WSL, package with the game repository's modkit and upload
the verified ZIP with `gh release create` instead. Include `README.md` for
release notes and `DISCORD.md` for the announcement copy. Confirm that public
documentation contains only the names and terms you intend to ship.

## A practical checklist for your own quest

- [ ] The entrance and return path work without developer warps.
- [ ] Every map connection has a tested, reachable water or land seam.
- [ ] Quest flags are mod-private and saved.
- [ ] Loss handling cannot strand the player or erase prior progress.
- [ ] Multi-screen commands restore temporary party or state changes.
- [ ] Dialogue fits the game's text box, including battle-end text.
- [ ] Custom art uses a supported palette path.
- [ ] Focused and full mod tests pass.
- [ ] The release archive, README, and Discord post describe the same build.
