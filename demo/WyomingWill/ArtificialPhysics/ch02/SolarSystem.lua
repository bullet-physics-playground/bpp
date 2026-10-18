--
-- SolarSystem -- Ch. 2.3, solar_system.nlogo (PDF 78-85): one planet
-- under a 1/r^2 law, with the book's force and velocity caps. Sliders as
-- in the NetLogo model (Fig. 2.11 defaults); the planet draws its orbit.
--
-- What to try (book/ch02.md 2.3):
--   a. Time_Step 0.1, Angular_Motion 15 or 10, Mass_of_Sun 100 or 95:
--      ellipses; a lighter sun gives a larger orbit.
--   b. Angular_Motion 5 at Time_Step 0.1: the planet escapes (the time step
--      is too coarse); 0: nonsense, E changes wildly.
--   c. Time_Step 0.001: AM 5 orbits properly; AM 0 still shoots off left.
--   d. Tick Velocity_Cap; Velocity_Maximum 12 then 9 (AM 15): 9 drops the
--      planet into the sun.
--   e. Tick Force_Cap, Force_Maximum 1 (AM 9, 4, 1, 0): bound orbits that
--      precess. AM 9 draws the clearest rosette (out to 55, about a third of
--      a turn per orbit); AM 4 is almost exactly the circular speed, so its
--      orbit is a near circle; AM 0 swings through the sun, 0 to 15 away.
-- The book switches the caps off with huge values (Force_Maximum 1000000,
-- Velocity_Maximum 1000); here each cap has its own tick box instead, so
-- its slider can cover the range that matters.
-- It runs as soon as it loads. R resets (needed after Angular_Motion or
-- Mass_of_Sun); S stops and restarts.
--
-- Status line: t time, sep separation, |P| total linear momentum (should
-- stay 0), L angular momentum about the centre of mass (negative =
-- clockwise), KE / PE / E kinetic, potential and total energy. Full
-- definitions in ch02/scene.lua.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"

v:addParam("Angular_Motion", 15, 0, 30, 1, "planet's starting speed (the sun gets -AM / Mass_of_Sun); applies on R")
v:addParam("Mass_of_Sun", 100, 50, 150, 1, "applies on R")
v:addParam("Gravitational_Constant", 20, 1, 50, 1, "G")
v:addParam("Force_Cap", false, "cap |F| at Force_Maximum (off = the book's 1000000)")
v:addParam("Force_Maximum", 1, 0.1, 10, 0.1, "cap on |F| when Force_Cap is ticked")
v:addParam("Velocity_Cap", false, "cap each speed at Velocity_Maximum (off = the book's 1000)")
v:addParam("Velocity_Maximum", 12, 1, 30, 1, "cap on each speed when Velocity_Cap is ticked")
v:addParam("Time_Step", 0.1, 0.001, 0.5, 0.001, "Delta-t")
v:addParam("stepsPerFrame", 2, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

local function build()
  return ch.solar({ angularMotion = v:getParam("Angular_Motion"), sunMass = v:getParam("Mass_of_Sun"),
                    G = v:getParam("Gravitational_Constant"),
                    forceMax = v:getParam("Force_Cap") and v:getParam("Force_Maximum") or 1e6,
                    speedMax = v:getParam("Velocity_Cap") and v:getParam("Velocity_Maximum") or 1000,
                    dt = v:getParam("Time_Step") })
end

scene.run({
  title = "solar_system",
  build = build,
  resetOn = { Angular_Motion = true, Mass_of_Sun = true },
  live = function(name, value, m)
    if name == "Time_Step" then m.dt = value; return true end
    if name == "Gravitational_Constant" or name == "Force_Maximum" or name == "Velocity_Maximum"
       or name == "Force_Cap" or name == "Velocity_Cap" then
      local fresh = build()            -- the law only; keep the bodies where they are
      m.law, m.G = fresh.law, fresh.G
      return true
    end
    return name == "stepsPerFrame"
  end,
  radius = function(m) return m > 10 and 4 or 1.5 end,
  colors = { "#ffc020", "#60a0ff" },
  trail = 600, trailEvery = 2, trailOf = 2,
  camHeight = 190, cx = 25,
  help = "solar_system (Ch. 2.3). Runs at load; R resets, S stops and restarts. Status: t, separation, |P|, L, KE, PE, E.",
})
-- EOF
