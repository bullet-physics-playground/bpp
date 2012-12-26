use_lightsys = 1

p = Plane(0,1,0)
p.col = "#333333"

if (use_lightsys == 1) then
  p.pre_sdl = "plane { <0, 1, 0>, 0"
  p.post_sdl = "pigment{rgb ReferenceRGB(Gray20)}}"
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
v:add(sp)

v:preDraw(function(N)
  cam = Cam()
  cam.pos = btVector3(4,4,5)
  cam.look = sp.pos - btVector3(0,0.25,0)
  v:cam(cam)
end)
