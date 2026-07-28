-- Hands you a wild battle in the widescreen layout with THUNDER_WAVE on
-- the player's Pokémon, then gets out of the way. Run from a game repo
-- root (v0.1.31 or later, for BATTLE LAYOUT -> WIDE):
--   set POKEPORT_DRIVER=.../d_thunderwave.lua && set POKEPORT_IDENTITY=capture && love .
--
-- The driver idles at the battle menu with the window open rather than
-- quitting, so the battle can be played by hand; close the window when
-- you are done.
local U = require("tests.drivers.util")

return function(game)
  local Pokemon = require("src.pokemon.Pokemon")
  local BattleState = require("src.battle.BattleState")
  local OUT = os.getenv("CAPTURE_DIR") or "."

  game.speedOverride = 4

  -- the widescreen layout this is meant to be seen in
  game.save.options = game.save.options or {}
  game.save.options.battleLayout = "wide"

  -- PIKACHU learns THUNDER_WAVE naturally, so the move list is the only
  -- thing forced here; PP comes from the move's own data
  local mon = Pokemon.new(game.data, "PIKACHU", 22)
  local function move(id)
    local def = game.data.moves[id]
    return { id = id, pp = def and def.pp or 0 }
  end
  mon.moves = {
    move("THUNDER_WAVE"),
    move("THUNDERSHOCK"),
    move("QUICK_ATTACK"),
    move("TAIL_WHIP"),
  }
  game.save.party = { mon }

  -- an owned foe, so jj_caught_indicator's mark is up as well
  local dex = game.save.pokedex or { owned = {}, seen = {} }
  game.save.pokedex = dex
  dex.owned["PIDGEY"] = true

  U.teleport(game, "VIRIDIAN_FOREST", 3, 42, "down")
  local ow = game.overworld

  local battle = BattleState.newWild(game, "PIDGEY", 8)
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
  -- bound to locals first: a multi-return in a non-final argument slot
  -- collapses to its first value
  local uw, uh = battle:uiSize()
  U.log(string.format("wide=%s ui=%dx%d  first move: %s",
    tostring(battle:wideLayout()), uw, uh, mon.moves[1].id))
  U.shot(game, OUT .. "/thunderwave_wide.png")

  game.speedOverride = 1
  U.log("battle ready -- FIGHT to see THUNDER_WAVE; idling, close when done")
  while true do U.wait(1) end
end
