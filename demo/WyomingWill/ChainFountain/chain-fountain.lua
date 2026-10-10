--
-- The Chain Fountain -- Euler's Cabinet of Curiosities
--
-- Pull the end of a long bead chain out of a jar and let it fall to the
-- floor, and the chain pours out of the jar on its own -- but it doesn't
-- just slide over the rim: it leaps up and over in an arch, a fountain of
-- chain standing above the jar. Steve Mould filmed it in 2013 (the "Mould
-- effect"); John Biggins and Mark Warner explained it in 2014.
--
-- WHY: a chain's links are short stiff rods, and a chain can only bend so
-- far between links. A link being picked up off the pile is lifted by one
-- end, so it turns about its middle and pushes its other end down into the
-- pile. The pile pushes back -- and that upward push, on top of the pull
-- of the falling chain, throws the chain up above the jar. A rope, which
-- has no such links, just slides over the rim.
--
-- THE CHAIN: 1.5 cm links (rods 6 mm thick) joined by joints that bend at
-- most 30 degrees (the bending slider), 0.5 g a link; about 16 m of it,
-- coiled flat in layers in a glass jar 1.5 m above the floor. It runs at
-- 3-5 m/s, so it starts at a quarter of real speed (Z: real speed).
--
-- SIMULATION, to keep it to what a computer can do in time:
--  * The coil in the jar waits, drawn but not simulated, on a flat rigid
--    pile; ten links ahead of the one being picked up are simulated, and
--    more are woken as the chain comes for them.
--  * A link that reaches the floor is frozen where it lands.
--  * So only the moving chain is simulated, about 150-200 links, with
--    1800 physics steps a second and 20 solver iterations.
--
-- Keys
--   R   start again (with the sliders' chain settings)
--   V   the fountain close up <-> the whole drop
--   Z   quarter speed <-> real speed
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: CF_SPEED, CF_STEPS, CF_BEND, CF_LOG=file.csv.
--

local common = require "common"

local DIR = "chain-fountain-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/ChainFountain/" .. DIR }) do
  local f = io.open(dir .. "link.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local L, RL = 1.5, 0.3                  -- a link: joint to joint, and its radius (as in link.obj)
local MASS = 0.0005
local RJ, JH = 7, 8                     -- the jar: inside radius, height of its wall
local LAYER_T = 2 * RL + 0.05           -- the coil: one layer's thickness
local K_AHEAD = 10                      -- links simulated ahead of the pick-up
local ABSORB_Y = 2.5                    -- links lower than this are on the floor

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("CF_SPEED", 0.25), 0.05, 1, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("CF_STEPS", 1800), 1200, 4800, 300, "physics steps per simulated second")
param("bending", envnum("CF_BEND", 30), 10, 90, 5, "most a joint can bend, degrees (on R)")
param("height", envnum("CF_HEIGHT", 150), 60, 200, 10, "the jar above the floor, cm (on R)")
param("layers", envnum("CF_LAYERS", 10), 2, 14, 1, "layers of chain in the jar, 1.6 m each (on R)")
param("friction", 0.3, 0.05, 1, 0.05, "friction, chain on glass and chain")

local STEP, NSTEPS, FRAME_DT = 1 / 1800, 30, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()
v:setSolverIterations(20)
v.gravity = btVector3(0, -G, 0)

local floor = Plane(0, 1, 0, 0, 300)
floor.col = "#3b3f45"
v:add(floor)

local UPQ = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local ident = btQuaternion(0, 0, 0, 1)
local function show(o, col, tr)
  o.col = col
  o.collides = false
  if tr then o.transparency = tr end
  v:add(o)
  return o
end

-- ---------------------------------------------------------------------
-- the jar on its stand (rebuilt on R, since the height can change)
-- ---------------------------------------------------------------------
local scene = {}          -- everything built for one run, to take away on R
local function keep(o) scene[#scene + 1] = o; return o end
local H, MU
local function buildJar()
  -- the stand: a turned walnut column, and a foot (only to look at: the
  -- chain falls clear of it)
  local col = Cylinder(4.5, H - 4, 0); col.trans = btTransform(UPQ, btVector3(0, (H - 4) / 2, 0))
  keep(show(col, "#4a2c14"))
  local foot = Cylinder(16, 4, 0); foot.trans = btTransform(UPQ, btVector3(0, 2, 0))
  keep(show(foot, "#3b2412"))
  local cap = Cylinder(RJ + 3, 4, 0); cap.trans = btTransform(UPQ, btVector3(0, H - 2, 0))
  keep(show(cap, "#b8932e"))
  -- the jar: a glass wall of 24 slabs, solid; its floor
  for i = 0, 23 do
    local a = 2 * math.pi * i / 24
    local s = Cube(2 * math.pi * (RJ + 0.5) / 24 + 0.15, JH, 1.0, 0)
    s.trans = btTransform(btQuaternion(btVector3(0, 1, 0), -a + math.pi / 2),
                          btVector3((RJ + 0.5) * math.cos(a), H + JH / 2, (RJ + 0.5) * math.sin(a)))
    s.col = "#cfe8f0"
    s.transparency = 0.75
    s.friction = MU
    v:add(s)
    keep(s)
  end
end

-- the pile: a rigid disc at the top of the coil (lowered a layer at a
-- time), and under it the rest of the coil drawn as a block
local disc, block
local function setPile(top)
  if not disc then
    disc = Cylinder(RJ + 0.3, 1, 0)
    disc.col = "#8a8a8a"
    disc.friction = MU
    v:add(disc)
    keep(disc)
  end
  disc.trans = btTransform(UPQ, btVector3(0, top - 0.5, 0))
  if block then v:remove(block) end
  local h = top - 1 - H
  if h > 0.2 then
    block = Cylinder(RJ - 0.05, h, 0)
    block.trans = btTransform(UPQ, btVector3(0, H + h / 2, 0))
    show(block, "#7c7c7c")
  else
    block = nil
  end
end

-- ---------------------------------------------------------------------
-- the chain
-- ---------------------------------------------------------------------
local SHAPE = btCapsuleShapeX(RL, L - 2 * RL)
local IP = MASS * (L * L / 12 + RL * RL / 4)
local INERTIA = btVector3(0.5 * MASS * RL * RL, IP, IP)
local LINK_COL = "#c9c3b4"

local function quatAlong(dx, dy, dz)          -- turns +x onto (dx, dy, dz)
  local n = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / n, dy / n, dz / n
  local ay, az = -dz, dy
  local s = math.sqrt(ay * ay + az * az)
  if s < 1e-9 then return dx > 0 and ident or btQuaternion(btVector3(0, 1, 0), math.pi) end
  return btQuaternion(btVector3(0, ay / s, az / s), math.atan2(s, dx))
end

local pts, layerOf = {}, {}       -- the chain's joint points, floor end first; each one's coil layer
local links = {}                  -- by index: { obj, body, con, rest, disp, active, frozen }
local tail, head, nLead, LAYERS, curLayer
local BEND
local run = { t = 0, absorbed = 0, top = -1e9, best = -1e9, speedAvg = 0, topAvg = 0 }

-- the coil: in each layer a flat spiral, outside in, then inside out
local function coil(yTop)
  local out = {}
  -- (no tighter than 3 cm: a chain that bends 30 degrees a joint can't)
  local Ro, Ri = RJ - RL - 0.3, 3.0
  local b = (2 * RL + 0.1) / (2 * math.pi)
  local y = yTop
  for layer = 1, LAYERS do
    local seq = {}
    local phi, r = 0, Ro
    while r > Ri do
      seq[#seq + 1] = { r, phi }
      local ds = 0
      while ds < L do
        local r2 = r - b * 0.01
        ds = ds + math.sqrt((r * 0.01) ^ 2 + (r - r2) ^ 2)
        phi, r = phi + 0.01, r2
      end
    end
    if layer % 2 == 0 then
      local rev = {}
      for i = #seq, 1, -1 do rev[#rev + 1] = seq[i] end
      seq = rev
    end
    for _, s in ipairs(seq) do out[#out + 1] = { btVector3(s[1] * math.cos(s[2]), y, s[1] * math.sin(s[2])), layer } end
    y = y - LAYER_T
  end
  return out
end

local function linkPose(i)
  local p, q = pts[i], pts[i + 1]
  return btVector3((p.x + q.x) / 2, (p.y + q.y) / 2, (p.z + q.z) / 2), quatAlong(q.x - p.x, q.y - p.y, q.z - p.z)
end
-- a coil link not yet moving: drawn only
local function drawWaiting(i)
  if links[i] or i >= #pts then return end
  local mid, rot = linkPose(i)
  local m = Mesh(DIR .. "link.obj", 0, false)
  m.trans = btTransform(rot, mid)
  show(m, LINK_COL)
  links[i] = { disp = m }
end
local function drawLayer(layer)
  for i = nLead, #pts - 1 do if layerOf[i] == layer then drawWaiting(i) end end
end
local function join(a, b)
  local c = btConeTwistConstraint(a.body, b.body, btTransform(ident, btVector3(L / 2, 0, 0)),
                                  btTransform(ident, btVector3(-L / 2, 0, 0)))
  c:setLimit(5, BEND); c:setLimit(4, BEND); c:setLimit(3, math.pi)
  v:addConstraint(c)
  a.con = c
end
-- a link starts moving
local function wake(i)
  local l = links[i] or {}
  if l.disp then v:remove(l.disp); l.disp = nil end
  local mid, rot = linkPose(i)
  local m = Mesh(DIR .. "link.obj", 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(rot, mid)), SHAPE, INERTIA)
  m.body = body
  m.col = LINK_COL
  v:add(m)
  body:setActivationState(4)
  body:setFriction(MU)
  body:setRestitution(0)
  body:setDamping(0, 0)
  l.obj, l.body, l.rest, l.active = m, body, mid, true
  links[i] = l
  if links[i - 1] and links[i - 1].active then join(links[i - 1], l) end
  head = i
  -- (a new layer: the pile drops to it, and the layer under it is drawn)
  local lay = layerOf[i]
  if lay and lay > curLayer then
    curLayer = lay
    setPile(H + JH - 1.5 - (lay - 1) * LAYER_T - RL)
    drawLayer(lay + 1)
  end
end

local function teardown()
  for _, l in pairs(links) do
    if l.con then v:removeConstraint(l.con) end
    if l.obj then v:remove(l.obj) end
    if l.disp then v:remove(l.disp) end
  end
  links = {}
  for _, o in ipairs(scene) do v:remove(o) end
  scene = {}
  if block then v:remove(block) end
  disc, block = nil, nil
end

local VIEW = 1
local function setView()
  if VIEW == 1 then common.setCamera(btVector3(14, H + 30, 75), btVector3(10, H + 2, 0))
  else common.setCamera(btVector3(30, H * 0.65, 230 + H * 0.4), btVector3(10, H * 0.5, 0)) end
end

local function start()
  teardown()
  H = v:getParam("height")
  MU = v:getParam("friction")
  LAYERS = math.floor(v:getParam("layers") + 0.5)
  BEND = math.rad(v:getParam("bending"))
  buildJar()
  -- the coil, its top layer just under the rim
  local c = coil(H + JH - 1.5)
  -- the lead: from the coil's first point straight up, over the rim and
  -- down beside the jar to the floor (floor end first)
  local p0 = c[1][1]
  local path = {}
  local y = p0.y
  while y < H + JH + 1.2 do path[#path + 1] = btVector3(p0.x, y, 0); y = y + L end
  local top = path[#path]
  local xo = RJ + 2.5
  local n = math.ceil((xo - p0.x) / L)
  for i = 1, n do path[#path + 1] = btVector3(p0.x + (xo - p0.x) * i / n, top.y, 0) end
  y = top.y - L
  while y > ABSORB_Y + 1 do path[#path + 1] = btVector3(xo, y, 0); y = y - L end
  pts, layerOf = {}, {}
  for i = #path, 1, -1 do pts[#pts + 1] = path[i] end
  nLead = #pts
  for i = 2, #c do pts[#pts + 1] = c[i][1]; layerOf[#pts - 1] = c[i][2] end
  layerOf[nLead] = 1
  curLayer = 1
  setPile(H + JH - 1.5 - RL)
  drawLayer(1); drawLayer(2)
  tail, head = 1, 0
  for i = 1, nLead - 1 + K_AHEAD do wake(i) end
  run = { t = 0, absorbed = 0, top = -1e9, best = -1e9, speedAvg = 0, topAvg = 0, total = #pts - 1 }
  print(string.format("\n--- %.1f m of chain, %d links; the jar %.0f cm up; joints bend %.0f deg at most ---",
                      (#pts - 1) * L / 100, #pts - 1, H, math.deg(BEND)))
  setView()
end

-- wake links ahead of the pick-up; freeze the ones that have landed
local function feed()
  local n, i = 0, head
  while i >= tail and links[i] and links[i].rest do
    local x, y, z = getPosXYZ(links[i].obj)
    local r = links[i].rest
    if (x - r.x) ^ 2 + (y - r.y) ^ 2 + (z - r.z) ^ 2 > 1.0 then break end
    n, i = n + 1, i - 1
  end
  local woke = 0
  while n < K_AHEAD and head + 1 < #pts and woke < 6 do
    wake(head + 1)
    n, woke = n + 1, woke + 1
  end
end
local function absorb()
  while tail < head - K_AHEAD do
    local l = links[tail]
    local _, y, _ = getPosXYZ(l.obj)
    if y > ABSORB_Y then break end
    if l.con then v:removeConstraint(l.con); l.con = nil end
    l.body:forceActivationState(5)               -- DISABLE_SIMULATION: it lies where it fell
    l.active, l.frozen = false, true
    tail = tail + 1
    run.absorbed = run.absorbed + 1
  end
end

v:preSim(function(N)
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)

local LOGF = os.getenv("CF_LOG") and io.open(os.getenv("CF_LOG"), "w")
if LOGF then LOGF:write("t,top_above_rim,speed,active\n") end
v:postSim(function(N)
  run.t = run.t + FRAME_DT
  absorb()
  feed()
  -- the chain's highest point above the rim, and how fast it goes there
  local top, ti = -1e9, nil
  for i = tail, head do
    local l = links[i]
    if l and l.active then
      local _, y, _ = getPosXYZ(l.obj)
      if y > top then top, ti = y, i end
    end
  end
  local rim = H + JH
  if ti and tail < head - K_AHEAD then
    local vx, vy, vz = getVelXYZ(links[ti].obj)
    local sp = math.sqrt(vx * vx + vy * vy + vz * vz)
    run.top, run.speed = top - rim, sp
    run.best = math.max(run.best, top - rim)
    run.topAvg = run.topAvg + (run.top - run.topAvg) * 0.05
    run.speedAvg = run.speedAvg + (sp - run.speedAvg) * 0.05
    if LOGF and N % 2 == 0 then LOGF:write(string.format("%.4f,%.2f,%.1f,%d\n", run.t, run.top, sp, head - tail + 1)) end
  end
  if N % 60 == 0 and not run.done then
    if head + 1 >= #pts and tail >= head - K_AHEAD then
      run.done = true
      print(string.format("t=%5.2fs  all of it out of the jar; the fountain stood up to %.1f cm above the rim", run.t, run.best))
    elseif ti then
      print(string.format("t=%5.2fs  fountain %4.1f cm above the rim (average %4.1f, highest %4.1f); chain %3.0f cm/s; %d links moving, %.1f m out",
                          run.t, run.top, run.topAvg, run.best, run.speedAvg, head - tail + 1, run.absorbed * L / 100))
    end
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N) start() end)
v:addShortcut("V", function(N) VIEW = 3 - VIEW; setView() end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 1, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "friction" then
    MU = value
    for i = tail, head do if links[i] and links[i].body then links[i].body:setFriction(MU) end end
  end
end)

v:setHelpText(table.concat({
  "The chain fountain (Euler's Cabinet of Curiosities)",
  "",
  "A long bead chain pours out of a jar on its own -- and leaps",
  "up over the rim in an arch on its way down to the floor.",
  "",
  "Why: each link is a short stiff rod, and the chain can only bend",
  "so far between links. A link picked up by one end pushes its other",
  "end down into the pile; the pile pushes back, and throws the chain up.",
  "",
  "R   start again (with the bending, height and layers sliders)",
  "V   the fountain close up <-> the whole drop",
  "Z   quarter speed <-> real speed",
  "",
  "Try bending 90 (a floppier chain): the fountain shrinks to a few",
  "centimetres; at 20 (stiffer) it stands twice as high.",
  "Rest the mouse on the chain to see how fast it's going.",
}, "\n"))

if v.onHover then
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey(obj)
    for i = tail, head do
      local l = links[i]
      if l and l.obj and objectKey(l.obj) == k then
        local vx, vy, vz = getVelXYZ(l.obj)
        return string.format("link %d of %d, %.0f cm/s\nfountain now %.1f cm above the rim (highest %.1f)\n%.1f m of chain out of the jar",
                             i, run.total or 0, math.sqrt(vx * vx + vy * vy + vz * vz), run.top or 0, run.best or 0,
                             run.absorbed * L / 100)
      end
    end
    return nil
  end)
end

start()
