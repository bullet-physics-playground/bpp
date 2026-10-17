-- appended (-l) to a *-Quadcopter.lua run: sets mode from env, then every
-- 30 s of flight logs the swarm's progress through the obstacle field
local Swarm = require "quadcopter.swarm"
if os.getenv("DIM") == "2" then setDimension(false) elseif os.getenv("DIM") == "3" then setDimension(true) end
if os.getenv("SQUARE") == "1" then toggleFormation() end
if os.getenv("FIELD") == "0" then v:addParam("obstacleField", false, "") end
for _, k in ipairs({ "goalForce", "goalSpeed", "fieldDensity", "apHz", "layerGain", "range", "forceMax" }) do
  local e = os.getenv(k:upper()) or os.getenv(({ layerGain = "LAYER", forceMax = "FMAX" })[k] or "")
  if e then v:addParam(k, tonumber(e), 0, 100, 0.01, "") end
end
if os.getenv("SEED") then math.randomseed(tonumber(os.getenv("SEED"))); setup(math.floor(v:getParam("numDrones"))) end

local SEP = v:getParam(os.getenv("SEPNAME") or "rad") * v:getParam("metersPerUnit")
local nextLog = 30
v:preDraw(function(N)
  local st = Swarm.state()
  if st.simTime < nextLog then return end
  nextLog = nextLog + 30
  local n, cx, past, inField, before, crashed, maxX, minX = 0, 0, 0, 0, 0, 0, -1e9, 1e9
  for _, d in ipairs(st.drones) do
    if d.state == "crashed" then crashed = crashed + 1
    elseif d.state == "ap" or d.state == "hold" then
      n = n + 1; cx = cx + d.px
      maxX, minX = math.max(maxX, d.px), math.min(minX, d.px)
      if d.px < -38 then past = past + 1 elseif d.px < -2 then inField = inField + 1 else before = before + 1 end
    end
  end
  -- lattice bonds among drones past the field (once there)
  local bonds, sum, sq = 0, 0, 0
  for i, a in ipairs(st.drones) do
    if a.state == "ap" and a.px < -38 then
      for j = i + 1, #st.drones do
        local b = st.drones[j]
        if b.state == "ap" and b.px < -38 then
          local r = math.sqrt((a.px - b.px) ^ 2 + (a.py - b.py) ^ 2 + (a.pz - b.pz) ^ 2)
          if r < 1.2 * SEP then bonds = bonds + 1; sum = sum + r / SEP; sq = sq + (r / SEP) ^ 2 end
        end
      end
    end
  end
  local m = bonds > 0 and sum / bonds or 0
  -- drones on flight levels (sqrt(2/3) x spacing apart, phase from the drones)
  local h = SEP * math.sqrt(2 / 3)
  local sx, sy, fl = 0, 0, {}
  for _, d in ipairs(st.drones) do if d.state == "ap" then fl[#fl + 1] = d; local a = 2 * math.pi * d.py / h; sx, sy = sx + math.cos(a), sy + math.sin(a) end end
  local y0 = math.atan2(sy, sx) * h / (2 * math.pi)
  local onLevel = 0
  for _, d in ipairs(fl) do
    local k = math.floor((d.py - y0) / h + 0.5)
    if math.abs(d.py - (y0 + k * h)) < 0.15 * h then onLevel = onLevel + 1 end
  end
  print(string.format("FIELD t=%4.0f onLevel=%d/%d | flying=%d crashed=%d | centroid x=%6.1f (span %6.1f..%6.1f) | before=%d inField=%d past=%d | past-lattice bonds=%d len=%.3fR sd=%.3fR",
    st.simTime, onLevel, #fl, n, crashed, n > 0 and cx / n or 0, minX, maxX, before, inField, past, bonds, m,
    bonds > 0 and math.sqrt(math.max(0, sq / bonds - m * m)) or 0))
end)
