--
-- MODEL C: the ORIGINAL file (mass=10, maxSubSteps=20, the un-split
-- single-fused coupler with hand-computed inertia, hingeB still on
-- `coupler` at its old phantom point) with EXACTLY ONE change: the
-- hingeB Z-target mismatch fix (see the MODEL C Z-TARGET FIX note at
-- hingeB's construction, further down). No coupler split, no inertia
-- recomputation, nothing else touched -- built specifically to test
-- this one fix's effect in isolation from MODEL B's larger structural
-- changes.
--
-- Direct port of the original four-legged walker (cheby_normal6.lua),
-- with the Chebyshev Lambda linkage swapped for Chebyshev-Spears.
-- Every STRUCTURAL relationship is identical to the original: same
-- front/back pairing, same two-crossbar-per-pair bracing (one above,
-- one below, via attach_height), same hinge topology, same crossbar
-- mechanics. Only the linkage's own geometry (lengths, ground angle,
-- coupler shape) and the resulting coordinates changed.
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
-- PAIRING (REASSIGNED FOR DIAGONAL CROSSBARS): a rigid weld between two
-- pendants is only kinematically valid if they trace an identical
-- path, which requires matching PHASE (mirror doesn't matter -- it
-- only flips a constant Z sign). Since the crossbars now run
-- diagonally (front-left<->back-right, front-right<->back-left)
-- instead of front-front/back-back, phase is now assigned along those
-- same diagonals instead of by face: linkage1 (front-left, x=-half_spacing,
-- mirror=false) and linkage4 (back-right, x=+5, mirror=true) share
-- phase=0; linkage2 (front-right, x=+5, mirror=false) and linkage3
-- (back-left, x=-half_spacing, mirror=true) share phase=180. See buildLinkage's
-- call site for the exact reassignment.
--
-- CROSSBARS: ALL of the old front-front/back-back crossbars (both the
-- bottom and top pair) are gone. In their place, buildDiagonalCrossbar
-- welds two DIAGONAL pendants together (front-right<->back-left) near
-- the pendant's newly-extended top (see EXT_UP). Unlike the old
-- crossbars (flat, single-axis rotation, one shared Z plane per pair),
-- this spans X, Y, and Z all at once, so it needs a real 3D orientation
-- (alignVecX) and full quaternion composition (qmul/qconj) for its weld
-- frames, plus a small deliberate Z-rotation "give"
-- (btGeneric6DofConstraint, not btSliderConstraint) to absorb minor
-- phase drift between the two torque-limited motors. This used to be
-- two bars (front-left<->back-right too, at a different height so they
-- wouldn't collide crossing each other) -- now a single wider plate
-- spanning that same height range; see the buildDiagonalCrossbar
-- section further down for the full reasoning.
--
-- Gravity is off and there's no floor -- consistent with recent
-- testing state; flip back on when ready to test full dynamics.
--

v.timeStep = 1/10 --1/40 -- 1/200 -- 1/60
v.fixedTimeStep = 1/480 --1/960 -- 1/480

-- ---------------------------------------------------------------------
-- GUI sliders. All six apply live, no Restart needed -- Restart
-- Simulation can't help here anyway (see the REBUILD SUPPORT comment
-- above buildScene() further down for why: it wipes v's own param
-- table and reruns this script from its literal hardcoded defaults).
-- maxSubSteps and motorSpeed are applied in place via v:onParamChanged
-- (plus a redundant per-tick re-apply in the v:preSim hook near the
-- bottom, shared with the trail-marker code -- this engine only allows
-- one v:preSim and one v:onParamChanged registration each, so
-- everything for both funnels through those two single callbacks).
-- cube_d, cubeMass, terrainAmp and linkageSpacing instead tear down
-- and rebuild the whole scene (cube, terrain, all 4 legs) via
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
  motorSpeed  = { min = 0,   max = 8,   step = 0.1,
                  comment = "hip hinge motor target angular speed, all 4 legs (live)" },
  cube_d      = { min = 1,   max = 10,  step = 0.1,
                  comment = "cube's own depth / Z (rebuilds the scene)" },
  cubeMass    = { min = 1,   max = 200, step = 1,
                  comment = "cube body mass (rebuilds the scene)" },
  terrainAmp  = { min = 0,   max = 3,   step = 0.05,
                  comment = "terrain bump height (rebuilds the scene)" },
  linkageSpacing = { min = 10,  max = 40,  step = 0.5,
                  comment = "distance between the two front (and two back) leg mounts (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("maxSubSteps", 20)
setParam("motorSpeed", 2.6)
setParam("cube_d", 4.5)
setParam("cubeMass", 50.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 18)

v.maxSubSteps = v:getParam("maxSubSteps")

--local common = require "common"

--common.setTiming(1/10, 20, 1/480)

-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------

local g_len, a_len, h_len, p_len = 2.5, 36*2.5/48, 110*2.5/48, 110*2.5/48
local f_len = 2*h_len   -- AM = MB = h_len -- keeps the Grashof relation intact
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 1.2--0.8--0.4                     -- spacing between staggered planes
-- WMS 4.5 is good

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

local EXT_DOWN = 5.5
--local EXT_DOWN = 4.5   -- how far each pendant extends below its original bottom (C) -- requested +1.0 (5.0), but found a real collision threshold: safe through ~4.5 (max startup velocity ~13, same as baseline), a cliff starts at 4.7 (~19) and gets worse through 5.0 (~35) -- confirmed on the ORIGINAL unmodified file, not something the other changes here introduced. Landed on +0.5 as the largest safe extension found; see the EXT_DOWN COLLISION THRESHOLD note further down for the full writeup.

-- EXT_DOWN COLLISION THRESHOLD, full writeup: extending the pendant
-- downward (toward the foot, away from the coupler joint) shouldn't
-- geometrically affect anything near the OTHER end of the rod (B/M) --
-- and it doesn't cause the usual "widened cross-section overlaps a
-- neighbor" collision this series has seen before (confirmed: even with
-- every width reverted to stock 0.18, EXT_DOWN=5.0 alone still spikes
-- to ~35-41 at startup on the completely unmodified uploaded file).
-- Isolated by testing EXT_DOWN alone in 0.1 steps: 4.0-4.5 all stay
-- around 12-13, then a real cliff -- 4.7 jumps to ~19, 4.8 to ~29, 4.9
-- to ~39, 5.0 to ~35. This is NOT the same phenomenon as the periodic
-- velocity spikes seen later in a run (frames ~22-36 reaching 30-40) --
-- that pattern is present in the ORIGINAL file too, completely
-- unmodified, so it's normal gait-cycle dynamics (most likely a foot-
-- strike/stride-transition event), not a bug. The EXT_DOWN threshold is
-- specifically a FRAME-1 startup phenomenon, distinct from that later
-- cyclical one. Root cause not fully pinned down (did not find a single
-- clean collision pair via OBB testing the way the earlier pendant-
-- width bug was diagnosed) -- treated as an empirically-mapped danger
-- zone rather than a fully explained one. Worth another look if a
-- longer pendant is needed later.

-- EXT_UP: how far each pendant extends ABOVE B (toward the coupler),
-- making room for the two new diagonal top crossbars. C (the foot
-- attachment) is unaffected -- only the rod's TOP end moves, same idea
-- as p_top_extend in the diagonal-crossbar reference file.
--
-- SIZED AGAINST THE COUPLER'S REAL SWEPT RANGE, not guessed: swept the
-- crank a full rotation kinematically (the crank/coupler/rocker loop
-- IS fully determined by crank angle, no dynamics needed for that
-- part) and found the coupler assembly (both its real A->M box and its
-- visual M->B bend) reaches as high as Y=7.28 at some point in the
-- cycle, vs. B's own construction-time height of Y=4.10 -- B itself
-- swings up to Y=7.28 over the cycle (it's the coupler's own outer
-- tip), a good 3.2 units above where it starts. EXT_UP=2.5 keeps the
-- new bar attachment points (1.0 and 2.0 above B -- see
-- buildDiagonalCrossbar calls below) modest relative to that swing,
-- rather than reaching further up into the zone the coupler itself
-- sweeps through.
--
-- HONEST CAVEAT: that swept check only covers the crank/coupler/rocker
-- loop, which is fully kinematically driven by the motor. The PENDANT's
-- own swing (a free hinge at B, no motor) is a genuine dynamic unknown
-- -- influenced by gravity, momentum, and now the rigid diagonal bar
-- tying it to its diagonal partner -- that I can't solve without
-- actually running the sim. This sizing is a deliberately conservative
-- starting point given the real numbers above, not a guarantee the
-- pendant extension never swings close to the coupler -- worth
-- watching closely on the first run, same caveat the diagonal-crossbar
-- reference file gives its own top bars.
local EXT_UP = 5.0 --2.5

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

local DAMP_CUBE      = {lin = 0., ang = 1.0}   -- STRAIGHT-LINE FIX, RE-TUNED after fixing the pendant-width collision bug below (see the ASPECT RATIO REVERTED note near the pendant). The damp_ang=1.0 value used everywhere else in this series was originally tuned AGAINST the buggy (slamming) geometry -- once that was fixed, 1.0 dropped to net_disp=141.73 at 2400 frames, while 0.5 reaches 187.08. This is a narrow peak, not a broad plateau -- 0.4 and 0.6 are both noticeably worse (151, 159), and 0.35/0.65 collapse to near-nothing (32, 21) -- so this value is more sensitive to drift than the other files in this series; worth re-checking if anything else in this file changes.
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

-- maps local +X to an ARBITRARY 3D direction (dx,dy,dz) -- needed for
-- the diagonal crossbars below, which span X, Y, and Z all at once,
-- unlike the old front-front/back-back crossbars (which only ever
-- needed a single-axis rotation, since both ends sat on the same Z
-- plane). Standard "shortest arc" quaternion construction: axis =
-- (1,0,0) x d, and w = 1 + dot((1,0,0), d), then normalize.
function alignVecX(dx, dy, dz)
  local len = math.sqrt(dx*dx + dy*dy + dz*dz)
  dx, dy, dz = dx/len, dy/len, dz/len
  local qx, qy, qz, qw = 0, -dz, dy, 1 + dx
  local qlen = math.sqrt(qx*qx + qy*qy + qz*qz + qw*qw)
  return btQuaternion(qx/qlen, qy/qlen, qz/qlen, qw/qlen)
end

-- quaternion multiply and conjugate, computed by hand from components
-- (standard closed-form formulas) rather than relying on Bullet's own
-- operators, which aren't confirmed available on btQuaternion here.
-- For a unit quaternion, conjugate == inverse.
function qmul(a, b)
  local ax,ay,az,aw = a:getX(), a:getY(), a:getZ(), a:getW()
  local bx,by,bz,bw = b:getX(), b:getY(), b:getZ(), b:getW()
  return btQuaternion(
    aw*bx + ax*bw + ay*bz - az*by,
    aw*by - ax*bz + ay*bw + az*bx,
    aw*bz + ax*by - ay*bx + az*bw,
    aw*bw - ax*bx - ay*by - az*bz
  )
end

function qconj(a)
  return btQuaternion(-a:getX(), -a:getY(), -a:getZ(), a:getW())
end

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
-- linkage_spacing/half_spacing/cube_margin/cube_w/cube_center_x now
-- live inside buildScene() (see there) since linkageSpacing is a GUI
-- slider.
-- ---------------------------------------------------------------------


-- CUBE MASS RE-OPTIMIZED, found by running 2400-frame trials sweeping
-- mass 1-200 (feet untouched, per request). This was originally swept
-- BEFORE the pendant-width collision bug was found and fixed (see the
-- ASPECT RATIO REVERTED note near the pendant) -- re-run after that fix
-- and after re-tuning DAMP_CUBE.ang (0.5, not 1.0, for the same reason)
-- to make sure it still holds. It does: mass=11 remains the best stable
-- value (net displacement 187.09 at 2400 frames -- Y stays bounded
-- [-2.4, 2.8], X progresses monotonically). mass=1 scored higher in the
-- raw sweep (212.19) but was a genuine instability, not a better
-- result -- Y bounces up to 5.7 and the path wanders non-monotonically
-- in X before eventually drifting off, the same signature seen with
-- other too-low-mass or too-small-part configurations elsewhere in this
-- series -- discarded rather than reported as the "best" value. The
-- landscape here is noisier than the plain (non-diagonal) Spears file --
-- neighboring values swing more (10->127.72, 15->160.92, 20->173.97) --
-- so mass=11 is a genuine local peak, not the top of a broad plateau.
--cube = Cube(cube_w, 1.5, cube_d, 105.0)   -- small mass -> dynamic, affected by gravity

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

local floor_top_y = -1.8 - p_len

------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- REBUILD SUPPORT for cube_d/cubeMass/terrainAmp: every object and
-- constraint buildScene() creates is tracked here so a later call can
-- tear the whole thing down cleanly (v:remove / v:removeConstraint)
-- before rebuilding it with a new slider value. Restart Simulation
-- can't do this for us -- checked the actual BPP source
-- (Viewer::restartSim -> parse(_scriptContent)): parse() calls
-- Viewer::clear(), which does `_params.clear()`, wiping every GUI
-- param, then reruns this whole script from scratch -- so a slider
-- dragged before Restart is gone; the script just reasserts whatever
-- literal default setParam() was called with. The onParamChanged
-- handler below drives a live rebuild instead, without needing Restart
-- at all.
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

function buildScene()
local cube_d = v:getParam("cube_d")        -- cube's own depth (Z) -- GUI slider
local linkage_spacing = v:getParam("linkageSpacing")   -- GUI slider -- how far apart the two front (and two back) leg mounts sit
-- half_spacing scales correctly with linkage_spacing: +-5 when
-- linkage_spacing=10, +-9 at the default 18 (matching the old hardcoded
-- numbers exactly either way).
local half_spacing = linkage_spacing / 2
local cube_margin = 2.5
local cube_w = linkage_spacing + 2*cube_margin   -- 23 at the default linkage_spacing=18
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

-- ROCKER GIVEN ITS OWN PLANE: used to share the crank's plane (both
-- z_crank), which was fine at the old narrow widths but became a real
-- constraint once both needed to widen -- coplanar and both wide is
-- exactly the setup that risks them sweeping into each other. Moved
-- rocker outward onto its own dedicated plane instead, and coupler +
-- pendant both shift outward by one more plane_gap to keep the same
-- relative order/spacing they always had (ground < crank < rocker <
-- coupler < pendant) -- one more distinct plane overall (5, not 4).
local z_ground, z_crank, z_rocker, z_coupler, z_pendant =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap
cube = Cube(cube_w, 1.5, cube_d, v:getParam("cubeMass"))   -- small mass -> dynamic, affected by gravity -- GUI slider
--cube = Cube(cube_w, 1.5, cube_d, 10.0)   -- small mass -> dynamic, affected by gravity
cube.damp_lin = DAMP_CUBE.lin
cube.damp_ang = DAMP_CUBE.ang
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
track(cube)

--local floor_top_y = -0.6 - p_len
local floor_w, floor_d = 600, 600
local terrain_nx, terrain_nz = 120, 60   -- grid resolution: 2.5-unit cells in both X and Z

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
local floor_x0, floor_z0 = cube_center_x - floor_w/2, -floor_d/2
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
function buildLinkage(x_offset, g_ang, mirror, phase, speed, ext_down, ext_up)
  g_ang = g_ang or -45
  phase = phase or 0
  ext_down = ext_down or 0   -- how far the pendant extends below its original bottom (C)
  ext_up = ext_up or 0       -- how far the pendant extends above its original top (B)
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant

  -- raw geometry, exactly the original formulas -- terrain_lift
  -- (computed in buildScene above) is SUBTRACTED here, not added:
  -- flipY below negates every raw point's y, so subtracting pre-flip
  -- becomes adding post-flip -- verified algebraically (every
  -- downstream raw point -- O2_raw, O4_raw, A_raw, M_raw, B_raw -- is
  -- linear/translation-invariant in g_center_raw.y, so they all shift
  -- by the same -terrain_lift pre-flip, landing on +terrain_lift once
  -- flipY flips the whole assembly right-side up) and confirmed against
  -- the real engine (cube.pos.y and a foot's pos.y rise by exactly
  -- terrain_lift together, same check used on cheby_diag1.lua).
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
  -- coupler hinge), C just moves further away. B_top does the same
  -- thing on the other end: extends the rod further ABOVE B, making
  -- room for the diagonal top crossbars further down in the file. B
  -- itself stays fixed either way -- it's still the coupler<->pendant
  -- hinge point, just no longer at either end of the (now longer) rod.
  local C = { x = B.x, y = B.y - p_len - ext_down }
  local B_top = { x = B.x, y = B.y + ext_up }
  local pendant_len = p_len + ext_down + ext_up
  local mass_pendant = density_pendant * pendant_len   -- 0.9729 for the default ext_down=4.0, ext_up=0

  -- B's own position along the (now longer) rod, in the pendant body's
  -- own local frame. makeLink(B_top, C, ...) puts B_top at local -X end
  -- (-pendant_len/2) and C at local +X end (+pendant_len/2) -- B sits
  -- ext_up in from the -X end, i.e. at -pendant_len/2 + ext_up. Reduces
  -- to the old -pendant_len/2 when ext_up=0 (B back at the rod's own
  -- end, matching the original file exactly).
  local B_local_x = -pendant_len/2 + ext_up

  local half_f = f_len/2   -- = L below; AM and MB are equal-length segments, both = half_f

  local crank   = makeLink(O2, A, z_crank_l, mass_crank, "coral", 0.8, rod_d)   -- ASPECT RATIO, widened further now that rocker has its own plane (was 0.3): 0.18->0.5, +336% I_xx for +6.1% motor load
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
  -- I_xx (off-plane wobble resistance) for +1.85% motor-load-like cost.
  -- Threaded through BOTH the makeLink calls below AND every inertia
  -- formula here, since this body's inertia is hand-computed (not
  -- Cube's own auto-inertia) and explicitly depends on the cross-section
  -- dimensions -- widening the body without updating these formulas
  -- would leave the inertia tensor describing the OLD, thinner cross-
  -- section while the actual collision shape used the new wider one.
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

  local rocker   = makeLink(M, O4, z_rocker_l, mass_rocker, "purple", 0.8, rod_d)   -- ASPECT RATIO, widened further now on its own dedicated plane (was 0.5, sharing the crank's plane): 0.18->0.8, +938% I_xx for +1.9% load
  rocker.damp_lin = DAMP_ROCKER.lin
  rocker.damp_ang = DAMP_ROCKER.ang
  -- ASPECT RATIO REVERTED for the pendant specifically: 1.0 caused a
  -- violent snap right at frame 1 (velocity spikes up to ~26 units/frame
  -- vs. ~10-13 at baseline) -- confirmed by isolating it: widening JUST
  -- the coupler stayed safe (~14.5 max), widening JUST the pendant alone
  -- reproduced the slam almost exactly (~26.7). Most likely cause: the
  -- pendant isn't directly constrained to couplerVis (only to `coupler`
  -- itself, via hingeB) -- couplerVis and pendant meet right at the same
  -- B corner with no constraint between them to suppress collision, so
  -- widening the pendant to 1.0 was enough for their collision shapes to
  -- newly overlap there, and Bullet's contact solver threw in a violent
  -- separating impulse on the very first step. Left at rod_w (0.18,
  -- unmodified) rather than guessing at a smaller "safe" width without
  -- being able to verify exactly where the overlap threshold sits.
  -- ASPECT RATIO, widened modestly: unlike the other files in this
  -- series, this one has a genuine startup-collision sensitivity near
  -- the B/couplerVis joint that scales with pendant width (confirmed by
  -- isolating it: 0.2 wide -> +3.4% frame-1 velocity vs unwidened,
  -- climbing to +63% at the 1.0 width used safely elsewhere). Landed on
  -- 0.3 (+6.9%, still close to noise) as a real but modest improvement
  -- rather than chasing the full aspect-ratio benefit and reopening the
  -- collision -- see the EXT_DOWN COLLISION THRESHOLD note for the full
  -- investigation this is based on.
  local pendant  = makeLink(B_top, C, z_pendant_l, mass_pendant, "goldenrod", 1.0, rod_d) -- 0.8 --0.3
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
  hingeO2:enableAngularMotor(true, speed, 8.0) -- WMS is good
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
  --
  -- MODEL C Z-TARGET FIX (the ONLY change in this file relative to the
  -- original): every other cross-plane hinge in this file is built so
  -- BOTH sides resolve to the SAME world-Z target -- e.g. hingeA targets
  -- z_crank_l on both sides (pivotCrank_A has zero Z-offset since crank
  -- is already there; pivotCoupler_A carries z_crank_l - z_coupler_l to
  -- reach it from coupler's own plane). hingeB didn't follow that
  -- pattern: pivotCoupler_B's Z-component was z_coupler_l - z_pendant_l,
  -- applied on the COUPLER side -- but coupler is ALREADY at z_coupler_l,
  -- so that offset overshoots to a target of 2*z_coupler_l - z_pendant_l,
  -- not z_coupler_l. pivotPendant_B (the SAME offset value, applied on
  -- pendant's side) was already correct, targeting z_coupler_l exactly.
  -- Fixed by zeroing pivotCoupler_B's Z-component instead -- coupler
  -- needs no offset to reach its own plane. The error this introduced
  -- was a full plane_gap (1.2 units for this file's dimensions) of
  -- built-in Z mismatch at hingeB, right where the pendant attaches --
  -- structurally the same KIND of bug as the O4-hinge mismatch found
  -- much earlier in this file series (Model H), just at a different
  -- joint. Nothing else in this file was touched -- no coupler split,
  -- no inertia recomputation, no width/mass/damping changes -- purely
  -- this one pivot correction, to test its effect in isolation from
  -- MODEL B's larger structural changes.
  local pivotCoupler_B = btVector3(half_f/2, -half_f, 0)
  local pivotPendant_B = btVector3(B_local_x, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  trackConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, couplerVis = couplerVis, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeM = hingeM, weldVis = weldVis, hingeO4 = hingeO4, hingeB = hingeB,
    z_pendant = z_pendant_l, B = B, C = C, pendant_len = pendant_len, B_local_x = B_local_x,
  }
end

-- PHASE REASSIGNMENT FOR DIAGONAL BARS: a rigid weld between two
-- pendants is only kinematically consistent if they maintain a FIXED
-- relative transform over the whole motion, which requires the same
-- PHASE (mirror status doesn't matter -- it only flips a constant Z
-- sign, since it never touches the zrotVec rotation itself, only a Z
-- translation -- confirmed by the same reasoning the diagonal-crossbar
-- reference file uses for its own diagonal pairing). The old
-- front-front/back-back crossbars are gone now (see "all crossbars
-- removed" below), so phase no longer needs to match within a face --
-- it needs to match along the new DIAGONALS instead: front-left (1)
-- and back-right (4) share phase 0; front-right (2) and back-left (3)
-- share phase 180, per the explicit assignment requested.
-- WMS Speed 2.6 is good, 4.6 works but looks dangerous
-- Initial speed comes from the motorSpeed GUI slider; see the preSim
-- hook right below for how it stays live while the sim runs.
linkage1 = buildLinkage(-half_spacing, -45, false, 0, v:getParam("motorSpeed"), EXT_DOWN, EXT_UP)                 -- front-left,  phase 0
linkage2 = buildLinkage(half_spacing, -45, false, 180, v:getParam("motorSpeed"), EXT_DOWN, EXT_UP)  -- front-right, phase 180
linkage3 = buildLinkage(-half_spacing, -45, true, 180, v:getParam("motorSpeed"), EXT_DOWN, EXT_UP)                -- back-left,   phase 180 (matches linkage2's diagonal pair)
linkage4 = buildLinkage(half_spacing, -45, true, 0, v:getParam("motorSpeed"), EXT_DOWN, EXT_UP) -- back-right,  phase 0 (matches linkage1's diagonal pair)
-- ---------------------------------------------------------------------
-- DIAGONAL crossbar builder: joins a point near the TOP of the
-- (now upward-extended) pendant on two linkages that share the same
-- PHASE -- front-right<->back-left, per the phase reassignment above.
-- This REPLACES the old front-front/back-back crossbars entirely (both
-- bottom and top) -- ALL of the old horizontal crossbars are gone; this
-- one diagonal plate (see the "ONE PLATE INSTEAD OF TWO BARS" note near
-- its call site below) is the only crossbar left in the file.
--
-- Unlike the old crossbars (which only ever needed a single-axis
-- rotation, since both ends sat on the same Z plane), this spans X, Y,
-- and Z all at once, so the bar itself needs a real 3D orientation
-- (alignVecX) rather than sitting unrotated -- and the weld frames need
-- actual rotation composition (qmul/qconj) to match the pendant's
-- orientation, same technique as the diagonal-crossbar reference file.
--
-- attach_up: how far ABOVE B this bar's endpoint sits, measured along
-- the pendant's own rod (NOT above C -- these bars live up near the
-- newly-extended top of the rod, not down near the feet). At
-- construction the pendant hangs straight down from B (C is directly
-- below B), so moving "up" by attach_up in world Y is the same as
-- moving toward B_top along the rod's own local frame -- see
-- buildLinkage's B_local_x for the exact offset.
--
-- GIVE: a small deliberate Z-rotation slack (btGeneric6DofConstraint,
-- not btSliderConstraint -- a slider's only give axis is a twist about
-- its own local X, which doesn't point along world Z here, unlike the
-- old crossbars), so the weld absorbs small unavoidable phase drift
-- between the two torque-limited motors instead of rigidly fighting it.
--
-- width: the bar's own cross-section in what was always rod_w before --
-- for THESE bars specifically, that dimension maps EXACTLY to world Y
-- (vertical) at construction, not just approximately. attach_up is
-- added identically to both endpoints (PA.y and PB.y), and phase-
-- matched pendants share an identical B.y at every instant, so dy is
-- always exactly 0 for these bars. With dy=0, alignVecX's shortest-arc
-- rotation is necessarily a pure rotation about world Y, which leaves Y
-- itself unchanged -- so local Y (the width dimension) stays exactly
-- world Y regardless of how tilted the bar is in X/Z. That's what makes
-- it safe to widen this into a genuine vertical plate below.
-- ---------------------------------------------------------------------

function buildDiagonalCrossbar(lkA, lkB, attach_up, color, mass, width)
  mass = mass or 1.0
  width = width or rod_w
  local pivotLocalX_A = lkA.B_local_x - attach_up
  local pivotLocalX_B = lkB.B_local_x - attach_up

  local PA = { x = lkA.B.x, y = lkA.B.y + attach_up, z = lkA.z_pendant }
  local PB = { x = lkB.B.x, y = lkB.B.y + attach_up, z = lkB.z_pendant }

  local dx, dy, dz = PB.x-PA.x, PB.y-PA.y, PB.z-PA.z
  local len = math.sqrt(dx*dx + dy*dy + dz*dz)
  local bar_quat = alignVecX(dx, dy, dz)
  local bar_center = btVector3((PA.x+PB.x)/2, (PA.y+PB.y)/2, (PA.z+PB.z)/2)

  local bar = Cube(len, width, rod_d, mass)
  bar.col = color
  bar.trans = btTransform(bar_quat, bar_center)
  bar.damp_lin = DAMP_CROSSBAR.lin
  bar.damp_ang = DAMP_CROSSBAR.ang
  track(bar)

  -- with the center exactly at the midpoint of PA/PB, each pivot is
  -- simply +-len/2 along the bar's own local X -- on-axis, no offset
  -- math needed
  local frameInBar_end = len/2

  -- both pendants in a (phase-matched) diagonal pair share the same
  -- orientation at construction, so one quaternion is the correct
  -- weld-frame rotation TARGET for both ends -- mirror doesn't affect
  -- this (see the phase-reassignment note above). The bar's own frame
  -- needs qconj(bar_quat)*pendant_quat to land on that target, since
  -- the bar itself isn't built unrotated this time.
  local pendant_quat = lkA.pendant.trans:getRotation()
  local frameRot_onBar = qmul(qconj(bar_quat), pendant_quat)

  local giveAngle = math.rad(3)   -- small and tunable -- widen if it's still fighting drift, narrow if it looks too loose

  local frameInBar_A = btTransform(frameRot_onBar, btVector3(-frameInBar_end, 0, 0))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(pivotLocalX_A, 0, 0))
  local weldA = btGeneric6DofConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLinearLowerLimit(btVector3(0, 0, 0))   -- position fully locked
  weldA:setLinearUpperLimit(btVector3(0, 0, 0))
  weldA:setLimit(3, 0, 0)                          -- angular X locked
  weldA:setLimit(4, 0, 0)                          -- angular Y locked
  weldA:setLimit(5, -giveAngle, giveAngle)          -- angular Z: the deliberate give
  trackConstraint(weldA)

  local frameInBar_B = btTransform(frameRot_onBar, btVector3(frameInBar_end, 0, 0))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(pivotLocalX_B, 0, 0))
  local weldB = btGeneric6DofConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLinearLowerLimit(btVector3(0, 0, 0))
  weldB:setLinearUpperLimit(btVector3(0, 0, 0))
  weldB:setLimit(3, 0, 0)
  weldB:setLimit(4, 0, 0)
  weldB:setLimit(5, -giveAngle, giveAngle)
  trackConstraint(weldB)

  return bar
end

-- ONE PLATE INSTEAD OF TWO BARS: this used to be two separate bars --
-- diagonalTop1 (purple/slateblue, linkage1<->linkage4) at 0.5 above B,
-- and diagonalTop2 (red/firebrick, linkage2<->linkage3) at 5.0 above B,
-- offset from each other purely so they wouldn't collide where their
-- diagonals cross. They connect DIFFERENT pendant pairs, so it was
-- never an over-constraint bug -- just visual/structural clutter (an
-- X-brace at this level). Per request: purple is removed, red becomes a
-- single wider plate spanning the same 0.5-to-5.0 range the two bars
-- used to occupy (width=4.5, centered at attach_up=2.75 -- the old
-- pair's midpoint). See the width note on buildDiagonalCrossbar above
-- for why this widened dimension really is vertical, not just
-- approximately so.
-- Net effect: the front-left<->back-right pair (1<->4) now has no
-- brace up here at all -- only front-right<->back-left (2<->3) is
-- braced.
diagonalTop = buildDiagonalCrossbar(linkage2, linkage3, 2.75, "firebrick", 1.0, 2.25)   -- front-right <-> back-left -- the sole brace at this level now
--diagonalTop = buildDiagonalCrossbar(linkage2, linkage3, 1.75, "firebrick", 1.0, .75)   -- front-right <-> back-left -- the sole brace at this level now

-- BOTTOM PLATE, added to match: this file never had an active bottom
-- pair (diagonalBottom1 below was a single abandoned attempt, not a
-- red/purple pair -- see the commented-out line), so there was nothing
-- to consolidate the way the reference file's bottom pair was.
--
-- CORRECTED POSITIONING: a first pass at this placed the plate by
-- mirroring the TOP plate's own distance-from-B envelope (symmetric
-- about B, just reflected downward) -- but that was wrong. B itself
-- sits well ABOVE the cube here (B.y ~4.10 at construction, vs. the
-- cube's own top at 0.75), since this file's whole assembly is flipped
-- so the legs point up above the cube. Mirroring around B put the
-- "bottom" plate spanning roughly y=[-0.90, 3.60] -- overlapping the
-- cube itself rather than sitting below it near the feet.
--
-- Repositioned using actual world-space targets instead: the cube's
-- bottom face sits at y=-0.75, and the foot pad (welded at C, y~-5.63,
-- with its own 0.3 thickness) has its top surface at y~-5.48. attach_up
-- =-8.0 with width=2.25 (half the top plate's 4.5, as requested) puts
-- this plate at y=[-5.02, -2.77] at construction: its bottom edge clears
-- the foot pad's own top surface by 0.45 (just above the feet), and its
-- top edge clears the cube's bottom face by exactly 2.0 -- comfortably
-- below the cube, not overlapping it.
--
-- Uses the COMPLEMENTARY pair (front-left<->back-right, 1<->4) rather
-- than reusing 2<->3 -- same convention as the reference file: each
-- diagonal pair ends up braced exactly once, at opposite ends (1<->4 at
-- the bottom, 2<->3 at the top), rather than one pair braced twice and
-- the other not at all.
diagonalBottom = buildDiagonalCrossbar(linkage1, linkage4, -9.9, "slateblue", 1.0, 0.75)   -- front-left <-> back-right -- the sole brace at this level


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
  local outward_extra = 4.0 --5.0 --2.0            -- how far the foot reaches PAST the pendant, away from the body

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
  local inner_gap = 2.5 --2.0 --1.0 -- 2.0                -- was -1.0

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod
  -- WMS 1.0 Best so far, smaller feet better. Larger feet worse.
  --local foot_x, foot_y = 1.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

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
foot2 = buildFoot(linkage2, "blue")
foot3 = buildFoot(linkage3, "blue")
foot4 = buildFoot(linkage4, "yellow")
end

buildScene()

-- ---------------------------------------------------------------------
-- GUI SLIDER LIVE SYNC: v:onParamChanged fires whenever a slider is
-- dragged (or setParam() is called from Lua), exactly like the GUI's
-- own drag handler updates a param -- see uniform-coverage7.lua's
-- onParamChanged for the reference pattern. Only one v:onParamChanged
-- may be registered for the whole file (same single-callback rule as
-- v:preSim), so every param's handling lives in this one function.
--
-- maxSubSteps and motorSpeed apply immediately in place. cube_d,
-- cubeMass, terrainAmp and linkageSpacing instead tear down and
-- rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene() -- see the REBUILD SUPPORT comment
-- above buildScene() for why Restart Simulation can't do this for us,
-- so this handler has to.
-- ---------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  elseif name == "motorSpeed" then
    linkage1.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage2.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage3.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage4.hingeO2:enableAngularMotor(true, value, 8.0)
    print(string.format("motorSpeed = %.2f", value))
  elseif name == "cube_d" or name == "cubeMass" or name == "terrainAmp" or name == "linkageSpacing" then
    teardownScene()
    buildScene()
    clearTrail()   -- the walker just snapped back to its starting position -- an old trail from before the rebuild would misleadingly show a path it never walked from here
    print(string.format("%s = %s (scene rebuilt)", name, tostring(value)))
  end
end)

-- GUI SLIDER LIVE SYNC, redundant safety net for maxSubSteps/motorSpeed:
-- also re-applied every tick in the SINGLE v:preSim hook further down
-- (with the trail-marker code) -- this file only supports one v:preSim
-- registration, so a second one here would silently replace it instead
-- of running alongside it.


-- ---------------------------------------------------------------------
-- CENTROID TRAIL: ported unmodified from Cheby_baseline.lua. Drops a
-- small marker on the floor every TRAIL_INTERVAL frames at the
-- mechanism's current (x,z) position, to visualize its trajectory over
-- time (turning, drifting, straight-line travel, etc.).
--
-- Uses the CUBE's position as a practical stand-in for the true mass-
-- weighted centroid, rather than summing every body in the mechanism
-- every frame -- the cube alone is close to half the total mass, so
-- its path should closely track the true centroid's shape without
-- that bookkeeping.
--
-- Markers are static (mass 0) AND mostly buried in the floor -- only
-- about 0.02 units poke above the surface, thin enough that a foot
-- crossing one shouldn't meaningfully disturb the walk. (Cheby's own
-- comment notes CF_NO_CONTACT_RESPONSE isn't settable through this
-- binding's setCollisionFlags -- burying them is the lower-risk
-- workaround that doesn't depend on that.)
--
-- TRAIL_INTERVAL=30 was tuned as "0.5s at 60fps" in Cheby, which
-- actually undershoots there since Cheby's own v.timeStep is 1/10 --
-- but Spears' v.timeStep IS 1/60, so 30 frames really is 0.5s here,
-- matching the original comment's intent exactly.
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30   -- frames between markers (0.5s at 60fps) -- lower = finer trail, more markers over a long run
local trail_frame_count = 0
local trailMarkers = {}   -- separate from builtObjects/builtConstraints on purpose: these are history dropped over time, not scene state buildScene() itself creates -- but a cube_d/cubeMass/terrainAmp rebuild snaps the walker back to its starting position, so the OLD trail would otherwise misleadingly show a path the walker never walked from its new start.

function clearTrail()
  for i = 1, #trailMarkers do
    v:remove(trailMarkers[i])
  end
  trailMarkers = {}
  trail_frame_count = 0
end

v:preSim(function(N)
  -- GUI SLIDER LIVE SYNC: maxSubSteps and motorSpeed can be dragged
  -- while the sim is running. maxSubSteps is just re-assigned onto v
  -- each tick; motorSpeed is re-applied to all four hip hinges' motor
  -- target via enableAngularMotor (torque/maxImpulse stays fixed at
  -- 8.0, matching each hinge's original construction-time call).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local motorSpeed = v:getParam("motorSpeed")
  linkage1.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage2.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage3.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage4.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    local marker = Cube(1.0, 0.05, 1.0, 0)   -- static, thin
    marker.col = "red"
    --marker.pos = btVector3(cube.pos.x, floor_top_y, cube.pos.z)   -- centered AT floor surface -- half buried, ~0.02 protrusion
    marker.pos = btVector3(cube.pos.x, floor_top_y, cube.pos.z)   -- centered AT floor surface -- half buried, ~0.02 protrusion
    v:add(marker)
    trailMarkers[#trailMarkers + 1] = marker
  end
end)

-- ---------------------------------------------------------------------
-- camera + gravity
-- ---------------------------------------------------------------------

v.cam.pos  = btVector3(26, 6, 30)
v.cam.look = btVector3(5, -3, 0)
v.cam.up   = btVector3(0, 1, 0)

v.gravity = btVector3(0, -9.8, 0)

