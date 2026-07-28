# Running Shoes

Hold **B** while you walk and the player runs: a tile takes half the
frames, and the legs cycle twice as fast to match, so the speed reads as
running rather than as the world scrolling faster.

- On foot by default. The bicycle and the water each keep their vanilla
  speed unless you ask for more (see **BIKE SPEED** and **SURF SPEED**).
- Nothing else changes pace. Wild encounters, poison damage, daycare EXP
  and the Repel counter all tick once per tile, so running covers ground
  faster without shifting a single rate.
- Ledge hops keep their vanilla arc, and scripted movement — the escort
  out of Pallet, Oak's lab, every cutscene — never runs.
- B stays free everywhere it already did: in the overworld vanilla only
  reads the d-pad, A and START, so nothing is shadowed.

## Options

Three rows in the options menu.

**RUN SPEED** picks the pace on foot: **2X** (default), **1.5X**, or
**OFF**. Note that 2X is exactly bicycle speed — both are 8 frames a tile
— so at the default the shoes catch the bike. **1.5X** leaves the bike
ahead.

**RUN BUTTON** picks how it triggers: **HOLD B** (default), **TOGGLE**, or
**ALWAYS**. **TOGGLE** latches — tap B once to start running and again to
stop, no holding — and it applies to the bicycle and the water too,
wherever those rows ask for more than vanilla. The latch is deliberately
not saved: a run state that survived a reload would have you moving at
double speed with no memory of asking for it.

Tapping B in a menu or a battle cannot flip the latch. The engine only
updates the state on top of the stack, so the overworld — where the latch
lives — is not running while a menu is open, and the B that backs out of
one never reaches it.

**BIKE SPEED** hurries the bicycle the same way: **VANILLA** (default,
untouched), **MATCH RUN**, **1.5X**, or **2X**. **MATCH RUN** hands the
bike whatever multiplier the feet have, so it keeps its exact 2:1 lead
over a runner instead of being caught by one. The bike answers to the
same trigger as the feet — on **HOLD B** it stays vanilla until you hold
B, and the 2:1 lead holds whether you are holding it or not; on
**ALWAYS** the faster bike is permanent.

**SURF SPEED** does the same for crossing water, with the same four
settings and the same default of **VANILLA**. It is a row of its own
because wanting to cross the sea faster and wanting to sprint on land are
different wishes. Surfing is read before the bicycle, so a step on the
water always takes this row's setting whatever you were riding when you
stepped in.

However it is set, a step's animation is paid its unhurried length in
ticks, so the leg cadence rises by exactly as much as the speed does: a
run is one full cycle per tile like a walk, and a hurried bike keeps the
half cycle per tile the engine gave it, pedalled faster.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_running_shoes/tests/jj_running_shoes_test.lua
```
