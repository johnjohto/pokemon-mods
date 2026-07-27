-- Standalone: luajit mods/jj_auto_field_moves/tests/jj_auto_field_moves_test.lua
-- Drives the collision wrapper and the map.entered listener with a stub
-- overworld: every activation must reach the engine's own use*/try* pair.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local run = T.sdk.loadMod("mods/jj_auto_field_moves", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local TextBox = require("src.render.TextBox")

local function newWorld(over)
  local stack = { states = {} }
  function stack:push(s) self.states[#self.states + 1] = s end
  function stack:pop() return table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  local game = {
    data = Data,
    stack = stack,
    save = { inventory = {}, party = {}, flags = {} },
  }
  local o = {
    player = { surfing = false },
    strengthActive = false,
    dark = false,
    map = { id = "ROUTE_1" },
    surfCalls = {},
    cutCalls = {},
    useSurfFieldMove = function(s) return s.surfGate or "ok" end,
    trySurf = function(s, x, y) s.surfCalls[#s.surfCalls + 1] = { x, y } end,
    useCutFieldMove = function(s) return s.cutGate or "ok" end,
    tryCut = function(s, x, y)
      s.cutCalls[#s.cutCalls + 1] = { x, y }
      return true
    end,
    partyKnows = function(s) return s.knower end,
    npcAtCell = function(s) return s.npc end,
  }
  game.overworld = o
  for k, v in pairs(over or {}) do o[k] = v end
  Runtime.emit("game.ready", { game = game })
  return game, o
end

local function blockedStep(ctx)
  return Runtime.call("movement.collision",
    function(a) return a end, false, ctx)
end

local function waterMap(wet)
  return { isWaterCell = function() return wet end }
end

-- water contact surfs
local game, o = newWorld()
local ctx = { mover = o.player, reason = "tile", map = waterMap(true),
              toX = 7, toY = 9 }
T.eq(blockedStep(ctx), false, "the step itself stays blocked")
T.eq(#o.surfCalls, 1, "water contact starts surfing")
T.eq(o.surfCalls[1][1], 7, "surf targets the blocked cell")

-- already surfing: no remount
game, o = newWorld({ player = { surfing = true } })
ctx = { mover = o.player, reason = "tile", map = waterMap(true),
        toX = 7, toY = 9 }
blockedStep(ctx)
T.eq(#o.surfCalls, 0, "already surfing does not remount")

-- the engine's own gate refusing means no trigger
game, o = newWorld({ surfGate = "forced_bike" })
ctx = { mover = o.player, reason = "tile", map = waterMap(true),
        toX = 7, toY = 9 }
blockedStep(ctx)
T.eq(#o.surfCalls, 0, "the Cycling Road refusal is respected")

-- NPC pathing never triggers
game, o = newWorld()
ctx = { mover = { npc = true }, reason = "tile", map = waterMap(true),
        toX = 7, toY = 9 }
blockedStep(ctx)
T.eq(#o.surfCalls, 0, "NPC steps are ignored")

-- cuttable contact cuts
game, o = newWorld()
ctx = { mover = o.player, reason = "tile", map = waterMap(false),
        toX = 3, toY = 4 }
blockedStep(ctx)
T.eq(#o.cutCalls, 1, "tree contact cuts")
T.eq(o.cutCalls[1][2], 4, "cut targets the blocked cell")

game, o = newWorld({ cutGate = "nothing" })
ctx = { mover = o.player, reason = "tile", map = waterMap(false),
        toX = 3, toY = 4 }
blockedStep(ctx)
T.eq(#o.cutCalls, 0, "nothing to cut stays a plain bump")

-- boulder contact activates STRENGTH once
game, o = newWorld({
  npc = { def = { sprite = "SPRITE_BOULDER" } },
  knower = { species = "ABRA" },
})
ctx = { mover = o.player, reason = "entity", map = waterMap(false),
        toX = 5, toY = 6 }
blockedStep(ctx)
T.check(o.strengthActive, "boulder contact activates STRENGTH")
T.check(getmetatable(game.stack:top()) == TextBox,
  "the used-STRENGTH text shows")
local boxes = #game.stack.states
blockedStep(ctx)
T.eq(#game.stack.states, boxes, "an active STRENGTH is not re-announced")

-- no STRENGTH mon, no activation
game, o = newWorld({ npc = { def = { sprite = "SPRITE_BOULDER" } } })
ctx = { mover = o.player, reason = "entity", map = waterMap(false),
        toX = 5, toY = 6 }
blockedStep(ctx)
T.check(not o.strengthActive, "no STRENGTH mon, no activation")

-- entering a dark cave FLASHes
game, o = newWorld({ dark = true, knower = { species = "ABRA" } })
Runtime.emit("map.entered", { mapId = "ROCK_TUNNEL_1F" })
T.check(not o.dark, "entering the dark cave lights it")
T.check(game.save.flashLit, "the lit state persists on the save")
T.check(getmetatable(game.stack:top()) == TextBox,
  "the FLASH text shows")

game, o = newWorld({ dark = false, knower = { species = "ABRA" } })
Runtime.emit("map.entered", { mapId = "PALLET_TOWN" })
T.eq(game.save.flashLit, nil, "a lit map does not re-flash")

game, o = newWorld({ dark = true })
Runtime.emit("map.entered", { mapId = "ROCK_TUNNEL_1F" })
T.check(o.dark, "no FLASH mon, the cave stays dark")

run.release()
T.finish("jj_auto_field_moves")
