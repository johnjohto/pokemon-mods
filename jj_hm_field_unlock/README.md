# HM Field Unlock

HM Field Unlock lets a party Pokémon use Cut, Fly, Surf, Strength, or Flash in
the field without having the move in its moveset. The Pokémon must be able to
learn that HM, and you must still own both the HM and its required badge.
Battles are unchanged: a Pokémon can use an HM move in battle only when it has
actually learned the move.

Version: 1.0.0.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_hm_field_unlock` release `.zip` through the **MODS** tab and
make sure it is enabled. You may use an existing save. This mod has no options.

For each field move, keep the HM in either your Bag or PC item storage, earn
the listed badge, and have at least one eligible Pokémon in the active party:

| Field move | Item | Badge |
| --- | --- | --- |
| Cut | HM01 | Cascade Badge |
| Fly | HM02 | Thunder Badge |
| Surf | HM03 | Soul Badge |
| Strength | HM04 | Rainbow Badge |
| Flash | HM05 | Boulder Badge |

The mod checks whether a species can learn the move, not whether the individual
Pokémon already knows it. A fainted eligible party Pokémon still satisfies the
field check, as it does in the game's usual field-move handling.

## Use a field move

Open the party menu while in the overworld, select an eligible Pokémon, then
choose the field-move action that appears in its submenu. The game still
decides whether the current location allows that action. For example, Fly is
available only outdoors and Flash appears only in a dark area.

The mod does not bypass map-specific restrictions or replace the game's normal
field-move animations and effects. If a move cannot be used at the selected
location in the unmodified game, owning the HM does not make it usable there.

## Use with Auto Field Moves

Auto Field Moves is optional. When both mods are enabled, its contact triggers
use this wider HM rule too. Walk into water, a cuttable tile, a pushable
boulder, or a dark cave only after you meet the same item, badge, and party
requirements above. Fly remains a party-menu action because it has no contact
trigger.

## Troubleshooting

If a field action is missing, verify all four requirements: the mod is enabled,
the correct HM is in the Bag or PC storage, the correct badge is owned, and a
party species can learn the move. Check the location as well. A Pokémon that
cannot learn a move will not receive an action merely because another party
member can use it.

## For contributors

Read [LUA_GUIDE.md](LUA_GUIDE.md) for the HM lookup, eligibility rule, party
submenu hook, sibling-mod export, and focused tests.

From the game repository root:

```
luajit mods/jj_hm_field_unlock/tests/jj_hm_field_unlock_test.lua
```

Then run `luajit tests/run_modkit.lua` before release.
