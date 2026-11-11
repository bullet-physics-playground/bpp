-- Scene parameters (v:addParam): each value parameter is mirrored into a Lua
-- global of its name, which getParam() reads back (so a script that changes
-- the global changes the parameter); onParamChanged hears of every value
-- parameter added, sliders included, but not of push buttons or button rows;
-- a slider's value survives the trip through the global (as a float, so
-- 0.12 comes back as 0.1199999...); and getParams() gives the values in a
-- table (a push button, which has no value, isn't in it).

local pass = 0
local fail = 0

local function assert_near(name, got, expected)
  if type(got) == "number" and math.abs(got - expected) < 1e-6 then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local function assert_eq(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local heard = {}
v:onParamChanged(function(N, name, value)
  heard[#heard + 1] = name .. "=" .. tostring(value)
end)

v:addParam("speed", 2.5)
v:addParam("title", "hello", "a text cell")
v:addParam("enabled", true, "a check box")
v:addParam("rate", 0.12, 0, 1, 0.01, "a slider")
v:addParam("go", function() end, "a push button")
v:addParam("row", { a = function() end, b = function() end }, "a row of buttons")

-- mirrored into Lua globals
assert_eq("number global", speed, 2.5)
assert_eq("string global", title, "hello")
assert_eq("boolean global", enabled, true)
assert_near("slider global keeps its fraction", rate, 0.12)
assert_eq("no global for a button", go, nil)
assert_eq("no global for a button row", row, nil)

-- read back
assert_eq("getParam number", v:getParam("speed"), 2.5)
assert_eq("getParam string", v:getParam("title"), "hello")
assert_eq("getParam boolean", v:getParam("enabled"), true)
assert_near("getParam slider", v:getParam("rate"), 0.12)

-- the global is the parameter: a script that changes it changes the value
speed = 7
assert_eq("getParam follows the global", v:getParam("speed"), 7)

-- onParamChanged: every value parameter, in order, not the buttons
assert_eq("hook heard four", #heard, 4)
assert_eq("hook 1", heard[1], "speed=2.5")
assert_eq("hook 2", heard[2], "title=hello")
assert_eq("hook 3", heard[3], "enabled=true")
assert_eq("hook 4", string.sub(heard[4], 1, 9), "rate=0.11")

-- adding a parameter again gives it the new value, and is heard
v:addParam("speed", 3.5)
assert_eq("re-added global", speed, 3.5)
assert_eq("re-added heard", heard[5], "speed=3.5")

-- getParams: the values in a table
local all = v:getParams()
assert_eq("getParams is a table", type(all), "table")
assert_eq("getParams number", all.speed, 3.5)
assert_eq("getParams string", all.title, "hello")
assert_eq("getParams boolean", all.enabled, true)
assert_near("getParams slider", all.rate, 0.12)
assert_eq("getParams leaves out a button", all.go, nil)

print(string.format("\n%d passed, %d failed", pass, fail))
