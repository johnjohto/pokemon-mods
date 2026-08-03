# Lua guide: EXP Bar

EXP Bar uses a pure state machine for experience progress and a thin renderer
that connects it to battle events. This is useful when a visual animation needs
to be tested without depending on Love2D pixels.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Defines options, listens for active-battler EXP events, and draws the bar. |
| `expbar.lua` | Computes level progress, animates gains and level-up wraps, and returns layout geometry. |
| `tests/jj_exp_bar_test.lua` | Tests progress, state transitions, geometry, visibility, and runtime wiring. |

## `expbar.lua`

`progress(data, mon)` converts total experience into a fraction of the current
level. It reads the species growth rate, asks `Growth.expForLevel` for the
current and next level floors, clamps the result to 0 through 1, and returns a
full bar at the level cap. It does not mutate the Pokémon.

`visibleFor` mirrors the battle HUD conditions: it needs a player battler and
rejects Safari, demo, player-back, and intro-slide states. The bar is HUD
decoration, so it should disappear whenever the HUD disappears.

`ExpBar.new` creates four fields. `mon` identifies the tracked battler,
`displayed` is what the renderer draws, `target` is the current animation goal,
and `pending` stores the post-level-up fraction. `onExpGained` receives a
Pokémon after the engine has already applied experience. It reconstructs the
pre-gain level and experience by subtracting the event amount and number of
levels. A normal gain animates directly to its new fraction. A level-up first
animates to full, then `tick` resets to zero and continues toward `pending`.

`sync` snaps to a different active Pokémon and clears any pending animation.
`tick` advances by the fixed `RATE` once per drawn frame. A switch or battle
start therefore never animates old progress into a new Pokémon.

`CLASSIC` and `WIDE` are pixel geometry tables. `geometry` applies the one-pixel
position option as an offset in either layout. `voxelGeometry` returns a
transformed classic bar only when Dramatic Shape Voxel Mod exposes valid
`pw`, `ly`, and `scale` values. `isWide` feature-checks the optional engine API.

## `main.lua`

The entry function defines fill style and vertical position options, stores the
game on `game.ready`, and creates one `ExpBar` instance. `battle.exp_gained`
starts animation only when the event's Pokémon is the active player Pokémon;
EXP.ALL recipients do not move the bar. The overlay wrapper calls the base draw
first, syncs and ticks the state, hides during Mimic selection, then chooses
classic, widescreen, or voxel geometry and draws a right-anchored fill.

Classic shake offsets come from the battle effect state. The move-selection box
clips the fill so it does not paint across the panel. The previous canvas is
restored after voxel drawing, which prevents later UI from being redirected.

## Test tour

Tests cover growth-rate fractions, level 100, normal gains, level-up wraps,
switch snaps, hidden HUD states, classic and widescreen geometry, the voxel
transform, option defaults, and overlay calls.

Run it from the game checkout:

```
luajit mods/jj_exp_bar/tests/jj_exp_bar_test.lua
```

## Safe extension points

Keep progress math independent of drawing. Start animation only from the
active-battler event, and use `sync` for every other state change. When adding a
layout, add guarded geometry and a test for an engine without that layout.
Always restore the prior Love canvas after custom-canvas drawing.
