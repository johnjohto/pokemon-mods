# Roadmap

Mod ideas, roughly in the order we plan to build them. Each becomes a
`jj_*` folder with its own manifest, readme, and headless tests when work
starts.

## Done

- **jj_repel_prompt** — asks "Use another?" when a Repel wears off.
- **jj_alternate_start** — begin a new game tutorial-free at any town,
  city, or flyable location.
- **jj_hm_field_unlock** — HMs work in the field without being taught:
  a party pokémon that can learn the move, the HM in the bag or PC box,
  and the badge are enough. Battle still requires teaching.
- **jj_auto_field_moves** — field moves fire on contact: water surfs,
  cuttable tiles cut, boulders activate STRENGTH, dark caves FLASH.
  FLY stays menu-only; composes with jj_hm_field_unlock automatically.
- **jj_exp_bar** — Gen 2-style EXP bar under the player HP bar in battle:
  fills on exp gain, wraps through level-ups, three fill styles.
- **jj_caught_indicator** — Gen 2-style pokeball icon next to a wild
  enemy's name when its species is already owned in the dex.
- **jj_running_shoes** — hold B to run: half the frames per tile on foot,
  with the leg cadence doubled to match. Bike and surf keep their speed.

## Next

- **Fuchsia Swamp** (`jj_fuchsia_swamp`) — an optional, Surf-gated Route 19 swamp quest with
  a custom map, a post-quest rest point, and earned move-tutor
  trials ([#1](https://github.com/johnjohto/pokemon-mods/issues/1)).
- **More QoL mods** — grilled candidates: randomizer, overworld spawns,
  more informative FIGHT menu, bag/item storage sort, SELECT hotkey for
  key items. All feasible against the current upstream hooks except the
  SELECT hotkey, which would need a runtime patch or an upstream PR.

## Later

- **Upstream eligibility hook** — filed as PR #310. If it lands,
  jj_hm_field_unlock can drop its runtime patch.
- **Upstream walk-cadence hook** — `movement.speed` sets a step's length
  but nothing exposes the animation clock, so jj_running_shoes patches
  Player:update to keep the legs in step. A companion hook there would
  let it drop the patch.
