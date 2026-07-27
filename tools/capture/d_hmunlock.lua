-- Capture driver for jj_hm_field_unlock media.
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_hmunlock.lua && set POKEPORT_IDENTITY=capture && love .
local U = require("tests.drivers.util")

return function(game)
  local OUT = os.getenv("CAPTURE_DIR") or "."
  U.newGame(game)

  -- the rule: HM + badge owned, a party mon that can learn the move,
  -- nothing taught
  game.save.inventory.HM_SURF = 1
  game.save.inventory.SOULBADGE = 1
  local Pokemon = require("src.pokemon.Pokemon")
  local mon = Pokemon.new(game.data, "SQUIRTLE", 5)
  require("src.battle.BattleState").stampOT(game.save, mon)
  require("src.pokemon.Party").add(game.save.party, mon)
  U.wait(5)

  U.tap(game, "start") -- pause menu
  U.wait(15)
  U.tap(game, "a") -- POKéMON (first row with no pokédex flag)
  U.wait(15)
  U.tap(game, "down") -- onto the Squirtle (second party slot)
  U.wait(3)
  U.tap(game, "a") -- its submenu
  U.wait(50)
  U.shot(game, OUT .. "/party_submenu_surf.png")
  U.log("hm field unlock captured")
  love.event.quit()
end
