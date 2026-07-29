-- Pure decision logic for the caught indicator: when the icon shows and
-- where it lands. Kept free of love and engine requires so the headless
-- tests drive it directly; main.lua only reads battle state and draws.
local Indicator = {}

-- The icon shows only where the vanilla enemy HUD name is on screen:
-- a wild battle (trainer and link battles have no wild mon to catch),
-- with the enemy fully sent out and its HUD up. Ghosts (pre-Scope) and
-- the old man's demo are excluded: neither is a catchable encounter the
-- player owns. The dex read is the whole point: only an owned species
-- earns the icon, matching the later generations.
function Indicator.shouldShow(battle, game)
  if not battle or not game then return false end
  if battle.kind ~= "wild" or battle.ghost or battle.demo then return false end
  local enemy = battle.enemy
  if not enemy or not enemy.mon or enemy.fainted then return false end
  if battle.showEnemyTrainer or battle.enemySendingOut then return false end
  if (battle.introSlide or 0) ~= 0 then return false end
  -- the party ball rows hold the HUD back while the intro text runs, in
  -- both layouts (BattleState's enemy HUD gate and WideBattle.drawHUDs
  -- both test introBalls); without this the mark appears before the box
  -- it belongs to
  if battle.introBalls then return false end
  if battle.growInScale and battle:growInScale(enemy) then return false end
  local dex = game.save and game.save.pokedex
  return dex ~= nil and dex.owned ~= nil
     and dex.owned[enemy.mon.species] == true
end

-- Where the icon lands, per battle layout.
--
-- Classic (160x144): the HUD's second row at tile (1,1) -- below the
-- name, directly above the vertical HP-bar bracket the engine draws at
-- tile (1,2). The name's own padding never moves it.
--
-- Wide (304x144, upstream v0.1.31's BATTLE LAYOUT -> WIDE): the foe's
-- status is a 16x4 box at the origin whose *name* row is drawn at (8,8) --
-- exactly the classic icon spot, so the old fixed placement printed the
-- mark over the name's first letter. The row below is the HP bar, which
-- with its end cap fills out to the box's inner edge (x=120). So the icon
-- goes immediately right of the bar's fill, which ends at x=112, in the
-- empty cap cell before the box's right border (measured at x=121). The
-- extra pixel of clearance puts its right edge flush at 120, hard against
-- that border without touching it.
function Indicator.placement(wide)
  if wide then return 113, 16 end
  return 8, 8
end

-- Whether this battle is drawing the wide layout. Guarded rather than
-- called outright: wideLayout is v0.1.31+, and on an older engine there
-- is no wide layout to be in.
function Indicator.isWide(battle)
  if not battle or type(battle.wideLayout) ~= "function" then return false end
  return battle:wideLayout() == true
end

-- The shake offsets the mark rides, per layout and per the ICON SHAKE row.
--
-- Classic: the same offsets BattleState applies to the scene and to the
-- enemy HUD block, so the mark shakes with the name it sits beside. The
-- fx.shake branch reproduces BattleState's own fallback -- a bare countdown
-- with no program behind it alternates +/-2 on a four-frame cycle.
--
-- Wide: nothing, whatever the row says. That layout draws its status boxes
-- outside the shaken picture regions, so a still mark is what matches a
-- still foe panel; riding the shake there would be the icon jittering alone
-- against a box that isn't moving.
--
-- shake=false pins it in the classic layout too, for anyone who finds a
-- jittering 8x8 harder to read than a still one. The cost is honest: the
-- mark holds its place while the name beside it shakes.
function Indicator.shakeOffset(battle, wide, shake)
  if wide or shake == false or not battle then return 0, 0 end
  local fx = battle.fx
  local sx = (fx and fx.shakeX) or 0
  local sy = (fx and fx.shakeY) or 0
  if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
    sx = (battle.frame or 0) % 4 < 2 and 2 or -2
  end
  sx = sx + ((fx and fx.hudShakeX) or 0)
  return sx, sy
end

-- The white wash BattleState and WideBattle lay over the screen on a flash
-- frame. Not a preference, which is why no option reaches it.
Indicator.FLASH_ALPHA = 0.85

-- That wash's alpha this frame, or nil when the screen is not flashing.
--
-- battle.overlay runs AFTER the flash rectangle in both layouts
-- (BattleState.draw, WideBattle.draw), so anything drawn from the hook lands
-- on top of it -- the mark would sit crisp and black over an 85%-white
-- screen, the one thing on it not flashing. Repainting the same wash over
-- the icon's own cell, not the screen (which is already washed, and would
-- only get whiter), puts it back under the effect exactly as though it had
-- been drawn before it.
function Indicator.flashAlpha(battle)
  local fx = battle and battle.fx
  if not (fx and fx.flash and fx.flash > 0) then return nil end
  if ((battle.frame or 0) % 4) >= 2 then return nil end
  return Indicator.FLASH_ALPHA
end

-- The icons, as pixel rows; X is ink, and every one is 8x8 to fill the
-- tile placement() picks. main.lua rasterizes them as white and tints them
-- black like the rest of the enemy HUD -- or with the recorded capture
-- ball's color. Art lives here rather than beside the draw so the tests can
-- check it.
Indicator.ICONS = {
  -- the Gen 1 mark: a small open ball, all outline
  gen1 = {
    "........",
    "...XX...",
    "..X.XX..",
    ".XXXXXX.",
    ".X....X.",
    "..X..X..",
    "...XX...",
    "........",
  },
  -- the Gen 2 mark: a filled top with a glint at the upper left, the
  -- classic red-top silhouette in one bit, over an open lower half
  gen2 = {
    "........",
    "..XXXX..",
    ".XX.XXX.",
    ".XXXXXX.",
    ".X....X.",
    ".X....X.",
    "..XXXX..",
    "........",
  },
}

Indicator.DEFAULT_ICON = "gen2"

-- An unknown style is answered with the default rather than nothing: a
-- stale saved option must never cost the player the icon entirely.
function Indicator.pixels(style)
  return Indicator.ICONS[style] or Indicator.ICONS[Indicator.DEFAULT_ICON]
end

-- Colors for balls that can make a successful Gen 1 catch. They deliberately
-- live apart from the icon choice: GEN 1 / GEN 2 remains the player's chosen
-- silhouette, while the color answers which ball most recently caught that
-- species. A ball unknown to this release uses the normal HUD ink instead.
Indicator.BALL_COLORS = {
  POKE_BALL = { 0.86, 0.23, 0.20 },
  GREAT_BALL = { 0.22, 0.47, 0.85 },
  ULTRA_BALL = { 0.89, 0.67, 0.08 },
  MASTER_BALL = { 0.60, 0.30, 0.77 },
  SAFARI_BALL = { 0.33, 0.69, 0.32 },
}

function Indicator.ballColor(ball)
  return Indicator.BALL_COLORS[ball]
end

return Indicator
