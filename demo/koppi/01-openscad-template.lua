--
-- OpenSCAD template for Bullet Physics Playground
--

v.gravity = btVector3(0,-98.1,0)

p = Plane(0,1,0,0,100)
p.col = "#ccc"
v:add(p)

for i = 0,3 do
o = OpenSCAD([===[ // add your OpenSCAD script here

difference() {
  cylinder (h = ]===]..tostring(i+2.5)..[===[, r=2, center = true, $fn=102);

  rotate ([90,0,0]) cylinder (h = 6, r=1, center = true, $fn=102);
  rotate ([0,90,0]) cylinder (h = 5, r=1, center = true, $fn=102);
}


]===], 10)

o.col = "#f00"
o.pos = btVector3(i*4,10,0)
v:add(o)

end