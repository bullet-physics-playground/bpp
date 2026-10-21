-- test track, plus a PATH line each second: time, x, z (cm from start), heading (deg), and TILT at the end
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
local q0 = w.cube.body:getCenterOfMassTransform():getRotation()
local function angles()
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  -- the body's own x (along the walk) and z (across) axes in the world
  local function rot(x, y, z)
    local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
    local ix, iy, iz, iw = qw*x + qy*z - qz*y, qw*y + qz*x - qx*z, qw*z + qx*y - qy*x, -qx*x - qy*y - qz*z
    return ix*qw + iw*-qx + iy*-qz - iz*-qy, iy*qw + iw*-qy + iz*-qx - ix*-qz, iz*qw + iw*-qz + ix*-qy - iy*-qx
  end
  local fx, fy, fz = rot(1, 0, 0); local sx, sy, sz = rot(0, 0, 1)
  return math.deg(math.asin(math.max(-1, math.min(1, fy)))), math.deg(math.asin(math.max(-1, math.min(1, sy)))), math.deg(math.atan2(-fz, fx))
end
local p0, r0, h0 = angles()
local X0p, _, Z0p = getPosXYZ(w.cube)
local pmax, rmax = 0, 0
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  local p, r, h = angles()
  pmax, rmax = math.max(pmax, math.abs(p - p0)), math.max(rmax, math.abs(r - r0))
  if N % 60 == 0 then local x, _, z = getPosXYZ(w.cube); print(string.format("PATH %d|%.1f|%.1f|%.1f", N / 60, x - X0p, z - Z0p, h - h0)) end
  if N == 3699 then print(string.format("TILT %s|pitch max %.1f|roll max %.1f|heading %.1f deg", w.spec.name, pmax, rmax, h - h0)) end
end)
