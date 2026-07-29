-- Caught Indicator: a Gen 2-style pokeball icon one tile left of the wild
-- enemy's name when its species is already registered as caught in the
-- dex. Nothing else changes: no text, no sounds, catching works as before.
--
-- Deliberately thin: battle.overlay is a draw-only hook, and the decision
-- and the icon art both live in indicator.lua, a pure module the headless
-- tests drive directly. The mod only reads battle/dex state, rasterizes
-- the chosen 8x8 tile, and draws it.
return function(mod)
  local Indicator = require("mods.jj_caught_indicator.indicator")

  mod.options:define({
    { key = "icon", label = "CAUGHT ICON", type = "choice",
      default = Indicator.DEFAULT_ICON,
      choices = { { "GEN 2", "gen2" }, { "GEN 1", "gen1" } } },
    -- ON is vanilla: the mark shakes with the name it sits beside. OFF pins
    -- it. Only the classic layout has anything to pin -- the wide one never
    -- shook the mark, because its status boxes don't shake either.
    --
    -- The screen flash deliberately has no row. A mark floating crisp over
    -- a flashed screen is wrong rather than a matter of taste, so it is
    -- fixed for everyone below and not offered as a choice.
    { key = "shake", label = "ICON SHAKE", type = "toggle", default = true },
  })

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  -- built lazily and kept per style: love.graphics only exists once a
  -- frame draws, and caching both means switching the option mid-battle
  -- costs nothing
  local cache = {}
  local function iconImage(style)
    local img = cache[style]
    if img then return img end
    local data = love.image.newImageData(8, 8)
    for y, row in ipairs(Indicator.pixels(style)) do
      for x = 1, 8 do
        if row:sub(x, x) == "X" then
          data:setPixel(x - 1, y - 1, 0, 0, 0, 1)
        end
      end
    end
    img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    cache[style] = img
    return img
  end

  mod.hooks:wrap("battle.overlay", function(nextFn, battle)
    nextFn(battle)
    if not Indicator.shouldShow(battle, game) then return end
    -- a pushed screen (party, bag, a modal TextBox) draws over the HUD;
    -- the icon belongs to the battle scene only
    if game.stack and game.stack:top() ~= battle then return end
    local wide = Indicator.isWide(battle)
    local sx, sy = Indicator.shakeOffset(battle, wide,
      mod.options:get("shake") ~= false)
    local x, y = Indicator.placement(wide)
    local g = love.graphics
    g.push()
    g.translate(sx, sy)
    g.setColor(1, 1, 1, 1)
    g.draw(iconImage(mod.options:get("icon")), x, y)
    -- the hook runs after the layout's flash rectangle, so put the mark back
    -- under it: the same wash over its own cell alone, since the rest of the
    -- screen already has one and a second would only make it whiter
    local flash = Indicator.flashAlpha(battle)
    if flash then
      g.setColor(1, 1, 1, flash)
      g.rectangle("fill", x, y, 8, 8)
      g.setColor(1, 1, 1, 1)
    end
    g.pop()
  end)
end
