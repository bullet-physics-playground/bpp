-- Button groups: a table of functions passed to v:addParam() renders as one
-- row of push buttons in the parameters panel; clicking one invokes its
-- function. Named keys label the buttons; a positional table numbers them.
-- A button group holds no value, so it is neither mirrored as a Lua global
-- nor reported to onParamChanged, and ordinary parameters keep working next
-- to it. (Headless mode cannot click the buttons, so this test covers
-- registration and coexistence; the GUI invocation is covered by the C++
-- harness.)

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

local function assert_match(name, got, pattern)
  if string.match(got, pattern) then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected pattern=" .. pattern)
    fail = fail + 1
  end
end

-- Named keys -> labelled buttons.
function do_reset() end
function do_step() end
function do_clear() end

v:addParam("controls", { reset = do_reset, step = do_step, clear = do_clear },
           "a row of buttons")

-- Positional table -> numbered buttons.
v:addParam("actions", { function() end, function() end },
           "numbered buttons")

-- The groups are stored as their tables.
assert_match("named group is a table", type(v:getParam("controls")), "table")
assert_match("positional group is a table", type(v:getParam("actions")), "table")

-- Ordinary parameters still work beside a button group.
v:addParam("speed", 0.5, 0, 1, 0.1, "slider beside the buttons")
assert_eq("slider kept its value", v:getParam("speed"), 0.5)

print(string.format("\n%d passed, %d failed", pass, fail))
