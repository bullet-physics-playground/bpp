--
-- Dominos
--

v.pre_sdl = [[

#include "textures.inc"

]]

plane = Plane(0,1,0,0,100)
plane.col = "#333333"
plane.friction = 2

-- v.gravity = btVector3(0,0,0)

v.timeStep      = 1/5
v.fixedTimeStep = v.timeStep / 4
v.maxSubSteps   = 10

if (use_lightsys == 1) then
  plane.sdl = [[
  pigment { rgb ReferenceRGB(Gray20) }
]]
else
  plane.sdl = [[
  pigment { rgb <0.2,0.2,0.2> }
]]
end


v:add(plane)

function line(N,zpos,damp_lin,damp_ang,fri,res)
  local s = Sphere(1,5)
  s.pos = btVector3(-15, 1.5, zpos)
  s.col = "#ffffff"
  s.vel = btVector3(5,0,0)
  s.sdl = [[
  texture { Polished_Chrome }
]]


  v:add(s)

  local d_end

  for i = 5,N do
    local d = Cube(0.4,3,1.5, 1)
    d.pos = btVector3(i*2, 1.5, zpos)
    d.col = "#cccccc"

    d.friction = fri
    d.restitution = res

    d.damp_lin = damp_lin
    d.damp_ang = damp_ang

    v:add(d)

    if (i == N / 2) then
      d_end = d
    end
  end

  return s,d_end
end

n = 16

line(n, -3, 0.01, 0.01, 0.1, 0.1)
s,d = line(n,  0, 0.01,  0.01,  0.2, 0.2)
line(n,  3, 0.01,  0.01,  0.3, 0.3)
line(n,  6, 0.1,  0.01,  0.4, 0.4)

v:preDraw(function(N) --print(N)
  v.cam:setHorizontalFieldOfView(0.8)

  if (N < 50) then
    --v.cam.up = btVector3(0,1,0)
    v.cam.pos  = d.pos + btVector3(-45+N,20,45)
    v.cam.look = d.pos + btVector3(-29+N*0.7,1,0)
  end
end)
