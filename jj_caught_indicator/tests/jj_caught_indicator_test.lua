-- Standalone: luajit mods/jj_caught_indicator/tests/jj_caught_indicator_test.lua
-- Drives the pure decision module: the icon shows only for a wild battle
-- against an owned species with the enemy HUD fully up, and it lands one
-- tile left of wherever the engine's nameX places the name.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local run = T.sdk.loadMod("mods/jj_caught_indicator", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local Indicator = require("mods.jj_caught_indicator.indicator")

local function newGame(owned)
  return { data = Data, save = { pokedex = { owned = owned } } }
end

local function wildBattle(species)
  return {
    kind = "wild",
    enemy = { name = species, mon = { species = species } },
  }
end

-- the core case: wild battle, species owned, HUD up
T.check(Indicator.shouldShow(wildBattle("PIDGEY"), newGame({ PIDGEY = true })),
  "icon shows for an owned wild species")

-- same battle but the species was never caught
T.check(not Indicator.shouldShow(wildBattle("PIDGEY"), newGame({ WEEDLE = true })),
  "no icon for a species not yet caught")
T.check(not Indicator.shouldShow(wildBattle("PIDGEY"), newGame({})),
  "no icon with an empty dex")

-- trainer and link battles have no catchable wild mon
local trainer = wildBattle("PIDGEY")
trainer.kind = "trainer"
T.check(not Indicator.shouldShow(trainer, newGame({ PIDGEY = true })),
  "no icon in trainer battles")
local link = wildBattle("PIDGEY")
link.kind = "link"
T.check(not Indicator.shouldShow(link, newGame({ PIDGEY = true })),
  "no icon in link battles")

-- a ghost is unidentified; the old man's demo is not the player's encounter
local ghost = wildBattle("PIDGEY")
ghost.ghost = true
T.check(not Indicator.shouldShow(ghost, newGame({ PIDGEY = true })),
  "no icon for a pre-Scope ghost")
local demo = wildBattle("PIDGEY")
demo.demo = true
T.check(not Indicator.shouldShow(demo, newGame({ PIDGEY = true })),
  "no icon in the old man demo")

-- the icon rides the enemy HUD, so it shares the HUD's own conditions
local sendingOut = wildBattle("PIDGEY")
sendingOut.enemySendingOut = true
T.check(not Indicator.shouldShow(sendingOut, newGame({ PIDGEY = true })),
  "no icon while the enemy is sending out")
local sliding = wildBattle("PIDGEY")
sliding.introSlide = 3
T.check(not Indicator.shouldShow(sliding, newGame({ PIDGEY = true })),
  "no icon during the intro slide")
local fainted = wildBattle("PIDGEY")
fainted.enemy.fainted = true
T.check(not Indicator.shouldShow(fainted, newGame({ PIDGEY = true })),
  "no icon over a fainted enemy")
local growing = wildBattle("PIDGEY")
growing.growIn = { battler = growing.enemy, frame = 0 }
function growing:growInScale(b)
  local g = self.growIn
  if not g or g.battler ~= b then return nil end
  local f = g.frame
  return f < 3 and 0 or f < 7 and 3 / 7 or 5 / 7
end
T.check(not Indicator.shouldShow(growing, newGame({ PIDGEY = true })),
  "no icon during the grow-in")
growing.growIn = nil
T.check(Indicator.shouldShow(growing, newGame({ PIDGEY = true })),
  "icon returns once the grow-in finishes")

-- no dex data at all (corrupted or pre-Oak save) must not error
T.check(not Indicator.shouldShow(wildBattle("PIDGEY"), { save = {} }),
  "no icon without dex data")
T.check(not Indicator.shouldShow(wildBattle("PIDGEY"), nil),
  "no icon without a game")

-- placement: fixed spot below the name, right above the HP-bar bracket
local x, y = Indicator.placement()
T.eq(x, 8, "icon sits one tile in, under the name")
T.eq(y, 8, "icon sits on the second row, above the HP bracket")

run.release()
T.finish("jj_caught_indicator")
