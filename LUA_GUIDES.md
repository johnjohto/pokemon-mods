# Lua development guides

These guides explain the Lua in each mod for someone who has not written a
game mod before. Read this file first, then open the guide for the mod you want
to change.

## What you are setting up

The mods in this repository are loaded by the Pokémon Gen 1 recompilation. A
mod is not a standalone Lua program. The game supplies the `mod` object, game
data, save data, event bus, hook registry, UI stack, and Lua modules under
`src/`. A mod's `manifest.json` names its entry file, normally `main.lua`.

You need a local checkout of the game repository, LuaJIT, and the game data
that the game generated from a legally obtained ROM. The mod repository alone
cannot run these files because modules such as `src.mods.Runtime` and
`tests.modkit` live in the game checkout.

From the game repository root, create a directory junction for the mod you are
working on. On Windows:

```
mklink /J "mods\jj_<name>" "C:\Users\George\Projects\pokemon-mods\jj_<name>"
```

The link makes the game load your working files without copying them. Keep the
game checkout's `.git/info/exclude` entry for `mods/jj_*/`, then run the
focused command in the mod's guide. Run the complete suite before a release:

```
luajit tests/run_modkit.lua
```

## Lua concepts used in every guide

`local` creates a value visible only in the current file or function. A table
such as `{ move = "SURF" }` is Lua's main data structure. A function can be
stored in a table, passed to another function, and called later by an event or
hook. `return function(mod) ... end` is the standard entry shape here: the
loader calls the returned function once and gives it the mod API.

The game uses two extension mechanisms. An event listener runs after something
happens, such as `game.ready` or `map.entered`. A hook wrapper intercepts an
existing function. Its `nextFn` argument calls the previous implementation; a
wrapper should usually call it before adding its own behavior so sibling mods
continue to work. A script is a list of rows interpreted by the game's script
runner, while a command is Lua code that can pause a runner and resume it after
menus or battles.

Each test is a normal Lua process. It loads the same entry point through the
modkit SDK, supplies the fixture data and stubs it needs, then asserts a
player-visible rule. Tests do not replace in-game playtesting. When a change
affects timing, rendering, or a battle scene, use the corresponding human
driver in the game repository as well.

## A safe change loop

1. Read the mod's manifest and guide before editing code.
2. Identify whether the behavior belongs in an event listener, hook wrapper,
   pure helper, map script, or test fixture.
3. Make one small change and keep the existing engine path whenever possible.
4. Run the focused test from the game repository root.
5. Run the full modkit suite.
6. Launch the game and exercise the player-facing path.
7. Update the mod README, changelog, Discord copy, and Lua guide when the
   behavior or development contract changed.

Avoid editing generated game data in this repository. Keep mod-private save
fields under the mod's namespace, restore temporary state in every callback,
and never assume a newer engine API exists without a manifest version gate or
feature check.
