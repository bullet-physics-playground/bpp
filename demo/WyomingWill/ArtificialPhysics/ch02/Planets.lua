--
-- Planets -- a sun and several planets on elliptical, slightly tilted
-- orbits (ours, not in the book; solar_system.nlogo's law and units, G 20,
-- sun mass 100, with no force or velocity cap).
--
-- Planet i's orbit has semi-major axis 15 x ratio^(i-1) and eccentricity
-- Eccentricity (0 = circles); it starts at its farthest point, at a random
-- phase, in a plane tilted at random by up to Tilt degrees. The centre of
-- mass starts at rest. R gives a new start (the seed slider repeats one).
--
-- Two rules make it stable (FINDINGS F57, F58), and the scene applies both
-- on every R:
--   * Spacing. Gap is the outer orbit's nearest point over the inner
--     orbit's farthest point, so ratio = Gap (1 + e) / (1 - e). 1.8 keeps
--     circles stable and keeps ellipses stable too; at Gap 1 the orbits
--     touch, and below 1 they cross. Lower it to see what goes wrong.
--   * Time step. The nearest-point pass of an ellipse is short and fast:
--     Time_Step is set to give about 50 steps across the inner planet's
--     pass, sqrt(rp^3 / (G M)) / 50 with rp = 15 (1 - e), and stepsPerFrame
--     to keep 0.3 time units per frame. Raise Time_Step afterwards to see
--     the fast pass go wrong (at e 0.9 even 0.01 is too large).
--
-- What to see: with light planets (Planet_Mass 0.1, a thousandth of the
-- sun, about Jupiter's share) every orbit keeps its shape; the planets tug
-- on each other's planes, so each plane's tilt slowly changes (the "tilts"
-- field) while the total angular momentum L stays fixed. Heavier planets
-- (Planet_Mass 1, a hundredth) still hold at Gap 1.8, but at Gap 1 they
-- throw each other out.
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

v:addParam("Planets", 3, 1, 6, 1, "number of planets; applies on R")
v:addParam("Eccentricity", 0.3, 0, 0.9, 0.05, "e of every orbit (0 = circles); applies on R")
v:addParam("Gap", 1.8, 0.5, 3, 0.1, "outer orbit's nearest point / inner orbit's farthest point (1.8 is stable, 1 touches); applies on R")
v:addParam("Planet_Mass", 0.1, 0.01, 3, 0.01, "each planet's mass (the sun's is 100); applies on R")
v:addParam("Tilt", 10, 0, 45, 1, "largest starting tilt of an orbit, degrees; applies on R")
v:addParam("Time_Step", 0.01, 0.0001, 0.1, 0.0001, "Delta-t; set on R to ~50 steps per nearest-point pass of the inner orbit")
v:addParam("stepsPerFrame", 30, 1, 2000, 1, "integrator steps per drawn frame (display speed only); set on R to 0.3 time units per frame")

local COLORS = { "#ffd040", "#7090ff", "#50d070", "#ff7060", "#d080ff", "#60e0e0", "#ffffff" }
local TIME_PER_FRAME = 0.3

-- the farthest any orbit reaches, and a size scale for drawing, so the
-- bodies and trails stay visible however wide the system is
local function extent(m)
  local far = 0
  for i = 2, #m.ps do far = math.max(far, ch.planetOrbit(m, i - 1, { 0, 0, 1 })) end
  return far
end
local drawScale = 1

local function opts()
  return { n = v:getParam("Planets"), planetMass = v:getParam("Planet_Mass"), tilt = v:getParam("Tilt"),
           ecc = v:getParam("Eccentricity"), gap = v:getParam("Gap") }
end

scene.run({
  title = "planets",
  threeD = true,
  noSep = true,
  build = function()
    local o = opts()
    -- the time-step rule, and a display speed to match
    o.dt = ch.planetsTimeStep(o)
    v:addParam("Time_Step", o.dt, 0.0001, 0.1, 0.0001, "Delta-t; set on R to ~50 steps per nearest-point pass of the inner orbit")
    v:addParam("stepsPerFrame", math.max(1, math.floor(TIME_PER_FRAME / o.dt + 0.5)), 1, 2000, 1,
               "integrator steps per drawn frame (display speed only); set on R to 0.3 time units per frame")
    local m = ch.planets(o)
    drawScale = math.max(1, extent(m) / 90)
    return m
  end,
  resetOn = { Planets = true, Planet_Mass = true, Tilt = true, Eccentricity = true, Gap = true },
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
  radius = function(mass) return (mass >= 10 and 3 or 1.2) * drawScale end,
  colors = COLORS,
  trail = 250, trailEvery = 40, trailRadius = function() return 0.3 * drawScale end,
  trails = (function()
    local t = {}
    for i = 1, 6 do t[i] = { of = i + 1, color = COLORS[i + 1] } end
    return t
  end)(),
  -- frame the outermost orbit's farthest point
  camHeight = function(m) return math.max(150, 3.6 * extent(m)) end,
  help = "planets (ours): a sun and planets on tilted ellipses, solar_system's law without caps. Spacing (Gap) and Time_Step follow two rules that keep it stable; lower Gap or raise Time_Step to see why. R: new start; S: stop/start. Status: t, |P|, |L|, tilt of L, each orbit's tilt, KE, PE, E.",
})
-- EOF
