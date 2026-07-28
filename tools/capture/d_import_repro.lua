-- Repro driver for the launcher mod-import crash, file-logged.
return function(game)
  local out = io.open("C:/Users/George/AppData/Local/Temp/import_repro.txt", "w")
  local function log(fmt, ...)
    out:write(fmt:format(...), "\n")
    out:flush()
  end
  log("driver alive")
  local LauncherMods = require("src.mods.LauncherMods")
  local ok, res = LauncherMods.installZip(
    "C:/Users/George/Downloads/Pokémon Green Sprites 1.0.1.zip")
  log("installZip -> %s %s", tostring(ok), tostring(res))
  local list = LauncherMods.list()
  log("mods listed: %d", #list)
  for _, m in ipairs(list) do
    log("row id=%s name=%s", tostring(m.id), tostring(m.name))
  end
  out:close()
  love.event.quit()
end
