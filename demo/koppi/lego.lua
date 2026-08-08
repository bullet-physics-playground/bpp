--
-- Lego Brick Parametric OpenScad
-- by stalkerface, published Nov 26, 2013
--
-- based on Lego_Tech.scad in the downloaded zip file
--
-- http://www.thingiverse.com/thing:191146
--

local lego   = require "scad/lego"
local trans  = require "scad/trans"
local common = require "common"

local l00 = lego.new({ fun  = "KLOTZ(3, 4, 1, Tile=false, Technic=false);", mass = 0 })

trans.move(l00, btVector3(0,0,0))
trans.rotate(l00, btQuaternion(1,0,1,1), btVector3(3.1416,0,0))

v:add(l00)

common.setCamera(btVector3(20000,10000,35000), btVector3(0,0,0), 0.003,
                 { horizontal = true })
