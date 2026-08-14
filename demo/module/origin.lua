--
-- origin.lua - RGB XYZ origin marker
--
-- Three colored axis arrows (cylinder shaft + cone tip) with text labels:
-- x = red, y = green, z = blue.
--
-- Load with:  local origin = require "origin"
--

local common = require "common"
local text   = require "scad/text"

local M = {}

-- Builds an RGB XYZ origin marker, offset by `origin` (a btVector3,
-- defaults to btVector3(0,0,0)), and returns it as an array of objects.
-- Objects are not added to the viewer; add them yourself, e.g.
--   v:addObjects(origin.new())
function M.new(origin)
  origin = origin or btVector3(0, 0, 0)
  local ox, oy, oz = origin.x, origin.y, origin.z

  local objs = {}
  local function add(o)
    table.insert(objs, o)
    return o
  end

  -- z axis (blue)
  local cy = Cylinder(0.05, 7, 0)
  cy.col = "#00f"
  cy.pos = origin
  add(cy)

  local co = Cone(0.2, 0.7, 0)
  co.col = "#00f"
  co.trans = common.transform(3.1415, 0.0, 0.0, ox, oy, oz - 3.5)
  add(co)

  local txt = text.new({ str = "z", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
  txt.col = "#00f"
  txt.trans = common.transform(0.0, 0.0, 0.0, ox, oy + 0.25, oz - 3.5)
  add(txt)

  -- y axis (green)
  cy = Cylinder(0.05, 7, 0)
  cy.col = "#0f0"
  cy.trans = common.transform(0.0, -3.1415/2, 0.0, ox, oy, oz)
  add(cy)

  co = Cone(0.2, 0.7, 0)
  co.col = "#0f0"
  co.trans = common.transform(0.0, -3.1415/2, 0.0, ox, oy + 3.5, oz)
  add(co)

  txt = text.new({ str = "y", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
  txt.col = "#0f0"
  txt.trans = common.transform(-3.1415/2, 0.0, 0.0, ox, oy + 3.5 + 0.5, oz)
  add(txt)

  -- x axis (red)
  cy = Cylinder(0.05, 7, 0)
  cy.col = "#f00"
  cy.trans = common.transform(3.1415/2, 0.0, 0.0, ox, oy, oz)
  add(cy)

  co = Cone(0.2, 0.7, 0)
  co.col = "#f00"
  co.trans = common.transform(3.1415/2, 0.0, 0.0, ox + 3.5, oy, oz)
  add(co)

  txt = text.new({ str = "x", size = 0.5, height = 0.1, y = 1, z = 0, mass = 0})
  txt.col = "#f00"
  txt.trans = common.transform(-3.1415/2, 0.0, 0.0, ox + 3.5, oy + 0.25, oz)
  add(txt)

  return objs
end

return M
