-- Fuchsia Swamp begins with the map foundation.  The quest content belongs
-- behind this seam: if this map cannot load and return safely, none of the
-- quest state or encounters should ship.
return function(mod)
  local Tutor = require("mods.jj_fuchsia_swamp.tutor")
  local Runtime = require("src.mods.Runtime")
  local MAP = "JJ_SHREK_SWAMP"
  local HUT = "JJ_SHREK_HUT"
  local SHREK_MOVES = {
    { "SLUDGE", "DISABLE", "ACID_ARMOR", "SCREECH" },
    { "ROCK_SLIDE", "EARTHQUAKE", "DEFENSE_CURL", "STRENGTH" },
    { "SURF", "PSYCHIC_M", "REST", "DISABLE" },
    { "BODY_SLAM", "ROCK_SLIDE", "REST", "HYPER_BEAM" },
  }
  local BATTLE_END_TEXT = {
    OPP_JJ_DREDGER = "The dredger is still.\nLeave it that way.",
    OPP_JJ_SURVEYOR = "Paper tears. The reeds\ndo not.",
    OPP_JJ_TECH = "The pump is quiet.\nSo is the argument.",
    OPP_JJ_SHREK = "You are persistent.\nI can work with that.",
  }
  local function finishQuestBattle(ctx, result, battle, onDone)
    if result ~= "lose" or not ctx.overworld then
      if ctx.overworld then ctx.overworld:afterBattle(result, battle) end
      onDone()
      return
    end

    -- The swamp is deliberately a self-contained detour: losing one of its
    -- battles heals the party, applies the usual blackout money loss, and
    -- returns the player to Fuchsia (or, for a lesson, the hut) without
    -- altering any completed sites.
    local Pokemon = require("src.pokemon.Pokemon")
    local FieldDefaults = require("src.world.FieldDefaults")
    for _, mon in ipairs(ctx.save.party) do Pokemon.heal(mon) end
    local divisor = FieldDefaults.world(ctx.game.data, "blackoutMoneyDivisor") or 2
    ctx.save.money = math.floor((ctx.save.money or 0) / divisor)
    Runtime.emit("world.blacked_out", {
      save = ctx.save,
      healTarget = { map = "FUCHSIA_CITY", x = 19, y = 28 },
    })
    local destination = Tutor.lossDestination(ctx.overworld.map.id)
    ctx.overworld:startWarpTo(destination.map, destination.x, destination.y,
      destination.facing, onDone)
  end
  local function siteScript(flag, intro, after, trainer)
    return {
      { "check_flag", "mod:" .. flag },
      { "jump_if_true", "after" },
      { "show_text", intro },
      { "jj_fuchsia_swamp:battle", trainer, 1 },
      { "jump_if_false", "end" },
      { "set_field", "mod:" .. flag, true },
      { "jump", "end" },
      { "label", "after" },
      { "show_text", after },
    }
  end

  -- The supplied portrait is intentionally owned by this mod.  Its use is
  -- limited to Shrek's trainer introduction; a separate walking sheet will
  -- be registered for the overworld encounter.
  mod.content.sprites:register("SPRITE_JJ_SHREK", {
    id = "SPRITE_JJ_SHREK",
    image = mod.path .. "/assets/shrek-overworld.png",
    frames = 6,
    walker = true,
    -- The custom art borrows only a palette assignment from the native
    -- Bug Catcher slot; it remains a mod-supplied image.  Group 2 is the
    -- green OBJ palette in Advanced mode.
    paletteSource = "ROM:SpriteSheetPointerTable[21]",
  })

  mod.content.trainers:register("OPP_JJ_SHREK", {
    id = "OPP_JJ_SHREK",
    name = "OGRE SHREK",
    pic = mod.path .. "/assets/shrek-source.png",
    paletteSource = "ROM:SpriteSheetPointerTable[21]",
    baseMoney = 4400,
    parties = {
      {
        { level = 40, species = "MUK" },
        { level = 41, species = "GOLEM" },
        { level = 42, species = "SLOWBRO" },
        { level = 44, species = "SNORLAX" },
      },
    },
  })

  mod.content.trainers:register("OPP_JJ_DREDGER", {
    id = "OPP_JJ_DREDGER", name = "DREDGER", baseMoney = 2280,
    basePic = "OPP_ENGINEER",
    parties = { { { level = 37, species = "GOLDUCK" },
                  { level = 38, species = "MACHOKE" } } },
  })
  mod.content.trainers:register("OPP_JJ_SURVEYOR", {
    id = "OPP_JJ_SURVEYOR", name = "SURVEYOR", baseMoney = 2280,
    basePic = "OPP_HIKER",
    parties = { { { level = 37, species = "SANDSLASH" },
                  { level = 38, species = "GRAVELER" } } },
  })
  mod.content.trainers:register("OPP_JJ_TECH", {
    id = "OPP_JJ_TECH", name = "PUMP TECH", baseMoney = 2280,
    basePic = "OPP_SCIENTIST",
    parties = { { { level = 38, species = "MAGNEMITE" },
                  { level = 39, species = "ELECTRODE" } } },
  })
  for _, lesson in ipairs(Tutor.lessons) do
    mod.content.trainers:register(lesson.trainer, {
      id = lesson.trainer,
      name = "OGRE SHREK",
      pic = mod.path .. "/assets/shrek-source.png",
      parties = { { { level = 30, species = lesson.species } } },
    })
  end

  mod.content.text:register("_JjShrekBattle", "You made it this far.\nThat was unwise.")
  mod.content.text_pointers:patch("OgreSwamp", {
    TEXT_JJ_SHREK_BATTLE = { text = "_JjShrekBattle" },
  })
  mod.content.map_scripts:register(MAP, {
    talk = {
      TEXT_JJ_SHREK_DREDGER = siteScript("site_dredger",
        "Water belongs in a\npipe. Then it pays.",
        "The dredger is still.\nLeave it that way.", "OPP_JJ_DREDGER"),
      TEXT_JJ_SHREK_SURVEYOR = siteScript("site_surveyor",
        "Paper says this land\nis ours now.",
        "Paper tears. The reeds\ndo not.", "OPP_JJ_SURVEYOR"),
      TEXT_JJ_SHREK_TECH = siteScript("site_tech",
        "One more drain and\nthis place is useful.",
        "The pump is quiet.\nSo is the argument.", "OPP_JJ_TECH"),
      TEXT_JJ_SHREK_BATTLE = {
        { "check_flag", "mod:shrek_defeated" },
        { "jump_if_true", "after" },
        { "check_flag", "mod:site_dredger" },
        { "jump_if_false", "waiting" },
        { "check_flag", "mod:site_surveyor" },
        { "jump_if_false", "waiting" },
        { "check_flag", "mod:site_tech" },
        { "jump_if_false", "waiting" },
        { "show_text", "You handled them.\nNow you handle me." },
        { "jj_fuchsia_swamp:battle", "OPP_JJ_SHREK", 1 },
        { "jump_if_false", "end" },
        { "set_field", "mod:shrek_defeated", true },
        { "warp", HUT, 2, 6, "down" },
        { "jump", "end" },
        { "label", "waiting" },
        { "show_text", "Three crews.\nThree problems." },
        { "jump", "end" },
        { "label", "after" },
        { "show_text", "The hut is open.\nDo not overuse it." },
        { "warp", HUT, 2, 6, "down" },
      },
    },
  })

  -- Optional guidance only: this replaces one Fuchsia resident's generic
  -- line, leaving the Route 19 cove itself unmarked.
  mod.content.map_scripts:register("FUCHSIA_CITY", {
    talk = {
      TEXT_FUCHSIACITY_YOUNGSTER1 = {
        { "show_text", "Someone on ROUTE 19\nfound a quiet cove." },
        { "show_text", "It is east of the\nopen water, they said." },
      },
    },
  })

  mod.content.map_scripts:register(HUT, {
    talk = {
      TEXT_JJ_SHREK_REST = {
        { "check_flag", "mod:shrek_defeated" },
        { "jump_if_false", "before" },
        { "show_text", "Sit. The swamp does\nnot care who you are." },
        { "ask", "Rest your POKeMON?" },
        { "jump_if_false", "return" },
        { "heal_party" },
        { "show_text", "Your POKeMON are\nready to move." },
        { "label", "return" },
        { "ask", "Want a lesson?" },
        { "jump_if_false", "leave" },
        { "check_flag", "mod:lesson_explained" },
        { "jump_if_true", "lesson" },
        { "show_text", "Any POKeMON can learn.\nChoose one lesson." },
        { "show_text", "Then choose one POKeMON.\nIt fights alone." },
        { "show_text", "No switching. The teacher\nis one level stronger." },
        { "show_text", "Win, and it learns that.\nLose, come back." },
        { "set_field", "mod:lesson_explained", true },
        { "label", "lesson" },
        { "jj_fuchsia_swamp:tutor" },
        { "label", "leave" },
        { "ask", "Ride back to FUCHSIA?" },
        { "jump_if_false", "end" },
        { "warp", "FUCHSIA_CITY", 19, 28, "down" },
        { "jump", "end" },
        { "label", "before" },
        { "show_text", "No visitors.\nNot today." },
      },
    },
  })

  -- Trainer records intentionally accept only level/species slots.  The
  -- public party hook supplies the agreed movesets at battle construction
  -- time, without relying on an undocumented registry extension.
  mod.hooks:wrap("trainer.party", function(nextParty, oppClass, partyIndex, party)
    party = nextParty(oppClass, partyIndex, party)
    if oppClass == "OPP_JJ_SHREK" and partyIndex == 1 then
      local taught = {}
      for index, slot in ipairs(party) do
        taught[index] = {
          level = slot.level,
          species = slot.species,
          moves = SHREK_MOVES[index],
        }
      end
      return taught
    end
    local trial = mod.exports.activeTrial
    if trial and oppClass == trial.trainer and partyIndex == 1 then
      return { { level = trial.level, species = trial.species } }
    end
    return party
  end)

  -- One foreground command owns the whole lesson: choose a move, choose a
  -- healthy party member, fight the matching one-Pokemon trial, then use the
  -- engine's normal learn/forget flow.  The temporary one-member party makes
  -- switching impossible without changing the player's saved party order.
  mod.content.commands:register("jj_fuchsia_swamp:tutor", {
    foreground = true,
    blocking = true,
    fn = function(ctx)
      local Menu = require("src.ui.Menu")
      local Screens = require("src.ui.Screens")
      local Commands = require("src.script.Commands")
      local BattleState = require("src.battle.BattleState")
      local runner, game = ctx.runner, ctx.game
      local selectedLesson

      local choices = {}
      for index, lesson in ipairs(Tutor.lessons) do
        local option = lesson
        choices[index] = {
          label = option.label,
          onSelect = function()
            selectedLesson = option
            runner:resume()
          end,
        }
      end
      local bounds = Tutor.lessonMenuBounds()
      game.stack:push(Menu.new(game, choices, {
        tx = bounds.tx, ty = bounds.ty, tw = bounds.tw,
        onCancel = function() runner:resume() end,
      }))
      runner:yield()
      if not selectedLesson then return end

      local selectedMon
      Screens.push(game, "PartyMenu", {
        pickOnly = true,
        onSwitch = function(mon)
          selectedMon = mon
          runner:resume()
        end,
        onCancel = function() runner:resume() end,
      })
      runner:yield()
      if not selectedMon then return end

      local name = selectedMon.nickname
        or (game.data.pokemon[selectedMon.species] or {}).name
        or selectedMon.species
      if (selectedMon.hp or 0) <= 0 then
        Commands.show_text(ctx, name .. " needs to rest\nbefore a lesson.")
        return
      end
      if Tutor.knows(selectedMon, selectedLesson.move) then
        Commands.show_text(ctx, name .. " already knows\n" .. selectedLesson.label .. "!")
        return
      end

      local party = ctx.save.party
      ctx.save.party = { selectedMon }
      mod.exports.activeTrial = {
        trainer = selectedLesson.trainer,
        species = selectedLesson.species,
        level = Tutor.levelFor(selectedMon),
      }
      local battle = BattleState.newTrainer(game, selectedLesson.trainer, 1)
      battle.endBattleText = selectedLesson.winText
      battle.onFinish = function(result)
        ctx.save.party = party
        mod.exports.activeTrial = nil
        ctx.lastCheck = result == "win"
        finishQuestBattle(ctx, result, battle, function() runner:resume() end)
      end
      game.stack:push(battle)
      runner:yield()
      if not ctx.lastCheck then
        Commands.show_text(ctx, "Come back when your\nPOKeMON is ready.")
        return
      end

      if #selectedMon.moves < 4 then
        table.insert(selectedMon.moves, {
          id = selectedLesson.move,
          pp = game.data.moves[selectedLesson.move].pp,
        })
        Runtime.emit("pokemon.move_learned", {
          mon = selectedMon, moveId = selectedLesson.move,
        })
        Commands.show_text(ctx, name .. " learned\n" .. selectedLesson.label .. "!")
        return
      end

      local learned
      Screens.push(game, "MoveLearnMenu", selectedMon, selectedLesson.move,
        function(ok)
          learned = ok
          runner:resume()
        end)
      runner:yield()
      if not learned then
        Commands.show_text(ctx, name .. " kept its old\nmoves.")
      end
    end,
  })

  -- Scripted crew and capstone battles use the same blackout destination as
  -- tutor trials.  Keeping it as a command lets their map scripts retain the
  -- normal battle branching syntax while the detour owns its failure path.
  mod.content.commands:register("jj_fuchsia_swamp:battle", {
    foreground = true,
    blocking = true,
    fn = function(ctx, trainer, partyIndex)
      local BattleState = require("src.battle.BattleState")
      local battle = BattleState.newTrainer(ctx.game, trainer, partyIndex)
      battle.endBattleText = BATTLE_END_TEXT[trainer]
      battle.onFinish = function(result)
        ctx.lastBattleResult = result
        ctx.lastCheck = result == "win"
        finishQuestBattle(ctx, result, battle, function() ctx.runner:resume() end)
      end
      ctx.game.stack:push(battle)
      ctx.runner:yield()
    end,
  })

  -- Use the native overworld tileset instead of an invented tileset id.  The
  -- field engine explicitly permits Surf on OVERWORLD, and its blocks 67 and
  -- 11 are respectively open water and encounter grass.  This keeps the
  -- Route 19 entrance honest: the player has to Surf into the swamp.
  local WATER, GRASS = 67, 11
  local SWAMP_WIDTH, SWAMP_HEIGHT = 10, 27
  local blocks = {}
  for i = 1, SWAMP_WIDTH * SWAMP_HEIGHT do blocks[i] = WATER end
  local function grassIsland(left, top, right, bottom)
    for y = top, bottom do
      for x = left, right do
        blocks[y * SWAMP_WIDTH + x + 1] = GRASS
      end
    end
  end
  -- Four separated clearings make the three crew sites and Shrek's clearing
  -- distinct Surf destinations.  The long water channels are deliberate:
  -- there is no land route around the reclamation work.
  grassIsland(2, 1, 5, 5)   -- dredger's bank
  grassIsland(5, 10, 9, 14) -- survey stakes
  grassIsland(1, 18, 5, 22) -- pump station
  grassIsland(3, 23, 7, 26) -- Shrek's clearing

  mod.content.maps:register(HUT, {
    id = HUT,
    label = "OgreHut",
    index = 1001,
    tileset = "REDS_HOUSE_1",
    width = 4, height = 4,
    -- Block 7 is Red's House's upstairs staircase.  This hut has no second
    -- floor, so use the adjacent wall block instead.
    blocks = { 4, 9, 5, 5, 15, 15, 15, 15, 15, 1, 2, 15, 15, 11, 15, 15 },
    borderBlock = 10,
    warps = {
      { x = 2, y = 7, destMap = "LAST_MAP", destWarp = 1 },
      { x = 3, y = 7, destMap = "LAST_MAP", destWarp = 1 },
    },
    objects = {
      {
        index = 1,
        name = "JJ_SHREK_REST",
        movement = "STAY",
        range = "DOWN",
        sprite = "SPRITE_JJ_SHREK",
        text = "TEXT_JJ_SHREK_REST",
        x = 5, y = 4,
      },
    },
    signs = {},
  })

  mod.content.maps:register(MAP, {
    id = MAP,
    label = "OgreSwamp",
    index = 1000,
    tileset = "OVERWORLD",
    width = SWAMP_WIDTH, height = SWAMP_HEIGHT,
    blocks = blocks,
    borderBlock = WATER,
    -- This hidden return marker gives the hut's LAST_MAP exit a safe return;
    -- the visible way into the hut is Shrek inviting the player inside.
    warps = { { x = 8, y = 50, destMap = HUT, destWarp = 1 } },
    objects = {
      {
        index = 1,
        name = "JJ_SHREK_DREDGER",
        movement = "STAY",
        range = "DOWN",
        sprite = "SPRITE_SAFARI_ZONE_WORKER",
        text = "TEXT_JJ_SHREK_DREDGER",
        x = 6, y = 7,
      },
      {
        index = 2,
        name = "JJ_SHREK_SURVEYOR",
        movement = "STAY",
        range = "DOWN",
        sprite = "SPRITE_SUPER_NERD",
        text = "TEXT_JJ_SHREK_SURVEYOR",
        x = 14, y = 25,
      },
      {
        index = 3,
        name = "JJ_SHREK_TECH",
        movement = "STAY",
        range = "DOWN",
        sprite = "SPRITE_SCIENTIST",
        text = "TEXT_JJ_SHREK_TECH",
        x = 6, y = 42,
      },
      {
        index = 4,
        name = "JJ_SHREK",
        movement = "STAY",
        range = "DOWN",
        sprite = "SPRITE_JJ_SHREK",
        text = "TEXT_JJ_SHREK_BATTLE",
        x = 8, y = 49,
      },
    },
    signs = {},
    connections = { west = { map = "ROUTE_19", offset = 0 } },
    outdoor = true,
    palette = "WATER",
  })

  mod.content.maps:patch("ROUTE_19", {
    blocks = require("mods.jj_fuchsia_swamp.route19_blocks"),
    connections = { east = { map = MAP, offset = 0 } },
  })

  mod.content.encounters:register(MAP, {
    grass = { rate = 20, slots = {
      { level = 30, species = "PARAS" },
      { level = 30, species = "VENONAT" },
      { level = 31, species = "GLOOM" },
      { level = 31, species = "GRIMER" },
      { level = 32, species = "PARAS" },
      { level = 32, species = "VENONAT" },
      { level = 33, species = "GLOOM" },
      { level = 33, species = "GRIMER" },
      { level = 34, species = "VENONAT" },
      { level = 34, species = "GLOOM" },
    } },
  })

  -- Move playtest saves from the pre-release id.  Leave the legacy bucket in
  -- place so returning to an older local build remains safe.
  local function migrateLegacySave()
    if not game or not game.save then return end
    game.save.modData = game.save.modData or {}
    local legacy = game.save.modData.jj_shrek
    if not legacy then return end
    local current = game.save.modData.jj_fuchsia_swamp or {}
    for key, value in pairs(legacy) do
      if current[key] == nil then current[key] = value end
    end
    game.save.modData.jj_fuchsia_swamp = current
  end

  -- Keep quest state private to this mod.  The same namespace will hold the
  -- three restoration sites and Shrek's completed battle.
  mod.events:on("map.entered", function(event)
    if event.mapId ~= MAP or not game or not game.save then return end
    migrateLegacySave()
    game.save.modData = game.save.modData or {}
    game.save.modData.jj_fuchsia_swamp = game.save.modData.jj_fuchsia_swamp or {}
    game.save.modData.jj_fuchsia_swamp.visited = true
  end)
end
