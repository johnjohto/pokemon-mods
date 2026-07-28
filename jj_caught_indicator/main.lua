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
      choices = { { "BALL", "ball" }, { "GEN 2", "gen2" } } },
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
    -- the same offsets BattleState applies to the scene and to the enemy
    -- HUD block, so the icon shakes with the name it sits next to
    local fx = battle.fx
    local sx = (fx and fx.shakeX) or 0
    local sy = (fx and fx.shakeY) or 0
    if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
      sx = (battle.frame or 0) % 4 < 2 and 2 or -2
    end
    local hx = (fx and fx.hudShakeX) or 0
    local x, y = Indicator.placement()
    local g = love.graphics
    g.push()
    g.translate(sx + hx, sy)
    g.setColor(1, 1, 1, 1)
    g.draw(iconImage(mod.options:get("icon")), x, y)
    g.pop()
  end)
end
