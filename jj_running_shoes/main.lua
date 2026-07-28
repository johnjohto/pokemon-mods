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
      choices = { { "HOLD B", "hold" }, { "ALWAYS", "always" } } },
  })

  local function opts()
    return {
      speed = tonumber(mod.options:get("speed")) or 2,
      trigger = mod.options:get("trigger") or "hold",
    }
  end

  -- nextFn first, so a sibling speed mod still gets its say and this one
  -- scales whatever it settled on
  mod.hooks:wrap("movement.speed", function(nextFn, frames, ctx)
    frames = nextFn(frames, ctx)
    local o = opts()
    local running = Run.running(ctx, o)
    -- read by the patch below; set on every step so it can never go stale
    if ctx.player then ctx.player.jjRunning = running end
    if not running then return frames end
    return Run.frames(frames, ctx, o)
  end)

  -- The engine advances animClock once per frame while moving.  A running
  -- step is short, so it would land mid-cycle and read as a walk played
  -- at half length; the extra ticks make the legs keep pace with the feet.
  local vanillaUpdate = Player.update
  Player.update = function(self, ...)
    -- captured before the vanilla step: it increments progress itself
    local stepLen = self.jjRunning and self.moving and self.stepFramesCur
    local progress = stepLen and (self.progress or 0)
    local landed = vanillaUpdate(self, ...)
    if progress then
      local extra = Run.animTicks(progress + 1, stepLen) - 1
      if extra > 0 then self.animClock = (self.animClock or 0) + extra end
    end
    if landed then self.jjRunning = false end
    return landed
  end
end
