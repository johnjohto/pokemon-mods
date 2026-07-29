-- Running Shoes: hold B to move at double speed on foot.
--
-- Two seams, both thin:
--   speed:     movement.speed is upstream's own hook for exactly this
--              ("running shoes, dash" -- src/world/Player.lua).  It is
--              handed the step length in frames; the mod divides it.
--   animation: the leg cadence has no hook, so Player:update is patched
--              to pay the animation clock the extra ticks a shorter step
--              owes.  Everything about *what* the extra is lives in
--              runshoes.lua; the patch only knows when to ask.
--
-- Nothing else moves.  Encounters, poison, and daycare exp all fire from
-- OverworldState:onStepComplete -- once per tile, not per frame -- so a
-- run covers ground faster without touching a single rate.
return function(mod)
  local Run = require("mods.jj_running_shoes.runshoes")
  local Player = require("src.world.Player")

  mod.options:define({
    { key = "speed", label = "RUN SPEED", type = "choice", default = 2,
      choices = { { "2X", 2 }, { "1.5X", 1.5 }, { "OFF", 1 } } },
    { key = "trigger", label = "RUN BUTTON", type = "choice", default = "hold",
      choices = { { "HOLD B", "hold" }, { "TOGGLE", "toggle" },
                  { "ALWAYS", "always" } } },
    -- the bicycle is vanilla until asked otherwise: MATCH RUN keeps its
    -- 2:1 lead over the feet, the numbers set it independently
    { key = "bike", label = "BIKE SPEED", type = "choice", default = 1,
      choices = { { "VANILLA", 1 }, { "MATCH RUN", "match" },
                  { "1.5X", 1.5 }, { "2X", 2 } } },
    -- surfing is its own mode with its own row: a player who wants to
    -- cross water faster does not necessarily want to sprint on land
    { key = "surf", label = "SURF SPEED", type = "choice", default = 1,
      choices = { { "VANILLA", 1 }, { "MATCH RUN", "match" },
                  { "1.5X", 1.5 }, { "2X", 2 } } },
  })

  -- a row is either the literal "match" or a number; anything else is a
  -- stale saved value and reads as vanilla
  local function choice(key)
    local v = mod.options:get(key)
    return v == "match" and "match" or (tonumber(v) or 1)
  end

  -- TOGGLE's latch.  Deliberately not saved: a run state that survived a
  -- reload would have the player moving at double speed with no memory of
  -- having asked for it.
  local toggled = false
  mod.exports.toggled = function() return toggled end

  local function opts()
    return {
      speed = tonumber(mod.options:get("speed")) or 2,
      trigger = mod.options:get("trigger") or "hold",
      bike = choice("bike"),
      surf = choice("surf"),
      toggled = toggled,
    }
  end

  -- nextFn first, so a sibling speed mod still gets its say and this one
  -- scales whatever it settled on
  mod.hooks:wrap("movement.speed", function(nextFn, frames, ctx)
    frames = nextFn(frames, ctx)
    local o = opts()
    local running = Run.running(ctx, o)
    local p = ctx.player
    -- read by the patch below; set on every step so they cannot go stale.
    -- jjRunBase is this mode's unhurried step length, which is what the
    -- animation clock gets paid in -- 16 on foot, 8 on the bicycle.
    if p then
      p.jjRunning = running
      p.jjRunBase = frames
    end
    if not running then return frames end
    return Run.frames(frames, ctx, o)
  end)

  -- The engine advances animClock once per frame while moving.  A hurried
  -- step is short, so it would land mid-cycle and read as a slide; the
  -- extra ticks make the legs keep pace with the feet.
  local Game = require("src.core.Game")
  local vanillaUpdate = Player.update
  Player.update = function(self, ...)
    -- TOGGLE flips here rather than in the speed hook, which only fires on
    -- a step that actually starts -- a tap while standing still has to
    -- count.  StateStack:update only ticks the top state, so this runs in
    -- the free-roam overworld alone: the B that backs out of a menu or a
    -- battle never reaches the latch.
    if mod.options:get("trigger") == "toggle"
       and Run.togglePressed(Game.input) then
      toggled = not toggled
      mod.log:info("run toggled %s", toggled and "on" or "off")
    end
    -- captured before the vanilla step: it increments progress itself
    local stepLen = self.jjRunning and self.moving and self.stepFramesCur
    local progress = stepLen and (self.progress or 0)
    local landed = vanillaUpdate(self, ...)
    if progress then
      local extra = Run.animTicks(progress + 1, stepLen, self.jjRunBase) - 1
      if extra > 0 then self.animClock = (self.animClock or 0) + extra end
    end
    if landed then
      self.jjRunning = false
      -- Hand the unhurried step length back.  A scripted step
      -- (OverworldState:scriptMove -- Oak's walk to the lab, and every
      -- other cutscene the player is walked through) sets moving/progress
      -- on the entity directly and never calls Player:tryMove, so
      -- movement.speed never fires for it: it simply inherits whatever
      -- stepFramesCur the last free-roam step left behind.  Left hurried,
      -- the player crosses a scripted tile in 8 frames while the NPC being
      -- followed is pinned to Npc's own STEP_FRAMES 16, and walks straight
      -- past them.
      if self.jjRunBase then self.stepFramesCur = self.jjRunBase end
    end
    return landed
  end
end
