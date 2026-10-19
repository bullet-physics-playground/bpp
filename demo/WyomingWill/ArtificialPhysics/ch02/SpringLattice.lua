--
-- SpringLattice -- a cube of masses on springs (ours, not in the book; a
-- first step toward the Ch. 3 formations in 3D).
--
-- Size x Size x Size unit masses on a cubic grid of spacing 50, with a
-- spring of rest length equal to the starting distance between every pair
-- closer than 1.5 x 50: the cube's edges (drawn) and its faces' diagonals
-- (not drawn, for clarity). Edges alone would let the cube shear flat; the
-- diagonals hold its shape, as a truss does. Each mass starts displaced at
-- random by up to Jitter x 50, and the whole cube spins at Spin about a
-- random axis. R gives a new start (the seed slider repeats one).
--
-- Colours: each spring is coloured by its strain (r - rest) / rest, blue
-- compressed, white at rest, red stretched, full colour at 5% (so the
-- ringing shows as colour flickering through the cube); the masses are
-- coloured by their starting layer (yellow, white, blue, and green for a
-- fourth), so the turning is easy to follow.
--
-- What to see: the cube turns and rings -- every mass oscillating about
-- its place -- for ever without friction, with |P| = 0 and L fixed exactly
-- and E not drifting. With Friction the ringing dies away and the cube
-- settles back into a perfect cube (strain to 0); the book's friction
-- slows every velocity, so it stops the spin too.
--
-- Status line: t time; |P| total linear momentum (stays 0); |L| size of the
-- angular momentum about the centre of mass; tilt the angle between L now
-- and at the start (degrees, stays 0); strain the mean of |r - rest| /
-- rest over all springs (per cent; 0 = a perfect cube); KE / PE / E
-- kinetic, spring potential (sum of k (r - rest)^2 / 2) and total energy.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"
local status = require "lib.status"
local mon = require "lib.monitors"

-- strain -> colour: blue (compressed) - white (at rest) - red (stretched),
-- saturating at FULL_STRAIN
local FULL_STRAIN = 0.05
local function strainColor(m, bd)
  local s = (mon.dist(m.ps[bd[1]], m.ps[bd[2]]) - bd.rest) / bd.rest
  local t = math.max(-1, math.min(1, s / FULL_STRAIN))
  local r, g, b
  if t >= 0 then r, g, b = 255, 255 - 190 * t, 255 - 210 * t      -- white -> red
  else r, g, b = 255 + 205 * t, 255 + 120 * t, 255 end               -- white -> blue
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end
local LAYER = { "#ffd040", "#ffffff", "#5090ff", "#50d070" }

v:addParam("Size", 3, 2, 4, 1, "masses along each edge of the cube (27 at 3); applies on R")
v:addParam("Jitter", 0.1, 0, 0.3, 0.01, "starting random displacement, as a fraction of the spacing; applies on R")
v:addParam("Spin", 0.3, 0, 1.5, 0.05, "starting spin about a random axis, radians per unit time; applies on R")
v:addParam("Spring_Constant", 10, 1, 50, 0.5, "k")
v:addParam("Friction", 0, 0, 0.01, 0.0001, "v <- (1 - Friction) v each step")
v:addParam("Time_Step", 0.002, 0.0001, 0.01, 0.0001, "Delta-t")
v:addParam("stepsPerFrame", 20, 1, 200, 1, "integrator steps per drawn frame (display speed only)")

scene.run({
  title = "spring lattice",
  threeD = true,
  noSep = true,
  build = function()
    return ch.lattice({ n = v:getParam("Size"), jitter = v:getParam("Jitter"), spin = v:getParam("Spin"),
                        k = v:getParam("Spring_Constant"), friction = v:getParam("Friction"),
                        dt = v:getParam("Time_Step") })
  end,
  resetOn = { Size = true, Jitter = true, Spin = true, Spring_Constant = true },
  live = function(name, value, m)
    if name == "Friction" then m.law.friction = value; return true end
    if name == "Time_Step" then m.dt = value; return true end
    return name == "stepsPerFrame"
  end,
  lines = function(m)
    local edges = {}
    for _, bd in ipairs(m.bonds) do
      if bd.rest < 1.1 * m.D then edges[#edges + 1] = bd end
    end
    return edges
  end,
  lineRadius = 0.6,
  lineColor = strainColor,
  extra = function(m) return { status.num("strain", 100 * ch.strain(m), 2, false, 6, "%") } end,
  radius = function() return 2.5 end,
  -- masses are made layer by layer in z (models.lua), n x n per layer
  colors = setmetatable({}, { __index = function(_, i)
    local n = math.floor(v:getParam("Size") + 0.5)
    return LAYER[((i - 1) % n) % #LAYER + 1]
  end }),
  trail = 0,
  camHeight = 420,
  help = "spring lattice (ours): a cube of masses on springs (edges drawn, face diagonals hidden). It spins and rings for ever; with Friction it settles into a perfect cube. R: new start; S: stop/start. Status: t, |P|, |L|, tilt of L, strain, KE, PE, E.",
})
-- EOF
