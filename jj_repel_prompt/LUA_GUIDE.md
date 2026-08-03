# Lua guide: Repel Reuse Prompt

This mod is a small example of coordinating two public events. It does not
replace the Repel system. It watches for the moment immediately before the
engine decrements the counter, then waits for the engine's expiration textbox
to close before offering another item.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Registers the two event listeners and builds the YES/NO textbox. |
| `tests/jj_repel_prompt_test.lua` | Runs the entry point with a fake game stack and checks expiry, item order, and no-op cases. |

## `main.lua`, from top to bottom

The entry function imports `TextBox`, `ItemEffects`, and `Bag`. These are the
real game services. `ItemEffects.use` applies an item's normal effect; using it
instead of changing `save.repelSteps` directly keeps item behavior in one place.

`REPELS` is ordered from weakest to strongest: `REPEL`, `SUPER_REPEL`, then
`MAX_REPEL`. `repelInBag(save)` walks that array and returns the first item whose
inventory count is truthy. It deliberately checks only `save.inventory`, so PC
storage is not part of this feature.

The `game.ready` listener stores the live game in an upvalue. The
`world.stepped` listener runs before the engine consumes the current step. When
`repelSteps` equals 1, it sets the private `pending` flag. That flag is not a
save field. It describes one in-progress step and must disappear if the next
screen is unrelated.

The `screen.popped` listener receives the state that was removed from the
stack. It ignores non-textbox states, which keeps `pending` armed while another
screen closes. It then checks that the counter really reached zero. If there is
no item to offer, it clears `pending` and returns, matching the unmodified game.

When an item exists, the code pushes a new `TextBox`. `defaultNo = true` makes
the safe answer the default. The `choice` callback returns immediately for NO.
For YES it removes exactly one item, calls the normal item effect, and pushes
the item's ordinary "used" message when the effect supplies one.

## Why the event order matters

Reading the counter only in `screen.popped` would be too late to know whether
the textbox came from a Repel expiration. Reading it only in `world.stepped`
would open the prompt before the engine's own message. The two-event handshake
avoids both mistakes.

## Test tour

The test creates a fake state stack and a save with a Repel counter. It emits a
step, sets the counter to zero as the engine would, and pops the expiration box.
It checks that YES spends Super Repel before Max Repel, that NO changes nothing,
and that an empty Bag opens no prompt. It also checks that a counter above one
and an unrelated popped state do not trigger the feature.

Run it from the game checkout:

```
luajit mods/jj_repel_prompt/tests/jj_repel_prompt_test.lua
```

## Safe extension points

Add another reusable item only by changing `REPELS` and confirming that the
engine's item data accepts it. If the engine changes when it decrements the
counter, revisit the event handshake and its test together. Do not call the
item's effect twice and do not push a prompt while a battle or menu owns the
state stack.
