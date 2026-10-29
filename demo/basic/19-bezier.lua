--
-- BezierPatch primitive demo
--
-- Demonstrates the BezierPatch primitive (bicubic surface, new primitive type from Moray integration).
--
-- Usage: bpp -f demo/basic/bezier-demo.lua

local common = require "common"

common.setTiming(1/30)

-- Ground plane
plane = Plane(0,1,0,0,500)
plane.col = "#224422"
v:add(plane)

-- Flat Bezier patch
bp1 = BezierPatch(4)
bp1.col = "#ff6600"
bp1.pos = btVector3(-6, 4, 0)
v:add(bp1)

-- Curved Bezier patch - hill shape (set control points individually)
bp2 = BezierPatch(4)
bp2.col = "#00ffff"
bp2.pos = btVector3(0, 2, 0)
for i = 0, 3 do
  for j = 0, 3 do
    local x = (i - 1.5) * 2
    local z = (j - 1.5) * 2
    local y = math.sin(i * math.pi / 3) * math.cos(j * math.pi / 3) * 2
    bp2:setControlPoint(i, j, btVector3(x, y, z))
  end
end
bp2:rebuild()
v:add(bp2)

-- Another curved patch - saddle
bp3 = BezierPatch(4)
bp3.col = "#ff00ff"
bp3.pos = btVector3(6, 4, 0)
for i = 0, 3 do
  for j = 0, 3 do
    local x = (i - 1.5) * 2
    local z = (j - 1.5) * 2
    local y = (x * x - z * z) * 0.3
    bp3:setControlPoint(i, j, btVector3(x, y, z))
  end
end
bp3:rebuild()
v:add(bp3)

common.setCamera(btVector3(20, 15, 20), btVector3(0, 4, 0), math.rad(45))
