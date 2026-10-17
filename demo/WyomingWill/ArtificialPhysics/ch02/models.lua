--
-- ch02/models.lua -- Ch. 2's three NetLogo models on the book's integrator
--
-- spring1D.nlogo, spring2D.nlogo and solar_system.nlogo (PDF 58-85,
-- book/ch02.md) as plain Lua on lib/monitors.lua, which implements the
-- models' step (friction first, all forces from one snapshot, then
-- semi-implicit Euler, Listings 2.1-2.6). Used by the BPP scenes in this
-- folder and by checks/ch02.lua.
--
-- Each constructor takes the book's sliders (defaults as in the book's
-- figures) and returns a model { ps, law, dt, ... }:
--   m.ps   the particles (x, y, z, vx, vy, vz, m); the book's 2D plane is
--          our x-y here, drawn in BPP as x and -z (lib/world.lua's mapping)
--   m.law  forces and potential for lib/monitors.lua (> 0 repels)
--   m.dt   the time step
--   M.step(m) advances one step; M.measure(m) gives the monitors.
--
-- Choices where the book is silent (also in ch02/README.md):
--   * spring2D's starting geometry is not stated: the masses start apart
--     along y, as spring1D's along x (each 1 + random(D/2) from the
--     origin), so the x velocities set them spinning.
--   * solar_system's velocity cap clips the speed (its code is not shown).
--   * With a force cap, the potential is the one that matches the capped
--     force: -G m1 m2 / r outside the cap radius rc = sqrt(G m1 m2 / Fmax),
--     and Fmax (r - rc) - G m1 m2 / rc inside it, so the energy monitor
--     stays meaningful when the cap is on.
--

package.path = "../?.lua;" .. package.path    -- lib/ when run from ch02/
local mon = require "lib.monitors"
local rng = require "lib.rng"

local M = {}

local function spring(k, D)
  return {
    pair = function(r) return -k * (r - D) end,
    potential = function(r) return 0.5 * k * (r - D) ^ 2 end,
  }
end

-- spring1D (Fig. 2.1 defaults). opts: massRatio 1, k 10, friction 0,
-- dt 0.001, D 50, seed (for the starting offsets; nil = the shared stream).
function M.spring1D(o)
  o = o or {}
  local D = o.D or 50
  local s = o.seed and rng.new(o.seed) or rng.shared
  local function off() return 1 + s:random(0, math.floor(D / 2) - 1) end
  local m = { kind = "spring1D", D = D, k = o.k or 10, dt = o.dt or 0.001 }
  m.ps = { { x = -off(), m = 1 }, { x = off(), m = o.massRatio or 1 } }
  m.law = spring(m.k, D)
  m.law.friction = o.friction or 0
  return m
end

-- spring2D (Fig. 2.9 defaults). opts: angularMotion 200, massRatio 10,
-- k 10, friction 0, dt 0.001, D 50, seed.
function M.spring2D(o)
  o = o or {}
  local D = o.D or 50
  local s = o.seed and rng.new(o.seed) or rng.shared
  local function off() return 1 + s:random(0, math.floor(D / 2) - 1) end
  local mr, am = o.massRatio or 10, o.angularMotion or 200
  local m = { kind = "spring2D", D = D, k = o.k or 10, dt = o.dt or 0.001 }
  m.ps = { { y = -off(), vx = am, m = 1 }, { y = off(), vx = -am / mr, m = mr } }
  m.law = spring(m.k, D)
  m.law.friction = o.friction or 0
  return m
end

-- The capped inverse-square law and its matching potential.
local function gravity(G, fmax)
  local law = {}
  law.pair = function(r, a, b) return -G * a.m * b.m / (r * r) end
  if fmax then law.forceMax = fmax end
  law.potential = function(r, a, b)
    local gm = G * a.m * b.m
    if fmax then
      local rc = math.sqrt(gm / fmax)
      if r < rc then return fmax * (r - rc) - gm / rc end
    end
    return -gm / r
  end
  return law
end

-- solar_system (Fig. 2.11 defaults). opts: angularMotion 15, sunMass 100,
-- G 20, forceMax 1e6 (effectively off), speedMax 1000 (off), dt 0.1.
-- Sun at the origin moving -AM/Msun along y, planet (mass 1) at (15, 0)
-- moving +AM along y, so the total momentum is 0.
function M.solar(o)
  o = o or {}
  local am, ms = o.angularMotion or 15, o.sunMass or 100
  local m = { kind = "solar", dt = o.dt or 0.1, G = o.G or 20 }
  m.ps = { { x = 0, vy = -am / ms, m = ms, name = "sun" }, { x = 15, vy = am, m = 1, name = "planet" } }
  local fmax = o.forceMax or 1e6
  m.law = gravity(m.G, fmax < 1e6 and fmax or nil)
  m.law.speedMax = (o.speedMax or 1000) < 1000 and o.speedMax or nil
  return m
end

function M.step(m) mon.step(m.ps, m.dt, m.law) end

-- Monitors: the lib/monitors.lua measurement plus the separation (and, for
-- the solar system, the planet's distance from the sun and its speed).
function M.measure(m)
  local r = mon.measure(m.ps, m.law)
  r.sep = mon.dist(m.ps[1], m.ps[2])
  local p = m.ps[2]
  r.speed2 = math.sqrt((p.vx or 0) ^ 2 + (p.vy or 0) ^ 2 + (p.vz or 0) ^ 2)
  return r
end

-- Changing a law setting mid-run (as the book does with D and k).
function M.setSpring(m, k, D)
  m.k, m.D = k or m.k, D or m.D
  local fr = m.law.friction
  m.law = spring(m.k, m.D)
  m.law.friction = fr
end

return M
