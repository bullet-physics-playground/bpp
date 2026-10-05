--
-- Direct port of the original four-legged walker (cheby_normal6.lua),
-- with the Chebyshev Lambda linkage swapped for Chebyshev-Spears.
-- Every STRUCTURAL relationship is identical to the original: same
-- front/back pairing, same hinge topology, same crossbar mechanics.
-- Only the linkage's own geometry (lengths, ground angle, coupler
-- shape) and the resulting coordinates changed. (Bracing was originally
-- two crossbars per pair, one above and one below via attach_height --
-- that turned out to be an over-constrained weld setup and is now one
-- taller bar per pair instead; see the buildCrossbar section for why.)
--
-- CHEBYSHEV-SPEARS LINKAGE: crank=36, ground=48, coupler=rocker=leg=
-- 110, ground_angle=45 from linkage.lua's compute_chebyshev_spears,
-- scaled by 2.5/48 so ground stays at the original file's g_len=2.5.
-- The coupler is bent 90 degrees at its midpoint (M), rather than being
-- one straight rod. It is now ONE fused rigid body (`coupler`, covering
-- A->M) carrying the combined mass of both halves, with B's hinge pivot
-- placed at a fixed local offset that encodes the bend -- see
-- buildLinkage's comment for why (an earlier two-body version, joined
-- by a weld at the SAME point as the coupler<->rocker hinge, was
-- over-constrained and produced visible jitter/wobble under motor
-- torque). A second, massless-ish `couplerVis` body is welded on at a
-- different point purely to render the bend's second segment; it
-- carries no other constraint and can't destabilize anything. The
-- whole assembly is flipped across the x-axis so the legs point up,
-- above the cube, instead of down.
--
-- Ground link  g = 2.5    -- O2 -> O4, tilted 45 degrees
-- Crank        a = 1.875  -- O2 -> A
-- Coupler      f = 11.458 -- A  -> B, with midpoint M (AM = MB = 5.729, matching rocker)
-- Rocker       h = 5.729  -- M  -> O4
-- Pendant      p = 5.729  -- B  -> C, hinged and hanging free (no motor)
--
-- PAIRING: linkage1 (front, x=-5) and linkage2 (front, x=+5) share
-- mirror=false and phase=0 -- identical geometry, just translated, so
-- their pendants always stay a fixed distance apart with zero relative
-- rotation, exactly like the original. linkage3/linkage4 are the same
-- pair mirrored onto the back face (mirror=true), phase=180. Front and
-- back never need to worry about each other: they're on opposite Z
-- half-spaces the whole time, same as the original.
--
-- CROSSBARS: buildCrossbar welds (not hinges) ONE rigid bar per pair
-- between the two pendants -- flat, axis-aligned rod, using ONE
-- pendant's orientation (read via getRotation(), never decomposed or
-- recomputed) for both weld frames, since both ends share identical
-- orientation by construction. This used to be two separate crossbars
-- per pair (near the top of the pendant and near the bottom); that was
-- an over-constrained pair of independent full welds onto the same two
-- pendants, and is now one bar tall enough to span that same range --
-- see the buildCrossbar section further down for the full reasoning.
--
-- Gravity is off and there's no floor -- consistent with recent
-- testing state; flip back on when ready to test full dynamics.
--

v.timeStep = 1/10
v.fixedTimeStep = 1/480

-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- GUI sliders. All seven apply live, no Restart needed -- Restart
-- Simulation wipes v's own param table and reruns this script from its
-- literal hardcoded defaults (checked the actual BPP source,
-- Viewer::restartSim -> parse(_scriptContent) -> Viewer::clear() ->
-- _params.clear()), so it can't preserve a dragged value either way.
-- maxSubSteps, "Left Speed" and "Right Speed" are applied in place via
-- v:onParamChanged (plus a redundant per-tick re-apply in the v:preSim
-- hook near the bottom, shared with the trail-marker code -- this
-- engine only allows one v:preSim and one v:onParamChanged
-- registration each, so everything for both funnels through those two
-- single callbacks). "Left Speed" drives linkage1/linkage2 (what this
-- file calls the front legs); "Right Speed" drives linkage3/linkage4
-- (the back legs) -- two independent motors instead of one shared
-- speed. cube_d, cubeMass, terrainAmp and linkageSpacing instead tear
-- down and rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene(), also from v:onParamChanged -- see that
-- registration, right after buildScene()'s definition further down,
-- for the full picture. Since a rebuild snaps the walker back to its
-- starting position, that same handler also clears the red centroid-
-- trail markers (clearTrail(), defined next to the trail-marker code
-- near the bottom) so an old trail from before the rebuild doesn't
-- linger and misrepresent where the walker has actually been since.
-- ---------------------------------------------------------------------
local PARAM_INFO = {
  maxSubSteps = { min = 1,   max = 2000, step = 1,
                  comment = "Bullet max substeps per tick (live)" },
  ["Left Speed"]  = { min = 0,   max = 8,   step = 0.1,
                  comment = "front hip hinge motor target angular speed, linkage1/2 (live)" },
  ["Right Speed"] = { min = 0,   max = 8,   step = 0.1,
                  comment = "back hip hinge motor target angular speed, linkage3/4 (live)" },
  cube_d      = { min = 1,   max = 10,  step = 0.1,
                  comment = "cube's own depth / Z (rebuilds the scene)" },
  cubeMass    = { min = 1,   max = 200, step = 1,
                  comment = "cube body mass (rebuilds the scene)" },
  terrainAmp  = { min = 0,   max = 3,   step = 0.05,
                  comment = "terrain bump height (rebuilds the scene)" },
  linkageSpacing = { min = 5,   max = 30,  step = 0.5,
                  comment = "distance between the two leg mounts on each face (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("maxSubSteps", 20)
setParam("Left Speed", 2.6)
setParam("Right Speed", 2.6)
setParam("cube_d", 4.5)
setParam("cubeMass", 7.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 10)

v.maxSubSteps = v:getParam("maxSubSteps")

local g_len, a_len, h_len, p_len = 2.5, 36*2.5/48, 110*2.5/48, 110*2.5/48
local f_len = 2*h_len   -- AM = MB = h_len -- keeps the Grashof relation intact
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.4                     -- spacing between staggered planes

-- MASS: every link here is longer than its counterpart in the original
-- file (crank 1.0->1.875, rocker/coupler-half 2.5/5.0->5.729, pendant
-- 10.0->9.73-ish once ext_down is folded in), but the masses were
-- carried over unchanged -- which quietly makes each part LESS dense
-- than the original built it at, and a long, underweight rod is more
-- prone to whipping around under the same motor torque. These are the
-- original's own mass/length ratios (0.3/1.0 crank, 0.6/5.0 coupler,
-- 0.3/2.5 rocker, 1.0/10.0 pendant), reapplied to this file's actual
-- (longer) lengths, so each part keeps its original density instead of
-- being scaled up in size only.
local density_crank, density_coupler, density_rocker, density_pendant =
      0.3, 0.12, 0.12, 0.1
local mass_crank = density_crank * a_len          -- 0.5625
local mass_couplerHalf = density_coupler * (f_len/2)  -- 0.6875 each; combined into one fused coupler body below
local mass_rocker = density_rocker * h_len        -- 0.6875

-- STABILITY: the feet are the actual support base -- the lowest points
-- of the whole mechanism, and the ones the walker's weight actually
-- rests on. Doubling their mass (from the original 1.2) pulls the
-- system's overall center of mass measurably lower relative to that
-- support base -- COM height above the floor drops from ~7.01 to
-- ~6.41 units at construction pose -- without touching the cube's own
-- mass, which stays coupled to motor torque/reaction-inertia behavior
-- elsewhere in the file.
local mass_foot = 0.1 -- 2.4   -- was 1.2

-- rocker shares the crank's plane (both z_crank) instead of getting its
-- own slot -- one fewer distinct plane, and the coupler/pendant/crossbar
-- slots shift in by one gap to fill the space that opens up.
local EXT_DOWN = 4.0   -- how far each pendant extends below its original bottom (C)
-- ---------------------------------------------------------------------
-- DAMPING TUNING: linear/angular damping bleeds off kinetic energy each
-- step (a body's velocity is scaled down by roughly (1-damp) per
-- second, independent of any constraint), which is a different lever
-- from the crossbar welds' erp/cfm (further down, in buildCrossbar) --
-- those soften how hard ONE constraint corrects positional error;
-- damping instead drains energy from a body's OWN motion regardless of
-- which constraint (if any) is driving it. Useful against exactly the
-- kind of "sequential joints accumulate error, solver throws in a
-- corrective impulse, chain of hinges amplifies it" wobble described
-- for impulse-based solvers generally.
--
-- 0.0 = no damping (Bullet's own default). Values are "per second"
-- rates, not per-step -- 0.1-0.3 is a mild-to-moderate everyday range;
-- above ~0.5 starts to visibly slow the body down, not just smooth it.
-- pendant/crossbar already had hand-tuned damp_ang values from earlier
-- in this thread (0.5, 0.15) -- kept as their defaults below rather
-- than reset.
--
-- Each pair is (linear, angular). Change these and re-run -- nothing
-- else in the file needs touching.

--local DAMP_CUBE      = {lin = 0.3, ang = 0.3}
--local DAMP_CRANK     = {lin = 0.3, ang = 0.3}
--local DAMP_COUPLER   = {lin = 0.3, ang = 0.30}   -- coupler + couplerVis: the newest/least-tested body, given a bit more angular damping
--local DAMP_ROCKER    = {lin = 0.3, ang = 0.3}
--local DAMP_PENDANT   = {lin = 0.3, ang = 0.3}    -- ang matches the value already hand-tuned earlier in this thread
--local DAMP_CROSSBAR  = {lin = 0.3, ang = 0.3}   -- ang matches the value already hand-tuned earlier in this thread
--local DAMP_FOOT      = {lin = 0.3, ang = 0.3}

local DAMP_CUBE      = {lin = 0., ang = 1.0}   -- STRAIGHT-LINE FIX: confirmed via real 600-frame sweep for THIS mechanism specifically (not assumed to carry over from the other files) -- ang=1.0 cut heading drift from -26.6 degrees to 0.78 degrees AND improved distance traveled by 46% (46.9 -> 68.5 units). See the other Hoecken-family files in this series for why: without rotational damping, nothing resists small torque asymmetries between the front/back leg pairs from accumulating into persistent yaw.
local DAMP_CRANK     = {lin = 0., ang = 0.}
local DAMP_COUPLER   = {lin = 0., ang = 0.}   -- coupler + couplerVis: the newest/least-tested body, given a bit more angular damping
local DAMP_ROCKER    = {lin = 0., ang = 0.}
local DAMP_PENDANT   = {lin = 0., ang = 0.}    -- ang matches the value already hand-tuned earlier in this thread
local DAMP_CROSSBAR  = {lin = 0., ang = 0.}   -- ang matches the value already hand-tuned earlier in this thread
local DAMP_FOOT      = {lin = 0., ang = 0.}

function midpoint(p1, p2)
  return { x = (p1.x + p2.x)/2, y = (p1.y + p2.y)/2 }
end

-- one of the two points where a circle (center c1, radius r1) meets
-- a circle (center c2, radius r2) -- law of cosines, algebraically
-- pre-solved so it costs one sqrt instead of an acos+cos+sin.
function circleIntersect(c1, r1, c2, r2, flip)
  local dx, dy = c2.x - c1.x, c2.y - c1.y
  local d = math.sqrt(dx*dx + dy*dy)
  local a = (r1*r1 - r2*r2 + d*d) / (2*d)
  local hh = math.sqrt(r1*r1 - a*a)
  local xm, ym = c1.x + a*dx/d, c1.y + a*dy/d
  local px, py = -dy/d, dx/d
  if flip then px, py = -px, -py end
  return { x = xm + hh*px, y = ym + hh*py }
end

-- build a Z-axis rotation quaternion directly from a direction vector
-- (half-angle formulas -- avoids atan2, which isn't in every Lua build)
function zrotVec(dx, dy)
  local len = math.sqrt(dx*dx + dy*dy)
  local cosT, sinT = dx/len, dy/len
  local cosHalf = math.sqrt((1 + cosT)/2)
  local sinHalf = math.sqrt((1 - cosT)/2)
  if sinT < 0 then sinHalf = -sinHalf end
  return btQuaternion(0, 0, sinHalf, cosHalf)
end

local IDENTITY_QUAT = btQuaternion(0, 0, 0, 1)

-- makes one rod-shaped link body from p1 to p2, sitting flat on its
-- own Z-plane, and adds it to the view.
function makeLink(p1, p2, z, mass, color, width, depth)
  width = width or rod_w
  depth = depth or rod_d
  local len = math.sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, width, depth, mass)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  track(obj)   -- track() is defined below, but only called once this function itself is called from inside buildScene() -- global lookup happens at call time, so definition order doesn't matter here
  return obj
end
-- ---------------------------------------------------------------------
-- ground: one wide cube shared by both linkages -- same sizing formula
-- as the original (linkage_spacing + margin on each side). Mass
-- restored to 10.0 (dynamic, matching the original) -- a static cube
-- turned out to be a real contributor to growing oscillation: it gave
-- the leg mechanism nowhere to shed reaction force into, unlike the
-- original's cube, which can absorb some of that momentum by moving
-- slightly, the same way a real body would.
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- REBUILD SUPPORT for cube_d/cubeMass/terrainAmp/linkageSpacing: every
-- object and constraint buildScene() creates is tracked here so a
-- later call can tear the whole thing down cleanly (v:remove /
-- v:removeConstraint) before rebuilding it with a new slider value --
-- see the GUI sliders comment above for why Restart Simulation can't
-- do this for us.
-- ---------------------------------------------------------------------
local builtObjects, builtConstraints = {}, {}

function track(obj)
  v:add(obj)
  builtObjects[#builtObjects + 1] = obj
  return obj
end

function trackConstraint(con)
  v:addConstraint(con)
  builtConstraints[#builtConstraints + 1] = con
  return con
end

function teardownScene()
  for i = 1, #builtConstraints do
    v:removeConstraint(builtConstraints[i])
  end
  builtConstraints = {}
  for i = 1, #builtObjects do
    v:remove(builtObjects[i])
  end
  builtObjects = {}
end

local floor_top_y = -0.8 - p_len

function buildScene()
local cube_d = v:getParam("cube_d")        -- cube's own depth (Z) -- GUI slider -- 2.5
local linkage_spacing = v:getParam("linkageSpacing")   -- GUI slider -- how far apart the two leg mounts on each face sit
-- half_spacing keeps the mounts symmetric around cube_center_x=0 for
-- any linkage_spacing, not just the original hardcoded 10 -- the old
-- "-5"/"linkage_spacing-5" pair only happened to be symmetric (+-5)
-- because linkage_spacing was always 10; the same mount-offset issue
-- Spears_diag3_ModelC.lua's own comments describe and fix.
local half_spacing = linkage_spacing / 2
local cube_margin = 2.5
local cube_w = linkage_spacing + 2*cube_margin
local cube_center_x = 0
-- Read early (also used by the floor section further down) so the
-- walker's starting height can already account for it -- see
-- terrain_lift below.
local terrain_amp = v:getParam("terrainAmp")  -- bump height -- GUI slider
-- STARTING-HEIGHT CLEARANCE: terrainHeight()'s three sine terms sum to
-- a max combined amplitude of 0.5+0.3+0.2=1.0, so the terrain can bulge
-- up to terrain_amp above the flat floor_top_y baseline anywhere on the
-- mesh. At terrain_amp=0 the walker was built flush with that baseline
-- (fine, since there's no bulge to clip); raising terrain_amp alone
-- left the walker's construction-time height fixed while the terrain
-- under it could now rise above that height, embedding the feet at the
-- very first frame, before gravity/contact ever got a chance to settle
-- it naturally. Lifting the whole walker by terrain_lift clears the
-- tallest possible bump anywhere on the terrain, not just wherever it
-- happens to start -- gravity still settles it onto the actual surface
-- normally from there.
local terrain_lift = terrain_amp * 1.0

-- rocker shares the crank's plane (both z_crank) instead of getting its
-- own slot -- one fewer distinct plane, and the coupler/pendant/crossbar
-- slots shift in by one gap to fill the space that opens up.
local z_ground, z_crank, z_coupler, z_rocker, z_pendant, z_crossbar =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap

cube = Cube(cube_w, 1.5, cube_d, 7.0)   -- CUBE MASS OPTIMIZED, found by running 2400-frame trials (not visible at 600) sweeping mass from 0.5 to 200: at the old mass=100, the walker phase-locks (see the long-run note below buildLinkage's linkage3/4 calls) and then REVERSES, ending up at only 99.8 units of net displacement by frame 2400. Every mass from roughly 3 to 25 avoids that reversal entirely -- net displacement 255-275 units, the walker just keeps going -- with mass=7 the peak of that plateau (275.25). Below ~mass=1 the cube starts bouncing more (Y range widens from the usual ~[-2,1.3] toward [-2.3,5.7] at mass=0.5) and net distance drops off; above ~mass=30 the reversal reappears and by mass=35 is about as bad as the original 100. This also improves the cube:leg mass ratio directly -- crank/coupler/rocker/pendant masses are all under 1.5, so mass=100 put a ~180:1 ratio across the motor-driven hinge, exactly the kind of large mass ratio flagged elsewhere in this file series as an iterative-solver risk; mass=7 brings that down to a much healthier ~12:1.
cube.damp_lin = DAMP_CUBE.lin
cube.damp_ang = DAMP_CUBE.ang
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
track(cube)

-- ---------------------------------------------------------------------
-- floor: an uneven terrain mesh (Terrain, backed by
-- btBvhTriangleMeshShape -- Bullet's BVH-accelerated static concave
-- shape) instead of a flat Cube. floor_top_y is still the mechanism's
-- own baseline reach, DERIVED from p_len exactly as before (4.6 - p_len
-- comes from the crank/rocker/coupler loop's own lowest point,
-- independent of p_len, minus the foot's half-thickness and a small
-- margin); terrainHeight(x,z) adds a small undulation ON TOP of that
-- baseline, so a foot still finds ~floor_top_y on average but has real
-- bumps to step over/into instead of a perfectly flat surface.
-- terrain_amp is on the order of the crank length driving the whole
-- gait (a_len=1.0) and well past the foot's own half-thickness (0.15),
-- so bumps are a real obstacle the feet have to climb, not just surface
-- texture -- worth watching on the first run, same honest caveat as the
-- top crossbars above.
-- (Terrain was tried here before via btGImpactMeshShape -- tiles,
-- scattered patches -- but reverted: GImpact is built for shapes that
-- might move, and is markedly slower/less stable than it needs to be
-- for a shape that never does. btBvhTriangleMeshShape builds its BVH
-- tree once, at construction, and is ONLY ever valid for a static body
-- -- exactly what the floor already was, so nothing about "static,
-- never moves" had to change, just the shape type backing it.)
-- ---------------------------------------------------------------------

-- floor_w/floor_d/terrain_nx/terrain_nz/floor_x0/floor_z0 (below) are
-- globals, not locals -- same "REBUILD SUPPORT" convention already used
-- for cube/floor themselves, needed so the trail code past the end of
-- buildScene() can convert a world (x,z) back to a terrain triangle
-- index using these exact same values, instead of only the code inside
-- this function being able to see them.
floor_w, floor_d = 600, 600
terrain_nx, terrain_nz = 120, 60   -- grid resolution: 2.5-unit cells in both X and Z

-- Smooth, deterministic pseudo-noise: three sine waves at different
-- frequencies/phases/axes summed together. Each term alone is perfectly
-- smooth (a sine has no discontinuities), so neighboring grid points are
-- always close in height -- no cliff edge a foot could catch a corner on
-- -- while the SUM of three incommensurate frequencies isn't simply
-- periodic the way a single sine would be, so the walker's path crosses
-- real bump-to-bump variation rather than a uniform ripple.
function terrainHeight(x, z)
  return terrain_amp * (
    0.5 * math.sin(x * 0.30 + z * 0.21) +
    0.3 * math.sin(x * 0.11 - z * 0.44 + 1.7) +
    0.2 * math.sin(x * 0.53 + z * 0.07 + 4.1))
end

floor = Terrain()
floor_x0, floor_z0 = cube_center_x - floor_w/2, -floor_d/2
for i = 0, terrain_nx - 1 do
  for j = 0, terrain_nz - 1 do
    local xa, xb = floor_x0 + i*(floor_w/terrain_nx), floor_x0 + (i+1)*(floor_w/terrain_nx)
    local za, zb = floor_z0 + j*(floor_d/terrain_nz), floor_z0 + (j+1)*(floor_d/terrain_nz)
    local yaa, yab = floor_top_y + terrainHeight(xa, za), floor_top_y + terrainHeight(xa, zb)
    local yba, ybb = floor_top_y + terrainHeight(xb, za), floor_top_y + terrainHeight(xb, zb)
    floor:addTriangle(btVector3(xa, yaa, za), btVector3(xa, yab, zb), btVector3(xb, yba, za))
    floor:addTriangle(btVector3(xb, yba, za), btVector3(xa, yab, zb), btVector3(xb, ybb, zb))
  end
end
floor:build()
floor.col = "#694811"
floor.friction = 0.8
track(floor)
-- ---------------------------------------------------------------------
-- linkage builder -- one Chebyshev-Spears g/a/f/h/p mounted at
-- x_offset along the cube's face (g_center = (x_offset, 1.25)). g_ang
-- tilts the ground link around its own midpoint.
--
-- FLIPPED ALONG X: every point is computed with the original formulas
-- first (the "_raw" points), then reflected across the x-axis (y ->
-- -y) with flipY -- moves the legs from below the cube to above it.
--
-- BENT COUPLER: the coupler is ONE fused rigid body spanning A -> M,
-- carrying the combined mass of what used to be two segments. The
-- second segment's endpoint, B, is just a fixed local offset on that
-- same body (see the FUSED COUPLER comment below) -- moving B (and the
-- pendant hinged off it) 90 degrees from where a straight coupler
-- would put it, exactly as before, but without a second rigid body or
-- a weld constraint competing with the coupler<->rocker hinge at M.
-- ---------------------------------------------------------------------

local function flipY(p) return { x = p.x, y = -p.y } end
function buildLinkage(x_offset, g_ang, mirror, phase, speed, ext_down)
  g_ang = g_ang or -45
  phase = phase or 0
  ext_down = ext_down or 0   -- how far the pendant extends below its original bottom (C)
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant

  -- raw geometry, exactly the original formulas -- terrain_lift
  -- (computed in buildScene above) is SUBTRACTED here, not added:
  -- flipY below negates every raw point's y, so subtracting pre-flip
  -- becomes adding post-flip -- same reasoning (and the same real-
  -- engine verification: cube.pos.y and a foot's pos.y rise by exactly
  -- terrain_lift together) as Spears_diag3_ModelC.lua's identical fix.
  local g_center_raw = { x = x_offset, y = 1.25 - terrain_lift }
  local O2_raw = { x = g_center_raw.x - (g_len/2)*math.cos(math.rad(g_ang)),
                    y = g_center_raw.y - (g_len/2)*math.sin(math.rad(g_ang)) }
  local O4_raw = { x = g_center_raw.x + (g_len/2)*math.cos(math.rad(g_ang)),
                    y = g_center_raw.y + (g_len/2)*math.sin(math.rad(g_ang)) }
  local a_ang0 = g_ang + 90 + phase
  local A_raw = { x = O2_raw.x + a_len*math.cos(math.rad(a_ang0)),
                   y = O2_raw.y + a_len*math.sin(math.rad(a_ang0)) }
  local M_raw = circleIntersect(A_raw, f_len/2, O4_raw, h_len, true)   -- the "other" branch

  -- bend: rotate the A->M direction 90 degrees for the second half
  local ux, uy = (M_raw.x - A_raw.x)/(f_len/2), (M_raw.y - A_raw.y)/(f_len/2)
  local rx, ry = -uy, ux   -- +90 degrees (counterclockwise)
  local B_raw = { x = M_raw.x + (f_len/2)*rx, y = M_raw.y + (f_len/2)*ry }

  -- flip across the x-axis so the whole assembly ends up above the cube
  local g_center = flipY(g_center_raw)
  local O2 = flipY(O2_raw)
  local O4 = flipY(O4_raw)
  local A  = flipY(A_raw)
  local M  = flipY(M_raw)
  local B  = flipY(B_raw)

  -- pendant's initial pose: computed straight from the already-flipped
  -- B, so "down" here means down in the actual build space (negative
  -- y). ext_down extends the pendant further below its original
  -- bottom, exactly the same way as before -- B stays fixed (it's the
  -- coupler hinge), C just moves further away.
  local C = { x = B.x, y = B.y - p_len - ext_down }
  local pendant_len = p_len + ext_down
  local mass_pendant = density_pendant * pendant_len   -- 0.9729 for the default ext_down=4.0

  local half_f = f_len/2   -- = L below; AM and MB are equal-length segments, both = half_f

  local crank   = makeLink(O2, A, z_crank_l, mass_crank, "coral", 0.3, rod_d)   -- ASPECT RATIO: 0.18->0.3, +89% I_xx (off-plane wobble resistance) for +1.6% motor load -- see the ASPECT RATIO note below buildLinkage's other geometry
  crank.damp_lin = DAMP_CRANK.lin
  crank.damp_ang = DAMP_CRANK.ang

  -- FUSED COUPLER: previously couplerA (A->M) and couplerB (M->B) were
  -- two separate rigid bodies joined by a locked btSliderConstraint
  -- "weld" at M -- but that weld shared its anchor point with hingeM
  -- (coupler<->rocker), so two independent constraints were pinning the
  -- same point, which is what caused the bend to jitter under motor
  -- torque.
  --
  -- Fix: build ONE rigid body -- `coupler` -- covering A->M. Its own
  -- local frame is exactly what makeLink(A,M,...) already gives it:
  -- local +X runs A->M, so in that frame:
  --     local A = (-half_f/2, 0, 0)      local M = (+half_f/2, 0, 0)
  --
  -- SIGN BUG (this is what actually broke every earlier attempt):
  -- buildLinkage computes the raw bend as "+90 degrees CCW" from the
  -- raw A->M direction, THEN reflects every point (A, M, B, ...) across
  -- the x-axis via flipY to make the legs point up instead of down. A
  -- reflection reverses handedness -- so in the FINAL (flipped)
  -- coordinates that `coupler`'s own local frame is actually built
  -- from, B sits 90 degrees CLOCKWISE from the A->M direction, not
  -- counterclockwise. Checked numerically (raw A=(0,0), M=(half_f,0) ->
  -- raw B=(half_f,half_f) via the +90 CCW formula -> after flipY,
  -- B=(half_f,-half_f) -- i.e. B ends up BELOW M, negative local Y, not
  -- above it). So in `coupler`'s own local frame:
  --     local B = (+half_f/2, -half_f, 0)     <- negative Y
  -- Every previous version of this fix used +half_f here, putting B's
  -- pivot, the visual weld, and (in the compound-shape version) the
  -- second child shape all on the mirror-opposite side of where the
  -- real geometry sits -- a 180-degree-wrong initial configuration,
  -- which is a far more severe and far more plausible explanation for
  -- "blows apart immediately" than anything about mass or inertia.
  -- Notably, the ORIGINAL two-body weldBend code never hit this bug --
  -- it computed the couplerA/couplerB relative rotation directly from
  -- the actual (already-flipped) A/M/B coordinates via dot/cross
  -- products, rather than assuming a fixed +/-90 degrees.
  --
  -- M is therefore no longer a constraint at all -- it's just a fixed
  -- point inside a single rigid body. The only constraints left at that
  -- end are hingeA (to the crank) and hingeM (coupler<->rocker) -- both
  -- now anchored to the SAME single body, so there's nothing left to
  -- fight over.
  --
  -- CAN'T ACTUALLY BUILD A COMPOUND SHAPE HERE: checked the engine's
  -- source (object.cpp) -- Object::setCollisionShape only reassigns
  -- Object's own bookkeeping pointer, it never touches the underlying
  -- btRigidBody's actual shape (there's no setCollisionShape exposed on
  -- btRigidBody/btCollisionObject in this binding at all). Cube's shape
  -- is baked into the body permanently inside Cube::init() with no way
  -- to swap it or attach a real btCompoundShape afterward (a genuine
  -- compound body IS buildable via the raw btCompoundShape /
  -- btRigidBodyConstructionInfo / btRigidBody / Object:setRigidBody
  -- path, but that adds several more unverifiable API calls on top of
  -- an already-unverifiable sim, so this version deliberately avoids it
  -- to isolate the sign fix as the only real change). So `coupler`
  -- physically remains a single box spanning only A->M -- collision
  -- volume for the M->B half doesn't exist (acceptable here since
  -- gravity/the floor are both off).
  --
  -- MASS/INERTIA: putting the combined mass of both former segments
  -- into a shape that only spans A->M would badly underestimate the
  -- body's resistance to rotating around B (all that mass sitting near
  -- the body's own center, none of it out where the leverage actually
  -- is) -- so instead of trusting Cube's own auto-computed inertia
  -- (which only knows about the A->M box), the inertia below is derived
  -- by hand for the TRUE two-segment L-shape (each segment treated as
  -- its own solid box, combined via the standard parallel-axis
  -- theorem), then applied directly via body:setMassProps. This is
  -- still an approximation -- computed about this body's own origin
  -- (the A->M midpoint) rather than the true combined center of mass,
  -- and it drops the small off-diagonal (product-of-inertia) term a
  -- perfectly exact bent-shape tensor would have -- but it's a much
  -- closer match to the real mass distribution than either "all mass
  -- crammed into the A->M box's own natural inertia" or the original
  -- two-body version. (These formulas only depend on squared
  -- distances, so they're unaffected by the sign bug above.)
  local mass_coupler = mass_couplerHalf * 2   -- combined mass of both former segments
  local m = mass_couplerHalf   -- per-segment mass, for the formulas below
  local L = half_f
  -- ASPECT RATIO: coupler_width replaces the global rod_w for this body
  -- only (both segments of the L-shape share it) -- 0.18->0.8, +938%
  -- I_xx (off-plane wobble resistance) for +1.85% motor-load-like cost
  -- at this length (5.73). Threaded through BOTH the makeLink call below
  -- AND every inertia formula here, since this body's inertia is hand-
  -- computed (not Cube's own auto-inertia) and explicitly depends on
  -- the cross-section dimensions -- widening the body without updating
  -- these formulas would leave the inertia tensor describing the OLD,
  -- thinner cross-section while the actual collision shape used the new
  -- wider one, a mismatch between visible size and rotational
  -- resistance that setMassProps would silently bake in.
  local coupler_width = 0.8
  -- segment 1 (A->M), own box inertia about its own center, axes aligned
  -- with this body's local frame (unrotated):
  local I1xx = m/12 * (coupler_width*coupler_width + rod_d*rod_d)
  local I1yy = m/12 * (L*L + rod_d*rod_d)
  local I1zz = m/12 * (L*L + coupler_width*coupler_width)
  -- segment 2 (M->B), own box inertia is the same shape but rotated 90
  -- degrees about Z, which swaps its X/Y moments when expressed in this
  -- body's (unrotated) local frame:
  local I2xx_local = m/12 * (L*L + rod_d*rod_d)
  local I2yy_local = m/12 * (coupler_width*coupler_width + rod_d*rod_d)
  local I2zz_local = m/12 * (L*L + coupler_width*coupler_width)
  -- parallel-axis shift: segment 1's own center is at this body's local
  -- origin (0,0,0); segment 2's own center is at local (L/2, -L, 0)
  -- (midpoint of local M=(L/2,0,0) and local B=(L/2,-L,0)). Shifting
  -- both to the origin (not the true COM -- see note above). Only
  -- squared components are used, so the sign of seg2cy doesn't change
  -- the result here:
  local seg2cx, seg2cy = L/2, -L
  local Ixx = I1xx + I2xx_local + m * seg2cy*seg2cy
  local Iyy = I1yy + I2yy_local + m * seg2cx*seg2cx
  local Izz = I1zz + I2zz_local + m * (seg2cx*seg2cx + seg2cy*seg2cy)

  local coupler = makeLink(A, M, z_coupler_l, mass_coupler, "teal", coupler_width, rod_d)
  coupler.damp_lin = DAMP_COUPLER.lin
  coupler.damp_ang = DAMP_COUPLER.ang
  coupler.body:setMassProps(mass_coupler, btVector3(Ixx, Iyy, Izz))

  -- VISUAL-ONLY second segment (M->B): still can't render a true
  -- compound shape (see note above), so the bend's second half is a
  -- separate body welded rigidly to `coupler` -- same weld recipe
  -- already proven elsewhere in this file (buildCrossbar, buildFoot): a
  -- btSliderConstraint with both linear limits locked to 0 (rotation is
  -- locked by default -- see the header note on btSliderConstraint).
  -- This weld is anchored at local (half_f/2, -half_f/2, 0) on
  -- `coupler` -- a point NOTHING else is pinned to (hingeA is at
  -- (-half_f/2,0,0), hingeM at (half_f/2,0,0), hingeB at
  -- (half_f/2,-half_f,...)) -- so no redundant double-pin like the
  -- original couplerA/couplerB weld had at M. couplerVis carries a
  -- small nonzero mass (needed for the solver to actually move it to
  -- satisfy the weld -- mass 0 would make it static/immovable) but no
  -- other constraint, and `coupler` now carries the REAL combined
  -- mass/inertia via setMassProps above, so couplerVis stays
  -- dynamically negligible and can't destabilize anything.
  local couplerVis = makeLink(M, B, z_coupler_l, mass_coupler * 0.02, "teal", coupler_width, rod_d)
  couplerVis.damp_lin = DAMP_COUPLER.lin
  couplerVis.damp_ang = DAMP_COUPLER.ang
  -- couplerVis's own origin (midpoint of local M=(L/2,0,0) and local
  -- B=(L/2,-L,0)) sits at local (L/2, -L/2, 0); its own local +X axis
  -- (which runs M->B) points along coupler's local -Y -- a fixed -90
  -- degree twist (NOT +90 -- see the sign-bug note above).
  local frameInCoupler    = btTransform(zrotVec(0, -1), btVector3(L/2, -L/2, 0))
  local frameInCouplerVis = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldVis = btSliderConstraint(coupler.body, couplerVis.body, frameInCoupler, frameInCouplerVis, true)
  weldVis:setLowerLinLimit(0)
  weldVis:setUpperLinLimit(0)
  trackConstraint(weldVis)

  local rocker   = makeLink(M, O4, z_rocker_l, mass_rocker, "purple", 0.5, rod_d)   -- ASPECT RATIO: 0.18->0.5, +336% I_xx for +0.7% load
  rocker.damp_lin = DAMP_ROCKER.lin
  rocker.damp_ang = DAMP_ROCKER.ang
  local pendant  = makeLink(B, C, z_pendant_l, mass_pendant, "goldenrod", 1.0, rod_d)   -- ASPECT RATIO: 0.18->1.0, +1493% I_xx for +1.0% swing cost
  pendant.damp_lin = DAMP_PENDANT.lin
  pendant.damp_ang = DAMP_PENDANT.ang

  -- NOTE: a ground-link rod (O2->O4, welded rigidly to the cube) was
  -- tried here to make the crank/rocker hinges look physically attached
  -- instead of floating -- removed again because it can collide with
  -- the crank: it shares O2 as an endpoint, and even on a separate
  -- Z-plane its swept footprint near O2 overlaps the crank's own sweep
  -- closely enough to generate real contact forces that fight the
  -- rigid weld. The crank/rocker hinge straight to the cube, same as
  -- the original file -- no ground-link body at all.

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank -- the driven joint
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  hingeO2:enableAngularMotor(true, speed, 8.0)
  trackConstraint(hingeO2)

  -- A: crank <-> coupler
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-half_f/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  trackConstraint(hingeA)

  -- M: coupler <-> rocker (free hinge -- the real four-bar joint, and
  -- now the ONLY constraint anchored at M)
  local pivotCoupler_M = btVector3(half_f/2, 0, 0)
  local pivotRocker_M  = btVector3(-h_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeM = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_M, pivotRocker_M, axis, axis)
  trackConstraint(hingeM)

  -- O4: rocker <-> cube
  local pivotRocker_O4 = btVector3(h_len/2, 0, z_ground_l - z_rocker_l)
  local pivotCube_O4   = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  local hingeO4 = btHingeConstraint(rocker.body, cube.body, pivotRocker_O4, pivotCube_O4, axis, axis)
  trackConstraint(hingeO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings).
  -- B's local pivot on `coupler` now carries the bend offset directly
  -- (half_f/2 along local X to M, plus a full half_f along local NEGATIVE
  -- Y to reach B -- see the sign-bug note above for why it's -Y, not +Y)
  -- instead of being the +X end of a second body.
  local pivotCoupler_B = btVector3(half_f/2, -half_f, z_coupler_l - z_pendant_l)
  local pivotPendant_B = btVector3(-pendant_len/2, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  trackConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, couplerVis = couplerVis, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeM = hingeM, weldVis = weldVis, hingeO4 = hingeO4, hingeB = hingeB,
    z_pendant = z_pendant_l, B = B, C = C, pendant_len = pendant_len,
  }
end
linkage1 = buildLinkage(-half_spacing, -45, false, 0, v:getParam("Left Speed"), EXT_DOWN)   -- front face, x=-half_spacing, phase 0
linkage2 = buildLinkage(half_spacing, -45, false, 0, v:getParam("Left Speed"), EXT_DOWN)    -- front face, x=+half_spacing, phase 0
linkage3 = buildLinkage(-half_spacing, -45, true, 90, v:getParam("Right Speed"), EXT_DOWN)  -- back face,  x=-half_spacing, phase 90 (comment previously said 180 -- corrected to match what the code actually passes)
linkage4 = buildLinkage(half_spacing, -45, true, 90, v:getParam("Right Speed"), EXT_DOWN)   -- back face,  x=+half_spacing, phase 90
-- LONG-RUN BEHAVIOR (found running 2400 frames, not visible at 600): the
-- front and back leg pairs' crank angles drift into sync with each
-- other over time regardless of their starting phase offset -- a real
-- mechanical entrainment/coupling effect through the shared cube, not a
-- bug in any one part. Confirmed at both phase=90 (this file) and
-- phase=180 (tested as an alternative): BOTH lock into a synchronized
-- gait by roughly frame 750-1250, and in BOTH cases the walker
-- eventually reverses direction after locking -- phase=90 actually
-- travels farther forward first (peaks around -133 units at frame 1250)
-- than phase=180 did in the same fully-fixed file (peaks around -88 at
-- frame 773, reversing sooner). So changing the phase value doesn't fix
-- the reversal -- it's a genuine longer-timescale dynamical property of
-- this coupled system, not something resolved by picking a different
-- starting offset. Left at 90 (unchanged) since 180 tested no better.
-- ---------------------------------------------------------------------
-- crossbar builder -- welds (not hinges) a single rigid bar between two
-- pendants' midpoints. Works because linkage1/linkage2 (and
-- linkage3/linkage4) share identical mirror AND phase -- their pendants
-- trace an IDENTICAL path, just translated, so they stay a fixed
-- distance apart with zero relative rotation, and welding a rigid bar
-- between them is consistent rather than conflicting with the rest of
-- the motion. Front and back never interact -- they sit on opposite Z
-- half-spaces the whole time.
--
-- ONE BAR PER SIDE, NOT TWO: this file used to build TWO independent
-- crossbar bodies per side (crossbarFront + crossbarFront2, at
-- attach_height=brace_bottom and brace_top), each with its own full
-- weld (translation AND rotation locked, since a slider-weld locks both
-- by default) to the SAME two pendants. That's over-constrained -- a
-- single weld already fully pins a pendant's pose to its crossbar, so a
-- second, unrelated body welded the same way has no way to stay
-- simultaneously consistent except by exact numerical coincidence. Any
-- tiny solver residual makes the two crossbars fight each other for
-- control of the same pendant -- visible separation between crossbar
-- and pendant, not a stiffness problem (which is why the ERP/CFM
-- softness tuning below wasn't the fix -- it was correctly diagnosing
-- "something's fighting the weld" but softening a weld that's being
-- pulled two directions at once just trades jitter for drift). Fixed by
-- building ONE bar tall enough (bar_height) to span the same vertical
-- range the old two bars covered, welded once per pendant instead of
-- twice. Visually this trades the old "two thin struts" look for a
-- single wider plate.
-- ---------------------------------------------------------------------

-- CROSSBAR WELD TUNING: these welds are locked entirely via the LIMIT
-- machinery (setLowerLinLimit(0)/setUpperLinLimit(0) below), not the
-- constraint's normal drive -- so it's specifically the LIMIT's own
-- erp/cfm (Bullet's "stop" params) that governs how firmly that lock
-- gets enforced each step, not the constraint's plain ERP/CFM.
--
-- CROSSBAR_WELD_STOP_ERP: how aggressively any mismatch at the weld
--   (e.g. the two legs' pendants drifting very slightly out of sync)
--   gets corrected per step. 1.0 = snap fully closed every frame
--   (Bullet's usual rigid-limit behavior). Lower = correct gradually
--   over several frames instead of all at once -- worth revisiting only
--   if the single-bar fix above still leaves some jitter; it's no
--   longer the first thing to reach for now that the actual
--   conflicting-constraint cause is fixed.
-- CROSSBAR_WELD_STOP_CFM: how much residual give the weld tolerates
--   even once "corrected" -- 0.0 = mathematically exact lock (Bullet's
--   default). Raising it a little (try 0.01-0.05 first) lets the weld
--   go slightly soft/springy, which can absorb small oscillations
--   instead of fighting them every frame.
-- Push either too far and the crossbar stops reading as rigid at all --
-- visible drift/looseness instead of jitter. Small steps, one at a
-- time, is the way to feel out where that line is.
--
-- Bullet's constraint-param indices (btTypedConstraint.h) -- the axis
-- argument (-1) applies the param across the constraint's locked DOFs;
-- if a specific value doesn't seem to take effect, this axis argument
-- is the one part of this call I'm least certain about without being
-- able to run the sim myself, and is worth experimenting with (0 or 1)
-- if -1 doesn't behave as expected:
--local BT_CONSTRAINT_STOP_ERP = 2
--local BT_CONSTRAINT_STOP_CFM = 4

--WMS
--local CROSSBAR_WELD_STOP_ERP = 0.5    -- try lowering first (e.g. 0.5 -> 0.2)
--local CROSSBAR_WELD_STOP_CFM = 0.0    -- try raising second (e.g. 0.0 -> 0.02)
function buildCrossbar(lkA, lkB, z_pos, color, bar_height)
  bar_height = bar_height or rod_w
  local PA, PB = lkA.pendant.pos, lkB.pendant.pos
  local len = math.sqrt((PB.x-PA.x)^2 + (PB.y-PA.y)^2)   -- should equal linkage_spacing, by symmetry
  local mid_x = (PA.x + PB.x) / 2

  local bar = Cube(len, bar_height, rod_d, 1.0)
  bar.col = color
  bar.trans = btTransform(IDENTITY_QUAT, btVector3(mid_x, PA.y, z_pos))   -- centered ON the pendant's own line -- no attach_height offset needed now there's only one bar
  bar.damp_lin = DAMP_CROSSBAR.lin
  bar.damp_ang = DAMP_CROSSBAR.ang
  track(bar)

  -- both pendants in a pair share the same orientation at construction
  -- (same geometry, just translated), so this one quaternion is the
  -- correct weld-frame rotation for both ends -- read directly from the
  -- engine body via getRotation(), never decomposed or recomputed.
  local pendant_quat = lkA.pendant.trans:getRotation()

  local frameInBar_A = btTransform(pendant_quat, btVector3(-len/2, 0, lkA.z_pendant - z_pos))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldA = btSliderConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLowerLinLimit(0)
  weldA:setUpperLinLimit(0)
  --weldA:setParam(BT_CONSTRAINT_STOP_ERP, CROSSBAR_WELD_STOP_ERP, 1) --1) --   -1)
  --weldA:setParam(BT_CONSTRAINT_STOP_CFM, CROSSBAR_WELD_STOP_CFM, 1) --1) --   -1)
  trackConstraint(weldA)

  local frameInBar_B = btTransform(pendant_quat, btVector3(len/2, 0, lkB.z_pendant - z_pos))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldB = btSliderConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLowerLinLimit(0)
  weldB:setUpperLinLimit(0)
  --weldB:setParam(BT_CONSTRAINT_STOP_ERP, CROSSBAR_WELD_STOP_ERP, 1) --1) --   -1)
  --weldB:setParam(BT_CONSTRAINT_STOP_CFM, CROSSBAR_WELD_STOP_CFM, 1) --1) --   -1)
  trackConstraint(weldB)

  return bar
end

-- bar_height spans from near-C (the foot end) to near-B (the coupler
-- hinge end) of the pendant, the same combined range the old
-- brace_bottom/brace_top pair of bars covered -- brace_margin keeps it
-- clear of the B hinge at one end and the foot pad welded at C at the
-- other, rather than running the bar's full length. All four linkages
-- share the same pendant_len (same ext_down), so linkage1's is a valid
local half_pendant = linkage1.pendant_len / 2
local brace_margin = 0.5
local brace_height = 2 * (half_pendant - brace_margin)

crossbarFront = buildCrossbar(linkage1, linkage2, z_crossbar, "slateblue", brace_height)
crossbarBack  = buildCrossbar(linkage3, linkage4, -z_crossbar, "slateblue", brace_height)
-- ---------------------------------------------------------------------
-- foot builder -- unmodified port of the original's buildFoot. A wide,
-- flat pad welded (not hinged) to the bottom of a pendant, extending
-- from the pendant's own Z-plane inward to z=0 -- the cube's own
-- centerline -- so each foot reaches under the body rather than just
-- sitting out at the side where its pendant hangs. Built unrotated
-- (like the crossbars), with the Z-extent baked directly into the
-- Cube's own depth dimension -- only the weld frame's rotation needs
-- to match the pendant's actual orientation, using the same
-- identity-body-plus-matched-frame trick as the crossbars.
--
-- The one change from the original: "C is the pendant's own +X end"
-- offset uses lk.pendant_len/2 instead of a hardcoded p_len/2, since
-- our pendants are now longer (extended downward by EXT_DOWN) -- C is
-- still the +X end, just further out along a longer rod.
-- ---------------------------------------------------------------------
function buildFoot(lk, color)
  local C = lk.C
  local zp = lk.z_pendant
  local dir = zp >= 0 and 1 or -1
  local outward_extra = 5.0 --2.0            -- how far the foot reaches PAST the pendant, away from the body

  -- STABILITY FIX: the tipping margin toward whichever pair is
  -- currently lifted was only ~1.0 unit (COM sits near Z=0, and the old
  -- inner_gap=-1.0 put the inner edge right there too), vs. ~4.45
  -- toward the planted side -- an ~8.9 degree critical tip angle in the
  -- weak direction. Extending the inward reach to -2.0 roughly doubles
  -- that margin (~17.4 degrees). TRADE-OFF: front and back pads already
  -- share a Z-overlap zone by design (their X-positions are assumed
  -- never to coincide there); this doubles that shared zone from 2 to 4
  -- units, which hasn't been swept across the full gait cycle to
  -- confirm X-positions still stay clear of each other everywhere --
  -- worth a visual check if pushed further.
  local inner_gap = 1.0 -- 2.0                -- was -1.0

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, mass_foot)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  foot.damp_lin = DAMP_FOOT.lin
  foot.damp_ang = DAMP_FOOT.ang
  track(foot)

  local pendant_quat = lk.pendant.trans:getRotation()
  -- the pendant attaches at z=zp, which is now partway along the foot's
  -- length (not at its end), since the foot extends past it on both sides
  local frameInFoot    = btTransform(pendant_quat, btVector3(0, 0, zp - foot_center_z))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(lk.pendant_len/2, 0, 0))   -- C is the pendant's own "+X end"
  local weld = btSliderConstraint(foot.body, lk.pendant.body, frameInFoot, frameInPendant, true)
  weld:setLowerLinLimit(0)
  weld:setUpperLinLimit(0)
  trackConstraint(weld)

  return foot
end
foot1 = buildFoot(linkage1, "yellow")
foot2 = buildFoot(linkage2, "yellow")
foot3 = buildFoot(linkage3, "blue")
foot4 = buildFoot(linkage4, "blue")
end

buildScene()

-- ---------------------------------------------------------------------
-- GUI SLIDER LIVE SYNC: v:onParamChanged fires whenever a slider is
-- dragged (or setParam() is called from Lua), exactly like the GUI's
-- own drag handler updates a param. Only one v:onParamChanged may be
-- registered for the whole file (same single-callback rule as
-- v:preSim), so every param's handling lives in this one function.
--
-- maxSubSteps, "Left Speed" and "Right Speed" apply immediately in
-- place. cube_d, cubeMass, terrainAmp and linkageSpacing instead tear
-- down and rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene(), then clear the centroid trail since
-- the walker just snapped back to its starting position.
-- ---------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  elseif name == "Left Speed" then
    linkage1.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage2.hingeO2:enableAngularMotor(true, value, 8.0)
    print(string.format("Left Speed = %.2f", value))
  elseif name == "Right Speed" then
    linkage3.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage4.hingeO2:enableAngularMotor(true, value, 8.0)
    print(string.format("Right Speed = %.2f", value))
  elseif name == "cube_d" or name == "cubeMass" or name == "terrainAmp" or name == "linkageSpacing" then
    teardownScene()
    buildScene()
    clearTrail()   -- the walker just snapped back to its starting position -- an old trail from before the rebuild would misleadingly show a path it never walked from here
    print(string.format("%s = %s (scene rebuilt)", name, tostring(value)))
  end
end)

-- GUI SLIDER LIVE SYNC, redundant safety net for maxSubSteps/"Left
-- Speed"/"Right Speed": also re-applied every tick in the SINGLE
-- v:preSim hook further down (with the trail-marker code) -- this file
-- only supports one v:preSim registration, so a second one here would
-- silently replace it instead of running alongside it.

-- ---------------------------------------------------------------------
-- CENTROID TRAIL: colors the terrain triangle under the mechanism's
-- current (x,z) position every TRAIL_INTERVAL frames, to visualize its
-- trajectory over time (turning, drifting, straight-line travel, etc.).
--
-- Uses the CUBE's position as a practical stand-in for the true mass-
-- weighted centroid, rather than summing every body in the mechanism
-- every frame -- the cube alone is close to half the total mass, so
-- its path should closely track the true centroid's shape without
-- that bookkeeping.
--
-- REWORKED, per direct request, to color existing terrain triangles
-- instead of spawning a Cube marker per trail point: a long run drops a
-- lot of markers (every 0.5s), and each one was a genuine extra static
-- rigid body PLUS an extra draw call for the rest of the run -- the
-- count only ever grows, so a long walk visibly slowed down over time.
-- Terrain:setTriangleColor() (added to the engine for this) recolors a
-- triangle that's already part of the one floor body and already being
-- drawn every frame -- no new bodies, no growing draw-call count, no
-- matter how long the walk runs or how fine TRAIL_INTERVAL is set. This
-- also means there's nothing to v:remove() any more -- see clearTrail()
-- below.
--
-- floor_x0/floor_z0/floor_w/floor_d/terrain_nx/terrain_nz are the exact
-- same values the floor-building loop above used to place its
-- triangles -- converting a world (x,z) back to that loop's own (i,j)
-- cell indices, then to the triangle index Bullet assigns in
-- addTriangle() call order (2 triangles per cell, added in row-major
-- i,j order: cell (i,j)'s first triangle is index 2*(i*terrain_nz+j),
-- its second is that +1), recolors the exact cell the mechanism is over.
-- A position outside the floor's own extent is skipped rather than
-- clamped -- clamping would misleadingly paint the floor's edge cell for
-- a walker that's actually run off the mesh entirely, instead of just
-- not drawing anything.
--
-- TRAIL_INTERVAL=30 was tuned as "0.5s at 60fps" -- with v.timeStep now
-- 1/10 (same as Cheby's), that's exactly what it means here too. (Still
-- true after this rework -- TRAIL_INTERVAL only ever gated how often
-- colorTrailAt() fires, unrelated to what it does once it fires.)
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30   -- frames between markers (0.5s at 60fps) -- lower = finer trail, more markers over a long run
local trail_frame_count = 0
function clearTrail()
  floor:clearTriangleColors()   -- one call resets the whole floor to its base .col -- no per-marker list to walk any more
  trail_frame_count = 0
end

local function colorTrailAt(x, z)
  local i = math.floor((x - floor_x0) / (floor_w / terrain_nx))
  local j = math.floor((z - floor_z0) / (floor_d / terrain_nz))
  if i < 0 or i >= terrain_nx or j < 0 or j >= terrain_nz then
    return   -- off the floor's own extent -- nothing to color
  end
  local triIndex = 2 * (i * terrain_nz + j)
  floor:setTriangleColor(triIndex, 255, 0, 0)       -- "red", matching the old marker color
  floor:setTriangleColor(triIndex + 1, 255, 0, 0)   -- both triangles of the cell, not just one half of it
end

v:preSim(function(N)
  -- GUI SLIDER LIVE SYNC: maxSubSteps, "Left Speed" and "Right Speed"
  -- can be dragged while the sim is running. maxSubSteps is just
  -- re-assigned onto v each tick; the two speeds are re-applied to
  -- their own pair of hip hinges via enableAngularMotor (maxMotorImpulse
  -- stays fixed at 8.0, matching each hinge's original construction-
  -- time call).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local leftSpeed = v:getParam("Left Speed")
  local rightSpeed = v:getParam("Right Speed")
  linkage1.hingeO2:enableAngularMotor(true, leftSpeed, 8.0)
  linkage2.hingeO2:enableAngularMotor(true, leftSpeed, 8.0)
  linkage3.hingeO2:enableAngularMotor(true, rightSpeed, 8.0)
  linkage4.hingeO2:enableAngularMotor(true, rightSpeed, 8.0)

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera + gravity
-- ---------------------------------------------------------------------

v.cam.pos  = btVector3(26, 6, 30)
v.cam.look = btVector3(5, -3, 0)
v.cam.up   = btVector3(0, 1, 0)

v.gravity = btVector3(0, -9.8, 0)
--v.gravity = btVector3(0, 0, 0)
 -- restored -- see the cube-mass note above for why this matters for stability
