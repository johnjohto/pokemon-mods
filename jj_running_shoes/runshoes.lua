-- Running Shoes: the whole decision, as a pure module the headless tests
-- drive directly.  main.lua only wires it to the engine.
local Run = {}

-- One full leg cycle in animation-clock ticks.  Player:walkPhase reads
-- animClock % 16 and Player:pose derives the mirror flip from
-- floor(animClock / 16), so 16 is the cycle both agree on.  It is also
-- the vanilla walking step length, which is why a walked tile comes out
-- as exactly one cycle.
Run.CYCLE = 16

-- The multiplier this step is eligible for; 1 is vanilla.  Surfing is
-- never hurried: no legs, no pedals.
function Run.multiplier(ctx, opts)
  if ctx.surfing then return 1 end
  if ctx.onBike then
    local bike = opts.bike or 1
    -- "match" pins the bicycle to the walking multiplier, so it holds its
    -- 2:1 lead over a runner rather than being caught by one
    if bike == "match" then return opts.speed or 1 end
    return bike
  end
  return opts.speed or 1
end

-- Whether to hurry this step.  The bicycle answers to the same trigger as
-- the feet, so B means "faster" everywhere it means anything -- and with
-- "match" the bike keeps its lead whether or not B is down.
function Run.running(ctx, opts)
  if Run.multiplier(ctx, opts) <= 1 then return false end
  if opts.trigger == "always" then return true end
  local input = ctx.input
  return input ~= nil and input.isDown ~= nil and input:isDown("b") == true
end

-- Step length in frames.  Floored to whole frames and never below 1: the
-- engine divides by this in Player:update's pixel math.
function Run.frames(base, ctx, opts)
  if not Run.running(ctx, opts) then return base end
  return math.max(1, math.floor(base / Run.multiplier(ctx, opts)))
end

-- Animation ticks owed by the frame that carries a step from progress-1
-- to progress, where `base` is the step length this mode would have had
-- unhurried: 16 on foot, 8 on the bicycle.
--
-- The engine ticks animClock once per real frame, so a shortened step
-- would land mid-cycle and read as a slide.  Paying `base` ticks across
-- the step instead -- by the same Bresenham step Player:update uses for
-- its pixel offset -- advances the clock at exactly the multiplier: the
-- legs speed up by as much as the feet do.
--
-- On foot that lands one full cycle per tile, so the clock finishes every
-- tile on a cycle boundary and the mirror flip keeps alternating per tile
-- the way walking does.  On the bicycle it preserves vanilla's half cycle
-- per tile -- the look the engine deliberately chose for it (issue #82) --
-- pedalled faster.
function Run.animTicks(progress, stepLen, base)
  base = base or Run.CYCLE
  return math.floor(progress * base / stepLen)
       - math.floor((progress - 1) * base / stepLen)
end

return Run
