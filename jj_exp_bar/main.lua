-- EXP Bar: a Gen 2-style experience bar under the player HP bar in
-- battle.  It fills as the active battler gains exp, wrapping through
-- level-ups; every other state change (battle start, switch-in) snaps.
--
-- Deliberately thin: battle.overlay is a draw-only hook and all the state
-- lives in expbar.lua, a pure module the headless tests drive directly.
-- The engine applies exp before emitting battle.exp_gained, so the mod
-- never touches battle logic -- it reads, eases, and draws.
return function(mod)
  local ExpBar = require("mods.jj_exp_bar.expbar")

  mod.options:define({
    { key = "bar_style", label = "EXP BAR", type = "choice",
      default = "ink",
      choices = { { "INK", "ink" }, { "GEN 2 BLUE", "blue" },
                  { "HP MATCH", "hp" } } },
    { key = "bar_y", label = "EXP BAR POS", type = "choice",
      default = 90,
      choices = { { "BORDER", 90 }, { "GEN 2", 89 } } },
  })

  local game
  mod.events:on("game.ready", function(e) game = e.game end)

  local bar = ExpBar.new()
  ExpBar.active = bar -- exposed for the headless tests

  -- the bar's only animation trigger.  EXP ALL shares fire one event per
  -- recipient; like Gen 2, only the active battler's bar shows
  mod.events:on("battle.exp_gained", function(e)
    local b = e.battle
    if not b or not b.player or e.mon ~= b.player.mon then return end
    bar:onExpGained(b.data or (game and game.data), e.mon,
                    e.gained or 0, e.levels)
  end)

  -- geometry lives in expbar.lua, which knows both battle layouts; here
  -- only the height, which neither changes.  One pixel tall, fill only --
  -- a white track erases the box border and reads as a glitch.  Like Gen 2
  -- it fills from right to left.
  local H = 1

  -- fill colors; the HP MATCH thresholds and palette are the engine's own
  -- GetHealthBarColor cutoffs (>= 27/48 green, >= 10/48 yellow, else red)
  -- with the SGB bar fills
  local STYLES = {
    ink = function() return 0, 0, 0 end,
    blue = function() return 0.32, 0.50, 0.91 end,
    hp = function(mon)
      local maxhp = mon.stats and mon.stats.hp or 0
      local px = maxhp > 0 and (mon.hp / maxhp) * 48 or 0
      if px >= 27 then return 0.29, 0.65, 0.35 end
      if px >= 10 then return 0.84, 0.65, 0 end
      return 0.84, 0.32, 0.19
    end,
  }

  mod.hooks:wrap("battle.overlay", function(nextFn, battle)
    nextFn(battle)
    if not game or not ExpBar.visibleFor(battle) then return end
    -- a pushed screen (party, bag, a modal TextBox) draws its own UI over
    -- the HUD region; the bar belongs to the battle scene only
    if game.stack and game.stack:top() ~= battle then return end
    local mon = battle.player.mon
    bar:sync(battle.data or game.data, mon)
    bar:tick()
    -- The wide layout keeps every menu box on tile row 13 and below, well
    -- clear of the player status box, and draws its HUDs outside the
    -- shaken picture regions.  So the two classic dodges below -- and the
    -- shake -- are classic's alone.
    local wide = ExpBar.isWide(battle)
    -- Mimic's copy menu box (0,7) 16x6 covers the bar's row almost
    -- entirely; the bar hides rather than drawing across it
    if not wide and battle.phase == "mimicSelect" then return end
    local sx, sy = 0, 0
    if not wide then
      -- the same window-shake offsets BattleState:draw applies to the
      -- scene, so the bar shakes with the rest of the UI
      local fx = battle.fx
      sx = (fx and fx.shakeX) or 0
      sy = (fx and fx.shakeY) or 0
      if sx == 0 and sy == 0 and fx and fx.shake and fx.shake > 0 then
        sx = (battle.frame or 0) % 4 < 2 and 2 or -2
      end
    end
    local g = love.graphics
    local style = STYLES[mod.options:get("bar_style") or "ink"] or STYLES.ink
    local r, gr, b = style(mon)
    local shot = battle.dramaticShapeShot
    local X, W, y, scale = ExpBar.voxelGeometry(shot,
                                                  mod.options:get("bar_y"))
    local voxel = X ~= nil and shot.canvas ~= nil
    if not voxel then
      X, W, y = ExpBar.geometry(wide, mod.options:get("bar_y"))
      scale = 1
    end
    -- Gen 2 fills right to left: the fill is anchored at the right edge.
    -- During move selection the TYPE/PP panel box (0,8) 11x5 owns x<88 on
    -- this row; clip the fill there instead of drawing across it. The Voxel
    -- Mod moves only the HUD band, so that classic-canvas menu cannot overlap
    -- the external canvas that owns its player HUD.
    local left = X + W - math.floor(W * bar.displayed + 0.5)
    if not voxel and not wide and battle.phase == "moveSelect" and left < 88 then
      left = 88
    end
    local width = X + W - left
    local height = H * scale
    g.push()
    local priorCanvas
    if voxel then
      -- 3D-BTL composites the normal HUD into this full-window canvas before
      -- the regular overlay hook runs. Join that same canvas, applying the
      -- identical classic-to-window transform, rather than drawing an orphan
      -- bar in the letterboxed 160x144 UI surface.
      priorCanvas = g.getCanvas()
      g.setCanvas(shot.canvas)
      sx, sy = sx * scale, sy * scale
    end
    g.translate(sx, sy)
    g.setColor(r, gr, b, 1)
    if width > 0 then g.rectangle("fill", left, y, width, height) end
    g.setColor(1, 1, 1, 1)
    g.pop()
    if voxel then g.setCanvas(priorCanvas) end
  end)
end
