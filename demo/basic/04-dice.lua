--
-- Dice
--

require "module/color"
require "module/dice"

v.pre_sdl = [==[

#include "finish.inc"
#include "textures.inc"
#include "dice.inc"

]==]

p = Plane(0,1,0,0,10)
p.col = "#fff"
p.friction = 100
p.sdl = [[ texture { pigment { color White } }]]
v:add(p)

txt = OpenSCAD([[
  text = "Bullet Physics Playground";
  font = "Arial";
  linear_extrude(height = 2) {
    text(
      text = text, font = font,
      size = 1, halign = "center");
  }]],0)
txt.pos = btVector3(0,7.5,-1)
txt.col = "#000000"
txt.post_sdl = [[
  no_shadow
  no_reflection
  no_radiosity
}]]

v:add(txt)

function run()
  d = dice.new({ mass = 10, col = color.random_google() })
  d.friction = 100
  d.pos=btVector3(0,0.75,0)
  v:add(d)
end

run()run()

v:postSim(function(N)
  if (N % 5 == 0 and N < 1000) then
    run()
  end

  c = 1
  i = math.sin(N/100)*c
  j = math.cos(N/100)*c
  v.gravity = btVector3(i,-c,j)

end)

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

v.cam:setFieldOfView(0.025)

v.cam:setUpVector(btVector3(0,1,0), true)
--v.cam.pos  = btVector3(1,4,900)
v.cam.pos  = btVector3(0, 6, 550)
v.cam.look = btVector3(0,4,0)

--v.cam.focal_blur      = 10
v.cam.focal_aperture  = 5
--- set blur point to XXX shape position
v.cam.focal_point = txt.pos
