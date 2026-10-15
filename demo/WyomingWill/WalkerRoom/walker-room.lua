--
-- Walker room: WyomingWill's walkers on one meadow, each scaled to the
-- same stride, walking freely inside a walled arena. They turn away from the
-- walls and from each other; one that falls is stood up again. The
-- TerrainHeight slider raises the bumps. Tab / Shift+Tab follow a
-- walker, O looks over the room, T clears the trails (README.md).
--
-- Each walker is built by its own ../Walkers_For_Room/<name>_parts.lua --
-- a copy of the build its standalone file uses, with a few options added
-- (see that folder's README) -- at a scale that makes its stride
-- (the length of its foot's path) STRIDE cm, under the same gravity as
-- every other walker (GRAVITY), with its motors made stronger or weaker
-- to match, on the same feet (FOOT_LENGTH ...), with its cranks kept in
-- step (LOCK_CRANKS) and its cranks turning so that it would cross flat
-- ground at FLAT_SPEED if its feet never slipped. A
-- bump is then the same obstacle to every walker's step, each walker's
-- foot lifts as high, for its stride, as its linkage lifts it, and on
-- flat ground they should all go the same speed: one that doesn't has
-- something wrong with its build.
-- All of them share one world, one terrain and one physics step.
--
-- Units: centimetres and seconds.
--

local common = require "common"
v.shadows = false

-- where the walkers' parts files are, relative to this file (bpp runs a
-- script from its own folder); a launcher elsewhere can set WALKERS_DIR
local WALKERS_DIR = WALKERS_DIR or "../Walkers_For_Room/"

-- ---------------------------------------------------------------------
-- settings
-- ---------------------------------------------------------------------

local STRIDE = STRIDE or 15  -- every walker's stride: the length of its foot's path, cm
-- every walker's crank speed is set so that, if its feet never slipped,
-- it would cross flat ground at FLAT_SPEED cm/s: 2 pi FLAT_SPEED / its
-- `advance` (below). CRANK (rad/s), if set, gives every walker that crank
-- speed instead (Walker Room1 and the gravity-70 version: 2.6 for all).
local FLAT_SPEED = FLAT_SPEED or 9
local CRANK = CRANK
-- the chassis every four-legged walker is given (see `chassis` below),
-- for STRIDE = 15; the chassis values in WALKERS were worked out for these
local CLEARANCE, BASE, WIDTH = 12, 35, 30   -- cm: 0.8, 2.33 and 2 strides
local GRAVITY = GRAVITY or 70   -- every walker's gravity, cm/s^2 (see addWalker)
-- LOCK_CRANKS (default on): a walker's cranks are kept in step, at the
-- timing they were built with, as if one motor drove them all through
-- gears (see lockCranks)
LOCK_CRANKS = (LOCK_CRANKS ~= false)
-- every walker's feet: the same flat box, FOOT_LENGTH (along the walk) x
-- FOOT_WIDTH (across) x FOOT_THICK cm, weighing FOOT_MASS (SAME_FEET =
-- false: each keeps its own file's feet, and Jansen and Klann none)
SAME_FEET = (SAME_FEET ~= false)
-- every walker's body the same: SAME_BODY (default on) makes each walker
-- weigh TOTAL_MASS in all (its body making up whatever its legs, feet
-- and braces don't), with its body turning as a BODY_BOX (cm: along the
-- walk, up, across) of that weight would. Its body keeps its own shape
-- for drawing and for touching things (it sits 12 cm up, clear of the
-- ground; its depth also sets where its legs are mounted).
SAME_BODY = (SAME_BODY ~= false)
local TOTAL_MASS = TOTAL_MASS or 100
local BODY_BOX = BODY_BOX or { 40, 3, 30 }
-- every walker's motors the same: MOTOR_STRENGTH (default 10) is the
-- most twisting effort all of a walker's crank motors together can give,
-- in units of its weight x gravity x stride -- the same for every walker.
-- (Its own file's motors ranged from 1.4 to 71 in these units.) false:
-- each walker's own file's motors.
MOTOR_STRENGTH = (MOTOR_STRENGTH == nil) and 10 or MOTOR_STRENGTH
-- SOLVER_ITERATIONS (default 40): how many times the physics solver
-- works over each of a walker's joints every step. Bullet's default is
-- 10, and at 10 a walker whose braces close a loop across its body (the
-- diag walkers) has its joints pulled apart on hills and jams. false:
-- Bullet's default (and 40 for the balanced 2-leg Spears, as its own
-- file has it).
SOLVER_ITERATIONS = (SOLVER_ITERATIONS == nil) and 40 or SOLVER_ITERATIONS
-- WIDE (default on): every walker's feet about 38 cm apart side to side
-- (outer foot edge to outer foot edge, as Jansen's own file has them),
-- each walker's body made wide enough for that (see `wide`). false:
-- about 30-31 cm, from the `chassis` body depths
WIDE = (WIDE ~= false)
-- BRACE_CLEARANCE (default 7 cm): the plates and bars joining a walker's
-- legs (its braces) kept at least this far above flat ground while it
-- stands -- above the tallest bumps -- so they never catch on a bump
-- between its feet. A plate loses that much off its bottom (its top stays
-- where it was); a diag walker's low bar is moved up. `brace.gap` is how
-- far above the ground each walker's own braces sit (cm, measured
-- walking on flat ground): as low as 0.9 cm. false: as built.
BRACE_CLEARANCE = (BRACE_CLEARANCE == nil) and 7 or BRACE_CLEARANCE
-- MARKS (default on): each walker's body marked with its colours and
-- code (see markBody). false: plain bodies, as the walkers' own files
-- paint them.
MARKS = (MARKS ~= false)
-- ANKLES = true: every walker's feet hinged to its legs about the
-- side-to-side axis, like ankles (as the 2-leg Spears' own files have
-- them), instead of welded (Walker Room1: welded)
ANKLES = ANKLES or false
-- REVERSE: true runs every walker's cranks backward (a table of names,
-- { ["Spears 4-bar"] = true }, just those): each foot goes round its path
-- the other way, so the walker walks the other way, and the end of its
-- foot's swing it came down at is now the one it lifts off at
REVERSE = REVERSE or false
-- GAIT = { four crank phases, degrees }: every leg's phase, for the
-- walkers without braces locking their legs together (Jansen, Klann,
-- Spears 4-bar), in the Spears 4-bar file's order: front face first leg,
-- second leg, back face first leg, second leg. Its own: { 0, 225, 180, 225 }
GAIT = GAIT or nil
-- UNBRACED: true (or a table of names) leaves off the side plates of the
-- walkers that have them (Chebyshev-Spears, the Hoecken walkers and
-- Hoecken-Spears 4-bars and sliders), so their legs are free to take
-- any GAIT, a trot (GAIT = { 0, 180, 180, 0 }) among them
UNBRACED = UNBRACED or false
local FOOT = { length = FOOT_LENGTH or 8, width = FOOT_WIDTH or 12, thick = FOOT_THICK or 0.5, mass = FOOT_MASS or 1.5 }
local ARENA = ARENA or 1000 -- the arena is ARENA x ARENA cm, centred on 0 ...
local ARENA_X = ARENA_X or ARENA   -- ... or ARENA_X long (along x) and ARENA_Z wide
local ARENA_Z = ARENA_Z or ARENA

-- TEST_TRACK = true: the test track. Only the walker named ONLY, starting near
-- the -x end facing +x, walks straight down the arena (make it long and
-- narrow: ARENA_X, ARENA_Z) with no avoidance turns, for TRACK_SECS
-- seconds, and reports how far it got along x. Its start is moved, by
-- SEED, up to a bump length along and across, so runs with different
-- seeds meet the bumps differently. See test-track.lua.
TEST_TRACK = TEST_TRACK or false
local TRACK_SECS = TRACK_SECS or 60
local CELL_SET = CELL      -- terrain cell, cm: a launcher can fix it; otherwise it follows BumpLength (below)
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
-- TerrainHeight slider and its bumps' length the BumpLength slider;
-- changing either builds the room again (the floor changes shape, and
-- each walker is built to clear the highest bump).
-- ---------------------------------------------------------------------

local AMP = AMP or 1.0     -- bump height, cm: the highest a bump reaches above 0
local AMP_MAX = 8          -- the slider's top: about the walkers' own sliders' tops, scaled to the room
-- bump length, cm: the middle one of the three sine terms' wavelengths
-- (the other two are 1.25 and 0.84 times it). At 22 (1.5 strides) the
-- bumps are rolling hills the walkers walk up and down; shorter ones are
-- obstacles a foot has to lift over within a step.
local BUMP = BUMP or 22
local BUMP_MIN, BUMP_MAX = 11, 44

-- three sine terms as in the walkers' own terrains (amplitudes 0.5, 0.3
-- and 0.2: AMP is the highest a bump can reach), their wavelengths all
-- scaled by BUMP
local function terrainHeight(x, z)
  local r = 22 / BUMP
  return AMP * (0.5 * math.sin((x * 0.19 + z * 0.13) * r) +
                0.3 * math.sin((x * 0.07 - z * 0.28) * r + 1.7) +
                0.2 * math.sin((x * 0.34 + z * 0.045) * r + 4.1))
end

-- the terrain's cells: about a sixth of the shortest wavelength (4 cm
-- at BUMP 22), so short bumps stay round. That is (22 / BUMP)^2 times
-- as many triangles: at BUMP 11, four times as many (500,000), which
-- takes longer to build and to draw.
local CELL, NX, NZ
local X0, Z0 = -ARENA_X / 2, -ARENA_Z / 2
local function setCells()
  CELL = CELL_SET or math.max(2, math.min(8, BUMP / 5.5))
  NX, NZ = math.floor(ARENA_X / CELL), math.floor(ARENA_Z / CELL)
end
setCells()

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
  local x, z = X0 + (i + 0.5) * CELL, Z0 + (j + 0.5) * CELL
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
  local t = 2 * (i * NZ + j)
  floor:setTriangleColor(t, r, g, b)
  floor:setTriangleColor(t + 1, clamp(r * 0.97), clamp(g * 0.97), clamp(b * 0.97))
end

local WALL_H, WALL_T = 20, 10

local function buildTerrain()
  setCells()
  floor = Terrain()
  for i = 0, NX - 1 do
    for j = 0, NZ - 1 do
      local xa, xb, za, zb = X0 + i * CELL, X0 + (i + 1) * CELL, Z0 + j * CELL, Z0 + (j + 1) * CELL
      floor:addTriangle(btVector3(xa, terrainHeight(xa, za), za), btVector3(xa, terrainHeight(xa, zb), zb), btVector3(xb, terrainHeight(xb, za), za))
      floor:addTriangle(btVector3(xb, terrainHeight(xb, za), za), btVector3(xa, terrainHeight(xa, zb), zb), btVector3(xb, terrainHeight(xb, zb), zb))
    end
  end
  floor:build()
  floor.col = "#5a7a32"
  floor.friction = 0.8
  addObject(floor)
  for i = 0, NX - 1 do
    for j = 0, NZ - 1 do paintCell(i, j, cellColour(i, j)) end
  end

  -- walls round the arena: low stone blocks
  for side = 0, 3 do
    -- (sides 0 and 2 run along x, at z = +-; 1 and 3 along z, at x = +-)
    local len = ((side % 2 == 0) and ARENA_X or ARENA_Z) + 2 * WALL_T
    local wall = Cube((side % 2 == 0) and len or WALL_T, WALL_H, (side % 2 == 0) and WALL_T or len, 0)
    local off = ((side % 2 == 0) and ARENA_Z or ARENA_X) / 2 + WALL_T / 2
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
-- stride: the length (along its heading) of its feet's path, at full
--   size, measured with its body held still in the air and its cranks
--   turned slowly (the mean over its feet). The scale is STRIDE /
--   stride. Measured the same way, every build's foot path matches
--   Walking_Linkages.lua's (and the linkage reference's) duty, lift and
--   flatness, except that the diag walkers' braces hold their legs at a
--   slightly different angle (Chebyshev diag: lift 13% against 16%;
--   Chebyshev-Spears diag: 23-25% against 26%).
-- chassis: the build options that give it the room's chassis, so that
--   only its linkage differs from the others': body clearance CLEARANCE
--   (its body's lowest point above flat ground, walking), front-to-back
--   spacing BASE (between the middles of its front and back feet's
--   paths) and side-to-side width WIDTH (outer foot edge to outer foot
--   edge). linkageSpacing and cube_d are its own file's sliders;
--   bodyRaise is the room's own option (../Walkers_For_Room/), which
--   lengthens its pendants -- or, with no pendant, moves its body --
--   without changing its foot path. Worked out from measurements at
--   bodyRaise 0 and its default spacing and width; each of the three is
--   linear in its option. Jansen and Klann take CLEARANCE only (their
--   rows of legs can't come closer than about 1.8 strides without
--   colliding, and their width is fixed); the two 2-leg Spears, with a
--   single column of legs, keep their own chassis.
-- advance: how far it would go per crank turn if its feet never slipped
--   (cm, at the room's stride; measured with its body held still in the
--   air, cranks turned slowly and in step: at each moment its lowest foot
--   is the one standing, and the body moves as fast as that foot sweeps
--   back). Its crank speed is 2 pi FLAT_SPEED / advance, so that every
--   walker would cross flat ground at the same speed.
-- fixed: its own physics step; the room steps at FIXED, so its motors'
--   impulse (applied once per step) is scaled by FIXED / fixed
-- lift: how its build is told about the bumps -- "groundTop" (the
--   highest the ground gets) or "terrainLift" (how much to lift it)
-- forward: the direction it walks in its own frame (+1: +x, -1: -x)
-- opts: its standalone file's slider defaults (its crank speed, though,
--   is set by its advance: see addWalker)
-- solverIterations: its joints are solved with this many solver
--   iterations instead of the world's 10, as its standalone file does for
--   the whole world (v:setSolverIterations(40) -- its notes: at 10 its
--   rocking roughly doubles). Here it is set on its own joints only, so
--   the others keep the 10 their own files use.
-- railed: its body is held to move only along its own heading (the
--   balanced Spears' fix for a sideways drift); it turns only in right
--   angles, and the hold is put back along its new heading after each
-- ---------------------------------------------------------------------

-- wide: its chassis for WIDE (its body depth, giving a 38 cm stance)
-- look: how its body is marked, so each walker can be told at a glance
--   (see README.md, Telling the walkers apart): code is drawn on top
--   of its body -- its linkage's inventor(s) (J Jansen, K Klann, C
--   Chebyshev, H Hoecken, S Spears; "-S" a linkage Spears changed), then
--   its number of bars, S for a slider; colour is its linkage's; spears
--   puts a gold rim round its body; diag draws a line across it
local RED, PURPLE, BLUE, MAGENTA, WHITE, GOLD = "#D62828", "#7B2CBF", "#1F6FEB", "#E5007E", "#F2F2F2", "#FFC300"

local WALKERS = {
  { name = "Jansen", look = { code = "J 8", colour = RED, spears = false, diag = false }, wide = { cube_d = 150.563 }, advance = 25.308, parts = "Jansen_6Leg_parts.lua", stride = 67.908, chassis = { bodyRaise = -29.99, rowSpacing = 158.44, cube_d = 114.8 }, fixed = 1 / 240, lift = "groundTop", forward = -1,
    opts = { speed = 2.5, rows = 2, rowPhase = 0, sidePhase = 180, hingeCFM = 0 } },
  { name = "Klann", look = { code = "K 6", colour = PURPLE, spears = false, diag = false }, wide = { cube_d = 167.501 }, advance = 29.542, parts = "Klann_6Leg_parts.lua", stride = 70.619, chassis = { bodyRaise = 10.85, rowSpacing = 164.79, cube_d = 129.8 }, fixed = 1 / 240, lift = "groundTop", forward = 1,
    opts = { speed = 2.5, rows = 2, rowPhase = 0, sidePhase = 180, hingeCFM = 0 } },
  { name = "Chebyshev", look = { code = "C 4", colour = BLUE, spears = false, diag = false }, wide = { cube_d = 3.118 }, brace = { gap = 1.03 }, advance = 25.104, parts = "Chebyshev_normal_parts.lua", stride = 4.712, chassis = { bodyRaise = -0.368, linkageSpacing = 10.995, cube_d = 0.5 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 50, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Chebyshev diag", look = { code = "C 4", colour = BLUE, spears = false, diag = true }, wide = { cube_d = 8.082 }, brace = { gap = 1.51, diag = true }, advance = 20.003, parts = "Chebyshev_diag_parts.lua", stride = 5.827, chassis = { bodyRaise = 0.019, linkageSpacing = 13.596, cube_d = 5.029 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 140, linkageSpacing = 10, motorSpeed = 3.0 } },
  { name = "Chebyshev-Spears", look = { code = "C-S 4", colour = BLUE, spears = true, diag = false }, wide = { cube_d = 13.312 }, brace = { gap = 0.94 }, advance = 17.691, parts = "Chebyshev_Spears_normal_parts.lua", stride = 10.473, chassis = { bodyRaise = 3.226, linkageSpacing = 24.436, cube_d = 8.131 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180 } },
  { name = "Chebyshev-Spears diag", look = { code = "C-S 4", colour = BLUE, spears = true, diag = true }, wide = { cube_d = 10.520 }, brace = { gap = 1.45, diag = true }, advance = 16.374, parts = "Chebyshev_Spears_diag_parts.lua", stride = 11.558, chassis = { bodyRaise = 2.651, linkageSpacing = 26.969, cube_d = 5.209 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6 } },
  { name = "Hoecken 4-bar", look = { code = "H 4", colour = MAGENTA, spears = false, diag = false }, wide = { cube_d = 7.348 }, brace = { gap = 3.22 }, advance = 25.372, parts = "Hoecken_normal_parts.lua", stride = 5.505, chassis = { bodyRaise = 1.182, linkageSpacing = 12.845, cube_d = 4.419 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 10, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken slider", look = { code = "H 2S", colour = WHITE, spears = false, diag = false }, wide = { cube_d = 7.569 }, brace = { gap = 6.54 }, advance = 25.207, parts = "Hoecken_slider_parts.lua", stride = 8.378, chassis = { bodyRaise = 2.536, linkageSpacing = 19.549, cube_d = 2.0 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken-Spears slider", look = { code = "H-S 2S", colour = WHITE, spears = true, diag = false }, wide = { cube_d = 8.440 }, brace = { gap = 3.11 }, advance = 17.054, parts = "Hoecken_Spears_slider_parts.lua", stride = 8.727, chassis = { bodyRaise = 2.624, linkageSpacing = 20.363, cube_d = 3.656 }, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Spears 4-bar", look = { code = "S 4", colour = GOLD, spears = false, diag = false }, wide = { cube_d = 13.918 }, advance = 29.019, parts = "Spears_4Bar_4Leg_parts.lua", stride = 8.324, chassis = { bodyRaise = -9.240, linkageSpacing = 19.423, cube_d = 9.467 }, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, linkageSpacing = 20, speed = 2.6 } },
  -- (linkages of Chebyshev-Spears' kind, built by its file with other
  -- link lengths: see README.md)
  { name = "Hoecken-Spears 4-bar", look = { code = "H-S 4", colour = MAGENTA, spears = true, diag = false }, wide = { cube_d = 12.640 }, brace = { gap = 0.99 }, advance = 18.965, parts = "Chebyshev_Spears_normal_parts.lua", stride = 10.057, chassis = { bodyRaise = 3.099, linkageSpacing = 23.652, cube_d = 7.05 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180,
             geometry = { a = 1.875, g = 2.6138, h = 5.8331, leg = 5.8331, legAngle = 90, groundAngle = -45 } } },
  { name = "Hoecken-Spears long-stance", look = { code = "H-S 4L", colour = MAGENTA, spears = true, diag = false }, wide = { cube_d = 8.582 }, brace = { gap = 1.10 }, advance = 15.718, parts = "Chebyshev_Spears_normal_parts.lua", stride = 8.545, chassis = { bodyRaise = -0.727, linkageSpacing = 20.032, cube_d = 4.0 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180,
             geometry = { a = 1.875, g = 2.1842, h = 2.8129, leg = 2.8129, legAngle = 39.80, groundAngle = -20.14 } } },
  { name = "Spears 2-leg", look = { code = "S 4", colour = GOLD, spears = false, diag = false }, twoLeg = true, parts = "Spears_4Bar_2Leg_parts.lua", stride = 8.324, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8 } },
  { name = "Spears 2-leg balanced", look = { code = "S 4", colour = GOLD, spears = false, diag = false }, twoLeg = true, parts = "Spears_4Bar_2Leg_Balanced_parts.lua", stride = 8.335, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8, barLen = 13, tipMass = 70 }, railed = true, solverIterations = 40 },
}
-- EXTRA_WALKERS: more entries like these, added for experiments (set
-- before running this file)
for _, spec in ipairs(EXTRA_WALKERS or {}) do WALKERS[#WALKERS + 1] = spec end

-- the 2-leg Spears are left out unless TWO_LEGS is set (a side experiment:
-- two legs can't be compared fairly with four)
if not TWO_LEGS then
  for i = #WALKERS, 1, -1 do if WALKERS[i].twoLeg then table.remove(WALKERS, i) end end
end

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
room = { walkers = walkers, groundAt = terrainHeight }   -- (global, for tests and the command line)

-- ---------------------------------------------------------------------
-- marking the bodies (spec.look): the body and its braces painted its
-- linkage's colour (the rest of the walker in plain greys),
-- a gold rim round its top edges for a linkage Spears changed, a line
-- across it for a diag build, and its code in raised letters on top.
-- These are for looks only: bodies that touch nothing and weigh nothing,
-- moved with the walker's body every time the room is drawn.
-- ---------------------------------------------------------------------

local CF_KINEMATIC_OBJECT, CF_NO_CONTACT_RESPONSE = 2, 4

-- black or white, whichever reads better on the colour c ("#rrggbb")
local function codeOf(spec) return spec.look and (spec.look.code .. ", ") or "" end

local function ink(c)
  local r, g, b = tonumber(c:sub(2, 3), 16) / 255, tonumber(c:sub(4, 5), 16) / 255, tonumber(c:sub(6, 7), 16) / 255
  return (0.2126 * r + 0.7152 * g + 0.0722 * b > 0.5) and "#111111" or "#FFFFFF"
end

-- a look-only part of a walker's marking, at (x, y, z) in its body's own
-- frame, turned by the quaternion q (x, y, z, w)
local function decor(w, o, col, x, y, z, q)
  o.col = col
  addObject(o)
  o.body:setCollisionFlags(CF_KINEMATIC_OBJECT + CF_NO_CONTACT_RESPONSE)
  w.decor[#w.decor + 1] = { o = o, p = { x, y, z }, q = q or { 0, 0, 0, 1 } }
end

local function markBody(w, look)
  w.decor = {}
  if not look then return end
  w.cube.col = look.colour
  -- its braces (the plates and bars between its legs) in its colour too,
  -- everything else in plain greys, so the walker's colours stand out
  for _, o in ipairs(w.bodies) do
    if not rawequal(o, w.cube) then
      local by = w.madeBy and w.madeBy[o] or ""
      if by:find("Crossbar") then o.col = look.colour
      elseif by == "buildFoot" then o.col = "#3C3C3C"
      else o.col = "#6A6A6A" end
    end
  end
  -- the body's size, from its box as built (still lined up with its axes)
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  w.cube.body:getAabb(lo, hi)
  local m = 0.04                                   -- (the box's collision margin)
  local X, H, Z = hi.x - lo.x - 2 * m, hi.y - lo.y - 2 * m, hi.z - lo.z - 2 * m
  local hy = H / 2
  local e = 0.05                                   -- standing just proud of the body, so it shows
  local top = hy + e
  if look.spears then
    -- the gold rim: four strips round the top edges, part way down the sides
    local r, k = math.max(0.2 * math.min(X, Z), 0.8), math.max(0.6 * H, 0.8)
    for _, sz in ipairs({ -1, 1 }) do
      decor(w, Cube(X + 2 * e, k, r, 0), GOLD, 0, top - k / 2, sz * (Z / 2 + e - r / 2))
    end
    for _, sx in ipairs({ -1, 1 }) do
      decor(w, Cube(r, k, Z + 2 * e, 0), GOLD, sx * (X / 2 + e - r / 2), top - k / 2, 0)
    end
  end
  if look.diag then
    -- a line from corner to corner across the top
    local a = math.atan(Z / X)
    local L = 0.94 * math.sqrt(X * X + Z * Z)
    decor(w, Cube(L, 0.15, math.max(0.1 * math.min(X, Z), 0.6), 0), ink(look.colour), 0, top + 0.08, 0,
          { 0, math.sin(-a / 2), 0, math.cos(-a / 2) })
  end
  -- the code, in raised letters lying on the top, reading along the walk
  local size = math.min(0.42 * Z, 0.8 * X / (0.62 * #look.code))
  local text = OpenSCAD(string.format(
    [[linear_extrude(height = 0.3) text("%s", size = %.3f, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");]],
    look.code, size), 0, false)
  local c = math.sqrt(0.5)
  decor(w, text, ink(look.colour), 0, top + 0.1, 0, { -c, 0, 0, c })   -- (turned so the letters face up)
end

-- each marking part to where the body now is
local function placeMarks(w)
  if not w.decor or #w.decor == 0 then return end
  local t = w.cube.body:getCenterOfMassTransform()
  local p, q = w.cube.body:getCenterOfMassPosition(), t:getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  for _, d in ipairs(w.decor) do
    local dx, dy, dz = qrot(qx, qy, qz, qw, d.p[1], d.p[2], d.p[3])
    local rx, ry, rz, rw = qmul(qx, qy, qz, qw, d.q[1], d.q[2], d.q[3], d.q[4])
    d.o.trans = btTransform(btQuaternion(rx, ry, rz, rw), btVector3(p.x + dx, p.y + dy, p.z + dz))
  end
end

local function addWalker(spec, x, z, heading)
  local W = dofile(WALKERS_DIR .. spec.parts)
  local scale = STRIDE / spec.stride
  local w = { spec = spec, scale = scale, bodies = {}, constraints = {} }
  local opts = {}
  for k, val in pairs(spec.opts) do opts[k] = val end
  -- its chassis for the room (see `chassis` above); CHASSIS_TEST, for
  -- tests, overrides it
  for k, val in pairs(spec.chassis or {}) do opts[k] = val end
  if WIDE then for k, val in pairs(spec.wide or {}) do opts[k] = val end end
  for k, val in pairs(CHASSIS_TEST or {}) do opts[k] = val end
  if SAME_FEET then opts.foot = FOOT end
  if BRACE_CLEARANCE and spec.brace then
    local d = math.max(0, BRACE_CLEARANCE - spec.brace.gap)
    if spec.brace.diag then opts.braceRaise = d else opts.braceCut = d end
  end
  opts.ankle = ANKLES
  local unbraced = UNBRACED == true or (type(UNBRACED) == "table" and UNBRACED[spec.name])
  if unbraced then opts.noBraces = true; opts.legGuides = true end
  if GAIT and (spec.opts.rows or spec.parts:find("Spears_4Bar_4Leg") or unbraced) then opts.phases = GAIT end
  -- the room's crank speed (each walker names it its own way)
  local crank = CRANK or (spec.advance and 2 * math.pi * FLAT_SPEED / spec.advance) or 2.6
  local rev = REVERSE == true or (type(REVERSE) == "table" and REVERSE[spec.name])
  if rev then crank = -crank end
  w.crank = crank
  w.forward = rev and -spec.forward or spec.forward   -- which way along its body it walks
  for _, k in ipairs({ "speed", "leftSpeed", "rightSpeed", "motorSpeed" }) do
    if opts[k] then opts[k] = crank end
  end
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
  -- gravity: the same for every walker. Each standalone file uses 9.8
  -- units/s^2, but the walkers are built at very different sizes in
  -- those units (hips from about 4 units high to about 92), so scaling
  -- each one's gravity with it left them under gravities from 1.3 cm/s^2
  -- (Jansen) to 30 (Chebyshev-Spears) -- Klann, at 1.9, floated off the
  -- ground for seconds at a time. Even at 20 (Walker Room1), the
  -- walkers whose feet lift most (Klann, Chebyshev-Spears, Hoecken-Spears
  -- slider) had no foot on the ground 17-31% of the time: a small push
  -- up kept them in the air for a long time. At 70 none is off the ground
  -- more than 2% of the time; much higher (200 and more), most walkers
  -- stall. Its motors are made stronger (or weaker) by the same factor
  -- as its gravity, so each can still lift itself as on its own.
  w.gravityFactor = GRAVITY / (9.8 * scale)
  opts.impulseScale = FIXED / spec.fixed * w.gravityFactor
  opts[spec.lift] = AMP                  -- the room's bumps reach AMP above 0
  -- its crank motors, as its build makes them (for lockCranks)
  w.motors = {}
  W.onMotor = function(h, speed, impulse)
    w.motors[#w.motors + 1] = { hinge = h, speed = speed, impulse = impulse, sign = (speed < 0) and -1 or 1 }
  end
  -- (noting which bodies are braces and feet, for marking the walker
  -- below: the builds make them in functions named for them)
  local made, realCube = {}, Cube
  Cube = function(...)
    local o = realCube(...)
    local f = debug.getinfo(2, "n")
    made[o] = f and f.name
    return o
  end
  local ok, built = pcall(W.build, opts)
  Cube = realCube
  if not ok then error(built, 0) end
  w.madeBy = made
  -- a diag walker's low brace, raised (BRACE_CLEARANCE), would cross the
  -- circles its own cranks turn in and jam on them: it passes the
  -- walker's other parts as if built in a plane of its own (a free joint,
  -- holding nothing, to each of them turns off contact between the pair),
  -- and still meets the ground
  if BRACE_CLEARANCE and spec.brace and spec.brace.diag then
    local I = btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))
    for _, o in ipairs(w.bodies) do
      if made[o] == "buildDiagonalCrossbar" then
        for _, p in ipairs(w.bodies) do
          if not rawequal(p, o) then
            local free = btGeneric6DofConstraint(o.body, p.body, I, I, true)
            free:setLinearLowerLimit(btVector3(1, 1, 1)); free:setLinearUpperLimit(btVector3(-1, -1, -1))
            free:setAngularLowerLimit(btVector3(1, 1, 1)); free:setAngularUpperLimit(btVector3(-1, -1, -1))
            opts.addConstraint(free)
          end
        end
      end
    end
  end
  for _, m in ipairs(w.motors) do m.last = m.hinge:getHingeAngle(); m.turned = 0 end
  -- the same motors for every walker (MOTOR_STRENGTH, above): Bullet
  -- applies a motor's impulse once per physics step, so its most torque
  -- is impulse / FIXED
  if MOTOR_STRENGTH and #w.motors > 0 then
    local torque = MOTOR_STRENGTH * TOTAL_MASS * GRAVITY * STRIDE / #w.motors
    for _, m in ipairs(w.motors) do
      m.impulse = torque * FIXED
      m.hinge:enableAngularMotor(true, m.speed, m.impulse)
    end
  end
  if SOLVER_ITERATIONS or spec.solverIterations then
    for _, con in ipairs(w.constraints) do con:setOverrideNumSolverIterations(SOLVER_ITERATIONS or spec.solverIterations) end
  end
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
  -- the same body for every walker (SAME_BODY, above)
  if SAME_BODY then
    local rest = 0
    for _, o in ipairs(w.bodies) do if o.mass > 0 and not rawequal(o, w.cube) then rest = rest + o.mass end end
    local m = TOTAL_MASS - rest
    assert(m > 0, spec.name .. ": TOTAL_MASS is less than its legs weigh")
    local x, y, z = BODY_BOX[1], BODY_BOX[2], BODY_BOX[3]
    w.cube.body:setMassProps(m, btVector3(m / 12 * (y * y + z * z), m / 12 * (x * x + z * z), m / 12 * (x * x + y * y)))
    w.cube.body:updateInertiaTensor()
    w.cube.mass = m
    w.bodyMass = m
  end
  -- its gravity, on its moving bodies only
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 then o.body:setGravity(btVector3(0, -GRAVITY, 0)) end
  end
  -- its floor (FLOOR_TOP_Y, its own units) onto the room's (0), then to
  -- its spot, turned to its heading (0: walking along +x)
  local cp = w.cube.body:getCenterOfMassPosition()
  local cx, cz = cp.x, cp.z
  local yaw0 = (w.forward > 0) and 0 or math.pi
  if MARKS then markBody(w, spec.look) end
  moveWalker(w, cx, cz, heading - yaw0, x - cx, -(W.FLOOR_TOP_Y or 0) * scale, z - cz)
  if MARKS then placeMarks(w) end
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

-- spots: a grid 4 across, as many rows deep as it takes, filling the arena, the walkers in list order
local COLS = 4
local ROWS = math.ceil(#WALKERS / COLS)
local function buildWalkers()
  rngState = SEED
  local n = 0
  for _, spec in ipairs(WALKERS) do
    if ONLY == nil or spec.name == ONLY then
      local col, row = n % COLS, math.floor(n / COLS)
      local x = ONLY and 0 or (X0 + (col + 0.5) * ARENA_X / COLS)
      local z = ONLY and 0 or (Z0 + (row + 0.5) * ARENA_Z / ROWS)
      local heading = ONLY and 0 or random() * 2 * math.pi
      if TEST_TRACK then
        -- (near the -x end, facing +x; moved up to a bump length along
        -- and across by SEED, so each seed meets the bumps differently)
        x = X0 + 60 + random() * BUMP
        z = (random() - 0.5) * BUMP
        heading = 0
      end
      -- (a railed walker starts along an axis: see `railed` above)
      if spec.railed and not TEST_TRACK then heading = math.floor(random() * 4) * math.pi / 2 end
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
  local f = w.forward
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

local GAP = 40              -- about one body length, cm
local AHEAD = math.rad(60)  -- "in front": within this of straight ahead
local COOLDOWN = 2.0        -- s after a turn ends before it looks again
local CANDIDATES = 12       -- new headings tried per turn
local WALL_X, WALL_Z = ARENA_X / 2, ARENA_Z / 2   -- the walls' inner faces are at x = +-WALL_X, z = +-WALL_Z

local function angleDiff(a, b)       -- a - b, wrapped to (-pi, pi]
  local d = (a - b) % (2 * math.pi)
  if d > math.pi then d = d - 2 * math.pi end
  return d
end

-- how bad heading h would be for walker w at (x, z): the closer what lies
-- that way, the worse
-- how close walkers w (at x, z, moving at vx, vz cm/s) and o will come,
-- edge to edge, over the next PREDICT seconds if both keep their present
-- velocities (o's from its last half second), and when
local PREDICT = 4.0
local function closest(w, x, z, vx, vz, o)
  local ox, _, oz = getPosXYZ(o.cube)
  local rx, rz = ox - x, oz - z
  local ux, uz = (o.vx or 0) - vx, (o.vz or 0) - vz
  local uu = ux * ux + uz * uz
  local t = 0
  if uu > 1e-6 then t = math.max(0, math.min(PREDICT, -(rx * ux + rz * uz) / uu)) end
  local cx, cz = rx + ux * t, rz + uz * t
  return math.sqrt(cx * cx + cz * cz) - w.radius - o.radius, t
end

local function badness(w, x, z, h)
  local fx, fz = math.cos(h), -math.sin(h)
  local bad = 0
  -- walls: the distance to the wall along h, if it is near
  local reach = 4 * GAP
  local dist = 1e30
  if fx > 1e-6 then dist = math.min(dist, (WALL_X - w.radius - x) / fx) end
  if fx < -1e-6 then dist = math.min(dist, (-WALL_X + w.radius - x) / fx) end
  if fz > 1e-6 then dist = math.min(dist, (WALL_Z - w.radius - z) / fz) end
  if fz < -1e-6 then dist = math.min(dist, (-WALL_Z + w.radius - z) / fz) end
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
      -- and how close they'd come with w travelling along h at its
      -- present speed (a crossing path, from any side)
      if gap < reach and w.vx then
        local sp = math.max(math.sqrt(w.vx * w.vx + w.vz * w.vz), 1)
        local g = closest(w, x, z, sp * fx, sp * fz, o)
        if g < GAP then bad = bad + 2 * (GAP - math.max(g, 0)) / GAP end
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
  for _, wall in ipairs({ { WALL_X - x, fx }, { WALL_X + x, -fx }, { WALL_Z - z, fz }, { WALL_Z + z, -fz } }) do
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

-- the way a walker actually travels, which isn't always the way it
-- faces: some walk sideways or backwards part of the time (Klann, and
-- Chebyshev-Spears diag after some turns, among others). Each walker
-- keeps a running average of the angle between the two (in its own
-- frame, so it carries over through a turn), updated each half second
-- it isn't turning, and avoidance steers by facing + that angle: a
-- walker that travels backwards turns to face what it should get away
-- from. (A walker that hardly moves, or moves every which way, keeps
-- steering by the way it faces.)
local function noteTravel(w, dx, dz)
  if w.turnLeft or dx * dx + dz * dz < 0.09 then return end   -- (turning, or under 0.3 cm in half a second)
  local off = angleDiff(math.atan2(-dz, dx), heading(w))
  local a = 0.2
  w.offC = (w.offC or 1) * (1 - a) + math.cos(off) * a
  w.offS = (w.offS or 0) * (1 - a) + math.sin(off) * a
end
local function travel(w)
  local c, s = w.offC or 1, w.offS or 0
  if c * c + s * s < 0.09 then return heading(w) end       -- (no clear direction yet)
  return heading(w) + math.atan2(s, c)
end
room.travel = travel

-- a near miss: another walker less than GAP / 4 away and closer than it
-- was half a second ago -- checked even in a walker's calm spell after a
-- turn, so two walkers can't close in on each other while neither looks
local function nearMiss(w, x, z)
  local last = w.track and w.track[#w.track]
  if not last then return nil end
  for _, o in ipairs(walkers) do
    if o ~= w and w.vx then
      local g, t = closest(w, x, z, w.vx, w.vz, o)
      if g < GAP / 4 and t > 0 and t < 2 then return o end
    end
    if o ~= w and o.track and o.track[#o.track] then
      local ox, _, oz = getPosXYZ(o.cube)
      local d = math.sqrt((ox - x) ^ 2 + (oz - z) ^ 2)
      if d - w.radius - o.radius < GAP / 4 then
        local ol = o.track[#o.track]
        local d0 = math.sqrt((ol[1] - last[1]) ^ 2 + (ol[2] - last[2]) ^ 2)
        if d < d0 - 0.2 then return o end
      end
    end
  end
end

local function blocked(w, x, z, h)
  local what = blockedAlong(w, x, z, h)
  if what then return what end
  -- a walker on a crossing path, from any side: both keep their present
  -- velocities and they'd come within GAP / 2
  if w.vx then
    for _, o in ipairs(walkers) do
      if o ~= w then
        local g, t = closest(w, x, z, w.vx, w.vz, o)
        if g < GAP / 2 and t > 0 then return o end
      end
    end
  end
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
local PROGRESS_EVERY = 300  -- frames between the samples its distance gone is summed over (5 s)

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
  { "navy", 20, 30, 110 }, { "olive", 128, 128, 0 },
}
local painted = {}          -- [cell] = the walker whose trail is on it

local function cellAt(x, z)
  local i, j = math.floor((x - X0) / CELL), math.floor((z - Z0) / CELL)
  if i < 0 or i >= NX or j < 0 or j >= NZ then return nil end
  return i * NZ + j, i, j
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
    local i, j = math.floor(cell / NZ), cell % NZ
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
v:addParam("BumpLength", BUMP, BUMP_MIN, BUMP_MAX, 0.5, "bump length, cm (the stride is 15; the room is built again when you let go)")
buildRoom()

-- ---------------------------------------------------------------------
-- keeping a walker's cranks in step. Each crank has its own motor in most
-- builds, and nothing else keeps them in step: over a minute or two their
-- legs drift out of the timing they were built with (Klann's within half
-- a minute, into walking back and forth). Here, every frame, each motor's
-- speed is nudged by how far its crank has got ahead of or behind the
-- average of the walker's cranks (since it was built): LOCK_GAIN rad/s
-- for each radian, up to LOCK_MAX rad/s. Their average still turns as the
-- load lets it, at up to its crank speed; only their timing is held, as a gear
-- train from one motor would hold it. (The 2-leg Spears' legs share one
-- crank, so there is nothing to hold.)
-- ---------------------------------------------------------------------

local LOCK_GAIN, LOCK_MAX = 4, 1.5

local function lockCranks(w)
  local n = #w.motors
  if n < 2 then return end
  local sum = 0
  for _, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    local d = a - m.last
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    m.turned, m.last = m.turned + d * m.sign, a
    sum = sum + m.turned
  end
  local mean = sum / n
  for _, m in ipairs(w.motors) do
    local nudge = math.max(-LOCK_MAX, math.min(LOCK_MAX, LOCK_GAIN * (mean - m.turned)))
    m.hinge:enableAngularMotor(true, m.speed + m.sign * nudge, m.impulse)
  end
end

v:preSim(function(N)
  simTime = simTime + FRAME
  for k, w in ipairs(walkers) do
    if LOCK_CRANKS then lockCranks(w) end
    if TURN_TEST then
      -- (a test: every walker turns 90 degrees to the left every 10 s)
      if not w.turnLeft and simTime >= (w.nextTest or 10) then
        startTurn(w, math.pi / 2)
        w.nextTest = (w.nextTest or 10) + 10
      end
    elseif not TEST_TRACK and not w.turnLeft then
      local x, _, z = getPosXYZ(w.cube)
      local h = travel(w)
      local what
      if simTime >= (w.calmUntil or 0) then what = blocked(w, x, z, h) else what = nearMiss(w, x, z) end
      if what then
        local turn = chooseTurn(w, x, z, h)
        startTurn(w, turn)
        w.calmUntil = simTime + TURN_TIME + COOLDOWN
        room.turns[#room.turns + 1] = { simTime, w.spec.name, (what == "wall") and "wall" or what.spec.name, math.deg(turn) }
        w.turns = (w.turns or 0) + 1
      end
    end
    -- (how far it has gone: in 5 s steps, so rocking in place, back and
    -- forth within a step, doesn't count as getting anywhere)
    if N % PROGRESS_EVERY == 0 then
      local x, _, z = getPosXYZ(w.cube)
      if w.p5 then
        w.travelled = w.travelled + math.sqrt((x - w.p5[1]) ^ 2 + (z - w.p5[2]) ^ 2)
        w.p5[1], w.p5[2] = x, z
      else
        w.p5 = { x, z }
      end
    end
    -- (where it was half a second and a second ago: its actual motion)
    if N % TRACK_EVERY == 0 then
      local x, _, z = getPosXYZ(w.cube)
      w.track = w.track or {}
      local last = w.track[#w.track]
      if last then
        noteTravel(w, x - last[1], z - last[2])
        w.vx, w.vz = (x - last[1]) / (TRACK_EVERY * FRAME), (z - last[2]) / (TRACK_EVERY * FRAME)
      end
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
    -- (the test track: how far it got along x, reported once)
    if TEST_TRACK then
      local x, _, z = getPosXYZ(w.cube)
      if not w.trackStart then w.trackStart = { x, z, simTime } end
      if not w.trackDone and simTime - w.trackStart[3] >= TRACK_SECS then
        w.trackDone = true
        local d = x - w.trackStart[1]
        print(string.format("TRACK %s|height %.2f|length %.1f|seed %d|forward %.1f cm|%.2f cm/s|sideways %.1f cm|stood up %d",
          w.spec.name, AMP, BUMP, SEED, d, d / TRACK_SECS, z - w.trackStart[2], w.stoodUp or 0))
      end
    end
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
  if TEST_TRACK then
    local h = "TEST TRACK -- " .. (walkers[1] and (walkers[1].spec.name .. " (" .. (walkers[1].spec.look and walkers[1].spec.look.code or "") .. ")") or "") .. "\n\n"
    h = h .. "Tab         put the next walker on the track (built again)\n"
    h = h .. "Shift+Tab   the one before\n"
    h = h .. "O           look over the whole track\n"
    h = h .. "Mouse       turn and zoom the view (it keeps following)\n\n"
    h = h .. "It walks straight for " .. TRACK_SECS .. " s, then prints how far it got (the\n"
    h = h .. "output pane), and carries on. TerrainHeight and BumpLength (Params\n"
    h = h .. "pane) build the track again with the same walker.\n"
    return h
  end
  local h = "WALKER ROOM -- " .. (following and ("following " .. following.spec.name .. " (" .. codeOf(following.spec) .. "trail " .. following.colour[1] .. ")")
                                           or "looking over the room") .. "\n\n"
  h = h .. "Tab         follow the next walker\n"
  h = h .. "Shift+Tab   follow the one before\n"
  h = h .. "O           look over the whole room\n"
  h = h .. "T           clear the trails\n"
  h = h .. "Mouse       turn and zoom the view (it keeps following)\n\n"
  h = h .. "Rest the pointer on a walker, or on a trail, to see whose it is,\n"
  h = h .. "how far it has gone, its average speed, and how often it has turned\nor been stood up.\n\n"
  h = h .. "TerrainHeight (Params pane): how high the bumps are, 0 to " .. AMP_MAX .. " cm.\n"
  h = h .. "BumpLength: how long they are, " .. BUMP_MIN .. " to " .. BUMP_MAX .. " cm (every walker's stride is " .. STRIDE .. " cm).\n"
  h = h .. "The room is built again, every walker back at its start, when you let go.\n\n"
  h = h .. "Each body shows its walker's code: its linkage's inventor(s) -- J Jansen,\n"
  h = h .. "K Klann, C Chebyshev, H Hoecken, S Spears; -S: a linkage Spears changed,\n"
  h = h .. "which also has a gold rim -- then its number of bars, S if a slider. A\n"
  h = h .. "line across the body: a diag build. The colour is the linkage's.\n\n"
  h = h .. "Walkers and their trails:\n"
  for _, w in ipairs(walkers) do
    h = h .. string.format("  %-7s %-27s %s\n", w.spec.look and w.spec.look.code or "", w.spec.name, w.colour[1])
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

-- on the test track, Tab and Shift+Tab put the next (or the one before)
-- walker on the track instead: the track is built again with it
local function trackNext(step)
  local k = 1
  for i, spec in ipairs(WALKERS) do if spec.name == ONLY then k = i end end
  k = (k - 1 + step) % #WALKERS + 1
  ONLY = WALKERS[k].name
  teardownRoom()
  buildRoom()
  follow(walkers[1])
  print("test track: " .. ONLY)
end

v:onKey(function(N, key, down)
  if TEST_TRACK and (key == "Tab" or key == "Backtab") then
    if down then trackNext(key == "Tab" and 1 or -1) end
    return true
  end
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
    first = w.spec.name .. " (" .. codeOf(w.spec) .. "trail " .. w.colour[1] .. ")"
  elseif rawequal(obj, floor) then
    local cell = cellAt(x, z)
    w = cell and painted[cell]
    first = w and ("the " .. w.colour[1] .. " trail of " .. w.spec.name)
  end
  if not w then return nil end
  return string.format("%s\nhas gone %.0f cm in %.0f s (%.1f cm/s)\nturned %d times, stood up %d times",
    first, w.travelled, simTime, w.travelled / math.max(simTime, 1e-9), w.turns or 0, w.stoodUp or 0)
end)

-- the TerrainHeight and BumpLength sliders: the room is built again
-- once a slider has stayed put for a moment (a drag sends every value it
-- passes through, and each build takes a second or more)
local pendingAmp, pendingBump, pendingAt, draws = nil, nil, 0, 0
v:onParamChanged(function(N, name, value)
  if name == "TerrainHeight" then pendingAmp, pendingAt = value, draws end
  if name == "BumpLength" then pendingBump, pendingAt = value, draws end
end)
v:preDraw(function(N)
  draws = draws + 1
  if MARKS then for _, w in ipairs(walkers) do placeMarks(w) end end
  if (pendingAmp or pendingBump) and draws - pendingAt >= 20 then
    local amp, bump = pendingAmp or AMP, pendingBump or BUMP
    if math.abs(amp - AMP) > 1e-9 or math.abs(bump - BUMP) > 1e-9 then
      AMP, BUMP = amp, bump
      teardownRoom()
      buildRoom()
      local k = following and following.index
      follow(k and walkers[k] or nil)
      print(string.format("TerrainHeight = %.1f cm, BumpLength = %.1f cm (room built again)", AMP, BUMP))
    end
    pendingAmp, pendingBump = nil, nil
  end
end)

follow(TEST_TRACK and walkers[1] or nil)
