-- probes/batch_drones.lua -- a lib/batch.py probe for the *-Quadcopter.lua demos
--
-- Every EVERY frames (default 900, 30 s of flight) and at the end, reports:
-- flight time, drones flying under AP, crashed, the swarm's centre, and the
-- nearest-neighbour distance over the formation spacing (10th, 50th and
-- 90th percentile; 1.00 = every drone at the spacing from its nearest).
--
--   python3 lib/batch.py Formations-Newtonian-Quadcopter.lua \
--     --probe probes/batch_drones.lua --seeds 1-3 --set friction=0.3,0.5 \
--     --frames 5400 --summary nn50
--
local batch = require "lib.batch"
local Swarm = require "quadcopter.swarm"

local function sepMeters()
  local ok, r = pcall(function() return v:getParam("rad") end)
  local sep = (ok and tonumber(r)) or v:getParam("desiredSeparation")
  return sep * v:getParam("metersPerUnit")
end

local function pct(sorted, q)
  if #sorted == 0 then return "" end
  return sorted[math.max(1, math.ceil(#sorted * q))]
end

local function report(extra)
  local st = Swarm.state()
  local fly, crashed, cx, cy, cz = {}, 0, 0, 0, 0
  for _, d in ipairs(st.drones) do
    if d.state == "crashed" then crashed = crashed + 1
    elseif d.state == "ap" or d.state == "hold" then
      fly[#fly + 1] = d
      cx, cy, cz = cx + d.px, cy + d.py, cz + d.pz
    end
  end
  local n, sep, nn = #fly, sepMeters(), {}
  for i, a in ipairs(fly) do
    local best = math.huge
    for j, b in ipairs(fly) do
      if i ~= j then
        local r = math.sqrt((a.px - b.px) ^ 2 + (a.py - b.py) ^ 2 + (a.pz - b.pz) ^ 2)
        if r < best then best = r end
      end
    end
    if best < math.huge then nn[#nn + 1] = best / sep end
  end
  table.sort(nn)
  local row = {
    t = string.format("%.1f", st.simTime), drones = #st.drones, flying = n, crashed = crashed,
    cx = n > 0 and cx / n or "", cy = n > 0 and cy / n or "", cz = n > 0 and cz / n or "",
    nn10 = pct(nn, 0.1), nn50 = pct(nn, 0.5), nn90 = pct(nn, 0.9),
  }
  for k, val in pairs(extra or {}) do row[k] = val end
  batch.row(row, { "t", "drones", "flying", "crashed", "nn10", "nn50", "nn90" })
end

batch.every(tonumber(os.getenv("EVERY") or "") or 900, function() report() end)
batch.atEnd(function() report({ final = 1 }) end)
