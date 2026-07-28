-- EXP bar state machine: pure Lua, no love, no engine state.  main.lua
-- feeds it events and draws from it every frame; the headless tests drive
-- it directly.  Keeping the logic here means the tests assert on state,
-- never on pixels.
local Growth = require("src.pokemon.Growth")

local ExpBar = {}
ExpBar.__index = ExpBar

-- fraction of a level the bar sweeps per drawn frame (a full level takes
-- ~0.8s at 60 fps)
local RATE = 0.02

-- progress through the mon's current level, 0..1.  Level-cap mons read
-- full, matching Gen 2.
function ExpBar.progress(data, mon)
  local cap = (data.constants and data.constants.levelCap) or 100
  if mon.level >= cap then return 1 end
  local def = data.pokemon[mon.species]
  local rate = def and def.growthRate
  local floor = Growth.expForLevel(rate, mon.level, data.growth_rates)
  local ceil = Growth.expForLevel(rate, mon.level + 1, data.growth_rates)
  if ceil <= floor then return 0 end
  local f = (mon.exp - floor) / (ceil - floor)
  if f < 0 then return 0 end
  if f > 1 then return 1 end
  return f
end

-- the same conditions under which BattleState draws the player HUD: the
-- bar is HUD chrome, so it lives and dies with the HUD
function ExpBar.visibleFor(battle)
  return battle.player ~= nil
    and not battle.safari
    and not battle.demo
    and not battle.showPlayerBack
    and (battle.introSlide or 0) == 0
end

function ExpBar.new()
  return setmetatable({
    mon = nil,       -- the mon the bar currently tracks
    displayed = 0,   -- the fraction currently drawn
    target = 0,      -- where displayed is heading
    pending = nil,   -- final fraction waiting behind a level-up wrap
  }, ExpBar)
end

-- battle.exp_gained for the tracked mon.  The engine has already applied
-- the exp and any level-ups, so the pre-gain state is reconstructed by
-- subtracting.  This is the bar's ONLY animation trigger; every other
-- state change snaps (see sync).
function ExpBar:onExpGained(data, mon, gained, levels)
  local n = #(levels or {})
  local pre = { species = mon.species, level = mon.level - n,
                exp = mon.exp - gained }
  self.mon = mon
  self.displayed = ExpBar.progress(data, pre)
  if n == 0 then
    self.target = ExpBar.progress(data, mon)
    self.pending = nil
  else
    -- Gen 2 wrap: fill to full through the level-up fanfare, then continue
    -- from empty into the new level
    self.target = 1
    self.pending = ExpBar.progress(data, mon)
  end
end

-- one drawn frame
function ExpBar:tick()
  if self.displayed < self.target then
    self.displayed = math.min(self.target, self.displayed + RATE)
  end
  if self.displayed >= self.target and self.pending ~= nil then
    self.displayed = 0
    self.target = self.pending
    self.pending = nil
  end
end

-- glue the bar to the active mon outside of gains: battle start,
-- switch-in, send-out.  Snaps, never animates.
function ExpBar:sync(data, mon)
  if mon == self.mon then return end
  self.mon = mon
  self.displayed = ExpBar.progress(data, mon)
  self.target = self.displayed
  self.pending = nil
end

return ExpBar
