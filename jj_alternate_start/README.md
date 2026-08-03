# Alternate Start

Alternate Start changes the end of Oak's opening speech for new games. You can
begin in one of eight towns or at Indigo Plateau instead of Pallet Town, or
choose **PALLET (CLASSIC)** to leave the opening completely vanilla.

Version: 2.0.1.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_alternate_start` release `.zip` through the **MODS** tab and
confirm that it is enabled before creating the save. The mod only changes a
new game started while it is enabled. It does not move an existing save to a
new town.

Choose this mod before investing in a new run. An alternate start marks several
opening events complete and changes the save's return point, so make a backup
first if you may want to preserve an untouched opening save.

## Start a game

1. Start a new game and complete Oak's normal opening speech.
2. Open the **STORY BEATS** option from the game's mod options if you want to
   change it. It is on by default.
3. Choose a hometown from the list. Pressing B at this list chooses
   **PALLET (CLASSIC)**.
4. Finish the opening. If you chose an alternate town, the game warps you to
   that town's Pokémon Center area.

The available alternate starts are Viridian City, Pewter City, Cerulean City,
Lavender Town, Vermilion City, Celadon City, Saffron City, and Indigo Plateau.
Fuchsia City and Cinnabar Island are not offered because a fresh save could not
leave them without access that it does not yet have.

## Choose the story style

**STORY BEATS** controls how you receive the starter and whether Blue's early
story scenes are preserved.

With **STORY BEATS** on, Oak and Blue meet you at the new town's Pokémon
Center. Choose Bulbasaur, Charmander, or Squirtle from Oak's Poké Balls, then
fight Blue and receive the Pokédex. Blue's later encounters are held until you
have enough badges: Route 22 after one, Cerulean after two, S.S. Anne after
three, Pokémon Tower after four, and Silph Co. after six.

With **STORY BEATS** off, choose Bulbasaur, Charmander, or Squirtle during
Oak's speech. You arrive at the selected town with the starter and opening
progress already applied. This skips the Oak and Blue visit scene.

In either alternate-start mode, the starter is level 5, has no nickname prompt,
and the game records the Pokédex and parcel sequence as complete. The Viridian
old man is moved out of the north path. Blackouts and Escape Ropes return you
to the chosen town's Pokémon Center. A Saffron start also opens the thirsty
guard gates so you can leave the city.

## Classic start and save behavior

Selecting **PALLET (CLASSIC)** changes nothing. It does not grant a starter,
set alternate-start flags, or add the new story scenes. Existing saves that did
not begin with this mod are also left alone by the Blue encounter changes.

If you black out during the Oak and Blue visit scene after choosing a starter,
the mod cleans up the scene rather than starting it again. Continue the save
normally after returning to the town.

## Troubleshooting

If you do not see the hometown question, verify that the mod was enabled before
starting the new game. Loading an old save does not replay Oak's speech. If you
chose Pallet Town, that is the explicit vanilla option. If a start town seems
unavailable, it is not a hidden choice; the mod excludes starts that could
strand a fresh save.

## For contributors

Read [LUA_GUIDE.md](LUA_GUIDE.md) before editing. It explains the speech hook,
save preparation, rival gates, scene stages, and safe extension points.

From the game repository root:

```
luajit mods/jj_alternate_start/tests/jj_alternate_start_test.lua
```

See [the open-world blocker audit](docs/gen1-openworld-blocker-audit.md) for
the design notes behind the safe start locations. Run `luajit tests/run_modkit.lua`
before release.
