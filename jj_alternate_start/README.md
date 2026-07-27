# Alternate Start

Begin a new game in any of nine towns instead of Pallet Town, with the
tutorial quests already done — and, if you want, with the story intact.

Oak's speech ends with one question: **where to?** What happens next
depends on the STORY BEATS option (on by default):

- **Story beats on:** Oak and Blue come to see you off at your new
  town's Pokémon Center. Pick your starter from Oak's balls, fight Blue
  and his counter-pick right there, and get the Pokédex from Oak
  himself. Blue keeps showing up all game: his ambushes are re-gated on
  gym badges (Route 22 after 1, Cerulean after 2, S.S. Anne after 3,
  Pokémon Tower after 4, Silph Co. after 6), so they happen in order
  even without the Pallet tutorial.
- **Story beats off:** the quick start. Pick a starter in the speech
  and simply appear in your new town, everything already in hand.

Either way: Pokédex and parcel quest count as done, the Viridian old
man is off the road, blackouts and escape ropes return to your town's
Pokémon Center, and every offered town has a guaranteed way out
(Fuchsia and Cinnabar would softlock a fresh save, so they're not
offered; a Saffron start opens the thirsty guards' gates).

Pick **PALLET (CLASSIC)** and none of this happens: the game is
completely vanilla.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu. Only affects new games started while the mod is enabled.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_alternate_start/tests/jj_alternate_start_test.lua
```
