-- One steering run, measured (handover/STEERING.md; for run-table.sh with PROBE=runs/steerprobe.lua): the
-- walker's heading (the way it walks, seen from above; a turn to the left counts up) and where it is. Lines:
--   SIDES <name>|feet <side+end ...>|motors <side+end+group ...>   (STEER's placing of feet and cranks, at the start)
--   PATH <name>|t <s>|x <cm>|z <cm>|heading <deg>                  (each second)
--   STEER <name>|turn <deg/s, from 5 s to the end>|speed <cm/s: straight from where it was at 5 s to the end>|heading <deg at the end>
--         |tilt max <deg, its body's up from the vertical, from 2 s>|tipped <1 if over 60 degrees>
-- Run from the WalkerRoom folder, after the room's settings (ONLY, TERRAIN, AMP, SEED, STEER, ...).
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
local END = (RUN_SECS or 20) * 60
local function out(s) io.stdout:write(s .. "\n"); io.stdout:flush() end
local function rot(q, x, y, z)
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local tx, ty, tz = 2 * (qy * z - qz * y), 2 * (qz * x - qx * z), 2 * (qx * y - qy * x)
  return x + qw * tx + (qy * tz - qz * ty), y + qw * ty + (qz * tx - qx * tz), z + qw * tz + (qx * ty - qy * tx)
end
if w.steer then
  local f, m = {}, {}
  for _, ft in ipairs(w.steer.feet) do f[#f + 1] = string.format("%s%s(mu %.2f)", ft.side, ft.front and "front" or "rear", ft.o.body:getFriction()) end
  for i, mo in ipairs(w.motors) do m[#m + 1] = i .. ":" .. (mo.side or "?") .. (mo.front and "front" or "rear") .. "/" .. (mo.group or 1) end
  out(string.format("SIDES %s|feet %s|motors %s", w.spec.name, table.concat(f, " "), table.concat(m, " ")))
end
local heading, lastH, h5, tilt, px, pz = 0, nil, nil, 0, nil, nil
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local b = w.cube.body
  local q, p = b:getCenterOfMassTransform():getRotation(), b:getCenterOfMassPosition()
  local fx, _, fz = rot(q, w.forward, 0, 0)
  local h = math.atan2(-fz, fx)
  if lastH then local d = h - lastH; heading = heading + d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5) else heading = h end
  lastH = h
  if N >= 120 then local _, uy = rot(q, 0, 1, 0); tilt = math.max(tilt, math.deg(math.acos(math.max(-1, math.min(1, uy))))) end
  if N == 300 then h5, px, pz = heading, p.x, p.z end
  if N % 60 == 0 then out(string.format("PATH %s|t %d|x %.1f|z %.1f|heading %.1f", w.spec.name, math.floor(N / 60), p.x, p.z, math.deg(heading))) end
  if N == END then
    local secs = END / 60 - 5
    out(string.format("STEER %s|turn %.3f|speed %.3f|heading %.1f|tilt max %.1f|tipped %d", w.spec.name,
      math.deg(heading - h5) / secs, math.sqrt((p.x - px) ^ 2 + (p.z - pz) ^ 2) / secs, math.deg(heading), tilt, tilt > 60 and 1 or 0))
  end
end)
