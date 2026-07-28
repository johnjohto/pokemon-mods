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
-- empty cap cell before the box's right border (measured at x=121).
function Indicator.placement(wide)
  if wide then return 112, 16 end
  return 8, 8
end

-- Whether this battle is drawing the wide layout. Guarded rather than
-- called outright: wideLayout is v0.1.31+, and on an older engine there
-- is no wide layout to be in.
function Indicator.isWide(battle)
  if not battle or type(battle.wideLayout) ~= "function" then return false end
  return battle:wideLayout() == true
end

-- The icons, as pixel rows; X is ink, and every one is 8x8 to fill the
-- tile placement() picks. main.lua rasterizes them in black like the rest
-- of the enemy HUD, so the zone pass recolors them with everything else.
-- Art lives here rather than beside the draw so the tests can check it.
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

return Indicator
