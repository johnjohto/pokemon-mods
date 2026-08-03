-- Standalone: luajit mods/jj_fuchsia_swamp/tests/jj_fuchsia_swamp_test.lua
-- Validate the Route 19 map, its islands and Surf channels, reciprocal
-- connection, encounters, and namespaced state.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
local MapLoader = require("src.world.MapLoader")
local Overworld = require("src.world.OverworldController")
local MapScripts = require("src.script.MapScripts")
local ScriptRunner = require("src.script.ScriptRunner")
local Pokemon = require("src.pokemon.Pokemon")
local BattleState = require("src.battle.BattleState")
local Tutor = require("mods.jj_fuchsia_swamp.tutor")
local PaletteFX = require("src.render.PaletteFX")
local TextBox = require("src.render.TextBox")
local Font = require("src.render.Font")

Data:load()
Font.load(Data)
-- The portrait/palette registry fields this mod uses shipped in v0.1.39.
-- The manifest also names the source tree's 0.0.0-dev placeholder so normal
-- development boots exercise the same loader path as the release build.
local run = T.sdk.loadMod("mods/jj_fuchsia_swamp", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
T.eq(run.mod.manifest.game_version, ">=0.1.39 <2.0.0 || =0.0.0-dev",
  "the mod accepts the source placeholder but refuses unsupported releases")

local MAP = "JJ_SHREK_SWAMP"
local HUT = "JJ_SHREK_HUT"
T.check(Data.maps[MAP] ~= nil, "custom swamp reaches map data")
T.check(Data.maps[HUT] ~= nil, "Shrek's hut reaches map data")
T.eq(Data.maps[HUT].warps[1].destMap, "LAST_MAP", "the hut door returns safely")
T.eq(Data.maps[MAP].warps[1].destMap, HUT, "the swamp exposes the hut return point")
T.eq(Data.maps[MAP].warps[1].y, 50,
  "leaving the hut returns the player in front of Shrek")
T.check(Data.maps[HUT].blocks[4] ~= 7,
  "the hut contains no unused upstairs stair block")
local shrekSprite = Data.sprites.SPRITE_JJ_SHREK
T.check(shrekSprite ~= nil, "Shrek walking sprite reaches sprite data")
T.eq(shrekSprite.image, "mods/jj_fuchsia_swamp/assets/shrek-overworld.png",
  "the supplied walking sheet is registered")
T.eq(shrekSprite.frames, 6, "the walking sheet uses native six-frame animation")
T.check(shrekSprite.walker, "the walking sheet is flagged as a walker")
T.eq(shrekSprite.paletteSource, "ROM:SpriteSheetPointerTable[21]",
  "the custom walker declares an advanced-palette assignment")
local oldPaletteMode = PaletteFX.mode
PaletteFX.mode = "redpp"
local shrekColors, shrekGroup = PaletteFX.spriteObp(shrekSprite, "JJ_SHREK")
PaletteFX.mode = oldPaletteMode
T.check(shrekColors ~= nil and shrekGroup == 2,
  "the custom walker resolves the green Advanced OBJ palette")
local shrek = Data.trainers.OPP_JJ_SHREK
T.check(shrek ~= nil, "OGRE SHREK trainer reaches trainer data")
T.eq(shrek.name, "OGRE SHREK", "the battle introduction uses Shrek's trainer title")
T.eq(shrek.pic, "mods/jj_fuchsia_swamp/assets/shrek-source.png",
  "the supplied portrait is wired into the trainer")
T.eq(shrek.paletteSource, shrekSprite.paletteSource,
  "the trainer portrait uses the same palette source as the overworld walker")
PaletteFX.mode = "redpp"
local trainerPalette = BattleState.trainerPalette(Data, shrek)
PaletteFX.mode = oldPaletteMode
T.eq(trainerPalette.colors[3][1], shrekColors[3][1],
  "the trainer portrait's green shade matches the overworld walker")
T.eq(trainerPalette.colors[3][2], shrekColors[3][2],
  "the trainer portrait's green shade matches the overworld walker")
T.eq(trainerPalette.colors[3][3], shrekColors[3][3],
  "the trainer portrait's green shade matches the overworld walker")
local party = Runtime.call("trainer.party", function(_, _, base) return base end,
  "OPP_JJ_SHREK", 1, shrek.parties[1])
T.eq(party[1].moves[1], "SLUDGE", "Muk has its agreed moveset")
T.eq(party[2].moves[1], "ROCK_SLIDE", "Golem has its agreed moveset")
T.eq(party[3].moves[3], "REST", "Slowbro has its agreed moveset")
T.eq(party[4].moves[4], "HYPER_BEAM", "Snorlax has its agreed moveset")

local player = Pokemon.new(Data, "BULBASAUR", 45)
local battle = BattleState.newTrainer({
  data = Data,
  save = {
    party = { player }, player = { name = "RED" }, inventory = {}, flags = {},
    defeatedTrainers = {},
  },
}, "OPP_JJ_SHREK", 1)
T.eq(battle.trainer.name, "OGRE SHREK", "the battle builds Shrek's trainer intro")
T.eq(#battle.enemyParty, 4, "the battle builds all four of Shrek's Pokemon")
T.eq(battle.enemyParty[1].moves[1].id, "SLUDGE", "Muk keeps its custom battle move")
T.eq(battle.enemyParty[4].moves[4].id, "HYPER_BEAM", "Snorlax keeps its custom battle move")
T.eq(Data.maps.ROUTE_19.connections.east.map, MAP,
  "Route 19 connects to the custom swamp")
T.eq(Data.maps[MAP].connections.west.map, "ROUTE_19",
  "the swamp has a return connection to Route 19")

MapLoader.invalidate(MAP)
local swamp = MapLoader.load(Data, MAP)
T.eq(Data.maps[MAP].tileset, "OVERWORLD",
  "the swamp stays on OVERWORLD so its native tile palettes apply")
T.check(PaletteFX.hasWorldTileset(Data.maps[MAP].tileset),
  "the swamp tileset resolves the base game's palette mapping")
T.eq(#Data.tilesets.OVERWORLD.blocks, 128,
  "the swamp does not alter the shared OVERWORLD blockset")
T.check(swamp:isWaterCell(0, 0), "the Route 19 edge enters surfable water")
T.check(swamp:isWalkableCell(6, 7), "the dredger's island is walkable")
T.check(swamp:isGrassCell(6, 7), "the reclamation islands supply encounters")
T.check(swamp:isWaterCell(0, 17), "water channels separate the reclamation sites")
local function blockAt(def, x, y) return def.blocks[y * def.width + x + 1] end
for _, island in ipairs({
  { left = 2, top = 1, right = 5, bottom = 5 },
  { left = 5, top = 10, right = 9, bottom = 14 },
  { left = 1, top = 18, right = 5, bottom = 22 },
  { left = 3, top = 23, right = 7, bottom = 26 },
}) do
  T.eq(blockAt(Data.maps[MAP], island.left, island.bottom), 11,
    "each clearing keeps a clean grass edge along its bottom")
  T.eq(blockAt(Data.maps[MAP], island.right, island.top), 11,
    "each clearing keeps a clean grass edge along its right side")
end
local route19 = MapLoader.load(Data, "ROUTE_19")
local function waterEdgeReachable(map)
  local queue, seen = {}, {}
  local function key(x, y) return y * map.widthCells + x end
  local function add(x, y)
    local k = key(x, y)
    if not seen[k] then
      seen[k] = true
      queue[#queue + 1] = { x = x, y = y }
    end
  end
  for y = 0, map.heightCells - 1 do
    for x = 0, map.widthCells - 1 do
      if map:isWalkableCell(x, y) then
        for _, delta in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = x + delta[1], y + delta[2]
          if map:inBounds(nx, ny) and map:isWaterCell(nx, ny) then add(nx, ny) end
        end
      end
    end
  end
  local index = 1
  while queue[index] do
    local cell = queue[index]
    index = index + 1
    if cell.x == map.widthCells - 1 then return true end
    for _, delta in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local nx, ny = cell.x + delta[1], cell.y + delta[2]
      if map:inBounds(nx, ny) and map:isWaterCell(nx, ny) then add(nx, ny) end
    end
  end
  return false
end
T.check(waterEdgeReachable(route19),
  "a player can Surf from Route 19's shoreline to the swamp seam")
T.eq(#Data.maps[MAP].objects, 4, "the swamp contains three sites and Shrek")
local shrekObject = Data.maps[MAP].objects[4]
T.eq(shrekObject.sprite, "SPRITE_JJ_SHREK", "Shrek appears with the custom walker")
T.eq(shrekObject.text, "TEXT_JJ_SHREK_BATTLE", "Shrek owns the gated battle script")
T.eq(shrekObject.x, 8, "Shrek stands on the final swamp clearing")
T.eq(shrekObject.y, 49, "Shrek's clearing is deep in the swamp")
T.eq(Data:resolveText("OgreSwamp", "TEXT_JJ_SHREK_BATTLE"),
  "You made it this far.\nThat was unwise.", "Shrek has bespoke battle text")
local shrekScript = MapScripts.talkScript(MAP, "TEXT_JJ_SHREK_BATTLE")
T.eq(shrekScript[1][1], "check_flag", "Shrek checks quest progress first")
T.eq(shrekScript[10][1], "jj_fuchsia_swamp:battle", "Shrek's script starts the capstone battle")
local siteScript = MapScripts.talkScript(MAP, "TEXT_JJ_SHREK_DREDGER")
T.eq(siteScript[4][2], "OPP_JJ_DREDGER", "each site starts its own trainer battle")
T.eq(siteScript[7][1], "jump", "crew victory text is handled inside the battle")
local endText = run.loader.exports.jj_fuchsia_swamp.battleEndText
for trainer, text in pairs(endText) do
  local pages = TextBox.paginate(text, 18)
  T.check(#pages == 1 and #pages[1] <= 2,
    trainer .. " end-battle text fits one two-line text box")
end
T.eq(shrekScript[16][2], "They poison it!\nMake them leave!",
  "Shrek is angry about the crews before the quest is cleared")
local rumorScript = MapScripts.talkScript("FUCHSIA_CITY", "TEXT_FUCHSIACITY_YOUNGSTER1")
T.check(rumorScript ~= nil, "Fuchsia has an optional swamp rumor")
T.eq(rumorScript and rumorScript[1][2], "Someone on ROUTE 19\nfound a quiet cove.",
  "the Fuchsia rumor points toward the swamp")
local restScript = MapScripts.talkScript(HUT, "TEXT_JJ_SHREK_REST")
T.eq(restScript[6][1], "heal_party", "the hut heals the player's party")
T.eq(restScript[13][2], "Any POKeMON can learn.\nChoose one lesson.",
  "Shrek explains the lesson rules the first time")
T.eq(restScript[17][1], "set_field", "the lesson explanation is remembered")
T.eq(restScript[19][1], "jj_fuchsia_swamp:tutor", "the hut opens the tutor flow")
T.eq(restScript[23][2], "FUCHSIA_CITY", "the hut can return the player to Fuchsia")
T.eq(#Tutor.lessons, 4, "Shrek offers four lessons")
T.check(Data.trainers.OPP_JJ_TRIAL_SLAM ~= nil, "Body Slam has a trial trainer")
T.check(Data.trainers.OPP_JJ_TRIAL_ROCK ~= nil, "Rock Slide has a trial trainer")
T.check(Data.trainers.OPP_JJ_TRIAL_SLUDGE ~= nil, "Sludge has a trial trainer")
T.check(Data.trainers.OPP_JJ_TRIAL_REST ~= nil, "Rest has a trial trainer")
for _, lesson in ipairs(Tutor.lessons) do
  local trial = Data.trainers[lesson.trainer]
  T.eq(trial.name, "OGRE SHREK", lesson.label .. " shows Shrek as the trainer")
  T.eq(trial.pic, "mods/jj_fuchsia_swamp/assets/shrek-source.png",
    lesson.label .. " uses Shrek's trainer portrait")
  T.eq(trial.paletteSource, shrek.paletteSource,
    lesson.label .. " uses Shrek's matching battle palette")
  T.check(type(lesson.winText) == "string" and lesson.winText ~= "",
    lesson.label .. " has Shrek's post-battle line")
  local pages = TextBox.paginate(lesson.winText, 18)
  T.check(#pages == 1 and #pages[1] <= 2,
    lesson.label .. " lesson victory text fits one two-line text box")
end
T.eq(Data.trainers.OPP_JJ_DREDGER.basePic, "OPP_ENGINEER",
  "the dredger reuses the base game's Engineer portrait")
T.eq(Data.trainers.OPP_JJ_SURVEYOR.basePic, "OPP_HIKER",
  "the surveyor reuses the base game's Hiker portrait")
T.eq(Data.trainers.OPP_JJ_TECH.basePic, "OPP_SCIENTIST",
  "the pump-tech reuses the base game's Scientist portrait")
T.check(BattleState.trainerPicPath(Data, Data.trainers.OPP_JJ_DREDGER) ~= nil,
  "a base portrait resolves for the dredger battle")
T.check(type(Data.commands["jj_fuchsia_swamp:tutor"]) == "table",
  "the tutor flow is registered as a blocking command")
T.check(type(Data.commands["jj_fuchsia_swamp:battle"]) == "table",
  "quest battles own their Fuchsia blackout path")
T.eq(Tutor.levelFor({ level = 40 }), 41, "a trial scales one level above its student")
T.eq(Tutor.levelFor({ level = 2 }), 30, "a trial has a midgame lower bound")
T.eq(Tutor.levelFor({ level = 70 }), 55, "a trial has a fair upper bound")
T.check(Tutor.knows({ moves = { { id = "SLUDGE" } } }, "SLUDGE"),
  "the tutor rejects a move the Pokemon already knows")
local lessonBounds = Tutor.lessonMenuBounds and Tutor.lessonMenuBounds() or {}
T.eq(lessonBounds.tx, 1, "the lesson menu starts clear of the text box")
T.eq(lessonBounds.tw, 14, "the longest lesson label clears the menu border")
local trialLoss = Tutor.lossDestination and Tutor.lossDestination(HUT) or {}
T.eq(trialLoss.map, HUT, "losing a lesson returns the player to Shrek's hut")
T.eq(trialLoss.x, 2, "the lesson loss returns at the hut entrance")

-- Replay the three real talk scripts with their battles resolved as wins.
-- This is the quest gate as a player encounters it: each victory must write
-- its mod-private flag and the capstone conversation must then start Shrek.
do
  local game = {
    data = Data,
    save = { flags = {}, modData = {}, inventory = {}, party = {} },
    stack = { push = function() end },
  }
  local wins = {}
  local originalBattle = Data.commands["jj_fuchsia_swamp:battle"]
  local originalText = Data.commands.show_text
  local originalWarp = Data.commands.warp
  Data.commands["jj_fuchsia_swamp:battle"] = function(ctx, trainer)
    wins[#wins + 1] = trainer
    ctx.lastCheck = true
  end
  Data.commands.show_text = function() end
  Data.commands.warp = function() end
  local function runTalk(text)
    local runner = ScriptRunner.new(game, nil)
    runner:run(MapScripts.talkScript(MAP, text), {
      source = MapScripts.talkSource(MAP, text),
    })
    T.check(not runner:isRunning(), text .. " completes after a victory")
  end
  runTalk("TEXT_JJ_SHREK_DREDGER")
  runTalk("TEXT_JJ_SHREK_SURVEYOR")
  runTalk("TEXT_JJ_SHREK_TECH")
  T.check(game.save.modData.jj_fuchsia_swamp.site_dredger,
    "defeating the dredger persists the first gate")
  T.check(game.save.modData.jj_fuchsia_swamp.site_surveyor,
    "defeating the surveyor persists the second gate")
  T.check(game.save.modData.jj_fuchsia_swamp.site_tech,
    "defeating the pump tech persists the third gate")
  runTalk("TEXT_JJ_SHREK_BATTLE")
  T.eq(wins[4], "OPP_JJ_SHREK", "all three crew wins unlock Shrek's battle")
  T.check(game.save.modData.jj_fuchsia_swamp.shrek_defeated,
    "defeating Shrek persists the completed quest")
  Data.commands["jj_fuchsia_swamp:battle"] = originalBattle
  Data.commands.show_text = originalText
  Data.commands.warp = originalWarp
end

local outward = Overworld.computeNeighbors(Data.maps, "ROUTE_19", 1)
local returnPath = Overworld.computeNeighbors(Data.maps, MAP, 1)
local function hasMap(rows, id)
  for _, row in ipairs(rows) do
    if row.id == id then return true end
  end
  return false
end
T.check(hasMap(outward, MAP), "Route 19 can cross to the swamp")
T.check(hasMap(returnPath, "ROUTE_19"), "the swamp can cross back to Route 19")

local encounter = Data.encounters[MAP]
T.eq(encounter.grass.rate, 20, "ambient encounters stay low-rate")
T.eq(#encounter.grass.slots, 10, "the encounter table is complete")

local game = { save = { flags = {}, modData = {
  jj_shrek = { site_dredger = true },
} } }
_G.game = game
Runtime.emit("map.entered", { mapId = MAP })
T.check(game.save.modData.jj_fuchsia_swamp.visited,
  "a mod-private quest flag persists on the game save")
T.check(game.save.modData.jj_fuchsia_swamp.site_dredger,
  "legacy jj_shrek quest progress migrates to Fuchsia Swamp")

run.release()
T.finish("jj_fuchsia_swamp")
