--
-- Linkages That Write -- Babbage's Hall
--
-- Type a letter: linkages draw it. Each pen is its own one-crank linkage of
-- hinged bars, found in advance by William Spears's synthesizer (a
-- four-bar and up to four more dyads, by differential evolution); one
-- crank turns once, the other cranks geared to it, and every pen draws its
-- stroke. A letter with junctions (E, H, K) is split among pens at them;
-- a better letter takes more bars, and more pens.
--
-- THE SLIDER (1, 2, 3; or the "accuracy" slider)
--   1 sloppy     every pen within 8% of the letter's height
--   2 ok         within 4%
--   3 very good  within 2%
-- For each, the cheapest split and linkages (fewest bars, then fewest pens)
-- that do it: synthesis/final2.py, alphabet.lua.
--
-- KEYS
--   A - Z   a letter: its linkages go on the board and draw it
--   1 2 3   sloppy, ok, very good (and draw the letter again)
--   Space   draw it again            0  the tour            F1  the manual
--
-- PHYSICS: every link is a body (a link with three pins, the coupler or a
-- dyad's first link, a rigid plate), every pin a hinge (Bullet's
-- btHingeConstraint), each pin's two points at one height (the bars are
-- drawn at different heights). A motor turns the first pen's crank; the
-- other cranks are held in step with it, 1:1, the same way round or the
-- other as each linkage was found, as a timing belt would hold them (each
-- crank's hinge drives it to the first crank's angle; Bullet's gear
-- constraint ties only speeds, and slipped: FINDINGS.md).
-- The board lies flat, so the bars' weight is across their motion. Stiff
-- hinges, the solver at 80 iterations, 600 steps a second. The linkages
-- pass through one another (no collisions): a built one puts them on
-- separate layers. The slate, the letter's grey guide and the pens' dots
-- are the script's; every dot is where a pen is.
--
-- Units: centimetres, kilograms, seconds; the letter 8 cm tall.
-- Headless: LW_SET="B 3" (a letter and a position), LW_TOUR=0, LW_ALL=1
-- (every letter at every position: the tour), LW_HZ, LW_ITER, LW_PERIOD
-- (seconds a turn).
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/LinkagesWrite/" }) do
  local f = io.open(d .. "alphabet.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Linkages That Write: can't find its folder")
local function file(p) if hallPath then return hallPath(DIR .. p) end return DIR .. p end
local ALPHA = dofile(file("alphabet.lua"))
local function pic(name) return file("slate/" .. name .. ".png") end

local LEVELS = { "sloppy", "ok", "very good" }
local LEVELTILE = { "level-sloppy", "level-ok", "level-good" }
local CMH = 8.0                          -- the letter's height, cm
local BOARD_T = 1.0
local BOARD_Y = BOARD_T + 0.006

-- ---------------------------------------------------------------------
-- timing: steps a frame, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("accuracy", 3, 1, 3, 1, "1 sloppy, 2 ok, 3 very good")
v:addParam("turn", envnum("LW_PERIOD", 6), 6, 20, 1, "seconds the crank takes to turn once (no faster: the fastest linkages would lag)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = envnum("LW_HZ", 600)
local STEP, NSTEPS, FRAME_DT = 1 / HZ, 10, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(HZ * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()
v.gravity = btVector3(0, -981, 0)
pcall(function() v:setSolverIterations(envnum("LW_ITER", 80)) end)

local ident = btQuaternion(0, 0, 0, 1)
local AXIS = btVector3(0, 1, 0)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end

local TABLE
do
  local path, f = file("../../exhibit-table.lua")
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(40, 48, { x = 0, z = -4, floor = 300 })

-- the board, the slate on its easel
local function box(w, h, d, x, y, z, col, q)
  local c = Cube(w, h, d, 0); c.collides = false; c.col = col; v:add(c)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return c
end
local O = {}
O.board = box(40, BOARD_T, 34, 0, BOARD_T / 2, 0, "#c9a46a")
local SX, SY, SZ = 0, 12.5, -22
O.slate = box(26, 15, 0.6, SX, SY, SZ, "#22282a")
for _, f in ipairs({ { 27.4, 1.2, 0, 7.6 }, { 27.4, 1.2, 0, -7.6 }, { 1.2, 16.4, 13.4, 0 }, { 1.2, 16.4, -13.4, 0 } }) do
  box(f[1], f[2], 0.9, SX + f[3], SY + f[4], SZ, "#6b4423")
end
for _, x in ipairs({ -10, 10 }) do box(1.2, SY - 7, 1.2, x, (SY - 7) / 2, SZ - 0.4, "#6b4423") end
pcall(function() v.showConstraints = false end)
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))

local QFACE = ident
local function tile(w, h, x, y, z, picture)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = pic(picture)
  v:add(c)
  c.trans = btTransform(QFACE, btVector3(x, y, z))
  return c
end
local SLZ = SZ + 0.32
local slate = { rows = {} }
slate.say = tile(24.6, 2.4, SX, SY + 5.3, SLZ, "say-ready")
slate.level = tile(11.0, 0.9, SX, SY + 3.4, SLZ, LEVELTILE[3])
local ROWY = { SY + 1.6, SY - 0.6, SY - 2.8, SY - 5.0 }
local LABELS = { "label-letter", "label-pens", "label-bars", "label-worst" }
for r = 1, 4 do
  slate.rows[r] = { label = tile(13.0, 0.85, SX - 5.0, ROWY[r], SLZ, LABELS[r]), d = {} }
  for k = 1, 5 do slate.rows[r].d[k] = tile(1.1, 1.6, SX + 4.0 + (k - 1) * 1.2, ROWY[r], SLZ, "ch-blank") end
end
local shown = {}
local function show(t, picture) if shown[t] ~= picture then shown[t] = picture; t.tex = pic(picture) end end
local CH = { ["."] = "dot", ["%"] = "pct", [" "] = "blank" }
local function showText(r, s, green)
  s = s or ""
  local row = slate.rows[r]
  local pad = 5 - #s
  for k = 1, 5 do
    local c = k > pad and s:sub(k - pad, k - pad) or " "
    local n = CH[c] or c
    show(row.d[k], "ch-" .. n .. ((green and n ~= "blank") and "-green" or ""))
  end
end
local function sayIt(s) show(slate.say, "say-" .. s) end

-- ---------------------------------------------------------------------
-- a letter's linkages: build, take down
-- ---------------------------------------------------------------------
local RHO = 0.00124 * 0.8 * 0.3                 -- PLA bar, 8 x 3 mm: kg a cm
local PEN_COL = { "#c0392b", "#2471a3", "#1e8449", "#8e44ad", "#d35400", "#16a085", "#7f8c8d" }
local BAR_COL = { "#8e5a2b", "#a0692f", "#6f4a26", "#b07a3c", "#7d5530", "#94622e", "#6a4524" }
local L = nil                                   -- the letter on the board
local function world(body, p)
  local q, c = body:getCenterOfMassTransform():getRotation(), body:getCenterOfMassPosition()
  local th = q:getAngle()
  if th < 1e-9 then return c.x + p.x, c.z + p.z end
  local k = q:getAxis()
  local ct, st = math.cos(th), math.sin(th)
  local kx, kz = k.y * p.z - k.z * p.y, k.x * p.y - k.y * p.x
  local kd = k.x * p.x + k.y * p.y + k.z * p.z
  return c.x + p.x * ct + kx * st + k.x * kd * (1 - ct), c.z + p.z * ct + kz * st + k.z * kd * (1 - ct)
end
local function yaw(body)
  local q = body:getCenterOfMassTransform():getRotation()
  local th = q:getAngle()
  if th < 1e-9 then return 0 end
  return q:getAxis().y >= 0 and th or -th
end
local function takeDown()
  if not L then return end
  for _, c in ipairs(L.cons) do v:removeConstraint(c) end
  for _, o in ipairs(L.objs) do v:remove(o) end
  L = nil
end
local function build(letter, level)
  takeDown()
  local entry = ALPHA[letter] and ALPHA[letter][level]
  if not entry then return false end
  local bx = (entry.box[1] + entry.box[2]) / 2
  local by = (entry.box[3] + entry.box[4]) / 2
  local function W(p) return CMH * (p[1] - bx), -CMH * (p[2] - by) end   -- (letter y up = the board's -z)
  L = { letter = letter, level = LEVELS[level], entry = entry, objs = {}, cons = {}, pens = {}, edges = {}, caps = {},
        dots = {}, turned = 0, lastYaw = nil }
  local function add(o) v:add(o); L.objs[#L.objs + 1] = o; return o end
  -- (the letter, faint, as a guide)
  for _, pen in ipairs(entry.pens) do
    local s = pen.stroke
    for i = 1, #s - 1 do
      local x1, z1 = W(s[i]); local x2, z2 = W(s[i + 1])
      local dx, dz = x2 - x1, z2 - z1
      local len = math.sqrt(dx * dx + dz * dz)
      if len > 1e-4 then
        local c = Cube(len + 0.5, 0.01, 0.5, 0); c.collides = false; c.col = "#efe4c8"
        add(c); c.trans = btTransform(btQuaternion(AXIS, math.atan2(-dz, dx)), btVector3((x1 + x2) / 2, BOARD_Y, (z1 + z2) / 2))
      end
    end
  end
  for j, P in ipairs(entry.pens) do
    local B = { ground = { body = anchor.body, c = { 0, 0 }, ground = true } }
    for bi, bd in ipairs(P.bodies) do
      local pts = {}
      for i, p in ipairs(bd.pts) do local x, z = W(p); pts[i] = { x, z } end
      local cx, cz, n, len = 0, 0, #pts, 0
      for _, p in ipairs(pts) do cx = cx + p[1]; cz = cz + p[2] end
      cx, cz = cx / n, cz / n
      local ext = 0.3
      for i, p in ipairs(pts) do
        ext = math.max(ext, math.abs(p[1] - cx), math.abs(p[2] - cz))
        local q = pts[i % n + 1]; len = len + math.sqrt((p[1] - q[1]) ^ 2 + (p[2] - q[2]) ^ 2)
      end
      if n == 2 then len = len / 2 end
      local m = RHO * math.max(len, 0.5)
      local I = m * (2 * ext) ^ 2 / 12
      local y = BOARD_T + 0.6 + 0.4 * (bi - 1) + 0.03 * (j - 1)
      local tr = btTransform(ident, btVector3(cx, y, cz))
      local b = btRigidBody(m, btDefaultMotionState(tr), btBoxShape(btVector3(ext, 0.15, ext)), btVector3(I, I, I))
      local o = Cube(0.05, 0.05, 0.05, 0)
      o.body = b; o.collides = false; o.col = "#6b4423"; add(o); o.trans = tr
      b:setActivationState(4)
      B[bd.name] = { body = b, c = { cx, cz }, y = y, obj = o, name = bd.name }
      -- (its bars, drawn: a thin bar along every side, between its pins)
      for i = 1, (n == 2 and 1 or n) do
        local p, q = pts[i], pts[i % n + 1]
        local dx, dz = q[1] - p[1], q[2] - p[2]
        local ln = math.sqrt(dx * dx + dz * dz)
        if ln > 1e-3 then
          local e = Cube(ln + 0.45, 0.25, 0.45, 0); e.collides = false
          e.col = BAR_COL[(bi - 1) % #BAR_COL + 1]
          add(e)
          L.edges[#L.edges + 1] = { obj = e, body = b, m = btVector3((p[1] + q[1]) / 2 - cx, 0, (p[2] + q[2]) / 2 - cz),
                                    a = math.atan2(-dz, dx), y = y, pen = j, part = bd.name }
        end
      end
    end
    local function loc(bd, p) local x, z = W(p); if bd.ground then return btVector3(x, BOARD_T + 0.6, z) end return btVector3(x - bd.c[1], 0, z - bd.c[2]) end
    local crankH
    for _, h in ipairs(P.hinges) do
      local a, b = B[h.a], B[h.b]
      local pa, pb = loc(a, h.p), loc(b, h.p)
      -- (a hinge pins its two points together in all three directions: A's
      -- point is given at B's height, so the pin runs from one bar's height
      -- to the other's and doesn't pull them together: the linkages' FINDINGS)
      if a.ground then pa = btVector3(pa.x, b.y, pa.z)
      elseif b.ground then pb = btVector3(pb.x, a.y, pb.z)
      else pa = btVector3(pa.x, b.y - a.y, pa.z) end
      local c = btHingeConstraint(a.body, b.body, pa, pb, AXIS, AXIS)
      v:addConstraint(c); L.cons[#L.cons + 1] = c
      if h.a == "ground" then
        local x, z = W(h.p)
        local post = Cube(0.5, 0.6 + 0.4 * 4, 0.5, 0); post.collides = false; post.col = "#2b2b2b"
        add(post); post.trans = btTransform(ident, btVector3(x, BOARD_T + 0.3 + 0.8, z))
        if h.b == "crank" then crankH = c end
      end
    end
    local pb = B[P.pen.body]
    local cap = Cube(0.5, 0.5, 0.5, 0); cap.collides = false; cap.col = PEN_COL[(j - 1) % #PEN_COL + 1]; add(cap)
    L.pens[j] = { B = B, crankH = crankH, pen = pb, penL = loc(pb, P.pen.p), k = P.k, h = P.h, cap = cap,
                  path = {}, last = nil, stroke = P.stroke, D = P.D }
  end
  -- (the other cranks are held in step with the first, the same way round
  -- or the other as each linkage was found, as a timing belt would hold
  -- them: each crank's hinge drives it to the first crank's angle. Bullet's
  -- gear constraint ties only their speeds, and a crank that pulled hard let
  -- it slip, 114 degrees in one turn: FINDINGS.md)
  for j, P in ipairs(L.pens) do
    P.s = L.pens[1].k * P.k
    P.yaw0, P.lastYaw, P.turned = yaw(P.B.crank.body), yaw(P.B.crank.body), 0
  end
  L.W = -2 * math.pi / v:getParam("turn") * (L.pens[1].k >= 0 and 1 or -1)
  L.W = L.W * 1   -- (the hinge turns the crank clockwise, seen from above, for a positive speed)
  return true
end
local function drawParts()
  if not L then return end
  for _, e in ipairs(L.edges) do
    local x, z = world(e.body, e.m)
    e.obj.trans = btTransform(btQuaternion(AXIS, yaw(e.body) + e.a), btVector3(x, e.y + 0.1, z))
  end
  for _, P in ipairs(L.pens) do
    local x, z = world(P.pen.body, P.penL)
    P.cap.trans = btTransform(ident, btVector3(x, BOARD_T + 0.4, z))
  end
end

-- ---------------------------------------------------------------------
-- the pens' dots, and the check: how far each pen strayed from its stroke
-- (both ways: the farthest the pen got from the stroke, and the farthest a
-- point of the stroke is from the pen), in the letter's heights
-- ---------------------------------------------------------------------
local function penStep()
  for j, P in ipairs(L.pens) do
    local x, z = world(P.pen.body, P.penL)
    P.path[#P.path + 1] = { x, z }
    if not P.last or (x - P.last[1]) ^ 2 + (z - P.last[2]) ^ 2 > 0.04 then
      P.last = { x, z }
      local c = Cube(0.3, 0.03, 0.3, 0); c.collides = false; c.col = PEN_COL[(j - 1) % #PEN_COL + 1]
      v:add(c); L.objs[#L.objs + 1] = c
      c.trans = btTransform(ident, btVector3(x, BOARD_Y + 0.01, z))
    end
  end
end
local function segDist(px, pz, a, b)
  local dx, dz = b[1] - a[1], b[2] - a[2]
  local L2 = dx * dx + dz * dz
  local t = L2 > 0 and math.max(0, math.min(1, ((px - a[1]) * dx + (pz - a[2]) * dz) / L2)) or 0
  local qx, qz = a[1] + t * dx, a[2] + t * dz
  return math.sqrt((px - qx) ^ 2 + (pz - qz) ^ 2)
end
local function polyDist(px, pz, poly)
  local best = 1e9
  for i = 1, #poly - 1 do best = math.min(best, segDist(px, pz, poly[i], poly[i + 1])) end
  return best
end
local function check()
  local bx = (L.entry.box[1] + L.entry.box[2]) / 2
  local by = (L.entry.box[3] + L.entry.box[4]) / 2
  local worst, ok = 0, true
  local lines = {}
  for j, P in ipairs(L.pens) do
    local stroke = {}
    for i, p in ipairs(P.stroke) do stroke[i] = { CMH * (p[1] - bx), -CMH * (p[2] - by) } end
    local path = {}
    for i = 1, #P.path, 3 do path[#path + 1] = P.path[i] end
    local h1 = 0
    for _, q in ipairs(path) do h1 = math.max(h1, polyDist(q[1], q[2], stroke)) end
    local h2 = 0
    for i = 1, #stroke - 1 do
      for t = 0, 1, 0.1 do
        local x = stroke[i][1] + t * (stroke[i + 1][1] - stroke[i][1])
        local z = stroke[i][2] + t * (stroke[i + 1][2] - stroke[i][2])
        h2 = math.max(h2, polyDist(x, z, path))
      end
    end
    local h = math.max(h1, h2) / CMH
    worst = math.max(worst, h)
    local right = h <= P.h + 0.005
    ok = ok and right
    lines[#lines + 1] = string.format("    pen %d (%d bars): off its stroke %.2f%% of the height, computed %.2f%%  (%s)",
      j, 4 + 2 * P.D, 100 * h, 100 * P.h, right and "right" or "WRONG")
  end
  return ok, worst, lines
end

-- ---------------------------------------------------------------------
-- the jobs: build a letter, turn the crank once, check
-- ---------------------------------------------------------------------
local job, queue = nil, {}
local S = { letter = "B", level = 3, result = nil }
local function idle() return job == nil and #queue == 0 end
local function showLetter()
  local e = ALPHA[S.letter] and ALPHA[S.letter][S.level]
  showText(1, S.letter)
  show(slate.level, LEVELTILE[S.level])
  if e then
    showText(2, tostring(#e.pens)); showText(3, tostring(e.bars)); showText(4, string.format("%.1f%%", 100 * e.worst))
  end
end
local function queueDraw(letter, level)
  queue[#queue + 1] = { kind = "draw", letter = letter, level = level }
end
local function stepJob(dt)
  if not job then
    job = table.remove(queue, 1)
    if not job then return end
    job.t = 0
    if job.kind == "draw" then
      S.letter, S.level, S.result = job.letter, job.level, nil
      showLetter()
      sayIt("building")
      if not build(job.letter, job.level) then job = nil; return end
      job.phase = "settle"
      for _, P in ipairs(L.pens) do P.path = {} end
    end
  end
  job.t = job.t + dt
  if job.kind == "wait" then if job.t >= job.wait then job = nil end; return end
  local master = L.pens[1]
  if job.phase == "settle" then
    master.crankH:enableAngularMotor(true, 0, 50)
    for j = 2, #L.pens do L.pens[j].crankH:enableAngularMotor(true, 0, 200) end
    if job.t >= 0.3 then
      job.phase = "draw"; job.t = 0; sayIt("drawing"); L.turned = 0; L.slip = 0
      for _, P in ipairs(L.pens) do P.lastYaw, P.turned = yaw(P.B.crank.body), 0 end
    end
    return
  end
  if job.phase == "draw" then
    local ramp = math.min(1, job.t / 0.5)
    master.crankH:enableAngularMotor(true, L.W * ramp, 50)
    for j, P in ipairs(L.pens) do
      local y = yaw(P.B.crank.body)
      local d = y - P.lastYaw
      if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
      P.turned = P.turned + d; P.lastYaw = y
    end
    for j = 2, #L.pens do
      local P = L.pens[j]
      local err = P.s * master.turned - P.turned
      -- (the hinge's motor speed turns the crank the other way round to its
      -- yaw: the master's motor speed L.W makes its yaw go at -L.W)
      P.crankH:enableAngularMotor(true, P.s * L.W * ramp - 30 * err, 200)
      L.slip = math.max(L.slip or 0, math.abs(err))
    end
    L.turned = master.turned
    penStep()
    if math.abs(L.turned) >= 2 * math.pi + 0.02 then
      for _, P in ipairs(L.pens) do P.crankH:enableAngularMotor(true, 0, 200) end
      local ok, worst, lines = check()
      S.result = ok
      print(string.format("  %s, %s: %d pen%s, %d bars; the worst pen off its stroke %.2f%% of the height%s (%s)",
        L.letter, L.level, #L.pens, #L.pens > 1 and "s" or "", L.entry.bars, 100 * worst,
        #L.pens > 1 and string.format("; the cranks in step within %.2f deg", math.deg(L.slip or 0)) or "", ok and "right" or "WRONG"))
      if os.getenv("LW_LOG") then for _, l in ipairs(lines) do print(l) end end
      if not ok then for _, l in ipairs(lines) do print(l) end end
      showText(4, string.format("%.1f%%", 100 * worst), ok)
      sayIt(ok and "done" or "wrong")
      job = nil
    elseif job.t > 4 * v:getParam("turn") + 3 then
      print(string.format("  %s, %s: the crank stuck at %.0f degrees (WRONG)", L.letter, L.level, math.deg(L.turned)))
      S.result = false; sayIt("wrong"); job = nil
    end
  end
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = { { "B", 1 }, { "B", 2 }, { "B", 3 }, { "K", 3 } }
if os.getenv("LW_ALL") == "1" then
  TOUR = {}
  for i = 0, 25 do for lv = 1, 3 do TOUR[#TOUR + 1] = { string.char(65 + i), lv } end end
end
local touring, fails, frame = nil, 0, 0
local function tourStart()
  touring, fails = 1, 0
  print(string.format("\nLINKAGES THAT WRITE -- the tour: %d letters", #TOUR))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > 1 and S.result ~= true then fails = fails + 1 end
  if touring > #TOUR then
    touring = nil
    print("RESULT linkages-write tour: " .. (fails == 0 and "PASS" or "FAIL")
          .. string.format("  (%d letters, %d wrong; frame %d)", #TOUR, fails, frame))
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  S.result = nil
  queue[#queue + 1] = { kind = "wait", wait = touring == 2 and 0.3 or 1.0 }
  queueDraw(t[1], t[2])
end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdLeft, holdNow = HOLD_FRAMES, false
v:preSim(function(N)
  if holdLeft > 0 then holdLeft = holdLeft - 1; holdNow = true; v.timeStep = 0; return end
  if holdNow then holdNow = false; applyTiming() end
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)
local started = false
v:postSim(function(N)
  frame = N
  drawParts()
  if holdNow then return end
  if not started then
    started = true
    local s = os.getenv("LW_SET")
    if s then
      local c, lv = s:match("^%s*(%a)%s*(%d?)")
      if c then queueDraw(c:upper(), tonumber(lv) or 3) end
    end
    if (os.getenv("LW_TOUR") or "1") ~= "0" and not s then tourStart() end
  end
  stepJob(FRAME_DT)
  tourNext()
end)
showLetter()

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
for i = 0, 25 do
  local c = string.char(65 + i)
  v:addShortcut(c, function()
    touring = nil
    if job and job.kind == "draw" then return end
    queueDraw(c, S.level)
  end)
end
for lv = 1, 3 do
  v:addShortcut(tostring(lv), function()
    touring = nil
    S.level = lv
    v:setParam("accuracy", lv)
    if idle() then queueDraw(S.letter, lv) end
  end)
end
pcall(function() v:addShortcut("Space", function() touring = nil; if idle() then queueDraw(S.letter, S.level) end end) end)
v:addShortcut("0", function() tourStart() end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "accuracy" then
    local lv = math.floor(value + 0.5)
    if lv ~= S.level then S.level = lv; showLetter() end
  end
end)
if not hallPath then      -- (in the hall, F1 is the hall's: it opens this manual)
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  v:addShortcut("F1", function() MANUAL.open(DIR, "the linkages that write's manual") end)
end
pcall(function()
  v:setHelpText(table.concat({
    "LINKAGES THAT WRITE",
    "Type a letter: its linkages go on the board, one crank turns once, and every pen",
    "draws its stroke. Each pen is its own linkage of hinged bars, found in advance by",
    "a search (William Spears's synthesizer); the other cranks are kept in step with it.",
    "A letter with junctions is split among pens; a better letter takes more bars.",
    "",
    "KEYS: A-Z a letter; 1 2 3 sloppy, ok, very good; Space draw it again; 0 the tour;",
    "F1 the manual. The slate: the letter, its pens and bars, and its worst pen.",
    "",
    "Every link is a body and every pin a hinge; the cranks turn together, as on a belt.",
    "The slate, the grey guide and the pens' dots are the script's." }, "\n"))
end)
if v.onHover then
  v:onHover(function(N, obj)
    if not objectKey then return nil end
    local k = objectKey(obj)
    if k == objectKey(O.board) then return "the board: the cranks' and the dyads' fixed pivots stand in it" end
    if k == objectKey(O.slate) then return "the slate: the letter, how many pens and bars it took, and how close its worst pen came" end
    if L then
      for _, e in ipairs(L.edges) do
        if k == objectKey(e.obj) then
          local P = L.pens[e.pen]
          return string.format("pen %d of %d: its own linkage, %d bars (%s)", e.pen, #L.pens, 4 + 2 * P.D,
            e.part == "crank" and (e.pen == 1 and "its crank: the motor turns it" or "its crank: geared to the first")
            or e.part)
        end
      end
      for j, P in ipairs(L.pens) do if k == objectKey(P.cap) then return string.format("pen %d of %d", j, #L.pens) end end
    end
    return nil
  end)
end
common.setCamera(btVector3(0, 58, 32), btVector3(0, 2, -5))
