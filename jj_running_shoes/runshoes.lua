-- Running Shoes: the whole decision, as a pure module the headless tests
-- drive directly.  main.lua only wires it to the engine.
local Run = {}

-- One full leg cycle in animation-clock ticks.  Player:walkPhase reads
-- animClock % 16 and Player:pose derives the mirror flip from
-- floor(animClock / 16), so 16 is the cycle both agree on.
Run.CYCLE = 16

-- Walking only.  The bicycle is already the fast option and hurrying it
-- would undercut it; surfing has no legs to hurry.
function Run.running(ctx, opts)
  if (opts.speed or 1) <= 1 then return false end
  if ctx.onBike or ctx.surfing then return false end
  if opts.trigger == "always" then return true end
  local input = ctx.input
  return input ~= nil and input.isDown ~= nil and input:isDown("b") == true
end

-- Step length in frames.  Floored to whole frames and never below 1: the
-- engine divides by this in Player:update's pixel math.
function Run.frames(base, ctx, opts)
  if not Run.running(ctx, opts) then return base end
  return math.max(1, math.floor(base / opts.speed))
end

-- Animation ticks owed by the frame that carries a step from progress-1
-- to progress.
--
-- The engine ticks animClock once per real frame, which is why a bike
-- step -- half as many frames -- shows half a leg cycle per tile.  A run
-- instead advances the clock with *distance*, by the same Bresenham step
-- Player:update uses for its pixel offset, so a tile is always exactly
-- one cycle: at half the step length, twice the leg cadence.
--
-- The sum over a step telescopes to CYCLE for any step length, so the
-- clock lands on a cycle boundary every tile however the speed is set --
-- the mirror flip keeps alternating per tile, exactly as it does walking.
function Run.animTicks(progress, stepLen)
  return math.floor(progress * Run.CYCLE / stepLen)
       - math.floor((progress - 1) * Run.CYCLE / stepLen)
end

return Run
