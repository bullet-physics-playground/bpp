--
-- Not a scene: run on its own, this file builds nothing. To see the
-- walker, open Chebyshev_diagT.lua.
--
-- Chebyshev (diagonal crossbars) walker, the mechanism: the cube body, its legs, and everything
-- welded or hinged to them, as a function. Chebyshev_diagT.lua calls it
-- to build the walker on its own terrain; a room can call it to build
-- the same walker beside others. Nothing here sets the physics
-- settings, gravity, terrain, sliders or camera: the caller does. Every
-- name here is local, so walkers built side by side don't share globals.
--
--   local Walker = dofile("Chebyshev_diag_parts.lua")
--   local w = Walker.build{
--     add = function(obj) ... end,          -- adds a body to the world
--     addConstraint = function(con) ... end,
--     terrainLift = ...,  -- how far the ground can rise above Walker.FLOOR_TOP_Y
--     cube_d = ..., cubeMass = ..., linkageSpacing = ...,   -- the sliders
--     motorSpeed = ...,                                      -- of the same names
--     scale = ...,         -- optional, default 1: multiplies every length
--     impulseScale = ...,  -- optional, default 1: multiplies the motors' impulse
--   }
--   w.cube, w.cube_w, w.cubeCenterX, w.linkage1 .. w.linkage4 (each with
--   .hingeO2, the motor), w.diagonalBottom/Top, w.foot1 .. w.foot4;
--   Walker.MOTOR_TORQUE_RATIO (motor impulse = |speed| x this)
--
-- The notes below were written when all of this lived in
-- Chebyshev_diagT.lua; "this file" in them means the walker as a whole.
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

-- This version of the model differs from the original Plantigrade machine
-- (as far as I can tell) by linking the "legs" with diagonal crossbars,
-- which allow the walker to maintain balance better.
--
-- MODEL DIAG: four copies of the same four-bar linkage -- the original
-- two on the front face, plus a mirrored pair on the back face. Each
-- crank hinges to the shared cube and is driven by a hinge motor
-- (enableAngularMotor). A v:preSim + setAngularVelocity approach was
-- tried instead but reverted: that only overrides velocity once per
-- v.timeStep, while the actual physics runs in up to 20 finer
-- substeps in between (maxSubSteps/fixedTimeStep below) -- with no
-- motor, gravity and the diagonal bars' rigid pull were free to act
-- on each crank unopposed for all of that in-between time, which is
-- what caused the mechanism to freeze regardless of the commanded
-- sign. A hinge motor is a bias term the solver applies every
-- substep, so there's no such gap. All 4 currently run positive --
-- see the note near the linkage construction calls for why each
-- diagonal pair's sign has to match its partner, whichever sign that is.
--
-- Ground link  g = 2.5  -- a stretch of the cube's top edge
-- Crank        a = 1.0  -- O2 -> A
-- Coupler      f = 5.0  -- A  -> B, with midpoint M
-- Rocker       h = 2.5  -- M  -> O4
-- Pendant      p = 10.5 -- B  -> C, hinged and hanging free (no motor)
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
-- CROSSBAR: a rigid (welded, not hinged) bar joining a point near each
-- pendant's foot attachment on two DIAGONAL linkages (left-front <->
-- right-back, and right-front <-> left-back) -- see buildDiagonalCrossbar.
-- This only stays kinematically consistent because each pair shares the
-- same PHASE: a pendant's own attachment point only has ONE other
-- constraint (its hinge to the coupler's free end B), so its position
-- is normally a free dynamic variable -- but two linkages with matching
-- phase always trace the identical relative offset from each other, so
-- welding a bar between them is consistent, not conflicting, with the
-- rest of the motion. The two pairs run at different phases (0 and
-- 180) and different speeds, so each needs its own separate bar.
--
-- IMPORTANT: btSliderConstraint does NOT lock translation by default --
-- its stock constructor leaves the linear range free (lower=1 > upper=
-- -1, Bullet's "free" convention) and only locks rotation. A "weld"
-- needs setLowerLinLimit(0)/setUpperLinLimit(0) explicitly, or the
-- welded body can just slide off along the constraint's own axis.
--
-- Building one linkage is wrapped in buildLinkage(...), and building
-- one crossbar between a diagonal pair of linkages is wrapped in
-- buildDiagonalCrossbar(...) -- two calls total, one per pair.
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

-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------

local g_len, a_len, f_len, h_len, p_len = 2.5, 1.0, 5.0, 2.5, 10.5
local p_top_extend = 4.0   -- how far the pendant rod extends ABOVE B (toward the coupler), making room for the two new top crossbars. C (the foot attachment) is unaffected -- only the rod's TOP end moves.
local rod_w, rod_d = 0.38, 0.18          -- rod cross-section
local plane_gap = 0.4                     -- spacing between staggered planes

-- shared with buildLinkage (below) and the motorSpeed onParamChanged/
-- preSim sync code (in Chebyshev_diagT.lua) -- one constant instead of two
-- copies that could drift apart.
M.MOTOR_TORQUE_RATIO = 3.0
local MOTOR_TORQUE_RATIO = M.MOTOR_TORQUE_RATIO


-- The crank and rocker never come close to each other in XY: the crank
-- stays within a_len=1.0 of O2, and the rocker (a rigid h_len=2.5 rod
-- pinned at O4) sweeps no closer than ~1.43 to the O2-A segment over a
-- full crank rotation (checked numerically) -- comfortably more than
-- the ~0.42 two rod cross-sections (rod_w x rod_d) would need to touch.
-- So they can share a Z-plane instead of each getting its own, which
-- drops the stack from 5 distinct planes to 4 -- one plane_gap less of
-- total depth per linkage, moving coupler/pendant (and everything
-- mounted off the pendant: feet, diagonal crossbars) that much closer
-- to the cube, on both the front and mirrored back face.

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

-- maps local +X to an ARBITRARY 3D direction (dx,dy,dz) -- needed for
-- the diagonal crossbars below, which span X, Y, and Z all at once,
-- unlike everything else in this file (which only ever needed a single-
-- axis rotation). Standard "shortest arc" quaternion construction:
-- axis = (1,0,0) x d, and w = 1 + dot((1,0,0), d), then normalize.
-- Numerically robust, no explicit trig calls.
local function alignVecX(dx, dy, dz)
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
local function qmul(a, b)
  local ax,ay,az,aw = a:getX(), a:getY(), a:getZ(), a:getW()
  local bx,by,bz,bw = b:getX(), b:getY(), b:getZ(), b:getW()
  return btQuaternion(
    aw*bx + ax*bw + ay*bz - az*by,
    aw*by - ax*bz + ay*bw + az*bx,
    aw*bz + ax*by - ay*bx + az*bw,
    aw*bw - ax*bx - ay*by - az*bz
  )
end

local function qconj(a)
  return btQuaternion(-a:getX(), -a:getY(), -a:getZ(), a:getW())
end

-- stiffens a constraint via Bullet's ERP/CFM constraint parameters
-- (setParam), confirmed available on btHingeConstraint/btSliderConstraint.
-- ERP = how much positional error gets corrected each step (Bullet's
-- default is a gentle ~0.2; push this high for a snappier, less wiggly
-- joint). CFM = how "spongy"/pushable the constraint is; 0 is fully
-- rigid. This binding requires the axis argument explicitly (no default
-- like plain C++ Bullet) -- -1 targets the constraint's main lock,
-- rather than a specific limit/motor axis. Constants below are
-- Bullet's btConstraintParams enum values, not exposed as named
-- constants in this Lua binding:
--   BT_CONSTRAINT_ERP = 1, BT_CONSTRAINT_STOP_ERP = 2,
--   BT_CONSTRAINT_CFM = 3, BT_CONSTRAINT_STOP_CFM = 4
local function stiffen(c)
  --c:setParam(1, 1.0, -1)   -- BT_CONSTRAINT_ERP
  --c:setParam(2, 1.0, -1)   -- BT_CONSTRAINT_STOP_ERP
  --c:setParam(3, 0.0, -1)   -- BT_CONSTRAINT_CFM
  --c:setParam(4, 0.0, -1)   -- BT_CONSTRAINT_STOP_CFM
end

-- same as stiffen(), but per-axis (0-2 linear, 3-5 angular) on a
-- btGeneric6DofConstraint, skipping one axis entirely -- used to keep
-- every DOF rigid except a single deliberately-soft "give" axis, which
-- axis=-1 (stiffen's blanket target) would otherwise also stiffen,
-- defeating the point of leaving it soft.
local function stiffenExcept(c, excludeAxis)
  for axis = 0, 5 do
    if axis ~= excludeAxis then
     -- c:setParam(1, 1.0, axis)
     -- c:setParam(2, 1.0, axis)
     -- c:setParam(3, 0.0, axis)
     -- c:setParam(4, 0.0, axis)
    end
  end
end

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
-- both g-mountings (linkageSpacing apart) plus a margin on each outer
-- side. linkage_spacing/cube_w/cube_center_x now live inside
-- buildScene() (see there) since linkageSpacing is a GUI slider.
-- ---------------------------------------------------------------------


M.FLOOR_TOP_Y = 4.6 - p_len   -- the floor's baseline height for this mechanism (see the floor notes in Chebyshev_diagT.lua)

-- ---------------------------------------------------------------------
-- linkage builder -- one full copy of g/a/f/h/p mounted at x_offset
-- along the cube's face (g_center = (x_offset, 1.25)), with its own
-- motor. g_ang tilts the ground link around its own midpoint; defaults
-- to 0 (along the top edge).
-- ---------------------------------------------------------------------


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
local p_top_extend, rod_w, rod_d, plane_gap = p_top_extend * S, rod_w * S, rod_d * S, plane_gap * S
local cube_d = opts.cube_d * S       -- cube's own depth (Z) -- GUI slider -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically
local linkage_spacing = opts.linkageSpacing * S   -- GUI slider -- how far apart the two g-mountings sit
local cube_margin = 2.5 * S
local cube_w = linkage_spacing + 2*cube_margin   -- returned: Chebyshev_diagT.lua's one-time camera setup reads it
local cube_center_x = linkage_spacing / 2         -- midway between the two -- returned (the floor is centred on it)
local z_ground, z_crank, z_coupler, z_rocker, z_pendant =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + plane_gap, cube_d/2 + 3*plane_gap
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
-- Chebyshev_diagT.lua.
local terrain_lift = opts.terrainLift
--cube = Cube(cube_w, 1.5, cube_d, 140.0)
local cube = Cube(cube_w, 1.5 * S, cube_d, opts.cubeMass)   -- GUI slider
-- CUBE MASS OPTIMIZED, found by running 2400-frame trials sweeping mass 1-200 (feet untouched -- outward_extra/inner_gap left at their current values, per request). Low mass (1-40) gives modest, fairly flat travel (45-78 units net displacement); a clear step up begins around mass=50 (152) and climbs through a broad plateau from ~100-170 (216-244), peaking at mass=140 (244.04, the best found) before declining again by 180-200. Higher mass also brings a bit more sideways (Z) drift at the very top of the plateau (-7 to -14 at 140-180) than the low-mass regime shows, worth knowing if perfect straightness matters more than raw distance.
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, terrain_lift, 0)   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
cube.friction = 0.5
cube.damp_ang = 1.0   -- STRAIGHT-LINE FIX -- see the other Hoecken/Chebyshev-family files in this series: without rotational damping, nothing resists small torque asymmetries between the differently-phased leg pairs from accumulating into persistent yaw. Confirmed on this file specifically below, not assumed to transfer.
add(cube)
local function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant

  local g_center = { x = x_offset, y = 1.25 * S + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point (O2, O4, A, M, B, C -- all translation-invariant relative to g_center) in sync with the raised cube, so the whole leg stays correctly connected, just higher up
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
  local B_top = { x = B.x, y = B.y + p_top_extend }   -- extends the pendant rod UPWARD past B, toward the coupler -- C is unaffected

  -- ASPECT RATIO: widened cross-sections (width only, depth left at
  -- rod_d so the plane_gap stacking clearance isn't touched). This
  -- file already starts wider (rod_w=0.38) than the 0.18x0.18 baseline
  -- used elsewhere in this series, so gains are relative to that.
  -- I_xx (off-plane wobble resistance) scales with width^2+depth^2,
  -- while I_zz (the driven rotation, what the motor fights) is
  -- dominated by length^2, so widening still buys stiffness far cheaper
  -- than it costs in motor load. Checked numerically: crank (len 1.0)
  -- 0.38->0.5 gives +60% I_xx for +9.2% motor load (the crank is short
  -- enough that this is the priciest of the four, same pattern as every
  -- other file in this series); rocker (len 2.5) 0.38->0.7 gives +195%
  -- for +5.4%; coupler (len 5.0) 0.38->1.0 gives +484% for +3.4%;
  -- pendant (len 14.5, now spanning B_top to C) 0.38->1.3 gives +874%
  -- for +0.7%.
  local crank   = makeLink(O2, A, z_crank_l, 0.3, "coral", 0.5 * S, rod_d)
  local coupler = makeLink(A, B, z_coupler_l, 0.6, "teal", 1.0 * S, rod_d)
  local rocker  = makeLink(M, O4, z_rocker_l, 0.3, "purple", 0.7 * S, rod_d)
  local pendant = makeLink(B_top, C, z_pendant_l, 1.0, "goldenrod", 1.3 * S, rod_d)   -- now spans B_top to C, not B to C -- B sits partway along this longer rod, not at its end
  pendant.damp_ang = 0.15   -- bleeds off some oscillation energy -- helps at higher speeds, raise if it still overshoots

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank -- back to a hinge motor (was direct
  -- setAngularVelocity via preSim). That approach only overrides
  -- velocity once per frame, at the start of v.timeStep, but the real
  -- physics runs in up to 20 finer substeps in between -- with the
  -- motor gone, hingeO2 was a fully free hinge for all of that
  -- in-between time, leaving nothing to resist gravity except a once-
  -- per-frame reset. enableAngularMotor is a bias term the solver
  -- applies every substep alongside the hinge's own constraints, so
  -- there's no such gap for gravity (or the diagonal bar's rigid pull)
  -- to act unopposed in.
  --
  -- maxMotorImpulse SCALES with speed (fixed ratio) instead of using a
  -- flat value -- a flat maxMotorImpulse gives faster-driven pairs
  -- proportionally less torque headroom than slower ones, which is a
  -- fixed (non-averaging) asymmetry between differently-sped pairs.
  -- Anchored to 3.0, matching the existing speed=2.0 tuning (2.0*3.0=6.0,
  -- unchanged) while scaling other speeds to the same relative headroom.
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  hingeO2:enableAngularMotor(true, speed, math.abs(speed) * MOTOR_TORQUE_RATIO * S * S * IMPULSE_SCALE)
  stiffen(hingeO2)
  addConstraint(hingeO2)

  -- A: crank <-> coupler
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-f_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  stiffen(hingeA)
  addConstraint(hingeA)

  -- M: coupler <-> rocker (M is the coupler's own center, so its local pivot is 0,0,0)
  local pivotCoupler_M = btVector3(0, 0, 0)
  local pivotRocker_M  = btVector3(-h_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeM = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_M, pivotRocker_M, axis, axis)
  stiffen(hingeM)
  addConstraint(hingeM)

  -- O4: rocker <-> cube (this is the pin that has to bridge all three planes)
  local pivotRocker_O4 = btVector3(h_len/2, 0, z_ground_l - z_rocker_l)
  local pivotCube_O4   = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  local hingeO4 = btHingeConstraint(rocker.body, cube.body, pivotRocker_O4, pivotCube_O4, axis, axis)
  stiffen(hingeO4)
  addConstraint(hingeO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings).
  -- pivotPendant_B used to be simply -p_len/2 (the pendant's own -X
  -- end, back when B WAS that end). Now the rod is longer (B_top to C,
  -- not B to C), so B sits partway along it instead: at local X =
  -- -(p_len+p_top_extend)/2 + p_top_extend, which reduces exactly to
  -- -p_len/2 when p_top_extend=0 (verified numerically).
  local pivotCoupler_B = btVector3(f_len/2, 0, 0)
  local pendant_total_len = p_len + p_top_extend
  local B_local_x = -pendant_total_len/2 + p_top_extend
  local pivotPendant_B = btVector3(B_local_x, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  stiffen(hingeB)
  addConstraint(hingeB)

  return {
    pendant = pendant, hingeO2 = hingeO2,
    z_pendant = z_pendant_l, C = C,
  }
end

-- Labels: left = x=0, right = x=10, front = unmirrored, back = mirrored.
--   linkage1 = left-front   linkage2 = right-front
--   linkage3 = left-back    linkage4 = right-back
--
-- PHASE REASSIGNMENT FOR DIAGONAL BARS: a rigid weld between two
-- pendants is only kinematically consistent if they maintain a FIXED
-- relative transform over the whole motion -- which requires the same
-- PHASE (mirror status doesn't matter; it only flips a constant Z sign,
-- confirmed by the same reasoning used for the front/back crossbars
-- earlier). The original front-front/back-back pairing worked because
-- each pair shared phase. For left-front<->right-back and
-- right-front<->left-back to be valid instead, phase has to be
-- reassigned along those same diagonals: left-front & right-back share
-- phase 0, right-front & left-back share phase 90 -- still "90 degrees
-- out of phase" overall, just regrouped onto the new pairing.
local linkage1 = buildLinkage(0, 0, false, 0, opts.motorSpeed)                    -- left-front,  phase 0,   +2.0
local linkage2 = buildLinkage(linkage_spacing, 0, false, 180, opts.motorSpeed)    -- right-front, phase 180, +3.0
local linkage3 = buildLinkage(0, 0, true, 180, opts.motorSpeed)                   -- left-back,   phase 180, +3.0 (matches linkage2's diagonal pair)
local linkage4 = buildLinkage(linkage_spacing, 0, true, 0, opts.motorSpeed)       -- right-back,  phase 0,   +2.0 (matches linkage1's diagonal pair)

-- Sign pattern kept from before: left-front/right-back (the
-- linkage1<->linkage4 diagonal pair) and right-front/left-back (the
-- linkage2<->linkage3 pair) each match within their own pair -- that's
-- what keeps both diagonal bars' relative offset exactly constant.
-- Speeds are fixed (no periodic swap) -- removed to isolate whether the
-- turning bias was coming from the swap mechanism itself or from
-- something structural underneath it.

-- ---------------------------------------------------------------------
-- DIAGONAL crossbar builder: joins a point just above the FEET (near
-- C, not the pendant's own midpoint) of two linkages that share the
-- same PHASE (see note above -- that's what keeps their relative
-- transform fixed over time, same requirement as the original
-- front/back crossbars, just satisfied by phase-matching now instead
-- of face-matching). Unlike the old crossbars, these span X, Y, and Z
-- all at once, so the bar itself needs a real 3D orientation
-- (alignVecX) rather than sitting unrotated -- which means the weld
-- frames need actual rotation composition (qmul/qconj) to match the
-- pendant's orientation, and the position offsets are found by
-- un-rotating the world-space offset into the bar's own frame (via the
-- bar's axis+angle and btVector3:rotate, both confirmed available --
-- avoids needing an unconfirmed quaternion*quaternion operator for
-- that part). y_offset raises the whole bar vertically, for the two
-- diagonals to clear each other where they cross.
--
-- width: the bar's own cross-section in what was always rod_w before --
-- for THESE bars specifically, that dimension maps EXACTLY to world Y
-- (vertical) at construction, not just approximately. That's because
-- attach_height is added identically to both endpoints (PA.y and PB.y),
-- and phase-matched pendants share an identical B.y/C.y at every
-- instant (see the phase-matching note above), so dy is always exactly
-- 0 for these bars. With dy=0, alignVecX's shortest-arc rotation is
-- necessarily a pure rotation about world Y (verified: the axis
-- alignVecX derives is (0,-dz,dy) = (0,-dz,0), a pure Y-axis term), and
-- a rotation about Y leaves Y itself unchanged -- so local Y (the
-- width dimension) stays exactly world Y regardless of how tilted the
-- bar is in X/Z. That's what makes it safe to widen this into a genuine
-- vertical plate below, rather than something that reads as vertical
-- only for a near-horizontal bar.
-- ---------------------------------------------------------------------

local function buildDiagonalCrossbar(lkA, lkB, attach_height, color, mass, width)
  mass = mass or 1.0
  width = width or rod_w
  -- attach_height is how far above C (where the foot connects) this
  -- bar's endpoints sit -- NOT a separate shift applied to the bar's
  -- center after the fact. Both bar endpoints AND the pendant-side
  -- pivots are computed at this same height, so the bar's own geometric
  -- ends always exactly coincide with the weld pivots -- no off-axis
  -- lever arm, unlike an earlier version of this function that shifted
  -- the bar's center vertically while leaving the pivots at the
  -- original (lower) points; that mismatch put every weld pivot off
  -- the bar's own centerline, meaning gravity + solver error there
  -- produced a torque instead of just a force -- likely why that bar
  -- flew apart first. Passing a taller attach_height for one call and
  -- a shorter one for the other still gives two bars at different
  -- heights, just without that defect.
  --
  -- At construction time the pendant hangs straight down (C.x = B.x),
  -- so moving up by attach_height in world Y corresponds to local X =
  -- p_len/2 - attach_height on the pendant's own body (p_len/2 is C
  -- itself).
  local pivotLocalX = (p_len+p_top_extend)/2 - attach_height
  local PA = { x = lkA.C.x, y = lkA.C.y + attach_height, z = lkA.z_pendant }
  local PB = { x = lkB.C.x, y = lkB.C.y + attach_height, z = lkB.z_pendant }

  local dx, dy, dz = PB.x-PA.x, PB.y-PA.y, PB.z-PA.z
  local len = math.sqrt(dx*dx + dy*dy + dz*dz)
  local bar_quat = alignVecX(dx, dy, dz)
  local bar_center = btVector3((PA.x+PB.x)/2, (PA.y+PB.y)/2, (PA.z+PB.z)/2)

  local bar = Cube(len, width, rod_d, mass)
  bar.col = color
  bar.trans = btTransform(bar_quat, bar_center)
  bar.damp_ang = 0.15
  add(bar)

  -- with the center exactly at the midpoint of PA/PB, each pivot is
  -- simply +-len/2 along the bar's own local X -- on-axis, no offset
  -- math needed at all this time.
  local frameInBar_end = len/2

  -- both pendants in a (phase-matched) diagonal pair share the same
  -- orientation at construction, so one quaternion is the correct
  -- weld-frame rotation TARGET for both ends. The bar's own frame needs
  -- qconj(bar_quat)*pendant_quat to land on that target, since the bar
  -- itself isn't built unrotated this time (unlike the old crossbars).
  local pendant_quat = lkA.pendant.trans:getRotation()
  local frameRot_onBar = qmul(qconj(bar_quat), pendant_quat)

  -- GIVE: a small, deliberate amount of Z-rotation slack, so the weld
  -- absorbs the small unavoidable phase drift between the two same-
  -- phase cranks (torque-limited motors, not perfectly rigid velocity
  -- sources -- see the note above) instead of rigidly fighting it. This
  -- needs btGeneric6DofConstraint, not btSliderConstraint: a slider's
  -- only give axis is a twist about its own local X, which here points
  -- along world -Y (the direction the pendant hangs), not world Z (the
  -- axis everything in this mechanism actually rotates about) -- 6dof
  -- lets each axis be set independently. Index 5 (angular Z, in this
  -- frame's own convention) is exactly world Z here, because
  -- frameRot_onBar's world rotation equals pendant_quat, which -- being
  -- built by zrotVec -- is always a pure Z-axis rotation, so its own Z
  -- axis maps to world Z regardless of angle.
  local giveAngle = math.rad(3)   -- small and tunable -- widen if it's still fighting the drift, narrow if it looks too loose

  local frameInBar_A = btTransform(frameRot_onBar, btVector3(-frameInBar_end, 0, 0))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(pivotLocalX, 0, 0))
  local weldA = btGeneric6DofConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLinearLowerLimit(btVector3(0, 0, 0))   -- position still fully locked, same as the old weld
  weldA:setLinearUpperLimit(btVector3(0, 0, 0))
  weldA:setLimit(3, 0, 0)                          -- angular X locked
  weldA:setLimit(4, 0, 0)                          -- angular Y locked
  weldA:setLimit(5, -giveAngle, giveAngle)          -- angular Z: the deliberate give
  stiffenExcept(weldA, 5)                          -- stiffen everything except the give axis
  addConstraint(weldA)

  local frameInBar_B = btTransform(frameRot_onBar, btVector3(frameInBar_end, 0, 0))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(pivotLocalX, 0, 0))
  local weldB = btGeneric6DofConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLinearLowerLimit(btVector3(0, 0, 0))
  weldB:setLinearUpperLimit(btVector3(0, 0, 0))
  weldB:setLimit(3, 0, 0)
  weldB:setLimit(4, 0, 0)
  weldB:setLimit(5, -giveAngle, giveAngle)
  stiffenExcept(weldB, 5)
  addConstraint(weldB)

  return bar
end

-- ONE PLATE INSTEAD OF TWO BARS: this used to be two separate bars --
-- diagonal1 (purple/slateblue, linkage1<->linkage4) at 0.5 above C, and
-- diagonal2 (red/firebrick, linkage2<->linkage3) at 2.3 above C, offset
-- from each other purely so they wouldn't collide where their diagonals
-- cross. They connect DIFFERENT pendant pairs, so it was never an
-- over-constraint bug the way the old front/back crossbars were -- just
-- visual/structural clutter (an X-brace at each end). Per request: the
-- red bar is removed, and the purple one becomes a single wider plate
-- spanning the same 0.5-to-2.3 range the two bars used to occupy
-- (width=1.8, centered at attach_height=1.4 -- the old pair's midpoint).
-- See the width note on buildDiagonalCrossbar above for why this
-- widened dimension really is vertical, not just approximately so.
-- Net effect: the right-front<->left-back pair (2<->3) now has NO
-- bottom brace at all -- only the left-front<->right-back pair (1<->4)
-- is braced here. The mass (1.0) was originally chosen alongside
-- diagonal2's 0.385 to counterweight the pair's combined center of
-- mass -- that reasoning no longer applies now that diagonal2 is gone,
-- so this may be worth revisiting on its own (a wider plate arguably
-- wants more mass, not the same amount tuned for a thin bar) -- left
-- unchanged here since only geometry was asked for.
local diagonalBottom = buildDiagonalCrossbar(linkage1, linkage4, 1.4 * S, "slateblue", 1.0, 1.8 * S)   -- left-front <-> right-back -- the sole bottom brace now

-- TOP crossbar: same idea as the bottom pair, but attached near the
-- TOP of the (now-extended) pendant instead of near C at the bottom.
-- Used to be topDiagonal1 (purple/slateblue, linkage1<->linkage4) at
-- p_len+1.0=11.5, and topDiagonal2 (red/firebrick, linkage2<->linkage3)
-- at p_len+2.8=13.3, offset for the same crossing-clearance reason as
-- the old bottom pair. Per request: purple is removed, red becomes a
-- single wider plate spanning that same 11.5-to-13.3 range (width=1.8,
-- centered at attach_height=12.4). B_top sits at p_len+p_top_extend=
-- 14.5 above C, so the plate's own top edge (13.3) still leaves the
-- same 1.2 units of clearance below the rod's own tip the old higher
-- bar had, and its bottom edge (11.5) still clears the original B point
-- (10.5) by 1.0, same as before -- the plate occupies exactly the old
-- pair's combined footprint, nothing new.
-- Net effect: the left-front<->right-back pair (1<->4) now has NO top
-- brace -- only right-front<->left-back (2<->3) is braced up here,
-- mirroring the bottom's asymmetry (which now favors 1<->4 instead).
-- Between the two plates, every pair ends up with exactly one brace,
-- just at opposite ends -- 1<->4 at the bottom, 2<->3 at the top.
--
-- HONEST CAVEAT: unlike the bottom (well clear of the actively-rotating
-- crank/coupler/rocker, down near the feet), this top plate sits closer
-- to where those parts actually move. The STATIC geometry checks out
-- (same footprint the old pair occupied), but whether it stays clear of
-- the crank/coupler/rocker through a full rotation isn't something I
-- can verify without actually running it.
local diagonalTop = buildDiagonalCrossbar(linkage2, linkage3, 12.4 * S, "firebrick", 0.385, 1.8 * S)  -- right-front <-> left-back -- the sole top brace now

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
  local outward_extra = 2.0 * S            -- how far the foot reaches PAST the pendant, away from the body
  local inner_gap = 1.0 * S --0.3                -- stops short of z=0 by this much, so opposing feet don't touch at the center

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0 * S, 0.3 * S      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.2)   -- heavier than before (was 0.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8 -- 0.9 -- This gave straighest motion. WMS
  add(foot)

  local pendant_quat = lk.pendant.trans:getRotation()
  -- the pendant attaches at z=zp, which is now partway along the foot's
  -- length (not at its end), since the foot extends past it on both sides
  local frameInFoot    = btTransform(pendant_quat, btVector3(0, 0, zp - foot_center_z))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3((p_len+p_top_extend)/2, 0, 0))   -- C is still the pendant's own "+X end" -- but the rod's own half-length grew with the extension, so this is no longer simply p_len/2
  local weld = btSliderConstraint(foot.body, lk.pendant.body, frameInFoot, frameInPendant, true)
  weld:setLowerLinLimit(0)   -- see the earlier note: slider defaults to FREE translation unless locked
  weld:setUpperLinLimit(0)
  stiffen(weld)
  addConstraint(weld)

  return foot
end

local foot1 = buildFoot(linkage1, "yellow")
local foot2 = buildFoot(linkage2, "blue")
local foot3 = buildFoot(linkage3, "blue")
local foot4 = buildFoot(linkage4, "yellow")
return {
  cube = cube, cube_w = cube_w, cubeCenterX = cube_center_x,
  linkage1 = linkage1, linkage2 = linkage2, linkage3 = linkage3, linkage4 = linkage4,
  diagonalBottom = diagonalBottom, diagonalTop = diagonalTop,
  foot1 = foot1, foot2 = foot2, foot3 = foot3, foot4 = foot4,
}
end   -- closes M.build()

return M
