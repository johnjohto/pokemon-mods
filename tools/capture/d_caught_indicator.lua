-- Capture driver for jj_caught_indicator media and a live look at the
-- icon. Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_caught_indicator.lua && set POKEPORT_IDENTITY=capture && love .
-- Screenshots the HUD, then idles at the battle menu with the window
-- open (a finished driver coroutine quits the game, so this waits
-- forever); close the window manually.
local U = require("tests.drivers.util")

return function(game)
  local Pokemon = require("src.pokemon.Pokemon")
  local BattleState = require("src.battle.BattleState")
  local OUT = os.getenv("CAPTURE_DIR") or "."

  game.speedOverride = 4

  -- PIDGEY marked caught: the icon should sit next to its name
  local dex = game.save.pokedex or { owned = {}, seen = {} }
  game.save.pokedex = dex
  dex.owned["PIDGEY"] = true

  game.save.party = { Pokemon.new(game.data, "CHARMANDER", 12) }

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
  U.shot(game, OUT .. "/caught_hud.png")

  -- the second icon style, straight from the options row the mod defines
  local loader = game.mods
  loader.modOptions = loader.modOptions or {}
  loader.modOptions.jj_caught_indicator =
    loader.modOptions.jj_caught_indicator or {}
  loader.modOptions.jj_caught_indicator.icon = "solid"
  U.wait(20)
  U.shot(game, OUT .. "/caught_hud_solid.png")

  game.speedOverride = 1
  U.log("caught indicator captured (both icons); idling at the battle menu")
  while true do U.wait(1) end
end
