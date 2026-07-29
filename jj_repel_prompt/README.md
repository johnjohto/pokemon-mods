# Repel Reuse Prompt

When a Repel wears off in the field, the game asks "Use another?" instead
of making you open the bag yourself, like Pokémon Gold/Silver and later.

- YES uses the weakest Repel in your bag (Repel, then Super, then Max)
  and shows the usual "used" message.
- NO, or an empty bag, leaves everything as vanilla.

## Install

Download the `.zip` from the release and, **without unzipping it**, drag it
onto the game's start screen — or open the **MODS** tab there and press
*Import mod .zip*. It installs itself and comes up enabled.

Unzipping it next to `gen1recomp.exe` does not work: a released build is not
portable, so the game never reads that folder and the mod silently never
appears. See the [root README](../README.md#install) for the folder to use
if you would rather place it by hand.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_repel_prompt/tests/jj_repel_prompt_test.lua
```
