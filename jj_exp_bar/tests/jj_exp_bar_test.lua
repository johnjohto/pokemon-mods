-- Standalone: luajit mods/jj_exp_bar/tests/jj_exp_bar_test.lua
-- Drives the pure state machine in expbar.lua directly, then the wiring
-- through the public events/hook: exp gains animate, everything else
-- snaps, and the draw runs headless without touching battle logic.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")

local run = T.sdk.loadMod("mods/jj_exp_bar")
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local ExpBar = require("mods.jj_exp_bar.expbar")

-- MEDIUM_FAST (n^3) keeps the expected fractions computable by hand:
-- level 9 = 729, level 10 = 1000, level 11 = 1331
local data = {
  pokemon = { TESTMON = { growthRate = "MEDIUM_FAST" } },
  growth_rates = nil,
  constants = nil,
}

local function mon(level, exp)
  return { species = "TESTMON", level = level, exp = exp,
           hp = 20, stats = { hp = 20 } }
end

local function near(a, b) return math.abs(a - b) < 1e-9 end

-- the options row is registered with its default
local schema = run.loader.optionSchemas["jj_exp_bar"]
T.check(schema and schema[1], "options schema registered")
T.eq(schema[1].key, "bar_style", "the row key is bar_style")
T.eq(schema[1].default, "ink", "INK is the default style")
T.eq(#schema[1].choices, 3, "three styles offered")
T.eq(schema[2].key, "bar_y", "the second row is the Y position")
T.eq(schema[2].default, 90, "BORDER is the default position")

-- progress math
T.eq(ExpBar.progress(data, mon(10, 1000)), 0, "level floor reads empty")
T.check(near(ExpBar.progress(data, mon(10, 1165.5)), 0.5),
  "mid-level reads half")
T.eq(ExpBar.progress(data, mon(10, 900)), 0, "below the floor clamps to 0")
T.eq(ExpBar.progress(data, mon(10, 2000)), 1, "past the ceiling clamps to 1")
T.eq(ExpBar.progress(data, mon(100, 999999)), 1, "level cap reads full")

-- visibility mirrors the player HUD's own rules
local function battle(over)
  local b = { player = { mon = mon(10, 1000) }, data = data }
  for k, v in pairs(over or {}) do b[k] = v end
  return b
end
T.check(ExpBar.visibleFor(battle()), "visible in a normal battle")
T.check(not ExpBar.visibleFor(battle({ safari = true })),
  "hidden in the Safari Zone")
T.check(not ExpBar.visibleFor(battle({ demo = true })),
  "hidden in the old-man demo")
T.check(not ExpBar.visibleFor(battle({ showPlayerBack = true })),
  "hidden during the trainer intro")
T.check(not ExpBar.visibleFor(battle({ introSlide = 2 })),
  "hidden while the HUD slides in")
T.check(not ExpBar.visibleFor({ data = data }), "no player mon, no bar")

-- a plain gain animates from the pre-gain value to the final one
local bar = ExpBar.new()
local m = mon(10, 1000)
m.exp = m.exp + 165.5 -- the engine applies exp before the event
bar:onExpGained(data, m, 165.5, {})
T.eq(bar.displayed, 0, "the fill starts at the pre-gain value")
T.check(near(bar.target, 0.5), "and heads for the final value")
for _ = 1, 26 do bar:tick() end
T.check(near(bar.displayed, 0.5), "the fill lands on the final value")

-- a gain that levels up wraps: fill to full, reset, fill the remainder
bar = ExpBar.new()
m = mon(9, 729)
m.level, m.exp = 10, 1165.5 -- engine state after gaining 436.5 with a level
bar:onExpGained(data, m, 436.5, { 10 })
T.eq(bar.displayed, 0, "the wrap starts at the pre-gain value")
T.eq(bar.target, 1, "and fills to full first")
for _ = 1, 50 do bar:tick() end
T.eq(bar.displayed, 0, "at full the bar resets to empty")
T.check(near(bar.target, 0.5), "then heads for the remainder")
for _ = 1, 26 do bar:tick() end
T.check(near(bar.displayed, 0.5), "the remainder lands")

-- sync snaps on mon change, never animates, and leaves a tracked mon alone
bar = ExpBar.new()
local a, b = mon(10, 1165.5), mon(9, 800)
bar:sync(data, a)
T.check(near(bar.displayed, 0.5), "battle start snaps to stored progress")
bar.target = 0.9
bar:sync(data, a)
T.eq(bar.target, 0.9, "re-syncing the same mon is a no-op")
bar:sync(data, b)
T.check(near(bar.displayed, (800 - 729) / (1000 - 729)),
  "a switch-in snaps to the new mon")

-- wiring: the live mod listens on battle.exp_gained, active battler only
local topState
local gameStub = {
  data = data,
  stack = { top = function() return topState end },
}
Runtime.emit("game.ready", { game = gameStub })
local live = ExpBar.active
T.check(live ~= nil, "the mod exposes its bar for the tests")
m = mon(10, 1000)
local b0 = battle()
b0.player.mon = m
m.exp = 1165.5
Runtime.emit("battle.exp_gained",
  { battle = b0, mon = m, gained = 165.5, levels = {} })
T.check(near(live.target, 0.5), "an active-battler gain moves the bar")
Runtime.emit("battle.exp_gained",
  { battle = b0, mon = mon(5, 500), gained = 100, levels = {} })
T.check(near(live.target, 0.5), "EXP ALL recipients do not move the bar")

-- the overlay hook draws headless: visible battle advances the bar, a
-- hidden one leaves it alone, and neither errors
topState = b0
local before = live.displayed
Runtime.call("battle.overlay", function() end, b0)
T.check(live.displayed > before, "the overlay ticks the bar when visible")
local ok = pcall(Runtime.call, "battle.overlay", function() end,
  battle({ safari = true }))
T.check(ok, "the overlay stays quiet when the HUD is hidden")

-- a screen pushed over the battle (party, bag, a modal box) suppresses
-- the bar entirely
topState = { modal = true }
before = live.displayed
Runtime.call("battle.overlay", function() end, b0)
T.eq(live.displayed, before, "a pushed screen hides the bar")
topState = b0

T.finish("jj_exp_bar")
