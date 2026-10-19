--
-- BRIO bricks train
--

color  = require "color"
brio   = require "scad/brio"
common = require "common"

common.setTiming(1/2, 100, 1/5)

v.pre_sdl =  [[
#include "textures.inc"
#include "finish.inc"

#declare F_Wood = finish {
  ambient   0
  diffuse   1
  specular  1
  roughness 0.02 
  reflection { 0,1 fresnel }
}

#declare T_Wood = texture {
  pigment {Tan_Wood} 
  finish { F_Wood }
}

]]

p = Plane(0,1,0,0,1250)
p.col = color.HuntersGreen
p.sdl = [[ pigment { color HuntersGreen } ]]
p.friction = 10
v:add(p)

tex = "texture{ Yellow_Pine rotate y*90 scale 10 }"

b = brio.new({ cmd = "brio_straight(LENGTH/2);", mass = 0  })
b.pos = btVector3(-110,0,0)
b.trans = btTransform(btQuaternion(0,1,0,1), btVector3(320,0,34))
b.friction = 10
b.sdl = tex
v:add(b)

b = brio.new({ cmd = "brio_straight(LENGTH-40);", mass = 0  })
b.pos = btVector3(-110,0,0)
b.trans = btTransform(btQuaternion(0,0,0,1), btVector3(-70,0,0))
b.friction = 10
b.sdl = tex
v:add(b)

c = brio.new({ cmd = "brio_cross(LENGTH/2);", mass = 0 })
c.pos = btVector3(-120,0,-20)
c.friction = 10
c.sdl = "texture{ Yellow_Pine rotate x*90 rotate y*90 scale 10 }"
v:add(c)

bridge1 = brio.new({ cmd = "brio_bridge();", mass = 0  })
bridge1.pos = btVector3(300,0,-40)
bridge1.friction = 10
bridge1.sdl = tex
v:add(bridge1)

bridge2 = brio.new({ cmd = "rotate([0,0,180])brio_bridge();", mass = 0  })
bridge2.pos = btVector3(300,0,0)
bridge2.friction = 10
bridge2.sdl = tex
v:add(bridge2)

tex = "texture{ Yellow_Pine rotate x*90 scale 30 }"

bridge3 = brio.new({ cmd = "brio_curved(ROUND_R, 2);", mass = 0  })
bridge3.trans = btTransform(btQuaternion(0,0,0,1), btVector3(-99,0,-70))
bridge3.friction = 10
bridge3.sdl = tex
v:add(bridge3)

bridge3 = brio.new({ cmd = "brio_curved(ROUND_R, 2);", mass = 0  })
bridge3.trans = btTransform(btQuaternion(0,1,0,0), btVector3(279,0,35))
bridge3.friction = 10
bridge3.sdl = tex
v:add(bridge3)

--------------------------------------------------------------------------------
-- train
--------------------------------------------------------------------------------

-- world space layout of the circuit: a "stadium" loop made of two straights
-- and two half circles of radius R (centerline of the grooves)
local R      = 209.35                     -- ROUND_R + WIDTH/2
local CX     = 90                         -- arc centers
local Z_BOT  = -70
local Z_TOP  = 35
local STR    = Z_TOP - Z_BOT              -- straight section length
local ARC    = math.pi * R                -- half circle length
local LOOP   = 2 * STR + 2 * ARC          -- total length of one lap
local RAIL_Y = 12.4                       -- top of the rails (HEIGHT)

-- position + heading of a point at distance d along the loop,
-- starting on the right hand straight, going counter clockwise
local function rails(d)
  d = d % LOOP
  if d < STR then
    -- right straight, running towards -z
    return CX + R, Z_TOP - d, math.pi / 2
  end
  d = d - STR
  if d < ARC then
    -- lower arc, center (CX, Z_BOT), from (CX+R, Z_BOT) to (CX-R, Z_BOT)
    local a = -d / R
    return CX + R * math.cos(a), Z_BOT + R * math.sin(a),
           math.atan2(math.cos(a), math.sin(a))
  end
  d = d - ARC
  if d < STR then
    -- left straight, running towards +z
    return CX - R, Z_BOT + d, -math.pi / 2
  end
  d = d - STR
  -- upper arc, center (CX, Z_TOP), from (CX-R, Z_TOP) to (CX+R, Z_TOP)
  local a = math.pi - d / R
  return CX + R * math.cos(a), Z_TOP + R * math.sin(a),
         math.atan2(math.cos(a), math.sin(a))
end

-- put a car on the rails at distance d along the loop
local function ride(car, d)
  local x, z, yaw = rails(d)
  car.trans = btTransform(btQuaternion(btVector3(0, 1, 0), yaw),
                          btVector3(x, RAIL_Y, z))
end

-- wooden loco
local LOCO = [==[
// wooden loco: boxy boiler, cab and two pairs of wheels
// model x -> world -z, y -> world y, z -> world x
union() {
  // wheels, sunk into the body so only the lower part sticks out
  for (p = [ [16, -8], [16, 8], [-16, -8], [-16, 8] ])
    translate([p[0], 0, p[1]])
      cylinder(h = 5, r = 7.5, $fn = 24, center = true);
  // chassis
  translate([0, 5.5, 0]) cube([66, 13, 24], center = true);
  // boiler, a cylinder running along the length of the loco
  translate([9, 17.5, 0]) rotate([90, 0, 0])
    cylinder(h = 44, r = 9.5, $fn = 32, center = true);
  translate([31, 17.5, 0]) sphere(r = 9.5, $fn = 24);
  // chimney
  translate([23, 26, 0]) cylinder(h = 10, r = 3.5, $fn = 20, center = true);
  translate([23, 30.5, 0]) cylinder(h = 3, r = 5, $fn = 20, center = true);
  // cab
  translate([-20, 19, 0]) cube([24, 20, 26], center = true);
  // roof
  translate([-20, 30, 0]) cube([28, 4, 30], center = true);
  // coupling pegs
  for (p = [ 36, -36 ])
    translate([p, 5, 0]) cylinder(h = 6, r = 3, $fn = 16, center = true);
}
]==]

-- wooden wagon
local WAGON = [==[
// wooden wagon: open box on four wheels
union() {
  // wheels, sunk into the body so only the lower part sticks out
  for (p = [ [14, -8], [14, 8], [-14, -8], [-14, 8] ])
    translate([p[0], 0, p[1]])
      cylinder(h = 5, r = 7.5, $fn = 24, center = true);
  // chassis
  translate([0, 5.5, 0]) cube([50, 13, 24], center = true);
  // sides of the wagon
  translate([0, 13, 11.5]) cube([46, 12, 3], center = true);
  translate([0, 13, -11.5]) cube([46, 12, 3], center = true);
  translate([21.5, 13, 0]) cube([3, 12, 26], center = true);
  translate([-21.5, 13, 0]) cube([3, 12, 26], center = true);
  // load: a couple of wooden planks
  translate([0, 19, 0]) cube([44, 4, 22], center = true);
  // coupling pegs
  for (p = [ 28, -28 ])
    translate([p, 5, 0]) cylinder(h = 6, r = 3, $fn = 16, center = true);
}
]==]

local loco = OpenSCAD(LOCO, 0)
loco.sdl = "texture{ T_Wood }"
loco.col = "#c9a06a"
loco.collides = false
v:add(loco)

-- the loco pulls a row of identical wagons, 62 units apart, so the
-- coupling pegs of neighbouring cars meet
local cars = { { loco, 0 } }
for i = 1, 4 do
  local wagon = OpenSCAD(WAGON, 0)
  wagon.sdl = tex
  wagon.col = "#b5854f"
  wagon.collides = false
  v:add(wagon)
  cars[#cars + 1] = { wagon, -62 * i }
end

-- the cars are placed by hand every frame
local SPEED = 3                            -- units per frame

local function runTrain(d)
  for i = 1, #cars do
    ride(cars[i][1], d + cars[i][2])
  end
end

runTrain(0)
v:preSim(function(N)
  runTrain(N * SPEED)
end)

common.setCamera(btVector3(-650, 1000, 860), btVector3(90, 20, -15))

v:preDraw(function(N)
--  v.cam.up   = btVector3(0,1,0)
--  v.cam.pos  = btVector3(2002,130,1700)
--  v.cam.look = b.pos - btVector3(0,-0.5,0)
end)

