--
-- House collapse
--

v.timeStep      = 1/5
v.maxSubSteps   = 10
v.fixedTimeStep = 1/70

v.pre_sdl = [[

#include "textures.inc"

#declare tbrick1 = texture{
  pigment{
    gradient <0,1,0>
    color_map {
      [0.0 color White ]
      [0.03 color rgb<0.8,0.25,0.1>]
      [1.0 color rgb<0.8,0.2,0.09>]
    }
    translate y*0.045
  }
  normal { wrinkles 0.75 scale 0.01}
  finish { diffuse 0.9 phong 0.2}
};

#declare tbrick2 = texture{
  pigment{
    gradient <0,1,0>
    color_map {
      [0.0 color White ]
      [0.03 color rgb<0.8,0.25,0.1>]
      [1.0 color rgb<0.8,0.2,0.09>]
    }
    translate y*0.045
  }
  normal { wrinkles 0.75 scale 0.01}
  finish { diffuse 0.9 phong 0.2}
};
]]

v.gravity = btVector3(0,-9.81,0)

plane = Plane(0,1,0,0,1000)
plane.pos = btVector3(0,1,0)
plane.col = "#222"
plane.friction = 10
v:add(plane)

v:preStart(function(N) 
  print("preStart("..tostring(N)..")")
end)

v:preStop(function(N) 
  print("preStop("..tostring(N)..")")
end)

function cubex(px, py, pz)
  c = Cube(2,1,1,.0001)
  c.pos = btVector3(px,py-0.05,pz)
  c.col = "#ff0000"
  c.sdl = [[
    texture { tbrick1 }
  ]]
  v:add(c)
end

function cubez(px, py, pz)
  c = Cube(1,1,2,.001)
  c.pos = btVector3(px,py-0.05,pz)
  c.col = "#ff0000"
  c.sdl = [[
    texture { tbrick2 }
  ]]
  v:add(c)
end

dy = 0.995

function wallx(h,px,py,pz)
for i = 0,19 do
  for j = 0,h do
    cubex(px+i*2-0.05,py+dy*j*2+dy,pz)
    cubex(px+i*2+1,py+dy*(j+1)*2,pz)
  end
end
end

function wallz(h,px,py,pz)
for i = 0,20 do
  for j = 0,h do
    cubez(px+0*2+1.5,py+dy*j*2+2,pz+i*2-0.7)
    if (i < 20) then
      cubez(px+0*2+1.5,py+dy*(j+1)*2-dy,pz+i*2-0)
    end
  end
end
end

function wallz2(h,px,py,pz)
for i = -1,19 do
  for j = 0,h do
    lz = 1
    if (i >= 0) then
    cubez(px+0*2+1.5,py+dy*j*2+2,pz+i*2-0.7+lz)
    end
    if (i < 20) then
      cubez(px+0*2+1.5,py+dy*(j+1)*2-dy,pz+i*2-0+lz)
    end
  end
end
end

function house(h,x, z)
  wallx(h,x+2*0,0,z+0.75)
  wallz(h,x+2*-1,0,z+1.25*1+1)
  wallx(h,x+2*0,0, z+1.2*1+1*41)
  wallz2(h,x+2*19,0,z+1.25*1+1)
end

h = 8

--house(h-2, -4,-2.5)
--house(h+6, -4, 2.5)
house(h, -4, 9)

--house(h+2,4,-2.5)
--house(h-2,4, 2.5)
--house(h+3,4, 9)

function run()
  s = Sphere(2,2)
  s.pos = btVector3(-80,3,30)
  s.vel = btVector3(30,20,2)
  v:add(s)
  s = Sphere(2,2)
  s.pos = btVector3(-55,20,25)
  s.vel = btVector3(40,2,0)
  v:add(s)
end

run()

v.cam:setHorizontalFieldOfView(0.15)

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

v.cam:setUpVector(btVector3(0,1,0), false)
v.cam:setHorizontalFieldOfView(0.15)
v.cam.pos  = btVector3(500,400,700)
v.cam.look = btVector3(20,0,0) 

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
