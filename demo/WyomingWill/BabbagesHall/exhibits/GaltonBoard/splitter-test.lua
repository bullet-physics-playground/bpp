--
-- splitter-test.lua -- a test bed for funnel splitters (Babbage's Hall)
--
-- Does a neck above every pin make the pins independent? (The Galton
-- board's pins are fair but remember: FINDINGS section 6.) Rows of
-- "teeth": each a pin on top of a solid wedge whose sides slope down into
-- vertical necks; each neck drops a ball straight onto the pin below, half
-- a pitch to the side. Balls are fed one at a time down a neck onto the
-- first pin, with a small random offset, and each ball's path is recorded
-- in the Galton board's format (u = 2x/S at a level in each row's necks),
-- for paths.py:
--
--   SP_PATHS=/tmp/sp.txt SP_BALLS=600 bpp -f splitter-test.lua -n 30000
--   python3 paths.py /tmp/sp.txt
--
-- SP_LOG=1 prints, for each ball leaving a neck, the row, the way it came
-- in (+1 right), its offset from the neck's centre (mm) and its sideways
-- speed (mm/s). Results: SPLITTERS.md.
--
-- Sizes in mm; the same balls (6 mm steel), pins (4 mm), plates (a 7 mm
-- gap) and contacts (bounce 0.4, friction 0.3) as the Galton board. All
-- can be set from the environment (SP_<NAME>).
--
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local MM = 0.1
local P = {
  S = envnum("SP_S", 30),           -- the splitters' pitch
  PIN_D = envnum("SP_PIN_D", 4),
  BALL_D = 6, GAP = 7, BALL_MASS = 0.000884,
  NECK_W = envnum("SP_NECK_W", 8),  -- the necks' inside width
  NECK_L = envnum("SP_NECK_L", 10), -- their length
  SLOPE = envnum("SP_SLOPE", 60),   -- the wedges' sides, degrees from level
  FOOT = envnum("SP_FOOT", 8),      -- a neck's foot above the next pin's centre
  ROWS = envnum("SP_ROWS", 8),
  BOUNCE = envnum("SP_BOUNCE", 0.4), FRICTION = envnum("SP_FRICTION", 0.3),
  JITTER = envnum("SP_JITTER", 0.3),-- the feed's random offset, +- mm
  EVERY = envnum("SP_EVERY", 0.6),  -- s between balls fed
  NBALLS = envnum("SP_BALLS", 400),
  POOL = 6,
}
math.randomseed(envnum("SP_SEED", 1))
local HW = P.S / 2 - P.NECK_W / 2                 -- a wedge's half-width
local H = HW * math.tan(math.rad(P.SLOPE))        -- its slope's drop
local V = H + P.NECK_L + P.FOOT                   -- row to row
assert(HW > 1, "splitter-test: the necks are wider than the pitch allows")
local function rowY(r) return -r * V end
local function levelY(r) return rowY(r) - H - P.NECK_L / 2 end   -- in row r's necks

local HZ = 2400
local NSTEPS = 40
local STEP = 1 / 60 / NSTEPS
v.timeStep, v.maxSubSteps, v.fixedTimeStep = STEP, 0, STEP
v.gravity = btVector3(0, -981, 0)
pcall(function() v:setSolverIterations(20) end)

local ident = btQuaternion(0, 0, 0, 1)
local BASE = btVector3(0, 40, 0)
local function W3(x, y, z) return btVector3(BASE.x + x * MM, BASE.y + y * MM, BASE.z + (z or 0) * MM) end

-- the board: plates, pins, wedges and the feed's neck, one fixed body
local items = {}
local function add(shape, x, y, z, q)
  shape:setMargin(0.004)
  items[#items + 1] = { shape, btTransform(q or ident, btVector3(x * MM, y * MM, z * MM)) }
end
local zc = P.GAP / 2
local XMAX = (P.ROWS / 2 + 1.5) * P.S
local YTOP, YBOT = 60, levelY(P.ROWS - 1) - 30
add(btBoxShape(btVector3(XMAX * MM, (YTOP - YBOT) / 2 * MM, 0.5 * MM)), 0, (YTOP + YBOT) / 2, -0.5)
add(btBoxShape(btVector3(XMAX * MM, (YTOP - YBOT) / 2 * MM, 0.5 * MM)), 0, (YTOP + YBOT) / 2, P.GAP + 0.5)
local function hull(pts, x, y)
  local h = btConvexHullShape()
  for _, p in ipairs(pts) do
    for _, z in ipairs({ -P.GAP / 2, P.GAP / 2 }) do h:addPoint(btVector3(p[1] * MM, p[2] * MM, z * MM), false) end
  end
  h:recalcLocalAabb()
  add(h, x, y, zc)
end
local nTeeth = 0
for r = 0, P.ROWS - 1 do
  local y = rowY(r)
  for j = -P.ROWS, P.ROWS do
    local x = (j + (r % 2) / 2) * P.S
    if math.abs(x) <= (r / 2 + 1) * P.S then      -- the triangle the balls can reach, and one more each side
      add(btCylinderShapeZ(btVector3(P.PIN_D / 2 * MM, P.PIN_D / 2 * MM, P.GAP / 2 * MM)), x, y, zc)
      hull({ { 0, 0 }, { HW, -H }, { HW, -H - P.NECK_L }, { -HW, -H - P.NECK_L }, { -HW, -H } }, x, y)
      nTeeth = nTeeth + 1
    end
  end
end
-- the feed: a neck straight down onto the first pin
local FEED_L = 24
for _, s in ipairs({ -1, 1 }) do
  add(btBoxShape(btVector3(1 * MM, FEED_L / 2 * MM, P.GAP / 2 * MM)), s * (P.NECK_W / 2 + 1), P.FOOT + FEED_L / 2, zc)
end
local board = Cube(1, 1, 1, 0)
do
  local level = items                           -- (a tree of compounds, twelve to each: luabind
  while #level > 1 do                           -- holds only so many children on one)
    local up = {}
    for k = 1, #level, 12 do
      local c = btCompoundShape(true)
      for j = k, math.min(k + 11, #level) do c:addChildShape(level[j][2], level[j][1]) end
      up[#up + 1] = { c, btTransform(ident, btVector3(0, 0, 0)) }
    end
    level = up
  end
  local c = level[1][1]
  board.body = btRigidBody(0, btDefaultMotionState(btTransform(ident, BASE)), c, btVector3(0, 0, 0))
end
board.collides = true
v:add(board)
board.trans = btTransform(ident, BASE)
pcall(function() board.transparency = 1 end)
board.body:setRestitution(1); board.body:setFriction(1)

-- the balls: a few, fed one at a time and reused
local balls, idle = {}, {}
local PARK = { -XMAX - 40, 0 }
local function place(b, x, y)
  local tr = btTransform(ident, W3(x, y, P.GAP / 2))
  b.body:setCenterOfMassTransform(tr)
  b.body:setLinearVelocity(btVector3(0, 0, 0))
  b.body:setAngularVelocity(btVector3(0, 0, 0))
  b.body:clearForces()
  b.obj.trans = tr
end
for i = 1, P.POOL do
  local s = Sphere(P.BALL_D / 2 * MM, P.BALL_MASS)
  s.col = "#b9bec6"
  v:add(s)
  s.body:setActivationState(4)
  s.body:setRestitution(P.BOUNCE); s.body:setFriction(P.FRICTION)
  local b = { obj = s, body = s.body, live = false }
  balls[i] = b
  b.parkX = PARK[1] - i * 10
  place(b, b.parkX, YTOP + 40)
  b.body:setLinearFactor(btVector3(0, 0, 0))
  idle[#idle + 1] = b
end

local out = os.getenv("SP_PATHS")
local LOG = os.getenv("SP_LOG")
local fh = out and io.open(out, "a")
local done, stuck, t, nextFeed = 0, 0, 0, 0
local fed = 0
local function park(b)
  b.live = false
  place(b, b.parkX, YTOP + 40)
  b.body:setLinearFactor(btVector3(0, 0, 0))
  idle[#idle + 1] = b
end
local function feed()
  local b = table.remove(idle)
  if not b then return end
  b.body:setLinearFactor(btVector3(1, 1, 1))
  place(b, (math.random() * 2 - 1) * P.JITTER, P.FOOT + FEED_L - 4)
  b.live, b.t0, b.u, b.py, b.px = true, t, {}, nil, nil
  fed = fed + 1
end
local function track(b)
  local p = b.body:getCenterOfMassPosition()
  local x, y = (p.x - BASE.x) / MM, (p.y - BASE.y) / MM
  local n = #b.u
  if b.py and n < P.ROWS then
    local L = levelY(n)
    if b.py >= L and y < L then
      local f = (b.py - L) / (b.py - y)
      b.u[n + 1] = 2 * (b.px + (x - b.px) * f) / P.S
    end
  end
  if LOG and n >= 1 and n < P.ROWS and b.py then
    local F = rowY(n) + P.FOOT
    if b.py >= F and y < F then
      local dir = n == 1 and (b.u[1] > 0 and 1 or -1) or (b.u[n] > b.u[n - 1] and 1 or -1)
      local vx = b.body:getLinearVelocity().x * 10
      print(string.format("FOOT %d %d %.3f %.1f", n, dir, x - b.u[n] * P.S / 2, vx))
    end
  end
  b.px, b.py = x, y
  if #b.u == P.ROWS then
    if fh then
      local s = {}
      for k = 1, P.ROWS do s[k] = string.format("%.3f", b.u[k]) end
      fh:write(table.concat(s, " "), "\n"); fh:flush()
    end
    done = done + 1
    park(b)
  elseif t - b.t0 > 12 or y < YBOT then
    stuck = stuck + 1
    print(string.format("SPLITTER: a ball stopped at x %.1f, y %.1f (row %d) after %.0f s", x, y, n, t - b.t0))
    park(b)
  end
end

print(string.format("SPLITTER TEST: pitch %.1f, pins %.1f, necks %.1f wide and %.1f long, sides %.0f deg, row to row %.1f mm, %d rows (%d teeth), bounce %.2f, friction %.2f",
  P.S, P.PIN_D, P.NECK_W, P.NECK_L, P.SLOPE, V, P.ROWS, nTeeth, P.BOUNCE, P.FRICTION))
local reported = false
v:preSim(function(N)
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)
v:postSim(function(N)
  t = t + 1 / 60
  if fed < P.NBALLS and t >= nextFeed then feed(); nextFeed = t + P.EVERY end
  for _, b in ipairs(balls) do if b.live then track(b) end end
  if not reported and done + stuck >= P.NBALLS then
    reported = true
    print(string.format("SPLITTER DONE: %d balls through, %d stopped, %.0f s", done, stuck, t))
  end
end)
