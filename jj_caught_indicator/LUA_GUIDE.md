# Lua guide: Caught Indicator

Caught Indicator separates the decision to show a mark from the rendering of
that mark. That separation lets tests check battle rules without creating Love2D
images.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Defines options, records successful capture balls, and draws the icon in the battle overlay. |
| `indicator.lua` | Pure rules, geometry, pixel art, shake offsets, flash timing, and ball colors. |
| `tests/jj_caught_indicator_test.lua` | Tests the pure module and the runtime event and overlay behavior. |

## `indicator.lua`

`shouldShow(battle, game)` is the complete visibility rule. It requires a wild
battle, a non-ghost and non-demo encounter, an enemy Pokémon that is sent out
and not fainted, no trainer-intro or grow-in animation, and a true Pokédex
owned bit. Keep transient HUD gates here rather than in the renderer; otherwise
the icon can appear before the enemy status box.

`placement(wide)` returns classic `(8, 8)` or widescreen `(113, 16)` pixels.
`isWide` checks that the engine actually provides `wideLayout`, so older game
versions do not crash. `shakeOffset` follows classic HUD shake when enabled,
adds the HUD shake component, and always returns zero for widescreen. The
fallback reproduces the engine's alternating two-pixel shake when only a
countdown exists.

`flashAlpha` describes the same every-other-frame white wash used by the battle
renderer. The overlay hook runs after that wash, so `main.lua` paints the wash
over the icon's 8 by 8 cell to put the icon visually underneath it.

`ICONS` holds two eight-row pixel tables. `pixels` falls back to the default Gen
2 shape for stale saved options. `BALL_COLORS` maps only known successful Gen 1
ball IDs. Unknown balls return nil and therefore use HUD ink.

## `main.lua`

The entry function defines `CAUGHT ICON`, `LAST BALL`, and `ICON SHAKE`. The
`pokemon.caught` listener receives the event after a successful catch and saves
the ball by species in the mod's private save namespace. It ignores malformed
events and misses. Existing ownership cannot reveal a historical ball, so no
guess is made for starters, gifts, trades, or old saves.

`iconImage` builds an 8 by 8 Love image lazily for each silhouette and caches it.
Source pixels are white so `setColor` can tint them either black or with a ball
color. The `battle.overlay` wrapper calls the base renderer first, then exits
when the icon should be hidden or another state covers the battle. It chooses
layout, shake, placement, silhouette, color, and flash wash in that order.

## Test tour

Tests cover every visibility exclusion, both layouts, old engines without
`wideLayout`, icon fallback, shake behavior, flash timing, ball colors, capture
event persistence, option defaults, and overlay drawing. The test uses a Love2D
stub so it can assert draw calls without opening a window.

Run it from the game checkout:

```
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```

## Safe extension points

Keep all new geometry and visibility rules in `indicator.lua`. Add a new ball
color only when the event and game data provide a stable ID. Do not draw over a
modal battle state, and do not assume the widescreen API exists. Any new saved
capture data needs a migration story before changing its shape.
