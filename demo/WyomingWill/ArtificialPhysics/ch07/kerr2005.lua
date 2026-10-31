--
-- ch07/kerr2005.lua -- Kerr's 2005 robot simulator (ch07/kerr2005/, the code
-- behind the corridor sweep of his thesis and the book's Ch. 7.10-7.12,
-- Figs. 7.11-7.13) as plain Lua, operation for operation: the world, the
-- sensors and the three controllers the book compares, KT (KTRobot), Ant
-- (AntRobot) and Default (Simple2)
--
-- His Java computes in floats wherever it declares floats; this port rounds
-- every such operation to the nearest float (f32 below), so a run from a
-- seed repeats his run step for step (checks/ch07.lua, against
-- ch07/kerr2005_reference.txt from his Java). His random numbers are
-- java.util.Random's (48-bit LCG), done here in exact arithmetic. Under
-- LuaJIT the float rounding is a cast through its FFI, which it compiles:
-- the same results, about 7 times faster than Lua 5.1 (ch07/README.md).
-- Java's Math.cos, sin and log (HotSpot's) and atan2 and acos (fdlibm) can
-- differ from the C library's in the last bit of a double; where that bit
-- survives (cos and sin move the positions, which are doubles) a run can
-- differ from his in the last bits (within 1e-12 over the whole runs
-- compared, with the same results; FINDINGS F98). Math.toRadians and toDegrees are JDK 9+'s (one
-- multiplication by a constant), the JDK the reference was run on.
--
-- THE WORLD (env/Environment.java): a corridor W x H = 1000" x 5000" (x
-- across, y along it toward the goal at y = H); robots 6" across, positions
-- (x, y) in doubles, bearings in degrees (doubles, counterclockwise from +x,
-- kept in [-360, 360]). Robots start on a square grid 40" apart from
-- (10, 10), bearings U(0, 360). One step: 100 random swaps of the move
-- order (the world's Random), then each robot in that order senses (seeing
-- the robots that have already moved), turns by `turn` degrees and moves
-- `distance` along its new bearing; a robot outside the corridor is put back
-- 3" inside. Messages are cleared after the step. The run ends when every
-- robot is done (10 steps in a row within 2 x 60" of the goal end, then it
-- stops) or at 150,000 steps.
-- Obstacles: his course files (data/course_P_k.txt), rectangles "0 x1 y1
-- x2 y2" (his circles and triangles are in no course and are not ported).
-- Coverage (env/Coverage.java): a 50 x 250 grid of 20" cells; cells whose
-- centre is inside an obstacle are not counted; the "behind" (shadow) cells
-- are the row just past each obstacle's far edge (toward the goal), not
-- inside another obstacle. A cell is covered when a robot's centre is in it
-- after a move (or at the start).
-- SENSORS (sensor/): goal bearing 90 - bearing; a ring of 24 sonars every
-- 15 degrees from the heading, range 60", each a ray from the robot's rim
-- against the other robots (circles of 3"), less 3" (the rim), and from the
-- centre against the corridor's walls and the obstacles (rectangles), less
-- 3" on an obstacle; the localisation (RodSensor): every robot within 60"
-- (centre to centre, through obstacles), distance less 3" and bearing in the
-- robot's frame; the messages (CommunicationSensor). Every move goes the
-- safe distance along the chosen heading: 6" if the sonar there reads more
-- than 6", else the reading less 3" (not below 0).
-- KT (robot/KTRobot.java; book Listings 7.1-7.3): velocity (distance, 0) in
-- its own frame; if no robot within 15" lies ahead (0-45 or 315-360
-- degrees), a wall collision when sonar 0 < 15" or sonar 6 or 18 (90, 270
-- degrees) < 2": a new velocity, Rayleigh mpv sqrt(-ln U) away from the
-- wall and N(0, stdev) along it, plus wall = 0.4 toward the goal if the
-- wall is judged parallel to the goal (within 45 degrees); then every robot
-- within 15" (not ignored, not met in the last 5 steps from behind) is
-- collided as Listing 7.3 (cos th = 1 - 2U, sin th = +sqrt(1 - cos^2), the
-- two results assigned so the paths do not cross) and told its new
-- velocity; one told already adds what it was told. The heading is the
-- velocity's; the speed is always the safe distance (6" when clear: the
-- velocity's size is not used). A robot that has not moved for 5 steps
-- turns to U(0, 360). mpv 1.11777, stdev 0.79038 (T = 0.0030).
-- Ant (robot/AntRobot.java): every third step it heads to the one of the
-- four neighbouring cells (goal, left, back, right) with the least
-- pheromone (the last of equals), else straight on; it adds 1 to its own
-- cell's count every step (node counting; Trails.java). Obstacle cells
-- count 2^31 - 1.
-- Default (robot/Simple2.java): eight headings 45 degrees apart from the
-- goal's, open if the sonar that way reads more than 18"; weights: 0.8 to
-- straight on if open; a third of the rest to each "shadow" move (90 degrees
-- left or right when the move 45 degrees beyond it is blocked and no robot
-- within 18" is there); half of what is left to the goal heading if open;
-- the rest evenly over the open headings. Drawn with nextDouble (the last
-- interval holding the draw wins).
--
-- o.fix (ours; all off by default, which is Kerr's code), each correcting
-- one thing his code does that the book does not say (FINDINGS F98):
--   seeds     each robot its own random numbers: KT and Ant seeded with
--             seed + id, as Default is (his KT and Ant robots are all made
--             in the same millisecond, so they share one sequence)
--   messages  a told robot reads the velocity it was told (his
--             CommunicationSensor stores the sender's bearing over the
--             velocity's angle and leaves the bearing 0)
--   wallfit   the wall's line from the leftmost and rightmost sonars
--             within +-45 degrees that see something within 15" (PDF 232;
--             his code takes the first sonars that see anything, any way
--             round the ring, at angles 45 - 15 i and -45 + 15 (23 - i))
--
-- DEFINITIONS (fields; inches, degrees, steps):
--   w.x[i], w.y[i], w.b[i]  position and bearing of robot i = 0..n-1
--   w.time                  steps taken
--   w.covered, w.cells      cells covered, cells not inside obstacles
--   w.behindCovered, w.behindCells  the same for the shadow cells
--   R.result(w)             { total = 100 covered/cells (%), behind = 100
--                           behindCovered/behindCells (%, 0 if none),
--                           time = steps }
--   R.line(res, o)          his log line: CONTROLLER Speed 0.4 N n Pct p
--                           Course k Run r Behind % Total % Time steps
--

local R = {}
local floor, ceil, sqrt, log, cos, sin, acos = math.floor, math.ceil, math.sqrt, math.log, math.cos, math.sin, math.acos
local atan2 = math.atan2 or math.atan -- Lua 5.3+: math.atan(y, x)
local huge = math.huge

-- f32(x): x rounded to the nearest float (ties to even), Java's (float)
local f32
local hasffi, ffi = pcall(require, "ffi") -- LuaJIT: a float cast it compiles
if jit and hasffi then
  local box = ffi.new("float[1]")
  f32 = function(x) box[0] = x; return box[0] end
elseif string.pack then
  local pack, unpack = string.pack, string.unpack
  f32 = function(x) return (unpack("f", pack("f", x))) end
else
  local frexp, ldexp = math.frexp, math.ldexp
  f32 = function(x)
    if x == 0 or x ~= x or x == huge or x == -huge then return x end
    local m, e = frexp(x)
    local s
    if e < -125 then s = x * 2 ^ 149 else s = m * 16777216 end
    local r = floor(s + 0.5)
    if r - s == 0.5 and r % 2 ~= 0 then r = r - 1 end
    if e < -125 then return r * 2 ^ -149 end
    if e > 128 or (e == 128 and r >= 16777216) then return x > 0 and huge or -huge end
    return ldexp(r, e - 24)
  end
end
local F = f32

local D2R, R2D = 0.017453292519943295, 57.29577951308232 -- JDK 9+ toRadians, toDegrees
local function int(x) if x >= 0 then return floor(x) else return ceil(x) end end
local function round(x) return floor(x + 0.5) end -- Java's Math.round(float), exact for floats
local INT_MAX = 2147483647

-- java.util.Random: seed (48 bits) as two 24-bit halves
local T24, T31 = 16777216, 2147483648
local MLO, MHI = 0xECE66D, 0x5DE -- 0x5DEECE66D
local function xor24(a, b)
  local r, p = 0, 1
  for _ = 1, 24 do
    local x, y = a % 2, b % 2
    if x ~= y then r = r + p end
    a, b, p = (a - x) / 2, (b - y) / 2, p * 2
  end
  return r
end
local function jrandom(seed)
  seed = seed % (T24 * T24)
  local lo = seed % T24
  local hi = (seed - lo) / T24
  return { lo = xor24(lo, MLO), hi = xor24(hi, MHI) }
end
local function nextBits(g, bits)
  local lo, hi = g.lo, g.hi
  local p = lo * MLO + 0xB
  local nlo = p % T24
  local nhi = (hi * MLO + lo * MHI + (p - nlo) / T24) % T24
  g.lo, g.hi = nlo, nhi
  return floor((nhi * T24 + nlo) / 2 ^ (48 - bits))
end
local function nextFloat(g) return nextBits(g, 24) / T24 end
local function nextDouble(g) return (nextBits(g, 26) * 134217728 + nextBits(g, 27)) / 9007199254740992 end
local function nextInt(g, bound)
  local r, m = nextBits(g, 31), bound - 1
  local p2 = 1
  while p2 < bound do p2 = p2 * 2 end
  if p2 == bound then return floor(bound * r / T31) end -- a power of two
  local u = r
  while true do
    r = u % bound
    if u - r + m < T31 then return r end
    u = nextBits(g, 31)
  end
end

local SMAX = 60 -- SonarSensor.max, RodSensor.max
local VMAX, VMAX2 = 6, 12
local MPV, STDEV, SAFE = F(1.11777), F(0.79038), 15

-- math/Intersection.java
local function circleIntersect(x1, y1, x2, y2, cx, cy, rad)
  local dx, dy = F(x2 - x1), F(y2 - y1)
  local a = F(F(dx * dx) + F(dy * dy))
  local b = 2 * F(F(dx * F(x1 - cx)) + F(dy * F(y1 - cy)))
  local c = F(F(F(F(F(F(cx * cx) + F(cy * cy)) + F(x1 * x1)) + F(y1 * y1)) - 2 * F(F(cx * x1) + F(cy * y1))) - F(rad * rad))
  local mid = F(F(b * b) - F(4 * a * c))
  if mid < 0 then return SMAX end
  local sq = F(sqrt(mid))
  local u1 = F(F(-b + sq) / (2 * a))
  local u2 = F(F(-b - sq) / (2 * a))
  if (u1 < 0 or u1 > 1) and (u2 < 0 or u2 > 1) then return SMAX end
  local u
  if u1 > 0 and u1 < 1 and u2 > 0 and u2 < 1 then
    if u1 < u2 then u = u1 else u = u2 end
  elseif u1 > 0 and u1 < 1 then u = u1
  else u = u2 end
  local ix = F(x1 + F(u * dx))
  local iy = F(y1 + F(u * dy))
  local ex, ey = F(ix - x1), F(iy - y1)
  return F(sqrt(F(F(ex * ex) + F(ey * ey))))
end
local function lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
  local ax, ay, bx, by = F(x2 - x1), F(y2 - y1), F(x4 - x3), F(y4 - y3)
  local denom = F(F(by * ax) - F(bx * ay))
  if denom == 0 then return SMAX end
  local cx, cy = F(x1 - x3), F(y1 - y3)
  local ua = F(F(F(bx * cy) - F(by * cx)) / denom)
  local ub = F(F(F(ax * cy) - F(ay * cx)) / denom)
  if ua <= 1 and ua >= 0 and ub <= 1 and ub >= 0 then
    local ex, ey = F(F(x1 + F(ua * ax)) - x1), F(F(y1 + F(ua * ay)) - y1)
    return F(sqrt(ex * ex + ey * ey))
  end
  return SMAX
end
local function doLinesIntersect(x1, y1, x2, y2, x3, y3, x4, y4) -- floats in, float numerators, double ua
  local ax, ay, bx, by = F(x2 - x1), F(y2 - y1), F(x4 - x3), F(y4 - y3)
  local denom = F(F(by * ax) - F(bx * ay))
  if denom == 0 then return false end
  local cx, cy = F(x1 - x3), F(y1 - y3)
  local ua = F(F(bx * cy) - F(by * cx)) / denom
  local ub = F(F(ax * cy) - F(ay * cx)) / denom
  return ua <= 1 and ua >= 0 and ub <= 1 and ub >= 0
end
local function intersectionPoint(x1, y1, x2, y2, x3, y3, x4, y4) -- doubles; nil if parallel
  local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
  if denom == 0 then return nil end
  local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
  return F(x1 + ua * (x2 - x1)), F(y1 + ua * (y2 - y1))
end

-- obstacle/Square.java: the four sides in his order
local function squareIntersect(o, px1, py1, px2, py2)
  local d = SMAX
  local e = lineIntersect(px1, py1, px2, py2, o[1], o[2], o[3], o[2]); if e < d then d = e end
  e = lineIntersect(px1, py1, px2, py2, o[1], o[2], o[1], o[4]); if e < d then d = e end
  e = lineIntersect(px1, py1, px2, py2, o[3], o[2], o[3], o[4]); if e < d then d = e end
  e = lineIntersect(px1, py1, px2, py2, o[1], o[4], o[3], o[4]); if e < d then d = e end
  return d
end

function R.loadCourse(path)
  local list = {}
  for line in io.lines(path) do
    local w = {}
    for t in line:gmatch("%S+") do w[#w + 1] = t end
    if #w > 0 then
      if w[1] ~= "0" then error("kerr2005: only rectangles are ported: " .. line) end
      local x1, y1, x2, y2 = F(tonumber(w[2])), F(tonumber(w[3])), F(tonumber(w[4])), F(tonumber(w[5]))
      if x2 < x1 then x1, x2 = x2, x1 end
      if y2 < y1 then y1, y2 = y2, y1 end
      list[#list + 1] = { x1, y1, x2, y2 }
    end
  end
  return list
end

-- Sensing near one robot. Exact shortcuts (they change no result): a
-- robot, obstacle or wall farther than a sonar can reach (63" from the
-- centre, plus a margin far beyond float error) returns the sonar's maximum
-- in his code, so it is left out of the loops; the order of the rest is his.
local REACH = 80
local function gather(w, id)
  local x, y = w.x[id], w.y[id]
  local rb, ob = w.nearR, w.nearO
  local nr, no = 0, 0
  for i = 0, w.n - 1 do
    if i ~= id then
      local dx, dy = w.x[i] - x, w.y[i] - y
      if dx < REACH and dx > -REACH and dy < REACH and dy > -REACH then nr = nr + 1; rb[nr] = i end
    end
  end
  local obs = w.obs
  for k = 1, #obs do
    local o = obs[k]
    if x > o[1] - REACH and x < o[3] + REACH and y > o[2] - REACH and y < o[4] + REACH then no = no + 1; ob[no] = o end
  end
  w.nr, w.no = nr, no
  w.wall1 = y < REACH                 -- (0,0)-(W,0)
  w.wall2 = x < REACH                 -- (0,0)-(0,H)
  w.wall3 = x > w.width - REACH       -- (W,H)-(W,0)
  w.wall4 = y > w.height - REACH      -- (W,H)-(0,H)
end

-- one sonar ray at `angle` degrees from robot id's heading (SonarSensor's
-- sonar() and fireSonar() alike); gather(w, id) first
local function ray(w, id, angle)
  local best = SMAX
  local sb = angle + w.b[id]
  local c, s = F(cos(sb * D2R)), F(sin(sb * D2R))
  local px, py = F(w.x[id]), F(w.y[id])
  local c60, s60 = F(SMAX * c), F(SMAX * s)
  local x1, y1 = F(px + F(3 * c)), F(py + F(3 * s))
  local x2, y2 = F(c60 + x1), F(s60 + y1)
  local rb = w.nearR
  for k = 1, w.nr do
    local i = rb[k]
    local d = circleIntersect(x1, y1, x2, y2, F(w.x[i]), F(w.y[i]), 3)
    if d ~= SMAX then d = F(d - 3) end
    if d < best then best = d end
  end
  x1, y1 = px, py
  x2, y2 = F(c60 + x1), F(s60 + y1)
  local W, H = w.width, w.height
  local d
  if w.wall1 then d = lineIntersect(x1, y1, x2, y2, 0, 0, W, 0); if d < best then best = d end end
  if w.wall2 then d = lineIntersect(x1, y1, x2, y2, 0, 0, 0, H); if d < best then best = d end end
  if w.wall3 then d = lineIntersect(x1, y1, x2, y2, W, H, W, 0); if d < best then best = d end end
  if w.wall4 then d = lineIntersect(x1, y1, x2, y2, W, H, 0, H); if d < best then best = d end end
  local ob = w.nearO
  for k = 1, w.no do
    d = squareIntersect(ob[k], x1, y1, x2, y2)
    if d ~= SMAX then d = F(d - 3) end
    if d < best then best = d end
  end
  if best < 0 then best = 0 end
  return best
end

local function sonarRing(w, id, out)
  for k = 0, 23 do out[k] = ray(w, id, 15 * k) end
  return out
end

-- Robot.determineSafeDistance (after SonarSensor.findSensorReading)
local function safeDistance(w, id, turn)
  if turn < 0 then turn = F(turn + 360) end
  local d = ray(w, id, turn)
  if d < VMAX2 and d > VMAX then return VMAX
  elseif d <= VMAX then return math.max(F(d - 3), 0)
  else return VMAX end
end

-- RodSensor.findVisibleRobots: ids, bearings, distances (nil if none)
local function rod(w, id)
  local x, y, b = w.x[id], w.y[id], w.b[id]
  local ids, th, ds, n = nil, nil, nil, 0
  for i = 0, w.n - 1 do
    if i ~= id then
      local dx, dy = w.x[i] - x, w.y[i] - y
      local dist = F(sqrt(dx * dx + dy * dy))
      if dist < SMAX then
        if not ids then ids, th, ds = {}, {}, {} end
        n = n + 1
        ids[n] = i
        th[n] = F(atan2(dy, dx) * R2D - b)
        ds[n] = F(dist - 3)
      end
    end
  end
  return ids, th, ds, n
end

local function goalBearing(w, id) return F(90.0 - w.b[id]) end
local function nearGoal(w, id) return w.y[id] >= w.height - 2 * SMAX end

-- the goal timer every controller runs (its own copy of Robot's)
local function goalTimer(w, id, r)
  local near = nearGoal(w, id)
  if near and not r.startTimer then r.startTimer = true; r.timer = 0
  elseif near and r.startTimer then r.timer = r.timer + 1
  elseif not near and r.startTimer then r.startTimer = false end
  return r.timer >= 10 and near
end

local function randn(g)
  local a = sqrt(-2.0 * log(1.0 - nextDouble(g)))
  return a * cos(6.283185307 * nextDouble(g))
end

----------------------------------------------------------------------------
-- KT (robot/KTRobot.java)
local KT = {}
function KT.new(w, id)
  local seed = w.seed
  if w.fix.seeds then seed = seed + id end
  local r = { id = id, rand = jrandom(seed), speed = VMAX, distance = VMAX, turn = 0, vx = 0, vy = 0,
              timer = 0, startTimer = false, stuckTimer = 0, stuck = false, done = false,
              col = {}, timeCounter = {}, sonar = {} }
  for i = 0, w.n - 1 do r.col[i] = false; r.timeCounter[i] = 0 end
  return r
end

local function collisionParallel(w, ds, goal)
  local w1x, w1y, w2x, w2y = 0, 0, 0, 0
  if w.fix.wallfit then
    -- leftmost and rightmost sonars within +-45 degrees seeing < 15"
    for k = 3, -3, -1 do
      local i = k % 24
      if ds[i] < SAFE then w1x, w1y = F(ds[i] * cos(15 * k * D2R)), F(ds[i] * sin(15 * k * D2R)); break end
    end
    for k = -3, 3 do
      local i = k % 24
      if ds[i] < SAFE then w2x, w2y = F(ds[i] * cos(15 * k * D2R)), F(ds[i] * sin(15 * k * D2R)); break end
    end
  else
    local theta = 45
    for i = 0, 23 do
      if ds[i] ~= SMAX then
        w1x, w1y = F(ds[i] * cos(theta * D2R)), F(ds[i] * sin(theta * D2R))
        break
      end
      theta = theta - 15
    end
    theta = -45
    for i = 23, 0, -1 do
      if ds[i] ~= SMAX then
        w2x, w2y = F(ds[i] * cos(theta * D2R)), F(ds[i] * sin(theta * D2R))
        break
      end
      theta = theta + 15
    end
  end
  local px, py = F(20.0 * cos(goal * D2R)), F(20.0 * sin(goal * D2R))
  local ix, iy = intersectionPoint(w1x, w1y, w2x, w2y, 0, 0, px, py)
  if not ix then return 0 end
  local a2 = F(F(w1x * w1x) + F(w1y * w1y))
  local b2 = F(F(ix * ix) + F(iy * iy))
  local ex, ey = F(w1x - ix), F(w1y - iy)
  local c2 = F(F(ex * ex) + F(ey * ey))
  local top = F(F(b2 + c2) - a2)
  local bottom = F(2.0 * sqrt(b2) * sqrt(c2))
  local frac = F(top / bottom)
  return F(acos(frac) * R2D)
end

local function ktWalls(w, r, goal, ds)
  if ds[0] < SAFE or ds[6] < 2 or ds[18] < 2 then
    local thetac = collisionParallel(w, ds, goal)
    local parallel = (thetac < 45 and thetac > -45) or (thetac > 135 and thetac < 225)
    local dir = 1
    if ds[6] < ds[18] then dir = -1 end
    local g = r.rand
    local ivx = F(F(sqrt(-log(1.0 - nextDouble(g)))) * MPV) -- (float) Math.sqrt(...) * mpv
    local ivy = F(randn(g) * STDEV)
    local d = F(sqrt(F(F(ivx * ivx) + F(ivy * ivy))))
    local theta = F(atan2(ivy, ivx) * R2D)
    local alpha = F(F(goal - 90) + theta)
    local vx, vy = F(d * cos(alpha * D2R)), F(d * sin(alpha * D2R))
    if vx > 0 then vx = -vx end
    if (vy > 0 and dir == -1) or (vy < 0 and dir ~= -1) then vy = -vy end
    if parallel then
      vx = F(vx + F(cos(goal * D2R) * w.wall))
      vy = F(vy + F(sin(goal * D2R) * w.wall))
    end
    r.vx, r.vy = vx, vy
  end
end

local function ktRobots(w, r, ids, bs, ds, n)
  if not ids then return end
  local id = r.id
  local inbox = w.msg[id]
  local ignore = w.ignoring[id]
  local col, tc = r.col, r.timeCounter
  for k = 1, n do
    local cid = ids[k]
    if ds[k] <= SAFE and not ignore[cid] then
      if col[cid] and tc[cid] < 5 and bs[k] > 45 and bs[k] < 315 then
        ignore[cid] = true; w.ignoring[cid][id] = true
      elseif inbox[cid] then
        local m = inbox[cid]
        local newSpeed, angle, rev
        if w.fix.messages then newSpeed, angle, rev = m[1], m[2], m[3]
        else newSpeed, angle, rev = m[1], m[3], 0 end
        local alpha = F(F(180 + bs[k]) - rev)
        local a = F(alpha + angle) * D2R
        r.vx = F(r.vx + newSpeed * cos(a))
        r.vy = F(r.vy + newSpeed * sin(a))
        col[cid] = true; tc[cid] = 0
      else
        local cbtm = F(atan2(w.y[cid] - w.y[id], w.x[cid] - w.x[id]) * R2D - w.b[cid]) -- getReverseBearning
        local cspeed = w.robots[cid].speed
        local thetar = F(F(180 + bs[k]) - cbtm)
        local cvx = F(cspeed * F(cos(thetar * D2R)))
        local cvy = F(cspeed * F(sin(thetar * D2R)))
        local speed = r.speed
        local ex = F(cvx - speed)
        local rel = F(sqrt(F(F(ex * ex) + F(cvy * cvy))))
        local cmx, cmy = F(0.5 * F(cvx + speed)), F(0.5 * cvy)
        local cth = F(1 - 2 * nextFloat(r.rand))
        local sth = F(sqrt(1.0 - F(cth * cth)))
        local relx, rely = F(rel * cth), F(rel * sth)
        local p1x, p1y = F(cmx + F(0.5 * relx)), F(cmy + F(0.5 * rely))
        local p2x, p2y = F(cmx - F(0.5 * relx)), F(cmy - F(0.5 * rely))
        local crx = F(ds[k] * cos(bs[k] * D2R))
        local cry = F(ds[k] * sin(bs[k] * D2R))
        local ncrx, ncry = F(crx + p2x), F(cry + p2y)
        local myx, myy, ncx, ncy = p1x, p1y, p2x, p2y
        if doLinesIntersect(0, 0, p1x, p1y, crx, cry, ncrx, ncry) then
          myx, myy, ncx, ncy = p2x, p2y, p1x, p1y
        end
        r.vx = F(r.vx + myx)
        r.vy = F(r.vy + myy)
        local ns = F(sqrt(F(F(ncx * ncx) + F(ncy * ncy))))
        local nt = F(atan2(ncy, ncx) * R2D)
        w.msg[cid][id] = { ns, nt, bs[k] }
        col[cid] = true; tc[cid] = 0
      end
    end
  end
end

function KT.move(w, r)
  local id = r.id
  r.speed = r.distance
  r.vx, r.vy = r.distance, 0
  for i = 0, w.n - 1 do if r.col[i] then r.timeCounter[i] = r.timeCounter[i] + 1 end end
  local goal = goalBearing(w, id)
  if goalTimer(w, id, r) then r.done = true; r.turn = 0; r.distance = 0; return end
  local ids, bs, ds, n = rod(w, id)
  gather(w, id)
  local sonar = sonarRing(w, id, r.sonar)
  local walls = true
  if ids then
    for k = 1, n do
      local b = bs[k]
      if b < 0 then b = F(b + 360) end
      if ((b < 45 and b > 0) or (b > 315 and b < 360)) and ds[k] < SAFE then walls = false end
    end
  end
  if walls then ktWalls(w, r, goal, sonar) end
  ktRobots(w, r, ids, bs, ds, n)
  r.turn = F(atan2(r.vy, r.vx) * R2D)
  r.distance = safeDistance(w, id, r.turn)
  r.speed = r.distance
  if r.stuck and r.distance < 0.0001 then
    r.stuckTimer = r.stuckTimer + 1
    if r.stuckTimer >= 5 then r.turn = F(nextFloat(r.rand) * 360); r.stuck = false end
    r.distance = safeDistance(w, id, r.turn)
    r.speed = r.distance
  elseif r.distance < 0.0001 then
    r.stuck = true; r.stuckTimer = 0
  end
end

----------------------------------------------------------------------------
-- Ant (robot/AntRobot.java, sensor/TrailSensor.java, env/Trails.java)
local ANT = {}
function ANT.new(w, id)
  local seed = w.seed
  if w.fix.seeds then seed = seed + id end
  return { id = id, rand = jrandom(seed), speed = VMAX, distance = VMAX, turn = 0,
           timer = 0, startTimer = false, stuckTimer = 0, stuck = false, done = false,
           state1 = true, stateTimer = 0 }
end

local function trailCell(w, x, y) return int(x * w.xRatio), int(y * w.yRatio) end
local function getU(w, x, y)
  local cx, cy = trailCell(w, x, y)
  if cx >= w.ncx or cy >= w.ncy or x < 0 or y < 0 then return INT_MAX end
  return w.trail[cy * w.ncx + cx]
end

function ANT.move(w, r)
  local id = r.id
  local goal = goalBearing(w, id)
  if goalTimer(w, id, r) then r.done = true; r.turn = 0; r.distance = 0; return end
  while goal < 0 do goal = F(goal + 360) end
  if r.state1 then
    -- runAlgorithm: the four neighbours' counts, u[0] goal-ward (+y), u[1] -x, u[2] -y, u[3] +x
    local x, y = w.x[id], w.y[id]
    local cx, cy = trailCell(w, x, y)
    local u = { [0] = 0, 0, 0, 0 }
    if not (cx >= w.ncx or cy >= w.ncy or x < 0 or y < 0) then
      local t, nx = w.trail, w.ncx
      u[2] = cy - 1 < 0 and INT_MAX or t[(cy - 1) * nx + cx]
      u[1] = cx - 1 < 0 and INT_MAX or t[cy * nx + cx - 1]
      u[0] = cy + 1 >= w.ncy and INT_MAX or t[(cy + 1) * nx + cx]
      u[3] = cx + 1 >= nx and INT_MAX or t[cy * nx + cx + 1]
    end
    local choice, min = 0, u[0]
    for i = 0, 3 do if u[i] <= min then choice, min = i, u[i] end end
    local a = F(goal + 90 * choice)
    while a < 0 do a = F(a + 360) end
    r.turn = a
    gather(w, id)
    r.distance = safeDistance(w, id, r.turn)
    r.state1 = false
  else
    r.turn = 0
    gather(w, id)
    r.distance = safeDistance(w, id, 0)
    r.stateTimer = r.stateTimer + 1
    if r.stateTimer == 3 then r.stateTimer = 0; r.state1 = true end
  end
  -- node counting: the robot's own cell + 1 (Java's int wraps)
  local x, y = w.x[id], w.y[id]
  local old = getU(w, x, y)
  local cx, cy = trailCell(w, x, y)
  local new = old + 1
  if new > INT_MAX then new = new - 4294967296 end
  local key = cy * w.ncx + cx
  if cx < 0 or cy < 0 or cx >= w.ncx or cy >= w.ncy then error("kerr2005: trail cell out of range (his code throws too)") end
  w.trail[key] = new
  if r.stuck and r.distance < 0.0001 then
    r.stuckTimer = r.stuckTimer + 1
    if r.stuckTimer >= 5 then r.turn = F(nextFloat(r.rand) * 360); r.stuck = false end
    r.distance = safeDistance(w, id, r.turn)
    r.speed = r.distance
  elseif r.distance < 0.0001 then
    r.stuck = true; r.stuckTimer = 0
  end
end

----------------------------------------------------------------------------
-- Default (robot/Simple2.java)
local DEF = {}
function DEF.new(w, id)
  return { id = id, rand = jrandom(w.seed + id), speed = VMAX, distance = VMAX, turn = 0,
           timer = 0, startTimer = false, done = false, sonar = {} }
end

function DEF.move(w, r)
  local id = r.id
  local ids, rbs, rds, n = rod(w, id)
  gather(w, id)
  local ds = sonarRing(w, id, r.sonar)
  local goal = goalBearing(w, id)
  if goalTimer(w, id, r) then r.done = true; r.turn = 0; r.distance = 0; return end
  while goal < 0 do goal = F(goal + 360) end
  -- getOptions
  local options, angle = {}, goal
  for i = 0, 7 do
    local index = round(F(angle / 15))
    if index == 24 then index = 0 end
    options[i] = ds[index] > 18
    angle = F(angle - 45)
    if angle < 0 then angle = F(angle + 360) end
  end
  -- areRobotsBlocking
  local blocked = {}
  if ids then
    for k = 1, n do
      if rds[k] <= 18 then
        local b = rbs[k]
        while b < 0 do b = F(b + 360) end
        rbs[k] = b
        local index = round(F(F(b - goal) / 45))
        if index == 8 then index = 0 end
        if index < 0 then index = index + 8 end
        blocked[index] = true
      end
    end
  end
  -- runAlgorithm: intervals of [0, 1) in his order
  local list, left, min = {}, 1.0, 0
  local function add(i, lo, hi) list[#list + 1] = { i, lo, hi } end
  local previous = round(F(goal / 45))
  if previous == 8 then previous = 0 end
  if options[previous] then add(previous, 0, 0.8); min = 0.8; left = left - 0.8 end
  local split = left / 3.0
  if not options[3] and options[2] and not blocked[3] then add(2, min, min + split); min = min + split; left = left - split end
  if not options[5] and options[6] and not blocked[5] then add(6, min, min + split); min = min + split; left = left - split end
  split = left / 2.0
  if options[0] then add(0, min, min + split); min = min + split; left = left - split end
  local count = 0
  for j = 0, 7 do if options[j] then count = count + 1 end end
  split = left / count
  for j = 0, 7 do
    if options[j] then add(j, min, min + split); min = min + split; left = left - split end
  end
  local pick, u = 0, nextDouble(r.rand)
  for k = 1, #list do
    local p = list[k]
    if u >= p[2] and u < p[3] then pick = p[1] end
  end
  local a = F(goal - 45 * pick)
  while a < 0 do a = F(a + 360) end
  r.turn = a
  r.distance = safeDistance(w, id, r.turn)
  r.speed = r.distance
end

R.controllers = { KTRobot = KT, AntRobot = ANT, Simple2 = DEF, KT = KT, Ant = ANT, Default = DEF }

----------------------------------------------------------------------------
-- the world

local function coverCell(w, x, y)
  local gx = int(x * (w.ncx / w.width))
  local gy = int(y * (w.ncy / w.height))
  if gx >= w.ncx then gx = w.ncx - 1 end
  if gy >= w.ncy then gy = w.ncy - 1 end
  local key = gy * w.ncx + gx
  if not w.area[key] and not w.cov[key] then
    w.covered = w.covered + 1
    if w.behind[key] then w.behindCovered = w.behindCovered + 1 end
  end
  w.cov[key] = true
end

-- ObstacleContainer.fillHashtables: cells inside obstacles, then shadows
local function fillCells(w)
  local rx, ry = w.ncx / w.width, w.ncy / w.height
  local hx, hy = (w.width / w.ncx) / 2.0, (w.height / w.ncy) / 2.0
  local area, behind, na, nb = {}, {}, 0, 0
  for _, o in ipairs(w.obs) do
    local minx, maxx = int((o[1] + hx) * rx), int((o[3] - hx) * rx)
    local miny, maxy = int((o[2] + hy) * ry), int((o[4] - hy) * ry)
    for i = minx, maxx do
      for j = miny, maxy do
        local key = j * w.ncx + i
        if not area[key] then area[key] = true; na = na + 1 end
      end
    end
  end
  for _, o in ipairs(w.obs) do
    local minx, maxx = int((o[1] + hx) * rx), int((o[3] - hx) * rx)
    local maxy = int((o[4] + hy) * ry)
    for i = minx, maxx do
      local key = maxy * w.ncx + i
      if not area[key] and not behind[key] then behind[key] = true; nb = nb + 1 end
    end
  end
  w.area, w.behind, w.cells, w.behindCells = area, behind, w.ncx * w.ncy - na, nb
end

-- o: controller ("KTRobot" | "AntRobot" | "Simple2", or "KT" | "Ant" |
-- "Default"), n (25), seed (his drivers': 100 + 10 course + run), course
-- (a file of rectangles, or nil for none), wall (KT's wall speed, 0.4 as
-- his drivers set it), width, height (1000, 5000), ncell_x, ncell_y (50,
-- 250), sep (40), fix = { seeds, messages, wallfit }
function R.new(o)
  local ctl = R.controllers[o.controller or "KTRobot"] or error("kerr2005: no controller " .. tostring(o.controller))
  local w = { n = o.n or 25, seed = o.seed or 100, width = o.width or 1000, height = o.height or 5000,
              ncx = o.ncell_x or 50, ncy = o.ncell_y or 250, sep = F(o.sep or 40), wall = F(o.wall or 0.4),
              fix = o.fix or {}, ctl = ctl, time = 0, x = {}, y = {}, b = {}, robots = {},
              msg = {}, ignoring = {}, order = {}, nearR = {}, nearO = {},
              cov = {}, covered = 0, behindCovered = 0 }
  w.rand = jrandom(w.seed)
  w.obs = o.course and R.loadCourse(o.course) or {}
  fillCells(w)
  w.xRatio, w.yRatio = w.ncx / w.width, w.ncy / w.height
  w.trail = {}
  for k = 0, w.ncx * w.ncy - 1 do w.trail[k] = w.area[k] and INT_MAX or 0 end
  for i = 0, w.n - 1 do w.msg[i] = {}; w.ignoring[i] = {} end
  local m = ceil(sqrt(w.n))
  local count = 0
  for i = 0, m - 1 do
    for j = 0, m - 1 do
      if count < w.n then
        w.robots[count] = ctl.new(w, count)
        w.x[count] = F(F(j * w.sep) + 10)
        w.y[count] = F(F(i * w.sep) + 10)
        w.b[count] = F(nextFloat(w.rand) * 360)
        coverCell(w, w.x[count], w.y[count])
        count = count + 1
      end
    end
  end
  return w
end

local function moveRobot(w, i)
  local r = w.robots[i]
  w.ctl.move(w, r)
  local b = w.b[i] + r.turn
  while b > 360 do b = b - 360 end
  while b < -360 do b = b + 360 end
  w.b[i] = b
  local d = r.distance
  local x = w.x[i] + d * cos(b * D2R)
  local y = w.y[i] + d * sin(b * D2R)
  if x < 0 then x = 3 elseif x > w.width then x = w.width - 3 end
  if y < 0 then y = 3 elseif y > w.height then y = w.height - 3 end
  w.x[i], w.y[i] = x, y
  coverCell(w, x, y)
end

function R.step(w)
  local n, order = w.n, w.order
  for i = 0, n - 1 do
    order[i] = i
    local ig = w.ignoring[i]
    for j in pairs(ig) do ig[j] = nil end
  end
  for _ = 1, 100 do
    local i1 = nextInt(w.rand, n)
    local i2 = nextInt(w.rand, n)
    order[i1], order[i2] = order[i2], order[i1]
  end
  for i = 0, n - 1 do moveRobot(w, order[i]) end
  w.time = w.time + 1
  for i = 0, n - 1 do w.msg[i] = {} end
end

-- Environment.continueGoing
function R.going(w)
  for i = 0, w.n - 1 do if not w.robots[i].done then return true end end
  return false
end

function R.result(w)
  return { total = 100 * w.covered / w.cells,
           behind = w.behindCells == 0 and 0 or 100 * w.behindCovered / w.behindCells,
           time = w.time }
end

-- his drivers' run: steps until every robot is done, at most `limit`
-- (150,000)
function R.run(o)
  local w = R.new(o)
  local limit = o.limit or 150000
  while w.time < limit do
    R.step(w)
    if not R.going(w) then break end
  end
  return R.result(w), w
end

-- the courses: his data/course_P_k.txt (P = 10..40, k = 0..9); P 0 is the
-- empty corridor
function R.coursePath(dir, pct, k)
  if pct == 0 then return nil end
  return dir .. "/course_" .. pct .. "_" .. k .. ".txt"
end

local names = { KT = "KTRobot", Ant = "AntRobot", Default = "Simple2" }
function R.line(res, o)
  local ctl = names[o.controller] or o.controller
  return string.format("%s Speed 0.4 N %d Pct %d Course %d Run %d Behind %.10g Total %.10g Time %d",
    ctl, o.n or 25, o.pct or 0, o.k or 0, o.run or 0, res.behind, res.total, res.time)
end

return R
