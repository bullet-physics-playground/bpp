--
-- Spring3D -- spring2D.nlogo with a third axis (ours, not in the book).
-- Sliders as in Spring2D.lua, plus Angular_Motion_Z.
--
-- Each particle starts in a random direction (uniform on the sphere),
-- 1 + random(D) from the origin; the light mass moves along x at
-- Angular_Motion and along z at Angular_Motion_Z, the heavy one at minus
-- those over Mass_Ratio, so the total momentum is 0. R gives a new start.
--
-- What to see: two bodies on a spring always move in one plane, the plane
-- through the centre of mass that is perpendicular to the angular momentum
-- L. So in 3D the spinning spring of Ch. 2.2 picks a tilted plane at random
-- and stays in it: |L| stays constant and so does its direction (tilt stays
-- 0). |P| stays 0, E swings but does not drift, and the separation still
-- stretches past D. The blue trail follows the light mass and traces the
-- plane. Drag the view to see the plane edge on.
--
-- Status line: t time, sep separation, |P| total linear momentum, |L| size
-- of the angular momentum about the centre of mass, tilt the angle between
-- L now and at the start (degrees), KE / PE / E kinetic, potential and total
-- energy. Full definitions in ch02/scene.lua.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"

v:addParam("Angular_Motion", 200, 0, 400, 1, "x velocity of the light mass (the heavy one gets -AM / Mass_Ratio); applies on R")
v:addParam("Angular_Motion_Z", 0, 0, 400, 1, "z velocity of the light mass (the heavy one gets -AMz / Mass_Ratio); applies on R")
v:addParam("Mass_Ratio", 10, 1, 20, 1, "mass of the heavy particle; applies on R")
v:addParam("Spring_Constant", 10, 1, 20, 0.5, "k")
v:addParam("Friction", 0, 0, 0.01, 0.0001, "v <- (1 - Friction) v each step")
v:addParam("Time_Step", 0.001, 0.0001, 0.02, 0.0001, "Delta-t")
v:addParam("Desired_Spring_Length", 50, 10, 100, 1, "D")
v:addParam("stepsPerFrame", 10, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

scene.run({
  title = "spring3D",
  threeD = true,
  build = function()
    return ch.spring3D({ angularMotion = v:getParam("Angular_Motion"),
                         angularMotionZ = v:getParam("Angular_Motion_Z"),
                         massRatio = v:getParam("Mass_Ratio"),
                         k = v:getParam("Spring_Constant"), friction = v:getParam("Friction"),
                         dt = v:getParam("Time_Step"), D = v:getParam("Desired_Spring_Length") })
  end,
  resetOn = { Mass_Ratio = true, Angular_Motion = true, Angular_Motion_Z = true },
  live = function(name, value, m)
    if name == "Spring_Constant" then ch.setSpring(m, value, nil); return true end
    if name == "Desired_Spring_Length" then ch.setSpring(m, nil, value); return true end
    if name == "Friction" then m.law.friction = value; return true end
    if name == "Time_Step" then m.dt = value; return true end
    return name == "stepsPerFrame"
  end,
  radius = function(m) return 2 * m ^ (1 / 3) end,
  colors = { "#ffffff", "#ffd040" },
  springLine = true,
  trail = 600, trailEvery = 5, trailOf = 1,
  camHeight = 330,
  help = "spring3D (ours: spring2D in 3D). Runs at load; R gives a new random start, S stops and restarts. Status: t, separation, |P|, |L|, tilt of L, KE, PE, E.",
})
-- EOF
