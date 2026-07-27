-- Capture driver for jj_alternate_start media.
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_altstart.lua && set POKEPORT_IDENTITY=capture && love .
local U = require("tests.drivers.util")

return function(game)
  local OUT = os.getenv("CAPTURE_DIR") or "."
  U.wait(5)
  U.tap(game, "start") -- skip intro movie
  U.wait(10)
  U.tap(game, "a") -- title -> menu
  U.wait(5)
  U.tap(game, "a") -- NEW GAME
  U.wait(10)

  -- mash through the vanilla speech + naming until the starter question
  for _ = 1, 600 do
    local top = game.stack:top()
    if top and top.items and top.items[1]
       and top.items[1].label == "BULBASAUR" then break end
    U.tap(game, "a")
    U.wait(2)
  end
  U.wait(30)
  U.shot(game, OUT .. "/starter_choice.png")

  U.tap(game, "a") -- BULBASAUR
  U.wait(40) -- the WHERE TO? list opens
  U.shot(game, OUT .. "/town_list.png")

  -- PALLET, VIRIDIAN, PEWTER, CERULEAN, LAVENDER, VERMILION, CELADON
  for _ = 1, 6 do
    U.tap(game, "down")
    U.wait(3)
  end
  U.tap(game, "a") -- CELADON CITY
  U.wait(240) -- shrink beat, then the warp
  U.shot(game, OUT .. "/celadon_arrival.png")
  U.log("alternate start captured")
  love.event.quit()
end
