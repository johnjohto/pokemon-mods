# Repel Reuse Prompt

Repel Reuse Prompt adds one question to the normal overworld flow: when a
Repel expires, the game asks whether to use another one. It does not change
Repel duration, encounter rules, battle behavior, or the Bag's normal manual
use flow.

Version: 1.0.0.

## Prerequisites and installation

Follow the [root installation guide](../README.md#before-you-install-a-mod).
Import the `jj_repel_prompt` release `.zip` from the game's **MODS** tab and
confirm that the mod is enabled. You can use an existing save. The feature has
no settings and needs no in-game setup.

## How to use it

1. Use a Repel, Super Repel, or Max Repel normally from the Bag.
2. Walk until the active Repel expires and dismiss the game's usual expiration
   message.
3. If another Repel is in the Bag, choose **YES** to spend one immediately or
   **NO** to continue without one.

The prompt always selects the weakest available item: Repel first, then Super
Repel, then Max Repel. Choosing **YES** removes one of that item and applies
its ordinary effect. Choosing **NO** leaves the Bag and the Repel counter as
they are after expiration.

## What to expect

The prompt appears only after an active Repel reaches zero and its normal
expiration textbox has closed. It does not appear while a Repel still has
steps remaining, and it does not appear when the Bag has no Repel, Super
Repel, or Max Repel to offer. The mod does not look in PC item storage.

## Troubleshooting

If the prompt does not appear, first check the MODS list and make sure a Repel
actually expired while you were walking in the overworld. Then confirm that a
second Repel item is in the Bag, not only in storage. See the
[root troubleshooting guide](../README.md#update-disable-and-troubleshoot) if
the mod itself is not listed.

## For contributors

Run the focused test from the game repository root:

```
luajit mods/jj_repel_prompt/tests/jj_repel_prompt_test.lua
```

Run `luajit tests/run_modkit.lua` before release. The root README explains the
required linked-mod development setup.
