-- Shrek's repeatable lessons.  Keep the choice and balancing facts separate
-- from the UI/battle wiring so each is easy to test and retune.
local Tutor = {}

Tutor.lessons = {
  { move = "BODY_SLAM", label = "BODY SLAM", trainer = "OPP_JJ_TRIAL_SLAM",
    species = "SNORLAX", winText = "Strong shoulders.\nNow make them count." },
  { move = "ROCK_SLIDE", label = "ROCK SLIDE", trainer = "OPP_JJ_TRIAL_ROCK",
    species = "GOLEM", winText = "Good. Do not throw it\nwithout a reason." },
  { move = "SLUDGE", label = "SLUDGE", trainer = "OPP_JJ_TRIAL_SLUDGE",
    species = "MUK", winText = "Dirty work. You did\nnot flinch." },
  { move = "REST", label = "REST", trainer = "OPP_JJ_TRIAL_REST",
    species = "SLOWBRO", winText = "Knowing when to stop\nis not weakness." },
}

function Tutor.levelFor(mon)
  local level = tonumber(mon and mon.level) or 30
  return math.max(30, math.min(55, level + 1))
end

function Tutor.knows(mon, moveId)
  for _, move in ipairs(mon and mon.moves or {}) do
    if move.id == moveId then return true end
  end
  return false
end

function Tutor.lessonMenuBounds()
  -- Cursor + two tiles of left padding + ROCK SLIDE (10 glyphs) must fit
  -- inside the frame.  The old right-aligned menu wrote into its border.
  return { tx = 1, ty = 2, tw = 14 }
end

function Tutor.lossDestination(mapId)
  if mapId == "JJ_SHREK_HUT" then
    return { map = "JJ_SHREK_HUT", x = 2, y = 6, facing = "down" }
  end
  return { map = "FUCHSIA_CITY", x = 19, y = 28, facing = "down" }
end

return Tutor
