# Lua guide: Alternate Start

Alternate Start is a new-game flow layered onto Oak's existing introduction.
The important design choice is to keep the base speech, starter creation, save
flags, and rival battles in the engine's normal paths wherever possible.

## Files

| File | Purpose |
| --- | --- |
| `main.lua` | Adds the town and starter choices, prepares an alternate save, gates rival scenes, and runs the story-beats visit scene. |
| `tests/jj_alternate_start_test.lua` | Exercises quick start, story beats, classic start, safe towns, rival gates, and scene cleanup. |

## `main.lua`, data and entry point

The entry function defines `TOWNS` and `STARTERS`. `TOWNS` includes a Pallet
classic option plus only locations with a safe way out for a fresh save. Keeping
these lists as data makes labels and choices easy to change without rewriting
the flow.

`grantStarter` is the single starter-writing function. It creates a level 5
Pokémon, stamps the original trainer, adds it to the party, updates Pokédex
seen and owned bits, and sets the normal opening flags. Both story modes call
this function, so they cannot disagree about what a starter grants.

## Extending Oak's speech

The `intro.oak_speech.build` wrapper calls `nextFn` first and inserts steps
before the engine's `shrink` step. Quick mode adds a starter `choice`; story
mode lets the later visit scene choose it. The town choice uses a custom `fn`
step because the fixed choice box cannot hold the whole list. It pushes a
`ListMenu`, records the answer, and treats cancel as Pallet so the speech never
waits for a menu that was dismissed.

The `intro.oak_speech.finished` listener ignores Pallet and repeat finishes. For
an alternate town it moves the Viridian old man, opens Saffron's guard gates
when needed, finds the town's fly warp, sets `lastHeal` and `lastOutdoor`, and
stores the private `startedInTown` marker. Quick mode grants the starter and
tutorial flags immediately. Story mode defers that work to the visit scene.

The warp is deferred until `screen.popped`. Pushing a warp while Oak's speech
is still on the state stack would be popped as part of closing the speech and
could cause the finish event to fire repeatedly.

## Rival gates and options

The `STORY BEATS` option defaults to true. `storyActive` requires both that
setting and the private start marker, which protects vanilla and classic saves.
`badgeCount` uses the engine's badge service. `suppressBelow` returns true only
at a specific NPC position, before its flag is set, while no script is busy, and
below the required badge count.

Route 22 needs a special handler because the base scene only knows how to run
before Brock. `route22FirstBattleRows` builds the same rival rows and the gate
starts them after the first badge. The other gates release the base scripts at
two, three, four, and six badges. The Pokémon Tower talk override also gives
Blue's visible NPC the same early refusal.

## The visit scene

`startVisitScene` spawns temporary Oak and Blue NPCs beside the selected town's
Pokémon Center and queues their movement and dialogue. A menu callback calls
`pickStarter`, which grants the Pokémon, records `introScene = "granted"`
before the battle, starts Blue's counter-pick battle, then cleans up NPCs and
marks the scene done.

The three stage values, unset, `spawned` through the spawn state, `granted`, and
`done`, make the scene safe across a blackout. `map.entered` retries an unstarted
scene and removes NPCs after a blackout during the battle. `npcIndex` converts a
runtime object ID into the script index expected by movement rows.

## Test tour

The test verifies inserted speech steps, quick-start starter data, tutorial
flags, heal points, classic no-op behavior, Saffron gates, every rival badge
threshold, menu starter selection, and blackout-safe scene cleanup. It uses
small doubles for the game stack and menu callbacks, then inspects the rows
that the real script runner would execute.

Run it from the game checkout:

```
luajit mods/jj_alternate_start/tests/jj_alternate_start_test.lua
```

## Safe extension points

Add a start location only after proving its exits and fly warp in a test. Do not
set the alternate marker for Pallet. Use `grantStarter` for any new starter
path, and defer new-game warps until the speech state has popped. Keep rival
gates private to alternate-start saves so normal games remain untouched.
