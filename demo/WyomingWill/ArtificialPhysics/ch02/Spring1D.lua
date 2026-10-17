--
-- Spring1D -- Ch. 2.1, spring1D.nlogo (PDF 58-72): two masses on a Hooke
-- spring along x. Sliders as in the NetLogo model (Fig. 2.1 defaults).
--
-- What to see (book/ch02.md 2.1): the separation (status line) oscillates
-- about Desired_Spring_Length; |P| stays exactly 0; E stays constant with
-- Friction 0; Mass_Ratio 10 makes the heavy mass barely move, with the
-- red centre of mass beside it; Friction > 0 drains E to 0 and the
-- separation settles at D; changing D or k mid-run moves E to a new
-- constant level. Keys: S start/stop, R reset.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch02.scene"
local ch = require "ch02.models"

v:addParam("Mass_Ratio", 1, 1, 10, 1, "mass of the right particle (the left is 1); applies on R")
v:addParam("Spring_Constant", 10, 1, 20, 0.5, "k")
v:addParam("Friction", 0, 0, 0.01, 0.0001, "v <- (1 - Friction) v each step")
v:addParam("Time_Step", 0.001, 0.0001, 0.02, 0.0001, "Delta-t")
v:addParam("Desired_Spring_Length", 50, 10, 100, 1, "D")
v:addParam("stepsPerFrame", 40, 1, 400, 1, "integrator steps per drawn frame (display speed only)")

scene.run({
  title = "spring1D",
  build = function()
    return ch.spring1D({ massRatio = v:getParam("Mass_Ratio"), k = v:getParam("Spring_Constant"),
                         friction = v:getParam("Friction"), dt = v:getParam("Time_Step"),
                         D = v:getParam("Desired_Spring_Length") })
  end,
  resetOn = { Mass_Ratio = true },
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
  camHeight = 75,
  help = "spring1D (Ch. 2.1). S start/stop, R reset. Status: t, separation, |P|, L, KE, PE, E.",
})
-- EOF
