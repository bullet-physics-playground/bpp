local color = require "color"

p = Plane(0,1,0,0,100)
p.pos = btVector3(0,0,0)
p.col = color.forestgreen
v:add(p)


rock = OpenSCAD([[

// Basic Randomized Rock Generator
function rock_points(num_faces = 90, size = 1) = 
    [for (i = [0:num_faces-1]) 
        let(
            angle = i * 360 / num_faces,
            r = size + rands(-5, 5, 1)[0], // Random radius variation
            x = r * cos(angle),
            y = r * sin(angle),
            z = rands(-size, size, 1)[0]
        ) [x, y, z]
    ];

// Define rock faces (a simple hull is often best for organic shapes)
module my_rock() {
    points = rock_points();
    hull() {
        for (p = points) {
            translate(p) cube(1);
        }
    }
}

my_rock();
]], 1, true)

v:add(rock)

