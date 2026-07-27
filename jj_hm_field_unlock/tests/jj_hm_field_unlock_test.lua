-- Standalone: luajit mods/jj_hm_field_unlock/tests/jj_hm_field_unlock_test.lua
-- Covers the unlock rule (badge + HM owned + a learner in the party), the
-- partyKnows widening that every field-move path uses, and the party
-- submenu injection.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local run = T.sdk.loadMod("mods/jj_hm_field_unlock", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local exports = run.loader.exports.jj_hm_field_unlock
T.check(type(exports.canUse) == "function", "canUse is exported for interop")

-- SQUIRTLE learns SURF, CHARMANDER does not; CHARMANDER learns CUT,
-- PIDGEY does not; PIDGEY learns FLY (facts pinned from the shipped data)
local function gameWith(over)
  local save = {
    party = { { species = "SQUIRTLE", moves = {} } },
    inventory = { SOULBADGE = 1, CASCADEBADGE = 1, THUNDERBADGE = 1 },
    pcItems = {},
    flags = {},
  }
  local game = { data = Data, save = save }
  for k, v in pairs(over or {}) do game.save[k] = v end
  return game
end

-- the rule itself
local game = gameWith()
game.save.inventory.HM_SURF = 1
T.check(exports.canUse(game, "SURF"), "badge + HM + learner unlocks SURF")
game.save.inventory.HM_SURF = nil
T.check(not exports.canUse(game, "SURF"), "no HM, no unlock")
game.save.pcItems.HM_SURF = 1
T.check(exports.canUse(game, "SURF"), "an HM in the PC box counts too")
game.save.inventory.SOULBADGE = nil
T.check(not exports.canUse(game, "SURF"), "the badge is still required")
game = gameWith({ inventory = { SOULBADGE = 1, HM_SURF = 1 },
                  party = { { species = "CHARMANDER", moves = {} } } })
T.check(not exports.canUse(game, "SURF"),
  "a party that cannot learn it stays locked")
T.check(not exports.canUse(gameWith(), "TELEPORT"),
  "non-HM moves keep vanilla rules")

-- the partyKnows widening, through the real engine module.  The vanilla
-- function reads OverworldController's Game upvalue (nil until enter in a
-- live game); the mod captured that closure, so wire it through debug the
-- same way mod_scripting_tests does.
local Game = require("src.core.Game")
local Overworld = require("src.world.OverworldController")
local vanillaPK
for i = 1, 10 do
  local name, value = debug.getupvalue(Overworld.partyKnows, i)
  if name == nil then break end
  if name == "vanillaPartyKnows" then vanillaPK = value break end
end
T.check(vanillaPK ~= nil, "the wrapper captured the vanilla partyKnows")
for i = 1, 20 do
  local name = debug.getupvalue(vanillaPK, i)
  if name == nil then break end
  if name == "Game" then debug.setupvalue(vanillaPK, i, Game) break end
end
game = gameWith()
game.save.inventory.HM_SURF = 1
Runtime.emit("game.ready", { game = game })
Game.save, Game.data = game.save, game.data
local mon = Overworld.partyKnows({}, "SURF")
T.check(mon == game.save.party[1],
  "partyKnows returns the learner when nobody knows the move")
game.save.party[1].moves = { { id = "SURF" } }
T.check(Overworld.partyKnows({}, "SURF") == game.save.party[1],
  "a mon that knows it still passes the vanilla path")
game.save.party[1].moves = {}
game.save.inventory.SOULBADGE = nil
T.eq(Overworld.partyKnows({}, "SURF"), nil,
  "vanilla and the rule both fail without the badge")

-- the party submenu shows unlocked moves with vanilla action ids
game = gameWith()
game.save.inventory.HM_SURF = 1
game.save.inventory.HM_CUT = 1
Runtime.emit("game.ready", { game = game })
local ow = { map = { def = Data.maps.PEWTER_CITY }, dark = false }
local mon2 = { species = "CHARMANDER", moves = {} }
game.save.party = { mon2, { species = "SQUIRTLE", moves = {} } }
local items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, mon2,
  { overworld = ow })
local function hasAction(list, action)
  for _, it in ipairs(list) do if it.action == action then return true end end
  return false
end
T.check(hasAction(items, "cut"), "CUT appears on a learner with HM + badge")
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, game.save.party[2],
  { overworld = ow })
T.check(hasAction(items, "surf"), "SURF appears on the Squirtle")
T.check(not hasAction(items, "fly"), "no FLY without its HM")
game.save.inventory.HM_FLY = 1
game.save.party = { { species = "PIDGEY", moves = {} } }
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, game.save.party[1],
  { overworld = ow })
T.check(hasAction(items, "fly"), "FLY appears outdoors with HM + badge")
ow.dark = false
game.save.party = { { species = "ABRA", moves = {} } }
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, game.save.party[1],
  { overworld = ow })
T.check(not hasAction(items, "flash"), "FLASH stays hidden outside dark maps")
ow.dark = true
game.save.inventory.HM_FLASH = 1
game.save.inventory.BOULDERBADGE = 1
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, game.save.party[1],
  { overworld = ow })
T.check(hasAction(items, "flash"), "FLASH appears in the dark with HM + badge")
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {}, { species = "PIDGEY", moves = {} },
  { battle = {}, overworld = ow })
T.check(not hasAction(items, "fly"), "battle keeps the vanilla submenu")
items = Runtime.call("ui.party.submenu",
  function(_, it) return it end, game, {},
  { species = "PIDGEY", moves = { { id = "FLY" } } }, { overworld = ow })
local flyCount = 0
for _, it in ipairs(items) do if it.action == "fly" then flyCount = flyCount + 1 end end
T.eq(flyCount, 0, "a mon that knows the move is not duplicated by the mod")

run.release()
T.finish("jj_hm_field_unlock")
