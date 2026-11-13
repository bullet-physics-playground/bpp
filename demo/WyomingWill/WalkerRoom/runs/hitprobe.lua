-- One walker's run, every frame (1/60 s) from HIT_T0 to HIT_T1 s drawn out for a side view (13 November; handover
-- section 4f, steps 7): each of its parts' outline in the world (x along the track, y up) and how far across it is,
-- the ground's height along the track at each foot's line, and every contact between the walker and the ground with
-- its normal force (a share of the walker's weight); the body's box, its tilt (nose up, the +z side up, degrees)
-- and its centre's height. Written to HIT_OUT; drawn by runs/drawhit.py. Otherwise
-- runs/speedprobe.lua's run, unchanged (RUN line and all).
local dims, scad = {}, {}
local rC, rS = Cube, OpenSCAD
Cube = function(a, b, c, m) local o = rC(a, b, c, m); dims[o] = { a, b, c }; return o end
OpenSCAD = function(sdl, ...) local o = rS(sdl, ...)
  local pts = sdl:match("points=%[(.-)%]%)"); local p = {}
  for x, y in (pts or ""):gmatch("%[([-%d.]+),([-%d.]+)%]") do p[#p + 1] = { tonumber(x), tonumber(y) } end
  if #p > 0 then scad[o] = p end
  return o end
local realv, speedPost = v, nil
v = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if k == "postSim" then return function(self, fn) speedPost = fn end end   -- (speedprobe's: run from ours)
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
dofile("runs/speedprobe.lua")
v = realv
Cube, OpenSCAD = rC, rS
local w = room.walkers[1]
local weight = w.totalMass * (GRAVITY or 981)
local G = room.groundAt
local parts, mine = {}, {}
for i, o in ipairs(w.bodies) do
  mine[o] = i
  local k = w.madeBy and w.madeBy[o] or "body"
  local poly
  if scad[o] then poly = scad[o]
  elseif dims[o] and dims[o][1] > 0.05 then local hx, hy = dims[o][1] / 2, dims[o][2] / 2; poly = { { -hx, -hy }, { hx, -hy }, { hx, hy }, { -hx, hy } } end
  if rawequal(o, w.cube) then k = "body"; poly = nil end
  parts[#parts + 1] = { o = o, poly = poly, kind = k, i = i }
end
local fh = io.open(HIT_OUT, "w")
fh:write(string.format("WALKER %s|weight %.1f|seed %d\n", w.spec.name, weight, SEED))
for i, o in ipairs(w.bodies) do fh:write(string.format("MASS %d %.4f\n", i, o.mass)) end
-- the joints that hold the walker's parts to its body: what each holds (its maker), where that part is (x, z, when
-- built), whether its motor drives it (a crank); each frame, the force each puts on the body (MOUNT, below)
local mounts = {}
local isMotor = {}
for _, m in ipairs(w.motors) do isMotor[m.hinge] = true end
local function objOf(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
for j, J in ipairs(w.joints or {}) do
  local A, B, con = J[1], J[2], J[4]
  local onA = A and A == w.cube.body
  local onB = B and B == w.cube.body
  if onA or onB then
    local other = objOf(onA and B or A)
    con:enableForces()
    mounts[#mounts + 1] = { con = con, onA = onA }
    local c = other and other.body:getCenterOfMassPosition()
    local motor = false
    for _, m in ipairs(w.motors) do if m.hinge == con then motor = true end end
    fh:write(string.format("MOUNTINFO %d %s %s %.2f %.2f %s\n", #mounts, J[5] or "?", other and (w.madeBy[other] or "?") or "none",
      c and c.x or 0, c and c.z or 0, motor and "crank" or "-"))
  end
end
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local T0, T1 = math.floor(HIT_T0 * 60), math.floor(HIT_T1 * 60)
v:postSim(function(N)
  speedPost(N)
  if N < T0 or N > T1 then return end
  fh:write(string.format("FRAME %.4f\n", N / 60))
  w.cube.body:getAabb(lo, hi)
  -- (its tilt: nose up -- the end toward +x higher -- and the +z side up, degrees, from its own axes in the world)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local ex = { 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy + qw * qz), 2 * (qx * qz - qw * qy) }
  local ez = { 2 * (qx * qz + qw * qy), 2 * (qy * qz - qw * qx), 1 - 2 * (qx * qx + qy * qy) }
  local up = math.deg(math.asin(math.max(-1, math.min(1, ex[2] * (ex[1] >= 0 and 1 or -1)))))
  local side = math.deg(math.asin(math.max(-1, math.min(1, ez[2] * (ez[3] >= 0 and 1 or -1)))))
  local c = w.cube.body:getCenterOfMassPosition()
  fh:write(string.format("BODY %.3f %.3f %.3f %.3f %.3f %.2f %.2f %.3f\n", lo.x, lo.y, hi.x, hi.y, (lo.z + hi.z) / 2, up, side, c.y))
  for _, P in ipairs(parts) do
    if P.poly then
      local T = P.o.body:getCenterOfMassTransform():inverse()
      local pts = {}
      for _, q in ipairs(P.poly) do local p = T:invXform(btVector3(q[1], q[2], 0)); pts[#pts + 1] = string.format("%.3f,%.3f", p.x, p.y) end
      local c = P.o.body:getCenterOfMassPosition()
      fh:write(string.format("PART %d %s %.2f %s\n", P.i, P.kind, c.z, table.concat(pts, ";")))
    end
  end
  for _, d in ipairs(w.tips or {}) do   -- (a foot's turned-up ends, part of its collision shape: spec.footTips)
    if d.len then
      local T = d.foot.body:getCenterOfMassTransform():inverse()
      local c, s = 1 - 2 * d.q[3] * d.q[3], 2 * d.q[3] * d.q[4]   -- (its turn about z)
      local pts = {}
      for _, q in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
        local lx, ly = q[1] * d.len / 2, q[2] * d.T / 2
        local p = T:invXform(btVector3(d.p[1] + c * lx - s * ly, d.p[2] + s * lx + c * ly, 0))
        pts[#pts + 1] = string.format("%.3f,%.3f", p.x, p.y)
      end
      fh:write(string.format("PART %d tip %.2f %s\n", mine[d.foot], d.foot.body:getCenterOfMassPosition().z, table.concat(pts, ";")))
    end
  end
  for _, P in ipairs(parts) do   -- (the ground along each foot's line, 30 cm either side)
    if P.kind == "buildFoot" then
      local c = P.o.body:getCenterOfMassPosition()
      local g = {}
      for dx = -30, 30, 0.5 do g[#g + 1] = string.format("%.2f", G(c.x + dx, c.z)) end
      fh:write(string.format("GROUND %d %.2f %.3f %s\n", P.i, c.z, c.x - 30, table.concat(g, ",")))
    end
  end
  for k, M in ipairs(mounts) do   -- (the force on the body, shares of the walker's weight)
    local F = M.onA and M.con:forceA() or M.con:forceB()
    fh:write(string.format("MOUNT %d %.4f %.4f %.4f\n", k, F.x / weight, F.y / weight, F.z / weight))
  end
  v:eachContact(function(a, b, px, py, pz, nx, ny, nz, dist, imp)
    if imp <= 0 or (mine[a] and mine[b]) or not (mine[a] or mine[b]) then return end
    local o, sgn = a, 1
    if mine[b] then o, sgn = b, -1 end
    local f = imp / FIXED / weight
    fh:write(string.format("CONTACT %d %.3f %.3f %.3f %.4f %.4f\n", mine[o], px, py, pz, sgn * nx * f, sgn * ny * f))
  end)
  if N == T1 then fh:close() end
end)
