--
-- OpenSCAD template (WIP)
--

v.gravity = btVector3(0,-9.81,0)

v.timeStep      = 1/10
v.maxSubSteps   = 10
v.fixedTimeStep = 1/100

p = Plane(0,1,0,0,10000)
p.col = "#7f7f7f"
v:add(p)

N=3

for i = 1,N do
  for j = 1,N do
    o = OpenSCAD([===[

  // add your OpenSCAD script here
  //
  // see http://edutechwiki.unige.ch/en/OpenScad_beginners_tutorial

  difference() {
    cube([10,10,10], center=true);
    cube([7.5,11,7.5], center=true);
  }

]===], 1)

    o.col = "#7f7f7f"

    dim = 9
    o.pos = btVector3(i*dim-N/2*dim,20,j*dim-N/2*dim)

    o.sdl = [[
texture {
  pigment {
    crackle
    scale 1.5
    turbulence 3
    lambda 5
    color_map {
      [0.00 color rgb<251, 213, 177>/255]
      [0.07 color rgb<251, 213, 177>/270]
      [0.32 color rgb<251, 213, 177>/275]
      [1.00 color rgb<173, 146, 119>/255]  
    }
    scale .1
 }
 normal { bumps 0.095 scale 0.008 }
 finish { ambient 0 diffuse 0.9 phong 0.0 } }
]]

    v:add(o)
  end
end

v.cam:setFieldOfView(0.025)
v.cam:setUpVector(btVector3(0,1,0), true)
v.cam.pos  = btVector3(600, 600, 2000)
v.cam.look = btVector3(1,10,0)

--v.cam.focal_blur     = 10
v.cam.focal_aperture = 5
v.cam.focal_point    = btVector(1,10,0)