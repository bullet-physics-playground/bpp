--
-- CSG (Constructive Solid Geometry) demo
--
-- Demonstrates CSG operations: union, difference, intersection with OpenGL
-- stencil buffer rendering. Objects overlap so the boolean results are
-- visually distinct.
--
-- Usage: bpp -f demo/basic/20-csg.lua

local common = require "common"

common.setTiming(1/30)

-- CSG operation codes
CSG_UNION = 0
CSG_DIFFERENCE = 1
CSG_INTERSECTION = 2

-- Ground plane
plane = Plane(0,1,0,0,500)
plane.col = "#224422"
plane.collides = true
v:add(plane)

-- Base objects positioned to overlap (centered at origin)
box1 = Cube(2, 2, 2, 1)
box1.pos = btVector3(0, 0, 0)
box1.col = "#888888"
box1.collides = false
v:add(box1)

sphere1 = Sphere(1.5, 2)
sphere1.pos = btVector3(0, 0, 0)
sphere1.col = "#aaaaaa"
sphere1.collides = false
v:add(sphere1)

-- CSG union: box + sphere (red) - positioned left
node1 = CsgNode(box1)
node2 = CsgNode(sphere1)
root1 = CsgNode(CSG_UNION, node1, node2)
unionObj = CsgObject(root1, 1)
unionObj.pos = btVector3(-8, 4, 0)
unionObj.col = "#ff0000"
unionObj.collides = true
v:add(unionObj)

-- CSG difference: box - sphere (green) - positioned center
node3 = CsgNode(box1)
node4 = CsgNode(sphere1)
root2 = CsgNode(CSG_DIFFERENCE, node3, node4)
diffObj = CsgObject(root2, 1)
diffObj.pos = btVector3(0, 4, 0)
diffObj.col = "#00ff00"
diffObj.collides = true
v:add(diffObj)

-- CSG intersection: box * sphere (blue) - positioned right
node5 = CsgNode(box1)
node6 = CsgNode(sphere1)
root3 = CsgNode(CSG_INTERSECTION, node5, node6)
interObj = CsgObject(root3, 1)
interObj.pos = btVector3(8, 4, 0)
interObj.col = "#0000ff"
interObj.collides = true
v:add(interObj)

-- CSG union of three: box + sphere + cylinder (orange) - positioned back
cyl1 = Cylinder(1, 2, 2)
cyl1.pos = btVector3(0, 0, 0)
cyl1.col = "#cccccc"
cyl1.collides = false
v:add(cyl1)

node7 = CsgNode(box1)
node8 = CsgNode(sphere1)
node9 = CsgNode(cyl1)
innerUnion = CsgNode(CSG_UNION, node7, node8)
root4 = CsgNode(CSG_UNION, innerUnion, node9)
multiObj = CsgObject(root4, 1)
multiObj.pos = btVector3(0, 8, 0)
multiObj.col = "#ff8800"
multiObj.collides = true
v:add(multiObj)

-- Camera positioned to see all CSG results
common.setCamera(btVector3(20, 15, 15), btVector3(0, 4, 0), math.rad(45))
