--
-- Texture demo
--
-- Wraps image files round objects with the `tex` property. The same image is
-- drawn in the interactive view and exported to POV-Ray, so a quick render
-- (F6) shows the objects wearing what the view shows.
--
-- Usage: bpp -f demo/basic/18-texture.lua
--

local color = require "color"

v.cam.pos  = btVector3(0, 7, 18)
v.cam.look = btVector3(0, 1.5, -1)
v.cam.up   = btVector3(0, 1, 0)

-- A bare file name is looked for next to the script first and then in bpp's
-- own includes directory, which is where POV-Ray looks too -- so these all
-- resolve to the same image in the view and in a render.

-- The ground takes its image flat, once over the square the view draws, and
-- repeating outwards from there.
p = Plane(0, 1, 0, 0, 12)
p.tex = "grassy_bank_7160794.jpg"
p.friction = 1.0
v:add(p)

-- A sphere is wrapped the way a globe is, so each ball wears its own number.
for i = 0, 5 do
  local b = Sphere(0.6, 1)
  b.pos = btVector3(-4.5 + i * 1.8, 6 + i, 0)
  b.tex = "ball" .. (i + 1) .. ".jpeg"
  b.restitution = 0.6
  v:add(b)
end

-- A box takes the whole image on each of its six faces.
cu = Cube(2, 2, 2, 1)
cu.pos = btVector3(-3, 1.2, -3)
cu.tex = "flat_wood_4022164.JPG"
v:add(cu)

-- A cylinder and a cone are wrapped once round their axis.
cy = Cylinder(1, 2.4, 1)
cy.pos = btVector3(0.5, 1.5, -3)
cy.tex = "copper.jpg"
v:add(cy)

co = Cone(1.1, 2.4, 1)
co.pos = btVector3(4, 1.5, -3)
co.tex = "diva-wood-cherry.jpg"
v:add(co)

-- An object with no texture still uses its colour, and `sdl` still overrides
-- both -- a texture is only the default surface, not a replacement for it.
b = Cube(1.4, 1.4, 1.4, 1)
b.pos = btVector3(6.5, 0.8, 0)
b.col = color.orange
v:add(b)
