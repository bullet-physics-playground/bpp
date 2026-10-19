--
-- Tetrahedron -- four masses on six springs, spinning (ours, not in the
-- book; truly 3D, which two bodies on a spring never are).
--
-- Masses 1, 2, 3 and 4 (white, yellow, green, blue) sit at the corners of a
-- regular tetrahedron with edges of 50, joined by six springs of rest
-- length 50. Unequal masses make an asymmetric top: three different
-- principal moments of inertia (about 4390, 5840 and 7270). It starts
-- spinning at Spin about one principal axis (Axis: 1 the smallest moment,
-- 2 the middle, 3 the largest), tilted Tilt degrees toward the next.
--
-- What to see: about axes 1 and 3 it spins steadily, wobbling a little. About
-- the middle axis it cannot: it turns over, end for end, again and again
-- -- the tennis-racket (Dzhanibekov) effect -- while the angular momentum L
-- keeps its size and direction exactly (tilt stays 0) and the energy does
-- not drift. The springs stretch a few per cent as it spins.
--
-- Status line: t time; |P| total linear momentum (stays 0); |L| size of the
-- angular momentum about the centre of mass; tilt the angle between L now
-- and at the start (degrees, stays 0); axis the angle between the chosen
-- principal axis, carried with the body, and L (degrees): near 0 for a
-- steady spin, swinging to 180 and back when it flips; KE / PE / E kinetic,
-- spring potential (sum of k (r - 50)^2 / 2) and total energy.
-- Measured: ch02/README.md, FINDINGS F57.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"
local status = require "lib.status"

v:addParam("Spin", 0.5, 0.05, 1.5, 0.05, "starting spin rate, radians per unit time; applies on R")
v:addParam("Axis", 2, 1, 3, 1, "principal axis to spin about: 1 smallest moment, 2 middle (flips), 3 largest; applies on R")
v:addParam("Tilt", 2, 0, 30, 0.5, "start this many degrees off the axis; applies on R")
v:addParam("Spring_Constant", 10, 1, 50, 0.5, "k: stiffer springs keep the shape closer to rigid")
v:addParam("Friction", 0, 0, 0.01, 0.0001, "v <- (1 - Friction) v each step")
v:addParam("Time_Step", 0.001, 0.0001, 0.01, 0.0001, "Delta-t")
v:addParam("stepsPerFrame", 200, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

scene.run({
  title = "tetrahedron",
  threeD = true,
  noSep = true,
  build = function()
    return ch.tetra({ spin = v:getParam("Spin"), axis = v:getParam("Axis"), tilt = v:getParam("Tilt"),
                      k = v:getParam("Spring_Constant"), friction = v:getParam("Friction"),
                      dt = v:getParam("Time_Step") })
  end,
  resetOn = { Spin = true, Axis = true, Tilt = true, Spring_Constant = true },
  live = function(name, value, m)
    if name == "Friction" then m.law.friction = value; return true end
    if name == "Time_Step" then m.dt = value; return true end
    return name == "stepsPerFrame"
  end,
  lines = function(m) return m.bonds end,
  extra = function(m, mm)
    local ax, ay, az = ch.bodyAxis(m)
    local cx = ay * mm.lz - az * mm.ly
    local cy = az * mm.lx - ax * mm.lz
    local cz = ax * mm.ly - ay * mm.lx
    local dot = ax * mm.lx + ay * mm.ly + az * mm.lz
    local ang = math.deg(atan2(math.sqrt(cx * cx + cy * cy + cz * cz), dot))
    return { status.num("axis", ang, 1, false, 6) }
  end,
  radius = function(mass) return 2.2 * mass ^ (1 / 3) end,
  colors = { "#ffffff", "#ffd040", "#50d070", "#5090ff" },
  trail = 400, trailEvery = 50, trails = { { of = 1, color = "#c0c0c0" } },
  camHeight = 160,
  help = "tetrahedron (ours): four masses 1-4 on six springs, spinning. Axis 2 flips over and over (the tennis-racket effect); axes 1 and 3 spin steadily. R: new start; S: stop/start. Status: t, |P|, |L|, tilt of L, axis-to-L angle, KE, PE, E.",
})
-- EOF
