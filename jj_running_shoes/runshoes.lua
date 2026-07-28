-- Running Shoes: the whole decision, as a pure module the headless tests
-- drive directly.  main.lua only wires it to the engine.
local Run = {}

-- One full leg cycle in animation-clock ticks.  Player:walkPhase reads
-- animClock % 16 and Player:pose derives the mirror flip from
-- floor(animClock / 16), so 16 is the cycle both agree on.  It is also
-- the vanilla walking step length, which is why a walked tile comes out
-- as exactly one cycle.
Run.CYCLE = 16

-- A mode's own setting, resolved.  "match" pins it to the walking
-- multiplier -- which is how the bicycle holds its 2:1 lead over a runner
-- rather than being caught by one -- and a number stands alone.
local function setting(value, runSpeed)
  if value == "match" then return runSpeed or 1 end
  return tonumber(value) or 1
end

-- The multiplier this step is eligible for; 1 is vanilla.  Surfing is
-- checked before the bicycle: the sea is crossed on the water sprite
-- whatever the player was riding when they stepped in.
function Run.multiplier(ctx, opts)
  if ctx.surfing then return setting(opts.surf, opts.speed) end
  if ctx.onBike then return setting(opts.bike, opts.speed) end
  return opts.speed or 1
end

-- Whether to hurry this step.  Every mode answers to the same trigger as
-- the feet, so B means "faster" everywhere it means anything -- and with
-- "match" the mode keeps its lead whether or not B is down.
--
-- "toggle" reads a latch the caller keeps rather than the button itself;
-- main.lua flips it on B's rising edge.
function Run.running(ctx, opts)
  if Run.multiplier(ctx, opts) <= 1 then return false end
  local trigger = opts.trigger
  if trigger == "always" then return true end
  if trigger == "toggle" then return opts.toggled == true end
  local input = ctx.input
  return input ~= nil and input.isDown ~= nil and input:isDown("b") == true
end

-- B's rising edge, for the toggle latch.  Guarded the same way isDown is:
-- a driver or a stub may hand over an input with neither method.
function Run.togglePressed(input)
  return input ~= nil and input.wasPressed ~= nil
     and input:wasPressed("b") == true
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
