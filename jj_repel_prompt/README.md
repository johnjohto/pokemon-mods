# Repel Reuse Prompt

When a Repel wears off in the field, the game asks "Use another?" instead
of making you open the bag yourself, like Pokémon Gold/Silver and later.

- YES uses the weakest Repel in your bag (Repel, then Super, then Max)
  and shows the usual "used" message.
- NO, or an empty bag, leaves everything as vanilla.

## Install

Copy this folder into the game's `mods/` directory and enable it in the
MODS menu.

## Develop

Run the headless tests from the game repo root:

```
luajit mods/jj_repel_prompt/tests/jj_repel_prompt_test.lua
```
