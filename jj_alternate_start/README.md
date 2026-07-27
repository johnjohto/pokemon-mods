# Alternate Start

Begin a new game in any town or city instead of Pallet Town, with the
tutorial quests already done.

Oak's speech ends with two extra questions:

1. **Which starter?** Bulbasaur, Charmander, or Squirtle, at level 5.
2. **Where to?** Any of the eleven towns and cities.

Pick anywhere but Pallet Town and you start at that town's Pokémon Center,
starter in your party, Pokédex in hand, parcel quest done, and the
Viridian old man already off the road. Blackouts and escape ropes bring
you back to your town's Pokémon Center.

Pick **PALLET TOWN (CLASSIC)** and none of this happens: the game is
completely vanilla.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu. Only affects new games started while the mod is enabled.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_alternate_start/tests/jj_alternate_start_test.lua
```
