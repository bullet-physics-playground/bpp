-- BPP_USER_DIR (src/appenv.h): with it set, as the harness sets it for
-- every run, v:dataDir() is its data/ folder, and v:savePrefs writes to its
-- bpp.ini (on the Viewer's preference thread, so this waits for the file).
-- The harness also fails any run that writes where bpp would without it.

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

-- (Windows: the harness gives backslashes, Qt gives forward slashes)
local function slashes(p)
  return p and (p:gsub("\\", "/"))
end

local user = slashes(os.getenv("BPP_USER_DIR"))
assert_eq("BPP_USER_DIR is set", user ~= nil, true)

if user then
  assert_eq("dataDir", slashes(v:dataDir()), user .. "/data")

  v:savePrefs("userDirTest", "written")
  assert_eq("loadPrefs", v:loadPrefs("userDirTest", "missing"), "written")

  local found = false
  local start = os.clock()
  while not found and os.clock() - start < 5 do
    local f = io.open(user .. "/bpp.ini", "r")
    if f then
      found = f:read("*a"):find("userDirTest=written", 1, true) ~= nil
      f:close()
    end
  end
  assert_eq("savePrefs reaches bpp.ini", found, true)
end

print(string.format("\n%d passed, %d failed", pass, fail))
