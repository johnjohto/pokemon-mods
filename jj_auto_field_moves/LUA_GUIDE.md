# Lua guide: Auto Field Moves

Auto Field Moves is a thin adapter around the engine's field-move actions. The
hard part is deciding when a blocked player step is a contact attempt while
letting the engine decide whether the move is legal.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Wraps blocked movement, skips contact-only text and Flash transitions, and lights dark maps. |
| `tests/jj_auto_field_moves_test.lua` | Drives collision and map-entry events with a fake overworld and checks every continuation. |

## `main.lua`, from top to bottom

The entry function imports `TextBox` and `Map`, then stores the live game on
`game.ready`. `ow()` is a small guard that returns the current overworld or
nil. `knows(moveId)` asks the overworld's `partyKnows`; this automatically sees
HM Field Unlock's widened rule when that sibling mod is installed.

`skipText` looks at the top state. If it is a textbox, it pops it and invokes
its continuation immediately. This removes the player-facing text without
discarding the engine work that follows the text. `skipFlash` does the same for
the transition shape used by Surf. It checks for `onDone`, `frames`, and `t` so
ordinary screens are not mistaken for a transition.

`activateStrength` asks the engine for the eligible Strength user, sets
`strengthActive`, plays that Pokémon's cry, and pushes the normal white flash.
Strength does not push the boulder here. The next ordinary collision uses the
engine's existing push behavior.

The `movement.collision` wrapper calls `nextFn` first. Only a collision that is
still blocked can become an automatic action. It also requires `ctx.mover` to
be the player, so NPC pathing cannot trigger a field move.

For a tile collision, a water target starts Surf if the player is not already
Surfing. The callback's `ctx.dir` updates facing before the engine's
`useSurfFieldMove`, which handles stale input-facing state. A successful gate
calls `trySurf` on the blocked target, then removes the text and transition.
The Cut path follows the same pattern and passes the blocked target to
`tryCut`; the engine still decides whether it is a tree, plant, or grass tile.

For an entity collision, the wrapper looks for a pushable NPC and activates
Strength only while it is not already active and a user exists. Everything else
remains an ordinary blocked step.

The `map.entered` listener checks for a dark overworld and a Flash user. It sets
`save.flashLit` before calling `setDark(false)`. The order matters because an
advanced map reload can emit `map.entered` recursively. The nested listener
sees the saved flag and does not start Flash again. The white flash is pushed
after the lighting state is changed.

## Test tour

The test checks Surf direction, remount prevention, Cycling Road refusal, NPC
exclusion, Cut gates, Strength activation, and textbox removal. It also builds a
fake Surf continuation with a white flash to prove the continuation still runs.
The final cases simulate a dark-map reload and prove that saving `flashLit`
first prevents recursive Flash activation.

Run it from the game checkout:

```
luajit mods/jj_auto_field_moves/tests/jj_auto_field_moves_test.lua
```

## Safe extension points

Add a contact action only after finding the engine's existing `use*` and `try*`
pair. Keep the action in the collision wrapper if it is a blocked player step.
Never bypass the engine gate, and never skip a continuation without running its
callback. If a map reload is involved, write the saved guard before triggering
the reload.
