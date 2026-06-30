local color = require "color"

p = Plane(0,1,0,0,200)
p.pos = btVector3(0,0,0)
p.col = color.forestgreen
v:add(p)

N = 20

for i = 0,N do

rock = OpenSCAD([[

function rock_points(num_faces = 90, size = 20) = 
    [for (i = [0:num_faces-1]) 
        let(
            angle = i * 360 / num_faces,
            r = size + rands(-5, 5, 1)[0], // Random radius variation
            x = r * cos(angle),
            y = r * sin(angle),
            z = rands(-size, size, 1)[0]
        ) [x, y, z]
    ];

module my_rock() {
    points = rock_points();
    hull() {
        for (p = points) {
            translate(p) cube(1);
        }
    }
}

my_rock();
//]]..i, 1, true) -- true: enable center of mass calculation

v:add(rock)

end

v.cam:setUpVector(btVector3(0.523171, 0.681407, 0.511836), true)
v.cam.up   = btVector3(0.523171, 0.681407, 0.511836)
v.cam.pos  = btVector3(-179.156, 254.345, -195.809)
v.cam.look = btVector3(459988, -731122, 503128)
