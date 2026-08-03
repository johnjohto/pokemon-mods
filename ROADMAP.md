# Roadmap

This list tracks the repository's mod ideas. Every shipped mod has its own
folder, manifest, player guide, Discord announcement copy, and headless tests.

## Done

- **jj_repel_prompt**: asks "Use another?" when a Repel expires.
- **jj_alternate_start**: starts a new game in a selected town or city while
  preserving a classic Pallet Town option.
- **jj_hm_field_unlock**: permits field HM use when an eligible party Pokémon,
  the HM, and its badge are available. Battle use still requires learning the
  move.
- **jj_auto_field_moves**: triggers Surf, Cut, Strength, and Flash by contact.
  Fly remains a party-menu action and the mod works with HM Field Unlock.
- **jj_exp_bar**: draws a Gen 2-style active-battler experience bar.
- **jj_caught_indicator**: marks already-caught wild species in battle.
- **jj_running_shoes**: adds configurable foot, bicycle, and Surf movement
  speed without changing tile-based game counters.
- **jj_fuchsia_swamp**: adds an optional Route 19 Surf quest, rest hut, and
  repeatable single-Pokémon move-tutor trials.

## Next

- **More quality-of-life mods**: randomizer, overworld spawns, a more
  informative FIGHT menu, bag and item-storage sorting, and a SELECT hotkey
  for key items. The current upstream hooks can support all but the SELECT
  hotkey, which would need a runtime patch or an upstream change.

## Later

- **Upstream eligibility hook**: filed as PR #310. If it lands,
  jj_hm_field_unlock can drop its runtime patch.
- **Upstream walk-cadence hook**: `movement.speed` sets a step length but does
  not expose the animation clock. jj_running_shoes patches `Player:update` to
  keep the legs in step; a companion hook would remove that patch.
