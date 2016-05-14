--
-- OpenSCAD template for Bullet Physics Playground
--
-- see: http://edutechwiki.unige.ch/en/OpenScad_beginners_tutorial
--

v.gravity = btVector3(0,-98.1,0)

p = Plane(0,1,0,0,10000)
p.col = "#ccc"
v:add(p)

for i = 0,6 do
o = OpenSCAD([===[ // add your OpenSCAD script here

egginess = -10; //[-100:100]

egg(curveFactor = (100 + egginess) / 100);

//This makes an egg
//New
//-Fixed egg floating above 0 now sits on 0 like a cylinder

module egg( steps = 60, height = 100, curveFactor = 1, faces = 50 ) {	
    a = height;
    b = height * (0.78 * curveFactor);  //Through keen observation I have determined that egginess should be 0.78

    //Equation for the egg curve
    function eggCurve( offset ) = sqrt( 
                                  a - b - 2 * offset * step 
                                  + sqrt( 4 * b * offset * step + pow(a - b, 2) ) ) 
                                  * sqrt(offset * step) / sqrt(2);
	
	step = a / steps;
	union() {
        //This resembles the construction of a UV sphere
        //A series of stacked cylinders with slanted sides
        for( i = [0:steps]) {
		  //echo(i * step);
		  translate( [0, 0, a - ( i + 1 ) * step - 0.01] )
		    cylinder( r1 = eggCurve( i + 1 ),
		              r2 = eggCurve( i ), 
		              h = step,
		              $fn = faces );
		}
    }
}
]===], 10)

o.col = "#f00"
o.pos = btVector3(i*4,10,0)
o.sdl = [[
texture {
  pigment {
   crackle
   scale 1.5
   turbulence 3
   lambda 5
   color_map { [0.00 color rgb<251, 213, 177>/255]
               [0.07 color rgb<251, 213, 177>/270]
               [0.32 color rgb<251, 213, 177>/275]
               [1.00 color rgb<173, 146, 119>/255] }
   scale .1 }
 normal { bumps 0.095 scale 0.008 }
 finish { ambient 0 diffuse 0.9 phong 0.0}}
]]
v:add(o)

tux = Mesh("demo/koppi/tux.stl", 10)
tux.trans = btTransform(btQuaternion(-1,0,0,1), btVector3(0,-1,20*i))
tux.sdl = [[
texture {
  pigment {
   crackle
   scale 1.5
   turbulence 3
   lambda 5
   color_map { [0.00 color rgb<251, 213, 177>/255]
               [0.07 color rgb<251, 213, 177>/270]
               [0.32 color rgb<251, 213, 177>/275]
               [1.00 color rgb<173, 146, 119>/255] }
   scale .1 }
 normal { bumps 0.095 scale 0.008 }
 finish { ambient 0 diffuse 0.9 phong 0.0}}
]]
v:add(tux)

end
