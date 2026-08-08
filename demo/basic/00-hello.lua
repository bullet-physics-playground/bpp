--
-- Demo of basic BPP objects and functions
--
-- This demo shows how to create basic geometric objects:
-- Plane, Cube, Cylinder, Sphere, and OpenSCAD-generated shapes.
-- It also demonstrates callback functions like preStart, preStop,
-- preSim, postSim, preDraw, postDraw, and onCommand.
--
-- Usage: bpp -f demo/basic/00-hello.lua
--

-- Load the color module for predefined color names
local color  = require "color"
local common = require "common"
-- Load OpenSCAD geodesic sphere module
local gs    = require "scad/geodesic_sphere"
-- Load OpenSCAD text module
local text  = require "scad/text"

-- Set simulation timing: 25 fps, up to 120 substeps, 1/60s fixed timestep
common.setTiming(1/25, 120, 1/60)

-- Add parameters accessible from GUI
v:addParam("sphereColor", "red")
v:addParam("cubeMass", 1.0)
v:addParam("enableGravity", true)
v:addParam("cam.fov", 0.03, 0.01, 0.1)

v.pre_sdl = [[
]]

--
-- SCENE SETUP
--

-- Create a ground plane at y=0, size 5x5 units
p = Plane(0,1,0,0,10)
p.pos = btVector3(0,0,0)
p.col = color.darkgray
v:add(p)

-- Create a cube at position (-2, 0.5, 0)
cu = Cube(1,1,1,1)  -- dimensions 1x1x1, mass 1
cu.col = color.aquamarine
cu.pos = btVector3(-3, 0.5, 0);
v:add(cu)

-- Create a cylinder at position (-1, 0.5, 0)
cy = Cylinder(0.5,1,1)  -- radius 0.5, height 1, mass 1
cy.col = color.brown
cy.pos = btVector3(-1, 0.5, 0)
v:add(cy)

-- Create a sphere at position (1, 0.5, 0)
sp = Sphere(.5,1)  -- radius 0.5, mass 1
sp.col = color.coral
sp.pos = btVector3(1, 0.5, 0)
v:add(sp)

-- Create an OpenSCAD-generated geodesic sphere at position (2, 0.5, 0)
s1 = gs.new({ fun  = "geodesic_sphere(r = 0.5, $fn=6);", mass = 1})
s1.col = color.gold
s1.pos = btVector3(2,0.5,0)
v:add(s1)

cy = Cylinder(0.05, 7, 0)
cy.col = "#00f"
v:add(cy)
co = Cone(0.2, 0.7, 0)
co.col = "#00f"
co.trans = common.transform(3.1415, 0.0, 0.0, 0.0, 0.0, -3.5)
v:add(co)

txt = text.new({ str = "z", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
txt.col = "#00f"
txt.trans = common.transform(0.0, 0.0, 0.0, 0, 0.25, -3.5)
v:add(txt)

cy = Cylinder(0.05, 7, 0)
cy.col = "#0f0"
cy.trans = common.transform(0.0, -3.1415/2, 0.0, 0, 0, 0)
v:add(cy)
co = Cone(0.2, 0.7, 0)
co.col = "#0f0"
co.trans = common.transform(0.0, -3.1415/2, 0.0, 0.0, 3.5, 0)
v:add(co)

txt = text.new({ str = "y", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
txt.col = "#0f0"
txt.trans = common.transform(-3.1415/2, 0.0, 0.0, 0, 3.5 + 0.5, 0)
v:add(txt)

cy = Cylinder(0.05, 7, 0)
cy.col = "#f00"
cy.trans = common.transform(3.1415/2, 0.0, 0.0, 0, 0, 0)
v:add(cy)
co = Cone(0.2, 0.7, 0)
co.col = "#f00"
co.trans = common.transform(3.1415/2, 0.0, 0.0, 3.5, 0.0, 0.0)
v:add(co)

txt = text.new({ str = "x", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
txt.col = "#f00"
txt.trans = common.transform(-3.1415/2, 0.0, 0.0, 3.5, 0.25, 0)
v:add(txt)

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

-- preStop: Called once when simulation stops
v:preStop(function(N)
  print("preStop("..tostring(N)..")")
end)

-- preSim: Called before each physics simulation step
v:preSim(function(N)
  
  sp.col = tostring(v:getParam("sphereColor"))

  mass = v:getParam("cubeMass")
  if (mass ~= cu.mass) then
    cu.mass = v:getParam("cubeMass")
  end

  if v:getParam("enableGravity") then
    v.gravity = btVector3(0, -9.8, 0)
  else
    v.gravity = btVector3(0, 0, 0)
  end
end)

-- postSim: Called after each physics simulation step
v:postSim(function(N)
  --print("postSim("..tostring(N)..")")
  v.cam.focal_blur      = 0
  v.cam.focal_aperture  = 5
  -- set blur point to sphere shape position
  v.cam.focal_point = sp.pos
end)

-- preDraw: Called before each frame is drawn
v:preDraw(function(N)
--  print("preDraw("..tostring(N)..")")
end)

-- postDraw: Called after each frame is drawn
v:postDraw(function(N)
--  print("postDraw("..tostring(N)..")")
end)

-- onCommand: Called when a command is entered in the GUI
v:onCommand(function(N, cmd)
  print("onCommand("..tostring(N).."): '"..cmd.."'")
  local f = assert(loadstring(cmd))
  f(v)
end)

-- onParamChanged: Called when a parameter value is changed in the GUI
v:onParamChanged(function(N, name, value)
  print("onParamChanged("..tostring(N).."): "..name.." = "..value)
  if (name == "cam.fov") then
    v.cam:setFieldOfView(tonumber(value))
  end
end)

-- EOF
