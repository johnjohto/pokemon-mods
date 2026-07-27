-- Alternate Start: two extra questions at the end of Oak's speech let the
-- player pick a starter and a starting town. Picking anywhere but Pallet
-- Town grants the starter directly, marks the tutorial quests done, and
-- warps the new game to that town. Picking Pallet Town leaves the vanilla
-- intro completely alone.
--
-- Design decisions (deliberate, documented so they can be revisited):
--   - The speech itself still runs; "tutorial-free" means the fetch-quest
--     gating (parcel, old man, lab escort) is already done, not that Oak
--     skips his introduction.
--   - Starter is one of the classic three at level 5, no nickname prompt.
--   - Money, the PC Potion, and everything else stay at vanilla new-game
--     values. Blackouts and escape ropes return to the chosen town's
--     Pokémon Center.
return function(mod)
  -- in flyOrder, minus the dungeon landings
  -- every town here has an ungated way out (verified against the map
  -- scripts).  FUCHSIA (all land exits sealed: Snorlax on Route 12, the
  -- Route 18 bike gate, Surf on 19) and CINNABAR (water-only exits, no
  -- surf source on the island) would softlock a fresh save, so they are
  -- not offered.  SAFFRON is offered but gets the gate fix below.
  local TOWNS = {
    { id = "PALLET_TOWN", label = "PALLET (CLASSIC)" },
    { id = "VIRIDIAN_CITY", label = "VIRIDIAN CITY" },
    { id = "PEWTER_CITY", label = "PEWTER CITY" },
    { id = "CERULEAN_CITY", label = "CERULEAN CITY" },
    { id = "LAVENDER_TOWN", label = "LAVENDER TOWN" },
    { id = "VERMILION_CITY", label = "VERMILION CITY" },
    { id = "CELADON_CITY", label = "CELADON CITY" },
    { id = "SAFFRON_CITY", label = "SAFFRON CITY" },
    { id = "INDIGO_PLATEAU", label = "INDIGO PLATEAU" },
  }
  local STARTERS = { "BULBASAUR", "CHARMANDER", "SQUIRTLE" }

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  -- the starter plus the tutorial flags that say it was handed over:
  -- lab escort, parcel chain, pokédex.  Shared by the quick start (story
  -- beats off) and the visit scene's ball pick (story beats on)
  local function grantStarter(g, species)
    local save = g.save
    local Pokemon = require("src.pokemon.Pokemon")
    local mon = Pokemon.new(g.data, species, 5)
    require("src.battle.BattleState").stampOT(save, mon)
    require("src.pokemon.Party").add(save.party, mon)
    save.pokedex.seen[species] = true
    save.pokedex.owned[species] = true
    local flags = save.flags
    flags.EVENT_GOT_STARTER = true
    flags["EVENT_CHOSE_" .. species] = true
    flags.EVENT_GOT_POKEDEX = true
    flags.EVENT_GOT_OAKS_PARCEL = true
    flags.EVENT_OAK_GOT_PARCEL = true
  end

  mod.hooks:wrap("intro.oak_speech.build", function(nextFn, steps, speech)
    steps = nextFn(steps, speech)

    -- with story beats the starter is picked from Oak's balls in the
    -- visit scene, so the speech only asks where to go
    if mod.options:get("storyBeats") == false then
      mod.ui.insertStepBefore(steps, "shrink", {
        id = "jj_starter",
        kind = "choice",
        text = "Before you go...\nwhich POKéMON will\nyou take with you?",
        choices = STARTERS,
        values = STARTERS,
        saveKey = "jj_starter",
        tx = 2, ty = 0, tw = 15,
      })
    end

    -- the town list is eleven rows, too tall for the choice kind's fixed
    -- box, so a fn step drives a scrolling ListMenu instead
    local townStep = { id = "jj_start_town", kind = "fn", saveKey = "jj_start_town" }
    townStep.run = function(sp, done)
      local ListMenu = require("src.ui.ListMenu")
      local items = {}
      for i, town in ipairs(TOWNS) do
        items[i] = { label = town.label, value = town.id }
      end
      sp.game.stack:push(ListMenu.new(sp.game, "WHERE TO?", items, {
        onChoose = function(item, list)
          sp.game.stack:pop() -- close the list
          sp:recordAnswer(townStep, list.index, item.label, item.value)
          done()
        end,
        -- B pops the list itself; answer classic so the speech is never
        -- left waiting on a choice that is gone
        onCancel = function()
          sp:recordAnswer(townStep, 1, TOWNS[1].label, TOWNS[1].id)
          done()
        end,
      }))
    end
    mod.ui.insertStepBefore(steps, "shrink", townStep)

    return steps
  end)

  local grantedFor -- last speech the starter was granted to
  local pendingWarp -- deferred until the speech is off the stack

  mod.events:on("intro.oak_speech.finished", function(ev)
    local answers = ev.answers or {}
    local townId = answers.jj_start_town
    if not townId or townId == "PALLET_TOWN" then return end -- classic start
    if grantedFor == ev.speech then return end -- a re-fired finish is not a new game

    local g = ev.speech.game
    local save = g.save
    local flags = save.flags

    -- town infrastructure every alternate start needs, story or not:
    -- old man awake and off the Viridian north path...
    save.objectToggles = save.objectToggles or {}
    save.objectToggles.VIRIDIAN_CITY = {
      VIRIDIANCITY_OLD_MAN_SLEEPY = false,
      VIRIDIANCITY_OLD_MAN = true,
    }
    -- ...and a Saffron start needs the thirsty guards already served,
    -- since all four gates block BOTH directions and the city sells none
    if townId == "SAFFRON_CITY" then
      flags.EVENT_GAVE_GUARDS_DRINK = true
    end

    -- blackouts and escape ropes return to this town's Pokémon Center
    local fw = (g.data.field.flyWarps or {})[townId]
    if not fw then
      mod.log:warn("no fly warp for %s; staying in Pallet", townId)
      return
    end
    grantedFor = ev.speech
    save.lastHeal = { map = townId, x = fw.x, y = fw.y }
    save.lastOutdoor = { id = townId, x = fw.x, y = fw.y }
    -- this save is an alternate-start run: story-beats features (the
    -- visit scene, badge-gated rivals) key off this marker so vanilla
    -- and classic-start saves are untouched
    mod.save:set("startedInTown", townId)

    if mod.options:get("storyBeats") == false then
      -- quick start: starter and tutorial flags right now, no scene
      grantStarter(g, answers.jj_starter or "BULBASAUR")
      flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
    end
    -- with story beats the visit scene handles the starter and flags

    -- do NOT warp here: the speech pops itself right after this event, so
    -- anything pushed now is popped in its place and the speech stays
    -- alive, re-firing "finished" every frame. Wait for the pop.
    pendingWarp = { speech = ev.speech, townId = townId, fw = fw }
    mod.log:info("alternate start: %s", townId)
  end)

  mod.events:on("screen.popped", function(e)
    local w = pendingWarp
    if not w or e.state ~= w.speech then return end
    pendingWarp = nil
    local game = w.speech.game
    game.overworld:startWarpTo(w.townId, w.fw.x, w.fw.y, "down")
  end)

  -- ------------------------------------------------------------------
  -- Story beats: Blue's scenes re-gated on gym badges (v2, community
  -- request).  Vanilla ties his appearances to the Pallet tutorial flags
  -- an alternate start never raises, so without this he mostly vanishes.
  -- Each ambush is suppressed below its badge threshold; above it the
  -- base scene runs unchanged.  Applies only to alternate-start saves
  -- (the startedInTown marker) with the STORY BEATS option on.
  -- ------------------------------------------------------------------

  mod.options:define({
    { key = "storyBeats", label = "STORY BEATS", type = "toggle",
      default = true },
  })

  local MapScripts = require("src.script.MapScripts")
  local Badges = require("src.inventory.Badges")
  local Music = require("src.core.Music")

  local function storyActive()
    return mod.options:get("storyBeats") ~= false
       and mod.save:get("startedInTown") ~= nil
  end

  local function badgeCount(g)
    return Badges.count(g.data, g.save)
  end

  local function atCells(cells, x, y)
    for _, c in ipairs(cells) do
      if c[1] == x and c[2] == y then return true end
    end
    return false
  end

  local function busy(ow)
    return ow.runner:isRunning() or #(ow.scriptMoves or {}) > 0
  end

  -- a suppression that yields to the base scene once the threshold is met
  local function suppressBelow(cells, flag, threshold)
    return function(g, ow, x, y)
      if not storyActive() then return false end
      if g.save.flags[flag] then return false end
      if not atCells(cells, x, y) then return false end
      if busy(ow) then return false end
      return badgeCount(g) < threshold
    end
  end

  -- Route 22's first rival fight is special: the base scene only fires
  -- before Brock, so past the threshold the mod runs the ambush itself
  -- (same rows as story5's route22Scene for visit 1)
  local function route22ExitDirs(py)
    if py == 5 then
      return { "right", "right", "down", "down", "down", "down", "down" }
    end
    return { "up", "right", "right", "right",
             "down", "down", "down", "down", "down", "down" }
  end

  local function route22FirstBattleRows(py)
    return {
      { "show_object", "ROUTE_22", "ROUTE22_RIVAL1" },
      { "move_npc_to", 1, 28, py },
      { "face_object", 1, "right" },
      { "show_text", "_Route22RivalBeforeBattleText1" },
      { "rival_battle", "OPP_RIVAL1", 4 },
      { "jump_if_false", 11 },
      { "set_flag", "EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE" },
      { "show_text", "_Route22Rival1DefeatedText" },
      { "show_text", "_Route22RivalAfterBattleText1" },
      { "walk_npc", 1, route22ExitDirs(py) },
      { "hide_object", "ROUTE_22", "ROUTE22_RIVAL1" },
    }
  end

  local gates = {
    ROUTE_22 = {
      onStep = function(g, ow, x, y)
        if not storyActive() then return false end
        if not atCells({ { 29, 4 }, { 29, 5 } }, x, y) then return false end
        local f = g.save.flags
        -- nothing pending: the base owns the pre-Indigo second fight
        if not f.EVENT_GOT_POKEDEX or f.EVENT_BEAT_ROUTE22_RIVAL_1ST_BATTLE then
          return false
        end
        if busy(ow) then return false end
        if badgeCount(g) < 1 then
          return true -- too early: swallow the base's pre-Brock ambush
        end
        ow.player.facing = "left"
        Music.play(g.data, "Music_MeetRival")
        ow.runner:run(route22FirstBattleRows(y))
        return true
      end,
    },
    CERULEAN_CITY = {
      onStep = suppressBelow({ { 20, 6 }, { 21, 6 } },
                             "EVENT_BEAT_CERULEAN_RIVAL", 2),
    },
    SS_ANNE_2F = {
      onStep = suppressBelow({ { 36, 8 }, { 37, 8 } },
                             "EVENT_BEAT_SS_ANNE_RIVAL", 3),
    },
    POKEMON_TOWER_2F = {
      onStep = suppressBelow({ { 15, 5 }, { 14, 6 } },
                             "EVENT_BEAT_POKEMON_TOWER_RIVAL", 4),
      -- the tower rival stands on the map and can be talked to, so the
      -- fight needs gating there too; at threshold the base takes over
      talk = {
        TEXT_POKEMONTOWER2F_RIVAL = function(g, ow, npc, done)
          if storyActive() and badgeCount(g) < 4
             and not g.save.flags.EVENT_BEAT_POKEMON_TOWER_RIVAL then
            ow.runner:run({
              { "show_text",
                "BLUE: You? Not worth\nmy time yet.\fCome back with some\nBADGES. Smell ya!" },
            }, { npc = npc, onDone = done })
            return
          end
          local base = MapScripts.baseTalk("POKEMON_TOWER_2F",
                                           "TEXT_POKEMONTOWER2F_RIVAL")
          if base then return base(g, ow, npc, done) end
          if done then done() end
        end,
      },
    },
    SILPH_CO_7F = {
      onStep = suppressBelow({ { 3, 2 }, { 3, 3 } },
                             "EVENT_BEAT_SILPH_CO_RIVAL", 6),
    },
  }

  for mapId, contribution in pairs(gates) do
    mod.content.map_scripts:register(mapId, contribution)
  end
  mod.exports.rivalGates = gates

  -- ------------------------------------------------------------------
  -- The visit scene (story beats): Oak and Blue meet you at your new
  -- town's Pokémon Center.  Oak offers the three balls (the pick that
  -- the quick start makes in the speech), Blue takes the counter-pick
  -- and fights you, Oak hands over the dex explanation, they leave.
  -- Stages in save.modData: nil -> spawned -> granted -> done, so a
  -- blackout mid-scene can never restart it or orphan the NPCs.
  -- ------------------------------------------------------------------

  local sceneNpcs = {} -- townId -> { npcId, npcId }

  local function npcIndex(npcId)
    return tonumber(npcId:match("_(%d+)$"))
  end

  local function removeSceneNpcs(townId)
    for _, id in ipairs(sceneNpcs[townId] or {}) do
      mod.world:removeNpc(id)
    end
    sceneNpcs[townId] = nil
  end

  local function pickStarter(g, townId, fw, oakIdx, blueIdx, species)
    grantStarter(g, species)
    mod.save:set("introScene", "granted") -- blackout-safe from here
    local name = g.data.pokemon[species].name
    Music.play(g.data, "Music_MeetRival")
    mod.world:queueScript({
      { "show_text", ("BLUE: I'll take this\none, gramps!\fYou got %s?\nWhatever. Mine is\nstronger anyway.\fLet's go, RED.\nRight here, right now!"):format(name) },
      { "rival_battle", "OPP_RIVAL1", 1 },
      { "jump_if_false", 6 },
      { "show_text", "BLUE: What?!\nUnbelievable!\fI picked the wrong\nPOKéMON!" },
      { "show_text", "OAK: Well done, RED!\fThis POKéDEX is\nyours now. It\nrecords every POKéMON\nyou see and catch.\fBLUE, do try to be\na little nicer." },
      { "set_flag", "EVENT_BATTLED_RIVAL_IN_OAKS_LAB" },
    }, { onDone = function()
      -- the walk-off; on a blackout the map rebuilds mid-script and this
      -- never runs, which is what the "granted" cleanup on map.entered
      -- is for
      mod.world:queueScript({
        { "walk_npc", oakIdx,
          { "down", "down", "down", "down", "down" } },
        { "walk_npc", blueIdx,
          { "down", "down", "down", "down", "down" } },
      }, { onDone = function()
        removeSceneNpcs(townId)
        mod.save:set("introScene", "done")
      end })
    end })
  end

  local function startVisitScene(g, townId, fw)
    local oakId = mod.world:spawnNpc(townId, {
      name = "JJ_OAK", movement = "STAY", range = "UP",
      sprite = "SPRITE_OAK", x = fw.x - 1, y = fw.y + 3,
    })
    local blueId = mod.world:spawnNpc(townId, {
      name = "JJ_BLUE", movement = "STAY", range = "UP",
      sprite = "SPRITE_BLUE", x = fw.x + 1, y = fw.y + 3,
    })
    if not (oakId and blueId) then
      -- no live overworld to host the scene: never leave a save
      -- starterless over it
      mod.log:warn("visit scene could not spawn; granting starter silently")
      grantStarter(g, "BULBASAUR")
      g.save.flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
      mod.save:set("introScene", "done")
      return
    end
    sceneNpcs[townId] = { oakId, blueId }
    local oakIdx, blueIdx = npcIndex(oakId), npcIndex(blueId)
    local ok, err = mod.world:queueScript({
      { "move_npc_to", oakIdx, fw.x - 1, fw.y + 2 },
      { "move_npc_to", blueIdx, fw.x + 1, fw.y + 2 },
      { "face_object", oakIdx, "up" },
      { "face_object", blueIdx, "up" },
      { "show_text", "OAK: RED! There you\nare.\fI heard you were\nstarting your journey\nfrom here, so BLUE\nand I came to see\nyou off." },
      { "show_text", "OAK: Now, choose your\nvery first POKéMON!" },
    }, { onDone = function()
      local Menu = require("src.ui.Menu")
      local items = {}
      for i, species in ipairs(STARTERS) do
        items[i] = { label = g.data.pokemon[species].name, onSelect = function()
          pickStarter(g, townId, fw, oakIdx, blueIdx, species)
        end }
      end
      g.stack:push(Menu.new(g, items, { tx = 2, ty = 0, tw = 15 }))
    end })
    if not ok then
      mod.log:warn("visit scene script refused: %s", tostring(err))
      -- nothing ran yet; drop the NPCs so the next map.entered retries
      -- cleanly instead of duplicating them
      removeSceneNpcs(townId)
    end
  end

  mod.events:on("map.entered", function(e)
    if not storyActive() then return end
    local townId = mod.save:get("startedInTown")
    if not townId or e.mapId ~= townId then return end
    local stage = mod.save:get("introScene")
    if stage == nil then
      if not game then return end
      local fw = (game.data.field.flyWarps or {})[townId]
      if fw then startVisitScene(game, townId, fw) end
    elseif stage == "granted" then
      -- the duel ended in a blackout before the walk-off
      removeSceneNpcs(townId)
      mod.save:set("introScene", "done")
    end
  end)

  mod.exports.visitScene = {
    start = startVisitScene,
    pick = pickStarter,
    cleanup = removeSceneNpcs,
  }
end
