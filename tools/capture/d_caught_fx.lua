-- Capture driver for the caught indicator's screen-effect handling: proves
-- the mark is washed by the battle flash like the rest of the screen, and
-- that ICON SHAKE pins it.  Run from the game repo root:
--   POKEPORT_DRIVER=.../d_caught_fx.lua POKEPORT_IDENTITY=capture love .
-- Quits when done, unlike d_caught_indicator.lua which idles for a look.
--
-- main.lua resumes the driver BEFORE Game:update, and that update clears
-- fx.shakeX/shakeY every frame and steps fx.shakeProg -- so a driver that
-- assigns an offset once has it wiped before anything draws.  Hence `pin`,
-- re-applied on every yield: the shake goes in as a *program*, which is what
-- the update reads, and the flash counter and frame parity are held steady so
-- the capture cannot land on an off-beat of the four-frame flicker.
local U = require("tests.drivers.util")

return function(game)
  local Pokemon = require("src.pokemon.Pokemon")
  local BattleState = require("src.battle.BattleState")
  local OUT = os.getenv("CAPTURE_DIR") or "."

  game.speedOverride = 4

  local dex = game.save.pokedex or { owned = {}, seen = {} }
  game.save.pokedex = dex
  dex.owned["PIDGEY"] = true
  game.save.party = { Pokemon.new(game.data, "CHARMANDER", 12) }

  U.teleport(game, "VIRIDIAN_FOREST", 3, 42, "down")
  local ow = game.overworld

  local battle = BattleState.newWild(game, "PIDGEY", 3)
  battle.onFinish = function(result) ow:afterBattle(result, battle) end
  ow:pushBattle(battle)

  for _ = 1, 150 do
    if game.stack:top() == battle and battle.phase == "menu"
       and (battle.introSlide or 0) == 0 then break end
    U.tap(game, "a")
    U.wait(6)
  end
  U.wait(20)

  -- Shoot with `pin` re-applied every frame until the capture lands.
  local function shot(path, pin)
    game.capturePath = path
    for _ = 1, 240 do
      if not game.capturePath then break end
      if pin then pin() end
      coroutine.yield()
    end
    for _ = 1, 2 do
      if pin then pin() end
      coroutine.yield()
    end
    local f = io.open(path, "rb")
    if f then f:close() else U.log("FAIL no shot:", path) end
  end

  local function opts()
    local loader = game.mods
    loader.modOptions = loader.modOptions or {}
    loader.modOptions.jj_caught_indicator =
      loader.modOptions.jj_caught_indicator or {}
    return loader.modOptions.jj_caught_indicator
  end

  battle.fx = battle.fx or {}

  -- baseline: nothing running
  opts().shake = true
  shot(OUT .. "/fx_base.png", function()
    battle.fx.flash = 0
    battle.fx.shakeProg = nil
  end)

  -- flash: counter held up, frame pinned to the washed half of the cycle
  shot(OUT .. "/fx_flash.png", function()
    battle.fx.flash = 600
    battle.frame = 0
  end)

  -- shake, row ON: a one-step program long enough to outlive the capture,
  -- fed to the update the way BattleState feeds its own
  local function shakeProg()
    battle.fx.flash = 0
    battle.fx.shakeProg = { { dx = 3, dy = -1, frames = 9999 } }
  end
  opts().shake = true
  shot(OUT .. "/fx_shake_on.png", shakeProg)

  -- shake, row OFF: identical engine state, so the two shots can differ by
  -- nothing except where the mark sits
  opts().shake = false
  shot(OUT .. "/fx_shake_off.png", shakeProg)

  U.log("caught indicator fx captured")
end
