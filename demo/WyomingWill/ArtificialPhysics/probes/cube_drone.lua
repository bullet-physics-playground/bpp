dofile((os.getenv('PROBES') or '.') .. '/cubic.lua')
local Swarm = require "quadcopter.swarm"
setDimension(true)
toggleFormation()
if os.getenv("FIELD") == "0" then v:addParam("obstacleField", false, "") end
for _, k in ipairs({ "launchOrder", "launchGap", "goalDelay", "layerGain", "downwash", "apHz", "range", "friction", "forceMax", "G", "timeStep" }) do
  local e = os.getenv(k:upper()); if e then v:addParam(k, tonumber(e), 0, 20000, 0.01, "") end
end
require("lib.rng").seed(tonumber(os.getenv("SEED") or "1"))
setup(50)
local SEPR = (pcall(v.getParam, v, "rad") and v:getParam("rad")) or v:getParam("desiredSeparation")
local ok, rr = pcall(function() return v:getParam("rad") end)
SEPR = (ok and rr) or v:getParam("desiredSeparation")
local nextLog = 30
v:preDraw(function()
  local st = Swarm.state()
  if st.simTime < nextLog then return end
  nextLog = nextLog + 30
  local pts = {}
  for _, d in ipairs(st.drones) do if d.state == "ap" then pts[#pts + 1] = { d.px, d.py, d.pz, d.id % 2 } end end
  local crashed = 0; for _, d in ipairs(st.drones) do if d.state == "crashed" then crashed = crashed + 1 end end
  print(string.format("CUBE t=%.0f n=%d crashed=" .. crashed .. " %s", st.simTime, #pts, cubicStats(pts, SEPR * v:getParam("metersPerUnit"))))
  if #pts < 2 then return end
  local R = SEPR * v:getParam("metersPerUnit")
  local nn, lv = {}, {}
  for i, a in ipairs(pts) do
    local best = 1e9
    for j, b in ipairs(pts) do if i ~= j then best = math.min(best, math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)) end end
    nn[#nn+1] = best / R
    local k = math.floor(a[2] / R + 0.5); lv[k] = (lv[k] or 0) + 1
  end
  table.sort(nn)
  local ks = {}; for k in pairs(lv) do ks[#ks+1] = k end; table.sort(ks)
  local ls = {}; for _, k in ipairs(ks) do ls[#ls+1] = lv[k] end
  if os.getenv("DUMP") and st.simTime >= 150 then
    local f = io.open(os.getenv("DUMP") .. ".txt", "w")
    for _, a in ipairs(pts) do f:write(string.format("%f %f %f %d\n", a[1], a[2], a[3], a[4])) end
    f:close()
  end
  print(string.format("SHAPE t=%.0f nearest/R p10=%.2f p50=%.2f p90=%.2f | drones per level (bottom up): %s", st.simTime, nn[math.ceil(#nn*.1)], nn[math.ceil(#nn*.5)], nn[math.ceil(#nn*.9)], table.concat(ls, " ")))
end)
