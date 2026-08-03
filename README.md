# pokemon-mods

Player-made mods for the Pokémon Gen 1 recompilation. Each `jj_*` directory is
a separate mod. You can install only the mods you want; they do not require one
another unless a guide explicitly says otherwise.

This repository contains mod packages, not the game or a Pokémon ROM. Set up
and run the base game first, using a game build and a ROM that the game itself
accepts. Then return here for the optional changes described below.

## Before you install a mod

You need all of the following:

- A working installation of the Pokémon Gen 1 recompilation. Launch it once
  before importing a mod so it can create its save directory.
- A save you are comfortable using with the selected mod. Back up an important
  save before changing its mod list. This repository does not provide a way to
  undo changes that a content or new-game mod has already written to a save.
- The release `.zip` for the mod you want, downloaded from the
  [releases page](https://github.com/johnjohto/pokemon-mods/releases). Check
  the mod name and version in the release title before downloading.

Fuchsia Swamp has one additional requirement: it needs gen1recomp v0.1.39 or
newer. Its manifest will reject unsupported release versions.

## Install a released mod

1. Close the game if it is already running.
2. Download the mod's release asset. Keep the `.zip` file intact.
3. Start the game and open the **MODS** tab on the start screen.
4. Choose **Import mod .zip**, select the downloaded file, and wait for the
   import to finish. You can also drag the `.zip` onto the start screen.
5. Confirm that the mod appears in the MODS list and is enabled.
6. Start or load a save, then follow that mod's guide below.

Do not unzip a release beside `gen1recomp.exe`. Released game builds do not
read mods from that location, so the mod will not appear in the MODS list.

## Manual installation

Use manual installation only when the in-game importer is unavailable. First
close the game, then unpack the release so that the mod's `manifest.json` is
directly inside its own folder under the game save directory:

| Platform | Mods folder |
| --- | --- |
| Windows | `%APPDATA%\pokemon-love2d\mods\` |
| macOS | `~/Library/Application Support/pokemon-love2d/mods/` |
| Linux | `~/.local/share/pokemon-love2d/mods/` |

For example, the Running Shoes manifest must end up at
`.../mods/jj_running_shoes/manifest.json`, not at
`.../mods/jj_running_shoes/jj_running_shoes/manifest.json`. Start the game and
use the MODS list to confirm the result.

## Update, disable, and troubleshoot

To update a mod, import the newer release asset and check the MODS list again.
Keep a save backup before updating a mod that changes a new game, records
extra information, or adds quest progress.

If a mod is missing from the MODS list, confirm that you imported its `.zip`
through the game or placed `manifest.json` at the exact manual-install path.
If the game reports a version incompatibility, install a compatible base-game
version rather than forcing the mod into place. If the mod is listed but its
effect is absent, check that it is enabled and read that mod's **When it takes
effect** section. Several mods only act in battle, when a Repel expires, or on
a newly started game.

## Mods and guides

| Mod | What it changes | Guide |
| --- | --- | --- |
| Alternate Start | Starts a new game outside Pallet Town. | [README](jj_alternate_start/README.md) |
| Auto Field Moves | Uses Surf, Cut, Strength, and Flash on contact. | [README](jj_auto_field_moves/README.md) |
| Caught Indicator | Shows an owned-species marker in wild battles. | [README](jj_caught_indicator/README.md) |
| EXP Bar | Draws an experience bar in battle. | [README](jj_exp_bar/README.md) |
| Fuchsia Swamp | Adds an optional Route 19 Surf quest. | [README](jj_fuchsia_swamp/README.md) |
| HM Field Unlock | Allows eligible party Pokémon to use field HMs without learning them. | [README](jj_hm_field_unlock/README.md) |
| Repel Reuse Prompt | Offers to use another Repel when one expires. | [README](jj_repel_prompt/README.md) |
| Running Shoes | Adds configurable faster overworld movement. | [README](jj_running_shoes/README.md) |

## Developing a mod

This section is for contributors, not players installing a release. You need a
local game source checkout with its own prerequisites installed, including the
`luajit` command used by the test suite. The game data must also be prepared
through the base game's documented ROM-import workflow before you can run the
game from source.

Link a mod into the game checkout's `mods/` directory. On Windows, from the
game repository root, a directory junction looks like this:

```
mklink /J "mods\jj_<name>" "C:\Users\George\Projects\pokemon-mods\jj_<name>"
```

The game checkout's local `.git/info/exclude` should ignore `mods/jj_*/` so a
linked local mod is not accidentally committed there. Run all modkit tests from
the game repository root:

```
luajit tests/run_modkit.lua
```

Each mod README includes its focused test command. Package a release with
`tools/release.sh <mod-id>` after verifying the package and documentation.
