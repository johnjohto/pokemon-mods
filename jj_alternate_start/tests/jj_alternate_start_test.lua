-- Standalone: luajit mods/jj_alternate_start/tests/jj_alternate_start_test.lua
-- Covers the two inserted speech steps and the finished-event flow:
-- starter grant, tutorial flags, heal point, and the warp itself.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local SaveData = require("src.core.SaveData")
local ListMenu = require("src.ui.ListMenu")

local run = T.sdk.loadMod("mods/jj_alternate_start", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

-- ------- the build hook inserts both steps before shrink

local vanillaSteps = {
  { id = "oak_welcome", kind = "say" },
  { id = "shrink", kind = "shrink" },
}
local steps = Runtime.call("intro.oak_speech.build",
  function(s) return s end, vanillaSteps, {})
T.eq(#steps, 4, "the hook adds two steps")
T.eq(steps[2].id, "jj_starter", "the starter choice comes first")
T.eq(steps[3].id, "jj_start_town", "the town picker comes second")
T.eq(steps[4].id, "shrink", "both land before the finale")
T.eq(steps[2].kind, "choice", "the starter step is a plain choice")
T.eq(steps[2].saveKey, "jj_starter", "the starter answer has a save key")
T.eq(#steps[2].choices, 3, "three starters on offer")
T.eq(steps[3].kind, "fn", "the town step drives its own scrolling list")

-- ------- the town step pushes a scrolling list and records the answer

local function newGameDouble()
  local stack = { states = {} }
  function stack:push(s) self.states[#self.states + 1] = s end
  function stack:pop() return table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  local game = {
    data = Data,
    stack = stack,
    save = SaveData.newGame(),
  }
  game.overworld = {
    startWarpTo = function(_, map, x, y, facing)
      game.warpedTo = { map = map, x = x, y = y, facing = facing }
    end,
  }
  return game
end

local game = newGameDouble()
local speech = {
  game = game,
  answers = {},
  recordAnswer = function(self, step, index, label, value)
    self.answers[step.saveKey] = value
  end,
}
local townStep = steps[3]
local advanced = false
townStep.run(speech, function() advanced = true end)
local list = game.stack:top()
T.check(list and getmetatable(list) == ListMenu, "the town step opens a list")
T.eq(#list.items, 11, "eleven destinations including the classic start")
T.eq(list.items[1].value, "PALLET_TOWN", "the classic start leads the list")
list.onChoose(list.items[2], list) -- VIRIDIAN CITY
T.eq(game.stack:top(), nil, "choosing closes the list")
T.eq(speech.answers.jj_start_town, "VIRIDIAN_CITY", "the answer is recorded")
T.check(advanced, "choosing advances the speech")

-- B on the town list answers classic instead of stranding the speech
game = newGameDouble()
speech = {
  game = game,
  answers = {},
  recordAnswer = function(self, step, index, label, value)
    self.answers[step.saveKey] = value
  end,
}
advanced = false
townStep.run(speech, function() advanced = true end)
list = game.stack:top()
game.stack:pop() -- ListMenu pops itself on B
list.onCancel()
T.eq(speech.answers.jj_start_town, "PALLET_TOWN", "B answers the classic start")
T.check(advanced, "B still advances the speech")

-- ------- finished: starter, flags, heal point; the warp waits for the pop

local speechState = { game = game }
Runtime.emit("intro.oak_speech.finished", {
  speech = speechState,
  answers = { jj_start_town = "PEWTER_CITY", jj_starter = "CHARMANDER" },
})
local save = game.save
T.eq(#save.party, 1, "the starter joins the party")
T.eq(save.party[1].species, "CHARMANDER", "the chosen species arrives")
T.eq(save.party[1].level, 5, "the starter is level 5")
T.check(save.pokedex.owned.CHARMANDER and save.pokedex.seen.CHARMANDER,
  "the starter lands in the pokédex")
T.check(save.flags.EVENT_GOT_STARTER, "starter flag set")
T.check(save.flags.EVENT_CHOSE_CHARMANDER, "rival team flag set")
T.check(save.flags.EVENT_GOT_POKEDEX, "pokédex flag set")
T.check(save.flags.EVENT_GOT_OAKS_PARCEL and save.flags.EVENT_OAK_GOT_PARCEL,
  "the parcel quest reads as done")
T.eq(save.objectToggles.VIRIDIAN_CITY.VIRIDIANCITY_OLD_MAN, true,
  "the Viridian old man is on his feet")
local fw = Data.field.flyWarps.PEWTER_CITY
T.eq(save.lastHeal.map, "PEWTER_CITY", "blackouts return to the new town")
T.eq(save.lastHeal.x, fw.x, "the heal point is the fly landing")
T.eq(save.lastOutdoor.id, "PEWTER_CITY", "the outdoor palette follows")
T.eq(game.warpedTo, nil, "no warp while the speech is still on the stack")

-- a re-fired finished (the engine's shrink timeline can repeat it when a
-- listener leaves the speech on the stack) is not a second grant
Runtime.emit("intro.oak_speech.finished", {
  speech = speechState,
  answers = { jj_start_town = "PEWTER_CITY", jj_starter = "CHARMANDER" },
})
T.eq(#save.party, 1, "a repeated finished grants nothing twice")

-- only the speech's own pop triggers the warp, and only once
Runtime.emit("screen.popped", { state = { someOtherScreen = true } })
T.eq(game.warpedTo, nil, "an unrelated pop does not warp")
Runtime.emit("screen.popped", { state = speechState })
T.check(game.warpedTo and game.warpedTo.map == "PEWTER_CITY"
  and game.warpedTo.x == fw.x and game.warpedTo.y == fw.y
  and game.warpedTo.facing == "down",
  "popping the speech warps to the town's Pokémon Center")
local warp = game.warpedTo
Runtime.emit("screen.popped", { state = speechState })
T.eq(game.warpedTo, warp, "the warp fires once")

-- ------- the classic start is a complete no-op

game = newGameDouble()
Runtime.emit("intro.oak_speech.finished", {
  speech = { game = game },
  answers = { jj_start_town = "PALLET_TOWN", jj_starter = "CHARMANDER" },
})
T.eq(#game.save.party, 0, "classic start grants nothing")
T.eq(game.warpedTo, nil, "classic start warps nowhere")
T.eq(next(game.save.flags), nil, "classic start sets no flags")

-- no answers at all (steps removed by another mod) is also a no-op
game = newGameDouble()
Runtime.emit("intro.oak_speech.finished", {
  speech = { game = game }, answers = {},
})
T.eq(#game.save.party, 0, "no answers, no starter")
T.eq(game.warpedTo, nil, "no answers, no warp")

run.release()
T.finish("jj_alternate_start")
