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
-- can be set from the environment (SP_<NAME>); also mixing chambers
-- (SP_CHAMBERS) and leaning necks (SP_SHEAR, SP_LAND, SP_ALT), both tried
-- and set aside, fixed-height teeth (SP_TOTAL), swallowing walls
-- (SP_WALL_L, SP_WALL_R, SP_CAUGHT) and reflecting walls (SP_REFL_L,
-- SP_REFL_R); walls.py compares both with the exact counts: SPLITTERS.md.
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
-- fixed-height teeth (SP_TOTAL, mm from a pin's centre to its necks' foot):
-- the slope takes what the neck leaves, so every variant fits the same
-- rows. 29.05 is the 60-degree, 10 mm tooth's.
P.TOTAL = envnum("SP_TOTAL", 0)
if P.TOTAL > 0 then
  H = P.TOTAL - P.NECK_L
  assert(H > 2, "splitter-test: the neck is longer than the tooth")
  P.SLOPE = math.deg(math.atan(H / HW))
end
assert(HW > 1, "splitter-test: the necks are wider than the pitch allows")
-- mixing chambers in each neck (SP_CHAMBERS, 0 for none): the neck widens
-- at 45 degrees to CHAMBER_W around a post on its centre line, runs
-- CHAMBER_L, and narrows at 45 degrees again; NECK_L of plain neck above,
-- between and below them. Mirror-symmetric, so they cannot favour a side.
P.CHAMBERS = envnum("SP_CHAMBERS", 0)
P.CHAMBER_W = envnum("SP_CHAMBER_W", 17)
P.CHAMBER_L = envnum("SP_CHAMBER_L", 8)
P.POST_D = envnum("SP_POST_D", 4)
local E = (P.CHAMBER_W - P.NECK_W) / 2            -- how far a chamber widens each side
assert(P.CHAMBERS == 0 or (E > 0 and E < HW - 1), "splitter-test: the chambers do not fit")
-- a tooth's half-width, down from its pin's centre: { depth, half-width }
local profile = { { 0, 0 }, { H, HW } }
do
  local d = H
  for c = 1, P.CHAMBERS do
    d = d + P.NECK_L; profile[#profile + 1] = { d, HW }
    d = d + E; profile[#profile + 1] = { d, HW - E }
    d = d + P.CHAMBER_L; profile[#profile + 1] = { d, HW - E }
    d = d + E; profile[#profile + 1] = { d, HW }
  end
  d = d + P.NECK_L; profile[#profile + 1] = { d, HW }
end
local NECKS = profile[#profile][1] - H             -- the neck's whole length
local V = H + NECKS + P.FOOT                      -- row to row
local function rowY(r) return -r * V end
local function levelY(r) return rowY(r) - H - 2 end   -- just inside row r's necks
-- leaning necks (SP_SHEAR, degrees from upright; 0 for none): gravity holds
-- a ball on the lower wall, so it leaves the same way whichever side it
-- came in from. The pin below is where it lands: the neck's lean plus
-- SP_LAND mm more. With SP_ALT=1 (the default) the lean changes side row
-- by row, so whatever a row favours, the next favours the other way.
P.SHEAR = envnum("SP_SHEAR", 0)
P.LAND = envnum("SP_LAND", 0)
P.ALT = envnum("SP_ALT", 1)
local TS = math.tan(math.rad(P.SHEAR))
local function lean(r) return (P.ALT == 1 and r % 2 == 1) and -1 or 1 end
local offs = { [0] = 0 }
for r = 0, P.ROWS do offs[r + 1] = offs[r] + (P.SHEAR ~= 0 and lean(r) * (NECKS * TS + P.LAND) or 0) end

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
-- reflecting walls (SP_REFL_L, SP_REFL_R: the places, from the start, of
-- the outermost place a ball can reach; 0 for none). A ball at that place
-- is sent back: in place of the tooth there is a half tooth, a solid whose
-- top is the tooth's inner slope run on up to the neck's foot above, so a
-- ball dropping out of the neck lands on it and rolls inward. Beyond it
-- there are no teeth but the next one out, whose inner side is the neck's
-- outer wall: the wall zigzags. SPLITTERS.md, "Reflecting walls".
P.REFL_L, P.REFL_R = envnum("SP_REFL_L", 0), envnum("SP_REFL_R", 0)
assert((P.REFL_L == 0 and P.REFL_R == 0) or (P.CHAMBERS == 0 and P.SHEAR == 0),
  "splitter-test: reflecting walls are for plain teeth")
-- SP_REFL_PIN=0: the plain half tooth, its slope run on up (a ball lands
-- on the slope, not a pin, leaves it fast and turns back to the wall two
-- times in three). SP_REFL_PIN=1 (the default): the half tooth keeps its
-- pin, set SP_REFL_D mm outward, and the neck's outer wall runs on down
-- to it, so a ball always lands on the pin's inner shoulder and rolls off
-- it as a ball going inward off a splitter does.
P.REFL_PIN = envnum("SP_REFL_PIN", 1)
P.REFL_D = envnum("SP_REFL_D", 2.5)
-- SP_REFL_FILL=1 (the default): the wall is solid, as on the board. The
-- outer tooth in the rows between the half teeth keeps only its inner
-- half (no pin), and the wall fills the rest, beside the half teeth too,
-- out to that tooth's outer edge. SP_REFL_FILL=0: the outer tooth whole,
-- on its pin, and the wall beside a half tooth only HW wide.
P.REFL_FILL = envnum("SP_REFL_FILL", 1)
local function reflector(x, y, s)               -- s = -1 a left wall (sends right), +1 a right one
  local pieces
  if P.REFL_PIN == 0 then
    local k = H / HW
    local xs = HW - (H + P.FOOT) / k             -- where the slope meets the neck's foot above
    local xl = math.min(-HW, xs - 1)
    pieces = { { { xl, P.FOOT }, { xs, P.FOOT }, { HW, -H }, { HW, -H - NECKS }, { xl, -H - NECKS } } }
  else
    local d, wx = P.REFL_D, -P.NECK_W / 2         -- the pin's offset; the neck's outer wall
    local k = H / (HW + d)
    pieces = {
      { { P.REFL_FILL ~= 0 and -HW - P.S / 2 or -HW, P.FOOT }, { wx, P.FOOT }, { wx, -H - NECKS },
        { P.REFL_FILL ~= 0 and -HW - P.S / 2 or -HW, -H - NECKS } },
      { { -d, 0 }, { HW, -H }, { HW, -H - NECKS }, { wx, -H - NECKS }, { wx, (wx + d) * -k } } }
  end
  for _, q in ipairs(pieces) do
    if s > 0 then for _, p in ipairs(q) do p[1] = -p[1] end end
    hull(q, x, y)
  end
  if P.REFL_PIN ~= 0 then
    add(btCylinderShapeZ(btVector3(P.PIN_D / 2 * MM, P.PIN_D / 2 * MM, P.GAP / 2 * MM)), x + s * P.REFL_D, y, zc)
  end
end
local nTeeth, nRefl, nFill = 0, 0, 0
for r = 0, P.ROWS - 1 do
  local y = rowY(r)
  for j = -P.ROWS, P.ROWS do
    local x0 = (j + (r % 2) / 2) * P.S
    local x = x0 + offs[r]
    local sh = lean(r) * TS
    local u = 2 * j + r % 2                       -- the tooth's place
    -- (a half tooth only where a ball can reach the wall: above that the
    -- tooth stays whole, as the outer wall of the neck beside it; left out,
    -- balls left that neck still moving outward, and all went on to the wall)
    if ((P.REFL_L > 0 and u == -P.REFL_L) or (P.REFL_R > 0 and u == P.REFL_R)) and math.abs(u) <= r then
      reflector(x, y, u < 0 and -1 or 1); nRefl = nRefl + 1
    elseif (P.REFL_L > 0 and u < -P.REFL_L - 1) or (P.REFL_R > 0 and u > P.REFL_R + 1) then
      -- (beyond the wall: nothing)
    elseif P.REFL_FILL ~= 0 and ((P.REFL_L > 0 and u == -P.REFL_L - 1) or (P.REFL_R > 0 and u == P.REFL_R + 1))
           and math.abs(x0) <= (r / 2 + 1) * P.S then
      -- (the outer tooth: its inner half, and the wall outward of its top)
      local s = u < 0 and -1 or 1
      for _, q in ipairs({ { { 0, 0 }, { HW, -H }, { HW, -H - NECKS }, { 0, -H - NECKS } },
                           { { -HW, P.FOOT }, { 0, P.FOOT }, { 0, -H - NECKS }, { -HW, -H - NECKS } } }) do
        for _, p in ipairs(q) do p[1] = -s * p[1] end
        hull(q, x, y)
      end
      nTeeth, nFill = nTeeth + 1, nFill + 1
    elseif math.abs(x0) <= (r / 2 + 1) * P.S then -- the triangle the balls can reach, and one more each side
      add(btCylinderShapeZ(btVector3(P.PIN_D / 2 * MM, P.PIN_D / 2 * MM, P.GAP / 2 * MM)), x, y, zc)
      if P.CHAMBERS == 0 and P.SHEAR == 0 and not os.getenv("SP_SLICED") then
        -- one pentagon. (Built from two slices instead, with a seam at the neck's
        -- mouth, the memory moves from -0.01 to +0.12: SPLITTERS.md.)
        hull({ { 0, 0 }, { HW, -H }, { HW, -H - NECKS }, { -HW, -H - NECKS }, { -HW, -H } }, x, y)
      else for k = 1, #profile - 1 do                -- (a tooth from convex slices)
        local a, b = profile[k], profile[k + 1]
        local sa, sb = sh * math.max(0, a[1] - H), sh * math.max(0, b[1] - H)
        hull({ { -a[2] + sa, -a[1] }, { a[2] + sa, -a[1] }, { b[2] + sb, -b[1] }, { -b[2] + sb, -b[1] } }, x, y)
      end end
      local d = H
      for c = 1, P.CHAMBERS do                  -- the posts, in the necks to this tooth's right
        d = d + P.NECK_L + E
        add(btCylinderShapeZ(btVector3(P.POST_D / 2 * MM, P.POST_D / 2 * MM, P.GAP / 2 * MM)), x + P.S / 2, y - d - P.CHAMBER_L / 2, zc)
        d = d + P.CHAMBER_L + E
      end
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

-- swallowing walls (SP_WALL_L, SP_WALL_R: places from the start, 0 for
-- none): a ball reaching that column drops out (on a board, through a hole
-- in the neck into its tube). The row it was caught at goes to SP_CAUGHT.
P.WALL_L, P.WALL_R = envnum("SP_WALL_L", 0), envnum("SP_WALL_R", 0)
local caughtFile = os.getenv("SP_CAUGHT")
local ch = caughtFile and io.open(caughtFile, "a")
local caught = 0
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
      b.u[n + 1] = 2 * (b.px + (x - b.px) * f - offs[n]) / P.S
      local place = math.floor(b.u[n + 1] + 0.5)
      if (P.WALL_L > 0 and place <= -P.WALL_L) or (P.WALL_R > 0 and place >= P.WALL_R) then
        if ch then ch:write(string.format("%d %d\n", n + 1, place < 0 and -1 or 1)); ch:flush() end
        caught = caught + 1
        done = done + 1
        b.px, b.py = x, y
        park(b)
        return
      end
    end
  end
  if LOG and n >= 1 and n < P.ROWS and b.py then
    local F = rowY(n) + P.FOOT
    if b.py >= F and y < F then
      local dir = n == 1 and (b.u[1] > 0 and 1 or -1) or (b.u[n] > b.u[n - 1] and 1 or -1)
      local vx = b.body:getLinearVelocity().x * 10
      local fx = b.u[n] * P.S / 2 + offs[n - 1] + lean(n - 1) * NECKS * TS
      print(string.format("FOOT %d %d %.3f %.1f %d", n, dir, x - fx, vx, lean(n - 1)))
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

print(string.format("SPLITTER TEST: pitch %.1f, pins %.1f, necks %.1f wide and %.1f long, sides %.0f deg, %d chambers (%.1f wide, %.1f long, post %.1f), lean %.0f deg (%s), landing +%.1f, row to row %.1f mm, %d rows (%d teeth, %d half teeth, %d outer teeth halved; %d pieces), bounce %.2f, friction %.2f",
  P.S, P.PIN_D, P.NECK_W, NECKS, P.SLOPE, P.CHAMBERS, P.CHAMBER_W, P.CHAMBER_L, P.POST_D, P.SHEAR, P.ALT == 1 and "alternating" or "all one way", P.LAND, V, P.ROWS, nTeeth, nRefl, nFill, #items, P.BOUNCE, P.FRICTION))
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
    print(string.format("SPLITTER DONE: %d balls through (%d caught by the walls), %d stopped, %.0f s", done, caught, stuck, t))
  end
end)
