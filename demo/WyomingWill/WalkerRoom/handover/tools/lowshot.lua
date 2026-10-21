local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn; realv[h](realv, fn) end) end
v = P
dofile("test-track.lua")
v = realv
realv:preDraw(function(N)
  if hooks.preDraw then hooks.preDraw(N) end
  if N >= SHOT_AT - 3 then
    local x, y, z = getPosXYZ(room.walkers[1].cube)
    v.cam.pos = btVector3(x + CAM[1], CAM[2], z + CAM[3])
    v.cam.look = btVector3(x, CAM[4], z)
    v.cam:setUpVector(btVector3(0, 1, 0), true)
  end
  if N == SHOT_AT then os.execute("xwd -root -silent | convert xwd:- " .. os.getenv("SHOT_OUT")); os.exit(0) end
end)
