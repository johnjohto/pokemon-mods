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
  if battle.growInScale and battle:growInScale(enemy) then return false end
  local dex = game.save and game.save.pokedex
  return dex ~= nil and dex.owned ~= nil
     and dex.owned[enemy.mon.species] == true
end

-- The icon sits on the HUD's second row at tile (1,1): below the name,
-- directly above the vertical HP-bar bracket the engine draws at tile
-- (1,2). Fixed spot; the name's own padding never moves it.
function Indicator.placement()
  return 8, 8
end

-- The icons, as pixel rows; X is ink, and every one is 8x8 to fill the
-- tile placement() picks. main.lua rasterizes them in black like the rest
-- of the enemy HUD, so the zone pass recolors them with everything else.
-- Art lives here rather than beside the draw so the tests can check it.
Indicator.ICONS = {
  -- the original: an open pokeball outline
  ball = {
    "..XXXX..",
    ".X....X.",
    "X......X",
    "XXXXXXXX",
    "X......X",
    ".X....X.",
    "..XXXX..",
    "........",
  },
  -- filled top with a glint at the upper left, the classic red-top
  -- silhouette in one bit; it rides a pixel lower than the outline ball
  solid = {
    "........",
    "..XXXX..",
    "XX.XXXXX",
    "XXXXXXXX",
    "X......X",
    "X......X",
    ".XXXXXX.",
    "........",
  },
}

Indicator.DEFAULT_ICON = "ball"

-- An unknown style is answered with the default rather than nothing: a
-- stale saved option must never cost the player the icon entirely.
function Indicator.pixels(style)
  return Indicator.ICONS[style] or Indicator.ICONS[Indicator.DEFAULT_ICON]
end

return Indicator
