-- test Mesh class: constructor and loadFile

local pass = 0
local fail = 0

local function assert_eq(name, got, expected, tol)
  tol = tol or 0.001
  if math.abs(got - expected) > tol then
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
    return
  end
  print("PASS " .. name)
  pass = pass + 1
end

local function assert_nil(name, got)
  if got ~= nil then
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=nil")
    fail = fail + 1
    return
  end
  print("PASS " .. name)
  pass = pass + 1
end

local function assert_not_nil(name, got)
  if got == nil then
    print("FAIL " .. name .. ": got=nil expected=not nil")
    fail = fail + 1
    return
  end
  print("PASS " .. name)
  pass = pass + 1
end

-- test default constructor
local m = Mesh()
assert_not_nil("Mesh() default constructor", m)
assert_not_nil("Mesh() default shape", m.shape)

-- test constructor with invalid file - should throw a Lua error
local ok, err = pcall(Mesh, "nonexistent/file.3ds", 10)
if ok then
  print("FAIL Mesh with invalid file should have thrown")
  fail = fail + 1
else
  print("PASS Mesh with invalid file throws error")
  pass = pass + 1
end

-- test constructor with valid 3ds file
local m3 = Mesh("demo/mesh/testbed.3ds", 0)
assert_not_nil("Mesh with valid file has shape", m3.shape)

print(string.format("\n%d passed, %d failed", pass, fail))