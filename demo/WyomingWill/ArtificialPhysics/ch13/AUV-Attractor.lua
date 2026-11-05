--
-- AUV-Attractor -- one torpedo-shaped AUV (auv/model.lua: Prestero's
-- REMUS, 0.5-2.3 m/s, turn radius at least 6.03 m at every speed) and
-- one attractor at its depth: the AUV's counterpart of the UAV's Fig. 13.13
-- (ch13/auv.lua; ch13/README.md). It starts at the origin heading east
-- (+x) at cruise speed (1.54 m/s); its smallest turn circles (radius
-- R = 6.03 m, centred R to its left and right) are the unreachable zones.
--
--   case 1  attractor 2R directly behind
--   case 2  attractor outside both zones, (1.5R, 1.5R)
--   case 3  attractor inside the left zone, (0, R/2)
--   law     0 gravity (point-mass, Eq. 13.8), 1 torque (Eqs. 13.15-13.18)
--   speed   0 fixed at cruise (as the book's UAV), 1 Eq. 13.21's speed
--           channel: fast when the attractor is ahead, slow behind
--
-- STATUS LINE:
--   t        time, s
--   d        distance to the attractor now, m
--   near     share of the time so far within R of it
--   u        speed now, m/s
--   |Omega|  mean turn rate so far, rad/s
-- R restarts.
--
package.path = "../?.lua;" .. package.path
local scene = require "ch13.uavscene"
local U = require "ch13.auv"
local A = require "auv.model"
local status = require "lib.status"
local R = A.R_MIN
local CASES = { { -2 * R, 0 }, { 1.5 * R, 1.5 * R }, { 0, R / 2 } }
v:addParam("case", 1, 1, 3, 1, "1 behind, 2 outside the unreachable zones, 3 inside one")
v:addParam("law", 1, 0, 1, 1, "0 = point-mass (gravity) law, 1 = torque law")
v:addParam("speed", 1, 0, 1, 1, "0 = fixed cruise speed, 1 = speed channel (Eq. 13.21)")
local n, near, om = 0, 0, 0
scene.run({
  title = "Ch. 13: one AUV, one attractor",
  module = U, dart = A.LENGTH, camHeight = 60,
  build = function()
    n, near, om = 0, 0, 0
    local c = CASES[math.floor(v:getParam("case"))] or CASES[1]
    return U.newWorld({ law = v:getParam("law") >= 0.5 and "torque" or "gravity",
                        fixedSpeed = v:getParam("speed") < 0.5,
                        auvs = { A.new(0, 0, 0) }, targets = { { x = c[1], y = c[2] } } })
  end,
  status = function(w)
    local a, tg = w.auvs[1], w.targets[1]
    local d = math.sqrt((a.x - tg.x) ^ 2 + (a.y - tg.y) ^ 2)
    n, om = n + 1, om + math.abs(a.omega)
    if d < R then near = near + 1 end
    return { "Ch. 13: one AUV, one attractor", status.num("t", w.t, 0, false, 6, "s"),
             status.num("d", d, 1, false, 6, "m"), status.pct("near", 100 * near / n, 1),
             status.num("u", a.u, 2, false, 4, "m/s"), status.num("|Omega|", om / n, 3, false) }
  end,
  help = "R restart | case 1-3 | law 0 gravity, 1 torque | speed 0 fixed, 1 channel | ticksPerFrame: speed",
})
