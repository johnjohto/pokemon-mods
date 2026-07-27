-- HM Field Unlock: HMs work in the field without being taught.  When the
-- player owns the HM (bag or PC box) and the badge, any party pokémon
-- whose species can learn the move can use it in the field.  Battle is
-- untouched: using the move in a fight still requires teaching it.
--
-- Two seams, both deliberate:
--   activation-time: every field move funnels through partyKnows, so the
--     rule is widened there (a runtime patch, until a proper eligibility
--     hook exists upstream).
--   list-time: the party submenu shows unlocked moves too, injected with
--     the vanilla action ids so the whole vanilla activation flow runs.
return function(mod)
  local Overworld = require("src.world.OverworldController")
  local FieldDefaults = require("src.world.FieldDefaults")

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  -- move id -> HM item id, derived from the item data (cached on first use)
  local hmCache
  local function hmForMove(data, moveId)
    if not hmCache then
      hmCache = {}
      for id, def in pairs(data.items or {}) do
        local m = def.machine
        if m and m.kind == "HM" then hmCache[m.move] = id end
      end
    end
    return hmCache[moveId]
  end

  local function ownsHm(save, hmId)
    return (save.inventory[hmId] or 0) > 0
        or (save.pcItems ~= nil and (save.pcItems[hmId] or 0) > 0)
  end

  local function badgeOwned(data, save, moveId)
    local gate = (FieldDefaults.constant(data, "hmBadges") or {})[moveId]
    return not (gate and gate.badge) or save.inventory[gate.badge] ~= nil
  end

  local function canLearn(data, mon, moveId)
    local def = data.pokemon[mon.species]
    for _, mv in ipairs(def and def.tmhm or {}) do
      if mv == moveId then return true end
    end
    return false
  end

  -- the full rule: not a TM (HMs only), badge owned, HM owned somewhere,
  -- and at least one party mon whose species can learn it (fainted is
  -- fine; vanilla field moves ignore HP too)
  local function firstLearner(data, save, moveId)
    local hmId = hmForMove(data, moveId)
    if not hmId then return nil end
    if not badgeOwned(data, save, moveId) then return nil end
    if not ownsHm(save, hmId) then return nil end
    for _, mon in ipairs(save.party or {}) do
      if canLearn(data, mon, moveId) then return mon end
    end
    return nil
  end

  local vanillaPartyKnows = Overworld.partyKnows
  Overworld.partyKnows = function(self, moveId)
    local mon = vanillaPartyKnows(self, moveId)
    if mon then return mon end
    if not game then return nil end
    return firstLearner(game.data, game.save, moveId)
  end

  -- interop for sibling mods (jj_auto_field_moves asks before triggering)
  mod.exports.canUse = function(g, moveId)
    g = g or game
    return g ~= nil and firstLearner(g.data, g.save, moveId) ~= nil
  end

  local FIELD = {
    { move = "CUT", action = "cut" },
    { move = "SURF", action = "surf" },
    { move = "STRENGTH", action = "strength" },
    { move = "FLASH", action = "flash" },
    { move = "FLY", action = "fly" },
  }
  mod.hooks:wrap("ui.party.submenu", function(nextFn, g, items, mon, ctx)
    items = nextFn(g, items, mon, ctx)
    if not game or not ctx or ctx.battle or not ctx.overworld then
      return items
    end
    local known = {}
    for _, mv in ipairs(mon.moves or {}) do known[mv.id] = true end
    local ow = ctx.overworld
    local outside = require("src.world.Map").isOutside(ow.map.def,
      FieldDefaults.field(game.data, "outsideTilesets"))
    for _, fm in ipairs(FIELD) do
      -- the same list-time location filters vanilla uses, then the rule
      if not known[fm.move]
         and (fm.move ~= "FLY" or outside)
         and (fm.move ~= "FLASH" or ow.dark)
         and canLearn(game.data, mon, fm.move)
         and firstLearner(game.data, game.save, fm.move) then
        items[#items + 1] = { label = fm.move, action = fm.action }
      end
    end
    return items
  end)
end
