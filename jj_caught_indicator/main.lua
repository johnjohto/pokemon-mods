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
    -- The game only tells a mod about catches made while it is installed.
    -- An unrecorded species deliberately keeps the selected icon in HUD ink,
    -- rather than pretending a starter, trade, gift, or old save used a ball.
    { key = "last_ball", label = "LAST BALL", type = "toggle", default = true },
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

  -- Gen 1's save has only the dex's seen/owned bits. The engine event carries
  -- the one bit of capture history the vanilla save lacks, so retain the last
  -- successful ball per species in this mod's own save namespace. It fires
  -- after the mon has actually reached the party or box, never for a miss.
  mod.events:on("pokemon.caught", function(e)
    if type(e) ~= "table" then return end
    local species = e.species or (e.mon and e.mon.species)
    if type(species) ~= "string" or type(e.ball) ~= "string" then return end
    local caughtBalls = mod.save:get("caughtBalls", {})
    caughtBalls[species] = e.ball
    mod.save:set("caughtBalls", caughtBalls)
  end)

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
          -- White source pixels let setColor below produce either the HUD's
          -- usual black ink or a capture-ball tint. The old black source
          -- would multiply every tint back to black.
          data:setPixel(x - 1, y - 1, 1, 1, 1, 1)
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
    local ball
    if mod.options:get("last_ball") ~= false then
      local caughtBalls = mod.save:get("caughtBalls", {})
      ball = caughtBalls[battle.enemy.mon.species]
    end
    local color = Indicator.ballColor(ball)
    g.push()
    g.translate(sx, sy)
    if color then
      g.setColor(color[1], color[2], color[3], 1)
    else
      g.setColor(0, 0, 0, 1)
    end
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
