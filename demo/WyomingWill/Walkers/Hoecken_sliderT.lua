-- Sept 22, 2026, by William M. Spears
-- (Chebyshev -> Hoecken-Slider linkage swap ported by Claude)

-- This is a simulation of a walker driven by the ORIGINAL 1867 Hoecken
-- slider mechanism -- linkage.lua's compute_hoecken_slider, the "a, 2a,
-- 10a variant" -- ported from Chebyshev's Plantigrade Machine (shown at
-- the 1878 Paris World Exhibition) that this file was originally built
-- around. Claude wrote most of the original Chebyshev code under Bill
-- Spears's guidance -- this was not a simple process. Top-down
-- approaches failed miserably; the machine had to be built component by
-- component, and even after it started to move it took hours to tweak
-- the parameters. I want to thank Jakob Flierl for providing the very
-- nice mesh floor, which makes this much more interesting.
--
-- MODEL H (branched from Model 1A): four copies of the same
-- Hoecken-slider linkage -- the original two on the front face, plus a mirrored pair on the back face, whose motors run 90 degrees
-- out of phase with the front pair.
--
-- THIS IS A DIFFERENT KIND OF MECHANISM THAN THE PREVIOUS TWO VERSIONS
-- OF THIS FILE. Chebyshev's linkage and the classical 4-bar Hoecken
-- linkage are both closed four-bar loops whose free coupler point
-- traces a small, compact, roughly foot-shaped loop -- exactly what you
-- want for a walking gait. The Hoecken SLIDER is a different, older
-- (1867) mechanism: a crank drives a long rigid bar that is threaded
-- through a fixed pivot which only constrains the bar to pass through
-- that point (it's free to slide lengthwise through it, hence "slider"
-- -- there's no rocker link at all). A point at the far end of that bar
-- traces an approximate STRAIGHT LINE over a long stroke -- this is one
-- of the classic 19th-century straight-line linkages, not a compact
-- foot-lift curve. Swapped in here as a leg mechanism, its foot moves
-- through a much bigger, more nearly-linear excursion than either
-- Chebyshev's or the 4-bar Hoecken's did. See the amplitude note below.
--
-- Ground link  g = 2.0  -- O2 (crank pivot) -> O4 (slider pivot), DIRECTLY
--                          UPWARD from O2 (g_ang=90), matching
--                          compute_hoecken_slider's own ground_angle=90
-- Crank        a = 1.0  -- O2 -> A
-- Slider bar   L = 10.0 -- A  -> B, threaded through O4 (a=1, g=2a, L=10a -- Hoecken's own native ratios, used unscaled)
-- Pendant      p = 10.0 -- B  -> C, hinged and hanging free (no motor)
--
-- The bar's ORIENTATION is fully determined at every instant by the two
-- points it must pass through: A (pinned to the crank) and O4 (pinned,
-- via a free-rotating slider block, to the ground/cube) -- so B is just
-- A extended L units further out along the A->O4 direction, exactly as
-- linkage.lua's compute_hoecken_slider computes P. There is no rocker
-- link and no rocker hinge in this version -- SLIDER_JOINT below
-- replaces it with a small block that's hinged to the cube (free to
-- spin, so it can track the bar's changing angle) and slider-jointed to
-- the bar itself (free to translate along the bar's own long axis, so
-- the bar can slide lengthwise through it -- see the SLIDER JOINT note
-- further down for exactly how that's built from two ordinary Bullet
-- constraints).
--
-- ORIENTATION: O4 sits DIRECTLY ABOVE O2 (g_ang=90 in buildLinkage's own
-- convention, O4 = O2 + (0, g)) -- exactly compute_hoecken_slider's own
-- ground_angle=90, not the "along the top edge" tilt the earlier
-- four-bar versions used. A first attempt at this file mounted the
-- ground link horizontally instead, which was wrong -- the reference
-- mechanism's slider pivot is vertically above the crank pivot, not off
-- to the side.
--
-- AMPLITUDE / SCALE: used at FULL NATIVE SIZE here (a=1, g=2, L=10, no
-- rescale at all) -- a first attempt shrank this down to a=0.3 to keep
-- the reach compact, which made the bar look far too short next to the
-- rest of the model. Checked numerically (sweeping the crank through a
-- full rotation, no physics run): with the vertical orientation above,
-- B's range comes out to roughly Y in [9.19, 11.25] (a fairly TIGHT
-- vertical band, since "extend further past a point that's already
-- above you" mostly just goes further up) and X in [-4.16, +4.16]
-- relative to the mount (a much WIDER horizontal sweep -- this is where
-- the walking stride actually comes from). That X range comfortably
-- clears the neighboring leg (linkage_spacing=10 apart, checked for
-- both x_offset=0 and x_offset=10 -- no overlap). B itself stays high
-- above the cube the whole cycle, same as Chebyshev's own B did
-- (~4.8-6.0 up there) -- it's the PENDANT that does the actual reach
-- down to the ground in both designs, not the coupler/bar tip. p_len is
-- back to the original 10.0 for that reason: B.y - p_len works out to
-- roughly [-0.82, 1.25], i.e. a foot that swings side to side near
-- ground level while staying at a fairly constant height -- much closer
-- to an actual walking stride than the previous (horizontal-ground-line)
-- attempt's long diagonal reach.
--
-- SLIDER JOINT, precisely: two ordinary Bullet constraints stand in for
-- the physical "pin through a hole in the bar" joint. (1) A small block
-- body sits at O4 and is hinge-constrained to the cube there, axis Z,
-- with NO motor -- it's free to spin to whatever angle the bar needs.
-- (2) That same block is slider-constrained to the bar itself, with the
-- slider's own local X axis aligned along the bar's length. Per the
-- IMPORTANT note below, a stock btSliderConstraint already leaves
-- translation along that axis FREE and locks rotation by default -- so
-- with NO extra setLowerLinLimit/setUpperLinLimit calls (unlike the
-- weld pattern used elsewhere in this file), the bar is free to slide
-- lengthwise through the block exactly as intended, while the block's
-- locked-rotation coupling to the bar is exactly what lets constraint
-- (1)'s free hinge track the bar's angle. Together, A's fixed position
-- (from the crank) plus O4's fixed position (from the block) leave only
-- one consistent orientation for a straight rigid bar passing through
-- both -- which is exactly the analytic A->O4 direction used above.
--
-- A BUG WORTH FLAGGING: hinge (1)'s pivot, on the block's side, was
-- originally left at local (0,0,0) -- which looked right (the block
-- IS built centered at O4) but actually meant the hinge silently
-- targeted the block's own Z-plane, while the cube's side of that same
-- hinge targets z_ground_l, matching every other cube-mounted hinge in
-- this file (O2's hinge does the same z_ground_l-targeting on both
-- sides). That mismatch put a small but constant Z error right at the
-- one point that's ALSO gripped by the very stiff slider joint -- a
-- much likelier source of the reported per-leg jamming/tilting than
-- plane separation by itself. Fixed by giving the block's pivot the
-- same z_ground_l-targeting offset every other hinge here already uses.
--
-- SAME PLANE FOR CRANK AND BAR: the coupler (slider bar) and its block
-- now share the crank's own Z-plane (z_coupler is just an alias for
-- z_crank -- see the constants section) rather than sitting one
-- plane_gap further out. A hinge tolerates a Z-offset between its two
-- bodies fine on its own (see above), but combined with the very stiff
-- slider joint and the driven motor torque at O2, that extra offset was
-- still a real moment arm worth removing.
--
-- Each link lives on its own Z-plane (0.4 units apart) out from the
-- cube face so the rotating parts never collide with each other or with
-- the cube -- except the slider bar/block, which now share the crank's
-- plane (see above). All hinge axes are world Z, so every link only
-- ever rotates about Z -- which means each link's local pivot points
-- are simply (+-L/2, 0, z_offset) in its own frame, no trig needed at
-- hinge time.
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
-- MASS RATIOS / WOBBLE: cube mass went up to 100.0, but the leg bodies
-- were left at their original (much smaller) masses -- crank 0.3,
-- coupler 0.6, block 0.15, foot 0.1 -- against a 100-mass cube that's a
-- 333:1 to 1000:1 ratio across directly-constrained bodies, including
-- right across the MOTORED hinge at O2. Iterative constraint solvers
-- (which is what Bullet's default solver is) are well known to struggle
-- with exactly this: large mass ratios between linked bodies show up as
-- jitter, and can blow up entirely under motor load, which matches
-- "feet wobble excessively and everything breaks" even on a flat floor
-- better than a geometry bug would (a geometry bug should misbehave the
-- same way every time; a solver fighting a mass ratio tends to look
-- more like noise). Leg masses are raised below (crank 2.0, coupler
-- 4.0, block 1.0, pendant 3.0, foot 1.5, crossbar bar 3.0) to bring
-- that ratio down closer to something an iterative solver can actually
-- converge on, plus linear+angular damping added on every leg body that
-- didn't already have it. maxMotorImpulse at O2 is also raised well
-- past its old 8.0 -- that was tuned for the original, much lighter and
-- shorter Chebyshev coupler+rocker, and likely couldn't supply enough
-- torque to actually hold this bar+pendant+foot chain at its target
-- speed, which alone can look like wobble (a motor perpetually
-- overshooting/undershooting, not a stable one). None of this is
-- verified against a live physics run -- these are the standard levers
-- for this class of problem, not a confirmed diagnosis.
--
-- ASPECT RATIO: a separate lever from mass, applied on top of the above.
-- Every rod here only ever rotates about world Z (the hinge axis) --
-- I_zz for that DRIVEN rotation is m/12*(length^2+width^2), dominated by
-- length^2 for anything longer than a few units, so cross-section barely
-- affects the torque the motor feels. But nothing about a rod's LENGTH
-- helps resist it twisting OFF that Z-plane about its own long axis --
-- I_xx = m/12*(width^2+depth^2) for THAT rotation, which is exactly the
-- "wobble"/"whipping" failure mode described throughout this file, and
-- widening pays for itself far more there than it costs in extra motor
-- load. Checked numerically per part (not from a physics run):
--   crank  (length 1.0):  0.18->0.3 width:  +89%   I_xx, +5.6%  motor load
--   coupler(length 10.0): 0.18->1.2 width:  +2170% I_xx, +1.4%  motor load
--   pendant(length 14.0): 0.18->1.0 width:  +1490% I_xx, +0.5%  swing cost
-- The crank's bump is deliberately modest (its length is short enough
-- that width isn't totally free there, unlike the other two) -- the
-- coupler and pendant get the aggressive treatment since they're both
-- long AND implicated by name in the wobble symptoms (the coupler sits
-- directly on the stiffest joint in the mechanism, the O4 slider; the
-- pendant is literally "the foot end whipping side to side"). Depth
-- (rod_d) is left untouched throughout -- that's the dimension that eats
-- into plane_gap clearance between stacked Z-planes, so only width
-- (which stays within the rod's own Z-plane) was grown. Checked that
-- the widened crank and coupler still clear the O4 block by a full 0.6
-- units at closest approach (was 1.0 apart, combined half-widths now
-- 0.4) -- comfortable margin, not a near-miss.
--

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
setParam("cube_d", 4.5)
setParam("cubeMass", 100.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 10)

v.maxSubSteps = v:getParam("maxSubSteps")

local g_len, a_len, f_len, p_len = 2.0, 1.0, 10.0, 14.0   -- p_len was 12.0; +2 more at the bottom so the foot's own high point (was landing exactly on the cube's bottom face, y=-0.75, at -0.75 itself) clears it by 2 units instead
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.8--0.4                     -- spacing between staggered planes

-- SAME PLANE FOR CRANK AND SLIDER BAR: hingeA (crank<->coupler) and the
-- O4 hinge/slider pair were built with the coupler/block sitting one
-- full plane_gap away from the crank's own plane -- a Z-offset that a
-- HINGE tolerates fine on its own (it only locks the pivot point, plus
-- 2 rotational DOF), but combined with the much stiffer slider joint at
-- O4 (which locks nearly every DOF except the one axial slide) and the
-- driven motor torque at O2, that offset turned into a real moment arm
-- that jammed every leg except one. Putting the bar on the crank's own
-- plane removes that moment arm entirely -- z_coupler is now just an
-- alias for z_crank, not its own separate plane. The pendant and
-- crossbar keep their own planes (they're only ever hinged, never
-- slider-jointed, so they didn't show this problem).
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

local floor_top_y = -5.7   -- unchanged since p_len=12.0 -- see the floor-section note above buildScene()

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

-- SAME PLANE FOR CRANK AND SLIDER BAR -- see the header note above.
local z_ground, z_crank, z_pendant, z_crossbar =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + 3*plane_gap
local z_coupler = z_crank   -- slider bar shares the crank's plane -- see note above

--cube = Cube(cube_w, 1.5, cube_d, 100.0)   -- small mass -> now dynamic, affected by gravity
cube = Cube(cube_w, 1.5, cube_d, v:getParam("cubeMass"))   -- GUI slider -- small mass -> now dynamic, affected by gravity
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
-- STRAIGHT-LINE FIX: cube.damp_ang=1.0 was found by running actual 600-frame
-- physics trials (bpp -n 600, real Bullet, not just kinematics) and sweeping
-- parameters against a heading-drift metric. Without any rotational damping,
-- the cube had nothing resisting small torque asymmetries between the two
-- leg pairs (front phase=0, back phase=180 -- never perfectly synchronized in
-- practice), which accumulated into a persistent yaw and a curving path:
-- baseline heading drifted 53 degrees over 15 simulated seconds, ending up
-- 58.5 units from start. damp_ang=1.0 cuts that to -3 degrees (measured
-- heading is pinned at +-179-180 degrees from frame 61 onward -- a genuinely
-- straight line, not just matching start/end points) and INCREASES distance
-- traveled to 73.2 units (+25%) -- no distance/straightness tradeoff needed
-- here, damping the yaw actually let more of the leg thrust go into forward
-- motion instead of an arcing path.
-- What did NOT work, tried and discarded: (1) adjusting the front/back phase
-- offset away from 180 -- tested 0/90/110/120/130/140/150/160/170/175/185/
-- 190/200/210/270, none gave a clean fix, several collapsed distance
-- entirely (the back pair needs to stay close to 180 out of phase with the
-- front pair for the gait itself to work); (2) locking ONLY yaw via
-- cube.body:setAngularFactor(btVector3(1,0,1)) (free pitch/roll, no yaw) --
-- a more surgical-sounding fix that empirically made it WORSE (-88 degrees
-- of drift), for reasons not fully understood -- worth flagging that the
-- more "obviously correct" mechanism-based fix didn't win here, plain high
-- angular damping did. Also tried: damp_lin=1.0 alone, which nearly stops
-- the walker outright (0.01 units traveled) -- linear damping fights
-- translation directly, not a fix for this.
-- damp_ang below 1.0 gave partial, inconsistent improvement (e.g. 0.99 ->
-- 16.7 degrees, 0.9 -> 34.4 degrees) -- there's a real threshold effect
-- around full damping, not a smooth tradeoff curve, so 1.0 is used rather
-- than a "gentler" partial value.
cube.damp_ang = 1.0
track(cube)

-- ---------------------------------------------------------------------
-- floor: an uneven terrain mesh (Terrain, backed by
-- btBvhTriangleMeshShape -- Bullet's BVH-accelerated static concave
-- shape) instead of a flat Cube. floor_top_y is still the mechanism's
-- own baseline reach, DERIVED from p_len (the baseline below comes from
-- the bar-and-slider loop's own lowest point, independent of p_len,
-- minus the foot's half-thickness and a small margin);
-- terrainHeight(x,z) adds a small undulation ON TOP of that baseline,
-- so a foot still finds ~floor_top_y on average but has real bumps to
-- step over/into instead of a perfectly flat surface. terrain_amp is
-- on the order of the crank length driving the whole gait (a_len=1.0)
-- and well past the foot's own half-thickness (0.15), so bumps are a
-- real obstacle the feet have to climb, not just surface texture --
-- worth watching on the first run, same honest caveat as the top
-- crossbars above.
-- (Terrain was tried here before via btGImpactMeshShape -- tiles,
-- scattered patches -- but reverted: GImpact is built for shapes that
-- might move, and is markedly slower/less stable than it needs to be
-- for a shape that never does. btBvhTriangleMeshShape builds its BVH
-- tree once, at construction, and is ONLY ever valid for a static body
-- -- exactly what the floor already was, so nothing about "static,
-- never moves" had to change, just the shape type backing it.)
-- ---------------------------------------------------------------------
-- The bar's own tip B stays HIGH (y in roughly [9.19, 11.25]) over a
-- full crank rotation at this scale, same as Chebyshev's own B stayed
-- high (~4.8-6.0) in the original file -- checked numerically (Lua
-- sweep, no NaNs/degenerate geometry across a full rotation for both
-- x_offset=0 and x_offset=10), not from a live physics run.
--
-- floor_top_y is DELIBERATELY NOT re-derived from the current p_len.
-- Back when p_len first went 10.0 -> 12.0, the foot (B.y - p_len) had
-- worked out to roughly [-0.82, +1.25] at p_len=10.0, and floor_top_y=
-- -1.02 sat just under that low point (8.98 was that original baseline,
-- i.e. B.ymin(9.185) minus a small margin). Keeping floor_top_y pinned
-- there while p_len grew meant the cube's resting height rises instead
-- of just tracking the floor down to match -- see that earlier change
-- for the full reasoning. p_len is now 14.0 (+2 more, this time to
-- clear the cube's own body -- at p_len=12.0 the foot's own high point,
-- -0.75, landed exactly on the cube's bottom face, also at y=-0.75).
-- This latest +2 is a clearance fix, not a "raise the body" one, so
-- floor_top_y stays exactly where it was rather than moving again.
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
-- linkage builder -- one full copy of the Hoecken slider (g/a/L/p)
-- mounted at x_offset along the cube's face (g_center = (x_offset,
-- 1.25)), with its own motor. g_ang tilts the ground link around its
-- own midpoint; defaults to 0 (along the top edge).
-- ---------------------------------------------------------------------

function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_pendant_l = zSign * z_pendant

  local g_center = { x = x_offset, y = 1.25 + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point in sync with the raised cube -- no flipY in this file, so it's added directly here rather than subtracted
  local O2 = { x = g_center.x - (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y - (g_len/2)*math.sin(math.rad(g_ang)) }
  local O4 = { x = g_center.x + (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y + (g_len/2)*math.sin(math.rad(g_ang)) }

  local a_ang0 = g_ang + 90 + phase
  local A = { x = O2.x + a_len*math.cos(math.rad(a_ang0)),
              y = O2.y + a_len*math.sin(math.rad(a_ang0)) }
  -- the bar's direction is simply A->O4 (see the header note on why
  -- that's the only orientation consistent with a rigid bar pinned at A
  -- and threaded through the fixed point O4); B is that direction
  -- extended out to the bar's full length f_len, exactly matching
  -- linkage.lua's compute_hoecken_slider (P = A + L*unit(O2-A)).
  local adx, ady = O4.x - A.x, O4.y - A.y
  local adist = math.sqrt(adx*adx + ady*ady)
  local B = { x = A.x + f_len*adx/adist, y = A.y + f_len*ady/adist }
  local C = { x = B.x, y = B.y - p_len }   -- pendant hangs straight down initially

  -- CROSS-SECTION ASPECT RATIO: widened (not just enlarged) for the two
  -- long members -- see the ASPECT RATIO header note for the full
  -- reasoning. I_xx (resistance to the rod twisting about its own long
  -- axis -- the "off-plane wobble" failure mode, since length itself
  -- gives zero help against that specific rotation) scales with
  -- width^2+depth^2, so widening pays off far more than it costs for
  -- anything long enough that its DRIVEN rotation (I_zz, dominated by
  -- length^2) barely notices the same width change.
  local crank   = makeLink(O2, A, z_crank_l, 2.0, "coral", 0.3, rod_d)          -- modest width bump (0.18->0.3): +89% I_xx for only +5.6% motor load -- see note
  local coupler = makeLink(A, B, z_coupler_l, 4.0, "teal", 1.2, rod_d)          -- this is the full slider bar, A all the way to B -- widened aggressively: +22.7x I_xx for +1.4% motor load, and this is the bar sitting directly on the stiffest joint (O4 slider)
  coupler.damp_ang = 0.15   -- the bar sits on the stiffest joint in the chain (the O4 slider) -- undamped before, likely a real contributor to the wobble
  coupler.damp_lin = 0.1
  local pendant = makeLink(B, C, z_pendant_l, 3.0, "goldenrod", 1.0, rod_d)     -- widened aggressively too: +15.9x I_xx for +0.5% swing cost -- directly targets the "foot end whipping side to side" symptom, which IS off-plane wobble
  pendant.damp_ang = 0.3--0.00--0.15   -- bleeds off some oscillation energy -- helps at higher speeds, raise if it still overshoots
  pendant.damp_lin = 0.2   -- linear damping added alongside the existing angular damping -- the wobble is translational too (the foot end whipping side to side), not just rotational

  -- the slider block: a small body that sits at O4, oriented to match
  -- the bar's own current direction (so the slider constraint below
  -- starts with zero error), hinged to the cube (free to spin) and
  -- slider-jointed to the bar (free to slide lengthwise) -- see the
  -- SLIDER JOINT note up top for why these two constraints together
  -- reproduce "a bar threaded through a fixed pivot".
  local block = Cube(0.5, 0.5, 0.5, 1.0)
  block.col = "slategray"
  block.trans = btTransform(coupler.trans:getRotation(), btVector3(O4.x, O4.y, z_coupler_l))
  block.friction = 0.3
  block.damp_ang = 0.15
  block.damp_lin = 0.1
  track(block)

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  -- maxMotorImpulse raised 8.0 -> 150.0: the crank now has to drag a much
  -- heavier bar+pendant+foot chain (masses raised below, see the mass-
  -- ratio note near cube's own definition) through a full 10-unit slider
  -- bar's worth of inertia at the tip. 8.0 was tuned for the ORIGINAL
  -- Chebyshev linkage's much lighter, shorter coupler+rocker -- with this
  -- mechanism's longer bar and now-heavier parts, that impulse cap was
  -- very likely too small to actually hit the target speed, which would
  -- show up as exactly the kind of jerky, wobbly, "everything breaks"
  -- motion described -- an underpowered motor oscillating around its
  -- target instead of holding it. Not verified against a live physics
  -- run; if it's still not enough, raise this further.
  hingeO2:enableAngularMotor(true, speed, 150.0)
  trackConstraint(hingeO2)

  -- A: crank <-> coupler (the slider bar's near end)
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-f_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  trackConstraint(hingeA)

  -- O4, part 1: cube <-> block, a free hinge (NO motor) -- the block is
  -- simply pinned in POSITION at O4; its rotation is left free so it
  -- can track whatever angle the bar (via the slider joint below) needs.
  local pivotCube_O4  = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  -- block's own body sits at z_coupler_l, not z_ground_l -- its pivot
  -- offset has to bridge that gap the same way pivotCrank_O2/pivotCoupler_A
  -- do elsewhere in this function, so both sides of the hinge target the
  -- SAME world-Z point (z_ground_l). Leaving this at (0,0,0) (as a
  -- previous pass did) silently targeted z_coupler_l instead -- a
  -- built-in Z mismatch, right at the same point as the very stiff
  -- slider joint below, which is a much likelier source of the jamming
  -- than plane separation on its own.
  local pivotBlock_O4 = btVector3(0, 0, z_ground_l - z_coupler_l)
  local hingeO4 = btHingeConstraint(cube.body, block.body, pivotCube_O4, pivotBlock_O4, axis, axis)
  trackConstraint(hingeO4)

  -- O4, part 2: block <-> coupler, the actual SLIDER joint -- deliberately
  -- built with NO setLowerLinLimit/setUpperLinLimit calls (unlike every
  -- weld elsewhere in this file), so translation along the bar's own
  -- local X axis stays free by Bullet's default -- letting the bar
  -- slide lengthwise through the block as it swings. Rotation between
  -- the two frames stays locked by that same default, which is what
  -- lets the block's free hinge above track the bar's angle.
  local frameInBlock  = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local barLocalOffset = adist - f_len/2   -- where O4 currently sits along the bar, in the bar's own centered local frame
  local frameInCoupler = btTransform(IDENTITY_QUAT, btVector3(barLocalOffset, 0, 0))
  local sliderO4 = btSliderConstraint(block.body, coupler.body, frameInBlock, frameInCoupler, true)
  trackConstraint(sliderO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings)
  local pivotCoupler_B = btVector3(f_len/2, 0, 0)
  local pivotPendant_B = btVector3(-p_len/2, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  trackConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, block = block, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeO4 = hingeO4, sliderO4 = sliderO4, hingeB = hingeB,
    z_pendant = z_pendant_l, C = C,
  }
end
-- g_ang=90: the ground link (O2->O4) points straight up, matching
-- compute_hoecken_slider's own ground_angle=90 (see ORIENTATION note up
-- top) -- NOT 0/"along the top edge" the way the earlier four-bar
-- versions of this file used.
linkage1 = buildLinkage(0, 90, false, 0, v:getParam("Left Speed"))                 -- front face, x=0,  phase 0
linkage2 = buildLinkage(linkage_spacing, 90, false, 0, v:getParam("Left Speed"))   -- front face, x=10, phase 0
linkage3 = buildLinkage(0, 90, true, 180, v:getParam("Right Speed"))               -- back face,  x=0,  phase 180
linkage4 = buildLinkage(linkage_spacing, 90, true, 180, v:getParam("Right Speed")) -- back face,  x=10, phase 180
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
-- exact numerical coincidence. Any tiny solver residual (worse with the
-- heavier masses and stronger motor from the last round of changes)
-- means the two crossbars fight each other for control of the same
-- pendant, which is what "crossbars separate from the pendants a lot"
-- was -- not a stiffness problem, a genuinely conflicting-constraint one.
-- Fixed by building ONE bar tall enough (bar_height, default 9.5) to
-- span the same vertical range the old two bars covered, welded once
-- per pendant instead of twice. Visually this trades the old "two thin
-- struts" look for a single wider plate -- ask if you'd rather keep the
-- two-strut look; that needs the two bars welded to EACH OTHER (making
-- them one physically rigid unit) rather than independently to the
-- pendants, which is a bit more work than this fix.
-- ---------------------------------------------------------------------

function buildCrossbar(lkA, lkB, z_pos, color, bar_height)
  bar_height = bar_height or 9.5   -- was two 0.18-thick bars at +-4.5; this spans the same -4.5..+4.5 range as one body
  local PA, PB = lkA.pendant.pos, lkB.pendant.pos
  local len = math.sqrt((PB.x-PA.x)^2 + (PB.y-PA.y)^2)   -- should equal linkage_spacing, by symmetry
  local mid_x = (PA.x + PB.x) / 2

  local bar = Cube(len, bar_height, rod_d, 3.0)
  bar.col = color
  bar.trans = btTransform(IDENTITY_QUAT, btVector3(mid_x, PA.y, z_pos))   -- centered ON the pendant's own line -- no attach_height offset needed now there's only one bar
  bar.damp_ang = 0.15
  bar.damp_lin = 0.1
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
  local outward_extra = 5.0--2.0            -- how far the foot reaches PAST the pendant, away from the body
  local inner_gap = 1.5-- -1.0--0.3                -- stops short of z=0 by this much, so opposing feet don't touch at the center

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.5)   -- was 0.1 -- far too light against the now much-heavier cube (100) and pendant (3.0) it's rigidly welded to; a big local mass mismatch right at a weld (a 0-limit slider, very stiff) is its own source of jitter
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
    linkage1.hingeO2:enableAngularMotor(true, value, 150.0)
    linkage2.hingeO2:enableAngularMotor(true, value, 150.0)
    print(string.format("Left Speed = %.2f", value))
  elseif name == "Right Speed" then
    linkage3.hingeO2:enableAngularMotor(true, value, 150.0)
    linkage4.hingeO2:enableAngularMotor(true, value, 150.0)
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
  -- stays fixed at 150.0, matching each hinge's original construction-
  -- time call -- this file's much heavier bar+pendant+foot chain needs
  -- far more torque headroom than the flat 8.0 used elsewhere in this
  -- series).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local leftSpeed = v:getParam("Left Speed")
  local rightSpeed = v:getParam("Right Speed")
  linkage1.hingeO2:enableAngularMotor(true, leftSpeed, 150.0)
  linkage2.hingeO2:enableAngularMotor(true, leftSpeed, 150.0)
  linkage3.hingeO2:enableAngularMotor(true, rightSpeed, 150.0)
  linkage4.hingeO2:enableAngularMotor(true, rightSpeed, 150.0)

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
