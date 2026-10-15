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
--    more are woken as the chain comes for them. The last one woken is held
--    by its far end where it lies, as the rest of the coil would hold it.
--  * A link that reaches the floor is frozen where it lands, and is only
--    drawn from then on: the floor takes the chain without pulling on it.
--  * So only the moving chain is simulated, about 130-200 links, with
--    1800 physics steps a second and 20 solver iterations. Waking, freezing
--    and measuring are done after every step, so the chain does exactly
--    the same at any speed.
--
-- At the end it prints the steady part of the run against Biggins and
-- Warner's theory (see theory() below).
--
-- Keys
--   R   start again
-- The bending, height and layers sliders start it again too, once you let
-- go of them (half a second after the last change).
--   V   the fountain close up <-> the whole drop
--   Z   quarter speed <-> real speed
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: CF_SPEED, CF_STEPS, CF_BEND, CF_HEIGHT, CF_LAYERS, CF_LOG=file.csv,
-- CF_PUSH=1 (measure the pile's push: see measurePush).
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
local WAKE_RATE = 1200                  -- links woken a simulated second at most (18 m/s)
local SAMPLE_DT, PRINT_DT = 1 / 240, 0.25   -- measure the fountain, and print, this often (simulated s)
local T_STEADY = 1.0                    -- the theory check averages from here on

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("CF_SPEED", 0.25), 0.05, 1, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("CF_STEPS", 1800), 1200, 4800, 300, "physics steps per simulated second")
param("bending", envnum("CF_BEND", 30), 20, 90, 5, "most a joint can bend, degrees (starts it again)")
param("height", envnum("CF_HEIGHT", 150), 60, 200, 10, "the jar above the floor, cm (starts it again)")
param("layers", envnum("CF_LAYERS", 10), 2, 14, 1, "layers of chain in the jar, 1.6 m each (starts it again)")
param("friction", 0.3, 0.05, 1, 0.05, "friction, chain on glass and chain")

-- The physics step is always 1/steps of a simulated second, whatever the
-- speed: a frame takes as many whole steps as its share of simulated time
-- (at a quarter speed, 7 and 8 in turn), and all the script's own work
-- (waking, freezing, measuring) is done after every step, not every frame.
-- So the chain does exactly the same at any speed; only what is drawn differs.
local STEP, PER_FRAME, stepAcc = 1 / 1800, 30, 0
local function applyTiming()
  STEP = 1 / v:getParam("steps")
  PER_FRAME = v:getParam("steps") * v:getParam("speed") / 60
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
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
-- (to tell the chain's contacts apart, for the pile's push: see measurePush)
local linkOf, discKey, jarKeys = {}, nil, {}
local okey = objectKey
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
    if okey then jarKeys[okey(s)] = true end
  end
end

-- the pile: a rigid disc at the top of the coil (lowered a layer at a
-- time), and under it the rest of the coil drawn as a block
local disc, block
local pickY                       -- the height of the chain lying on the pile
local function setPile(top)
  if not disc then
    disc = Cylinder(RJ + 0.3, 1, 0)
    disc.col = "#8a8a8a"
    disc.friction = MU
    v:add(disc)
    keep(disc)
    if okey then discKey = okey(disc) end
  end
  disc.trans = btTransform(UPQ, btVector3(0, top - 0.5, 0))
  pickY = top + RL
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
local anchor, anchorBody          -- holds the far end of the last link woken
local BEND
local run = { t = 0, absorbed = 0, top = -1e9, best = -1e9, speedAvg = 0, topAvg = 0 }

-- the coil: in each layer a flat spiral, outside in, then inside out, all
-- turning the same way; at the end of a layer the chain tips down to the
-- next over DROP links, going on round. Every link is laid L long, and no
-- joint is laid bent further than it can bend: the spiral is no tighter
-- than the chain can turn while it tips down (and never under 3 cm).
-- (Until 15 Oct 2026 the spiral went in to 3 cm whatever the bending, so at
-- 20 degrees a third of the joints were laid bent past their stop, and each
-- layer began with a link 0.65 cm long, standing upright, the next layer
-- turning back the other way: when woken, those joints were kicked straight
-- by the solver.)
local DROP = 3
local function coil(yTop)
  local out = {}
  local dy = LAYER_T / DROP
  local tip = math.asin(dy / L)                                   -- a dropping link's slope
  local turn = math.sqrt(math.max(BEND * BEND - tip * tip, 1e-6))    -- most a joint may turn round
  local Ro = RJ - RL - 0.3
  local Ri = math.min(Ro, math.max(3.0, L / (2 * math.sin(turn / 2)) + 0.1))
  local b = (2 * RL + 0.1) / (2 * math.pi)
  local function put(r, phi, y, layer) out[#out + 1] = { btVector3(r * math.cos(phi), y, r * math.sin(phi)), layer } end
  local phi, r, y = 0, Ro, yTop
  put(r, phi, y, 1)
  for layer = 1, LAYERS do
    local dir = layer % 2 == 1 and -1 or 1                         -- inward, then outward
    if layer > 1 then
      -- tip down to this layer, going on round at the radius it's at
      local c = math.sqrt(L * L - dy * dy)
      for _ = 1, DROP do
        phi, y = phi + 2 * math.asin(c / (2 * r)), y - dy
        put(r, phi, y, layer)
      end
    end
    while true do
      local ds, r2, phi2 = 0, r, phi
      while ds < L do
        local r3 = r2 + dir * b * 0.01
        ds = ds + math.sqrt((r2 * 0.01) ^ 2 + (r3 - r2) ^ 2)
        phi2, r2 = phi2 + 0.01, r3
      end
      if (dir < 0 and r2 < Ri) or (dir > 0 and r2 > Ro) then break end
      phi, r = phi2, r2
      put(r, phi, y, layer)
    end
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
  if okey then linkOf[okey(m)] = i end
  body:setActivationState(4)
  body:setFriction(MU)
  body:setRestitution(0)
  body:setDamping(0, 0)
  l.obj, l.body, l.rest, l.active = m, body, mid, true
  links[i] = l
  if links[i - 1] and links[i - 1].active then join(links[i - 1], l) end
  head = i
  -- (the coil not yet moving holds the chain's far end where it lies, as
  -- the rest of the pile would: a moving chain can't drag it off)
  if anchor then v:removeConstraint(anchor); anchor = nil end
  if i + 1 < #pts then
    local mid2, rot2 = linkPose(i + 1)
    local held = btRigidBody(0, btDefaultMotionState(btTransform(rot2, mid2)), SHAPE, btVector3(0, 0, 0))
    anchor = btConeTwistConstraint(body, held, btTransform(ident, btVector3(L / 2, 0, 0)),
                                   btTransform(ident, btVector3(-L / 2, 0, 0)))
    anchorBody = held                            -- (kept, so Lua doesn't collect it)
    anchor:setLimit(5, BEND); anchor:setLimit(4, BEND); anchor:setLimit(3, math.pi)
    v:addConstraint(anchor)
  end
  -- (a new layer: the pile drops to it, and the layer under it is drawn)
  local lay = layerOf[i]
  if lay and lay > curLayer then
    curLayer = lay
    setPile(H + JH - 1.5 - (lay - 1) * LAYER_T - RL)
    drawLayer(lay + 1)
  end
end

local function teardown()
  if anchor then v:removeConstraint(anchor); anchor = nil end
  for _, l in pairs(links) do
    if l.con then v:removeConstraint(l.con) end
    if l.obj then v:remove(l.obj) end
    if l.disp then v:remove(l.disp) end
  end
  links, linkOf, discKey, jarKeys = {}, {}, nil, {}
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
  holdStart()
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
  run = { t = 0, absorbed = 0, top = -1e9, best = -1e9, speedAvg = 0, topAvg = 0, total = #pts - 1,
          budget = 0, nextSample = SAMPLE_DT, nextPrint = PRINT_DT,
          steady = { n = 0, h2 = 0, h1 = 0, rim = 0, steps = 0, push = 0, rimUp = 0, landed = 0, v2 = 0 } }
  stepAcc = 0
  print(string.format("\n--- %.1f m of chain, %d links; the jar %.0f cm up; joints bend %.0f deg at most ---",
                      (#pts - 1) * L / 100, #pts - 1, H, math.deg(BEND)))
  setView()
end

-- wake links ahead of the pick-up (ten still lying where they were laid,
-- no more than WAKE_RATE a simulated second); freeze the ones that have landed
local function feed()
  run.budget = math.min(K_AHEAD, run.budget + WAKE_RATE * STEP)
  local n, i = 0, head
  while i >= tail and links[i] and links[i].rest do
    local x, y, z = getPosXYZ(links[i].obj)
    local r = links[i].rest
    if (x - r.x) ^ 2 + (y - r.y) ^ 2 + (z - r.z) ^ 2 > 1.0 then break end
    n, i = n + 1, i - 1
  end
  while n < K_AHEAD and head + 1 < #pts and run.budget >= 1 do
    wake(head + 1)
    n, run.budget = n + 1, run.budget - 1
  end
end
local function absorb()
  while tail < head - K_AHEAD do
    local l = links[tail]
    local _, y, _ = getPosXYZ(l.obj)
    if y > ABSORB_Y then break end
    if l.con then v:removeConstraint(l.con); l.con = nil end
    -- (how fast it comes down, for the theory check: in the steady part)
    local st = run.steady
    if st.t0 and head + 1 < #pts then
      local vx, vy, vz = getVelXYZ(l.obj)
      st.landed, st.v2 = st.landed + 1, st.v2 + vx * vx + vy * vy + vz * vz
    end
    -- it lies where it fell, drawn only: the chain still coming down meets
    -- nothing on the floor, so nothing there pulls on it or holds it up
    local m = Mesh(DIR .. "link.obj", 0, false)
    m.trans = l.obj.trans
    if okey then linkOf[okey(l.obj)] = nil end
    v:remove(l.obj)
    l.obj, l.body, l.disp = nil, nil, show(m, LINK_COL)
    l.active, l.frozen = false, true
    tail = tail + 1
    run.absorbed = run.absorbed + 1
  end
end

local LOGF = os.getenv("CF_LOG") and io.open(os.getenv("CF_LOG"), "w")
if LOGF then LOGF:write("t,top_above_rim,speed,active,pickup_y,head,landed\n") end

-- the chain's highest point above the rim, and how fast it goes there
-- (every SAMPLE_DT of simulated time)
local function sample()
  local top, ti = -1e9, nil
  for i = tail, head do
    local l = links[i]
    if l and l.active then
      local _, y, _ = getPosXYZ(l.obj)
      if y > top then top, ti = y, i end
    end
  end
  run.ti = ti
  if not (ti and tail < head - K_AHEAD) then return end
  local rim = H + JH
  local vx, vy, vz = getVelXYZ(links[ti].obj)
  local sp = math.sqrt(vx * vx + vy * vy + vz * vz)
  run.top, run.speed = top - rim, sp
  -- (the highest: while there is chain still in the jar, not the free end
  -- flying out at the last)
  if head + 1 < #pts then run.best = math.max(run.best, top - rim) end
  run.topAvg = run.topAvg + (run.top - run.topAvg) * 0.05
  run.speedAvg = run.speedAvg + (sp - run.speedAvg) * 0.05
  -- for the theory check: the steady part, from T_STEADY until the last
  -- of the coil is woken
  if run.t >= T_STEADY and head + 1 < #pts then
    local s = run.steady
    if not s.t0 then s.t0, s.land0 = run.t, run.absorbed end
    s.n, s.t1, s.land1 = s.n + 1, run.t, run.absorbed
    s.h2, s.h1, s.rim = s.h2 + (top - pickY), s.h1 + (pickY - ABSORB_Y), s.rim + (rim - pickY)
  end
  if LOGF then LOGF:write(string.format("%.4f,%.2f,%.1f,%d,%.2f,%d,%d\n", run.t, run.top, sp, head - tail + 1, pickY, head, run.absorbed)) end
end

-- the pile's push, measured: after every physics step of the steady part,
-- the upward force of the pile (the disc) on the chain, from Bullet's
-- contact impulses, less the weight of the links lying on it (each link it
-- touches, m g: what it would carry anyway), and the upward force of the
-- jar (the rim, mostly). Only read, never changed. It walks all of Bullet's
-- contacts every step, which makes the run two or three times slower in the
-- Cabinet, so it is done only when asked for (CF_PUSH=1).
local PUSH = envnum("CF_PUSH", 0) > 0
local function measurePush()
  local s = run.steady
  if not (PUSH and s.t0 and okey and discKey and run.t >= T_STEADY and head + 1 < #pts) then return end
  local up, rimUp, lying, seen = 0, 0, 0, {}
  v:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
    if imp <= 0 then return end
    local ka, kb = a and okey(a), b and okey(b)
    local la, lb = ka and linkOf[ka], kb and linkOf[kb]
    local i, other, f
    if la and not lb then i, other, f = la, kb, imp * ny        -- (the normal is on b, pointing to a)
    elseif lb and not la then i, other, f = lb, ka, -imp * ny
    else return end
    if other == discKey then
      up = up + f
      if not seen[i] then seen[i] = true; lying = lying + 1 end
    elseif jarKeys[other] then
      rimUp = rimUp + f
    end
  end)
  s.steps = s.steps + 1
  s.push = s.push + up / STEP - lying * MASS * G
  s.rimUp = s.rimUp + rimUp / STEP
end

-- at the end: the steady part of the run against Biggins and Warner,
-- "Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689
-- (arXiv:1310.4056). Their h1 is the pick-up above the floor, h2 the top of
-- the chain above the pick-up; the pile pushes up on the link being picked
-- up with a m v^2 (m: mass per length), and the floor pulls down on the link
-- landing with b m v^2. Steady flow then gives v^2 = g h1 / (1 - a - b) and
-- h2 = a v^2 / g. Here a link that lands is frozen and its joint goes, and
-- the frozen links don't collide, so nothing at the floor pulls: b = 0, and
-- v^2 = g (h1 + h2), with nothing left to choose. a is not set anywhere: it
-- is read off three ways: from the height, from the speed (v: the rate the
-- links land), and from the pile's push itself (measurePush). The speed rule
-- needs only that the chain runs steadily from the pile to the floor; the
-- height rule needs as well that the chain goes straight up from the pile
-- and turns over in a narrow arch with nothing touching it (h2 = a v^2/g
-- less the radius of the arch's top). Here it doesn't: see the README. It
-- also prints how fast the links reach the floor: a chain that loses no
-- energy on the way would bring down 1/(2 (1 - a)) of the energy of the drop.
local function theory()
  local s = run.steady
  if s.n < 10 or s.t1 <= s.t0 then return end
  local h2, h1, rimUp = s.h2 / s.n, s.h1 / s.n, s.rim / s.n
  local vm = (s.land1 - s.land0) * L / (s.t1 - s.t0)
  local aRod = 0.5 * (1 - IP / (MASS * L * L / 4))
  print(string.format("  theory (Biggins and Warner 2014), steady part t=%.2f-%.2fs; h1 = %.1f cm, the pick-up above where a link lands (the rim is %.1f cm above the pick-up)",
                      s.t0, s.t1, h1, rimUp))
  print(string.format("  chain %.0f cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = %.0f cm/s and not rise above the pick-up",
                      vm, math.sqrt(G * h1)))
  print(string.format("  top of the chain %.1f cm above the pick-up on average (h2): h2/h1 = %.3f (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = %.0f cm/s",
                      h2, h2 / h1, math.sqrt(G * (h1 + h2))))
  print(string.format("  a = g h2/v^2 = %.2f from the height, 1 - g h1/v^2 = %.2f from the speed (rod model for one of these links: %.2f)",
                      G * h2 / (vm * vm), 1 - G * h1 / (vm * vm), aRod))
  if s.landed > 0 then
    local v2 = s.v2 / s.landed
    print(string.format("  the links reach the floor at %.0f cm/s (rms), with %.0f%% of the energy of their drop (an ideal chain: 50%%; one the pile pushes, more)",
                        math.sqrt(v2), 100 * v2 / (2 * G * h1)))
  end
  if s.steps > 0 then
    local mv2 = MASS / L * vm * vm
    print(string.format("  the pile's push, measured (its contact forces less the weight lying on it): a = %.2f; the rim holds the chain up with %.2f m v^2",
                        s.push / s.steps / mv2, s.rimUp / s.steps / mv2))
  end
end

local function afterStep()
  run.t = run.t + STEP
  absorb()
  measurePush()
  feed()
  if run.t >= run.nextSample - 1e-9 then
    run.nextSample = run.nextSample + SAMPLE_DT
    sample()
  end
  if run.t >= run.nextPrint - 1e-9 and not run.done then
    run.nextPrint = run.nextPrint + PRINT_DT
    if head + 1 >= #pts and tail >= head - K_AHEAD then
      run.done = true
      print(string.format("t=%5.2fs  all of it out of the jar; the fountain stood up to %.1f cm above the rim", run.t, run.best))
      theory()
    elseif run.ti then
      print(string.format("t=%5.2fs  fountain %4.1f cm above the rim (average %4.1f, highest %4.1f); chain %3.0f cm/s; %d links moving, %.1f m out",
                          run.t, run.top, run.topAvg, run.best, run.speedAvg, head - tail + 1, run.absorbed * L / 100))
    end
    if LOGF then LOGF:flush() end
  end
end

v:preSim(function(N)
  if holdPre() then return end
  stepAcc = stepAcc + PER_FRAME
  local n = math.max(1, math.floor(stepAcc + 1e-9))
  stepAcc = stepAcc - n
  for k = 1, n - 1 do
    v:stepSimulation(STEP, 0, STEP)
    afterStep()
  end
  -- (and bpp takes the last step itself)
end)

local restartIn                 -- frames until a slider's restart (see onParamChanged)
v:postSim(function(N)
  if holdNow then return end
  afterStep()
  if restartIn then
    restartIn = restartIn - 1
    if restartIn <= 0 then restartIn = nil; start() end
  end
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
  -- the chain's own settings: start again with them, once the slider has
  -- been still for half a second (not at every step of a drag); and not
  -- when it's set to what this run already has (bpp's Restart puts every
  -- slider back as it was)
  local now = { bending = BEND and math.deg(BEND), height = H, layers = LAYERS }
  if now[name] ~= nil and math.abs(now[name] - value) > 1e-6 then restartIn = 30 end
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
  "R   start again (so do the bending, height and layers",
  "    sliders, once you let go of them)",
  "V   the fountain close up <-> the whole drop",
  "Z   quarter speed <-> real speed",
  "",
  "Try bending 20 (stiffer) or 90 (floppier): the fountain stands",
  "much the same, 3-9 cm above the rim most of the time.",
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
