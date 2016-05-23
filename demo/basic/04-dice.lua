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

function text(t, x, y, z)
  t = OpenSCAD([[
  text = "]]..t..[[";
  font = "Arial";
  linear_extrude(height = 2) {
    text(
      text = text, font = font,
      size = 1, halign = "center");
  }]],0)
t.pos = btVector3(x,y,z)
t.col = "#ffffff"
t.post_sdl = [[
  no_shadow
  no_reflection
  no_radiosity
}]]
v:add(t)
return t
end

txt = text("Bullet Physics Playground", 0,8.4,-1)
text("Version 0.0.3 (WIP)", 0,6.6,-1)

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
--- set blur point to txt shape position
v.cam.focal_point = txt.pos
