local Swarm = require "quadcopter.swarm"
setDimension(true)
if os.getenv("FIELD") == "0" then v:addParam("obstacleField", false, "") end
for _, k in ipairs({ "launchOrder", "launchGap", "goalDelay", "layerGain" }) do
  local e = os.getenv(k:upper()); if e then v:addParam(k, tonumber(e), 0, 20000, 0.01, "") end
end
math.randomseed(tonumber(os.getenv("SEED") or "1"))
setup(50)
local ok, rr = pcall(function() return v:getParam("rad") end)
local SEPR = (ok and rr and rr > 0) and rr or v:getParam("desiredSeparation")
local nextLog = 30
v:preDraw(function()
  local st = Swarm.state()
  if st.simTime < nextLog then return end
  nextLog = nextLog + 30
  local R = SEPR * v:getParam("metersPerUnit")
  local h = R * math.sqrt(2 / 3)
  local pts, crashed = {}, 0
  for _, d in ipairs(st.drones) do
    if d.state == "ap" then pts[#pts + 1] = { d.px, d.py, d.pz } elseif d.state == "crashed" then crashed = crashed + 1 end
  end
  if #pts < 2 then return end
  -- level phase (circular mean), level of each drone
  local sx, sy = 0, 0
  for _, a in ipairs(pts) do local t = 2 * math.pi * a[2] / h; sx, sy = sx + math.cos(t), sy + math.sin(t) end
  local y0 = math.atan2(sy, sx) * h / (2 * math.pi)
  local lv, onLevel = {}, 0
  for _, a in ipairs(pts) do
    local k = math.floor((a[2] - y0) / h + 0.5); a[4] = k; lv[k] = (lv[k] or 0) + 1
    if math.abs(a[2] - (y0 + k * h)) < 0.15 * h then onLevel = onLevel + 1 end
  end
  local coord, good, all = 0, 0, 0
  for i, a in ipairs(pts) do
    local inl = {}
    for j, b in ipairs(pts) do
      if i ~= j then
        local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r > 0.8 * R and r < 1.2 * R then
          coord = coord + 1
          if b[4] == a[4] then inl[#inl + 1] = { dx / r, dz / r } end
        end
      end
    end
    for p = 1, #inl do for q = p + 1, #inl do
      local c = inl[p][1] * inl[q][1] + inl[p][2] * inl[q][2]
      local deg = math.deg(math.acos(math.max(-1, math.min(1, c))))
      all = all + 1
      if math.abs(deg - 60) < 12 or math.abs(deg - 120) < 12 or deg > 168 then good = good + 1 end
    end end
  end
  local ks = {}; for k in pairs(lv) do ks[#ks + 1] = k end; table.sort(ks)
  local ls = {}; for _, k in ipairs(ks) do ls[#ls + 1] = lv[k] end
  print(string.format("TRI t=%.0f n=%d crashed=%d onLevel=%d tri angles=%.0f%% coord=%.2f levels: %s",
    st.simTime, #pts, crashed, onLevel, 100 * good / math.max(all, 1), coord / #pts, table.concat(ls, " ")))
end)
