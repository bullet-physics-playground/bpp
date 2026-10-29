-- What a back foot does when it meets the side of a log (stallprobe under it), FP_FROM to FP_TO s: every frame, for
-- each back foot (behind the body's middle, the way it walks), its pitch (toe up +, against the world), the body's
-- pitch (nose up +), and its contacts on a slope (contact normal more than 20 degrees from vertical: the log's side).
-- An impact: a back foot touching a slope after 0.1 s or more without. For each: the slope's angle (+ rising the way
-- it walks), the foot's pitch then and 0.1 / 0.2 / 0.3 s later, its velocity's angle (up from the walking direction)
-- just before, and the body's speed along the walk over the next 0.3 s.
--   FP <t>|foot <i>|slope <deg>|pitch <deg> -> <+0.1> <+0.2> <+0.3>|vel angle <deg> speed <cm/s>|body pitch <deg>|body v after <cm/s>
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local cube, f = w.cube, (w.forward or 1)
local feet, mine = {}, {}
for _, o in ipairs(w.bodies) do mine[o] = true; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
mine[cube] = true
local function pitchOf(o)   -- toe up +: how far the body's own +x (times f) points up
  local Ti = o.body:getCenterOfMassTransform():inverse()
  local a, b = Ti:invXform(btVector3(0, 0, 0)), Ti:invXform(btVector3(1, 0, 0))
  local dy = b.y - a.y
  return f * math.deg(math.asin(math.max(-1, math.min(1, dy))))
end
local hist, off, pending = {}, {}, {}
local WF   -- the world's x the way it walks (+1 or -1): its forward along its body, seen in the world
do local Ti = cube.body:getCenterOfMassTransform():inverse(); local a, b = Ti:invXform(btVector3(0, 0, 0)), Ti:invXform(btVector3(f, 0, 0)); WF = (b.x - a.x) >= 0 and 1 or -1 end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < FP_FROM * 60 or N > FP_TO * 60 then return end
  local t = N / 60
  local T = cube.body:getCenterOfMassTransform()
  local slope = {}
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz)
    local o = (mine[a] and not mine[b]) and a or ((mine[b] and not mine[a]) and b or nil)
    if o then
      local s = 1; if not mine[a] then s = -1 end   -- (the normal points from b to a: make it point up out of the ground)
      local NX, NY = nx, ny; if NY < 0 then NX, NY = -NX, -NY end
      local ang = math.deg(math.acos(math.min(1, math.abs(NY))))
      if ang > 20 then slope[o] = -WF * (NX >= 0 and 1 or -1) * ang end   -- (rising the way it walks: the normal points back)
    end
  end)
  local bv = cube.body:getLinearVelocity().x * WF
  for i, o in ipairs(feet) do
    local lp = T:invXform(o.body:getCenterOfMassPosition())
    if lp.x * f < 0 then   -- a back foot
      if slope[o] and (off[i] or 0) >= 6 then
        local vl = o.body:getLinearVelocity()
        pending[#pending + 1] = { t = t, i = i, slope = slope[o], p0 = pitchOf(o), va = math.deg(math.atan2(vl.y, vl.x * WF)), vs = math.sqrt(vl.x^2 + vl.y^2),
                                  bp = pitchOf(cube), o = o, n0 = N, ps = {}, bvs = {} }
      end
      if slope[o] then off[i] = 0 else off[i] = (off[i] or 0) + 1 end
    else off[i] = 0 end
  end
  for k = #pending, 1, -1 do
    local e = pending[k]; local d = N - e.n0
    if d == 6 or d == 12 or d == 18 then e.ps[#e.ps + 1] = pitchOf(e.o) end
    if d > 0 then e.bvs[#e.bvs + 1] = bv end
    if d == 18 then
      local m = 0; for _, x in ipairs(e.bvs) do m = m + x end; m = m / #e.bvs
      print(string.format("FP %.2f|foot %d|slope %.1f|pitch %.1f -> %.1f %.1f %.1f|vel angle %.0f speed %.1f|body pitch %.1f|body v after %.2f",
        e.t, e.i, e.slope, e.p0, e.ps[1], e.ps[2], e.ps[3], e.va, e.vs, e.bp, m))
      table.remove(pending, k)
    end
  end
end)
