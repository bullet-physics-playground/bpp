--
-- Planets -- a sun and several planets in slightly tilted orbits (ours,
-- not in the book; solar_system.nlogo's law and units, G 20, sun mass 100,
-- with no force or velocity cap).
--
-- Planet i starts on a circular orbit at 15 x 1.8^(i-1) from the sun (15,
-- 27, 49, 87, ...), at a random phase, in a plane tilted at random by up to
-- Tilt degrees. The centre of mass starts at rest. R gives a new start
-- (the seed slider repeats one).
--
-- What to see: with light planets (Planet_Mass 0.1, a thousandth of the
-- sun, about Jupiter's share) the system is stable: in tests every orbit
-- kept its radius within 1-3% for 150 orbits of the outermost planet. The
-- planets tug on each other's planes, so each plane's tilt slowly changes
-- (the "tilts" field) while the total angular momentum L stays fixed. Make
-- the planets heavier (Planet_Mass 1 to 3, up to 3% of the sun) and they
-- perturb each other more, until one is thrown out (FINDINGS F57). Larger
-- Time_Steps lose accuracy on the inner orbit first.
--
-- Status line: t time; |P| total linear momentum (stays 0); |L| size of the
-- total angular momentum; tilt the angle between L now and at the start
-- (degrees, stays 0); tilts each planet's orbital plane against the plane
-- perpendicular to L (degrees, innermost first); KE / PE / E kinetic,
-- potential (sum of -G m1 m2 / r over all pairs) and total energy.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"

v:addParam("Planets", 4, 1, 6, 1, "number of planets, at 15 x 1.8^(i-1) from the sun; applies on R")
v:addParam("Planet_Mass", 0.1, 0.01, 3, 0.01, "each planet's mass (the sun's is 100); applies on R")
v:addParam("Tilt", 10, 0, 45, 1, "largest starting tilt of an orbit, degrees; applies on R")
v:addParam("Time_Step", 0.01, 0.001, 0.1, 0.001, "Delta-t")
v:addParam("stepsPerFrame", 30, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

local COLORS = { "#ffd040", "#7090ff", "#50d070", "#ff7060", "#d080ff", "#60e0e0", "#ffffff" }

scene.run({
  title = "planets",
  threeD = true,
  noSep = true,
  build = function()
    return ch.planets({ n = v:getParam("Planets"), planetMass = v:getParam("Planet_Mass"),
                        tilt = v:getParam("Tilt"), dt = v:getParam("Time_Step") })
  end,
  resetOn = { Planets = true, Planet_Mass = true, Tilt = true },
  live = function(name, value, m)
    if name == "Time_Step" then m.dt = value; return true end
    return name == "stepsPerFrame"
  end,
  extra = function(m, mm)
    local L, parts = { mm.lx, mm.ly, mm.lz }, {}
    for i = 1, #m.ps - 1 do
      local _, inc = ch.planetOrbit(m, i, L)
      parts[#parts + 1] = string.format("%4.1f", inc)
    end
    return { "tilts=" .. table.concat(parts, " ") }
  end,
  radius = function(mass) return mass >= 10 and 3 or 1.2 end,
  colors = COLORS,
  trail = 250, trailEvery = 40, trailRadius = 0.3,
  trails = (function()
    local t = {}
    for i = 1, 6 do t[i] = { of = i + 1, color = COLORS[i + 1] } end
    return t
  end)(),
  camHeight = 340,
  help = "planets (ours): a sun and several planets in tilted orbits, solar_system's law without caps. Light planets are stable; heavy ones throw each other out. R: new start; S: stop/start. Status: t, |P|, |L|, tilt of L, each orbit's tilt, KE, PE, E.",
})
-- EOF
