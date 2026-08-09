--
-- Transform utilities demo
--
-- Demonstrates the scad/trans module for rotating and moving objects.
-- Shows a grid of spheres, colored by height using the "spring" colormap.
--
-- Usage: bpp -f demo/basic/09-trans.lua

local trans     = require "scad/trans"
local color     = require "color"
local common    = require "common"
local colormaps = require "colormaps"

plane = Plane(0,1,0,0,1000)
plane.pos = btVector3(0,-100,0)
plane.col = "black"
plane.sdl = [[
  texture {
    pigment { color rgb <0,0,0>*1.5 }
    finish {
      specular 0.0
      roughness 0.1
      //reflection 0.3
    }
  }
]]
v:add(plane)

common.gravity(-9.81 * 20)

X = 40
Y = 40
r = 20

mt = {} -- create the matrix
for i=1,X do
  for j=1,Y do
  c = Sphere(0.25,0)
  trans.rotate(c, btQuaternion(1,0,1,1), btVector3(i/X,0,0))
  trans.move  (c, btVector3(i-X/2,0,j-Y/2))

  if (math.sqrt((i-X/2)*(i-X/2)+(j-Y/2)*(j-Y/2)) < r) 
  then
    v:add(c)
  end
  mt[i*Y + j] = c
  end
end

function update(N)
  local height = {}
  local hmin, hmax = math.huge, -math.huge

  for i=1,X do
    for j=1,Y do
      p1 = math.sin(N/50)*20
      x = i-X/2
      y = j-Y/2
      p = math.sin(((x*x)+(y*y))/50+2+p1)*1.5
      p2 = math.log(math.sqrt((x*x)+(y*y))+2.5)*2
      local h = p + 4 + p2
      height[i*Y + j] = h
      if h < hmin then hmin = h end
      if h > hmax then hmax = h end
    end
  end

  local span = hmax - hmin
  for i=1,X do
    for j=1,Y do
      local idx = i*Y + j
      local h = height[idx]
      tmp = mt[idx].pos
      tmp.y = h
      mt[idx].pos = tmp
      local t = (span > 0) and (h - hmin) / span or 0
      mt[idx].col = colormaps.sample_hex("spring", t)
    end
  end
end

update(0)

v:preSim(function(N)

if (math.fmod(N, 5) == 0 and N < 1000) then
if (math.random() > 0.5) then
  s=Sphere(1,1)
else
  s=Cube(2,2,2,1)
end
  s.col = color.random_google()
  trans.move(s, btVector3(1,0,0))
  trans.move(s, btVector3(0,20,0))
  v:add(s)
end

update(N)

end)

function setcam()
  common.setCamera(btVector3(13.0949, 43.915, 41.5668),
                   btVector3(-208476, -667341, -714892), nil,
                   { up = btVector3(-0.149028, 0.74414, -0.651189),
                     focal_aperture = 20, focal_point = btVector3(1,10,0) })
end

setcam()