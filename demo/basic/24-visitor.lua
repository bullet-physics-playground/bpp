--
-- Visitor pattern demo (Moray-style)
--
-- Demonstrates the visitor pattern for scene graph traversal:
-- StatisticsVisitor (count objects by type), FindObjectVisitor (find by name),
-- and Object::accept() traversal of parent/child scene graphs.
--
-- Usage: bpp -f demo/basic/24-visitor.lua

local common = require "common"

common.setTiming(1/30)

-- Build a scene graph: parent group with children
-- parent: Cube at (-6, 3, 0)
--   child1: Sphere at (0, 3, 0)
--   child2: Cube at (6, 3, 0)
--   child3: Sphere at (-3, 6, 0)
--   child4: Torus at (3, 6, 0)

parent = Cube(2, 2, 2, 1)
parent.pos = btVector3(-6, 3, 0)
parent.col = "#ff0000"

child1 = Sphere(1.5, 2)
child1.pos = btVector3(0, 3, 0)
child1.col = "#00ff00"
parent:addChild(child1)

child2 = Cube(1, 1, 1, 1)
child2.pos = btVector3(6, 3, 0)
child2.col = "#0000ff"
parent:addChild(child2)

child3 = Sphere(0.5, 2)
child3.pos = btVector3(-3, 6, 0)
child3.col = "#ffff00"
parent:addChild(child3)

child4 = Torus(0.5, 1.5, 2)
child4.pos = btVector3(3, 6, 0)
child4.col = "#ff00ff"
parent:addChild(child4)

-- StatisticsVisitor: count objects by type (Moray CStatisticsVisitor style)
local stats = StatisticsVisitor()
parent:accept(stats)
print("=== StatisticsVisitor ===")
print("  total:      " .. stats.total)
print("  lights:     " .. stats.lights)
print("  primitives: " .. stats.primitives)
print("  groups:     " .. stats.groups)
print("  realObjs:   " .. stats.realObjects)

-- FindObjectVisitor: find first object matching name (Moray CFindObjectVisitor style)
local finder = FindObjectVisitor("Cube")
parent:accept(finder)
print("=== FindObjectVisitor ===")
print("  found Cube:    " .. tostring(finder.found ~= nil))

-- FindObjectVisitor that should not match
local finder2 = FindObjectVisitor("NonExistent")
parent:accept(finder2)
print("  found NonExistent: " .. tostring(finder2.found ~= nil))

-- Verify scene graph structure
print("=== Scene Graph ===")
print("  parent children: " .. parent:getNumChildren())

common.setCamera(btVector3(20, 15, 15), btVector3(0, 4, 0), math.rad(45))
