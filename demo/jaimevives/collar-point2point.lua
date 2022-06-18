--
-- Pearls collar
--

-- Demo of the btPoint2PointConstraint

v.timeStep      = 1/5
v.maxSubSteps   = 10
v.fixedTimeStep = 1/20

v.pre_sdl = [[

#version 3.7;

#include "colors.inc"

#declare n_pearl=
normal{
   radial sine_wave
   frequency 36*4
   rotate 90*z
}
#declare t_pearl=
material{
   texture{
     pigment {
       aoi
       color_map{
         [0 Wheat*.5+Coral*.5]
         [1 White]
       }
     }
     normal{n_pearl .05}
     finish{
       specular albedo .25 metallic roughness .025 diffuse .75 brilliance 2
       reflection{0,1 metallic}
       conserve_energy
       irid {
           0.35
           thickness .1
           turbulence .5
         }
     }
   }
}
]]

plane = Plane(0,1,0,0,1000)
plane.pos = btVector3(0, 0, 0)
plane.col = "#777"
v:add(plane)

function collar(num_pearls,collar_pos,pearl_radius)

  collar_radius = pearl_radius * num_pearls / math.pi
  nv = btVector3(0,1,0)

  for i = 1,num_pearls do

    x = math.sin(i / num_pearls * math.pi * 2) * collar_radius
    y = math.cos(i / num_pearls * math.pi * 2) * collar_radius
    a = -2*math.pi*i/num_pearls

    pearl = Sphere(pearl_radius,1)
    q = btQuaternion(math.cos(a/2),math.sin(a/2)*nv.x,math.sin(a/2)*nv.y,math.sin(a/2)*nv.z)
    o = btVector3(collar_pos.x+x, collar_pos.y, collar_pos.z+y)
    pearl.trans = btTransform(q,o)    
    pearl.col = "#ffEEDD"
    pearl.friction = 0.6
    pearl.restitution = .1
    pearl.sdl = [[ material { t_pearl } ]]
    v:add(pearl)

    if (i>1) then
      this_pivot = btVector3(-pearl_radius,0,0)
      last_pivot = btVector3(pearl_radius,0,0)
      constr = btPoint2PointConstraint(
        pearl.body, last_pearl.body,
        this_pivot,last_pivot)
        v:addConstraint(constr)
    else
      first_pearl = pearl
    end

    if (i==num_pearls) then
      this_pivot = btVector3(pearl_radius,0,0)
      last_pivot = btVector3(-pearl_radius,0,0)
      constr = btPoint2PointConstraint(
        pearl.body, first_pearl.body,
        this_pivot,last_pivot)
        v:addConstraint(constr)
    end
    
    last_pearl = pearl

  end

end

collar(60,btVector3(0,175,0),4.6)

c = Cylinder(10,220,0)
c.pos = btVector3(0,120,0)
c.col = "#333"
c.friction = 1
v:add(c)
