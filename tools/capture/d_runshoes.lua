-- Capture driver for jj_running_shoes media and a live timing check.
-- Run from the game repo root:
--   set POKEPORT_DRIVER=.../d_runshoes.lua && set POKEPORT_IDENTITY=capture && love .
-- Walks a stretch of Viridian City, then runs the same stretch holding B,
-- so a recording shows the two back to back. Logs the frames each leg
-- took and the walk-phase trace of its first tile: the run should be half
-- the frames with the same full leg cycle. Quits at the end so a
-- recording can stop.
local U = require("tests.drivers.util")

return function(game)
  local OUT = os.getenv("CAPTURE_DIR") or "."
  local TILES = 5 -- the clear stretch south of the Viridian sign

  -- B must be held *with* the direction, which U.hold cannot do (it owns
  -- one button); same shape as U.hold otherwise, including the release.
  local function press(dir, withB)
    table.insert(game.input.pressQueue, dir)
    game.input.state[dir] = true
    if withB then game.input.state.b = true end
    coroutine.yield()
  end

  -- Hold `dir` until the player has covered `tiles` cells. Returns the
  -- frames it took and the leg poses seen while crossing the first one.
  local function go(dir, tiles, withB)
    local p = game.overworld.player
    local startY, frames, trace = p.cellY, 0, {}
    while math.abs(p.cellY - startY) < tiles and frames < 600 do
      press(dir, withB)
      frames = frames + 1
      if math.abs(p.cellY - startY) < 1 then
        trace[#trace + 1] = p:walkPhase()
      end
    end
    game.input.state[dir] = false
    game.input.state.b = false
    return frames, table.concat(trace)
  end

  game.speedOverride = 8 -- hurry the intro; the two legs are the demo
  U.newGame(game)
  game.speedOverride = 1
  U.wait(30)

  local function leg(label, withB, onBike, shot)
    U.teleport(game, "VIRIDIAN_CITY", 19, 3, "down")
    game.save.onBike = onBike or false
    U.wait(20)
    local p = game.overworld.player
    local from = p.cellY
    local frames, trace = go("down", TILES, withB)
    U.log(string.format("%-12s %d tiles (y %d -> %d) in %d frames; first tile %s",
      label, TILES, from, p.cellY, frames, trace))
    U.wait(20)
    if shot then U.shot(game, OUT .. "/" .. shot) end
    U.wait(10)
  end

  -- the option row the bicycle legs below are measuring
  local function setBike(value)
    local loader = game.mods
    loader.modOptions = loader.modOptions or {}
    loader.modOptions.jj_running_shoes =
      loader.modOptions.jj_running_shoes or {}
    loader.modOptions.jj_running_shoes.bike = value
  end

  leg("walked", false, false, "runshoes_walk.png")
  leg("ran", true, false, "runshoes_run.png")

  -- the bicycle: untouched at BIKE SPEED VANILLA even with B down, then
  -- hurried once MATCH RUN hands it the walking multiplier
  leg("biked", true, true)
  setBike("match")
  leg("biked MATCH", true, true, "runshoes_bike.png")
  setBike(nil)

  U.log("running shoes captured")
  love.event.quit()
end
