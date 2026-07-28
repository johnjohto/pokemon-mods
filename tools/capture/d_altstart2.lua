-- Capture driver for jj_alternate_start v2 media (the visit scene).
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_altstart2.lua && set POKEPORT_IDENTITY=capture && love .
local U = require("tests.drivers.util")

return function(game)
  local OUT = os.getenv("CAPTURE_DIR") or "."
  game.speedOverride = 8
  U.wait(5)
  U.tap(game, "start") -- skip intro movie
  U.wait(10)
  U.tap(game, "a") -- title -> menu
  U.wait(5)
  U.tap(game, "a") -- NEW GAME
  U.wait(10)

  -- mash through the vanilla speech + naming until the WHERE TO? list
  for _ = 1, 600 do
    local top = game.stack:top()
    if top and top.items and top.items[1]
       and tostring(top.items[1].label or ""):find("PALLET", 1, true) then
      break
    end
    U.tap(game, "a")
    U.wait(2)
  end
  game.speedOverride = 1
  U.wait(20)
  U.shot(game, OUT .. "/town_list.png")

  -- PALLET, VIRIDIAN, PEWTER, CERULEAN, LAVENDER, VERMILION, CELADON
  for _ = 1, 6 do
    U.tap(game, "down")
    U.wait(3)
  end
  U.tap(game, "a") -- CELADON CITY

  -- the A-mash typed letters into both naming screens; set the names
  -- the scene and duel should show
  game.save.player.name = "RED"
  game.save.player.rival = "BLUE"

  -- the scene: wait for its first textbox, let it type, shoot it
  for _ = 1, 3000 do
    local top = game.stack:top()
    if top and top.pages then break end
    U.wait(1)
  end
  U.wait(40)
  U.shot(game, OUT .. "/scene_oak_blue.png")

  -- the ball menu (mash through the dialogue to reach it)
  for _ = 1, 3000 do
    local top = game.stack:top()
    if top and top.items and top.items[1]
       and top.items[1].label == "BULBASAUR" then break end
    U.tap(game, "a")
    U.wait(2)
  end
  U.wait(10)
  U.shot(game, OUT .. "/scene_balls.png")

  U.tap(game, "down") -- CHARMANDER
  U.wait(3)
  U.tap(game, "a")

  -- the duel (mash through Blue's challenge to reach the battle)
  for _ = 1, 3000 do
    local top = game.stack:top()
    if top and top.player and top.enemy and top.phase then break end
    U.tap(game, "a")
    U.wait(2)
  end
  U.wait(240) -- intro pans + opening text types out
  U.shot(game, OUT .. "/scene_duel.png")
  U.log("visit scene captured")
  love.event.quit()
end
