-- Each ankle hinge's angle (foot against its leg) over a run, from its angle when built.
local ankles = {}
local realH = btHingeConstraint
btHingeConstraint = function(...)
  local con = realH(...)
  local f = debug.getinfo(3, "n"); if f and f.name == "buildFoot" then ankles[#ankles + 1] = con end
  return con
end
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
btHingeConstraint = realH
local a0, last, tot, lo, hi, atlo, athi = {}, {}, {}, {}, {}, {}, {}
for i, h in ipairs(ankles) do a0[i] = h:getHingeAngle(); last[i] = a0[i]; tot[i] = 0; lo[i] = 0; hi[i] = 0 end
do local t = {} for i = 1, #ankles do t[i] = string.format("%.1f", math.deg(a0[i])) end print("ANKLE built " .. room.walkers[1].spec.name .. ": " .. table.concat(t, " ")) end
local END = (RUN_SECS or 20) * 60
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  for i, h in ipairs(ankles) do
    local a = h:getHingeAngle(); local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
    tot[i] = tot[i] + d; last[i] = a
    local g = math.deg(tot[i])
    if g < lo[i] then lo[i] = g; atlo[i] = N end
    if g > hi[i] then hi[i] = g; athi[i] = N end
  end
  if N == END then
    local s = {}
    for i = 1, #ankles do s[#s + 1] = string.format("a%d built %.0f, %.0f@%.1fs..+%.0f@%.1fs", i, math.deg(a0[i]), lo[i], (atlo[i] or 0) / 60, hi[i], (athi[i] or 0) / 60) end
    print("ANKLE " .. #ankles .. "|" .. table.concat(s, "|"))
  end
end)
