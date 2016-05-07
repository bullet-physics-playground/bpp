 -- http://www.ignorancia.org/en/index.php?page=Lightsys
use_lightsys = 0

-- http://www.openscad.org/
use_openscad = 1

require "color"

v.gravity = btVector3(0,-9.81*4,0)

p = Plane(0.001,1,0.001,0,1000)
p.col = "#331"
p.pre_sdl = [[plane { <0,1,0>,0]]
if (use_lightsys == 1) then
  p.post_sdl = [[
  pigment{
    checker
      rgb ReferenceRGB(Gray20)
      rgb ReferenceRGB(Gray60)
  }}]]
else
  p.post_sdl = [[
  pigment {
    checker
      rgb <.2,.2,.2>,
      rgb <.6,.6,.6>
  }}]]
end
v:add(p)

cu = Cube()
cu.col = "#ff0000"
cu.pos = btVector3(0, 0.5, 0);
v:add(cu)

cy = Cylinder()
cy.col = "#00ff00"
cy.pos = btVector3(1, 0.5, 0)
v:add(cy)

sp = Sphere()
sp.col = "#ffff00"
sp.pos = btVector3(0.5, 1.5, 0)

sp.pre_sdl =
[[
sphere { <.0,.0,.0>, 0.5
]]

sp.post_sdl =
[[
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
}
]]

v:add(sp)

if (use_openscad == 1) then
  sc = OpenSCAD([[
    rotate_extrude(convexity = 10, $fn = 50)
    translate([0.45, 0, 0])
    circle(r = 0.25, $fn = 50);
  ]], .5)
  sc.col = color.blue
  sc.pos = btVector3(4,1,1)
  v:add(sc)
end

v.cam:setFieldOfView(.5)

v:preDraw(function(N)
  v.cam:setUpVector(btVector3(0,1,0), false)
  v.cam.pos  = btVector3(2,3,6)
  v.cam.look = cy.pos - btVector3(1,-.5,-1)
end)
