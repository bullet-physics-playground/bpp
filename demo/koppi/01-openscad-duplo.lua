--
-- marble run with Duplo
--

require "koppi/duplo" -- thingiverse.com/thing:159219

v.gravity = btVector3(0,-98.1*4,0)

p = Plane(0,1,0,0,1000)
p.pos = btVector3(0,-130,0)
p.col = "#303030"
v:add(p)

function d(p, rx, ry, rz, px, py, pz, col, mass)
  o = duplo.new({fun="rotate(["..rx..","..ry..","..rz.."])"..p..";", mass = mass})
  o.pos = btVector3(px*16, py*9.6, pz*16)
  o.col = col
  v:add(o)
end

m = 0
red    = "#f30"
yellow = "#ff0"
blue   = "#006"
green  = "#3c0"

d("duplo(4,2,2,true,false)", -90,0,0, -1,1,0, blue, m)

d("endPiece()", -90,-90,0, 0,3,0, red, m)
d("rampCornerPiece(steps=30)", -90,-0,0, 2,2,0, green, m)
d("rampCornerPiece(steps=30)", -90,-90,0, 2,0,2, red, m)
d("rampCornerPiece(steps=30)", -90,-180,0, 0,-2,2, yellow, m)

d("cornerPiece()", -90,0,0, 0,-3,0, red, m)

d("cornerHolePiece()", -90,90,0, -2,-2,0, green, m)
d("ramp2Piece()", -90,-90,0, -2,-4,2, red, m)

d("mirror([0,1,0])rampCornerPiece(steps=30)", -90,-180,0, -4,-6,2, blue, m)

d("mirror([0,1,0])rampCornerPiece(steps=30)", -90,-90,0, -4,-8,4, green, m)

d("longRampPiece()", -90,90,0, -1,-10,4, red, m)
d("rampPiece()", -90,90,0, 2,-12,4, green, m)

d("duplo(2,2,2,true,false)", -90,90,0, 2,-3,2, blue, m)

d("duplo(2,4,2,true,false)", -90,90,0, 1,-5,2, green, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-7,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-9,2, yellow, m)

d("duplo(2,4,2,true,false)", -90,90,0, -1,-7,2, yellow, m)
d("duplo(2,4,2,true,false)", -90,90,0, -3,-9,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-9,2, blue, m)
d("duplo(2,2,2,true,false)", -90,90,0, -4,-11,4, blue, m)
d("duplo(2,4,2,true,false)", -90,90,0, -3,-13,4, yellow, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-13,4, blue, m)
d("duplo(2,4,2,true,false)", -90,90,0, 1,-11,2, red, m)
d("duplo(2,2,2,true,false)", -90,90,0, 2,-13,2, green, m)
d("duplo(2,2,2,true,false)", -90,90,0, 0,-13,2, yellow, m)

for i = 0,4 do
d("duplo(2,2,2,true,false)", -90,90,0, 8,-4,4, yellow, 1)
end

for i = 0,1 do
d("duplo(2,3,2,true,false)", -90,90,0, 8,-4,4, green, 1)
end

for i = 0,1 do
d("duplo(4,2,2,true,false)", -90,90,0, 8,5,4, red, 1)
end

function run()
  s = Sphere(12,1.5)
  s.pos = btVector3(-1,60,0)
  s.col = "#202020"
  v:add(s)
end

run()

v:onCommand(function(cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)
