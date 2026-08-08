local hcw    = require "scad/hcw"
local common = require "common"

v:add(hcw.new({fn = 25, mass = 0}))

common.setCamera(btVector3(20000,10000,35000), btVector3(0,0,0), 0.003,
                 { horizontal = true })
