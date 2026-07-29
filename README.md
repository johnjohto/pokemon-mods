# pokemon-mods

Mods for the Pokémon Gen 1 recompilation. Each top-level `jj_*` folder is
one self-contained mod with its own manifest, readme, and headless tests.

## Install

Grab the zip for a mod from its
[GitHub release](https://github.com/johnjohto/pokemon-mods/releases) and
**leave it zipped**. On the game's start screen open the **MODS** tab and
either press *Import mod .zip* or drag the file onto the window. The mod
lands in the right place on its own and comes up enabled.

Do not unzip it into the folder holding `gen1recomp.exe`. A released build
is not portable, so the game never puts that folder on its read path and a
mod sitting there is ignored without a word — the symptom is a mod that
simply never shows up in the MODS menu. This bites hardest when the game
was installed by a launcher, where that folder is somewhere you never look.

Mods live in the save directory instead. On Windows that is:

```
%APPDATA%\pokemon-love2d\mods\
```

with one folder per mod, `manifest.json` directly inside it. macOS and
Linux use `pokemon-love2d` under `~/Library/Application Support` and
`~/.local/share` respectively. If a path doesn't exist yet, launch the game
once — or just use *Import mod .zip* and never think about it.

## Develop

Mods are developed outside the game repo on purpose: they are never
committed to it or its forks. During development each mod is linked into
the game's `mods/` folder with a directory junction:

```
mklink /J "mods\jj_<name>" "C:\Users\George\Projects\pokemon-mods\jj_<name>"
```

The game repo's local `.git/info/exclude` ignores `mods/jj_*/` so a linked
mod can never be swept into a commit there.

Run the headless tests from the game repo root:

```
luajit tests/run_modkit.lua
```

The modkit tier picks up every `mods/jj_*/tests` suite automatically.
Cut a release with `tools/release.sh <mod-id>` (packs the mod and uploads
the zip as the release asset).

## Mods

- `jj_repel_prompt` — asks "Use another?" when a Repel wears off.
- `jj_alternate_start` — begin a new game in any town, tutorial-free.
- `jj_hm_field_unlock` — field-use HMs without teaching them.
- `jj_auto_field_moves` — field moves fire on contact, no menus.
- `jj_exp_bar` — Gen 2-style EXP bar under the player HP bar in battle.
- `jj_caught_indicator` — pokeball icon next to a wild pokémon you've already caught.
- `jj_running_shoes` — hold B to run at double speed on foot.
