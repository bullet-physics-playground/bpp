--
-- Dice
--
color = require "module/color"
dice  = require "module/dice"
text  = require "module/text"

v.timeStep      = 1/5
v.maxSubSteps   = 20
v.fixedTimeStep = 1/120

v.pre_sdl = [==[

#include "finish.inc"
#include "textures.inc"
#include "dice.inc"

]==]

p = Plane(0,1,0,0,10)
p.col = "#050"
p.friction = 100
p.sdl = [[ texture { pigment { color White } }]]
v:add(p)

v:add(text.new({ str = "Bullet Physics Playground",
  size = 1, height = .1, y = 8, z = -2}))
txt = text.new({ str = "version 0.1.0",
  size = 1, height = .1, y = 6, z = -2})
v:add(txt)

function run()
  d = dice.new({ mass = 10, col = "#f00" })
  d.friction = 100
  d.pos=btVector3(0,0.45,0)
  v:add(d)
end

run()run()

v:postSim(function(N)
  if (N % 1 == 0 and N < 10000) then
    run()
  end

  c = 2.5
  i = math.sin(N/100)*c/2
  j = math.cos(N/100)*c/2
--  v.gravity = btVector3(0,-c,0)
  v.gravity = btVector3(i,-c,j)

  tmp = v.cam.pos tmp.z = tmp.z + 0.1 v.cam.pos = tmp
  tmp = v.cam.pos tmp.y = tmp.y + 0.1 v.cam.pos = tmp
  tmp = v.cam.look tmp.y = tmp.y + 0.001 v.cam.look = tmp
end)

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

v.cam:setFieldOfView(0.025)

v.cam:setUpVector(btVector3(0,1,0), false)
--v.cam.pos  = btVector3(1,4,900)
v.cam.pos  = btVector3(0, 4, 550)
v.cam.look = btVector3(0,4,0)

--v.cam.focal_blur      = 10
v.cam.focal_aperture  = 5
--- set blur point to txt shape position
v.cam.focal_point = txt.pos
