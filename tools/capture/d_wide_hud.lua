-- Capture driver for the widescreen battle layout (OPTION -> BATTLE
-- LAYOUT -> WIDE, added upstream in v0.1.31).  Run from a game repo root:
--   set POKEPORT_DRIVER=.../d_wide_hud.lua && set POKEPORT_IDENTITY=capture && love .
--
-- The wide layout composes a 304x144 surface with a Gen 3-style
-- arrangement -- foe status upper left, player status lower right -- so
-- any mod that draws onto the battle HUD at classic 160x144 coordinates
-- lands in the wrong place.  This shoots the same wild battle in both
-- layouts so the two can be compared side by side.
local U = require("tests.drivers.util")

return function(game)
  local Pokemon = require("src.pokemon.Pokemon")
  local BattleState = require("src.battle.BattleState")
  local OUT = os.getenv("CAPTURE_DIR") or "."

  game.speedOverride = 4

  -- PIDGEY owned, so jj_caught_indicator draws its mark; a mid-level
  -- party mon so jj_exp_bar has a bar to fill
  local dex = game.save.pokedex or { owned = {}, seen = {} }
  game.save.pokedex = dex
  dex.owned["PIDGEY"] = true
  game.save.party = { Pokemon.new(game.data, "CHARMANDER", 12) }

  -- a freshly built mon sits exactly on its level threshold, so jj_exp_bar
  -- would have nothing to draw; push it partway to the next level
  local ExpBar = require("mods.jj_exp_bar.expbar")
  local Growth = require("src.pokemon.Growth")
  local mon = game.save.party[1]
  local rate = game.data.pokemon[mon.species].growthRate
  local here = Growth.expForLevel(rate, mon.level, game.data.growth_rates)
  local next_ = Growth.expForLevel(rate, mon.level + 1, game.data.growth_rates)
  mon.exp = math.floor(here + (next_ - here) * 0.6)
  U.log(string.format("exp %d (level %d..%d) -> bar %.2f", mon.exp, here,
    next_, ExpBar.progress(game.data, mon)))

  local function shoot(layout, shot)
    game.save.options = game.save.options or {}
    game.save.options.battleLayout = layout

    U.teleport(game, "VIRIDIAN_FOREST", 3, 42, "down")
    local ow = game.overworld

    local battle = BattleState.newWild(game, "PIDGEY", 3)
    battle.onFinish = function(result) ow:afterBattle(result, battle) end
    ow:pushBattle(battle)

    -- clear the intro boxes until the battle menu is up
    for _ = 1, 150 do
      if game.stack:top() == battle and battle.phase == "menu"
         and (battle.introSlide or 0) == 0 then break end
      U.tap(game, "a")
      U.wait(6)
    end
    U.wait(20)
    U.log(string.format("%s layout: wide=%s, ui=%dx%d", layout,
      tostring(battle:wideLayout()), battle:uiSize()))
    U.shot(game, OUT .. "/" .. shot)
    U.wait(10)

    -- leave the battle so the next pass starts clean
    while game.stack:top() == battle do
      game.stack:pop()
      U.wait(2)
    end
    U.wait(10)
  end

  shoot("og", "wide_hud_og.png")
  shoot("wide", "wide_hud_wide.png")

  -- diagnostic: the INK style is black, and so is the status box frame, so
  -- a bar sitting on a frame line is indistinguishable from it.  Re-shoot
  -- the wide pass in GEN 2 BLUE, where the two cannot be confused.
  local loader = game.mods
  loader.modOptions = loader.modOptions or {}
  loader.modOptions.jj_exp_bar = loader.modOptions.jj_exp_bar or {}
  loader.modOptions.jj_exp_bar.bar_style = "blue"
  shoot("wide", "wide_hud_wide_blue.png")

  U.log("wide hud captured")
  love.event.quit()
end
