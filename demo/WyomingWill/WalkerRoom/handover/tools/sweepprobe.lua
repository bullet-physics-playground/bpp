-- One walker held 200 cm up, cranked slowly through a full turn: every
-- link's outline (in the body's frame, x along the walk, y up) at each
-- sampled moment, which links are joined, and which plane each is in.
-- Writes SWEEP_OUT (env).
package.path = "/home/claude/bpp/demo/module/?.lua;" .. package.path
local dims, scad, cons = {}, {}, {}
local rC, rS = Cube, OpenSCAD
Cube = function(a, b, c, m) local o = rC(a, b, c, m); dims[o] = { a, b, c }; return o end
OpenSCAD = function(sdl, ...) local o = rS(sdl, ...)
  local pts = sdl:match("points=%[(.-)%]%)"); local p = {}
  for x, y in (pts or ""):gmatch("%[([-%d.]+),([-%d.]+)%]") do p[#p + 1] = { tonumber(x), tonumber(y) } end
  scad[o] = p; return o end
for _, n in ipairs({ "btHingeConstraint", "btSliderConstraint", "btGeneric6DofConstraint" }) do
  local f = _G[n]
  _G[n] = function(A, B, pA, pB, ...) local c = f(A, B, pA, pB, ...); cons[#cons + 1] = { A, B, n, pA, pB }; return c end
end
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("walker-room.lua")
v = realv
Cube, OpenSCAD = rC, rS
local w = room.walkers[1]
for _, o in ipairs(w.bodies) do
  local b = o.body
  local t = b:getCenterOfMassTransform(); local p = b:getCenterOfMassPosition()
  local nt = btTransform(t:getRotation(), btVector3(p.x, p.y + 200, p.z))
  b:setCenterOfMassTransform(nt); o.trans = nt
end
w.cube.body:setLinearFactor(btVector3(0, 0, 0)); w.cube.body:setAngularFactor(0)
setVelXYZ(w.cube, 0, 0, 0); setAngVelXYZ(w.cube, 0, 0, 0)
local links, idOf = {}, {}
for i, o in ipairs(w.bodies) do
  local k = w.madeBy[o] or "?"
  if o.mass > 0 and not rawequal(o, w.cube) then
    local poly
    if k == "buildFoot" then local hx, hy = dims[o][1] / 2, dims[o][2] / 2; poly = { { -hx, -hy }, { hx, -hy }, { hx, hy }, { -hx, hy } }
    elseif scad[o] then poly = scad[o]
    elseif dims[o] then local hx, hy = dims[o][1] / 2, dims[o][2] / 2; poly = { { -hx, -hy }, { hx, -hy }, { hx, hy }, { -hx, hy } } end
    if poly then links[#links + 1] = { o = o, poly = poly, i = i }; idOf[o] = #links end
  end
end
local function find(b) for _, L in ipairs(links) do if L.o.body == b then return L end end end
local isCube = function(b) return b == w.cube.body end
local fh = io.open(os.getenv("SWEEP_OUT"), "w")
local cp = w.cube.body:getCenterOfMassPosition()
local lo, hi = btVector3(0,0,0), btVector3(0,0,0)
w.cube.body:getAabb(lo, hi)
fh:write(string.format("WALKER %s|scale %.5f|bodyhalfz %.4f|bodybox %.3f %.3f %.3f %.3f\n", w.spec.name, w.scale, (hi.z - lo.z) / 2 - 0.04, lo.x - cp.x + 0.04, hi.x - cp.x - 0.04, lo.y - cp.y + 0.04, hi.y - cp.y - 0.04))
for k, L in ipairs(links) do
  local T = L.o.body:getCenterOfMassTransform():inverse()
  local c = T:invXform(btVector3(0, 0, 0))
  local pts = {}
  for _, q in ipairs(L.poly) do pts[#pts + 1] = string.format("%.4f,%.4f", q[1], q[2]) end
  fh:write(string.format("LINK %d|z %.4f|mass %.3f|poly %s|kind %s\n", k, c.z - cp.z, L.o.mass, table.concat(pts, ";"), w.madeBy[L.o] or "?"))
end
for _, c in ipairs(cons) do
  local a, b = find(c[1]), (type(c[2]) == "userdata") and find(c[2]) or nil
  local ac, bc = isCube(c[1]), (type(c[2]) == "userdata") and isCube(c[2])
  local function pv(p) return (c[3] == "btHingeConstraint" and type(p) == "userdata") and string.format("%.4f,%.4f", p.x, p.y) or "-" end
  if a and b then fh:write(string.format("JOIN %d %d %s %s\n", idOf[a.o], idOf[b.o], c[3], pv(c[4])))
  elseif a and bc then fh:write(string.format("GROUND %d %s %s\n", idOf[a.o], c[3], pv(c[4])))
  elseif b and ac then fh:write(string.format("GROUND %d %s %s\n", idOf[b.o], c[3], pv(c[5]))) end
end
local crank = CRANK
local T0, T1 = 4, 4 + 2 * math.pi / crank
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  local t = N / 60
  if t >= T0 and t <= T1 and N % 3 == 0 then
    local c0 = w.cube.body:getCenterOfMassPosition()
    for k, L in ipairs(links) do
      local T = L.o.body:getCenterOfMassTransform():inverse()
      local pts = {}
      for _, q in ipairs(L.poly) do local p = T:invXform(btVector3(q[1], q[2], 0)); pts[#pts + 1] = string.format("%.3f,%.3f", p.x - c0.x, p.y - c0.y) end
      fh:write(string.format("S %d %s\n", k, table.concat(pts, ";")))
    end
  end
  if N == math.floor(T1 * 60) + 2 then fh:write("END\n"); fh:close() end
end)
