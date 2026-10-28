-- With steptest.lua (under it): each frame from SL_FROM to SL_TO s, the cranks' speeds (share of their target), the
-- body's x speed, its pitch, and every contact of the walker with the step box or the ground: part, F/B L/R, its
-- position relative to the step face (x ahead of the face, cm; y up), normal impulse.
--   SLP <t>|cranks a b c d|vx <cm/s>|pitch <deg>
--   SLC <t>|<box/ground>|<kind>|<FB><LR>|dx <cm>|y <cm>|imp
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/steptest.lua")
v = realv
local w = room.walkers[1]
local out = io.open(SL_OUT, "w")
local mine, kind = {}, {}
for _, o in ipairs(w.bodies) do mine[#mine + 1] = o; kind[o] = w.madeBy[o] or "?" end
mine[#mine + 1] = w.cube; kind[w.cube] = "body"
local function find(o) for _, q in ipairs(mine) do if rawequal(q, o) then return q end end end
local fwd = (w.spec and w.spec.forward) or 1
local last = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local rates = {}
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] then local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5); rates[i] = string.format("%.2f", d * 60 * m.sign / math.abs(m.speed)) end
    last[i] = a
  end
  if N < SL_FROM * 60 or N > SL_TO * 60 then return end
  local t = N / 60
  local T = w.cube.body:getCenterOfMassTransform(); local Ti = T:inverse(); local c0 = w.cube.body:getCenterOfMassPosition()
  local ax = Ti:invXform(btVector3(fwd, 0, 0))
  local tr = {}
  for i = 1, 4 do
    local lk = w.parts["linkage" .. i]
    if lk and lk.rocker and lk.coupler then
      local function xa(o) local T2 = o.body:getCenterOfMassTransform():inverse(); local a, b = T2:invXform(btVector3(0, 0, 0)), T2:invXform(btVector3(1, 0, 0)); return b.x - a.x, b.y - a.y end
      local ux, uy = xa(lk.coupler); local vx2, vy2 = xa(lk.rocker)
      local c = math.abs(ux * vx2 + uy * vy2) / math.sqrt((ux * ux + uy * uy) * (vx2 * vx2 + vy2 * vy2))
      tr[#tr + 1] = string.format("%.1f", math.deg(math.acos(math.min(1, c))))
    end
  end
  out:write(string.format("SLP %.4f|cranks %s|vx %.1f|pitch %.2f|trans %s\n", t, table.concat(rates, " "), w.cube.body:getLinearVelocity().x,
    math.deg(math.atan2(ax.y - c0.y, math.abs(ax.x - c0.x))), table.concat(tr, " ")))
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
    local pa, pb = find(a), find(b)
    if pa and pb then
      out:write(string.format("SLS %.4f|%s|%s|y %.2f|d %.3f|imp %.4f\n", t, kind[pa], kind[pb], y, d, imp or 0)); return
    end
    if not (pa or pb) then return end
    local p = pa or pb
    local other = pa and b or a
    local isBox = not (other.friction == 0.8 and other.mass == 0 and other.pos and false)   -- (decided below)
    local lp = T:invXform(btVector3(x, y, z))
    local where = (x > STEP_FACE_X - 0.5 and y > 0.3) and "box" or "ground"
    out:write(string.format("SLC %.4f|%s|%s|%s%s|dx %.2f|y %.2f|imp %.4f\n", t, where, kind[p], (lp.x * fwd > 0) and "F" or "B", (lp.z > 0) and "L" or "R", x - STEP_FACE_X, y, imp or 0))
  end)
  if N == SL_TO * 60 then out:close() end
end)
