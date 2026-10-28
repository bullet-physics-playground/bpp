-- How far each joint of the walker gives, frame by frame (stallprobe under it). Every hinge, slider, 6-dof and
-- point joint is noted as it is built (its two bodies and its frames in them); each frame from JP_FROM to JP_TO s:
--   gap   the distance between the joint's two anchor points in the world (cm): a hinge's pivots, a slider's or a
--         6-dof's frame origins measured across the axes it leaves free (a slider: off its x axis; a free 6-dof: 0)
--   twist the angle between the two frames about the axes it holds (deg): a hinge's axes; a slider's whole frames
--         (it holds all turning); a 6-dof's whole frames if its turning is held
-- JP <t>|<n>|<type>|<made in>|gap <cm>|twist <deg>   for every joint whose gap > JP_MIN_GAP (default 0.05) or twist > JP_MIN_TWIST (1)
-- JPMAX <type>|<made in>|joints <n>|gap max <cm> at <t>|twist max <deg> at <t>|gap mean|twist mean   at the end
-- JP_OUT: the file.
local J = {}
local real = {}
local function vec(v) return { v.x, v.y, v.z } end
local function isVec(a) local ok, x = pcall(function() return a.x end); return ok and type(x) == "number" end
local function tr(t) local o, r = t:inverse():invXform(btVector3(0, 0, 0)), t:getRotation(); return { o = vec(o), q = { r:getX(), r:getY(), r:getZ(), r:getW() } } end
for _, n in ipairs({ "btHingeConstraint", "btSliderConstraint", "btGeneric6DofConstraint", "btPoint2PointConstraint" }) do
  real[n] = _G[n]
  _G[n] = function(A, B, ...)
    local con = real[n](A, B, ...)
    local args = { ... }
    local by = "?"
    for lv = 2, 5 do
      local info = debug.getinfo(lv, "n")
      local nm = info and info.name
      if nm and nm ~= "n" and not nm:find("^bt") and nm ~= "f" then by = nm; break end
    end
    local j = { n = n, A = A, B = B, by = by, con = con }
    if n == "btHingeConstraint" and isVec(args[1]) then j.pA, j.pB, j.aA, j.aB = vec(args[1]), vec(args[2]), vec(args[3]), vec(args[4])
    elseif n == "btPoint2PointConstraint" then j.pA, j.pB = vec(args[1]), vec(args[2])
    elseif n ~= "btHingeConstraint" then j.fA, j.fB = tr(args[1]), tr(args[2]) end
    J[#J + 1] = j
    return con
  end
end
-- (6-dof limits: remember which are free, to measure only what each holds)
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/stallprobe.lua")
v = realv
for n, f in pairs(real) do _G[n] = f end
-- the 6-dofs: free or held, from how they were built (the room and the files use lower > upper for free)
-- (bpp can't read limits back, so: guides and holds (free to move, held turning), the sliders' 6-dof (free along x),
-- welds (all held), and the free "no contact" joints are told apart by where they were made)
local FROM, TO = JP_FROM * 60, JP_TO * 60
local out = io.open(JP_OUT, "w")
local MG, MT = JP_MIN_GAP or 0.05, JP_MIN_TWIST or 1
local function W(b, p) local T = b:getCenterOfMassTransform(); return T:inverse():invXform(btVector3(p[1], p[2], p[3])) end
local function Wdir(b, d) local T = b:getCenterOfMassTransform(); local Ti = T:inverse()
  local a, c = Ti:invXform(btVector3(0, 0, 0)), Ti:invXform(btVector3(d[1], d[2], d[3])); return { c.x - a.x, c.y - a.y, c.z - a.z } end
local function qmul(a, b) return { a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2], a[4]*b[2] - a[1]*b[3] + a[2]*b[4] + a[3]*b[1],
                                   a[4]*b[3] + a[1]*b[2] - a[2]*b[1] + a[3]*b[4], a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3] } end
local function bq(b) local r = b:getCenterOfMassTransform():getRotation(); return { r:getX(), r:getY(), r:getZ(), r:getW() } end
local function rot(q, p)   -- rotate p by q
  local u = { q[1], q[2], q[3] }; local s = q[4]
  local d = u[1]*p[1] + u[2]*p[2] + u[3]*p[3]; local uu = u[1]*u[1] + u[2]*u[2] + u[3]*u[3]
  local c = { u[2]*p[3] - u[3]*p[2], u[3]*p[1] - u[1]*p[3], u[1]*p[2] - u[2]*p[1] }
  return { 2*d*u[1] + (s*s - uu)*p[1] + 2*s*c[1], 2*d*u[2] + (s*s - uu)*p[2] + 2*s*c[2], 2*d*u[3] + (s*s - uu)*p[3] + 2*s*c[3] }
end
local function kind(j)
  if j.n == "btGeneric6DofConstraint" then
    if j.by == "buildLinkage" then return "slider6dof" end
    if j.by:find("Crossbar") then return "weld" end
    if j.by == "addWalker" or j.by == "?" or j.by == "build" then return "guide/hold" end
    return "6dof:" .. j.by
  end
  return j.n:gsub("^bt", ""):gsub("Constraint$", "")
end
local S = {}
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < FROM or N > TO then return end
  local t = N / 60
  for i, j in ipairs(J) do
    if type(j.B) == "userdata" then
      local gap, tw = 0, 0
      local k = kind(j)
      if j.pA then
        local a, b = W(j.A, j.pA), W(j.B, j.pB); gap = math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2)
        if j.aA then
          local x, y = Wdir(j.A, j.aA), Wdir(j.B, j.aB)
          local la, lb = math.sqrt(x[1]^2+x[2]^2+x[3]^2), math.sqrt(y[1]^2+y[2]^2+y[3]^2)
          local c = (x[1]*y[1] + x[2]*y[2] + x[3]*y[3]) / (la * lb); if c > 1 then c = 1 elseif c < -1 then c = -1 end
          tw = math.deg(math.acos(c))
        end
      elseif j.fA then
        local qa, qb = qmul(bq(j.A), j.fA.q), qmul(bq(j.B), j.fB.q)
        local a, b = W(j.A, j.fA.o), W(j.B, j.fB.o)
        local d = { b.x - a.x, b.y - a.y, b.z - a.z }
        if k == "Slider" or k == "slider6dof" then
          local ax = rot(qa, { 1, 0, 0 }); local along = d[1]*ax[1] + d[2]*ax[2] + d[3]*ax[3]
          gap = math.sqrt(math.max(0, d[1]^2 + d[2]^2 + d[3]^2 - along^2))
        elseif k == "guide/hold" then gap = 0
        else gap = math.sqrt(d[1]^2 + d[2]^2 + d[3]^2) end
        local dd = math.abs(qa[1]*qb[1] + qa[2]*qb[2] + qa[3]*qb[3] + qa[4]*qb[4]); if dd > 1 then dd = 1 end
        tw = math.deg(2 * math.acos(dd))
      end
      local key = k .. "|" .. j.by
      local s = S[key] or { n = 0, gmax = 0, tmax = 0, gt = 0, tt = 0, gs = 0, ts = 0, c = 0, seen = {} }
      if not s.seen[i] then s.seen[i] = true; s.n = s.n + 1 end
      if gap > s.gmax then s.gmax, s.gt = gap, t end
      if tw > s.tmax then s.tmax, s.tt = tw, t end
      s.gs, s.ts, s.c = s.gs + gap, s.ts + tw, s.c + 1
      S[key] = s
      if gap > MG or tw > MT then out:write(string.format("JP %.4f|%d|%s|gap %.3f|twist %.2f\n", t, i, key, gap, tw)) end
    end
  end
  if N == TO then
    for key, s in pairs(S) do
      out:write(string.format("JPMAX %s|joints %d|gap max %.3f at %.3f|twist max %.2f at %.3f|gap mean %.4f|twist mean %.3f\n",
        key, s.n, s.gmax, s.gt, s.tmax, s.tt, s.gs / s.c, s.ts / s.c))
    end
    out:close()
  end
end)
