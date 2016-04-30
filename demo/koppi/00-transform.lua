color = require "color"

v.gravity = btVector3(0,-9.81*20,0)

c = Cam()
v:setCam(c)
c.pos  = btVector3(-10, 40, -60)
c.look = btVector3(13, 15, 0)

v.glAmbient = 0.2
v.glDiffuse = 0.7
v.glLight0 = btVector4(100,100,100,1000)
v.glLight1 = btVector4(-100,100,100,100)
v.glSpecular = 0.8
v.glModelAmbient = 0.5

plane = Plane(0,1,0)
plane.col = "#7f7f7f"
v:add(plane)

ob = {}

function move(o, v)
  trans1 = btTransform(btQuaternion(0,0,0,1), v)
  trans2 = o.trans
  trans2:mult(trans1, trans2)
  o.trans = trans2
end

function rotate(o, q)
  trans1 = btTransform(q, btVector3(0,0,0))
  trans2 = o.trans
  trans2:mult(trans1, trans2)
  o.trans = trans2
end

N=0

for i = 1, 120 do
  --print(i)
  a = Cube(0.25,1.4,10,0)
--  rotate(a, btQuaternion(0,0,1, math.cos(N/10)))
  move(a, btVector3(i*0.5,math.sin(N/5+i/2)*2.5+5,0))
  a.col= "#ff0000"
  v:add(a)
  ob[#ob+1] = a
end

function update(N)
  for i = 1, 120 do
    --print(i)
    a = ob[i]
    t = a.pos
    t.y = math.sin(N/2+i/3.5)*1.2-2+i*0.1
    a.pos = t
  end
end

update(0)

v:preSim(function(N)
--print(N)

if (math.fmod(N, 34) == 0) then
print(N)
  s=Sphere(2.6,1)
  s.col = color.random_pastel()
  move(s, btVector3(45,0,0))
  move(s, btVector3(0,65,0))
  v:add(s)
end

update(N)
--print(ob)


end)