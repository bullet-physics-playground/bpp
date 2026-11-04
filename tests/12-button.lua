-- Push button parameters: a Lua function value passed to v:addParam() is
-- shown as a push button in the parameters panel; pressing it invokes the
-- function. A slider and a check box registered next to it must keep
-- working, i.e. there is no overload confusion between a function value and
-- an ordinary parameter value.

local pass = 0
local fail = 0

local function assert_eq(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local presses = 0
function reset()
  presses = presses + 1
  print("reset pressed #" .. presses)
end

-- These must all parse and register without error.
v:addParam("reset", reset, "Reset the simulation")
v:addParam("count", 0.5, 0, 1, 0.1, "a slider next to the button")
v:addParam("enabled", true, "a check box next to the button")

assert_eq("slider kept its value", v:getParam("count"), 0.5)
assert_eq("checkbox kept its value", v:getParam("enabled"), true)

print(string.format("\n%d passed, %d failed", pass, fail))
