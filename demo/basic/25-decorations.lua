--
-- Decorations demo
--
-- A decoration (o.decoration = true before v:add) is only drawn and
-- exported: Bullet never steps it, nothing collides with it, and the mouse
-- never picks it. v:attach(o, parent) makes it follow a body, keeping the
-- offset it had when attached; v:detach(o) leaves it where it is.
--
-- Here a cube tumbles down a ramp carrying a flag pole, a flag and corner
-- dots, none of which touch anything. A ghost wall of decorations stands
-- in its path and the cube rolls straight through it.
--
-- Usage: bpp -f demo/basic/25-decorations.lua
--

local tilt = btQuaternion(btVector3(0, 0, 1), -0.35)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#7f8c8d"
v:add(plane)

local ramp = Cube(8, 0.4, 4, 0)
ramp.col = "#95a5a6"
ramp.trans = btTransform(tilt, btVector3(-3, 2, 0))
v:add(ramp)

-- the cube starts upright at the origin, so its decorations are easy to place
local cube = Cube(1, 1, 1, 1)
cube.col = "#e67e22"
v:add(cube)

local function decoration(o, col, pos, parent)
  o.decoration = true
  o.col = col
  o.pos = pos
  v:add(o)
  if parent then v:attach(o, parent) end
  return o
end

-- a pole on the cube, and a flag on the pole (a decoration following a decoration)
local pole = Cylinder(0.04, 1.2, 0)
pole.decoration = true
pole.col = "#2c3e50"
pole.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(0, 1.1, 0))
v:add(pole)
v:attach(pole, cube)
decoration(Cube(0.5, 0.3, 0.02, 0), "#c0392b", btVector3(0.27, 1.55, 0), pole)

-- a dot on each top corner
for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
  decoration(Sphere(0.08, 0), "#f1c40f", btVector3(c[1] * 0.5, 0.5, c[2] * 0.5), cube)
end

-- now put the cube on the ramp: everything attached goes with it
cube.trans = btTransform(tilt, btVector3(-6, 4.2, 0))

-- a ghost wall the cube rolls through
for i = 0, 4 do
  local w = decoration(Cube(0.2, 1.5, 0.8, 0), "#3498db", btVector3(3, 0.75, i * 0.8 - 1.6))
  w.transparency = 0.5
end

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 6, 14)
v.cam.look = btVector3(0, 1.5, 0)
