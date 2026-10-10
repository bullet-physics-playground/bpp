--
-- Not a scene: run on its own, this file builds nothing. To see the
-- walker, open Chebyshev_normalT.lua.
--
-- Chebyshev (Model 1A) walker, the mechanism: the cube body, its legs, and everything
-- welded or hinged to them, as a function. Chebyshev_normalT.lua calls it
-- to build the walker on its own terrain; a room can call it to build
-- the same walker beside others. Nothing here sets the physics
-- settings, gravity, terrain, sliders or camera: the caller does. Every
-- name here is local, so walkers built side by side don't share globals.
--
--   local Walker = dofile("Chebyshev_normal_parts.lua")
--   local w = Walker.build{
--     add = function(obj) ... end,          -- adds a body to the world
--     addConstraint = function(con) ... end,
--     terrainLift = ...,  -- how far the ground can rise above Walker.FLOOR_TOP_Y
--     cube_d = ..., cubeMass = ..., linkageSpacing = ...,   -- the sliders
--     leftSpeed = ..., rightSpeed = ...,                     -- of the same names
--     scale = ...,         -- optional, default 1: multiplies every length
--     impulseScale = ...,  -- optional, default 1: multiplies the motors' impulse
--   }
--   w.cube, w.cube_w, w.cubeCenterX, w.linkage1 .. w.linkage4 (each with
--   .hingeO2, the motor), w.crossbarFront/Back, w.foot1 .. w.foot4
--
-- The notes below were written when all of this lived in
-- Chebyshev_normalT.lua; "this file" in them means the walker as a whole.
--
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

local M = {}

local add, addConstraint   -- set by M.build from its caller's opts
local S = 1                -- the scale (opts.scale): every length is multiplied by it

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
local function midpoint(p1, p2)
  return { x = (p1.x + p2.x)/2, y = (p1.y + p2.y)/2 }
end

-- one of the two points where a circle (center c1, radius r1) meets
-- a circle (center c2, radius r2) -- this is the law of cosines,
-- just algebraically pre-solved so it costs one sqrt instead of an
-- acos followed by a cos and a sin:
--   cos(theta) = (r1^2 + d^2 - r2^2) / (2*r1*d)   <- law of cosines
--   a  = r1*cos(theta)                            <- adjacent leg
--   hh = r1*sin(theta) = sqrt(r1^2 - a^2)          <- opposite leg (Pythagoras)
local function circleIntersect(c1, r1, c2, r2, flip)
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
local function zrotVec(dx, dy)
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
local function makeLink(p1, p2, z, mass, color, width, depth)
  width = width or rod_w * S
  depth = depth or rod_d * S
  local len = math.sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, width, depth, mass)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  add(obj)   -- add is the caller's (opts.add), set by M.build before any of this is called
  return obj
end

-- ---------------------------------------------------------------------
-- ground: one wide cube shared by both linkages. Wide enough to carry
-- both g-mountings (10 units apart) plus a margin on each outer side.
-- ---------------------------------------------------------------------


M.FLOOR_TOP_Y = 4.6 - p_len   -- the floor's baseline height for this mechanism -- read by Chebyshev_normalT.lua's floor


function M.build(opts)
add, addConstraint = opts.add, opts.addConstraint

-- SCALE: opts.scale (default 1) multiplies every length -- links, rod
-- sections, plane gaps, the cube, the leg spacing, crossbars and feet --
-- so the walker is built smaller or larger about the origin. Masses stay
-- the same. Motor strength (an angular impulse, mass x length^2 / time)
-- goes up with the square of the scale. The slider values passed in
-- (cube_d, linkageSpacing, ...) are in this walker's own units, as on
-- its sliders; terrainLift is in the caller's units. Moving as it does
-- full size also needs gravity scaled by the same factor; that is the
-- caller's job (gravity is set per body, after building).
S = opts.scale or 1
-- opts.impulseScale (default 1) multiplies the motors' impulse, which
-- Bullet applies once per physics step: a caller stepping at 1/960 s
-- instead of this walker's own 1/480 s passes 480/960 = 0.5, so the
-- motors push just as hard per second.
local IMPULSE_SCALE = opts.impulseScale or 1
local g_len, a_len, f_len, h_len, p_len = g_len * S, a_len * S, f_len * S, h_len * S, p_len * S
local rod_w, rod_d, plane_gap = rod_w * S, rod_d * S, plane_gap * S
local cube_d = opts.cube_d * S       -- cube's own depth (Z) -- GUI slider -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically
local linkage_spacing = opts.linkageSpacing * S   -- GUI slider -- how far apart the two leg mounts on each face sit
local cube_margin = 2.5 * S
local cube_w = linkage_spacing + 2*cube_margin   -- returned: Chebyshev_normalT.lua's one-time camera setup reads it
local cube_center_x = linkage_spacing / 2   -- returned (the floor is centred on it) -- midway between the two mounts (0 and linkage_spacing) -- symmetric for any linkage_spacing, nothing extra needed
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
-- opts.terrainLift is that tallest bump: terrain_amp * 1.0 in
-- Chebyshev_normalT.lua.
local terrain_lift = opts.terrainLift

-- The crank and rocker never come close to each other in XY -- see the
-- header comment -- so they can share a Z-plane instead of each getting
-- its own.
local z_ground, z_crank, z_coupler, z_rocker, z_pendant, z_crossbar =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap


local cube = Cube(cube_w, 1.5 * S, cube_d, opts.cubeMass)   -- GUI slider -- CUBE MASS RE-OPTIMIZED after the foot collision fix (outward_extra 2.0->3.0, inner_gap -1.0->1.0) -- changing the feet's own geometry/contact dynamics shifted the whole mass-vs-distance landscape: previously (buggy, overlapping feet) mass=50 was the peak at net displacement 210; with the feet fixed, that same mass=50 only reaches 138, and the actual peak moved out to mass~150-180 (net displacement 154-166, a broad flat plateau, not a sharp point) -- mass=170 is the best single value found (165.76). Direction also flipped sign (now travels -X instead of +X) purely from the foot fix, nothing else changed. Re-run this sweep again if the foot geometry changes further -- this mass value is coupled to it, not independent.
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
cube.damp_ang = 1.0   -- STRAIGHT-LINE FIX -- see the other Hoecken/Chebyshev-family files in this series: without rotational damping, nothing resists small torque asymmetries between the front/back leg pairs from accumulating into persistent yaw. Confirmed on this file specifically below, not assumed to transfer.
add(cube)

-- ---------------------------------------------------------------------
-- linkage builder -- one full copy of g/a/f/h/p mounted at x_offset
-- along the cube's face (g_center = (x_offset, 1.25)), with its own
-- motor. g_ang tilts the ground link around its own midpoint; defaults
-- to 0 (along the top edge).
-- ---------------------------------------------------------------------

local function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant

  local g_center = { x = x_offset, y = 1.25 * S + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point in sync with the raised cube -- no flipY in this file (unlike the Spears-linkage walkers), so it's added directly here rather than subtracted
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
  local crank   = makeLink(O2, A, z_crank_l, 0.3, "coral", 0.3 * S, rod_d)
  local coupler = makeLink(A, B, z_coupler_l, 0.6, "teal", 0.8 * S, rod_d)
  local rocker  = makeLink(M, O4, z_rocker_l, 0.3, "purple", 0.5 * S, rod_d)
  local pendant = makeLink(B, C, z_pendant_l, 1.0, "goldenrod", 1.0 * S, rod_d)
  pendant.damp_ang = 0.00--0.15   -- bleeds off some oscillation energy -- helps at higher speeds, raise if it still overshoots

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  hingeO2:enableAngularMotor(true, speed, 8.0 * S * S * IMPULSE_SCALE)   -- this is the driven joint -- raise the 3rd arg (maxMotorImpulse) further if you raise the 2nd (target speed)
  addConstraint(hingeO2)

  -- A: crank <-> coupler
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-f_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  addConstraint(hingeA)

  -- M: coupler <-> rocker (M is the coupler's own center, so its local pivot is 0,0,0)
  local pivotCoupler_M = btVector3(0, 0, 0)
  local pivotRocker_M  = btVector3(-h_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeM = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_M, pivotRocker_M, axis, axis)
  addConstraint(hingeM)

  -- O4: rocker <-> cube (this is the pin that has to bridge all three planes)
  local pivotRocker_O4 = btVector3(h_len/2, 0, z_ground_l - z_rocker_l)
  local pivotCube_O4   = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  local hingeO4 = btHingeConstraint(rocker.body, cube.body, pivotRocker_O4, pivotCube_O4, axis, axis)
  addConstraint(hingeO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings)
  local pivotCoupler_B = btVector3(f_len/2, 0, 0)
  local pivotPendant_B = btVector3(-p_len/2, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  addConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeM = hingeM, hingeO4 = hingeO4, hingeB = hingeB,
    z_pendant = z_pendant_l, C = C,
  }
end
local linkage1 = buildLinkage(0, 0, false, 0, opts.leftSpeed)                 -- front face, x=0,  phase 0
local linkage2 = buildLinkage(linkage_spacing, 0, false, 0, opts.leftSpeed)   -- front face, x=10, phase 0
local linkage3 = buildLinkage(0, 0, true, 180, opts.rightSpeed)               -- back face,  x=0,  phase 180
local linkage4 = buildLinkage(linkage_spacing, 0, true, 180, opts.rightSpeed) -- back face,  x=10, phase 180
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
local function buildCrossbar(lkA, lkB, z_pos, color, bar_height)
  bar_height = bar_height or 9.5 * S   -- was two 0.18-thick bars at +-4.5; this spans the same -4.5..+4.5 range as one body
  local PA, PB = lkA.pendant.pos, lkB.pendant.pos
  local len = math.sqrt((PB.x-PA.x)^2 + (PB.y-PA.y)^2)   -- should equal linkage_spacing, by symmetry
  local mid_x = (PA.x + PB.x) / 2

  local bar = Cube(len, bar_height, rod_d, 1.0)
  bar.col = color
  bar.trans = btTransform(IDENTITY_QUAT, btVector3(mid_x, PA.y, z_pos))   -- centered ON the pendant's own line -- no attach_height offset needed now there's only one bar
  bar.damp_ang = 0.15
  add(bar)

  -- both pendants in a pair share the same orientation at construction
  -- (same geometry, just translated), so this one quaternion is the
  -- correct weld-frame rotation for both ends.
  local pendant_quat = lkA.pendant.trans:getRotation()

  local frameInBar_A = btTransform(pendant_quat, btVector3(-len/2, 0, lkA.z_pendant - z_pos))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldA = btSliderConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLowerLinLimit(0)   -- btSliderConstraint defaults to FREE translation unless set --
  weldA:setUpperLinLimit(0)   -- these two calls are what actually makes this a rigid weld
  addConstraint(weldA)

  local frameInBar_B = btTransform(pendant_quat, btVector3(len/2, 0, lkB.z_pendant - z_pos))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldB = btSliderConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLowerLinLimit(0)
  weldB:setUpperLinLimit(0)
  addConstraint(weldB)

  return bar
end
local crossbarFront = buildCrossbar(linkage1, linkage2, z_crossbar, "slateblue")
local crossbarBack  = buildCrossbar(linkage3, linkage4, -z_crossbar, "slateblue")
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
local function buildFoot(lk, color)
  local C = lk.C
  local zp = lk.z_pendant
  local dir = zp >= 0 and 1 or -1
  local outward_extra = 3.0 * S            -- how far the foot reaches PAST the pendant, away from the body
  local inner_gap = 1.0 * S -- -1.0--0.3    -- stops short of z=0 by this much, so opposing feet don't touch at the center -- was -1.0, which actually crossed PAST z=0 onto the other side (front foot reaching to z=-1, back foot reaching to z=+1, overlapping by 2 units in the middle) -- this is what was colliding

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0 * S, 0.3 * S      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.2)   -- heavier than before (was 0.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  add(foot)

  local pendant_quat = lk.pendant.trans:getRotation()
  -- the pendant attaches at z=zp, which is now partway along the foot's
  -- length (not at its end), since the foot extends past it on both sides
  local frameInFoot    = btTransform(pendant_quat, btVector3(0, 0, zp - foot_center_z))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(p_len/2, 0, 0))   -- C is the pendant's own "+X end"
  local weld = btSliderConstraint(foot.body, lk.pendant.body, frameInFoot, frameInPendant, true)
  weld:setLowerLinLimit(0)   -- see the earlier note: slider defaults to FREE translation unless locked
  weld:setUpperLinLimit(0)
  addConstraint(weld)

  return foot
end
local foot1 = buildFoot(linkage1, "yellow")
local foot2 = buildFoot(linkage2, "yellow")
local foot3 = buildFoot(linkage3, "blue")
local foot4 = buildFoot(linkage4, "blue")
return {
  cube = cube, cube_w = cube_w, cubeCenterX = cube_center_x,
  linkage1 = linkage1, linkage2 = linkage2, linkage3 = linkage3, linkage4 = linkage4,
  crossbarFront = crossbarFront, crossbarBack = crossbarBack,
  foot1 = foot1, foot2 = foot2, foot3 = foot3, foot4 = foot4,
}
end   -- closes M.build()

return M
