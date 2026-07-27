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
  local TOWNS = {
    { id = "PALLET_TOWN", label = "PALLET (CLASSIC)" },
    { id = "VIRIDIAN_CITY", label = "VIRIDIAN CITY" },
    { id = "PEWTER_CITY", label = "PEWTER CITY" },
    { id = "CERULEAN_CITY", label = "CERULEAN CITY" },
    { id = "LAVENDER_TOWN", label = "LAVENDER TOWN" },
    { id = "VERMILION_CITY", label = "VERMILION CITY" },
    { id = "CELADON_CITY", label = "CELADON CITY" },
    { id = "FUCHSIA_CITY", label = "FUCHSIA CITY" },
    { id = "SAFFRON_CITY", label = "SAFFRON CITY" },
    { id = "CINNABAR_ISLAND", label = "CINNABAR ISLAND" },
    { id = "INDIGO_PLATEAU", label = "INDIGO PLATEAU" },
  }
  local STARTERS = { "BULBASAUR", "CHARMANDER", "SQUIRTLE" }

  mod.hooks:wrap("intro.oak_speech.build", function(nextFn, steps, speech)
    steps = nextFn(steps, speech)

    mod.ui.insertStepBefore(steps, "shrink", {
      id = "jj_starter",
      kind = "choice",
      text = "Before you go...\nwhich POKéMON will\nyou take with you?",
      choices = STARTERS,
      values = STARTERS,
      saveKey = "jj_starter",
      tx = 2, ty = 0, tw = 15,
    })

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

    local starter = answers.jj_starter or "BULBASAUR"
    local game = ev.speech.game
    local save = game.save

    -- the starter, straight into the party (dev-console grant pattern)
    local Pokemon = require("src.pokemon.Pokemon")
    local mon = Pokemon.new(game.data, starter, 5)
    require("src.battle.BattleState").stampOT(save, mon)
    require("src.pokemon.Party").add(save.party, mon)
    save.pokedex.seen[starter] = true
    save.pokedex.owned[starter] = true

    -- tutorial quests read as done: lab escort, parcel chain, pokédex
    -- handed over, old man awake and off the Viridian north path
    local flags = save.flags
    flags.EVENT_GOT_STARTER = true
    flags["EVENT_CHOSE_" .. starter] = true
    flags.EVENT_GOT_POKEDEX = true
    flags.EVENT_GOT_OAKS_PARCEL = true
    flags.EVENT_OAK_GOT_PARCEL = true
    flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB = true
    save.objectToggles = save.objectToggles or {}
    save.objectToggles.VIRIDIAN_CITY = {
      VIRIDIANCITY_OLD_MAN_SLEEPY = false,
      VIRIDIANCITY_OLD_MAN = true,
    }

    -- blackouts and escape ropes return to this town's Pokémon Center
    local fw = (game.data.field.flyWarps or {})[townId]
    if not fw then
      mod.log:warn("no fly warp for %s; staying in Pallet", townId)
      return
    end
    grantedFor = ev.speech
    save.lastHeal = { map = townId, x = fw.x, y = fw.y }
    save.lastOutdoor = { id = townId, x = fw.x, y = fw.y }
    -- do NOT warp here: the speech pops itself right after this event, so
    -- anything pushed now is popped in its place and the speech stays
    -- alive, re-firing "finished" every frame. Wait for the pop.
    pendingWarp = { speech = ev.speech, townId = townId, fw = fw }
    mod.log:info("alternate start: %s with %s", townId, starter)
  end)

  mod.events:on("screen.popped", function(e)
    local w = pendingWarp
    if not w or e.state ~= w.speech then return end
    pendingWarp = nil
    local game = w.speech.game
    game.overworld:startWarpTo(w.townId, w.fw.x, w.fw.y, "down")
  end)
end
