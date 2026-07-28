# pokemon-mods

Mods for the Pokémon Gen 1 recompilation. Each top-level `jj_*` folder is
one self-contained mod with its own manifest, readme, and headless tests.

## Download

Grab the zip for a mod from its
[GitHub release](https://github.com/johnjohto/pokemon-mods/releases),
unzip it into the game's `mods/` folder, and enable it in the MODS menu.

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
