--
-- Walker room: WyomingWill's walkers on one meadow, each scaled to about
-- 40 cm, walking freely inside a walled arena. They turn away from the
-- walls and from each other; one that falls is stood up again. The
-- TerrainHeight slider raises the bumps. Tab / Shift+Tab follow a
-- walker, O looks over the room, T clears the trails (README.md).
--
-- Each walker is built by its own ../Walkers/<name>_parts.lua -- the
-- same code its standalone file uses -- at a scale that makes its
-- footprint 40 cm, with its own gravity scaled to match, so it moves as
-- it does full size. All of them share one world, one terrain and one
-- physics step.
--
-- Units: centimetres and seconds.
--

local common = require "common"
v.shadows = false

-- where the walkers' parts files are, relative to this file (bpp runs a
-- script from its own folder); a launcher elsewhere can set WALKERS_DIR
local WALKERS_DIR = WALKERS_DIR or "../Walkers/"

-- ---------------------------------------------------------------------
-- settings
-- ---------------------------------------------------------------------

local TARGET = 40          -- every walker's footprint (its longer side), cm
local ARENA = ARENA or 1000 -- the arena is ARENA x ARENA cm, centred on 0
local CELL = CELL or 4      -- terrain cell, cm
local FIXED = FIXED or 1 / 960   -- the physics step every walker shares, s
local FRAME = 1 / 60       -- simulated time per drawn frame, s

-- ONLY = "<name>" builds just that walker (for tests); otherwise all
ONLY = ONLY or nil
SEED = SEED or 1           -- seeds the walkers' starting headings (and, later, their turns)

v.timeStep = FRAME
v.animationPeriod = math.floor(FRAME * 1000)   -- a frame every 16 ms: real time, if the machine keeps up
v.fixedTimeStep = FIXED
v.maxSubSteps = math.ceil(FRAME / FIXED)
v.gravity = btVector3(0, -981, 0)   -- (each walker's own bodies get their own, below)

-- ---------------------------------------------------------------------
-- the terrain: one bumpy meadow for everyone. Its bump height is the
-- TerrainHeight slider; changing it builds the room again (the floor
-- changes shape, and each walker is built to clear the highest bump).
-- ---------------------------------------------------------------------

local AMP = AMP or 1.0     -- bump height, cm: the highest a bump reaches above 0
local AMP_MAX = 8          -- the slider's top: about the walkers' own sliders' tops, at 40 cm

-- three sine terms as in the walkers' own terrains (amplitudes 0.5, 0.3
-- and 0.2: AMP is the highest a bump can reach), with wavelengths between
-- those of the big walkers' terrains and the small ones', at 40 cm
local function terrainHeight(x, z)
  return AMP * (0.5 * math.sin(x * 0.19 + z * 0.13) +
                0.3 * math.sin(x * 0.07 - z * 0.28 + 1.7) +
                0.2 * math.sin(x * 0.34 + z * 0.045 + 4.1))
end

local NX = math.floor(ARENA / CELL)
local X0 = -ARENA / 2

-- everything the room adds, to take it all down again for a rebuild
local roomObjects, roomConstraints = {}, {}
local function addObject(o)
  v:add(o)
  roomObjects[#roomObjects + 1] = o
  return o
end

-- meadow colours: grass greener in the hollows and drier on the tops,
-- browner where it is steep, with patches of bare earth
local function noise(i, j, k)
  local s = math.sin(i * 12.9898 + j * 78.233 + (k or 0) * 37.719) * 43758.5453
  return s - math.floor(s)
end
local function clamp(c) return math.max(0, math.min(255, math.floor(c + 0.5))) end
local function mix(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
local GRASS, GRASS_DRY, DIRT, DIRT_DARK = { 58, 112, 38 }, { 128, 132, 58 }, { 128, 92, 56 }, { 92, 64, 40 }
local function cellColour(i, j)
  local x, z = X0 + (i + 0.5) * CELL, X0 + (j + 0.5) * CELL
  local y = terrainHeight(x, z) / math.max(AMP, 1e-6)
  local slope = (math.abs(terrainHeight(x + CELL, z) - terrainHeight(x - CELL, z)) +
                 math.abs(terrainHeight(x, z + CELL) - terrainHeight(x, z - CELL))) / CELL
  local patch = math.sin(x * 0.011 + 1.3) + math.sin(z * 0.013 - 0.4) + 0.6 * math.sin((x + z) * 0.024)
  local t = math.max(0, math.min(1, (patch - 0.9) * 2.5))
  local c = mix(mix(GRASS, GRASS_DRY, math.max(0, math.min(1, y * 0.4 + 0.3))), DIRT, t)
  c = mix(c, DIRT_DARK, math.min(0.5, slope * 0.8))
  local k = 0.93 + 0.14 * noise(i, j)
  return clamp(c[1] * k), clamp(c[2] * k), clamp(c[3] * k)
end
-- a cell's two triangles (the second a shade darker, so the mesh reads)
local function paintCell(i, j, r, g, b)
  local t = 2 * (i * NX + j)
  floor:setTriangleColor(t, r, g, b)
  floor:setTriangleColor(t + 1, clamp(r * 0.97), clamp(g * 0.97), clamp(b * 0.97))
end

local WALL_H, WALL_T = 20, 10

local function buildTerrain()
  floor = Terrain()
  for i = 0, NX - 1 do
    for j = 0, NX - 1 do
      local xa, xb, za, zb = X0 + i * CELL, X0 + (i + 1) * CELL, X0 + j * CELL, X0 + (j + 1) * CELL
      floor:addTriangle(btVector3(xa, terrainHeight(xa, za), za), btVector3(xa, terrainHeight(xa, zb), zb), btVector3(xb, terrainHeight(xb, za), za))
      floor:addTriangle(btVector3(xb, terrainHeight(xb, za), za), btVector3(xa, terrainHeight(xa, zb), zb), btVector3(xb, terrainHeight(xb, zb), zb))
    end
  end
  floor:build()
  floor.col = "#5a7a32"
  floor.friction = 0.8
  addObject(floor)
  for i = 0, NX - 1 do
    for j = 0, NX - 1 do paintCell(i, j, cellColour(i, j)) end
  end

  -- walls round the arena: low stone blocks
  for side = 0, 3 do
    local len = ARENA + 2 * WALL_T
    local wall = Cube((side % 2 == 0) and len or WALL_T, WALL_H, (side % 2 == 0) and WALL_T or len, 0)
    local off = ARENA / 2 + WALL_T / 2
    local x = (side == 1) and off or (side == 3) and -off or 0
    local z = (side == 0) and off or (side == 2) and -off or 0
    wall.pos = btVector3(x, WALL_H / 2 - AMP, z)
    wall.col = (side % 2 == 0) and "#8a8378" or "#827b70"
    wall.friction = 0.5
    addObject(wall)
  end
end

-- ---------------------------------------------------------------------
-- the walkers
--
-- size: the longer side of its moving bodies' footprint when built at
--   full size (measured; the scale is TARGET / size)
-- fixed: its own physics step; the room steps at FIXED, so its motors'
--   impulse (applied once per step) is scaled by FIXED / fixed
-- lift: how its build is told about the bumps -- "groundTop" (the
--   highest the ground gets) or "terrainLift" (how much to lift it)
-- forward: the direction it walks in its own frame (+1: +x, -1: -x)
-- opts: its standalone file's slider defaults
-- railed: its body is held to move only along its own heading (the
--   balanced Spears' fix for a sideways drift); it turns only in right
--   angles, and the hold is put back along its new heading after each
-- ---------------------------------------------------------------------

local WALKERS = {
  { name = "Jansen", parts = "Jansen_6Leg_parts.lua", size = 379.7, fixed = 1 / 240, lift = "groundTop", forward = -1,
    opts = { speed = 2.5 } },
  { name = "Klann", parts = "Klann_6Leg_parts.lua", size = 435.3, fixed = 1 / 240, lift = "groundTop", forward = 1,
    opts = { speed = 2.5 } },
  { name = "Chebyshev", parts = "Chebyshev_normal_parts.lua", size = 16.36, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 50, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Chebyshev diag", parts = "Chebyshev_diag_parts.lua", size = 16.31, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 140, linkageSpacing = 10, motorSpeed = 3.0 } },
  { name = "Chebyshev-Spears", parts = "Chebyshev_Spears_normal_parts.lua", size = 17.67, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Chebyshev-Spears diag", parts = "Chebyshev_Spears_diag_parts.lua", size = 28.48, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6 } },
  { name = "Hoecken", parts = "Hoecken_normal_parts.lua", size = 17.21, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 10, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken slider", parts = "Hoecken_slider_parts.lua", size = 18.97, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken-Spears slider", parts = "Hoecken_Spears_slider_parts.lua", size = 17.71, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Spears 4-bar", parts = "Spears_4Bar_4Leg_parts.lua", size = 37.32, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, linkageSpacing = 20, speed = 2.6 } },
  { name = "Spears 2-leg", parts = "Spears_4Bar_2Leg_parts.lua", size = 26.57, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8 } },
  { name = "Spears 2-leg balanced", parts = "Spears_4Bar_2Leg_Balanced_parts.lua", size = 26.59, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8, barLen = 13, tipMass = 70 }, railed = true },
}

-- ---------------------------------------------------------------------
-- moving a whole walker rigidly: every body turned about a vertical axis
-- through (cx, cz) by yaw radians, then moved by (dx, dy, dz). Hinges
-- are fixed in the bodies' own frames, so a rigid move leaves every
-- joint as it was. Velocities are turned too.
-- ---------------------------------------------------------------------

local function moveWalker(w, cx, cz, yaw, dx, dy, dz)
  local c, s = math.cos(yaw), math.sin(yaw)
  local qs, qc = math.sin(yaw / 2), math.cos(yaw / 2)
  for _, o in ipairs(w.bodies) do
    local b = o.body
    local vx, vy, vz = getVelXYZ(o)
    setVelXYZ(o, c * vx + s * vz, vy, -s * vx + c * vz)
    local ax, ay, az = getAngVelXYZ(o)
    setAngVelXYZ(o, c * ax + s * az, ay, -s * ax + c * az)
    -- (from the body's physics transform: the drawn one, o.trans, can be
    -- a fraction of a step behind it)
    local t = b:getCenterOfMassTransform()
    local p, q = b:getCenterOfMassPosition(), t:getRotation()
    local rx, rz = p.x - cx, p.z - cz
    local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
    -- (0, qs, 0, qc) * (qx, qy, qz, qw)
    local nq = btQuaternion(qc * qx + qs * qz, qc * qy + qs * qw, qc * qz - qs * qx, qc * qw - qs * qy)
    local nt = btTransform(nq, btVector3(cx + c * rx + s * rz + dx, p.y + dy, cz - s * rx + c * rz + dz))
    b:setCenterOfMassTransform(nt)
    o.trans = nt                         -- (and the drawn one)
    b:activate(true)
  end
end

-- quaternions as four numbers (x, y, z, w): a product, and a vector turned
local function qmul(ax, ay, az, aw, bx, by, bz, bw)
  return aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
         aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz
end
local function qrot(qx, qy, qz, qw, vx, vy, vz)
  local tx, ty, tz = 2 * (qy * vz - qz * vy), 2 * (qz * vx - qx * vz), 2 * (qx * vy - qy * vx)
  return vx + qw * tx + (qy * tz - qz * ty), vy + qw * ty + (qz * tx - qx * tz), vz + qw * tz + (qx * ty - qy * tx)
end

-- the whole walker turned rigidly by the rotation (rx, ry, rz, rw) about
-- the point (cx, cy, cz), with its velocities turned too
local function rotateWalker(w, cx, cy, cz, rx, ry, rz, rw)
  for _, o in ipairs(w.bodies) do
    local b = o.body
    setVelXYZ(o, qrot(rx, ry, rz, rw, getVelXYZ(o)))
    setAngVelXYZ(o, qrot(rx, ry, rz, rw, getAngVelXYZ(o)))
    local t = b:getCenterOfMassTransform()
    local p, q = b:getCenterOfMassPosition(), t:getRotation()
    local px, py, pz = qrot(rx, ry, rz, rw, p.x - cx, p.y - cy, p.z - cz)
    local nx, ny, nz, nw = qmul(rx, ry, rz, rw, q:x(), q:y(), q:z(), q:w())
    local nt = btTransform(btQuaternion(nx, ny, nz, nw), btVector3(cx + px, cy + py, cz + pz))
    b:setCenterOfMassTransform(nt)
    o.trans = nt
    b:activate(true)
  end
end

-- a railed walker's hold: along x (it may not move in z) or along z
-- (Bullet's linear factor stops a body's velocity *changing* along the
-- held axis; whatever velocity it has that way when the hold goes on
-- would last for ever, so that part is taken away first)
local function setRail(w)
  local h = w.heading
  local vx, vy, vz = getVelXYZ(w.cube)
  if math.abs(math.cos(h)) > 0.5 then
    setVelXYZ(w.cube, vx, vy, 0)
    w.cube.body:setLinearFactor(btVector3(1, 1, 0))
  else
    setVelXYZ(w.cube, 0, vy, vz)
    w.cube.body:setLinearFactor(btVector3(0, 1, 1))
  end
end

local walkers = {}
room = { walkers = walkers }   -- (global, for tests and the command line)

local function addWalker(spec, x, z, heading)
  local W = dofile(WALKERS_DIR .. spec.parts)
  local scale = TARGET / spec.size
  local w = { spec = spec, scale = scale, bodies = {}, constraints = {} }
  local opts = {}
  for k, val in pairs(spec.opts) do opts[k] = val end
  opts.add = function(o)
    addObject(o)
    o.body:setActivationState(4)        -- DISABLE_DEACTIVATION: a sleeping body ignores its motor
    w.bodies[#w.bodies + 1] = o
  end
  opts.addConstraint = function(con)
    v:addConstraint(con)
    w.constraints[#w.constraints + 1] = con
    roomConstraints[#roomConstraints + 1] = con
  end
  opts.scale = scale
  opts.impulseScale = FIXED / spec.fixed
  opts[spec.lift] = AMP                  -- the room's bumps reach AMP above 0
  local built = W.build(opts)
  w.cube = built.cube
  w.parts = built
  -- its radius: half the diagonal of its moving bodies' footprint (from
  -- the moving bodies only: static ones would make it look huge)
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  local x0, x1, z0, z1 = 1e30, -1e30, 1e30, -1e30
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 then
      o.body:getAabb(lo, hi)
      x0, x1, z0, z1 = math.min(x0, lo.x), math.max(x1, hi.x), math.min(z0, lo.z), math.max(z1, hi.z)
    end
  end
  w.radius = 0.5 * math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
  -- its own gravity, scaled with it, on its moving bodies only
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 then o.body:setGravity(btVector3(0, -9.8 * scale, 0)) end
  end
  -- its floor (FLOOR_TOP_Y, its own units) onto the room's (0), then to
  -- its spot, turned to its heading (0: walking along +x)
  local cp = w.cube.body:getCenterOfMassPosition()
  local cx, cz = cp.x, cp.z
  local yaw0 = (spec.forward > 0) and 0 or math.pi
  moveWalker(w, cx, cz, heading - yaw0, x - cx, -(W.FLOOR_TOP_Y or 0) * scale, z - cz)
  w.heading = heading                    -- (the heading it was set to; heading(w) is the one it has)
  if spec.railed then setRail(w) end
  -- how it was built to stand (some, like the 2-leg Spears, are built
  -- tilted on purpose), to know when it has fallen and to stand it up again
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  w.q0 = { q:x(), q:y(), q:z(), q:w() }
  w.heading0 = heading
  w.tilt0 = math.acos(math.max(-1, math.min(1, 1 - 2 * (q:x() ^ 2 + q:z() ^ 2))))
  walkers[#walkers + 1] = w
  return w
end

-- a seeded random generator (the same seed gives the same room)
local rngState = SEED
local function random()
  rngState = (rngState * 1103515245 + 12345) % 2147483648
  return rngState / 2147483648
end

-- spots: a 4 x 3 grid filling the arena, the walkers in list order
local COLS, ROWS = 4, 3
local function buildWalkers()
  rngState = SEED
  local n = 0
  for _, spec in ipairs(WALKERS) do
    if ONLY == nil or spec.name == ONLY then
      local col, row = n % COLS, math.floor(n / COLS)
      local x = ONLY and 0 or (-ARENA / 2 + (col + 0.5) * ARENA / COLS)
      local z = ONLY and 0 or (-ARENA / 2 + (row + 0.5) * ARENA / ROWS)
      local heading = ONLY and 0 or random() * 2 * math.pi
      -- (a railed walker starts along an axis: see `railed` above)
      if spec.railed then heading = math.floor(random() * 4) * math.pi / 2 end
      addWalker(spec, x, z, heading)
      n = n + 1
    end
  end
end

-- ---------------------------------------------------------------------
-- turning: a turn of `angle` radians (+ to the left, seen from above) is
-- spread over TURN_TIME seconds, a little each frame, about a vertical
-- axis through the walker's body. Small steps let the feet's contacts
-- settle as it goes, where one big jump could push a foot into a bump.
-- ---------------------------------------------------------------------

local TURN_TIME = 1.0
local LIFT_TOLERANCE = 0.15   -- cm

local function startTurn(w, angle)
  w.turnLeft = angle
  w.turnRate = angle / TURN_TIME
  w.heading = w.heading + angle
  if w.spec.railed then w.cube.body:setLinearFactor(btVector3(1, 1, 1)) end   -- (free while it turns)
end

local function turnStep(w, dt)
  if not w.turnLeft then return end
  local step = w.turnRate * dt
  if math.abs(step) >= math.abs(w.turnLeft) then step = w.turnLeft end
  local p = w.cube.body:getCenterOfMassPosition()
  moveWalker(w, p.x, p.z, step, 0, 0, 0)
  -- turning sweeps the feet sideways, into rising ground on a bumpy
  -- floor; a foot pushed through the (thin) terrain then props the walker
  -- up from underneath. So if any body's lowest point is now below the
  -- ground under it, lift the whole walker by that much. (A body resting
  -- on the ground sits a hair into it, within Bullet's contact margin:
  -- LIFT_TOLERANCE keeps that from nudging the walker up every frame.)
  local need = 0
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  for _, o in ipairs(w.bodies) do
    o.body:getAabb(lo, hi)
    local ground = math.max(terrainHeight(lo.x, lo.z), terrainHeight(lo.x, hi.z),
                            terrainHeight(hi.x, lo.z), terrainHeight(hi.x, hi.z),
                            terrainHeight((lo.x + hi.x) / 2, (lo.z + hi.z) / 2))
    need = math.max(need, ground - lo.y - LIFT_TOLERANCE)
  end
  if need > 0 then moveWalker(w, p.x, p.z, 0, 0, need, 0) end
  w.turnLeft = w.turnLeft - step
  if math.abs(w.turnLeft) < 1e-9 then
    w.turnLeft = nil
    if w.spec.railed then setRail(w) end
  end
end

-- the way a walker faces now: its body's own forward axis, in the room
local function heading(w)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local f = w.spec.forward
  -- the body's local x axis in the room, times its forward sign
  local fx = f * (1 - 2 * (qy * qy + qz * qz))
  local fz = f * (2 * (qx * qz - qw * qy))
  return math.atan2(-fz, fx)        -- 0: +x; + : to the left (toward -z)
end
room.heading, room.startTurn = heading, startTurn

-- ---------------------------------------------------------------------
-- avoiding walls and each other. Each walker, unless it is turning or
-- has just turned, looks ahead: if it is heading toward a wall and is
-- within GAP of it, or heading toward another walker (within AHEAD of
-- straight at it) with less than GAP between them, it turns. The new
-- heading is the best of a few seeded random ones: away from walls and
-- walkers near enough to matter.
-- ---------------------------------------------------------------------

local GAP = TARGET          -- one body length, cm
local AHEAD = math.rad(60)  -- "in front": within this of straight ahead
local COOLDOWN = 2.0        -- s after a turn ends before it looks again
local CANDIDATES = 12       -- new headings tried per turn
local WALL_IN = ARENA / 2   -- the walls' inner faces are at +-WALL_IN

local function angleDiff(a, b)       -- a - b, wrapped to (-pi, pi]
  local d = (a - b) % (2 * math.pi)
  if d > math.pi then d = d - 2 * math.pi end
  return d
end

-- how bad heading h would be for walker w at (x, z): the closer what lies
-- that way, the worse
local function badness(w, x, z, h)
  local fx, fz = math.cos(h), -math.sin(h)
  local bad = 0
  -- walls: the distance to the wall along h, if it is near
  local reach = 4 * GAP
  local dist = 1e30
  if fx > 1e-6 then dist = math.min(dist, (WALL_IN - w.radius - x) / fx) end
  if fx < -1e-6 then dist = math.min(dist, (-WALL_IN + w.radius - x) / fx) end
  if fz > 1e-6 then dist = math.min(dist, (WALL_IN - w.radius - z) / fz) end
  if fz < -1e-6 then dist = math.min(dist, (-WALL_IN + w.radius - z) / fz) end
  if dist < reach then bad = bad + (reach - dist) / reach end
  -- walkers in that direction
  for _, o in ipairs(walkers) do
    if o ~= w then
      local ox, _, oz = getPosXYZ(o.cube)
      local dx, dz = ox - x, oz - z
      local d = math.sqrt(dx * dx + dz * dz)
      local gap = d - w.radius - o.radius
      if gap < reach and d > 1e-6 and (dx * fx + dz * fz) / d > math.cos(AHEAD) then
        bad = bad + (reach - math.max(gap, 0)) / reach
      end
    end
  end
  return bad
end

local RIGHT_ANGLES = { math.pi / 2, -math.pi / 2, math.pi }
local function chooseTurn(w, x, z, h)
  local best, bestBad
  for k = 1, w.spec.railed and #RIGHT_ANGLES or CANDIDATES do
    -- a turn of 60 to 180 degrees, left or right (a railed walker: a
    -- right angle, or about turn)
    local turn = w.spec.railed and RIGHT_ANGLES[k] or math.rad(60 + 120 * random()) * ((random() < 0.5) and -1 or 1)
    local b = badness(w, x, z, h + turn) + 0.1 * math.abs(turn) / math.pi   -- (smaller turns preferred, a little)
    if not bestBad or b < bestBad then best, bestBad = turn, b end
  end
  return best
end

-- what is in front of walker w, if anything: "wall", or another walker.
-- "In front" along heading h, which is checked twice: the way it faces,
-- and the way it has actually been moving (a walker that slides or veers
-- -- the 2-leg Spears does as it rolls over -- can move well off the way
-- it faces)
local function blockedAlong(w, x, z, h)
  local fx, fz = math.cos(h), -math.sin(h)
  -- each wall: the gap between the walker's edge and it, and how
  -- squarely the walker heads at it (1: straight at it; 0: along it)
  for _, wall in ipairs({ { WALL_IN - x, fx }, { WALL_IN + x, -fx }, { WALL_IN - z, fz }, { WALL_IN + z, -fz } }) do
    local gap, toward = wall[1] - w.radius, wall[2]
    if (gap < GAP and toward > math.cos(AHEAD)) or (gap < GAP / 4 and toward > 0) then return "wall" end
  end
  for _, o in ipairs(walkers) do
    if o ~= w then
      local ox, _, oz = getPosXYZ(o.cube)
      local dx, dz = ox - x, oz - z
      local d = math.sqrt(dx * dx + dz * dz)
      if d - w.radius - o.radius < GAP and d > 1e-6 and (dx * fx + dz * fz) / d > math.cos(AHEAD) then
        return o
      end
    end
  end
end

-- ---------------------------------------------------------------------
-- standing fallen walkers up again. A walker counts as fallen when its
-- body has tipped more than FALL_TILT beyond the tilt it was built with,
-- and has stayed so for FALL_TIME. It is then turned back, rigidly, to
-- the way it was built to stand (facing the way it faces now), lifted
-- clear of the ground, and stopped; it carries on from there.
-- ---------------------------------------------------------------------

local FALL_TILT = math.rad(50)
local FALL_TIME = 2.0
room.righted = {}   -- a log: { time, walker name }

local function tilt(w)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  return math.acos(math.max(-1, math.min(1, 1 - 2 * (q:x() ^ 2 + q:z() ^ 2))))
end

-- lift walker w so its lowest point is `clear` above the ground under it
-- (or by however much it needs to get there; never down)
local function liftClear(w, clear)
  local need = 0
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  for _, o in ipairs(w.bodies) do
    o.body:getAabb(lo, hi)
    local ground = math.max(terrainHeight(lo.x, lo.z), terrainHeight(lo.x, hi.z),
                            terrainHeight(hi.x, lo.z), terrainHeight(hi.x, hi.z),
                            terrainHeight((lo.x + hi.x) / 2, (lo.z + hi.z) / 2))
    need = math.max(need, ground + clear - lo.y)
  end
  if need > 0 then moveWalker(w, 0, 0, 0, 0, need, 0) end
end

local function standUp(w)
  -- the way it was built to stand, turned to face where it faces now
  local h = heading(w)
  local d = (h - w.heading0) / 2
  local tx, ty, tz, tw = qmul(0, math.sin(d), 0, math.cos(d), w.q0[1], w.q0[2], w.q0[3], w.q0[4])
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  -- the turn from how it is to how it should be: target x (current)^-1
  local rx, ry, rz, rw = qmul(tx, ty, tz, tw, -q:x(), -q:y(), -q:z(), q:w())
  local p = w.cube.body:getCenterOfMassPosition()
  rotateWalker(w, p.x, p.y, p.z, rx, ry, rz, rw)
  liftClear(w, 0.5)
  for _, o in ipairs(w.bodies) do
    setVelXYZ(o, 0, 0, 0)
    setAngVelXYZ(o, 0, 0, 0)
  end
  w.heading = h
  w.turnLeft = nil
  if w.spec.railed then
    -- (back onto the nearest axis, which a railed walker must face along)
    w.heading = math.floor(h / (math.pi / 2) + 0.5) * math.pi / 2
    setRail(w)
  end
end

local function blocked(w, x, z, h)
  local what = blockedAlong(w, x, z, h)
  if what then return what end
  local old = w.track and w.track[1]
  if old then
    local dx, dz = x - old[1], z - old[2]
    if dx * dx + dz * dz > 1 then           -- (moved more than 1 cm in the last second)
      return blockedAlong(w, x, z, math.atan2(-dz, dx))
    end
  end
end

room.turns = {}   -- a log: { time, walker name, what blocked it, turn in degrees }
local simTime = 0
local TRACK_EVERY = 30      -- frames between samples of where each walker is (half a second)

-- ---------------------------------------------------------------------
-- trails: each walker paints the cell under its body in its own colour
-- as it goes (the walkers take turns, one every frame or two, so the
-- painting is spread out). T clears them; the cells get their meadow
-- colours back.
-- ---------------------------------------------------------------------

local TRAIL_EVERY = 6       -- frames between one walker's marks
local TRAIL_COLOURS = {
  { "red", 230, 30, 30 }, { "orange", 255, 140, 0 }, { "yellow", 255, 225, 0 }, { "white", 250, 250, 250 },
  { "black", 25, 25, 25 }, { "cyan", 0, 210, 230 }, { "blue", 40, 70, 240 }, { "purple", 150, 50, 220 },
  { "pink", 255, 105, 180 }, { "maroon", 120, 0, 40 }, { "teal", 0, 128, 128 }, { "lavender", 200, 170, 255 },
}
local painted = {}          -- [cell] = the walker whose trail is on it

local function cellAt(x, z)
  local i, j = math.floor((x - X0) / CELL), math.floor((z - X0) / CELL)
  if i < 0 or i >= NX or j < 0 or j >= NX then return nil end
  return i * NX + j, i, j
end

local function markTrail(w)
  local x, _, z = getPosXYZ(w.cube)
  local cell, i, j = cellAt(x, z)
  if cell and painted[cell] ~= w then
    painted[cell] = w
    local c = w.colour
    paintCell(i, j, c[2], c[3], c[4])
  end
end

local function clearTrails()
  for cell in pairs(painted) do
    local i, j = math.floor(cell / NX), cell % NX
    paintCell(i, j, cellColour(i, j))
  end
  painted = {}
end

-- ---------------------------------------------------------------------
-- building (and building again, when the TerrainHeight slider moves)
-- ---------------------------------------------------------------------

local owner = {}            -- [objectKey(body)] = its walker (for the hover)

local function buildRoom()
  buildTerrain()
  buildWalkers()
  owner, painted = {}, {}
  for k, w in ipairs(walkers) do
    w.colour = TRAIL_COLOURS[(k - 1) % #TRAIL_COLOURS + 1]
    w.index = k
    w.travelled = 0
    for _, o in ipairs(w.bodies) do owner[objectKey(o)] = w end
  end
  room.turns, room.righted = {}, {}
  simTime = 0
end

local function teardownRoom()
  for _, con in ipairs(roomConstraints) do v:removeConstraint(con) end
  for _, o in ipairs(roomObjects) do v:remove(o) end
  roomObjects, roomConstraints = {}, {}
  for k = #walkers, 1, -1 do walkers[k] = nil end
end

v:addParam("TerrainHeight", AMP, 0, AMP_MAX, 0.1, "bump height, cm (the room is built again when you let go)")
buildRoom()

v:preSim(function(N)
  simTime = simTime + FRAME
  for k, w in ipairs(walkers) do
    if TURN_TEST then
      -- (a test: every walker turns 90 degrees to the left every 10 s)
      if not w.turnLeft and simTime >= (w.nextTest or 10) then
        startTurn(w, math.pi / 2)
        w.nextTest = (w.nextTest or 10) + 10
      end
    elseif not w.turnLeft and simTime >= (w.calmUntil or 0) then
      local x, _, z = getPosXYZ(w.cube)
      local h = heading(w)
      local what = blocked(w, x, z, h)
      if what then
        local turn = chooseTurn(w, x, z, h)
        startTurn(w, turn)
        w.calmUntil = simTime + TURN_TIME + COOLDOWN
        room.turns[#room.turns + 1] = { simTime, w.spec.name, (what == "wall") and "wall" or what.spec.name, math.deg(turn) }
        w.turns = (w.turns or 0) + 1
      end
    end
    -- (where it was half a second and a second ago: its actual motion;
    -- and how far it has gone, in those half-second steps)
    if N % TRACK_EVERY == 0 then
      local x, _, z = getPosXYZ(w.cube)
      w.track = w.track or {}
      local last = w.track[#w.track]
      if last then w.travelled = w.travelled + math.sqrt((x - last[1]) ^ 2 + (z - last[2]) ^ 2) end
      if #w.track >= 2 then
        -- (the oldest sample's table is reused: no garbage)
        local old = table.remove(w.track, 1)
        old[1], old[2] = x, z
        w.track[2] = old
      else
        w.track[#w.track + 1] = { x, z }
      end
    end
    if (N + 2 * k) % TRAIL_EVERY == 0 then markTrail(w) end
    -- (fallen? checked every frame: a cheap test on one body)
    if tilt(w) > w.tilt0 + FALL_TILT then
      w.fallenSince = w.fallenSince or simTime
      if simTime - w.fallenSince >= FALL_TIME then
        standUp(w)
        w.fallenSince = nil
        w.calmUntil = simTime + COOLDOWN
        room.righted[#room.righted + 1] = { simTime, w.spec.name }
        w.stoodUp = (w.stoodUp or 0) + 1
      end
    else
      w.fallenSince = nil
    end
    turnStep(w, FRAME)
  end
end)

-- ---------------------------------------------------------------------
-- camera: an overview of the room (O), or following one walker (Tab and
-- Shift+Tab go round them). Following moves the view with the walker but
-- does not turn it, so the mouse still turns and zooms it.
-- ---------------------------------------------------------------------

local OVERVIEW = { pos = btVector3(-620, 520, 760), look = btVector3(0, -40, 40) }
local FOLLOW_OFFSET = { -70, 60, 85 }   -- cm from the walker, the same way the overview looks
local following, followX, followZ        -- the walker followed (nil: the overview), and where it was

local function helpText()
  local h = "WALKER ROOM -- " .. (following and ("following " .. following.spec.name .. " (trail " .. following.colour[1] .. ")")
                                           or "looking over the room") .. "\n\n"
  h = h .. "Tab         follow the next walker\n"
  h = h .. "Shift+Tab   follow the one before\n"
  h = h .. "O           look over the whole room\n"
  h = h .. "T           clear the trails\n"
  h = h .. "Mouse       turn and zoom the view (it keeps following)\n\n"
  h = h .. "Rest the pointer on a walker, or on a trail, to see whose it is,\n"
  h = h .. "how far it has gone and how often it has turned or been stood up.\n\n"
  h = h .. "TerrainHeight (Params pane): how high the bumps are, 0 to " .. AMP_MAX .. " cm.\n"
  h = h .. "The room is built again, every walker back at its start, when you let go.\n\n"
  h = h .. "Walkers and their trails:\n"
  for _, w in ipairs(walkers) do
    h = h .. string.format("  %-24s %s\n", w.spec.name, w.colour[1])
  end
  return h
end

local function follow(w)
  following = w
  if w then
    local x, y, z = getPosXYZ(w.cube)
    common.setCamera(btVector3(x + FOLLOW_OFFSET[1], y + FOLLOW_OFFSET[2], z + FOLLOW_OFFSET[3]), btVector3(x, y, z), 0.75)
    followX, followZ = x, z
  else
    common.setCamera(OVERVIEW.pos, OVERVIEW.look, 0.75)
  end
  v:setHelpText(helpText())
end

v:postSim(function(N)
  if following then
    -- (moved by how far the walker has gone across the ground; not up and
    -- down, so the view doesn't bob with its gait)
    local x, _, z = getPosXYZ(following.cube)
    local dx, dz = x - followX, z - followZ
    if dx * dx + dz * dz > 0.01 then
      local c = v.cam
      local p, l = c.pos, c.look
      c.pos = btVector3(p.x + dx, p.y, p.z + dz)
      c.look = btVector3(l.x + dx, l.y, l.z + dz)
      followX, followZ = x, z
    end
  end
end)

v:onKey(function(N, key, down)
  if key == "Tab" or key == "Backtab" then
    if down and #walkers > 0 then
      local k = following and following.index or 0
      if key == "Tab" then k = k % #walkers + 1 else k = (k - 2) % #walkers + 1 end
      follow(walkers[k])
    end
    return true
  elseif key == "O" then
    if down then follow(nil) end
    return true
  elseif key == "T" then
    if down then clearTrails() end
    return true
  end
end)

-- the hover: whose walker or trail is under the pointer
v:onHover(function(N, obj, x, y, z)
  local w = owner[objectKey(obj)]
  local first
  if w then
    first = w.spec.name .. " (trail " .. w.colour[1] .. ")"
  elseif rawequal(obj, floor) then
    local cell = cellAt(x, z)
    w = cell and painted[cell]
    first = w and ("the " .. w.colour[1] .. " trail of " .. w.spec.name)
  end
  if not w then return nil end
  return string.format("%s\nhas gone %.0f cm in %.0f s\nturned %d times, stood up %d times",
    first, w.travelled, simTime, w.turns or 0, w.stoodUp or 0)
end)

-- the TerrainHeight slider: the room is built again once the slider has
-- stayed put for a moment (a drag sends every value it passes through,
-- and each build takes most of a second)
local pendingAmp, pendingAt, draws = nil, 0, 0
v:onParamChanged(function(N, name, value)
  if name == "TerrainHeight" then pendingAmp, pendingAt = value, draws end
end)
v:preDraw(function(N)
  draws = draws + 1
  if pendingAmp and draws - pendingAt >= 20 then
    if math.abs(pendingAmp - AMP) > 1e-9 then
      AMP = pendingAmp
      teardownRoom()
      buildRoom()
      local k = following and following.index
      follow(k and walkers[k] or nil)
      print(string.format("TerrainHeight = %.1f cm (room built again)", AMP))
    end
    pendingAmp = nil
  end
end)

follow(nil)
