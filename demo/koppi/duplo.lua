--
-- Marble run with Duplo
--
-- http://thingiverse.com/thing:159219
--

require "module/duplo"

v.timeStep      = 1/3
v.maxSubSteps   = 50
v.fixedTimeStep = 1/20

v.pre_sdl = [[

#include "textures.inc"

object {                                                                        
  Light(                                                                        
    EmissiveSpectrum(ES_GE_SW_Incandescent_100w),                               
    Lm_Incandescent_100w,                                                       
    x*50, z*50, 4, 4, on                                                        
  )                                                                             
  translate <0, 290, 150>                                                   
}
]]

p = Plane(0,1,0,0,1000)
p.pos = btVector3(0,-134.5,0)
p.col = "#00ff00"
p.sdl = [[
  pigment { HuntersGreen }
  normal  { quilted scale 2.5 }
]]
v:add(p)

function d(p, rx, ry, rz, px, py, pz, col, mass)
  o = duplo.new({fun="rotate(["..rx..","..ry..","..rz.."])"..p..";", mass = mass})
  o.pos = btVector3(px*16, py*9.6, pz*16)
  o.col = col
  v:add(o)
end

m = 0
red    = "#ff0000"
yellow = "#ff0"
blue   = "#006"
green  = "#3c0"

d("duplo(4,2,2,true,false)", -90,0,0, -1,1,0, blue, m)

d("endPiece()", -90,-90,0, 0,3,0, red, m)
d("rampCornerPiece(steps=30)", -90,-0,0, 2,2,0, green, m)
d("rampCornerPiece(steps=30)", -90,-90,0, 2,0,2, red, m)
d("rampCornerPiece(steps=30)", -90,-180,0, 0,-2,2, yellow, m)

d("cornerPiece()", -90,0,0, 0,-3,0, red, m)

d("cornerHolePiece()", -90,90,0, -2,-2,0, green, m)
d("ramp2Piece()", -90,-90,0, -2,-4,2, red, m)

d("mirror([0,1,0])rampCornerPiece(steps=30)", -90,-180,0, -4,-6,2, blue, m)

d("mirror([0,1,0])rampCornerPiece(steps=30)", -90,-90,0, -4,-8,4, green, m)

d("longRampPiece()", -90,90,0, -1,-10,4, red, m)
d("rampPiece()", -90,90,0, 2,-12,4, green, m)

d("duplo(2,2,2,true,false)", -90,90,0, 2,-3,2, blue, m)

d("duplo(2,4,2,true,false)", -90,90,0, 1,-5,2, green, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-7,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-9,2, yellow, m)

d("duplo(2,4,2,true,false)", -90,90,0, -1,-7,2, yellow, m)
d("duplo(2,4,2,true,false)", -90,90,0, -3,-9,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-9,2, blue, m)
d("duplo(2,2,2,true,false)", -90,90,0, -4,-11,4, blue, m)
d("duplo(2,4,2,true,false)", -90,90,0, -3,-13,4, yellow, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-13,4, blue, m)
d("duplo(2,4,2,true,false)", -90,90,0, 1,-11,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-13,2, green, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-13,2, yellow, m)

for i = 0,4 do
d("duplo(2,2,2,true,false)", -90,90,0, 8,-4,4, yellow, 1)
end

for i = 0,1 do
d("duplo(2,3,2,true,false)", -90,90,0, 8,-4,4, green, 1)
end

for i = 0,1 do
d("duplo(4,2,2,true,false)", -90,90,0, 8,5,4, red, 1)
end

function setcam()
  d = 2000
  -- pseudo orthogonal view
  --v.cam:setFieldOfView(.1)

  v.cam.focal_blur      = 0 -- > 0: enable focal blur
  v.cam.focal_aperture  = 5
  --v.cam.focal_point = XXX.pos
  v.cam:setUpVector(btVector3(0,1,0), true)
  v.cam:setHorizontalFieldOfView(0.075)
  v.cam.pos  = btVector3(-2000,1000,d)
  v.cam.look = btVector3(20,0,50) 
end

setcam()

function run()
  s = Sphere(12,3)
  s.pos = btVector3(-0.8,60,0)
  s.col = "#202020"
  s.sdl = [[
  texture { Polished_Chrome }
]]
  v:add(s)
end

run()run()run()

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)
