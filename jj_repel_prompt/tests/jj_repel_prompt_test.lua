-- Standalone: luajit mods/jj_repel_prompt/tests/jj_repel_prompt_test.lua
-- Drives the wear-off flow through the public events: world.stepped arms
-- the prompt, screen.popped on the engine's textbox opens it. The engine
-- counts the Repel down between those two, so the tests do the same.
package.path = "./?.lua;./?/init.lua;" .. package.path
love = love or require("tests.love_stub")

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local Data = require("src.core.Data")
Data:load()

local Font = require("src.render.Font")
Font.load(Data)

local TextBox = require("src.render.TextBox")

local run = T.sdk.loadMod("mods/jj_repel_prompt", { data = Data })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local function newGame()
  local stack = { states = {} }
  function stack:push(s) self.states[#self.states + 1] = s end
  function stack:pop() return table.remove(self.states) end
  function stack:top() return self.states[#self.states] end
  return {
    data = Data,
    stack = stack,
    save = { repelSteps = 1, inventory = { SUPER_REPEL = 1, MAX_REPEL = 3 },
             player = { name = "RED" } },
  }
end

-- one wear-off step: arm on the step, count down, show and close the box
local function wearOff(g)
  Runtime.emit("game.ready", { game = g })
  Runtime.emit("world.stepped", {})
  g.save.repelSteps = 0 -- the engine's own decrement
  local box = TextBox.new(g, "REPEL's effect\nwore off.")
  g.stack:push(box)
  Runtime.emit("screen.popped", { state = g.stack:pop() })
end

-- the wear-off box closing opens the YES/NO prompt
local game = newGame()
wearOff(game)
local prompt = game.stack:top()
T.check(prompt and getmetatable(prompt) == TextBox,
  "a prompt follows the wear-off box")
T.check(prompt.choice ~= nil, "the prompt offers YES/NO")

-- YES spends the weakest repel in the bag, not the strongest
prompt.choice(true)
T.eq(game.save.repelSteps, 200, "SUPER REPEL re-applies before MAX REPEL")
T.eq(game.save.inventory.SUPER_REPEL, nil, "the spent repel leaves the bag")
T.eq(game.save.inventory.MAX_REPEL, 3, "stronger repels are untouched")
T.check(getmetatable(game.stack:top()) == TextBox,
  "the used-item text shows after YES")

-- NO leaves the save alone
game = newGame()
wearOff(game)
prompt = game.stack:top()
prompt.choice(false)
T.eq(game.save.repelSteps, 0, "NO does not re-apply a repel")
T.eq(game.save.inventory.SUPER_REPEL, 1, "NO leaves the bag alone")

-- an empty bag means no prompt, matching Gen 2
game = newGame()
game.save.inventory = {}
wearOff(game)
T.eq(game.stack:top(), nil, "no repels in the bag, no prompt")

-- a textbox closing with steps still on the counter is not the wear-off
game = newGame()
game.save.repelSteps = 5
Runtime.emit("game.ready", { game = game })
Runtime.emit("world.stepped", {})
game.stack:push(TextBox.new(game, "Some unrelated\ntext."))
Runtime.emit("screen.popped", { state = game.stack:pop() })
T.eq(game.stack:top(), nil, "no prompt while the counter is above one")

-- a non-textbox state popping first does not disarm the prompt
game = newGame()
Runtime.emit("game.ready", { game = game })
Runtime.emit("world.stepped", {})
Runtime.emit("screen.popped", { state = { notATextBox = true } })
game.save.repelSteps = 0
game.stack:push(TextBox.new(game, "REPEL's effect\nwore off."))
Runtime.emit("screen.popped", { state = game.stack:pop() })
T.check(game.stack:top() and game.stack:top().choice ~= nil,
  "an unrelated pop does not disarm the wear-off prompt")

run.release()
T.finish("jj_repel_prompt")
