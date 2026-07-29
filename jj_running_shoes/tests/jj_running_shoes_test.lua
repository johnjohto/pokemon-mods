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
T.eq(#schema[2].choices, 3, "three triggers offered")
T.eq(schema[2].choices[2][2], "toggle", "with TOGGLE between hold and always")
T.eq(schema[3].key, "bike", "the third row is the bicycle")
T.eq(schema[3].default, 1, "the bicycle is vanilla until asked otherwise")
T.eq(schema[4].key, "surf", "the fourth row is surfing")
T.eq(schema[4].default, 1, "and it is vanilla until asked too")

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

-- TOGGLE reads the latch, never the button: the press that flips it is
-- an edge, and an edge is gone by the time the next step asks
local TOGGLE = { speed = 2, trigger = "toggle" }
T.check(not Run.running(ctx(), TOGGLE),
  "TOGGLE walks while the latch is off, even with B held")
TOGGLE.toggled = true
T.check(Run.running(ctx({ input = input(false) }), TOGGLE),
  "and runs while it is on, with B released")
T.check(not Run.running(ctx({ onBike = true }), TOGGLE),
  "the latch still respects a vanilla BIKE SPEED")
T.check(Run.running(ctx({ onBike = true }),
  { speed = 2, trigger = "toggle", toggled = true, bike = 2 }),
  "and hurries the bicycle once that row asks")

-- the edge reader is guarded like isDown is
T.check(Run.togglePressed({ wasPressed = function(_, b) return b == "b" end }),
  "togglePressed sees B's rising edge")
T.check(not Run.togglePressed({ wasPressed = function() return false end }),
  "and stays quiet otherwise")
T.check(not Run.togglePressed(nil), "no input source never toggles")
T.check(not Run.togglePressed({}), "nor one without wasPressed")
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
  "surfing is read before the bicycle, and is vanilla by default")

-- ------- the gate, surfing

local SURFING = ctx({ surfing = true })
T.check(not Run.running(SURFING, HOLD), "surfing is left alone by default")
T.eq(Run.multiplier(SURFING, HOLD), 1, "and its multiplier is vanilla")

local SURF2 = { speed = 2, trigger = "hold", surf = 2 }
T.eq(Run.multiplier(SURFING, SURF2), 2, "SURF SPEED hurries the water")
T.check(Run.running(SURFING, SURF2), "so B speeds up a crossing")
T.eq(Run.frames(16, SURFING, SURF2), 8, "halving the step, as on foot")

-- surfing answers to the RUN BUTTON row exactly like the feet do: B is
-- what turns it on, and releasing gives the vanilla crossing straight back
local SURF_RELEASED = ctx({ surfing = true, input = input(false) })
T.check(not Run.running(SURF_RELEASED, SURF2), "B released surfs at vanilla")
T.eq(Run.frames(16, SURF_RELEASED, SURF2), 16, "at the vanilla 16 frames")
T.check(Run.running(SURF_RELEASED, { speed = 2, trigger = "always", surf = 2 }),
  "and ALWAYS hurries the water with no button, like it does the feet")
T.eq(Run.multiplier(ctx({ onBike = true }), SURF2), 1,
  "and it never leaks onto the bicycle")

local SURFMATCH = { speed = 1.5, trigger = "hold", surf = "match" }
T.eq(Run.multiplier(SURFING, SURFMATCH), 1.5,
  "MATCH RUN pins surfing to the walking multiplier")

-- surfing wins over the bicycle when both are somehow set: the player is
-- on the water sprite, so the water's setting is the one that applies
T.eq(Run.multiplier(ctx({ surfing = true, onBike = true }),
  { speed = 2, trigger = "hold", bike = 2, surf = 1 }), 1,
  "a surfing step reads SURF SPEED, not BIKE SPEED")

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
local function step(holdB, onBike, surfing)
  Game.input = input(holdB)
  Game.save = { onBike = onBike or false }
  local p = Player.new(Data, 5, 5, "down")
  p.surfing = surfing or false
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

-- TOGGLE, through the real patch: a tap while standing still flips the
-- latch, and the next step runs with B released.  Player:update is where
-- the flip lives precisely so a tap that starts no step still counts.
run.loader.modOptions["jj_running_shoes"] = { trigger = "toggle" }
local function tapB(times)
  local fired = 0
  Game.input = {
    isDown = function() return false end,
    wasPressed = function(_, b)
      if b ~= "b" or fired >= times then return false end
      fired = fired + 1
      return true
    end,
  }
  local idle = Player.new(Data, 5, 5, "down")
  Game.save = { onBike = false }
  for _ = 1, times do idle:update() end   -- standing still: no step at all
end

tapB(1)
T.eq(step(false, false), 8, "one tap latches running, with B released")
tapB(1)
T.eq(step(false, false), 16, "a second tap latches it back off")
run.loader.modOptions["jj_running_shoes"] = nil

-- surfing, driven through the real chain: the same B that runs on land
-- is what hurries the water, and letting go hands the crossing straight
-- back to vanilla
run.loader.modOptions["jj_running_shoes"] = { surf = 2 }
local surfHeld = step(true, false, true)
T.eq(surfHeld, 8, "B held surfs at 2X once SURF SPEED asks for it")
local surfFree = step(false, false, true)
T.eq(surfFree, 16, "and releasing it is the vanilla crossing again")
run.loader.modOptions["jj_running_shoes"] = nil
local surfDefault = step(true, false, true)
T.eq(surfDefault, 16, "with the row at VANILLA, B does nothing on water")

-- ------- a scripted step is never hurried
--
-- OverworldState:scriptMove walks the player by setting moving/progress
-- straight on the entity, so Player:tryMove -- and with it movement.speed
-- -- is skipped entirely and the step runs at whatever stepFramesCur the
-- last free-roam step left behind.  Every NPC the player is made to follow
-- is pinned to Npc's own STEP_FRAMES, so a stale hurried value is the
-- player walking straight past Oak on the way to the lab.
local function scriptStep(p, dir)
  p.facing = dir
  p.targetX, p.targetY = Collision.target(p.cellX, p.cellY, dir)
  p.moving, p.progress = true, 0
  local frames = 0
  repeat
    frames = frames + 1
  until p:update() or frames > 64
  return frames
end

-- B stays held through the cutscene: the player has no idea a script just
-- took the wheel, and the mod cannot ask them to let go
Game.input = input(true)
Game.save = { onBike = false }
local cut = Player.new(Data, 5, 5, "down")
T.eq(cut:tryMove("down", {}, nil), "moved", "a free-roam run step starts")
local ran = 0
repeat ran = ran + 1 until cut:update() or ran > 64
T.eq(ran, 8, "and covers its tile at 2X, as it should")
T.eq(scriptStep(cut, "down"), 16,
  "the scripted step that follows it is the vanilla 16 frames")
T.eq(scriptStep(cut, "down"), 16, "and so is every scripted step after it")

-- the bicycle keeps its own vanilla, not the feet's: a scripted step on a
-- bike was always 8 frames, and staying vanilla must not mean slowing to 16
run.loader.modOptions["jj_running_shoes"] = { bike = 2 }
Game.save = { onBike = true }
local cutBike = Player.new(Data, 5, 5, "down")
T.eq(cutBike:tryMove("down", {}, nil), "moved", "a hurried bicycle step starts")
local pedalled = 0
repeat pedalled = pedalled + 1 until cutBike:update() or pedalled > 64
T.eq(pedalled, 4, "and covers its tile at 2X")
T.eq(scriptStep(cutBike, "down"), 8,
  "the scripted step after it is the bicycle's vanilla 8, not the feet's 16")
run.loader.modOptions["jj_running_shoes"] = nil

Collision.canMove = vanillaCanMove
Game.input, Game.save = nil, nil

run.release()
T.finish("jj_running_shoes")
