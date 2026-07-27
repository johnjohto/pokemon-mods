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

## Next

- **jj_auto_field_moves** — automatic field move use. Walking into water
  surfs instantly, cuttable tiles cut, boulders activate STRENGTH, dark
  caves FLASH. FLY stays menu-only. Uses jj_hm_field_unlock's wider rule
  when that mod is installed (optional dependency via mod interop).

## Later

- **Upstream eligibility hook** — file a PR proposing a proper
  `fieldmove.eligibility` hook in partyKnows so jj_hm_field_unlock can
  drop its runtime patch.
