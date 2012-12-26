plane = Plane(0,1,0)
plane.col = "#333333"

plane.pre_sdl = [[
plane { <0,1,0>,0]]

if (use_lightsys == 1) then
  plane.post_sdl = [[
  pigment{ rgb ReferenceRGB(Gray20) }
}
]]
else
  plane.post_sdl = [[
  pigment { rgb <0.2,0.2,0.2> }
}
]]
end


v:add(plane)

function line(N,zpos,damp_lin,damp_ang,fri,res)
  local s = Sphere(1,1)
  s.pos = btVector3(-15, 1, zpos)
  s.col = "#0000ff"
  s.vel = btVector3(5,0,0)
  s.pre_sdl = [[
sphere { <.0,.0,.0>, 1
]]
  s.post_sdl = [[
  texture{pigment{color Gray} finish{ reflection 1 }}
}
]]

  v:add(s)

  local d_end

  for i = 0,N do
    local d = Cube(0.4,3,1.5, 1)
    d.pos = btVector3(i*2, 1.5, zpos)
    d.col = "#ff0000"

    d.friction = fri
    d.restitution = res

    d.damp_lin = damp_lin
    d.damp_ang = damp_ang

    v:add(d)

    if (i == N) then
      d_end = d
    end
  end

  return s,d_end
end

s,d = line(5, -3, 0.01, 0.01, 0.4, 0.1)
line(5,  0, 0.1,  0.1,  0.3, 0.0)
line(5,  3, 0.1,  0.1,  0.3, 0.5)

v:preDraw(function(N)
  cam = Cam()

  if (N < 40) then
    cam.pos = s.pos + btVector3(7,18,18)
    cam.look = s.pos + btVector3(7,-4,0)
  elseif (N < 100) then
    cam.pos = d.pos + btVector3(-10,9,18)
    cam.look = d.pos + btVector3(-4,-4,0)
  else
    cam.pos = s.pos + btVector3(7,6,25)
    cam.look = s.pos + btVector3(7,4,0)
  end
  v:cam(cam)
end)
