--
-- Visitor pattern test (Moray-style)
--
-- Tests StatisticsVisitor, FindObjectVisitor, and Object::accept()
-- traversal of the scene graph.
--
-- Usage: bpp -f tests/10-visitor.lua

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

local function assert_true(name, cond)
  if cond then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": condition was false")
    fail = fail + 1
  end
end

-- Create objects without adding to viewer (avoid physics world side effects)
local root = Cube(2, 2, 2, 1)
root.pos = btVector3(0, 5, 0)
root.col = "#ff0000"

local child1 = Sphere(1, 2)
child1.pos = btVector3(0, 0, 0)
child1.col = "#00ff00"
root:addChild(child1)

local child2 = Cube(1, 1, 1, 1)
child2.pos = btVector3(0, 0, 0)
child2.col = "#0000ff"
root:addChild(child2)

local child3 = Sphere(0.5, 2)
child3.pos = btVector3(0, 0, 0)
child3.col = "#ffff00"
root:addChild(child3)

-- Test Object::getNumChildren
assert_eq("root has 3 children", root:getNumChildren(), 3)

-- Test Object::getChild
assert_true("child[0] is child1", root:getChild(0) == child1)
assert_true("child[1] is child2", root:getChild(1) == child2)
assert_true("child[2] is child3", root:getChild(2) == child3)
assert_true("child[3] is nil", root:getChild(3) == nil)

-- Test StatisticsVisitor via accept() (Moray CStatisticsVisitor style)
local stats = StatisticsVisitor()
root:accept(stats)
assert_eq("stats total = 4", stats.total, 4)
assert_true("stats primitives > 0", stats.primitives > 0)

-- Test FindObjectVisitor via accept() (Moray CFindObjectVisitor style)
local finder = FindObjectVisitor("Sphere")
root:accept(finder)
assert_true("finder.found is not nil", finder.found ~= nil)

-- Test FindObjectVisitor that should not match
local finder2 = FindObjectVisitor("NonExistent")
root:accept(finder2)
assert_true("finder2.found is nil", finder2.found == nil)

print(string.format("\n%d passed, %d failed", pass, fail))