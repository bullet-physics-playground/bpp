--
-- Demo of the SoftBody class (a Bullet cloth patch)
--
-- This demo shows the basic usage of SoftBody:
--   * creating a rectangular cloth patch and dropping it onto a rigid
--     obstacle and the ground, so it drapes and deforms on collision
--   * pinning selected corners of a patch in place (the "fixeds" bitmask)
--     to make a flag that waves in a constant wind force
--   * reading/writing the soft-body-specific properties (mass, stiffness,
--     damping, pos) and calling :addForce(), :translate(), :rotate()
--
-- Usage: bpp -f demo/basic/16-softbody.lua
--

local color = require "color"

v.timeStep      = 1/25
v.maxSubSteps   = 30
v.fixedTimeStep = 1/120

--
-- SCENE SETUP
--

-- Ground plane
p = Plane(0,1,0,0,20)
p.col = color.darkgray
v:add(p)

-- A static box for the falling cloth to drape over
box = Cube(2,1,2,0) -- 2x1x2, mass 0 => static
box.pos = btVector3(0, 0.5, 0)
box.col = color.steelblue
v:add(box)

-- A cloth patch, dropped flat above the box.
-- SoftBody(width, height, resX, resY, mass, fixeds); fixeds = 0 means all
-- four corners are free, so the whole patch falls under gravity.
cloth = SoftBody(4, 4, 16, 16, 1.5, 0)
cloth.col = color.coral
cloth.stiffness = 0.9  -- [0,1] linear stiffness coefficient of the links
cloth.damping   = 0.05 -- [0,1] velocity damping coefficient
cloth.pos = btVector3(0, 4, 0) -- moves the patch's centroid up above the box
v:add(cloth)

-- A flag: a smaller patch pinned along its left edge (corners 00 and 01,
-- bitmask 1+4=5), rotated upright and waved by a constant wind force
-- applied every simulation step below.
flag = SoftBody(2, 1.2, 10, 6, 0.3, 1 + 4)
flag.col = color.gold
flag:rotate(btQuaternion(btVector3(1,0,0), -math.pi/2)) -- tip from flat to vertical
flag.pos = btVector3(-3, 2, 0) -- pinned edge (local x=-1) ends up at x=-4, by the pole
v:add(flag)

-- A pole for the flag to hang from, purely decorative
pole = Cylinder(0.05, 3, 0)
pole.col = color.darkgray
pole.pos = btVector3(-4, 1.5, 0)
v:add(pole)

-- Camera
v.cam:setFieldOfView(0.5)
v.cam:setUpVector(btVector3(0,1,0), true)
v.cam.pos  = btVector3(8, 5, 9)
v.cam.look = btVector3(0, 1.5, 0)

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart("..tostring(N)..")")
  print("cloth: "..cloth.nodeCount.." nodes, "..cloth.faceCount.." faces, mass="..cloth.mass)
  print("flag:  "..flag.nodeCount.." nodes, "..flag.faceCount.." faces, mass="..flag.mass)
end)

-- preSim: Called before each physics simulation step. Blow a gentle,
-- slightly gusty wind on the flag so it visibly waves without blowing
-- away; SoftBody:addForce(force) adds a uniform force to every node of
-- the patch for this step.
v:preSim(function(N)
  local gust = 0.15 * math.sin(N * 0.2)
  flag:addForce(btVector3(0.8 + gust, 0, 0.3))
end)

-- postSim: Called after each simulation step
v:postSim(function(N)
  v.cam.focal_blur     = 0
  v.cam.focal_aperture = 5
  v.cam.focal_point    = cloth.pos
end)

-- EOF
