--
-- Jansen Walker -- a physically-simulated Theo Jansen ("Strandbeest") leg
-- mechanism, six legs (three mirrored pairs, laid out side by side)
-- mounted on a triangulated spine, built the same way as
-- demo/WyomingWill/cheby_normal6.lua: real Bullet rigid bodies + hinge
-- constraints (one of them motorized per leg), not analytic forward
-- kinematics.
--
-- KEYBOARD SHORTCUTS:
-- * R - reverse walking direction (see the shortcut's own comment below
--       for why flipping every crank motor's sign is enough)
--
-- Ground link lengths a..m are Theo Jansen's own published "holy numbers",
-- transcribed from the linkage_c reference tool's mechanisms.c (the same
-- crossing-free branch choice used there and in demo/WyomingWill/linkage.lua
-- -- an earlier, more commonly-cited branch choice was found to have two
-- links overlapping for 100% of the cycle, which isn't physically buildable
-- here any more than it would be with real hinges).
--
-- WHY 11 RIGID BODIES PER LEG, NOT 8: mechanisms.c's own compute_jansen()
-- finds each new joint (J2..J5, F) via circle_intersect(), i.e. a classic
-- RRR dyad -- two binary links whose OTHER ends are already known, meeting
-- at the new joint. Walking that dyad chain out gives 11 distinct binary
-- rods (crank O-J1, then J1-J2, G-J2, J2-J3, G-J3, J1-J4, G-J4, J3-J5,
-- J4-J5, J4-F, J5-F). The README's "8 links" count is the informal
-- description of the classic linkage (some of these rods -- e.g. G-J2,
-- J2-J3, G-J3 -- form a rigid triangle in a real Strandbeest leg and could
-- be cast as one ternary plate); kinematically a triangle of 3 pin-jointed
-- rods has zero internal freedom anyway, so building it here as 3 separate
-- hinged rods reproduces the exact same 1-DOF motion, just with more
-- (still fully consistent) constraints -- confirmed by DOF counting: 11
-- rods * 3 planar DOF = 33, minus 16 hinges * 2 DOF removed = 32, leaves
-- exactly 1 DOF, driven by the single motorized crank hinge at O.
--
-- HUB CONVENTION: several joints have MORE than 2 rods meeting at the same
-- point (J1 has 3, G has 3, J4 has 4). At each such point one rod is
-- picked as the "hub" and every other rod there is hinged directly to the
-- hub (all at the same local pivot) rather than to each other -- this pins
-- all of them together at that point without redundant/conflicting
-- constraints. See the hinge block in buildJansenLeg for exactly which rod
-- is the hub at each joint.
--
-- MIRRORED LEGS: a real Strandbeest's paired legs (front/back of one
-- crank) ARE true mirror images of each other -- but the mirror axis that
-- matters is Z (the lateral, side-to-side axis), not X (the walking
-- direction). An earlier version of this file also reflected the (X,Y)
-- shape itself across O.x and negated the mirrored leg's motor speed to
-- compensate (reasoning: a rotating shaft looks clockwise from one end
-- and counterclockwise from the other, so the mirrored leg's crank must
-- turn the opposite way). That reasoning about the ROTATIONAL SENSE was
-- right, but it doesn't imply the (X,Y) SHAPE needs reflecting too -- and
-- testing this proved it doesn't: with the shape reflected AND the sign
-- negated, cube.pos.x stayed at EXACTLY 0.00 for a full 900-frame run --
-- the mirrored pair's thrust was cancelling instead of adding, because
-- reflecting an asymmetric foot path makes it sweep the opposite X
-- direction during stance from its (unreflected) partner. The physically
-- correct picture: each leg is an entirely flat (X,Y) mechanism confined
-- to its own Z-plane; two copies sharing one crank, sitting in PARALLEL
-- planes on either side of the spine, are already each other's mirror
-- image simply by being Z-translated -- reflecting a flat shape across
-- the very plane it already lies in changes nothing about that shape, only
-- which side it's on. So both legs of a pair use the IDENTICAL (X,Y)
-- shape and the SAME motor sign; mirror only flips which side of Z they
-- sit on (exactly like cheby_normal6.lua's back face -- every hinge axis
-- is world Z, so flipping the whole staggered Z-plane stack's sign is
-- the entire job).
--
-- HONEST CAVEAT (stability): CFM softening (see HINGE_CFM / hinge()
-- below) was needed just to keep one leg's own closed-loop network from
-- diverging (see the CFM note below for why -- and for why it has to be
-- applied per-hinge, not as a world-level v:setCfm() call).
--
-- RESOLVED: FOR A WHILE, THIS WALKER DIDN'T TRAVEL. Laying all three
-- leg-pairs side by side along Z, all sharing the same X, appeared to
-- measure out to zero net motion no matter what was tried:
--   1. PAIR_X_STAGGER (declared below, near LANE_SPACING) nudging each
--      pair along X too, tested at 0, 40, 80, 120, and 160 units.
--   2. Cube mass, dropped from 220 down to 15, 5, 3, and 1.
--   3. Cube size, shrunk from spanning all 6 lanes down to a small
--      24-unit-deep central hub.
--   4. Foot friction, dropped from 0.9 to 0.3, 0.15, and 0.05 --
--      produced BIT-IDENTICAL trajectories at every value.
-- None of those changed the outcome even slightly. The actual cause
-- turned out to be unrelated to the leg arrangement entirely: the
-- TRIANGULATED TRUSS below was originally built with mass 0 for its
-- struts ("purely decorative, why would it need mass?"), each welded
-- rigidly to the cube. In Bullet, mass 0 means STATIC -- not "weightless
-- but free to move" -- so those 17 struts were 17 immovable anchors, each
-- permanently pinned to the cube's own CONSTRUCTION-TIME position; the
-- moment the cube tried to move, all 17 welds fought it back to where it
-- started. Confirmed by elimination: removing the truss entirely let the
-- cube travel 150+ units in 15 simulated seconds; restoring the truss
-- with a small nonzero strut mass (see TRUSS_MASS near the truss code)
-- walked just as well; raising solver iterations on the mass-0 version
-- (30, 50, 100 -- well above Bullet's default) did NOT help, which is
-- what pointed away from a precision/convergence explanation and toward
-- the static-vs-dynamic distinction specifically. Direct cube.vel
-- instrumentation during the broken period showed the actual signature
-- clearly: vel.x pinned within +-0.003 for an entire crank cycle while
-- vel.y swung from -2.5 to +0.17 and vel.z sustained excursions up to
-- 0.85 -- consistent with X being rigidly anchored while Y/Z retained
-- whatever slight give Bullet's CFM softening allowed even on a nominally
-- "static" weld. None of the four leg-layout fixes above could ever have
-- worked, since the leg arrangement was never the problem -- they're kept
-- here (PAIR_X_STAGGER is still 0; cube mass is still 220) as a record of
-- what was ruled out, not as remaining live levers.
--
-- SIX LEGS, NOT FOUR: the original 4-leg build (2 pairs x front/back,
-- phases 0/180) walked for a while but eventually tipped and fell -- with
-- only two phase groups 180 degrees apart, and each leg's own duty cycle
-- only ~62% of the cycle in ground contact (see linkage.lua's metrics for
-- this same mechanism), there are stretches where neither phase group has
-- solid contact, and the walker is momentarily balanced on very little
-- support. A third pair at a THIRD phase (0/120/240 degrees, not 0/180)
-- fills that gap: with duty ~62% and 3 phase groups spread evenly, at
-- least one (usually two) of the three is in stance at any instant, so
-- the cube is never left standing on a near-empty base the way the 2-pair
-- version was. Within a pair, front and back (the mirrored pair) already
-- move as true counterparts by construction (see "MIRRORED LEGS" above);
-- the three PAIRS (laid out side by side along Z, not spread along X the
-- way an earlier version of this file did) are what's phase-staggered for
-- continuous support -- unrelated to which axis they happen to sit along.
-- Now that the walker actually travels (see the "RESOLVED" note above)
-- and holds itself upright while doing so (see cube.damp_ang below, near
-- where the cube is built), it holds its full standing height for the
-- ENTIRE walk rather than sagging over time -- checked out to 900 frames
-- / 45s, reaching nearly 400 units of travel with pitch never exceeding
-- a few degrees. (An earlier version of this note described the walker
-- as "sagging into a lower stance" after ~10-12 seconds -- that was this
-- same pitch-forward problem, just misdiagnosed from cube.pos alone,
-- without checking cube.trans's actual rotation.)
--

local common = require "common"

-- SUBSTEP FINENESS: this must be at least as fine as the reference
-- mechanism's (cheby_diag4_surface.lua uses fixedTimeStep=1/480), and
-- arguably finer, not coarser -- this leg has 16 hinges per leg forming
-- several NESTED closed loops (redundant constraints even though
-- kinematically consistent, see the header note), while the reference
-- mechanism is a single simple loop with no redundancy at all. A
-- coarser substep lets MORE positional error accumulate in that already
-- fragile redundant network between each correction -- and that
-- accumulated error is exactly what surfaces as a large corrective
-- solver impulse (see the CFM note below for why this network needs
-- correcting at all). The previous timing here, 1/240, was actually
-- *coarser* than the reference's 1/480 despite this mechanism needing
-- finer integration, not coarser -- backwards for what this network
-- actually needs. 1/960 (4x finer than the old value, 2x finer than the
-- reference) keeps the same real-world timeStep (1/20 s/frame) by
-- doubling maxSubSteps to 48 (48 * 1/960 = 1/20, still an exact match,
-- no leftover fractional substep).
--common.setTiming(1/20, 48, 1/960)
common.setTiming(1/20, 48, 1/960)

-- Each leg's 16 hinges form several NESTED closed loops (unlike
-- cheby_normal6.lua's single open-then-closed 4-bar loop), which is a
-- classically hard case for an iterative sequential-impulse solver: even
-- though every pivot was verified to coincide to ~1e-6 at construction
-- (see the "WHY 11 RIGID BODIES" header note), the solver has no slack to
-- resolve the inevitable per-step floating-point/discretization error
-- among that many redundant constraints, so it fights itself and the leg
-- diverges within seconds at Bullet's default (zero) constraint force
-- mixing. A modest CFM gives every hinge a little softness -- verified
-- experimentally: 0 diverges immediately, 0.01 still drifts slowly, 0.1
-- holds a leg motionlessly stable indefinitely and lets the whole walker
-- walk (checked out to 800+ simulated frames).
--
-- THIS MUST BE PER-HINGE, NOT A WORLD-LEVEL v:setCfm() CALL: v:setCfm()
-- sets Bullet's *global* constraint force mixing, which softens every
-- constraint the solver touches each step -- including the CONTACT
-- constraints collision detection generates against the terrain (and,
-- to a lesser extent, anything else a foot touches). An earlier version
-- of this file called v:setCfm(0.1) globally, and the walker fell
-- straight through the terrain no matter how that mesh was built (open
-- shell, closed watertight solid, even a grid of separately-collidable
-- Cube tiles) -- because the softening was never really about the
-- terrain's shape, it was silently weakening every contact in the world
-- too, so nothing could build up resisting force fast enough before a
-- fast-moving foot penetrated straight through. The reference mechanism
-- this file is modeled on (cheby_diag4_surface.lua) never calls
-- v:setCfm() at all -- it leaves the world's contact solving at
-- Bullet's normal rigid default, and only softens ONE specific joint at
-- a time via c:setParam(3, cfmValue, -1) (see its own stiffen()/
-- stiffenExcept() helpers). CFM below is applied the same way, inside
-- hinge() itself, on the CFM axis (param 3) with axis -1 (the
-- constraint's main lock, not a specific limit/motor axis) -- so only
-- the 16 leg hinges get softened, and terrain/backstop contact
-- collision stays fully rigid.
local HINGE_CFM = 0.1

-- ---------------------------------------------------------------------
-- Jansen's own link lengths (mechanisms.c's a..m), identical for every leg
-- ---------------------------------------------------------------------

local LEN = {
  a = 38.0, b = 41.5, c = 39.3, d = 40.1, e = 55.8, f = 39.4, g = 36.7,
  h = 65.7, i = 49.0, j = 50.0, k = 61.9, l = 7.8, m = 15.0,
}

-- ---------------------------------------------------------------------
-- shared geometry helpers (same conventions as demo/WyomingWill/cheby_normal6.lua)
-- ---------------------------------------------------------------------

function midpoint(p1, p2)
  return { x = (p1.x + p2.x) / 2, y = (p1.y + p2.y) / 2 }
end

-- one of the two points where a circle (center p1, radius r1) meets a
-- circle (center p2, radius r2); branch = +1 or -1 selects which one --
-- same convention (and same verified branch values) as mechanisms.c's
-- circle_intersect() / demo/WyomingWill/linkage.lua's circleIntersect().
function circleIntersect(p1, r1, p2, r2, branch)
  local dx, dy = p2.x - p1.x, p2.y - p1.y
  local dist = math.sqrt(dx * dx + dy * dy)
  local a = (r1 * r1 - r2 * r2 + dist * dist) / (2.0 * dist)
  local h2 = r1 * r1 - a * a
  local h = (h2 > 0.0) and math.sqrt(h2) or 0.0
  local mx, my = p1.x + a * dx / dist, p1.y + a * dy / dist
  local px, py = -dy / dist, dx / dist
  return { x = mx + branch * h * px, y = my + branch * h * py }
end

-- build a Z-axis rotation quaternion directly from a direction vector
-- (half-angle formulas -- avoids atan2, following the same portability
-- caution as cheby_diag4.lua's own zrotVec).
function zrotVec(dx, dy)
  local len = math.sqrt(dx * dx + dy * dy)
  local cosT, sinT = dx / len, dy / len
  local cosHalf = math.sqrt((1 + cosT) / 2)
  local sinHalf = math.sqrt((1 - cosT) / 2)
  if sinT < 0 then sinHalf = -sinHalf end
  return btQuaternion(0, 0, sinHalf, cosHalf)
end

local IDENTITY_QUAT = btQuaternion(0, 0, 0, 1)
local AXIS = btVector3(0, 0, 1)

-- shortest-arc quaternion mapping local +X to an ARBITRARY 3D direction
-- (dx,dy,dz) -- adapted from cheby_diag4.lua's own alignVecX. (Originally
-- needed here for the truss struts, since removed -- see the AXLE header
-- note below for where this is used now.)
function alignVecX(dx, dy, dz)
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / len, dy / len, dz / len
  local qx, qy, qz, qw = 0, -dz, dy, 1 + dx
  local qlen = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw)
  return btQuaternion(qx / qlen, qy / qlen, qz / qlen, qw / qlen)
end

-- same shortest-arc construction as alignVecX, but for local +Y instead
-- of local +X -- see the AXLE header note below for why: Bullet's own
-- base btCylinderShape (unlike this file's Cube, whose long dimension is
-- whichever argument you put first) always puts its height along local Y,
-- so aligning a cylinder onto an arbitrary direction means rotating
-- local +Y there, not local +X.
function alignVecY(dx, dy, dz)
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / len, dy / len, dz / len
  local qx, qy, qz, qw = dz, 0, -dx, 1 + dy
  local qlen = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw)
  return btQuaternion(qx / qlen, qy / qlen, qz / qlen, qw / qlen)
end

local ROD_W, ROD_D = 1.8, 0.8   -- rod cross-section (Z-thickness ROD_D must stay
                                 -- under plane_gap below, or adjacent Z-planes'
                                 -- rods would overlap and collide)
local ROD_COLOR = "#d9c39a"     -- uniform tan, like real Strandbeest PVC
                                 -- electrical conduit -- all 11 rods share
                                 -- this one color rather than being coded
                                 -- by role, since a real leg isn't color-coded
                                 -- either (that's a kinematics-diagram
                                 -- convention, e.g. the Wikipedia animation's
                                 -- red/green/blue-per-phase-group scheme --
                                 -- not how the actual machine looks)
local MASS_BASE, MASS_PER_LEN = 0.3, 0.04   -- rod mass = MASS_BASE + length*MASS_PER_LEN

-- makes one rod-shaped rigid body from p1 to p2, sitting flat on its own
-- Z-plane; also returns its length (every hinge pivot below is expressed
-- as +-length/2 along the rod's own local X, since zrotVec always points
-- local +X from p1 toward p2 -- same trick as cheby_normal6.lua's makeLink).
function makeLink(p1, p2, z, color)
  local len = math.sqrt((p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, ROD_W, ROD_D, MASS_BASE + len * MASS_PER_LEN)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  obj.damp_ang = 0.05   -- mild passive damping -- this mechanism has far more
                         -- closed hinge loops than cheby_normal6's simple 4-bar,
                         -- so a little energy bleed helps keep it from ringing
  v:add(obj)
  return obj, len
end

-- thin wrapper around btHingeConstraint, all axes world Z (every rod here
-- only ever rotates about Z, exactly like cheby_normal6.lua's linkages).
-- axisA/axisB are each body's own LOCAL vector that should point along
-- world Z, in that body's own frame -- default AXIS=(0,0,1) is correct
-- for every body in this file EXCEPT the axle cylinders (see AXLE_QUAT
-- below), which are rotated so their local Z no longer equals world Z;
-- hinges built against an axle pass AXLE_LOCAL_AXIS explicitly instead.
function hinge(bodyA, bodyB, pivotA, pivotB, motorSpeed, motorImpulse, axisA, axisB)
  axisA = axisA or AXIS
  axisB = axisB or AXIS
  local h = btHingeConstraint(bodyA, bodyB, pivotA, pivotB, axisA, axisB)
  h:setParam(3, HINGE_CFM, -1)   -- BT_CONSTRAINT_CFM, axis -1 = main lock --
                                  -- scoped to just this one hinge, not the
                                  -- whole world's contact solving (see the
                                  -- HINGE_CFM note above)
  if motorSpeed ~= nil then
    h:enableAngularMotor(true, motorSpeed, motorImpulse)
  end
  v:addConstraint(h)
  return h
end

-- ---------------------------------------------------------------------
-- Z-plane stack -- one plane per rod, RELATIVE to a leg's own lane base
-- (see LANE_SPACING below) -- so the 11 rotating rods never collide with
-- each other or a neighboring leg's stack (same technique as
-- cheby_normal6.lua's z_ground/z_crank/z_coupler/..., just expressed
-- relative to a per-leg base now that six legs share the Z axis side by
-- side instead of just two).
-- ---------------------------------------------------------------------

local plane_gap = 1.2   -- > ROD_D, so adjacent planes' rod boxes never touch
local STACK_DEPTH = 11 * plane_gap   -- total Z one leg's 11 rod-planes span

local rel_ground = 0   -- reference only (this leg's own lane base) -- not a rod
local rel_crank  = 1  * plane_gap
local rel_rodJ   = 2  * plane_gap
local rel_rodB   = 3  * plane_gap
local rel_rodE   = 4  * plane_gap
local rel_rodD   = 5  * plane_gap
local rel_rodK   = 6  * plane_gap
local rel_rodC   = 7  * plane_gap
local rel_rodF   = 8  * plane_gap
local rel_rodG   = 9  * plane_gap
local rel_rodI   = 10 * plane_gap
local rel_rodH   = 11 * plane_gap

-- ---------------------------------------------------------------------
-- cube body + floor
--
-- LANE_SPACING/NUM_PAIRS lay the three leg-pairs SIDE BY SIDE along Z
-- (not spread out along X, the walking direction) -- matching a real
-- Strandbeest, where several mirrored leg-pairs sit at different points
-- along the width of one crankshaft-like spine, not stationed front-to-
-- back like a hexapod's leg rows. Each pair gets its own STACK_DEPTH-wide
-- band of Z, symmetric about the centerline (front=+Z, back=-Z).
--
-- O_ABOVE_CUBE / JANSEN_YMIN / FOOT_CLEARANCE below were derived the same
-- way as cheby_normal6.lua's floor_top_y: sampling compute(theta) over a
-- full crank rotation. JANSEN_YMIN=-91.83 is foot F's lowest point
-- relative to O; the same sweep also gives the leg's full footprint, x in
-- [-107.17,15.00] y in [-91.83,33.70] relative to O.
-- ---------------------------------------------------------------------

local LANE_SPACING = 20.0   -- > STACK_DEPTH (13.2), so adjacent lanes'
                             -- rod stacks never touch
local NUM_PAIRS = 3         -- 3 leg-pairs = 6 legs -- see the "SIX LEGS"
                             -- header note for why 3, not 2
local PAIR_X_STAGGER = 0.0   -- kept as a real parameter (not deleted) even
                              -- though it's 0 -- see the "HONEST CAVEAT"
                              -- header note: staggering the pairs along X
                              -- was tried, up to 160 units (close to the
                              -- ~220 that worked when pairs were spread
                              -- along X instead of side by side), and it
                              -- never restored net walking, so there is no
                              -- value of this that's worth the visual cost
                              -- of no longer reading as "side by side"
local LEG_MOUNT_X = 0.0     -- every leg's O sits at this same world X
                             -- (PAIR_X_STAGGER above is 0)
local OUTER_REACH = (NUM_PAIRS - 0.5) * LANE_SPACING + STACK_DEPTH   -- outermost
                                                                      -- lane's Z reach

local CUBE_MARGIN = 20.0     -- clearance beyond the outermost lane, so the
                              -- body's own Z-extent doesn't clip the legs
-- MOUNT_SPAN_MIN/MAX: every hinge that attaches directly to the cube (O,
-- plus the three G-rockers) lives in world X between the leftmost pair's
-- G (G.x = O.x - LEN.a, i.e. LEN.a=38 units further -X than O) and the
-- rightmost pair's O -- this is the ONLY span the cube actually needs to
-- structurally cover. An earlier version centered the cube on O alone
-- (CUBE_CENTER_X = LEG_MOUNT_X) with a generous flat CUBE_X_MARGIN on
-- both sides (120 units wide total) -- which put G comfortably inside but
-- left the cube's own +X edge sticking out ~45 units past the farthest
-- any leg hinge actually reaches there, an unsupported cantilever with
-- nothing under it. That overhang is what pitched the whole walker
-- forward onto its nose as it walked. Centering on the REAL mounting
-- span instead, with a small margin, fixes both the balance and the size
-- at once.
local MOUNT_SPAN_MIN = LEG_MOUNT_X - LEN.a                             -- leftmost G
local MOUNT_SPAN_MAX = LEG_MOUNT_X + (NUM_PAIRS - 1) * PAIR_X_STAGGER  -- rightmost O
local CUBE_X_MARGIN = 15.0   -- clearance beyond the mounting span on each side
local CUBE_W = (MOUNT_SPAN_MAX - MOUNT_SPAN_MIN) + 2 * CUBE_X_MARGIN
local CUBE_H = 10.0
local CUBE_D = 2 * (OUTER_REACH + CUBE_MARGIN)   -- spans all 6 lanes side by side
local CUBE_CENTER_X = (MOUNT_SPAN_MIN + MOUNT_SPAN_MAX) / 2   -- centered on the mounting span, not just O

local JANSEN_YMIN    = -91.83   -- foot F's lowest reach relative to O
local FOOT_CLEARANCE = 3.0
local FLOOR_TOP_Y    = 0.0
local O_MOUNT_Y      = FLOOR_TOP_Y - JANSEN_YMIN + FOOT_CLEARANCE
local O_ABOVE_CUBE   = 3.0
local CUBE_POS_Y     = O_MOUNT_Y - O_ABOVE_CUBE - CUBE_H / 2

-- AXLE: the single cube chassis is gone. In its place, NUM_AXLES separate
-- cylinder segments -- one sitting in EACH gap between two Z-adjacent legs
-- -- welded end to end into one effectively-rigid chain, the way a real
-- Strandbeest's driven shaft is one continuous member instead of a single
-- wide plank. Combined mass is kept the same as the old cube's 220 (see
-- AXLE_MASS below) for the same reason the header note gave: a light
-- chassis gets thrown around by its own legs' reaction forces (verified
-- on the earlier 4-leg build -- mass 30 tips and falls within seconds,
-- 150 holds a stable if lower stance).
--
-- 6 legs, 5 gaps: with the legs laid out side by side along Z (see
-- LANE_SPACING/NUM_PAIRS above), consecutive legs are exactly
-- LANE_SPACING apart, so there are (2*NUM_PAIRS - 1) even gaps between
-- them -- 5 for NUM_PAIRS=3. One cylinder per gap.
local NUM_AXLES = 2 * NUM_PAIRS - 1
local AXLE_CENTER_IDX = (NUM_AXLES + 1) / 2   -- =3 of 5 -- the gap between
                                                -- the innermost pair's own
                                                -- front and back leg, i.e.
                                                -- the walker's Z=0 centerline

-- WHY CylinderZ DOESN'T WORK HERE: that was tried first (build the
-- cylinder pre-aligned along Z, so it would need no rotation and every
-- pivot/axis below could keep treating "world offset" and "local offset"
-- as interchangeable, exactly like the old identity-rotation cube did) --
-- but this engine has no CylinderZ global, so that's not this engine's
-- API.
--
-- SECOND ATTEMPT, CONFIRMED WRONG: assumed Cylinder's default long axis
-- was local X, matching this file's Cube(w,h,d,mass) convention (first
-- arg = local-X extent), and rotated with alignVecX(0,0,1) to point that
-- axis down world Z.
--
-- THIRD ATTEMPT, ALSO CONFIRMED WRONG: assumed Cylinder's default was
-- Bullet's own base btCylinderShape convention (height along local Y,
-- the way the raw C++ class works), and rotated with alignVecY(0,0,1)
-- instead. Still not on world Z.
--
-- FOURTH ATTEMPT: with both X and Y rotations ruled out by two rounds of
-- actually looking at the result, the remaining explanation is that this
-- engine's Cylinder() ALREADY defaults to a Z-axis length -- i.e. no
-- rotation was ever needed, and the previous two attempts were actively
-- misaligning an already-correct shape. AXLE_LENGTH_AXIS's "Z" branch
-- below is exactly that: IDENTITY_QUAT, same as the old cube's own
-- (correct, working) rotation. If this is STILL wrong, the shape is
-- fine and the actual bug is elsewhere (radius/length argument order,
-- or a units/scale issue) rather than axis choice -- axis choice only
-- has 3 possibilities and all 3 are now covered by this switch.
local AXLE_LENGTH_AXIS = "Z"   -- "X", "Y", or "Z" -- change this one line
                                -- if the cylinders still come out on the
                                -- wrong axis; everything below derives
                                -- from it

-- THE COST OF AN X OR Y ROTATION (irrelevant for the current "Z" setting,
-- since that's IDENTITY_QUAT and behaves exactly like the old cube did --
-- kept for whoever next has to flip this switch): unlike trussStrut
-- (which only ever welds via explicit btTransform frames, never touches
-- hinge()'s AXIS shortcut), every axle-attached hinge below (O, G) would
-- need BOTH its pivot AND its hinge axis expressed in the axle's own
-- LOCAL frame, not world space directly -- see axleLocal()/
-- AXLE_LOCAL_AXIS just below. Skipping that and reusing a plain
-- `O - axle.pos` world-offset shortcut on a ROTATED axle would silently
-- misplace every axle-side pivot and hinge axis at once, the exact class
-- of quiet bug the header notes elsewhere in this file spent so long
-- chasing down -- which is also exactly why axleLocal() stays in place
-- (as an identity passthrough) even for the "Z" case below, rather than
-- being ripped out: flipping AXLE_LENGTH_AXIS back to "X"/"Y" later
-- shouldn't require restoring deleted code.
local AXLE_QUAT, axleLocal, AXLE_LOCAL_AXIS
if AXLE_LENGTH_AXIS == "X" then
  AXLE_QUAT = alignVecX(0, 0, 1)   -- local +X -> world +Z
  -- local +X -> world +Z, local +Y unchanged, local +Z -> world -X
  axleLocal = function(axle, wx, wy, wz) return btVector3(wz, wy, -wx) end
  AXLE_LOCAL_AXIS = btVector3(1, 0, 0)
elseif AXLE_LENGTH_AXIS == "Y" then
  AXLE_QUAT = alignVecY(0, 0, 1)   -- local +Y -> world +Z
  -- local +X unchanged, local +Y -> world +Z, local +Z -> world -Y
  axleLocal = function(axle, wx, wy, wz) return btVector3(wx, wz, -wy) end
  AXLE_LOCAL_AXIS = btVector3(0, 1, 0)
else -- "Z"
  AXLE_QUAT = IDENTITY_QUAT   -- no rotation needed -- local already = world
  axleLocal = function(axle, wx, wy, wz) return btVector3(wx, wy, wz) end
  AXLE_LOCAL_AXIS = AXIS   -- (0,0,1) -- same constant hinge() already
                            -- defaults to for every non-axle body
end
-- axleLocal transforms a WORLD-space offset (measured FROM an axle's own
-- .pos) into that axle's LOCAL frame -- every axle segment shares this
-- same rotation, so one formula (whichever branch above) covers all of
-- them. This is what pivotCube_O/pivotCube_G's plain `O - cube.pos`
-- subtraction used to get away with skipping, back when the cube's own
-- rotation was identity -- and, with AXLE_LENGTH_AXIS="Z" above, still
-- does, since axleLocal's "Z" branch is that exact same subtraction.
-- AXLE_LOCAL_AXIS is the local vector that points along world Z -- pass
-- it as an axle's own axisA/axisB wherever hinge()'s default
-- AXIS=(0,0,1) was correct for the old, unrotated cube.
--
-- (This still assumes a plain Cylinder(radius, length, mass) constructor
-- exists at all -- confirmed true since only the CylinderZ variant
-- errored, not this one. If the length/radius argument order turns out
-- to be swapped, the cylinders will come out short and fat instead of
-- long and thin -- an easy visual fix, not an axis one; nothing below
-- would need to change for that.)

local AXLE_RADIUS = CUBE_H / 2   -- same vertical thickness the old plank
                                  -- cube had (CUBE_H)
-- AXLE_LEN: previously sized to fit within the GAP between two neighboring
-- legs (this was when each segment sat at the gap's midpoint, clear of
-- both legs' stacks). Now that each segment is repositioned to sit
-- exactly AT its dedicated leg's own z_ground_l (see the leg-centering
-- note in the loop below), the relevant clearance concern flips: it's no
-- longer about reaching into a NEIGHBORING leg's stack, it's about not
-- reaching too far into this SAME leg's own stack, which starts growing
-- immediately outward from z_ground_l (rel_crank onward, see STACK_DEPTH
-- above). Kept short and stub-like for that reason -- a compact hub
-- around the mount point rather than a long beam.
--
-- CONFIRMED SELF-COLLISION AT THE OLD VALUE (6.0): only the crank (at O)
-- and the 3 G-rockers are hinged to the axle, which is what disables
-- collision for them (v:addConstraint always passes
-- disableCollisionsBetweenLinkedBodies=true, see hinge()/addConstraint
-- above) -- every OTHER rod in the leg is a normal collidable body as far
-- as the axle is concerned. At half-length 3.0, the old axle's Z-span
-- reached past rel_crank (1.2) into rel_rodJ (2.4, only 0.4 short of
-- rodJ's own half-thickness ROD_D/2 away) -- confirmed by instrumenting
-- v:eachContact() in a headless run: axle-vs-rodJ contacts fired on 4 of
-- the 6 legs (every leg NOT sharing the center axle segment, whose own
-- 10-unit Z offset from its legs happened to clear rodJ by accident) from
-- frame 1 onward, hundreds of contacts by frame 240. Shrunk so the axle's
-- half-length (1.5) plus rodJ's own half-thickness (0.4) stays under
-- rel_rodJ (2.4) with margin -- the O/G hinges themselves are unaffected,
-- since both sit exactly at z_ground_l regardless of how long the
-- cylinder is (see axleLocal()'s use of z_ground_l - mountAxle.pos.z,
-- always 0 for the dedicated-segment legs).
local AXLE_LEN = 3.0
local AXLE_MASS = 220.0 / NUM_AXLES   -- old cube's total mass split evenly
                                        -- across the segments -- a first
                                        -- pass, like every other tuned
                                        -- constant here, worth confirming
                                        -- empirically once this actually
                                        -- runs (see the "angular damping"
                                        -- note below for how the old
                                        -- cube's own constants were found)

-- Z position of axle segment k: CENTERED ON WHICHEVER LEG'S CRANK MOUNTS
-- THERE, not on the gap between two neighboring legs (the earlier
-- version placed segments at even (k - AXLE_CENTER_IDX)*LANE_SPACING
-- gap-midpoints, which put every dedicated segment 10 units off from the
-- leg it actually serves -- confirmed visually, not just in theory).
-- mountAxleIndex() below assigns each leg to exactly one segment; 4 of
-- the 5 segments (every one except the center) are dedicated to exactly
-- ONE leg apiece, so those can sit exactly at that leg's own z_ground_l
-- (zSign * (p+0.5) * LANE_SPACING, the same formula buildJansenLeg uses).
-- The CENTER segment is the one exception -- it's shared by both
-- innermost legs (back(p=0) and front(p=0)) -- so it stays at the true
-- midpoint between them (Z=0), the best a single shared segment can do
-- for two different mount points 20 units apart.
function axleZ(k)
  if k == AXLE_CENTER_IDX then
    return 0
  elseif k < AXLE_CENTER_IDX then
    local p = AXLE_CENTER_IDX - k   -- back(p)'s own pair index
    return -(p + 0.5) * LANE_SPACING
  else
    local p = k - AXLE_CENTER_IDX   -- front(p)'s own pair index
    return (p + 0.5) * LANE_SPACING
  end
end

axles = {}
for k = 1, NUM_AXLES do
  local az = axleZ(k)
  local ax = Cylinder(AXLE_RADIUS, AXLE_LEN, AXLE_MASS)
  ax.col = "#6b5d4f"   -- weathered wood/frame tone, distinct from the tan
                       -- PVC-tubing rods below -- real Strandbeest usually
                       -- have a wood or metal spine, not colored plastic
  -- X,Y = LEG_MOUNT_X, O_MOUNT_Y -- NOT CUBE_CENTER_X/CUBE_POS_Y anymore.
  -- Every leg's O already sits at exactly (LEG_MOUNT_X, O_MOUNT_Y) (see
  -- buildJansenLeg's `local O = {x = x_offset, y = O_MOUNT_Y}` --
  -- x_offset is LEG_MOUNT_X for every leg here, since PAIR_X_STAGGER=0),
  -- so putting the axle there too, combined with axleZ() above already
  -- matching Z, means O and its dedicated axle segment's .pos are now the
  -- EXACT SAME 3D point for 4 of the 6 legs (the two sharing the center
  -- segment still have a 10-unit Z offset -- see axleZ()'s note on why
  -- that one can't be fully centered). pivotAxle_O below comes out to
  -- (0,0,0) in those cases -- the crank hinges right at the cylinder's
  -- own center, not just alongside it.
  --
  -- TRADEOFF: G (the other hinge onto this same axle segment, see the O/G
  -- hinge code in buildJansenLeg) sits LEN.a=38 units away from O in X by
  -- construction -- an inherent feature of this mechanism, not something
  -- axle placement can fix -- so G is now MORE off-center on its axle
  -- than it was under the old CUBE_CENTER_X compromise position (which
  -- split the difference between O's and G's typical X spans instead of
  -- fully favoring either one). Centering O exactly, as asked, necessarily
  -- gives up some of G's centering.
  ax.trans = btTransform(AXLE_QUAT, btVector3(LEG_MOUNT_X, O_MOUNT_Y, az))
  ax.friction = 0.5
  -- angular damping: this used to need damp_ang=1.0 because O sat ~8
  -- units ABOVE the old cube's own center of mass (O_MOUNT_Y vs
  -- CUBE_POS_Y), and horizontal thrust applied above the COM is a
  -- textbook tip-forward lever arm -- this walker used to pitch forward
  -- hard enough to reach -80 to -90 degrees within ~15 seconds before
  -- damp_ang=1.0 was added (found empirically: 0.3 and 0.6 still tipped
  -- all the way to -89 degrees, 1.0 held pitch under ~4 degrees for a
  -- full 900-frame test). Now that the axle sits AT O_MOUNT_Y instead of
  -- below it, that specific lever arm is gone -- but damp_ang=1.0 is left
  -- in place rather than assumed unnecessary, since nothing has actually
  -- re-verified pitch behavior under this new geometry yet.
  ax.damp_ang = 1.0
  v:add(ax)
  axles[k] = ax
end

-- weld each segment to its neighbor (locked slider, same trick as
-- buildFoot's foot-to-rod weld below) so the chain behaves as one
-- effectively-rigid spine rather than 5 independently floppy pieces, each
-- only held in place by whichever 1-2 legs happen to hinge to it. Segment
-- centers are no longer evenly spaced (axleZ() above gives -50,-30,0,30,50
-- rather than the old even -40,-20,0,20,40), so consecutive gaps are now
-- 20/30/30/20 instead of a uniform 20 -- the weld's own midpoint math
-- below doesn't assume even spacing, so this needs no other change.
for k = 1, NUM_AXLES - 1 do
  local a, b = axles[k], axles[k + 1]
  local midz = (a.pos.z + b.pos.z) / 2
  local frameInA = btTransform(IDENTITY_QUAT, axleLocal(a, 0, 0, midz - a.pos.z))
  local frameInB = btTransform(IDENTITY_QUAT, axleLocal(b, 0, 0, midz - b.pos.z))
  local weld = btSliderConstraint(a.body, b.body, frameInA, frameInB, true)
  weld:setLowerLinLimit(0)
  weld:setUpperLinLimit(0)
  v:addConstraint(weld)
end

-- kept as a stand-in "whole walker" reference point for the trail marker
-- and camera below, the way cube.pos used to serve -- the center segment
-- since it sits at Z=0, the walker's own centerline.
mainAxle = axles[AXLE_CENTER_IDX]

-- which axle segment a given leg's O/G hinges mount to. Each of the 5
-- segments is now positioned (via axleZ() above) at the exact Z of
-- whichever leg is dedicated to it, EXCEPT the center segment, which is
-- dedicated to BOTH innermost legs (back(p=0) and front(p=0)) and sits at
-- their shared midpoint instead. This mapping has to stay consistent
-- with axleZ()'s own back(p)->CENTER_IDX-p / front(p)->CENTER_IDX+p
-- indexing -- they're two views of the same assignment, kept as separate
-- functions only because one is indexed by (p, mirror) and the other by
-- the raw segment number k.
function mountAxleIndex(p, mirror)
  return mirror and (AXLE_CENTER_IDX - p) or (AXLE_CENTER_IDX + p)
end

-- which PAIRS get their (X,Y) shape reflected -- see the "MIRROR-FLIP" note
-- at the flipAboutO call below for what that means and why it's safe.
--
-- USED TO select individual legs by Z-sorted leg number (every EVEN one of
-- #1..#6, via a since-removed legNumber() helper) rather than whole pairs
-- -- e.g. for pair p=0 that mirrored front(p0) (leg #4, even) but NOT
-- back(p0) (leg #3, odd), splitting a single pair between a mirrored leg
-- and an unmirrored one. Confirmed by a headless A/B run (v:preSim
-- position logging over 900 frames) to be why the walker curved instead
-- of tracking straight: front and back of a pair are meant to be true
-- synchronized counterparts (see the "MIRRORED LEGS" header note), and
-- splitting that symmetry within a pair introduces a per-pair left/right
-- foot-path mismatch that steers the walker sideways over many cycles.
-- Selecting by PAIR instead keeps every pair internally symmetric -- only
-- the pattern of WHICH pairs are mirrored varies.
function shouldReflectXY(p, mirror)
  return p % 2 == 1
end

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
-- floor_top_y must match FLOOR_TOP_Y -- that's the constant O_MOUNT_Y (and
-- therefore every leg's mounting height and the feet's lowest reach) was
-- derived from above. It used to be its own local, set from a leftover
-- copy-pasted formula (`4.6 - p_len`, p_len=10.5) borrowed from a
-- different demo's unrelated mechanism -- that put the actual terrain
-- mesh's collision surface ~5.9 units below y=0, while every leg/foot
-- dimension in this file was still calibrated against FLOOR_TOP_Y=0. Feet
-- built to stop 3 units above y=0 had nothing to land on until y=-5.9, so
-- the whole walker sank through that gap before finding the real floor.
local floor_top_y = FLOOR_TOP_Y
local floor_w, floor_d = 3000, 1500
local terrain_amp = 0.8                  -- bump height
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
-- BACK TO THE PLAIN TERRAIN MESH, matching the working reference file
-- exactly (byte-for-byte identical addTriangle code, confirmed by
-- direct diff). The tiled-Cube ground was introduced on a theory about
-- this mechanism's impulse behavior that was NEVER actually confirmed
-- -- and it broke the walker's movement outright, which the plain
-- mesh + correctly-scoped CFM never did on its own. Reverting to the
-- simplest state actually justified by evidence: same terrain as the
-- reference, hinge-scoped CFM (see HINGE_CFM above) instead of the
-- world-level v:setCfm() that was the one confirmed, literal
-- difference between this file and the reference.
floor = Terrain()
local floor_x0, floor_z0 = CUBE_CENTER_X - floor_w/2, -floor_d/2
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
v:add(floor)
--floor.pos = btVector3(CUBE_CENTER_X, FLOOR_TOP_Y - floor_th / 2, 0)
--floor.friction = 0.8
--v:add(floor)

-- ---------------------------------------------------------------------
-- (the triangulated spine truss that used to live here -- decorative
-- struts welded rigidly to the single cube plank -- has been removed
-- along with the cube itself: it was built entirely around the cube's
-- own flat top surface (CUBE_TOP_Y) and X position, and welding a Warren
-- truss across 5 separate, only-just-welded-together axle segments isn't
-- the same structural situation this was designed and tuned for. Keeping
-- only what was asked for -- the floor and the linkages -- rather than
-- carrying decorative bracing over onto a chassis shape it wasn't built
-- for.)

-- ---------------------------------------------------------------------
-- one full Jansen leg: 11 rods + 16 hinges (1 motorized), mounted at
-- world X = x_offset, with O at world Y = O_MOUNT_Y. laneBase places this
-- leg's whole Z-plane stack side by side with its neighbors (see
-- LANE_SPACING above); mirror flips the stack to the -Z side of that lane
-- (the (X,Y) shape itself is NOT reflected -- see the "MIRRORED LEGS"
-- header note for why). phase (degrees) offsets the crank's initial
-- angle, same role as cheby_normal6.lua's buildLinkage `phase` argument.
-- speed's SIGN is what the "R" shortcut below flips to reverse the gait
-- cycle -- see buildJansenLeg's returned hingeO.
-- ---------------------------------------------------------------------

-- MOTOR_IMPULSE caps how much impulse the crank motor can inject PER
-- SUBSTEP to hold its commanded angular velocity. This used to be a
-- flat 3000 -- unlike almost every other constant in this file, that
-- number had no "verified experimentally" note, and it's wildly out of
-- scale next to the reference mechanism's own equivalent: cheby_diag4
-- _surface.lua scales its cap WITH speed (maxMotorImpulse = |speed| *
-- MOTOR_TORQUE_RATIO, ratio=3.0), giving just 9.0 at speed=3.0 -- against
-- rod masses (crank mass 0.3) the same order of magnitude as this
-- file's own rods (crank rod mass ~0.9, see MASS_BASE/MASS_PER_LEN
-- above). A cap that many hundreds of times larger means that if this
-- already-redundant 16-hinge network ever needs a moment of extra
-- torque to hold speed through a tight spot, the motor doesn't get
-- limited -- it can slam a huge impulse into the chain in a single
-- substep, which is then what has to get corrected elsewhere in the
-- network. Scaled down to the same order of magnitude cheby's ratio
-- implies for this mechanism's own masses -- a starting point, like
-- every other tuned constant here, worth confirming empirically rather
-- than assuming correct on the first try.
local MOTOR_IMPULSE = 300.0

function buildJansenLeg(x_offset, mirror, phase, speed, laneBase, mountAxle, reflect)
  local zSign = mirror and -1 or 1
  local z_ground_l = zSign * (laneBase + rel_ground)
  local z_crank_l  = zSign * (laneBase + rel_crank)
  local z_rodJ_l   = zSign * (laneBase + rel_rodJ)
  local z_rodB_l   = zSign * (laneBase + rel_rodB)
  local z_rodE_l   = zSign * (laneBase + rel_rodE)
  local z_rodD_l   = zSign * (laneBase + rel_rodD)
  local z_rodK_l   = zSign * (laneBase + rel_rodK)
  local z_rodC_l   = zSign * (laneBase + rel_rodC)
  local z_rodF_l   = zSign * (laneBase + rel_rodF)
  local z_rodG_l   = zSign * (laneBase + rel_rodG)
  local z_rodI_l   = zSign * (laneBase + rel_rodI)
  local z_rodH_l   = zSign * (laneBase + rel_rodH)

  -- reference-pose geometry (world space, at theta = phase) -- used ONLY
  -- to place bodies/hinges at construction time. Motion afterward comes
  -- entirely from real physics (the motorized crank hinge at O, plus 15
  -- passive hinges), not from re-evaluating this every frame.
  local O = { x = x_offset, y = O_MOUNT_Y }
  local G = { x = O.x - LEN.a, y = O.y - LEN.l }
  local theta0 = math.rad(phase)
  local J1 = { x = O.x + LEN.m * math.cos(theta0), y = O.y + LEN.m * math.sin(theta0) }
  local J2 = circleIntersect(J1, LEN.j, G, LEN.b, -1)
  local J3 = circleIntersect(J2, LEN.e, G, LEN.d, -1)
  local J4 = circleIntersect(J1, LEN.k, G, LEN.c, 1)
  local J5 = circleIntersect(J3, LEN.f, J4, LEN.g, -1)
  local F  = circleIntersect(J4, LEN.i, J5, LEN.h, 1)

  -- MIRROR-FLIP the whole pair (see shouldReflectXY above): reflects the
  -- (X,Y) shape itself about O.x, exactly the "X-reflected geometry" the
  -- "MIRRORED LEGS" header note describes an EARLIER version trying. That
  -- earlier version ALSO negated the mirrored leg's motor speed, reasoning
  -- (by analogy with a shared crankshaft looking clockwise from one end and
  -- counterclockwise from the other) that reflecting the shape alone would
  -- reverse its thrust direction and needed a speed flip to compensate.
  --
  -- CONFIRMED WRONG for this independent-motor design, by a headless A/B
  -- test (v:preSim position logging over 900 frames, comparing mirror+
  -- reverse against mirror-alone and reverse-alone in isolation): with the
  -- shape reflected AND speed negated, the mirrored pairs and unmirrored
  -- pairs pushed in OPPOSITE net directions -- a 3-leg-vs-3-leg tug of war
  -- that oscillated axle.pos.x back and forth with zero net travel over 45
  -- simulated seconds. Reflecting the shape ALONE, with the motor speed
  -- left unchanged, instead reproduced the SAME net thrust direction as an
  -- unmirrored leg (confirmed: clean, monotonic forward travel, actually
  -- MORE stable than the unmirrored baseline) -- so no speed compensation
  -- is needed or correct here; see the baseSpeed note below.
  --
  -- Reflecting every already-computed point about O.x (rather than
  -- re-deriving which circleIntersect() branch to use) keeps every rod's
  -- length constraint exactly satisfied, since reflecting a whole rigid
  -- figure about a line through it preserves every distance inside it.
  if reflect then
    local function flipAboutO(p) p.x = 2 * O.x - p.x end
    flipAboutO(G); flipAboutO(J1); flipAboutO(J2); flipAboutO(J3)
    flipAboutO(J4); flipAboutO(J5); flipAboutO(F)
  end

  local crank = makeLink(O, J1, z_crank_l, ROD_COLOR)
  local rodJ  = makeLink(J1, J2, z_rodJ_l, ROD_COLOR)
  local rodB  = makeLink(G, J2, z_rodB_l, ROD_COLOR)
  local rodE  = makeLink(J2, J3, z_rodE_l, ROD_COLOR)
  local rodD  = makeLink(G, J3, z_rodD_l, ROD_COLOR)
  local rodK  = makeLink(J1, J4, z_rodK_l, ROD_COLOR)
  local rodC  = makeLink(G, J4, z_rodC_l, ROD_COLOR)
  local rodF  = makeLink(J3, J5, z_rodF_l, ROD_COLOR)
  local rodG  = makeLink(J4, J5, z_rodG_l, ROD_COLOR)
  local rodI  = makeLink(J4, F, z_rodI_l, ROD_COLOR)
  local rodH  = makeLink(J5, F, z_rodH_l, ROD_COLOR)

  -- O: mountAxle (ground) <-> crank -- the one driven joint, i.e. the
  -- motor. Both pivot sides are expressed relative to z_ground_l (a
  -- neutral reference plane, not either body's own resting plane) -- same
  -- convention as cheby_normal6.lua's pivotCube_O2/pivotCrank_O2, so the
  -- two sides' world Z actually agree instead of fighting each other.
  -- mountAxle's own side additionally routes through axleLocal() and
  -- passes AXLE_LOCAL_AXIS as its hinge axis, since (unlike the old cube)
  -- the axle segments are rotated -- see the AXLE header note above for
  -- why plain world-offset subtraction (what this used to be) would
  -- silently misplace the pivot now.
  --
  -- baseSpeed: just `speed`, same for every leg regardless of reflect --
  -- see the "MIRROR-FLIP" note above for why the mirrored pair does NOT
  -- get its motor speed negated here (it used to; that was confirmed to
  -- fight the unmirrored pairs' thrust instead of matching it). Still
  -- threaded through and returned (rather than inlined below) so the "R"
  -- shortcut has a per-leg value to flip later.
  local baseSpeed = speed
  local pivotAxle_O  = axleLocal(mountAxle, O.x - mountAxle.pos.x, O.y - mountAxle.pos.y, z_ground_l - mountAxle.pos.z)
  local pivotCrank_O = btVector3(-LEN.m / 2, 0, z_ground_l - z_crank_l)
  local hingeO = hinge(mountAxle.body, crank.body, pivotAxle_O, pivotCrank_O, baseSpeed, MOTOR_IMPULSE, AXLE_LOCAL_AXIS, AXIS)

  -- J1: crank is the hub for rodJ and rodK (3 rods meet here)
  local pivotCrank_J1 = btVector3(LEN.m / 2, 0, 0)
  hinge(crank.body, rodJ.body, pivotCrank_J1, btVector3(-LEN.j / 2, 0, z_crank_l - z_rodJ_l))
  hinge(crank.body, rodK.body, pivotCrank_J1, btVector3(-LEN.k / 2, 0, z_crank_l - z_rodK_l))

  -- G: mountAxle is the hub for rodB, rodD, rodC (3 independent rockers
  -- sharing the same frame pivot, exactly like real Jansen legs' shared
  -- bolt) -- same mountAxle/z_ground_l/axleLocal conventions as the O
  -- hinge above.
  local pivotAxle_G = axleLocal(mountAxle, G.x - mountAxle.pos.x, G.y - mountAxle.pos.y, z_ground_l - mountAxle.pos.z)
  hinge(mountAxle.body, rodB.body, pivotAxle_G, btVector3(-LEN.b / 2, 0, z_ground_l - z_rodB_l), nil, nil, AXLE_LOCAL_AXIS, AXIS)
  hinge(mountAxle.body, rodD.body, pivotAxle_G, btVector3(-LEN.d / 2, 0, z_ground_l - z_rodD_l), nil, nil, AXLE_LOCAL_AXIS, AXIS)
  hinge(mountAxle.body, rodC.body, pivotAxle_G, btVector3(-LEN.c / 2, 0, z_ground_l - z_rodC_l), nil, nil, AXLE_LOCAL_AXIS, AXIS)

  -- J2: rodJ is the hub for rodB and rodE (3 rods meet here)
  local pivotRodJ_J2 = btVector3(LEN.j / 2, 0, 0)
  hinge(rodJ.body, rodB.body, pivotRodJ_J2, btVector3(LEN.b / 2, 0, z_rodJ_l - z_rodB_l))
  hinge(rodJ.body, rodE.body, pivotRodJ_J2, btVector3(-LEN.e / 2, 0, z_rodJ_l - z_rodE_l))

  -- J3: rodE is the hub for rodD and rodF (3 rods meet here)
  local pivotRodE_J3 = btVector3(LEN.e / 2, 0, 0)
  hinge(rodE.body, rodD.body, pivotRodE_J3, btVector3(LEN.d / 2, 0, z_rodE_l - z_rodD_l))
  hinge(rodE.body, rodF.body, pivotRodE_J3, btVector3(-LEN.f / 2, 0, z_rodE_l - z_rodF_l))

  -- J4: rodK is the hub for rodC, rodG, and rodI (4 rods meet here)
  local pivotRodK_J4 = btVector3(LEN.k / 2, 0, 0)
  hinge(rodK.body, rodC.body, pivotRodK_J4, btVector3(LEN.c / 2, 0, z_rodK_l - z_rodC_l))
  hinge(rodK.body, rodG.body, pivotRodK_J4, btVector3(-LEN.g / 2, 0, z_rodK_l - z_rodG_l))
  hinge(rodK.body, rodI.body, pivotRodK_J4, btVector3(-LEN.i / 2, 0, z_rodK_l - z_rodI_l))

  -- J5: rodF is the hub for rodG and rodH (3 rods meet here)
  local pivotRodF_J5 = btVector3(LEN.f / 2, 0, 0)
  hinge(rodF.body, rodG.body, pivotRodF_J5, btVector3(LEN.g / 2, 0, z_rodF_l - z_rodG_l))
  hinge(rodF.body, rodH.body, pivotRodF_J5, btVector3(-LEN.h / 2, 0, z_rodF_l - z_rodH_l))

  -- F: rodI <-> rodH -- the foot joint
  local pivotRodI_F = btVector3(LEN.i / 2, 0, 0)
  local pivotRodH_F = btVector3(LEN.h / 2, 0, z_rodI_l - z_rodH_l)
  hinge(rodI.body, rodH.body, pivotRodI_F, pivotRodH_F)

  return {
    footRod = rodH, z_foot = z_rodH_l, F = F, hingeO = hingeO, baseSpeed = baseSpeed,
  }
end

-- ---------------------------------------------------------------------
-- foot: a flat pad welded (not hinged) to rodH at F (same weld-via-locked-
-- slider trick as cheby_normal6.lua's buildFoot, simplified since each leg
-- already sits on its own dedicated Z-plane stack -- no inward/outward
-- asymmetry needed the way cheby's shared-centerline feet required).
--
-- foot_z USED TO BE 18 (an even-wider 8 before that, see the commented-out
-- line below) -- "extending it in Z for a real contact patch" per this
-- block's own former wording. But the foot is only welded (and so only
-- collision-excluded, see the HINGE_CFM/hinge() note on
-- disableCollisionsBetweenLinkedBodies) to rodH; it's centered on rodH's
-- own plane and every OTHER rod is a normal collidable body to it. rodH's
-- very next neighbor, rodI, sits only one plane_gap (1.2) away -- so
-- ANY foot_z past roughly 1.6 physically engulfs rodI's own plane, and
-- 18 (or even the old 8) engulfed several more beyond that (rodG, rodF,
-- rodK...). Confirmed by instrumenting v:eachContact() in a headless run:
-- foot-vs-rodI fired on EVERY one of the 6 legs from frame 1 onward, with
-- applied impulses up to ~1600 -- vastly larger than the axle/rodJ issue
-- fixed above, and the main driver of the walker tipping over within
-- ~25 simulated seconds (upright metric, 1-2*(qx^2+qz^2) of the main
-- axle's rotation, went from 0.99 to -0.9997 over that span while these
-- fired continuously). Set to ROD_D -- the same thickness every other rod
-- plane already uses -- so the foot occupies exactly its own plane's
-- worth of Z, like everything else in this stack, with no overlap into
-- rodI's.
-- ---------------------------------------------------------------------

function buildFoot(lk, color)
  local F = lk.F
  local z = lk.z_foot
  --local foot_x, foot_y, foot_z = 9.0, 1.4, 8.0
  --local foot_x, foot_y, foot_z = 9.0, 1.4, 18.0
  local foot_x, foot_y, foot_z = 9.0, 1.4, ROD_D

  local foot = Cube(foot_x, foot_y, foot_z, 1.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(F.x, F.y, z))
  foot.friction = 0.9
  v:add(foot)

  local rod_quat = lk.footRod.trans:getRotation()
  local frameInFoot = btTransform(rod_quat, btVector3(0, 0, 0))
  local frameInRod  = btTransform(IDENTITY_QUAT, btVector3(LEN.h / 2, 0, 0))
  local weld = btSliderConstraint(foot.body, lk.footRod.body, frameInFoot, frameInRod, true)
  weld:setLowerLinLimit(0)   -- btSliderConstraint defaults to FREE translation
  weld:setUpperLinLimit(0)   -- unless locked -- these two calls make it a weld
  v:addConstraint(weld)

  return foot
end

-- ---------------------------------------------------------------------
-- six legs: NUM_PAIRS pairs laid out SIDE BY SIDE along Z x front/back
-- (Z-mirrored, see "MIRRORED LEGS" above) within each pair. Front and back
-- within a pair share the same phase and the same (unreflected) shape, so
-- they move as true synchronized counterparts; the three pairs are
-- staggered 360/NUM_PAIRS degrees apart -- see the "SIX LEGS" header note
-- for why this beats the original 2-pair/0-180-degree scheme for stability.
-- ---------------------------------------------------------------------

local SPEED = 0.5

legs, feet = {}, {}
for p = 0, NUM_PAIRS - 1 do
  local laneBase = (p + 0.5) * LANE_SPACING
  local phase = p * (360.0 / NUM_PAIRS)
  local x_offset = LEG_MOUNT_X + p * PAIR_X_STAGGER

  local legFront = buildJansenLeg(x_offset, false, phase, SPEED, laneBase, axles[mountAxleIndex(p, false)], shouldReflectXY(p, false))
  local legBack  = buildJansenLeg(x_offset, true, phase, SPEED, laneBase, axles[mountAxleIndex(p, true)], shouldReflectXY(p, true))
  table.insert(legs, legFront)
  table.insert(legs, legBack)

  table.insert(feet, buildFoot(legFront, "#33302c"))   -- dark, like rubber/PVC
  table.insert(feet, buildFoot(legBack, "#33302c"))    -- foot caps -- was
                                                        -- yellow/blue before,
                                                        -- which read as toy-like
                                                        -- rather than Strandbeest-like
end

-- ******************
-- KEYBOARD SHORTCUTS
-- ******************

-- R: reverse walking direction. Every leg's motion comes from ONE
-- motorized hinge (crank<->cube at O); the other 15 hinges per leg are
-- passive, just following along -- so reversing the walk is as simple as
-- flipping every crank motor's target angular velocity sign. Since the
-- foot traces a CLOSED loop (theta -> theta+2*pi returns to the same
-- pose), running theta backward retraces that exact same loop in reverse,
-- including the flat "stance" portion -- so the foot sweeps the ground in
-- the opposite X direction during stance, which is what actually walks
-- the cube backward (verified: cube.pos.x climbs, then after a brief
-- momentum-driven overshoot following a reversal, genuinely turns around
-- and decreases). The three pairs' relative phase offsets (0/120/240
-- degrees, baked in at construction via each crank's initial angle --
-- see buildJansenLeg) stay staggered the same way under a sign flip, so
-- the continuous-support property survives the reversal too. Each leg's
-- OWN baseSpeed is what gets flipped here (currently always equal to the
-- shared SPEED -- see the "MIRRORED LEGS" header note for why it's still
-- threaded through per-leg rather than inlined), multiplying walkDir
-- onto it.
local walkDir = 1

v:addShortcut("R", function(N)
  walkDir = -walkDir
  for _, lk in ipairs(legs) do
    lk.hingeO:enableAngularMotor(true, walkDir * lk.baseSpeed, MOTOR_IMPULSE)
  end
  print("Jansen Walker: gait cycle now running " .. (walkDir > 0 and "forward" or "backward"))
end)

-- ---------------------------------------------------------------------
-- centroid trail -- same idea as cheby_normal6.lua's: drop a small
-- static marker on the floor every TRAIL_INTERVAL frames at mainAxle's
-- current (x,z) -- mainAxle (the center axle segment, see the AXLE header
-- note above) stands in for "the walker's position" the way cube.pos used
-- to -- to visualize the walker's trajectory over time.
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30
local trail_frame_count = 0

v:preSim(function(N)
  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    local marker = Cube(3.0, 0.2, 3.0, 0)
    marker.col = "red"
    marker.pos = btVector3(mainAxle.pos.x, FLOOR_TOP_Y, mainAxle.pos.z)
    v:add(marker)
  end
end)

-- ---------------------------------------------------------------------
-- camera -- follow the walker's center, same fixed-offset chase style as
-- cheby_normal6.lua, scaled up for Jansen's much larger native units.
-- ---------------------------------------------------------------------

v:postSim(function(N)
  common.setCamera(btVector3(mainAxle.pos.x - 500, mainAxle.pos.y + 200, mainAxle.pos.z + 500),
                    btVector3(mainAxle.pos.x, mainAxle.pos.y - 50, mainAxle.pos.z), 0.5)
end)

common.gravity(-9.8)

-- EOF
