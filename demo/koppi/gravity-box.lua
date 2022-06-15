--
-- Omni-directional stereo rendered box with gravity variation
--

-- Notice: POV-Ray export requires the user_defined cam feature

require "module/color"
require "module/colors"
require "module/metal"

-- print(v.glAmbient) --btVector3(1,0,0))

v.glAmbient = 0.3
v.glDiffuse = 0.1
v.glLight0 = btVector4(10,10,10,10)
v.glLight1 = btVector4(10,10,10,10)
v.glSpecular = 0.3
v.glModelAmbient = 0.6

v.timeStep      = 1/10
v.fixedTimeStep = v.timeStep / 2
v.maxSubSteps   = 25

mod_gravity = 1  -- modulate gravity
pov_export  = 0  -- povray export on / off

d  = 100   -- box dimension
x  = 50   -- number of objects
od = 4     -- object dimension

v.gravity = btVector3(0,0,0)

col = "#aaaaaa"

friction = 0
restitution = 0.8
damp_ang = 0.05
damp_lin = 0.05

v.pre_sdl = [[
#include "colors.inc"
#include "textures.inc"
]]

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,0,1), btVector3(0,-d,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)


plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,0,1), btVector3(0,d,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,1,1), btVector3(d,0,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,1,1), btVector3(-d,0,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(1,0,0,1), btVector3(0,0,d))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(1,0,0,1), btVector3(0,0,-d))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin
v:add(plane)


for i = 0,x do
  vel = 10
  vel_ang = 5
  p = d*2-od

if (i > x/2) then
  s = Mesh("demo/mesh/torus.stl",1)
  s.col = color.random_pastel()
  s.vel = btVector3(math.random()*vel-vel/2,
                    math.random()*vel-vel/2,
                    math.random()*vel-vel/2)
  s.post_sdl = "texture { " .. metal.random() .. " } }"
else
  s = Cube(od*2,od*2,od*2,1)
  s.col = color.random_pastel()
  s.ang_vel = btVector3(math.random()*vel_ang-vel_ang/2,
                    math.random()*vel_ang-vel_ang/2,
                    math.random()*vel_ang-vel_ang/2)
  s.post_sdl = "pigment { " .. colors.random() .. " } }"

end

if (math.random() > 0.5) then
else
end

  s.pos = btVector3(math.random()*p - p/2,
                    math.random()*p - p/2,
                    math.random()*p - p/2)

  s.friction = friction
  s.restitution = restitution
  s.damp_ang = damp_ang
  s.damp_lin = damp_lin
  v:add(s)
end

function mod(a, b)
return a - (math.floor(a/b))
end

if (pov_export == 1) then
c = Cam() c.pos = btVector3(0,1,0)

v.pre_sdl = v.pre_sdl .. string.format("\n#declare cam_pos = <%f, %f, %f>;\n", c.pos.x, c.pos.y, c.pos.z)

c.pre_sdl = QString([[

  #declare ods_x     = cam_pos.x;
  #declare ods_y     = cam_pos.y;
  #declare ods_z     = cam_pos.z;
  #declare ods_ipd   =  0.065;    // 0.065 / interpupillary distance
  #declare ods_mod   =  0.2;      // 0.2 / use 0.0001 if you don't care about zenith & nadir zones.
  #declare ods_right =  -1;       // "-1" for left-handed or "1" for right-handed
  #declare ods_angle =  0;        // vertical rotation, clockwise, in degree. 

  camera {
    user_defined
    location {
      function { ods_x + cos(((x+0.5+ods_angle/360)) * 2 * pi - pi)*(ods_ipd/2*pow(sin(select(y, 1-2*(y+0.5), 1-2*y)*pi), ods_mod))*select(-y,-1,+1) }
      function { ods_y }
      function { ods_z + sin(((x+0.5+ods_angle/360)) * 2 * pi - pi)*(ods_ipd/2*pow(sin(select(y, 1-2*(y+0.5), 1-2*y)*pi), ods_mod))*select(-y,-1,+1) * ods_right }
    }
    direction {
      function { sin(((x+0.5+ods_angle/360)) * 2 * pi - pi) * cos(pi / 2 -select(y, 1-2*(y+0.5), 1-2*y) * pi) }
      function { sin(pi / 2 - select(y, 1-2*(y+0.5), 1-2*y) * pi) }
      function { -cos(((x+0.5+ods_angle/360)) * 2 * pi - pi) * cos(pi / 2 -select(y, 1-2*(y+0.5), 1-2*y) * pi) * ods_right }
    }
  }
]])

v:setCam(c)
end

if (pov_export == 1) then
  s = Sphere(5,0)
  s.pre_sdl = [[
sphere { <0,0,0>, 1
pigment{ color rgbt<0,0,0,1> }
no_image no_reflection no_shadow
  ]]
--  s.col = "#ffffff00"
  v:add(s)
end

v:postSim(function(N)

if (mod_gravity == 1) then
--if (mod(N,10) == 0) then
  v.gravity =
    btVector3(math.random()*10-5,
              math.random()*10-5,
              math.random()*10-5)
--  print(v.gravity)
--end
else
  v.gravity = btVector3(0,0,0)
end
end)
