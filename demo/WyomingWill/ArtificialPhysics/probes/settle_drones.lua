-- probes/settle_drones.lua -- a lib/batch.py probe: does the drone lattice
-- settle? Ch. 16.9's measures for the Ch. 13 work (milestone M1), and for
-- every vehicle behind lib/swarm.lua since M2 ("drones" below = agents)
--
-- Samples the swarm once a second of flight and reports a row every EVERY
-- frames (default 900, about 29 s of flight) and at the end. DEFINITIONS
-- (each row's window runs from the previous row to this one; t counts from
-- when AP engaged):
--   t          flight time since AP engaged, s
--   flying     drones under AP control or holding; crashed = drones down
--   cx         mean x of the flying drones, m (the obstacle field's goal
--              travels along -x from 0 and stops at -54)
--   speed      mean |actual velocity| of the AP drones, m/s (window mean)
--   acc        mean scalar acceleration |dv/dt| of the AP drones, from
--              their actual velocities one AP tick apart, m/s^2
--              (swarm.lua METRICS; Ch. 16.9's settling measure)
--   gap        mean suggested-position difference |actual - waypoint AP
--              issued one tick before|, m (Ch. 16.9)
--   cross      AR-boundary crossings per drone per minute (pairs whose
--              distance changed side of D between two AP ticks, each pair
--              once, x 2 / drones; book/ch13.md E11)
--   cv         Ch. 16.9 lattice quality: CV (sd/mean) of the Delaunay edge
--              lengths between drones within 80% of the swarm's maximum
--              radius from its centroid, in the horizontal plane. 2D only
--              (blank in 3D). Snapshot at the row's time
--   nncv       CV of each drone's nearest-neighbour distance (2D and 3D)
--   bond, bondcv  mean length (/ spacing) and CV of all pairs closer than
--              1.2 x spacing (swarm.lua's "bonds")
--   settleA    the time t after which the 1-s mean acc stayed below
--              ACC_SETTLE (default 0.10 m/s^2) to the end of the run, s;
--              -1 if the last second was still above (not settled)
--   settleV    the same for the 1-s mean speed below V_SETTLE (default
--              0.05 m/s)
--   formed     the time t after which the lattice is formed and still to
--              the end of the run: bond (below, sampled every second) at
--              least B_FORMED (default 0.97) x the spacing AND mean speed
--              below V_FORMED (default 0.01 m/s); -1 if not by the end.
--              settleA and settleV alone miss a lattice that is still
--              slowly growing (FIXES 41): use this one for "settled".
--   goaldist   horizontal distance from the flying drones' centroid to the
--              goal, m (snapshot)
--   past       with the obstacle field: the share of the flying drones
--              beyond the field's far edge (x < -38 m; snapshot)
--   through    the first t at which past >= 0.9 (90% of the swarm through
--              the field), s; -1 if not (yet). Sampled once a second
--   near4      the share of the flying drones within 4 spacings of the
--              goal (Ch. 14's "reached the goal", Eq. 14.5; snapshot)
--   contacts   agent-agent touches since Setup (lib/swarm.lua METRICS)
--   hits       agent-column touches since Setup
--   final      1 on the row written when the run ends
-- Lengths in metres; the spacing is rad or desiredSeparation x
-- metersPerUnit (3 m by default).
--
-- Environment: DIM=2 or 3 picks the dimension, SQUARE=1 the square/cube
-- formation (each re-applies the mode's defaults, then this run's --set
-- values again, then sets up a new launch); EVERY, ACC_SETTLE, V_SETTLE;
-- SERIES=1 also writes a row every second (series=1) for plotting.
-- SWITCH_AT=t and SWITCH_SET="name=value;..." change those sliders t s
-- after AP engages, as if moved by hand mid-run (e.g. turn etaPower on
-- once the lattice has formed); the change is printed and the settling
-- clock (settleA/V) then counts from the start of the run as before.
--
--   python3 lib/batch.py Formations-Newtonian-Quadcopter.lua \
--     --probe probes/settle_drones.lua --env DIM=2 --seeds 1-3 \
--     --set obstacleField=false --set goalDelay=0 --set etaPower=0,2.2 \
--     --frames 5600 --out eta2d.csv --summary settleA
--
local batch   = require "lib.batch"
local Swarm   = require "quadcopter.swarm"
local Lattice = require "lib.lattice"

local ACC_SETTLE = tonumber(os.getenv("ACC_SETTLE") or "") or 0.10
local V_SETTLE   = tonumber(os.getenv("V_SETTLE") or "") or 0.05
local SERIES     = os.getenv("SERIES") == "1"
local B_FORMED   = tonumber(os.getenv("B_FORMED") or "") or 0.97
local V_FORMED   = tonumber(os.getenv("V_FORMED") or "") or 0.01

-- the mode, then this run's own settings again (the mode's defaults would
-- otherwise overwrite them), then a fresh launch
do
  local dim, square = os.getenv("DIM"), os.getenv("SQUARE") == "1"
  if square or dim then
    if square then toggleFormation() end
    if dim then setDimension(dim == "3") end
    for _, kv in ipairs(batch.settings()) do batch.set(kv[1], kv[2]) end
    setup(math.floor(v:getParam("numDrones")))
  end
end

local function sepMeters()
  local ok, r = pcall(function() return v:getParam("rad") end)
  local sep = (ok and tonumber(r)) or v:getParam("desiredSeparation")
  return sep * v:getParam("metersPerUnit")
end

local series = {}        -- { t, acc, speed } once a second after AP engaged
local lastM, lastRow = nil, nil
local lastSampleT = -1

local function snapshot()
  local st = Swarm.state()
  local m = st.metrics
  return { accSum = m.accSum, accN = m.accN, gapSum = m.gapSum, gapN = m.gapN,
           crossings = m.crossings, droneTicks = m.droneTicks, t = st.simTime }
end

local function apSpeed(st)
  local n, s = 0, 0
  for _, d in ipairs(st.drones) do
    if d.state == "ap" then n = n + 1; s = s + math.sqrt(d.vx * d.vx + d.vy * d.vy + d.vz * d.vz) end
  end
  return n > 0 and s / n or 0, n
end

-- the centroid's horizontal distance to the goal, m (nil without one)
local function goalDist(st)
  if not st.goal then return nil end
  local n, x, z = 0, 0, 0
  for _, d in ipairs(st.drones) do
    if d.state == "ap" or d.state == "hold" then n = n + 1; x, z = x + d.px, z + d.pz end
  end
  if n == 0 then return nil end
  return math.sqrt((x / n - st.goal.x) ^ 2 + (z / n - st.goal.z) ^ 2)
end
local throughT = nil
-- the share of the flying drones past the field's far edge, and within 4
-- spacings of the goal (nil without a field / goal)
local function shares(st)
  local n, past, near = 0, 0, 0
  local r4 = 4 * sepMeters()
  for _, d in ipairs(st.drones) do
    if d.state == "ap" or d.state == "hold" then
      n = n + 1
      if st.field and d.px < st.field.xFar then past = past + 1 end
      if st.goal and (d.px - st.goal.x) ^ 2 + (d.pz - st.goal.z) ^ 2 < r4 * r4 then near = near + 1 end
    end
  end
  if n == 0 then return nil, nil end
  return st.field and past / n or nil, st.goal and near / n or nil
end

local SWITCH_AT = tonumber(os.getenv("SWITCH_AT") or "")
local switched = false

local function sample()
  local st = Swarm.state()
  if not st.apEngaged then return end
  if SWITCH_AT and not switched and st.simTime - st.apEngagedAt >= SWITCH_AT then
    switched = true
    for _, kv in ipairs(batch.settings(os.getenv("SWITCH_SET") or "")) do batch.set(kv[1], kv[2]) end
    print(string.format("probe: t=%.1f s after AP: set %s", st.simTime - st.apEngagedAt, os.getenv("SWITCH_SET") or ""))
  end
  local now = snapshot()
  local past = shares(st)
  if not throughT and past and past >= 0.9 then throughT = st.simTime - st.apEngagedAt end
  if lastM and now.accN > lastM.accN then
    local t = st.simTime - st.apEngagedAt
    local acc = (now.accSum - lastM.accSum) / (now.accN - lastM.accN)
    local speed = apSpeed(st)
    local pts = {}
    for _, d in ipairs(st.drones) do
      if d.state == "ap" or d.state == "hold" then pts[#pts + 1] = { x = d.px, y = d.pz, z = d.py } end
    end
    local _, bond = Lattice.bondCV(pts, sepMeters())
    local formed = (bond and bond >= B_FORMED and speed < V_FORMED) and 0 or 1
    series[#series + 1] = { t = t, acc = acc, speed = speed, unformed = formed }
    if SERIES then batch.row({ series = 1, t = string.format("%.1f", t), acc = acc, speed = speed }, { "series", "t" }) end
  end
  lastM = now
end

local function settleTime(key, thr)
  if #series == 0 then return "" end
  if series[#series][key] >= thr then return -1 end
  local t = 0
  for i = #series, 1, -1 do
    if series[i][key] >= thr then t = series[i].t; break end
  end
  return string.format("%.1f", t)
end

local function report(extra)
  local st = Swarm.state()
  local now = snapshot()
  local base = lastRow or { accSum = 0, accN = 0, gapSum = 0, gapN = 0, crossings = 0, droneTicks = 0, t = st.apEngagedAt }
  local fly, crashed, pts2, pts3, sx = 0, 0, {}, {}, 0
  for _, d in ipairs(st.drones) do
    if d.state == "crashed" then crashed = crashed + 1
    elseif d.state == "ap" or d.state == "hold" then
      fly = fly + 1
      sx = sx + d.px
      pts2[#pts2 + 1] = { x = d.px, y = d.pz }
      pts3[#pts3 + 1] = { x = d.px, y = d.pz, z = d.py }
    end
  end
  -- window means of the once-a-second samples
  local wAcc, wSpd, k = 0, 0, 0
  local t0 = (lastRow and lastRow.t or st.apEngagedAt) - st.apEngagedAt
  for _, s in ipairs(series) do
    if s.t > t0 then wAcc, wSpd, k = wAcc + s.acc, wSpd + s.speed, k + 1 end
  end
  local dTicks = now.droneTicks - base.droneTicks
  local minutes = (now.t - base.t) / 60
  local sep = sepMeters()
  local cv = (not st.is3D) and Lattice.delaunayCV(pts2) or nil
  local nncv = Lattice.nnCV(pts3)
  local bondcv, bond = Lattice.bondCV(pts3, sep)
  local row = {
    t = string.format("%.1f", st.apEngaged and st.simTime - st.apEngagedAt or 0),
    flying = fly, crashed = crashed, cx = fly > 0 and sx / fly or "",
    speed = k > 0 and wSpd / k or "", acc = k > 0 and wAcc / k or "",
    gap = now.gapN > base.gapN and (now.gapSum - base.gapSum) / (now.gapN - base.gapN) or "",
    cross = (fly > 0 and minutes > 0) and 2 * (now.crossings - base.crossings) / fly / minutes or "",
    cv = cv or "", nncv = nncv or "", bond = bond or "", bondcv = bondcv or "",
    settleA = settleTime("acc", ACC_SETTLE), settleV = settleTime("speed", V_SETTLE),
    formed = settleTime("unformed", 0.5),
    contacts = st.metrics.contacts, hits = st.metrics.hits,
    goaldist = goalDist(st) or "", past = (shares(st)) or "", near4 = select(2, shares(st)) or "",
    through = st.field and (throughT and string.format("%.1f", throughT) or -1) or "",
  }
  for kk, val in pairs(extra or {}) do row[kk] = val end
  batch.row(row, { "t", "flying", "crashed", "cx", "speed", "acc", "gap", "cross", "cv", "nncv", "bond", "bondcv", "formed", "settleA", "settleV", "contacts", "hits", "goaldist", "past", "through", "near4" })
  lastRow = now
end

-- once a second of flight (checked every frame: a frame is ~0.032 s, so
-- checking every 30 frames sampled only every ~1.9 s; FIXES 40)
batch.every(1, function()
  local st = Swarm.state()
  if st.simTime - lastSampleT >= 0.999 then lastSampleT = st.simTime; sample() end
end)
batch.every(tonumber(os.getenv("EVERY") or "") or 900, function()
  if Swarm.state().apEngaged then report() end
end)
batch.atEnd(function() report({ final = 1 }) end)
