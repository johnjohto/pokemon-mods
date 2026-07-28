-- Capture driver for jj_exp_bar media and geometry checks.
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_expbar.lua && set POKEPORT_IDENTITY=capture && love .
local U = require("tests.drivers.util")

return function(game)
  local Pokemon = require("src.pokemon.Pokemon")
  local BattleState = require("src.battle.BattleState")
  local OUT = os.getenv("CAPTURE_DIR") or "."

  game.speedOverride = 4

  -- blue fill for the captures: visible against the black box border,
  -- which the default INK style merges into
  game.mods.modOptions["jj_exp_bar"] = { bar_style = "blue" }

  -- a mid-level lead with the bar nearly full (MEDIUM_SLOW: level 12 =
  -- 973 exp, level 13 = 1261, so +275 lands ~95% of the way -- far
  -- enough left to exercise the moveSelect clipping)
  local lead = Pokemon.new(game.data, "CHARMANDER", 12)
  lead.exp = lead.exp + 275
  game.save.party = { lead }

  U.teleport(game, "VIRIDIAN_FOREST", 3, 42, "down")
  local ow = game.overworld

  -- big enough to give a visible exp award, still an OHKO for EMBER
  local battle = BattleState.newWild(game, "PIDGEOTTO", 8)
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
  U.shot(game, OUT .. "/expbar_hud.png")

  -- FIGHT menu open: the bar against the move list box
  U.tap(game, "a")
  U.wait(15)
  U.shot(game, OUT .. "/expbar_fightmenu.png")

  -- first move (EMBER) KOs; burst-shot the exp fill animation
  U.tap(game, "a")
  for i = 1, 12 do
    U.wait(15)
    if game.stack:top() ~= battle then break end
    U.shot(game, OUT .. ("/expbar_fill_%02d.png"):format(i))
  end

  U.log("exp bar captured")
  love.event.quit()
end
