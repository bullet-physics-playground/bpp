-- Sept 22, 2026, by William M. Spears

-- This is a simulation of Chebyshev's Plantigrade Machine, shown at
-- the 1878 Paris World Exhibition. Claude wrote most of the code under
-- my guidance This was not a simple process. Top-down approaches failed
-- miserably. I had to build the machine component by component. This
-- took perhaps 3 full conversations. Then, after it started to move, it
-- took at least another 10 hours to tweak the parameters. I want to thank
-- Jakob Flierl for providing the very nice mesh floor, which makes
-- this much more interesting.
--
-- MODEL 1A (branched from Model 1): four copies of the same four-bar
-- linkage -- the original two on the front face, plus a mirrored pair
-- on the back face, whose motors run 90 degrees out of phase with the
-- front pair.
--
-- Ground link  g = 2.5  -- a stretch of the cube's top edge
-- Crank        a = 1.0  -- O2 -> A
-- Coupler      f = 5.0  -- A  -> B, with midpoint M
-- Rocker       h = 2.5  -- M  -> O4
-- Pendant      p = 10.0 -- B  -> C, hinged and hanging free (no motor)
--
-- The loop that actually closes is O2-A-M-O4, with sides a=1, AM=2.5,
-- h=2.5, g=2.5. Since shortest+longest (1+2.5=3.5) <= sum of the other
-- two (2.5+2.5=5), this is a Grashof linkage, and since the shortest
-- link is the crank, it's a crank-rocker: a can spin all the way
-- around and drag the rest of the loop with it. B is the free end of
-- the coupler, sticking out past M, and p just hangs off B.
--
-- Each link lives on its own Z-plane (0.4 units apart) out from the
-- cube face so the rotating parts never collide with each other or with
-- the cube. All hinge axes are world Z, so every link only ever rotates
-- about Z -- which means each link's local pivot points are simply
-- (+-L/2, 0, z_offset) in its own frame, no trig needed at hinge time.
--
-- MIRRORING: since every link only ever rotates about world Z, mounting
-- onto the back face just means flipping the sign of the whole
-- staggered Z-plane stack -- none of the in-plane (X,Y) geometry needs
-- to change. That's buildLinkage's `mirror` argument.
--
-- PHASE: with a constant-velocity motor, a "phase offset" is just a
-- different starting crank angle -- a constant angular lag/lead that a
-- constant angular velocity preserves forever. That's buildLinkage's
-- `phase` argument, added to the crank's initial angle.
--
-- CROSSBAR: a rigid (welded, not hinged) cuboid joining the midpoints
-- of two pendant links. Each pendant on its own only has ONE constraint
-- (its hinge to f's free end B), so its rotation is normally a free
-- dynamic variable -- but as long as both linkages in a pair are
-- identical and driven identically (same mirror, same phase), their
-- pendant midpoints always stay exactly 10 units apart with zero
-- relative rotation, so welding them together is consistent, not
-- conflicting, with the rest of the motion. The front pair and back
-- pair are NOT connected to each other -- each gets its own crossbar --
-- since they're 90 degrees out of phase and have no fixed relationship
-- to weld against.
--
-- IMPORTANT: btSliderConstraint does NOT lock translation by default --
-- its stock constructor leaves the linear range free (lower=1 > upper=
-- -1, Bullet's "free" convention) and only locks rotation. A "weld"
-- needs setLowerLinLimit(0)/setUpperLinLimit(0) explicitly, or the
-- welded body can just slide off along the constraint's own axis.
--
-- Building one linkage is wrapped in buildLinkage(...), and building
-- one crossbar between a pair of linkages is wrapped in buildCrossbar,
-- so the back pair is just two more calls.
--
-- FEET: buildFoot welds a wide, flat pad to the bottom of each pendant,
-- extending both inward (toward z=0, under the body) and outward (past
-- the pendant's own Z-plane, away from the body) -- widening the
-- support base in Z so a single pair (front-only or back-only) still
-- has real Z-extent to resist tipping, not just a zero-width line.
-- Inner edges stop short of z=0 by a small gap so opposing feet (front
-- vs back) don't touch at the centerline.
--
-- BODY MASS + FLOOR: the cube now has a small nonzero mass, so it's no
-- longer fixed in place -- gravity affects it, and it's held up (once
-- things settle) by whatever the legs/feet transmit to the floor.
-- None of the existing hinge/weld pivot math needed to change for this
-- -- every pivot was already stored as a LOCAL offset relative to the
-- cube's own body frame at construction time, which Bullet tracks
-- correctly regardless of how the body later moves or rotates. The
-- floor sits at the lowest point any foot reaches over a full crank
-- rotation (checked numerically), so every foot touches down at some
-- point in its own cycle, not just whichever pair happens to start low.
--

--v.timeStep = 1/10
--v.maxSubSteps = 20
--v.fixedTimeStep = 1/480

local common = require "common"

common.setTiming(1/10, 20, 1/480)

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
-- single callbacks). "Left Speed" drives linkage1/linkage2 (the front
-- legs); "Right Speed" drives linkage3/linkage4 (the back legs) -- two
-- independent motors instead of one shared speed. cube_d, cubeMass,
-- terrainAmp and linkageSpacing instead tear down and rebuild the
-- whole scene (cube, terrain, all 4 legs) via teardownScene()/
-- buildScene(), also from v:onParamChanged -- see that registration,
-- right after buildScene()'s definition further down, for the full
-- picture. Since a rebuild snaps the walker back to its starting
-- position, that same handler also clears the red centroid-trail
-- markers (clearTrail(), defined next to the trail-marker code near
-- the bottom) so an old trail from before the rebuild doesn't linger
-- and misrepresent where the walker has actually been since.
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
  cubeMass    = { min = 1,   max = 300, step = 1,
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
setParam("cube_d", 2.5)
setParam("cubeMass", 50.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 10)

v.maxSubSteps = v:getParam("maxSubSteps")

local g_len, a_len, f_len, h_len, p_len = 2.5, 1.0, 5.0, 2.5, 10.0
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.4                     -- spacing between staggered planes

-- The crank and rocker never come close to each other in XY: the crank
-- stays within a_len=1.0 of O2, and the rocker (a rigid h_len=2.5 rod
-- pinned at O4) sweeps no closer than ~1.43 to the O2-A segment over a
-- full crank rotation (checked numerically) -- comfortably more than
-- the ~0.25 two rod cross-sections (rod_w x rod_d) would need to touch.
-- So they can share a Z-plane instead of each getting its own, which
-- drops the stack from 6 distinct planes to 5 -- one plane_gap less of
-- total depth per linkage, moving coupler/pendant/crossbar that much
-- closer to the cube, on both the front and mirrored back face.
function midpoint(p1, p2)
  return { x = (p1.x + p2.x)/2, y = (p1.y + p2.y)/2 }
end

-- one of the two points where a circle (center c1, radius r1) meets
-- a circle (center c2, radius r2) -- this is the law of cosines,
-- just algebraically pre-solved so it costs one sqrt instead of an
-- acos followed by a cos and a sin:
--   cos(theta) = (r1^2 + d^2 - r2^2) / (2*r1*d)   <- law of cosines
--   a  = r1*cos(theta)                            <- adjacent leg
--   hh = r1*sin(theta) = sqrt(r1^2 - a^2)          <- opposite leg (Pythagoras)
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
-- ground: one wide cube shared by both linkages. Wide enough to carry
-- both g-mountings (10 units apart) plus a margin on each outer side.
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

local floor_top_y = 4.6 - p_len

function buildScene()
local cube_d = v:getParam("cube_d")       -- cube's own depth (Z) -- GUI slider -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically
local linkage_spacing = v:getParam("linkageSpacing")   -- GUI slider -- how far apart the two leg mounts on each face sit
local cube_margin = 2.5
cube_w = linkage_spacing + 2*cube_margin   -- global (no "local"): the one-time camera setup further down reads this after buildScene()'s first call
local cube_center_x = linkage_spacing / 2   -- midway between the two mounts (0 and linkage_spacing) -- symmetric for any linkage_spacing, nothing extra needed
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

-- The crank and rocker never come close to each other in XY -- see the
-- header comment -- so they can share a Z-plane instead of each getting
-- its own.
local z_ground, z_crank, z_coupler, z_rocker, z_pendant, z_crossbar =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap

cube = Cube(cube_w, 1.5, cube_d, v:getParam("cubeMass"))   -- GUI slider -- CUBE MASS RE-OPTIMIZED after the foot collision fix (outward_extra 2.0->3.0, inner_gap -1.0->1.0) -- changing the feet's own geometry/contact dynamics shifted the whole mass-vs-distance landscape: previously (buggy, overlapping feet) mass=50 was the peak at net displacement 210; with the feet fixed, that same mass=50 only reaches 138, and the actual peak moved out to mass~150-180 (net displacement 154-166, a broad flat plateau, not a sharp point) -- mass=170 is the best single value found (165.76). Direction also flipped sign (now travels -X instead of +X) purely from the foot fix, nothing else changed. Re-run this sweep again if the foot geometry changes further -- this mass value is coupled to it, not independent.
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
cube.damp_ang = 1.0   -- STRAIGHT-LINE FIX -- see the other Hoecken/Chebyshev-family files in this series: without rotational damping, nothing resists small torque asymmetries between the front/back leg pairs from accumulating into persistent yaw. Confirmed on this file specifically below, not assumed to transfer.
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
-- WMS Was 4.6
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
-- floor: static, placed just below the lowest point any foot reaches
-- over a full crank rotation. Checked numerically (same kind of sweep
-- as the earlier clearance check) -- every linkage cycles through the
-- same B.y range regardless of its phase offset, and the lowest point
-- across that whole range is about y=-5.33 (foot's bottom surface).
-- The floor's top sits at -5.4, a small margin below that, so nothing
-- starts out already penetrating it.
-- ---------------------------------------------------------------------

--local floor_top_y = -5.4
--local floor_w, floor_th, floor_d = 600, 1.0, 600

--floor = Cube(floor_w, floor_th, floor_d, 0)   -- mass 0 -> static
--floor.col = "#694811"
--floor.pos = btVector3(cube_center_x, floor_top_y - floor_th/2, 0)
--floor.friction = 0.8
--v:add(floor)

-- ---------------------------------------------------------------------
-- linkage builder -- one full copy of g/a/f/h/p mounted at x_offset
-- along the cube's face (g_center = (x_offset, 1.25)), with its own
-- motor. g_ang tilts the ground link around its own midpoint; defaults
-- to 0 (along the top edge).
-- ---------------------------------------------------------------------

function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant

  local g_center = { x = x_offset, y = 1.25 + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point in sync with the raised cube -- no flipY in this file (unlike the Spears-linkage walkers), so it's added directly here rather than subtracted
  local O2 = { x = g_center.x - (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y - (g_len/2)*math.sin(math.rad(g_ang)) }
  local O4 = { x = g_center.x + (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y + (g_len/2)*math.sin(math.rad(g_ang)) }

  local a_ang0 = g_ang + 90 + phase
  local A = { x = O2.x + a_len*math.cos(math.rad(a_ang0)),
              y = O2.y + a_len*math.sin(math.rad(a_ang0)) }
  local M = circleIntersect(A, f_len/2, O4, h_len, false)
  local B = { x = 2*M.x - A.x, y = 2*M.y - A.y }
  local C = { x = B.x, y = B.y - p_len }   -- pendant hangs straight down initially

  -- ASPECT RATIO: widened cross-sections (width only, depth left at
  -- rod_d so plane_gap stacking clearance isn't touched) -- I_xx
  -- (off-plane wobble resistance) scales with width^2+depth^2 while
  -- I_zz (the driven rotation, what the motor fights) is dominated by
  -- length^2, so widening buys stiffness far cheaper than it costs in
  -- motor load. Checked numerically per part: crank (len 1.0) 0.18->0.3
  -- gives +89% I_xx for +5.6% motor load; rocker (len 2.5) 0.18->0.5
  -- gives +336% for +3.5%; coupler (len 5.0) 0.18->0.8 gives +938% for
  -- +2.4%; pendant (len 10.0) 0.18->1.0 gives +1493% for +1.0%.
  local crank   = makeLink(O2, A, z_crank_l, 0.3, "coral", 0.3, rod_d)
  local coupler = makeLink(A, B, z_coupler_l, 0.6, "teal", 0.8, rod_d)
  local rocker  = makeLink(M, O4, z_rocker_l, 0.3, "purple", 0.5, rod_d)
  local pendant = makeLink(B, C, z_pendant_l, 1.0, "goldenrod", 1.0, rod_d)
  pendant.damp_ang = 0.00--0.15   -- bleeds off some oscillation energy -- helps at higher speeds, raise if it still overshoots

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  hingeO2:enableAngularMotor(true, speed, 8.0)   -- this is the driven joint -- raise the 3rd arg (maxMotorImpulse) further if you raise the 2nd (target speed)
  trackConstraint(hingeO2)

  -- A: crank <-> coupler
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-f_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  trackConstraint(hingeA)

  -- M: coupler <-> rocker (M is the coupler's own center, so its local pivot is 0,0,0)
  local pivotCoupler_M = btVector3(0, 0, 0)
  local pivotRocker_M  = btVector3(-h_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeM = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_M, pivotRocker_M, axis, axis)
  trackConstraint(hingeM)

  -- O4: rocker <-> cube (this is the pin that has to bridge all three planes)
  local pivotRocker_O4 = btVector3(h_len/2, 0, z_ground_l - z_rocker_l)
  local pivotCube_O4   = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  local hingeO4 = btHingeConstraint(rocker.body, cube.body, pivotRocker_O4, pivotCube_O4, axis, axis)
  trackConstraint(hingeO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings)
  local pivotCoupler_B = btVector3(f_len/2, 0, 0)
  local pivotPendant_B = btVector3(-p_len/2, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  trackConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeM = hingeM, hingeO4 = hingeO4, hingeB = hingeB,
    z_pendant = z_pendant_l, C = C,
  }
end
linkage1 = buildLinkage(0, 0, false, 0, v:getParam("Left Speed"))                 -- front face, x=0,  phase 0
linkage2 = buildLinkage(linkage_spacing, 0, false, 0, v:getParam("Left Speed"))   -- front face, x=10, phase 0
linkage3 = buildLinkage(0, 0, true, 180, v:getParam("Right Speed"))               -- back face,  x=0,  phase 180
linkage4 = buildLinkage(linkage_spacing, 0, true, 180, v:getParam("Right Speed")) -- back face,  x=10, phase 180
-- ---------------------------------------------------------------------
-- crossbar builder: joins the pendant midpoints of two linkages that
-- are identical and driven identically (so their pendants always stay
-- a fixed distance apart with zero relative rotation -- see header).
-- z_pos is the crossbar's own Z-plane; sign matches which face it's on.
--
-- ONE BAR PER SIDE, NOT TWO: an earlier version of this file built TWO
-- independent crossbar bodies per side (at attach_height=-4.5 and
-- +4.5), each with its own full weld (translation AND rotation locked,
-- since a slider-weld locks both by default) to the SAME two pendants.
-- That's over-constrained -- a single weld already fully pins a
-- pendant's pose to its crossbar, so a second, unrelated body welded
-- the same way has no way to stay simultaneously consistent except by
-- exact numerical coincidence. Any tiny solver residual makes the two
-- crossbars fight each other for control of the same pendant, which
-- shows up as visible separation between crossbar and pendant -- not a
-- stiffness problem, a genuinely conflicting-constraint one. Fixed by
-- building ONE bar tall enough (bar_height, default 9.5) to span the
-- same vertical range the old two bars covered, welded once per pendant
-- instead of twice. Visually this trades the old "two thin struts" look
-- for a single wider plate.
-- ---------------------------------------------------------------------
function buildCrossbar(lkA, lkB, z_pos, color, bar_height)
  bar_height = bar_height or 9.5   -- was two 0.18-thick bars at +-4.5; this spans the same -4.5..+4.5 range as one body
  local PA, PB = lkA.pendant.pos, lkB.pendant.pos
  local len = math.sqrt((PB.x-PA.x)^2 + (PB.y-PA.y)^2)   -- should equal linkage_spacing, by symmetry
  local mid_x = (PA.x + PB.x) / 2

  local bar = Cube(len, bar_height, rod_d, 1.0)
  bar.col = color
  bar.trans = btTransform(IDENTITY_QUAT, btVector3(mid_x, PA.y, z_pos))   -- centered ON the pendant's own line -- no attach_height offset needed now there's only one bar
  bar.damp_ang = 0.15
  track(bar)

  -- both pendants in a pair share the same orientation at construction
  -- (same geometry, just translated), so this one quaternion is the
  -- correct weld-frame rotation for both ends.
  local pendant_quat = lkA.pendant.trans:getRotation()

  local frameInBar_A = btTransform(pendant_quat, btVector3(-len/2, 0, lkA.z_pendant - z_pos))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldA = btSliderConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLowerLinLimit(0)   -- btSliderConstraint defaults to FREE translation unless set --
  weldA:setUpperLinLimit(0)   -- these two calls are what actually makes this a rigid weld
  trackConstraint(weldA)

  local frameInBar_B = btTransform(pendant_quat, btVector3(len/2, 0, lkB.z_pendant - z_pos))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldB = btSliderConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLowerLinLimit(0)
  weldB:setUpperLinLimit(0)
  trackConstraint(weldB)

  return bar
end
crossbarFront = buildCrossbar(linkage1, linkage2, z_crossbar, "slateblue")
crossbarBack  = buildCrossbar(linkage3, linkage4, -z_crossbar, "slateblue")
-- ---------------------------------------------------------------------
-- foot builder: a wide, flat pad welded (not hinged) to the bottom of
-- a pendant, extending from the pendant's own Z-plane inward to z=0 --
-- the cube's own centerline -- so each foot reaches under the body
-- rather than just sitting out at the side where its pendant hangs.
-- Built unrotated (like the front/back crossbars), with the Z-extent
-- baked directly into the Cube's own depth dimension, so no rotation
-- bookkeeping is needed for the body itself -- only the weld frame's
-- rotation needs to match the pendant's actual orientation, using the
-- same identity-body-plus-matched-frame trick as the crossbars.
-- ---------------------------------------------------------------------
function buildFoot(lk, color)
  local C = lk.C
  local zp = lk.z_pendant
  local dir = zp >= 0 and 1 or -1
  local outward_extra = 3.0            -- how far the foot reaches PAST the pendant, away from the body
  local inner_gap = 1.0 -- -1.0--0.3    -- stops short of z=0 by this much, so opposing feet don't touch at the center -- was -1.0, which actually crossed PAST z=0 onto the other side (front foot reaching to z=-1, back foot reaching to z=+1, overlapping by 2 units in the middle) -- this is what was colliding

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.2)   -- heavier than before (was 0.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  track(foot)

  local pendant_quat = lk.pendant.trans:getRotation()
  -- the pendant attaches at z=zp, which is now partway along the foot's
  -- length (not at its end), since the foot extends past it on both sides
  local frameInFoot    = btTransform(pendant_quat, btVector3(0, 0, zp - foot_center_z))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(p_len/2, 0, 0))   -- C is the pendant's own "+X end"
  local weld = btSliderConstraint(foot.body, lk.pendant.body, frameInFoot, frameInPendant, true)
  weld:setLowerLinLimit(0)   -- see the earlier note: slider defaults to FREE translation unless locked
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
-- camera
-- ---------------------------------------------------------------------
  local CAM_SCALE = cube_w / 15

  common.setCamera(btVector3(cube.pos.x - 120*CAM_SCALE, cube.pos.y, cube.pos.z + 120*CAM_SCALE),               btVector3(cube.pos.x, cube.pos.y, cube.pos.z), 0.15)

common.gravity(-9.8)
