-- Auto Field Moves: field moves fire on contact instead of from the
-- party menu.  Walking into water surfs, into a cuttable tile cuts,
-- into a boulder activates STRENGTH, and entering a dark cave FLASHes.
-- FLY stays menu-only: it has no contact trigger.
--
-- The mod is deliberately thin: every activation runs the engine's own
-- use*/try* pair, so all the real rules (badges, Cycling Road, Seafoam
-- currents, tileset gates) stay in one place.  When jj_hm_field_unlock
-- is installed its partyKnows patch widens those same checks, so the two
-- mods compose with no interop code here.
return function(mod)
  local TextBox = mod.ui.TextBox
  local Map = require("src.world.Map")

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  local function ow() return game and game.overworld end

  local function knows(moveId)
    local o = ow()
    return o ~= nil and o:partyKnows(moveId) ~= nil
  end

  -- the vanilla STRENGTH activation (start_sub_menus.asm .strength):
  -- set the flag, then the two texts with the user's cry between
  local function activateStrength(o)
    local mon = o:partyKnows("STRENGTH")
    if not mon then return end
    o.strengthActive = true
    local def = game.data.pokemon[mon.species]
    local name = mon.nickname or def.name
    local t1 = (game.data.text._UsedStrengthText
      or "{RAM:wNameBuffer} used\nSTRENGTH."):gsub("{RAM:wNameBuffer}", name)
    local t2 = (game.data.text._CanMoveBouldersText
      or "{RAM:wNameBuffer} can\nmove boulders."):gsub("{RAM:wNameBuffer}", name)
    game.stack:push(TextBox.new(game, t1, function()
      game.stack:push(TextBox.new(game, t2, function()
        game.stack:push(require("src.render.Transition").whiteFlash(game))
      end))
    end, { auto = { sound = function()
      return require("src.core.Sound").playCry(game.data, mon.species)
    end } }))
    mod.log:info("auto STRENGTH activated")
  end

  mod.hooks:wrap("movement.collision", function(nextFn, allowed, ctx)
    allowed = nextFn(allowed, ctx)
    if allowed then return true end
    local o = ow()
    -- only the player's own blocked steps, never NPC pathing
    if not o or not game or ctx.mover ~= o.player then return false end
    if ctx.reason == "tile" then
      -- water: surf straight on (Gen 1 has no confirmation prompt either)
      if ctx.map:isWaterCell(ctx.toX, ctx.toY) and not o.player.surfing
         and o:useSurfFieldMove() == "ok" then
        o:trySurf(ctx.toX, ctx.toY)
        return false
      end
      -- trees, gym plants, tall grass: useCutFieldMove gates on the faced
      -- cell, which is exactly the blocked step's target
      if o:useCutFieldMove() == "ok" and o:tryCut(ctx.toX, ctx.toY) then
        mod.log:info("auto CUT at %d,%d", ctx.toX, ctx.toY)
        return false
      end
    elseif ctx.reason == "entity" and not o.strengthActive
           and knows("STRENGTH") then
      local npc = o:npcAtCell(ctx.toX, ctx.toY)
      if npc and Map.isPushable(npc.def) then
        activateStrength(o)
        return false
      end
    end
    return false
  end)

  -- entering a dark cave FLASHes (Rock Tunnel); the party-menu action's
  -- own sequence, triggered by the map change instead
  mod.events:on("map.entered", function()
    local o = ow()
    if not o or not o.dark or not knows("FLASH") then return end
    o.dark = false
    game.save.flashLit = true
    game.stack:push(TextBox.new(game,
      game.data.text._FlashLightsAreaText
      or "A blinding FLASH\nlights the area!", function()
        game.stack:push(require("src.render.Transition").whiteFlash(game))
      end))
    mod.log:info("auto FLASH lit %s", tostring(o.map and o.map.id))
  end)
end
