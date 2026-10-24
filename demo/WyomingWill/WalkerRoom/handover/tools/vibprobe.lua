-- Test track, plus how much the feet vibrate (sampled once a frame, 60 a second, from
-- frame 120 on; each foot, then the mean over the four):
--   spin    the foot's turning speed relative to the body (deg/s): mean, and the share of
--           frames over 200 deg/s
--   jitter  how much the foot's velocity changes from one frame to the next (cm/s)
--   bounce  the foot's vertical speed while it stays down (cm/s)
--   chatter how often its ground contact switches on or off (per second)
--   pend    the leg's pendant (the link the foot hangs from) turning relative to the body (deg/s)
-- VIB <name>|spin ..|>200 ..%|jitter ..|bounce ..|chatter ..|pend ..
-- and VIBSEC <s>|x|spin|jitter|bounce, once a second (the means over that second).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(VIB_BASE or "test-track.lua")   -- (VIB_BASE: e.g. stallprobe.lua, for its test switches)
v = realv
local w = room.walkers[1]
local feet, pend = {}, {}
for _, o in ipairs(w.bodies) do if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
-- (each foot's pendant: the body its ankle hinge joins it to)
for _, f in ipairs(feet) do
  for _, j in ipairs(w.joints or {}) do
    if j[5] == "btHingeConstraint" and j[2] and (j[1] == f.body or j[2] == f.body) then
      local other = (j[1] == f.body) and j[2] or j[1]
      for _, o in ipairs(w.bodies) do if o.body == other then pend[f] = o end end
    end
  end
end
local function relSpin(o)
  local a, b = o.body:getAngularVelocity(), w.cube.body:getAngularVelocity()
  return math.deg(math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2))
end
-- every contact, by the kinds of the two parts (CONTACTS line at the end: share of frames each pair touched)
local label, isPend = {}, {}
for _, f in ipairs(feet) do if pend[f] then isPend[pend[f]] = true end end
local deco = {}
for _, d in ipairs(w.decor or {}) do deco[#deco + 1] = d.o end
local function labelOf(o)
  if label[o] then return label[o] end
  local L
  if rawequal(o, w.cube) then L = "body" end
  if not L then for _, q in ipairs(deco) do if rawequal(q, o) then L = "deco" end end end
  if not L then
    for _, q in ipairs(w.bodies) do
      if rawequal(q, o) then
        local k = w.madeBy[q] or "?"
        if k == "buildFoot" then L = "foot" elseif isPend[q] then L = "pendant"
        elseif k == "makeLink" then L = "link" elseif k == "buildArchedCrossbar" then L = "arched"
        elseif k == "buildDiagonalCrossbar" then L = "straight" elseif k == "buildLowCrossbar" then L = "low" else L = k end
        if math.floor(q.body:getCollisionFlags() / 4) % 2 == 1 then L = L .. "(ghost)" end
      end
    end
  end
  if not L then
    local ok, im = pcall(function() return o.body:getInvMass() end)
    L = (ok and im == 0) and "ground" or "other"
  end
  label[o] = L
  return L
end
local pairT, cframes = {}, 0
local last, down = {}, {}
local T = { n = 0, spin = 0, over = 0, jit = 0, jn = 0, bounce = 0, bn = 0, flips = 0, pend = 0, pn = 0 }
local S = { n = 0, spin = 0, jit = 0, jn = 0, bounce = 0, bn = 0 }
local x0
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  if N == 120 then x0 = select(1, getPosXYZ(w.cube)) end
  local now = {}
  local seen = {}
  cframes = cframes + 1
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d)
    if d > 0.01 then return end
    do
      local la, lb = labelOf(a), labelOf(b)
      if la ~= "deco" and lb ~= "deco" and not (la == "ground" and lb == "ground") and not ((la == "foot" and lb == "ground") or (la == "ground" and lb == "foot")) then
        local key = la < lb and (la .. "-" .. lb) or (lb .. "-" .. la)
        seen[key] = true
      end
    end
    for _, f in ipairs(feet) do
      if rawequal(a, f) or rawequal(b, f) then
        local other = rawequal(a, f) and b or a
        local mine = false
        for _, o in ipairs(w.bodies) do if rawequal(o, other) then mine = true end end
        if not mine and not rawequal(other, w.cube) then now[f] = true end
      end
    end
  end)
  for k in pairs(seen) do pairT[k] = (pairT[k] or 0) + 1 end
  for _, f in ipairs(feet) do
    local s = relSpin(f)
    local vel = f.body:getLinearVelocity()
    T.n = T.n + 1; T.spin = T.spin + s; if s > 200 then T.over = T.over + 1 end
    S.n = S.n + 1; S.spin = S.spin + s
    if last[f] then
      local j = math.sqrt((vel.x - last[f][1])^2 + (vel.y - last[f][2])^2 + (vel.z - last[f][3])^2)
      T.jit = T.jit + j; T.jn = T.jn + 1; S.jit = S.jit + j; S.jn = S.jn + 1
      if now[f] and down[f] then T.bounce = T.bounce + math.abs(vel.y); T.bn = T.bn + 1; S.bounce = S.bounce + math.abs(vel.y); S.bn = S.bn + 1 end
      if (now[f] or false) ~= (down[f] or false) then T.flips = T.flips + 1 end
    end
    last[f] = { vel.x, vel.y, vel.z }; down[f] = now[f]
    if pend[f] then T.pend = T.pend + relSpin(pend[f]); T.pn = T.pn + 1 end
  end
  if N % 60 == 0 then
    local x = select(1, getPosXYZ(w.cube))
    print(string.format("VIBSEC %d|x %.1f|spin %.0f|jitter %.1f|bounce %.2f", N / 60, x - x0, S.spin / math.max(1, S.n), S.jit / math.max(1, S.jn), S.bounce / math.max(1, S.bn)))
    S = { n = 0, spin = 0, jit = 0, jn = 0, bounce = 0, bn = 0 }
  end
  if N == 3699 then
    local r = {}
    for k, n in pairs(pairT) do r[#r + 1] = { k, 100 * n / cframes } end
    table.sort(r, function(x, y) return x[2] > y[2] end)
    local t = {}
    for _, e in ipairs(r) do t[#t + 1] = string.format("%s %.1f%%", e[1], e[2]) end
    print("CONTACTS " .. w.spec.name .. "|" .. (#t > 0 and table.concat(t, ", ") or "none"))
    local secs = (N - 120) / 60
    print(string.format("VIB %s|feet %d|spin %.0f deg/s|>200 %.1f%%|jitter %.2f cm/s|bounce %.2f cm/s|chatter %.2f /s|pend %.1f deg/s",
      w.spec.name, #feet, T.spin / T.n, 100 * T.over / T.n, T.jit / T.jn, T.bounce / math.max(1, T.bn), T.flips / #feet / secs, T.pend / math.max(1, T.pn)))
  end
end)
