-- Repel Reuse Prompt: when a Repel wears off in the field, ask "Use
-- another?" like the later generations do, instead of making the player
-- dig through the bag.
--
-- How it works with only public events:
--   world.stepped fires before the engine counts the Repel down, so a
--   reading of 1 means the "wore off" textbox is coming this step.
--   screen.popped then tells us that textbox closed, and its state hands
--   us the game. We only prompt when the counter really hit zero and the
--   bag holds another Repel.
return function(mod)
  local TextBox = mod.ui.TextBox
  local ItemEffects = require("src.inventory.ItemEffects")
  local Bag = require("src.inventory.Bag")

  -- weakest first, so the prompt spends cheap Repels before Super and Max
  local REPELS = { "REPEL", "SUPER_REPEL", "MAX_REPEL" }

  local game
  local pending = false

  local function repelInBag(save)
    for _, id in ipairs(REPELS) do
      if (save.inventory or {})[id] then return id end
    end
    return nil
  end

  mod.events:on("game.ready", function(e) game = e.game end)

  mod.events:on("world.stepped", function()
    pending = game ~= nil and (game.save.repelSteps or 0) == 1
  end)

  mod.events:on("screen.popped", function(e)
    if not pending then return end
    local state = e.state
    -- not the wear-off box: leave pending armed, it may still be open
    if getmetatable(state) ~= TextBox then return end
    local g = state.game
    if not g or (g.save.repelSteps or 0) ~= 0 then return end
    pending = false
    local id = repelInBag(g.save)
    if not id then return end -- nothing to offer, same as Gen 2
    local def = g.data.items[id]
    g.stack:push(TextBox.new(g,
      ("Use another\n%s?"):format(def and def.name or id), nil, {
        defaultNo = true,
        choice = function(yes)
          if not yes then return end
          Bag.remove(g.save, id, 1)
          local _, payload = ItemEffects.use(g.data, g.save, id)
          if payload and payload[1] then
            g.stack:push(TextBox.new(g, payload[1]))
          end
          mod.log:info("re-applied %s from the wear-off prompt", id)
        end,
      }))
  end)
end
