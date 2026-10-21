-- rope-test.lua: can bpp model a cord over a pulley? An Atwood machine:
-- a rope of linked spheres (ball joints) over a fixed, smooth pulley, a
-- weight on each end. Prints the rope's stretch, whether it stays on the
-- pulley, and the weights' acceleration against the textbook answer.
--
-- bpp has no rope of its own (its soft bodies are cloth); this is the
-- workaround, measured in MACHINES.md ("Rope"). From the top folder:
--   ROPE_HZ=2400 ROPE_N=60 ROPE_M=0.05 ROPE_IT=100 build/release/bpp --     -f demo/WyomingWill/BabbagesHall/tools/rope-test.lua -n 90
-- works (stretch under 0.3%, acceleration within a few % of theory until
-- the lighter weight reaches the pulley); ROPE_M=0.01 with 120 beads (each
-- bead 2500 times lighter than a weight) breaks.
local common = require "common"
local N_SEG = tonumber(os.getenv("ROPE_N") or "") or 120
local SUB = tonumber(os.getenv("ROPE_HZ") or "") or 1200
local STEP = 1 / SUB
local NSTEPS = math.floor(SUB / 60 + 0.5)
common.setTiming(STEP, 0, STEP)
v:preSim(function(N) for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
pcall(function() v:setSolverIterations(tonumber(os.getenv("ROPE_IT") or "") or 50) end)
v.gravity = btVector3(0, -981, 0)

local R_P = 5            -- pulley radius (cm)
local PY = 60            -- pulley axle height
local LEG = 25           -- each straight leg at the start
local r = 0.25           -- the rope's spheres
local M1, M2 = 0.200, 0.250
local ROPE_M = tonumber(os.getenv("ROPE_M") or "") or 0.010     -- the whole rope (kg)

local pulley = Cylinder(R_P, 2, 0)
pulley.pos = btVector3(0, PY, 0)
pulley.col = "#a07040"
v:add(pulley)
pcall(function() pulley.body:setFriction(0) end)

-- the rope's path: up the left leg, over the top, down the right leg
local L = 2 * LEG + math.pi * (R_P + r)
local function pathAt(s)
  if s < LEG then return btVector3(-(R_P + r), PY - LEG + s, 0) end
  s = s - LEG
  local arc = math.pi * (R_P + r)
  if s < arc then
    local a = math.pi - s / (R_P + r)
    return btVector3((R_P + r) * math.cos(a), PY + (R_P + r) * math.sin(a), 0)
  end
  s = s - arc
  return btVector3(R_P + r, PY - s, 0)
end
local seg = L / N_SEG
local beads = {}
for i = 0, N_SEG do
  local b = Sphere(r, ROPE_M / (N_SEG + 1))
  b.pos = pathAt(i * seg)
  b.col = "#ddd"
  v:add(b)
  pcall(function() b.body:setFriction(0); b.body:setActivationState(4) end)
  beads[i] = b
end
local function link(a, b, pa, pb)
  local cn = btPoint2PointConstraint(a.body, b.body, pa, pb)
  v:addConstraint(cn)
end
for i = 1, N_SEG do
  local p, q = beads[i - 1].pos, beads[i].pos
  local mid = (p + q) * 0.5
  link(beads[i - 1], beads[i], mid - p, mid - q)
end
local function weight(m, end_, down)
  local w = Cube(3, 3, 3, m)
  w.pos = end_.pos + btVector3(0, -2.0, 0)
  v:add(w)
  pcall(function() w.body:setActivationState(4) end)
  link(end_, w, btVector3(0, -0.5, 0), btVector3(0, 1.5, 0))
  return w
end
local w1 = weight(M1, beads[0])
local w2 = weight(M2, beads[N_SEG])

local a_theory = 981 * (M2 - M1) / (M1 + M2 + ROPE_M)
local y1_0, frames = w1.pos.y, 0
local function stretch()
  local tot = 0
  for i = 1, N_SEG do tot = tot + (beads[i].pos - beads[i - 1].pos):length() end
  return tot / L - 1
end
v:postSim(function(N)
  frames = frames + 1
  local t = frames / 60
  if frames % 6 == 0 then
    local onTop = beads[math.floor(N_SEG / 2)].pos
    local dy = w1.pos.y - y1_0
    print(string.format("ROPE t %.2f  w1 rose %.2f cm  (a measured %.1f, theory %.1f cm/s^2)  stretch %.3f%%  middle bead %.2f cm from pulley centre",
      t, dy, 2 * dy / (t * t), a_theory, 100 * stretch(), (onTop - pulley.pos):length()))
  end
end)
