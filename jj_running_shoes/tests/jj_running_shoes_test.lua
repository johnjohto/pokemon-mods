-- Standalone: luajit mods/jj_running_shoes/tests/jj_running_shoes_test.lua
-- Drives the pure decision module, then the real thing: a real Player
-- taking a real step through the real movement.speed chain, so the frame
-- count and the leg cadence are both measured, not asserted about.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local run = T.sdk.loadMod("mods/jj_running_shoes", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local Run = require("mods.jj_running_shoes.runshoes")

-- ------- the options rows

local schema = run.loader.optionSchemas["jj_running_shoes"]
T.check(schema and schema[1], "options schema registered")
T.eq(schema[1].key, "speed", "the first row is the run speed")
T.eq(schema[1].default, 2, "2X is the default run speed")
T.eq(schema[2].key, "trigger", "the second row is the trigger")
T.eq(schema[2].default, "hold", "HOLD B is the default trigger")
T.eq(schema[3].key, "bike", "the third row is the bicycle")
T.eq(schema[3].default, 1, "the bicycle is vanilla until asked otherwise")

-- ------- the gate, on foot

local HOLD = { speed = 2, trigger = "hold" }
local function input(down)
  return { isDown = function(_, b) return down and b == "b" end }
end
local function ctx(over)
  local c = { onBike = false, surfing = false, input = input(true) }
  for k, v in pairs(over or {}) do c[k] = v end
  return c
end

T.check(Run.running(ctx(), HOLD), "B held on foot runs")
T.check(not Run.running(ctx({ input = input(false) }), HOLD),
  "B released walks")
T.check(not Run.running(ctx({ surfing = true }), HOLD),
  "surfing has no legs to hurry")
T.check(not Run.running(ctx(), { speed = 1, trigger = "hold" }),
  "OFF never runs")
T.check(Run.running(ctx({ input = input(false) }),
  { speed = 2, trigger = "always" }), "ALWAYS runs with no button")
-- spelled out rather than overridden: a nil in the override table is no
-- key at all, so this case can only be written as its own ctx
T.check(not Run.running({ onBike = false, surfing = false }, HOLD),
  "no input source walks rather than erroring")

-- ------- the gate, on the bicycle

local BIKE = ctx({ onBike = true })
T.check(not Run.running(BIKE, HOLD),
  "the bicycle is left alone by the walking speed")
T.eq(Run.multiplier(BIKE, HOLD), 1, "and its multiplier is vanilla")

local MATCH = { speed = 2, trigger = "hold", bike = "match" }
T.eq(Run.multiplier(BIKE, MATCH), 2,
  "MATCH RUN hands the bicycle the walking multiplier")
T.eq(Run.multiplier(ctx(), MATCH), 2, "and the feet keep their own")
T.check(Run.running(BIKE, MATCH), "so B hurries the bicycle too")
T.check(not Run.running(ctx({ onBike = true, input = input(false) }), MATCH),
  "and releasing it returns the bicycle to vanilla -- the 2:1 lead holds "
  .. "either way")

local BIKE15 = { speed = 2, trigger = "hold", bike = 1.5 }
T.eq(Run.multiplier(BIKE, BIKE15), 1.5, "a number sets the bicycle alone")
T.eq(Run.multiplier(ctx(), BIKE15), 2, "without touching the feet")
T.check(not Run.running(ctx({ onBike = true, surfing = true }), MATCH),
  "surfing outranks the bicycle -- the sea bike is never hurried")

-- ------- step length

T.eq(Run.frames(16, ctx(), HOLD), 8, "2X halves a walking step")
T.eq(Run.frames(16, ctx(), { speed = 1.5, trigger = "hold" }), 10,
  "1.5X floors to whole frames")
T.eq(Run.frames(16, ctx({ input = input(false) }), HOLD), 16,
  "a walking step is untouched")
T.eq(Run.frames(8, ctx(), { speed = 16, trigger = "hold" }), 1,
  "a step never shrinks below one frame")
T.eq(Run.frames(8, BIKE, HOLD), 8, "the vanilla bicycle keeps its 8 frames")
T.eq(Run.frames(8, BIKE, MATCH), 4, "MATCH RUN halves them")

-- ------- leg cadence

-- the invariant the animation rests on: a step pays its *unhurried*
-- length in ticks, so the clock advances at exactly the multiplier and
-- the legs speed up by as much as the feet do
for _, len in ipairs({ 16, 10, 8, 5, 1 }) do
  local total = 0
  for p = 1, len do total = total + Run.animTicks(p, len, 16) end
  T.eq(total, Run.CYCLE,
    "a " .. len .. "-frame walk pays one full cycle")
end
for _, len in ipairs({ 8, 5, 4, 1 }) do
  local total = 0
  for p = 1, len do total = total + Run.animTicks(p, len, 8) end
  T.eq(total, 8,
    "a " .. len .. "-frame bicycle step pays vanilla's half cycle")
end
T.eq(Run.animTicks(1, 16, 16), 1, "a walking frame owes the vanilla one tick")
T.eq(Run.animTicks(1, 8, 16), 2, "a 2X frame owes two -- twice the cadence")
T.eq(Run.animTicks(1, 8, 8), 1, "a vanilla bicycle frame still owes one")
T.eq(Run.animTicks(1, 4, 8), 2, "and a hurried one owes two")

-- ------- the hook, in the chain

local function speed(frames, over)
  return Runtime.call("movement.speed", function(f) return f end,
    frames, ctx(over))
end
T.eq(speed(16), 8, "movement.speed halves the step while B is held")
T.eq(speed(16, { input = input(false) }), 16, "and leaves a walk alone")
T.eq(speed(8, { onBike = true }), 8, "and leaves the default bicycle alone")

-- ------- end to end: real steps, measured

local Player = require("src.world.Player")
local Collision = require("src.world.Collision")
local Game = require("src.core.Game")

-- the only stub: an always-open map, so tryMove reaches the speed hook
local vanillaCanMove = Collision.canMove
Collision.canMove = function() return true end

-- Take one tile; returns the frames it took, the ticks the animation
-- clock gained, and every walk phase seen along the way.
local function step(holdB, onBike)
  Game.input = input(holdB)
  Game.save = { onBike = onBike or false }
  local p = Player.new(Data, 5, 5, "down")
  T.eq(p:tryMove("down", {}, nil), "moved", "the step starts")
  local clock0, frames, phases = p.animClock or 0, 0, {}
  repeat
    frames = frames + 1
    local landed = p:update()
    phases[p:walkPhase()] = true
  until landed or frames > 64
  return frames, (p.animClock or 0) - clock0, phases
end

local walkFrames, walkTicks, walkPhases = step(false)
T.eq(walkFrames, 16, "a walk is the vanilla 16 frames per tile")
T.eq(walkTicks, 16, "and one full leg cycle")

local runFrames, runTicks, runPhases = step(true)
T.eq(runFrames, 8, "a run covers the tile in half the frames")
T.eq(runTicks, 16, "and still one full leg cycle -- twice the cadence")
T.check(runPhases[0] and runPhases[1],
  "the run shows both leg poses, like a walk does")
T.check(walkPhases[0] and walkPhases[1], "as does the walk it is measured against")

-- the bicycle: vanilla by default, even with B down
local bikeFrames, bikeTicks = step(true, true)
T.eq(bikeFrames, 8, "the default bicycle is the vanilla 8 frames per tile")
T.eq(bikeTicks, 8, "and vanilla's half cycle across it")

-- ... and hurried once the option asks, at the same look per tile
run.loader.modOptions["jj_running_shoes"] = { bike = 2 }
local fastFrames, fastTicks = step(true, true)
T.eq(fastFrames, 4, "BIKE SPEED 2X halves the bicycle's step")
T.eq(fastTicks, 8, "with vanilla's half cycle per tile, pedalled twice as fast")
run.loader.modOptions["jj_running_shoes"] = nil

Collision.canMove = vanillaCanMove
Game.input, Game.save = nil, nil

run.release()
T.finish("jj_running_shoes")
