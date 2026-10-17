--
-- Spring2D -- Ch. 2.2, spring2D.nlogo (PDF 73-77): a spinning spring.
-- Sliders as in the NetLogo model (Fig. 2.9 defaults).
--
-- What to see (book/ch02.md 2.2): the spring rotates about the red centre
-- of mass while stretching and compressing; |P| stays 0 and L stays
-- constant (negative L would be clockwise); the separation often exceeds
-- 2D = 100 and averages more than D (centrifugal stretch). The blue trail
-- follows the light mass. Keys: S start/stop, R reset.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"

v:addParam("Angular_Motion", 200, 0, 400, 1, "x velocity of the light mass (the heavy one gets -AM / Mass_Ratio); applies on R")
v:addParam("Mass_Ratio", 10, 1, 20, 1, "mass of the heavy particle; applies on R")
v:addParam("Spring_Constant", 10, 1, 20, 0.5, "k")
v:addParam("Friction", 0, 0, 0.01, 0.0001, "v <- (1 - Friction) v each step")
v:addParam("Time_Step", 0.001, 0.0001, 0.02, 0.0001, "Delta-t")
v:addParam("Desired_Spring_Length", 50, 10, 100, 1, "D")
v:addParam("stepsPerFrame", 10, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

scene.run({
  title = "spring2D",
  build = function()
    return ch.spring2D({ angularMotion = v:getParam("Angular_Motion"), massRatio = v:getParam("Mass_Ratio"),
                         k = v:getParam("Spring_Constant"), friction = v:getParam("Friction"),
                         dt = v:getParam("Time_Step"), D = v:getParam("Desired_Spring_Length") })
  end,
  resetOn = { Mass_Ratio = true, Angular_Motion = true },
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
  trail = 400, trailEvery = 5, trailOf = 1,
  camHeight = 190,
  help = "spring2D (Ch. 2.2). S start/stop, R reset. Status: t, separation, |P|, L, KE, PE, E.",
})
-- EOF
