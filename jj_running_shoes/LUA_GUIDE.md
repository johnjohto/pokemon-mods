# Lua guide: Running Shoes

Running Shoes splits the movement decision from engine wiring. `runshoes.lua`
is pure logic that tests can call directly. `main.lua` connects that logic to
movement speed and the player's animation clock.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Defines options, wraps movement speed, tracks toggle state, and patches player animation timing. |
| `runshoes.lua` | Calculates eligible multipliers, trigger state, frame lengths, and animation ticks. |
| `tests/jj_running_shoes_test.lua` | Tests option schemas, pure decisions, real movement hooks, toggles, scripts, bicycle, and Surf. |

## `runshoes.lua`

`CYCLE` is the 16-tick walking animation cycle. `setting` resolves a numeric
multiplier or the special `match` value. `multiplier` checks Surf before bicycle
because water movement should use the Surf row even if the player arrived on a
bike.

`running` first rejects multipliers at or below one. ALWAYS returns true, TOGGLE
reads the caller's `toggled` latch, and HOLD asks the input object whether B is
down. `togglePressed` checks B's rising edge through `wasPressed`.

`frames` divides the base step length, floors it to whole frames, and never
returns less than one. `animTicks` distributes the unhurried step's animation
ticks over the shortened step with integer accumulation. This is why the legs
cycle faster without landing halfway through a pose.

## `main.lua`

The option schema defines foot speed, trigger mode, bicycle speed, and Surf
speed. `choice` treats stale saved values as vanilla. The `toggled` latch lives
only in memory; it is deliberately not saved across reloads.

The `movement.speed` wrapper calls `nextFn` first, allowing another speed mod to
settle the base frame count. It asks `Run.running`, stores the unhurried frame
length on the player for animation repair, and returns `Run.frames` when needed.

The module patches `Player.update` because the engine has a movement-speed hook
but no animation-clock hook. On each update it flips TOGGLE on B's rising edge,
captures running-step progress, calls the original update, pays the extra
animation ticks, and restores the unhurried step length when a tile lands.
Scripted movement does not call the speed hook, so restoring the base length
prevents a previous free-roam run from carrying into a cutscene.

## Test tour

The test checks all option rows, HOLD and TOGGLE decisions, stale input guards,
foot, bike, and Surf multipliers, integer frame lengths, animation ticks,
movement hook chaining, toggle taps while standing still, scripted steps, and
state cleanup after landing.

Run it from the game checkout:

```
luajit mods/jj_running_shoes/tests/jj_running_shoes_test.lua
```

## Safe extension points

Put a new movement policy in `runshoes.lua` first, then add one wiring change in
`main.lua`. Keep Surf precedence explicit. Preserve the call to `nextFn`, never
save the transient toggle latch, and test both a free-roam step and a scripted
step after changing animation timing.
