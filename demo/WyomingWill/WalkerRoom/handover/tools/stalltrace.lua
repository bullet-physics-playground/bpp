-- Where and how a walker stalls: every half second its body's x (cm along the track), its cranks' turning (share of
-- driven speed), and, in each half second, which of its parts touched the ground (share of frames) and which
-- touched each other. TRACE line per half second; STALL line: when it stopped gaining (under 0.5 cm a second).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
local w = room.walkers[1]
local kind = {}
local feetIdx, legIdx = {}, 0
for _, o in ipairs(w.bodies) do
  local k = w.madeBy[o] or "?"
  if rawequal(o, w.cube) then kind[o] = "body"
  elseif k == "buildFoot" then feetIdx[#feetIdx + 1] = o; kind[o] = "foot" .. #feetIdx
  elseif k == "makeLink" then kind[o] = "link"
  else kind[o] = k end
end
local function nameOf(o) if o == nil then return "?" end for q, k in pairs(kind) do if rawequal(q, o) then return k end end
  local ok, fl = pcall(function() return o.body:getCollisionFlags() end)
  if ok and math.floor(fl / 4) % 2 == 1 then return nil end   -- (look-only: the marks, the drawn frame, the toes)
  local ok2, im = pcall(function() return o.body:getInvMass() end); return (ok2 and im == 0) and "ground" or "other" end
local tally, frames, last = {}, 0, {}
local END = (RUN_SECS or 20) * 60
local x0 = w.cube.body:getCenterOfMassPosition().x
local hist = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  frames = frames + 1
  local seen = {}
  realv:eachContact(function(a, b, px, py, pz, nx, ny, nz, d, imp)
    if d > 0.05 then return end
    local A, B = nameOf(a), nameOf(b)
    if A == nil or B == nil then return end
    if A == "ground" or B == "ground" then
      local p = (A == "ground") and B or A
      if p ~= "ground" then seen["ground-" .. p] = true end
    elseif A ~= B then
      local k = (A < B) and (A .. "-" .. B) or (B .. "-" .. A); seen[k] = true
    end
  end)
  for k in pairs(seen) do tally[k] = (tally[k] or 0) + 1 end
  if N % 30 == 0 then
    local xb = w.cube.body:getCenterOfMassPosition().x - x0
    local cr = {}
    for i, m in ipairs(w.motors) do
      local a = m.hinge:getHingeAngle()
      if last[i] then local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5); cr[#cr + 1] = string.format("%.2f", d * 2 * m.sign / math.abs(m.speed)) end
      last[i] = a
    end
    local t = {}
    for k, n in pairs(tally) do if k:find("ground") or not k:find("foot") then t[#t + 1] = string.format("%s %.0f%%", k, 100 * n / frames) end end
    table.sort(t)
    local fx = {}
    for i, f in ipairs(feetIdx) do local p = f.body:getCenterOfMassPosition(); fx[#fx + 1] = string.format("f%d(%.1f,%.1f)", i, p.x - x0, p.y) end
    local bp = w.cube.body:getCenterOfMassPosition()
    print(string.format("TRACE %.1fs x %.1f body y %.1f cranks %s | %s | %s", N / 60, xb, bp.y, table.concat(cr, " "), table.concat(fx, " "), table.concat(t, ", ")))
    hist[#hist + 1] = { N / 60, xb }
    tally, frames = {}, 0
  end
  if N == END then
    local stall
    for i = 3, #hist do if hist[i][2] - hist[i - 2][2] < 0.5 and not stall then stall = hist[i - 2][1] end end
    print("STALL " .. (stall and string.format("from %.1fs at x %.1f", stall, hist[math.floor(stall * 2)][2]) or "none"))
  end
end)
