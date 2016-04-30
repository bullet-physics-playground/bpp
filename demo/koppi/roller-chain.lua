-- Roller Chain (WIP)

color = require "color"
colors = require "colors"
metal = require "metal"

v.glAmbient = 0.3
v.glDiffuse = 0.1
v.glLight0 = btVector4(10,10,10,10)
v.glLight1 = btVector4(10,10,10,10)
v.glSpecular = 0.3
v.glModelAmbient = 0.6


v.timeStep      = 1/25
v.fixedTimeStep = v.timeStep / 2
v.maxSubSteps   = 10

pov_export  = 1  -- povray export on / off

--v.gravity = btVector3(0,0,0)

d  = 100   -- box dimension
col = "#aaaaaa"

friction = 0
restitution = 1.02
damp_ang = 0.01
damp_lin = 0.01

v.pre_sdl = [[
#include "colors.inc"
#include "textures.inc"
]]

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,0,1), btVector3(0,-d,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)


plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,0,1), btVector3(0,d,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,1,1), btVector3(d,0,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(0,0,1,1), btVector3(-d,0,0))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,-1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(1,0,0,1), btVector3(0,0,d))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin

v:add(plane)

plane = Plane(0,1,0)
plane.col = col
plane.trans = btTransform(btQuaternion(1,0,0,1), btVector3(0,0,-d))

plane.friction = friction
plane.restitution = restitution
plane.damp_ang = damp_ang
plane.damp_lin = damp_lin
v:add(plane)

-- objects in the scene --------------------------

local R1 = 0.15;  -- big wheel radius
local R2 = 0.075; -- small wheel radius
local Dist = 0.30;-- axis distance
local Link_N = 30;-- number of links

-- calculations ----------------------------------

function math.degrees( rad )
  return rad * ( 180 / math.pi )
end

local Ri = R1-R2;
local C_Angle = math.degrees(math.asin(Ri/Dist));
--local C_Angle = math.asin(Ri/Dist);
-- chain length linear
local LLen=math.sqrt(math.pow(Dist,2)- math.pow(Ri,2));
-- segment angles and lengths
local Ang1 = 180+2*C_Angle;
local Ang2 = 180-2*C_Angle;
local Len1 = Ang1/360*2*math.pi*R1;
local Len2 = Ang2/360*2*math.pi*R2;
-- total length
local C_Len = 2*LLen+Len1+Len2;
local Link_L  = C_Len / Link_N;

local Ani = 0

print(Link_N)

local Nr = 0; -- start loop
while (Nr < Link_N) do
  local Pos = math.fmod(Nr*Link_L+Ani,C_Len);
  --print(Pos)
  if(Pos<Len1 ) then -- front down
    local Rot1 = Pos/Len1*Ang1;
 --print(Rot1)
      s = Sphere(0.075,1)
      o = btVector3(0,R1,0)
print(o)
      trans1 = btTransform(btQuaternion(), o)
      trans2 = btTransform(btQuaternion(0,0,1, -Rot1 + C_Angle), btVector3())
      s.trans:mult(trans1,trans2)
      v:add(s)
      --print(s)

--    object{Link translate<0,R1,0> rotate<0,0,-Rot1 +C_Angle>}
   end
   if((Pos>Len1) and (Pos<=Len1+LLen)) then
     local LPos = Pos-Len1; -- base side
-- object{Link translate<LPos,R1,0> rotate<0,0,-C_Angle-180 >}   
   end
   if((Pos>Len1+LLen ) -- back up
      and (Pos<= Len1+LLen+Len2)) then
     local Rot2 =
      (Pos-Len1-LLen)/Len2*Ang2
--  object{Link translate<0, R2,0> rotate<0,0,-Rot2-C_Angle-180> translate<-Dist,0,0>}
   end
   if((Pos > Len1+LLen+Len2) -- up forward
      and (Pos <= Len1+LLen+Len2+LLen)) then
     local LPos = Pos-(Len1+LLen+Len2)
-- object{Link  translate<LPos, R2,0> rotate<0,0,C_Angle> translate<-Dist,0,0>}
   end
   Nr = Nr + 1; -- next Nr
end

-- camera ----------------------------------------

if (pov_export == 1) then
c = Cam() c.pos = btVector3(0,1,0)
v.pre_sdl = v.pre_sdl .. string.format("\n#declare cam_pos = <%f, %f, %f>;\n", c.pos.x, c.pos.y, c.pos.z)
end

v:postSim(function(N)
end)