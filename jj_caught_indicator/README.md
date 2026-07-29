# Caught Indicator

A pokeball icon appears next to a wild pokémon's name in battle if its
species is already registered as caught in your Pokédex, like Pokémon
Gold/Silver and later. No more checking the dex before deciding whether
to weaken it or run.

- Wild battles only: trainer and link battles get no icon (their pokémon
  can't be caught anyway).
- Ghosts and the old man's tutorial battle get no icon either.
- The icon rides the enemy HUD, so it shakes and slides with the name it
  sits next to — or holds still, if you turn **ICON SHAKE** off.
- It dims under the battle's screen flash along with everything else.
- Purely visual: catching, the dex, and everything else play as vanilla.

## Options

A **CAUGHT ICON** row in the options menu picks the mark: **GEN 2**
(default — a filled top with a glint at the upper left over an open lower
half, the classic red-top silhouette in one bit) or **GEN 1** (a small
open ball, all outline). Both are 8×8 and drawn in the HUD's own ink, so
either recolors with the rest of the screen.

**LAST BALL** is on by default. Once the mod is installed, a successful
wild catch records the ball used and colors that species' indicator the
next time you meet it: Poké Ball red, Great Ball blue, Ultra Ball yellow,
Master Ball purple, and Safari Ball green. It always uses your chosen
**CAUGHT ICON** silhouette. Turn the row off to keep every mark in the
normal HUD ink.

Gen 1 itself saves only whether a species is owned, not the ball used to
obtain it. Existing Pokédex entries, as well as starters, gifts, trades,
and catches made while the mod was disabled, therefore retain the normal
HUD-ink mark. A later catch of that species updates the saved color to its
new ball.

Upgrading from 1.0.0 changes the mark you see, since that release drew
one icon unconditionally and neither option is a pixel match for it.

An **ICON SHAKE** toggle decides whether the mark rides the enemy HUD's
shake. **ON** is the default and the original behaviour: the mark moves
with the name it sits beside, so the pair reads as one label. **OFF** pins
it, for anyone who finds a jittering 8×8 harder to read than a still one —
the tradeoff being that the mark then holds its place while the name next
to it shakes.

Only the classic layout has anything to pin. The widescreen layout draws
its status boxes outside the shaken picture regions, so the mark was
already still there and stays that way whichever way the row is set.

## Screen effects

The battle's white screen flash gets no option, because a mark floating
crisp over a flashed screen is wrong rather than a matter of taste. The
`battle.overlay` hook the mod draws from runs *after* each layout paints
its flash rectangle, so anything drawn there lands on top of it. The mod
repaints the same wash over the icon's own cell — not the screen, which
already has one and would only get whiter — which puts the mark back
under the effect exactly as though it had been drawn before it.

## Battle layouts

Both of the engine's battle layouts are supported. In the classic 160×144
one the mark sits under the foe's name. In the widescreen layout
(**OPTION → BATTLE LAYOUT → WIDE**, added in gen1recomp v0.1.31) the foe's
status box draws its *name* exactly where that mark used to go, so the
icon moves to the immediate right of the foe's HP bar, clear of the box
and of the enemy's picture.

Older engines are unaffected: the mod asks whether the battle is wide
before assuming it can be, so it keeps working on versions that have no
widescreen layout at all.

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
luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
```
