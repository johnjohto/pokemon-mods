# Adding text to NPCs

This guide changes an NPC's dialogue in Fuchsia Swamp without introducing a
new map, sprite, or battle. Start with an NPC that already exists in the base
game: Fuchsia Swamp uses a Fuchsia City youngster to hint at the Route 19
cove.

## Prepare the local game data first

`data/generated/maps.lua` is created from a player's ROM; it is not checked
into the game repository and does not belong in a mod. If that file is absent,
prepare a local cache before looking for IDs.

### Option A: import through the app

This is the most direct route when you run the game from its source checkout.

1. In the game repository root, create an empty file named `portable.txt`.
   It belongs beside `main.lua` and `conf.lua`.
2. Start the game and, on its first screen, choose or drop your legally
   obtained ROM file.
3. Wait for the import to finish. The app verifies the ROM, creates
   `data/generated/` and `assets/generated/` beside `portable.txt`, then
   starts the game.

The desktop importer accepts canonical 1 MiB US Pokémon Red and Blue ROMs.
It uses the ROM only to build the local cache; it does not copy the ROM into
the project.

### Option B: build the cache from the source tree

If you are using the developer tools instead of the app, open a terminal in
the game repository and run:

```text
python tools/build_data.py --rom <path-to-your-pokemon-red-rom>
```

Replace the placeholder with the location of your legally obtained ROM. When
the command completes, open `data/generated/maps.lua` in the same repository.

Do not commit or package `data/generated/`, `assets/generated/`, or a ROM.
Fuchsia Swamp references engine IDs and ships only its own Lua files and art.

## Find the IDs before writing Lua

An **ID** is the internal name the game uses to connect things. You need two
IDs to change an existing NPC's text:

1. The **map ID** says which map contains the NPC.
2. The NPC's **text ID** says which talk script runs when the player speaks
   to it.

Do not invent either ID for a base-game NPC. Once the previous setup has
created it, open the generated map data in the game repository,
`pokemon-gen1-recomp-project`, and copy the object's `text` value exactly.

### 1. Find the map ID

Open `data/generated/maps.lua` in your editor. Use Find or Search and type
the town or map name, such as `FUCHSIA_CITY`. This file is the readable source
of truth for every loaded map.

The result you want is the table beginning with `FUCHSIA_CITY = {`. That key
is the map ID to use in `map_scripts:register`. If you only know the display
name, search for a distinctive part of it, then inspect the nearby table.

Near the start of the result, the same table also contains:

```lua
id = "FUCHSIA_CITY",
label = "FuchsiaCity",
objects = {
```

`id` confirms the map ID. `label` is the source-map label and is useful for
recognition, but `FUCHSIA_CITY` is the value used in Lua scripts. `objects`
starts the list of NPCs, signs, and other interactable map objects.

### 2. Find the NPC's text ID

Inside that map's `objects` list, find the object with the NPC you mean. The
first Fuchsia City youngster is:

```lua
{
  index = 1,
  name = "FUCHSIACITY_YOUNGSTER1",
  sprite = "SPRITE_YOUNGSTER",
  text = "TEXT_FUCHSIACITY_YOUNGSTER1",
  x = 10,
  y = 12,
},
```

`name` identifies the object for developers. `sprite` tells you what it looks
like. `x` and `y` tell you where it stands. The important line for dialogue is
`text = "TEXT_FUCHSIACITY_YOUNGSTER1"`: copy that quoted text ID into the
`talk` table. It is the link the game follows after the player presses A on
this NPC.

If the map has many objects, leave `maps.lua` open and use Find again for the
object's `name`, such as `FUCHSIACITY_YOUNGSTER1`. The object table is small:
read its `sprite`, `text`, `x`, and `y` fields together to make sure it is the
NPC you meant to change.

For a **new custom NPC**, you choose both IDs. Use the map ID you registered
(Fuchsia Swamp stores its as `local MAP = "JJ_SHREK_SWAMP"`) and give the
dialogue a unique, mod-prefixed text ID such as `TEXT_JJ_SHREK_DREDGER`.
That same ID must appear in the object’s `text = ...` field and in the map
script’s `talk` table.

## The smallest useful change

Put this inside the function returned by `main.lua`, alongside the other
`mod.content.map_scripts:register` calls:

```lua
mod.content.map_scripts:register("FUCHSIA_CITY", {
  talk = {
    TEXT_FUCHSIACITY_YOUNGSTER1 = {
      { "show_text", "Someone on ROUTE 19\nfound a quiet cove." },
      { "show_text", "It is east of the\nopen water, they said." },
    },
  },
})
```

It changes the dialogue attached to the base game's first Fuchsia City
youngster. It does not add an NPC: the map, youngster sprite, position, and
interaction range already belong to the base game.

| Lua | Meaning |
| --- | --- |
| `mod` | The mod API object passed into Fuchsia Swamp's `main.lua` function. It is how the mod contributes content to the game. |
| `.content` | The group of registries for game content such as maps, trainers, sprites, and scripts. |
| `.map_scripts` | The registry for map events. NPC dialogue is a `talk` event. |
| `:register(...)` | Adds this mod's script contribution. The colon means Lua passes `map_scripts` as the method's first hidden argument; use a colon here, not a dot. |
| `"FUCHSIA_CITY"` | The map ID. It is the engine's identifier for Fuchsia City, not the text shown to players. The script only applies while this map is active. |
| `{ ... }` | A Lua table: a collection of named fields. Here it holds every script contribution for Fuchsia City. |
| `talk = { ... }` | The NPC-talk portion of the map scripts. The keys inside it are text IDs that NPC objects use. |
| `TEXT_FUCHSIACITY_YOUNGSTER1` | The existing text ID for this particular youngster. It must be spelled exactly as the base map expects. Reusing this ID is what replaces the youngster's generic line. |
| `{ "show_text", ... }` | One script command. `show_text` opens the normal game text box and waits for the player to advance it. |
| `"Someone on ROUTE 19\nfound a quiet cove."` | The message argument for `show_text`. `\n` starts a new line inside the same text box; it is not two characters shown to the player. |
| The second `show_text` table | A second text box, shown after the first is advanced. Use a second command when the message needs another page. |
| Commas | Separate fields or entries in a Lua table. Keep the comma after each command; it lets a later edit add another command cleanly. |

The indentation has no effect on Lua, but it shows the ownership chain:
Fuchsia City contains `talk`, `talk` contains this text ID, and that ID
contains an ordered list of commands.

> [!TIP]
> Keep the message short and insert `\n` deliberately. Game Boy-style text
> boxes are narrow; a newline is more reliable than hoping long prose wraps
> where you want it to.

## Walkthrough: change an existing NPC safely

1. Use the previous section to find the map ID and text ID; do not guess.
   For this guide, the working pair is `"FUCHSIA_CITY"` and
   `TEXT_FUCHSIACITY_YOUNGSTER1`.
2. Add the snippet above inside `main.lua`'s `return function(mod)` block.
   Do not put it after the final `end`; there is no `mod` object outside that
   function.
3. Replace only the two quoted messages first. Keep the map ID, `talk`, text
   ID, braces, and commas unchanged until the dialogue works.
4. Test by loading a save in Fuchsia City and speaking to that youngster. If
   the old dialogue remains, the usual cause is a typo in the map ID or text
   ID.

For a one-box message, the body can be even smaller:

```lua
TEXT_FUCHSIACITY_YOUNGSTER1 = {
  { "show_text", "The cove is east of\nROUTE 19's open water." },
},
```

The outer table is still required because a talk script is always a list of
commands, even when the list has just one `show_text` command.

## Give a new custom-map NPC text

For an NPC Fuchsia Swamp itself adds, two pieces must agree:

1. The map object names its dialogue with `text = "..."`.
2. The map's `talk` table defines a script under exactly the same name.

Here is the Dredger pattern from the swamp map, reduced to text-only parts:

```lua
objects = {
  {
    index = 1,
    name = "JJ_SHREK_DREDGER",
    movement = "STAY",
    range = "DOWN",
    sprite = "SPRITE_SAFARI_ZONE_WORKER",
    text = "TEXT_JJ_SHREK_DREDGER",
    x = 6, y = 7,
  },
},

mod.content.map_scripts:register(MAP, {
  talk = {
    TEXT_JJ_SHREK_DREDGER = {
      { "show_text", "Water belongs in a\npipe. Then it pays." },
    },
  },
})
```

| Object line | Meaning |
| --- | --- |
| `objects = { ... }` | The list of visible, interactable objects on this custom map. It belongs inside the map definition passed to `mod.content.maps:register`. |
| `index = 1` | This object's local number within the map. Keep every object index on that map unique. |
| `name = "JJ_SHREK_DREDGER"` | A readable, mod-prefixed object name. It helps distinguish this object from base-game objects and other swamp NPCs. |
| `movement = "STAY"` | The NPC does not wander. |
| `range = "DOWN"` | The player may talk to the NPC from the tile below it. |
| `sprite = "SPRITE_SAFARI_ZONE_WORKER"` | The sprite ID to draw. This example reuses a base-game worker sprite. |
| `text = "TEXT_JJ_SHREK_DREDGER"` | The bridge from the physical NPC to the dialogue script. This string must exactly match the key in the `talk` table below. |
| `x = 6, y = 7` | The object's location in movement cells, not map blocks. A block occupies two-by-two movement cells. |

| Script line | Meaning |
| --- | --- |
| `register(MAP, ...)` | Associates this script with the swamp map ID stored earlier as `local MAP = "JJ_SHREK_SWAMP"`. Using `MAP` prevents the map definition and its scripts from drifting to different IDs. |
| `TEXT_JJ_SHREK_DREDGER = { ... }` | Defines what happens when an object whose `text` field has that exact value is spoken to. |
| `{ "show_text", ... }` | Uses the same normal text-box command as the base-game-youngster example. New NPCs and existing NPCs share the same dialogue language. |

If `text` says `"TEXT_JJ_SHREK_DREDGER"` but the script key says
`TEXT_JJ_SHREK_DREDGE`, the NPC has no matching dialogue. Treat the text ID
as a link: both ends must be identical.

## Add simple branching text

Dialogue can react to a mod-private quest flag. This is the smallest pattern:

```lua
TEXT_JJ_SHREK_DREDGER = {
  { "check_flag", "mod:site_dredger" },
  { "jump_if_true", "after" },
  { "show_text", "The dredge is still\nrunning." },
  { "jump", "end" },
  { "label", "after" },
  { "show_text", "The dredger is still.\nLeave it that way." },
},
```

| Command | Meaning |
| --- | --- |
| `check_flag` | Reads saved progress. The `mod:` prefix keeps the flag in Fuchsia Swamp's own save data instead of changing a base-game story flag. |
| `jump_if_true` | Moves to the named `label` when the previous check found the flag. |
| `jump` | Skips the later branch after the first message has been shown. Without it, both messages would play. |
| `label` | Names a position in this script. Labels are not shown to the player. |

This text-only example reads a flag but does not set one. A quest interaction
can set it with `{ "set_field", "mod:site_dredger", true }`, as the swamp's
crew-battle script does after a victory.

## Verify the change

Run Fuchsia Swamp's focused checks from the game repository root:

```text
luajit mods/jj_fuchsia_swamp/tests/jj_fuchsia_swamp_test.lua
```

Then open the map in game and talk to the intended NPC. Automated tests can
confirm the script is registered, but the game is the final check for which
NPC the player reaches and how the line wraps on screen.
