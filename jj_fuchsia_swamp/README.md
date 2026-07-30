# Fuchsia Swamp

An optional swamp quest reached from a hidden Surf cove on Route 19.

New modders: see [TUTORIAL.md](TUTORIAL.md) for a guided tour of the reusable
map, quest, battle, tutor, and test patterns used here.

## v1.0.0

Fuchsia Swamp is a complete optional quest. It registers a large custom swamp
of separated Surf clearings, connects it bidirectionally to Route 19, supplies
low-rate ambient encounters, and stores quest progress in
`save.modData.jj_fuchsia_swamp`. It requires gen1recomp v0.1.39 or newer.

Three original reclamation-crew battles must be cleared before the swamp host's
fixed four-Pokémon battle. Winning sends the player to the hut, where they can heal
their party, take the optional return to Fuchsia, or repeat an earned tutor
trial. Body Slam, Rock Slide, Sludge, and Rest are available to every species;
the selected Pokémon must win its matching solo battle before it learns the
move.
