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

-- ------- the gate

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
T.check(not Run.running(ctx({ onBike = true }), HOLD),
  "the bicycle is already the fast option")
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

-- ------- step length

T.eq(Run.frames(16, ctx(), HOLD), 8, "2X halves a walking step")
T.eq(Run.frames(16, ctx(), { speed = 1.5, trigger = "hold" }), 10,
  "1.5X floors to whole frames")
T.eq(Run.frames(16, ctx({ input = input(false) }), HOLD), 16,
  "a walking step is untouched")
T.eq(Run.frames(8, ctx(), { speed = 16, trigger = "hold" }), 1,
  "a step never shrinks below one frame")

-- ------- leg cadence

-- the invariant the whole animation rests on: whatever the step length,
-- one tile is exactly one full cycle, so the clock lands on a boundary
-- every tile and the mirror flip keeps alternating per tile
for _, len in ipairs({ 16, 10, 8, 5, 1 }) do
  local total = 0
  for p = 1, len do total = total + Run.animTicks(p, len) end
  T.eq(total, Run.CYCLE,
    "a " .. len .. "-frame step pays one full cycle")
end
T.eq(Run.animTicks(1, 16), 1, "a walking frame owes the vanilla one tick")
T.eq(Run.animTicks(1, 8), 2, "a 2X frame owes two -- twice the cadence")

-- ------- the hook, in the chain

local function speed(frames, over)
  return Runtime.call("movement.speed", function(f) return f end,
    frames, ctx(over))
end
T.eq(speed(16), 8, "movement.speed halves the step while B is held")
T.eq(speed(16, { input = input(false) }), 16, "and leaves a walk alone")
T.eq(speed(8, { onBike = true }), 8, "and leaves the bicycle alone")

-- ------- end to end: a real step, measured

local Player = require("src.world.Player")
local Collision = require("src.world.Collision")
local Game = require("src.core.Game")

-- the only stub: an always-open map, so tryMove reaches the speed hook
local vanillaCanMove = Collision.canMove
Collision.canMove = function() return true end
Game.save = { onBike = false }

-- Walk or run one tile; returns the frames it took and the ticks the
-- animation clock gained, plus every walk phase seen along the way.
local function step(holdB)
  Game.input = input(holdB)
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

Collision.canMove = vanillaCanMove
Game.input, Game.save = nil, nil

run.release()
T.finish("jj_running_shoes")
