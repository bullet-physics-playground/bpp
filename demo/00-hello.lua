v.pre_sdl = [[
#include "textures.inc"
]]

require "color"

use_openscad = 1 -- http://www.openscad.org

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

p = Plane(0,1,0,0,10)
p.col = color.gray
p.sdl = [[
#if (use_lightsys)
  pigment {
    checker
      rgb ReferenceRGB(Gray30)
      rgb ReferenceRGB(Gray60)
  }
#else
  pigment {
    checker
      rgb White * 0.3,
      rgb White * 0.6
  }
#end
]]
v:add(p)

cu = Cube(1,1,1,4)
cu.col = "#ef3010"
cu.pos = btVector3(0, 0.5, 0);
cu.sdl = [[
  texture {
    pigment { color Red }
    finish { phong 1}
  }
]]
v:add(cu)

cy = Cylinder()
cy.col = "#007f00"
cy.pos = btVector3(1, 0.5, 0)
cy.sdl = [[
  texture {
    pigment { color Green }
    finish { phong 1}
  }
]]
v:add(cy)

sp = Sphere(.5,2)
sp.col = "#ffff00"
sp.pos = btVector3(0.5, 2, 0)

sp.sdl = [[
  texture { uv_mapping
    pigment {
      tiling 6
        color_map {
          [ 0.0 color rgb<1,1,1>]
          [ 1.0 color rgb<0,0,0>]
        }
      scale 0.10/4
      rotate<-90,0,0>
      scale<1/1.6,2,1>
    }
    finish { phong 1}
  }
]]

v:add(sp)

if (use_openscad == 1) then
  sc = OpenSCAD([[
    rotate_extrude(convexity = 10, $fn = 40)
    translate([0.45, 0, 0])
    circle(r = 0.25, $fn = 20);
  ]], .75)
  sc.col = "#103070"
  sc.pos = btVector3(4,3,0.2)
  v:add(sc)
end

-- pseudo orthogonal view
v.cam:setFieldOfView(.01)

v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

v:preSim(function(N)
--  print("preSim("..tostring(N)..")")
end)

v:postSim(function(N)
  v.cam:setUpVector(btVector3(0,1,0), false)
  --d = 350
  --o = btVector3(-.2,-.2,0)
  --v.cam.pos  = btVector3(-d,d,d) - o
  --v.cam.look = cy.pos - o 

  ---- render every 10th frame with POV-Ray
  -- if (N % 10 == 0) then povRender(N) end
end)

v:preDraw(function(N)
--  print("preDraw("..tostring(N)..")")
end)

v:postDraw(function(N)
--  print("postDraw("..tostring(N)..")")
end)

function povRender(N)
  v:quickRender("-p -d +W320 +H240 +O/tmp/00-hello-"..string.format("%05d", N)..".png")
end

v:onCommand(function(N, cmd)
  --print("at frame "..tostring(N)..": '"..cmd)

  local f = assert(loadstring(cmd))
  f(v)
end)
