use_lightsys = 1

p = Plane(0,1,0)
p.col = "#333333"
p.pre_sdl = [[
plane { <0,1,0>,0]]

if (use_lightsys == 1) then
  p.post_sdl = [[
  pigment{ checker rgb ReferenceRGB(Gray20) rgb ReferenceRGB(Gray60)}
}
]]
else
  p.post_sdl = [[
  pigment { checker rgb <0.2,0.2,0.2>, rgb <0.6,0.6,0.6> }
}
]]
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

v:preDraw(function(N)
  cam = Cam()
  cam.pos = btVector3(4,4,5)
  cam.look = sp.pos - btVector3(0,0.25,0)
  v:cam(cam)
end)
