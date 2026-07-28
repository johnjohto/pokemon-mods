-- Caught Indicator: a Gen 2-style pokeball icon one tile left of the wild
-- enemy's name when its species is already registered as caught in the
-- dex. Nothing else changes: no text, no sounds, catching works as before.
--
-- Deliberately thin: battle.overlay is a draw-only hook and every decision
-- lives in indicator.lua, a pure module the headless tests drive directly.
-- The mod only reads battle/dex state and draws an 8x8 tile.
return function(mod)
  local Indicator = require("mods.jj_caught_indicator.indicator")

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  -- the icon as pixel rows; X is ink. Drawn in black like the rest of the
  -- enemy HUD, so the zone pass recolors it with everything else
  local PIXELS = {
    "..XXXX..",
    ".X....X.",
    "X......X",
    "XXXXXXXX",
    "X......X",
    ".X....X.",
    "..XXXX..",
    "........",
  }

  local icon -- built lazily: love.graphics only exists once a frame draws
  local function iconImage()
    if icon then return icon end
    local data = love.image.newImageData(8, 8)
    for y, row in ipairs(PIXELS) do
      for x = 1, 8 do
        if row:sub(x, x) == "X" then
          data:setPixel(x - 1, y - 1, 0, 0, 0, 1)
        end
      end
    end
    icon = love.graphics.newImage(data)
    icon:setFilter("nearest", "nearest")
    return icon
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
    g.draw(iconImage(), x, y)
    g.pop()
  end)
end
