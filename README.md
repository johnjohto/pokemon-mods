# pokemon-mods

Mods for the Pokémon Gen 1 recompilation. Each top-level `jj_*` folder is
one self-contained mod with its own manifest, readme, and headless tests.

These mods are developed outside the game repo on purpose: they are never
committed to it or its forks. During development each mod is linked into
the game's `mods/` folder with a directory junction:

```
mklink /J "mods\jj_<name>" "C:\Users\George\Projects\pokemon-mods\jj_<name>"
```

The game repo's local `.git/info/exclude` ignores `mods/jj_*/` so a linked
mod can never be swept into a commit there.

## Mods

- `jj_repel_prompt` — asks "Use another?" when a Repel wears off.

## Tests

From the game repo root:

```
luajit tests/run_modkit.lua
```

The modkit tier picks up every `mods/jj_*/tests` suite automatically.
