-- Capture driver for jj_auto_field_moves media (video).
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_autofield.lua && set POKEPORT_IDENTITY=capture && love .
-- Record the window with ffmpeg while this runs; the script quits the game
-- at the end so the recording can stop.
local U = require("tests.drivers.util")

return function(game)
  game.speedOverride = 8 -- hurry through the intro, the demo is what matters
  U.newGame(game)
  game.speedOverride = 1
  U.wait(30)

  -- give the kit: badges, HMs, and learners for both moves
  game.save.inventory.HM_CUT = 1
  game.save.inventory.HM_SURF = 1
  game.save.inventory.CASCADEBADGE = 1
  game.save.inventory.SOULBADGE = 1
  local Pokemon = require("src.pokemon.Pokemon")
  local Party = require("src.pokemon.Party")
  local stampOT = require("src.battle.BattleState").stampOT
  for _, species in ipairs({ "CHARMANDER", "SQUIRTLE" }) do
    local mon = Pokemon.new(game.data, species, 5)
    stampOT(game.save, mon)
    Party.add(game.save.party, mon)
  end

  -- scene 1: walk into the Route 2 tree line, no menu, no text
  U.teleport(game, "ROUTE_2", 5, 6, "down")
  U.wait(20)
  U.hold(game, "down", 60) -- into the tree and through the gap it leaves
  U.wait(40)

  -- scene 2: walk into the Route 22 pond, straight onto the water
  U.teleport(game, "ROUTE_22", 21, 4, "left")
  U.wait(20)
  U.hold(game, "left", 30) -- mount the water
  U.wait(30)
  U.hold(game, "left", 30) -- surf a little
  U.wait(30)

  U.log("auto field moves captured")
  love.event.quit()
end
