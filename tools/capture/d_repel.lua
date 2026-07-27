-- Capture driver for jj_repel_prompt media.
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_repel.lua && set POKEPORT_IDENTITY=capture && love .
local U = require("tests.drivers.util")

return function(game)
  local OUT = os.getenv("CAPTURE_DIR") or "."
  U.newGame(game)

  -- one repel step left: the next step shows the wear-off text, and
  -- dismissing it opens the mod's prompt
  U.teleport(game, "ROUTE_1", 10, 20, "down")
  game.save.repelSteps = 1
  game.save.inventory.REPEL = 1

  U.hold(game, "down", 16) -- one tile south: the wear-off step
  -- dismiss the wear-off text (A completes the typewriter first), then
  -- wait for the prompt: it is the TextBox carrying a YES/NO choice
  for _ = 1, 300 do
    local top = game.stack:top()
    if top and top.choice then break end
    U.tap(game, "a")
    U.wait(4)
  end
  U.wait(60) -- text fully typed, YES/NO box up
  U.shot(game, OUT .. "/prompt.png")
  U.log("repel prompt captured")
  love.event.quit()
end
