# Gen 1 Open-World Conversion: Blocker Audit

An assessment of every progression gate in Pokémon Red/Blue, sorted by what an open-world restructure should do with it. The organizing question for each entry is: **does this gate exist to teach, to pace, or to fence?** Teaching gates can go once the player is trusted. Pacing gates need replacing with something non-physical. Fencing gates should just be deleted.

---

## The core structural problem

Gen 1's map is a directed graph with almost no redundancy. Nearly every region has exactly one entrance, and the key to that entrance sits in the region immediately before it. Opening the world isn't primarily about deleting NPCs — it's about **adding edges to that graph** so that removing a gate doesn't create a softlock or a dead zone.

Three chokepoints matter more than all the others combined:

| Chokepoint | What it gates | Why it's fragile |
|---|---|---|
| **Cut** (S.S. Anne captain) | Cerulean east exit, Vermilion Gym, ~a third of the map | Ship departs permanently after you take it |
| **Surf** (Safari Zone Secret House) | All water routes, Seafoam, Cinnabar | Locked inside a timed minigame in a late town |
| **Poké Flute** (Mr. Fuji) | Both Snorlax, Routes 12 & 16 | Terminal node of a 4-step quest chain |

Everything else is comparatively cosmetic. If you fix only these three acquisition points, the game is already dramatically more open.

---

## Tier 1 — Delete outright

Pure fencing. No in-world logic, no player skill expressed, nothing lost.

- **Thirsty Saffron gate guards (all four).** The single most arbitrary gate in the game. Saffron is geographically central and should be a hub from the start. Delete the scripts entirely; keep the vending machines as a joke item source.
- **Old man blocking Viridian's north exit.** A tutorial gate. In an open-world build the catching demo should be an optional prompt, not a wall.
- **Old man blocking Pewter's east exit post-Brock.** Redundant with the badge itself.
- **Rocket blocking Saffron Gym entrance.** Ties the gym to Silph Co. completion for no reason once Saffron is open.
- **Cut tree in front of Vermilion Gym.** Double-gates Surge behind Cut when Cut is already required to leave Cerulean eastward. Remove this one; keep the Cerulean tree as a shortcut.
- **Route 16 gate guard requiring a bicycle.** Cycling Road works fine on foot; the guard exists solely to sequence the bike purchase.
- **Bike Voucher / ¥1,000,000 price tag.** Traversal speed is a quality-of-life baseline in an open map, not a reward. Either drop the price to something affordable (~¥3,000) or hand the bike out in Viridian. Keep the Fan Club chairman as a flavor NPC with a different reward.

---

## Tier 2 — Rework

These have real design value but the current implementation is too sequential.

### HM field-use badge requirements
Remove them wholesale. In vanilla, holding an HM isn't enough — you need the matching badge, which double-locks every traversal tool to the gym order. This is the highest-leverage single change in the whole project, and in the `pokered` disassembly it's a small, well-isolated set of checks.

Once badges no longer gate HM use, you have a choice about the HMs themselves:

- **Option A — Key-item traversal.** Convert Cut/Surf/Strength/Flash to key items usable from the menu (the Gen 7 Ride Pager model). Frees up four moveslots and removes the HM-mule problem. Most player-friendly, least faithful.
- **Option B — Keep as moves, multiply the sources.** Place a second obtainable copy of each HM in a different region so no single dungeon is a hard dependency. Preserves the "earned a new verb" feeling, which is worth something in an open world.

Option B is the better fit if you want the map to still feel like it unlocks in layers. Option A is better if your goal is maximum freedom on turn one.

### Surf (highest priority)
Currently the Secret House in the Safari Zone — behind a ¥500 entry fee, a 500-step timer, and the need to have already walked to Fuchsia. That's three gates stacked on the game's most world-opening ability.

Move the primary copy somewhere reachable early — the Cerulean Cape area or Route 25 near Bill's house both work thematically — and leave the Secret House copy in place as a redundant find. If you'd rather keep Surf as a deliberate mid-game "the map just doubled" moment, that's a legitimate design choice, but then it should be the reward for a real dungeon rather than a step-limited minigame.

### Cut and the S.S. Anne
The ship departing forever after you take Cut is a permanent-missable in a game that otherwise lets you re-enter everything. Two fixes:

1. Keep the ship docked indefinitely. Simplest, and the S.S. Anne is a good early-game trainer-density zone worth revisiting.
2. Move Cut to a land-based source (Vermilion's Pokémon Fan Club, or the Route 11 gate) and repurpose the ship as pure optional content.

Either way, decouple Cut from the S.S. Ticket → Bill → Nugget Bridge chain.

### Flash and Rock Tunnel
Two nested gates: HM05 requires catching 10 species from Oak's Aide, and Rock Tunnel is unnavigable without it. Rework by making the tunnel *dim* rather than black — a small visible radius that's playable but unpleasant. Flash becomes a comfort upgrade instead of a wall, and the 10-species requirement becomes a reasonable soft nudge rather than a hard stop. Drop the requirement to 5 species if you keep it at all.

### Poké Flute chain (Rocket Hideout → Silph Scope → Marowak → Mr. Fuji)
This chain is actually good dungeon design — it's the closest Gen 1 gets to a Zelda-style key-and-lock arc. Keep the structure. The problem is only that it's mandatory and strictly ordered. Fixes:

- Add a second Silph Scope acquisition (a Rocket drop in Celadon, or a Game Corner prize) so the Hideout isn't compulsory.
- Leave the two Snorlax where they are. In a genuinely open map they become optional shortcuts rather than walls — which is exactly what you want a mid-game key to do.

### Strength / Gold Teeth / Warden
Fine as a sidequest, badly placed. The Warden is in Fuchsia, which vanilla reaches late. If Fuchsia is now reachable early, this resolves itself — just verify the Gold Teeth spawn in the Safari Zone doesn't depend on flags set elsewhere.

### Viridian Gym's seven-badge lock
Delete the lock, keep Giovanni brutal. In an open world the gyms should be a difficulty menu, not a queue. Consider retuning gym levels so they span a real range (Brock ~12, Giovanni ~50) and letting the player read the room. Optionally add a sign outside each gym listing the leader's ace level as a soft difficulty label.

### Route 22/23 badge-check gates
Eight sequential checkpoints is the antithesis of an open structure. Collapse to a **single** gate at the Victory Road entrance. Whether it checks for 8 badges or a lower number depends on how you want the endgame paced — 6 badges with a level-scaled Elite Four is a defensible alternative that keeps two gyms as optional challenges.

---

## Tier 3 — Keep

These aren't world gates; they're dungeon internals, and removing them just makes the dungeons emptier.

- **Card Key** (Silph Co.) — intra-dungeon key, working as intended.
- **Secret Key** (Pokémon Mansion) — same. The Mansion is one of the better-designed areas in the game.
- **Lift Key** (Rocket Hideout) — same.
- **Victory Road boulder puzzles** — puzzles, not gates, once Strength is unrestricted.
- **Seafoam Islands boulders** — same.
- **Cerulean Cave guard (post-Champion)** — a postgame gate is fine and gives the credits some weight.
- **Mt. Moon fossil Super Nerd** — trivial flavor. Consider allowing both fossils, since the one-choice restriction only exists to force trading.

---

## What replaces the gates

Removing walls without replacing pacing produces a game where a level-8 Charmander wanders into Viridian Gym. Gen 1 has an underused mechanic that solves this cleanly.

### Extend the obedience system
Vanilla ties obedience to badge count, but only for **traded** Pokémon. Extend the same check to all Pokémon and you get a soft gate that never blocks movement:

| Badges | Obedience cap |
|---|---|
| 0 | Lv. 15 |
| 2 | Lv. 25 |
| 4 | Lv. 35 |
| 6 | Lv. 45 |
| 8 | No cap |

The player can walk anywhere immediately, but can't *win* everywhere — and the feedback is a disobeying Pokémon rather than a locked door. This is the single best replacement for the removed physical gates.

### Supporting soft gates
- **Encounter-level tiering.** Let route encounter levels telegraph difficulty honestly. A route with Lv. 40 wilds tells the player everything a guard would have.
- **Trainer density as friction.** High-level areas with expensive-to-cross trainer gauntlets discourage without forbidding.
- **One-way ledges.** Already in the game and already an open-world-friendly tool — use them to make risky excursions survivable via retreat rather than impossible.
- **Signposting.** Route signs listing recommended levels. Cheap, effective, and in-fiction.

---

## Suggested implementation order

1. Remove HM badge requirements (unblocks everything else conceptually).
2. Delete all Tier 1 NPCs.
3. Relocate Surf; make the S.S. Anne permanent or relocate Cut.
4. Implement the obedience cap system.
5. Collapse the Route 22/23 badge checks to one gate.
6. Retune gym and route levels into a coherent difficulty spread.
7. Playtest for softlocks — specifically anything that depends on a map-change event flag firing in a now-skippable order.

Step 7 is where most of the real work lives. The `pokered` disassembly's event flag system has a fair number of cross-map dependencies that only hold because the vanilla route is linear, and those are exactly the things that break when the route stops being linear.

---

## The one judgment call worth flagging

There's a real tension between "open world" and "the map unlocks in layers." Surf and Strength genuinely make the world feel bigger when you earn them — that's a Metroidvania pleasure, not a fencing tactic, and stripping it out costs you something. My read is that the traversal HMs are worth keeping as gated abilities while the *NPC* gates all go, because ability gates are earned and legible while a thirsty guard is just a wall wearing a hat. But a mod aimed at maximum day-one freedom would reasonably disagree and hand out all four HMs in Pallet Town.
