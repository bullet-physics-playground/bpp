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

local function assert_contains(name, haystack, needle)
  if string.match(haystack, needle) then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": haystack='" .. haystack .. "' missing needle='" .. needle .. "'")
    fail = fail + 1
  end
end

local c = require "color"

assert_eq("color module red", c.red, "#ff0000")
assert_match("color module is table", type(c), "table")

-- Test package.path contains expected paths
local fullPath = package.path

-- CLI mode: path should contain the bpp checkout's demo/module (whatever
-- the checkout's folder is called)
assert_contains("cli path contains demo/module", fullPath, "/demo/module/")

-- GUI mode (if running from bpp dir): path should work from any directory
-- The exact path depends on whether running from bpp/ or release/ subdir
print("package.path = " .. fullPath)

print(string.format("\n%d passed, %d failed", pass, fail))