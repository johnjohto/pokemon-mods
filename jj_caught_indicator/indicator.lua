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

return Indicator
