--
-- Layer Manager demo
--
-- Demonstrates the Layer system (from Moray integration) for scene organization.
-- Layers control visibility, locking, renderability, and color coding.
--
-- Usage: bpp -f demo/basic/layer-demo.lua

local common = require "common"

common.setTiming(1/30)

-- Ground plane
plane = Plane(0,1,0,0,500)
plane.col = "#224422"
v:add(plane)

-- Create layer manager
lm = LayerManager()

-- Create layers (default colors will be used)
redLayer = lm:createLayer("Red Objects")
redLayer:setVisible(true)
redLayer:setLocked(false)

blueLayer = lm:createLayer("Blue Objects")
blueLayer:setVisible(true)
blueLayer:setLocked(false)

greenLayer = lm:createLayer("Green Objects")
greenLayer:setVisible(false)  -- Initially hidden
greenLayer:setLocked(true)

-- Create objects and assign to layers
cube1 = Cube(2, 2, 2, 2)
cube1.pos = btVector3(-6, 3, 0)
cube1.col = "#ff0000"
v:add(cube1)
lm:assignObject(cube1, redLayer)

sphere1 = Sphere(1.5, 2)
sphere1.pos = btVector3(0, 3, 0)
sphere1.col = "#0000ff"
v:add(sphere1)
lm:assignObject(sphere1, blueLayer)

disc1 = Disc(2, 0.5, 1)
disc1.pos = btVector3(6, 3, 0)
disc1.col = "#00ff00"
v:add(disc1)
lm:assignObject(disc1, greenLayer)

torus1 = Torus(0.5, 1.5, 2)
torus1.pos = btVector3(-6, 6, 0)
torus1.col = "#ff0000"
v:add(torus1)
lm:assignObject(torus1, redLayer)

-- Show layer info
print("Layers:")
for i, layer in ipairs(lm:layers()) do
  print("  " .. layer:getName() .. " - visible=" .. tostring(layer:isVisible()) ..
        ", locked=" .. tostring(layer:isLocked()) .. ", objects=" .. layer:objectCount())
end

common.setCamera(btVector3(20, 15, 15), btVector3(0, 4, 0), math.rad(45))
