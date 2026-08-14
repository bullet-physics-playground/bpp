--
-- Jansen Walker -- a physically-simulated Theo Jansen ("Strandbeest") leg
-- mechanism, six legs (three mirrored pairs, laid out side by side)
-- mounted on a triangulated spine, built the same way as
-- demo/WyomingWill/cheby_normal6.lua: real Bullet rigid bodies + hinge
-- constraints (one of them motorized per leg), not analytic forward
-- kinematics. NOTE: in this side-by-side arrangement the mechanism cycles
-- its full gait correctly but does not travel -- see the "HONEST CAVEAT
-- (this walker doesn't travel)" note below for why, and what was tried.
--
-- KEYBOARD SHORTCUTS:
-- * R - reverse the gait cycle direction (see the shortcut's own comment
--       below for why flipping every crank motor's sign is enough) --
--       since this build doesn't travel either way (see above), this
--       mainly reverses which direction each foot sweeps through its
--       stance phase, not a literal forward/backward walk
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
-- HONEST CAVEAT (stability): CFM softening (see v:setCfm below) was
-- needed just to keep one leg's own closed-loop network from diverging
-- (see the CFM note below for why).
--
-- HONEST CAVEAT (this walker doesn't travel): laying all three leg-pairs
-- side by side along Z, all sharing the same X, measures out to zero net
-- motion -- cube.pos.x sits within +-0.001 of its starting point over a
-- full 900-frame test, even with the mirror fix above applied. Four
-- separate fixes were tried and none of them worked, which is worth
-- recording so a future attempt doesn't re-tread the same ground:
--   1. PAIR_X_STAGGER (declared below, near LANE_SPACING; currently 0)
--      nudges each pair along X too, on the theory that simultaneously-
--      planted feet from different phase groups were gripping the exact
--      same ground patch from competing directions. Tested at 40, 80,
--      120, and 160 units -- the last closing in on the ~220-unit spacing
--      that DOES walk when pairs are spread along X instead of side by
--      side (an earlier version of this file) -- and none produced
--      meaningful net motion; watching individual feet confirmed each
--      pair's own absolute ground-contact range was already well clear of
--      its neighbors' even at modest stagger, ruling out "feet fighting
--      over the same patch" as the actual mechanism.
--   2. Cube mass: dropped from 220 down to 15, then 5, 3, and 1. Heavier
--      values held perfectly still; lighter ones jiggled MORE (up to
--      +-0.5 briefly at mass 1) but never developed a sustained trend --
--      the signature of a mechanism with zero average thrust, not one
--      that's just too heavy to respond to nonzero thrust.
--   3. Cube size: shrunk from spanning all 6 lanes down to a small
--      24-unit-deep central hub (with the truss, not the cube itself,
--      providing the visual frame out to each leg) -- no change.
--   4. Foot friction: dropped from 0.9 to 0.3, 0.15, and 0.05 -- produced
--      BIT-IDENTICAL trajectories at every value tested, which rules out
--      a friction stalemate (multiple feet's conflicting demands locking
--      each other via static friction): if that were the mechanism,
--      lowering friction enough to let a foot slip should have changed
--      the outcome, and it did not, at all.
-- Directly instrumenting cube.vel confirmed a real, specific pattern:
-- vel.x stays within +-0.003 for an ENTIRE crank cycle while vel.y swings
-- from -2.5 to +0.17 and vel.z sustains excursions up to 0.85 for dozens
-- of frames. That's not oscillation-that-cancels-on-average (which is
-- what friction-based cancellation or destructive phase interference
-- would look like) -- X is pinned near-zero at every instant while Y and
-- Z move freely, which is a stronger and stranger constraint than "no net
-- progress." The actual cause remains unidentified. It is NOT a
-- construction bug in any individual leg (still verified pivot-exact --
-- see the diagnostic technique in the "WHY 11 RIGID BODIES" note) and,
-- per the four tests above, not explained by inertia, size, or friction
-- either. This version is shipped as-is: six legs, correctly built and
-- correctly phase-staggered, standing rock-stable and cycling their full
-- gait indefinitely (checked to 900 frames) -- it just doesn't go
-- anywhere. PAIR_X_STAGGER is left in the code at 0 (not deleted) so a
-- future attempt has the hook already wired up, and cube mass is left at
-- the original 220 (not the smaller values tested above, which made no
-- difference) since it's the one known-good value for standing stability.
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
-- continuous support -- unrelated to which axis they happen to sit along,
-- and this benefit held up in the current (side-by-side, non-traveling)
-- layout too: standing height stayed rock-stable for the full 900-frame
-- test, with no sagging at all -- likely because a stationary walker never
-- has to shift its own weight forward the way a traveling one does.
--

local common = require "common"

common.setTiming(1/20, 12, 1/240)   -- finer fixed timestep than cheby_normal6's --
                                     -- this mechanism has far more closed hinge
                                     -- loops (16 per leg vs. 5), which are more
                                     -- prone to drift under a coarse substep

-- Each leg's 16 hinges form several NESTED closed loops (unlike
-- cheby_normal6.lua's single open-then-closed 4-bar loop), which is a
-- classically hard case for an iterative sequential-impulse solver: even
-- though every pivot was verified to coincide to ~1e-6 at construction
-- (see the "WHY 11 RIGID BODIES" header note), the solver has no slack to
-- resolve the inevitable per-step floating-point/discretization error
-- among that many redundant constraints, so it fights itself and the leg
-- diverges within seconds at Bullet's default (zero) constraint force
-- mixing. A modest global CFM gives every hinge a little softness -- verified
-- experimentally: 0 diverges immediately, 0.01 still drifts slowly, 0.1
-- holds a leg motionlessly stable indefinitely and lets the whole walker
-- walk (checked out to 800+ simulated frames).
v:setCfm(0.1)

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
-- (dx,dy,dz) -- adapted from cheby_diag4.lua's own alignVecX, needed for
-- the truss struts below since they run in the Y-Z plane (not X-Y like
-- every leg rod), so zrotVec's Z-axis-only construction can't orient them.
function alignVecX(dx, dy, dz)
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / len, dy / len, dz / len
  local qx, qy, qz, qw = 0, -dz, dy, 1 + dx
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
function hinge(bodyA, bodyB, pivotA, pivotB, motorSpeed, motorImpulse)
  local h = btHingeConstraint(bodyA, bodyB, pivotA, pivotB, AXIS, AXIS)
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
local CUBE_X_MARGIN = 60.0   -- clearance beyond the staggered mount span,
                              -- covering G's own ~38-unit overhang past O
local CUBE_W = (NUM_PAIRS - 1) * PAIR_X_STAGGER + 2 * CUBE_X_MARGIN
local CUBE_H = 10.0
local CUBE_D = 2 * (OUTER_REACH + CUBE_MARGIN)   -- spans all 6 lanes side by side
local CUBE_CENTER_X = LEG_MOUNT_X + (NUM_PAIRS - 1) * PAIR_X_STAGGER / 2   -- middle pair's X

local JANSEN_YMIN    = -91.83   -- foot F's lowest reach relative to O
local FOOT_CLEARANCE = 3.0
local FLOOR_TOP_Y    = 0.0
local O_MOUNT_Y      = FLOOR_TOP_Y - JANSEN_YMIN + FOOT_CLEARANCE
local O_ABOVE_CUBE   = 3.0
local CUBE_POS_Y     = O_MOUNT_Y - O_ABOVE_CUBE - CUBE_H / 2

-- cube mass is heavy relative to the six legs' combined ~135 units of mass
-- -- a light chassis gets thrown around by its own legs' reaction forces
-- (verified on the earlier 4-leg build: at mass 30 the whole walker tips
-- and falls within a few seconds; at 150 it holds a stable, if lower,
-- stance -- scaled up further here for the extra two legs' worth of load).
cube = Cube(CUBE_W, CUBE_H, CUBE_D, 220.0)
cube.col = "#6b5d4f"   -- weathered wood/frame tone, distinct from the tan
                       -- PVC-tubing rods below -- real Strandbeest usually
                       -- have a wood or metal spine, not colored plastic
cube.pos = btVector3(CUBE_CENTER_X, CUBE_POS_Y, 0)
cube.friction = 0.5
v:add(cube)

-- floor is much thicker than a typical bpp floor -- this mechanism's 16
-- hinges per leg form several nested closed loops (see header), which
-- occasionally provoke a large corrective solver impulse; a thin floor
-- let a foot tunnel straight through it in testing, a thick one doesn't.
local floor_w, floor_th, floor_d = 2000, 40.0, 1000
floor = Cube(floor_w, floor_th, floor_d, 0)   -- mass 0 -> static
floor.col = "#694811"
floor.pos = btVector3(CUBE_CENTER_X, FLOOR_TOP_Y - floor_th / 2, 0)
floor.friction = 0.8
v:add(floor)

-- ---------------------------------------------------------------------
-- triangulated spine truss -- purely decorative struts, welded (locked
-- slider, mass 0) rigidly to the main cube so they move as one with it,
-- without adding any DOF to the leg hinge network (same weld-via-locked-
-- slider trick as buildFoot below). A real Strandbeest's frame is a
-- triangulated lattice of wood/PVC struts, not a solid plate -- this
-- approximates that with a classic zigzag (Warren) truss running the
-- spine's WIDTH (Z), the same direction the six legs are now laid out
-- side by side in, rather than along X like the rest of this file's rods.
-- alignVecX (not zrotVec) orients these, since they run in the Y-Z plane.
-- ---------------------------------------------------------------------

local TRUSS_TOP_Y = O_MOUNT_Y + 15.0   -- a "mast" height above the crank line,
                                        -- echoing where a real Strandbeest's
                                        -- wind-driven axle sits above its legs
local TRUSS_COLOR = "#4a3f34"           -- darker than the tan rods, like
                                        -- weathered wood
local TRUSS_W, TRUSS_D = 1.4, 1.4
local CUBE_TOP_Y = CUBE_POS_Y + CUBE_H / 2

-- one strut spanning (z1,y1)..(z2,y2) at the cube's own X, welded rigidly
-- to cube.body (mirrors buildFoot's foot-to-rod weld pattern below, just
-- with cube -- which has identity rotation -- playing the role foot played
-- there, and the strut itself playing the role the rotated rod played).
function trussStrut(z1, y1, z2, y2)
  local dz, dy = z2 - z1, y2 - y1
  local len = math.sqrt(dz * dz + dy * dy)
  local midz, midy = (z1 + z2) / 2, (y1 + y2) / 2
  local q = alignVecX(0, dy, dz)

  local obj = Cube(len, TRUSS_W, TRUSS_D, 0)
  obj.col = TRUSS_COLOR
  obj.trans = btTransform(q, btVector3(cube.pos.x, midy, midz))
  v:add(obj)

  local frameInStrut = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local frameInCube  = btTransform(q, btVector3(0, midy - cube.pos.y, midz - cube.pos.z))
  local weld = btSliderConstraint(obj.body, cube.body, frameInStrut, frameInCube, true)
  weld:setLowerLinLimit(0)
  weld:setUpperLinLimit(0)
  v:addConstraint(weld)
  return obj
end

do
  local N_BOTTOM = 2 * NUM_PAIRS + 1   -- 7 nodes along the cube's top edge
  local bottom_z = {}
  for i = 0, N_BOTTOM - 1 do
    bottom_z[i + 1] = -OUTER_REACH + i * (2 * OUTER_REACH / (N_BOTTOM - 1))
  end

  local prevTopZ = nil
  for i = 1, N_BOTTOM - 1 do
    local topZ = (bottom_z[i] + bottom_z[i + 1]) / 2
    trussStrut(bottom_z[i], CUBE_TOP_Y, topZ, TRUSS_TOP_Y)       -- rising diagonal
    trussStrut(topZ, TRUSS_TOP_Y, bottom_z[i + 1], CUBE_TOP_Y)   -- falling diagonal
    if prevTopZ ~= nil then
      trussStrut(prevTopZ, TRUSS_TOP_Y, topZ, TRUSS_TOP_Y)       -- top rail segment
    end
    prevTopZ = topZ
  end
end

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

local MOTOR_IMPULSE = 3000.0

function buildJansenLeg(x_offset, mirror, phase, speed, laneBase)
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

  -- NOT X-mirrored on purpose -- see the "MIRRORED LEGS" header note. Both
  -- sides of a pair use this SAME (unreflected) (X,Y) shape; mirror below
  -- only flips which Z-band this leg sits in.

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

  -- O: cube (ground) <-> crank -- the one driven joint. Both pivot sides
  -- are expressed relative to z_ground_l (the cube's own surface plane,
  -- not either body's resting plane) -- same "neutral third reference"
  -- convention as cheby_normal6.lua's pivotCube_O2/pivotCrank_O2, so the
  -- two sides' world Z actually agree instead of fighting each other.
  --
  -- baseSpeed is just `speed` here (see the "MIRRORED LEGS" header note --
  -- an earlier version of this file also X-reflected the geometry and
  -- negated this sign, which measured out to EXACTLY zero net walking:
  -- reflecting an asymmetric foot path makes a shared-crank pair's thrust
  -- cancel instead of add). It's still threaded through and returned
  -- (rather than inlining `speed` below) purely so the "R" shortcut has
  -- a per-leg value to flip later.
  local baseSpeed = speed
  local pivotCube_O  = btVector3(O.x - cube.pos.x, O.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O = btVector3(-LEN.m / 2, 0, z_ground_l - z_crank_l)
  local hingeO = hinge(cube.body, crank.body, pivotCube_O, pivotCrank_O, baseSpeed, MOTOR_IMPULSE)

  -- J1: crank is the hub for rodJ and rodK (3 rods meet here)
  local pivotCrank_J1 = btVector3(LEN.m / 2, 0, 0)
  hinge(crank.body, rodJ.body, pivotCrank_J1, btVector3(-LEN.j / 2, 0, z_crank_l - z_rodJ_l))
  hinge(crank.body, rodK.body, pivotCrank_J1, btVector3(-LEN.k / 2, 0, z_crank_l - z_rodK_l))

  -- G: cube is the hub for rodB, rodD, rodC (3 independent rockers sharing
  -- the same frame pivot, exactly like real Jansen legs' shared bolt).
  -- Same z_ground_l "neutral reference" convention as the O hinge above --
  -- each rod's own side must also be offset by z_ground_l - z_rod_l, not
  -- left at 0 (0 would target the ROD's own plane, not z_ground_l, so the
  -- two sides of the hinge would disagree about where the pivot's world Z
  -- actually is).
  local pivotCube_G = btVector3(G.x - cube.pos.x, G.y - cube.pos.y, z_ground_l - cube.pos.z)
  hinge(cube.body, rodB.body, pivotCube_G, btVector3(-LEN.b / 2, 0, z_ground_l - z_rodB_l))
  hinge(cube.body, rodD.body, pivotCube_G, btVector3(-LEN.d / 2, 0, z_ground_l - z_rodD_l))
  hinge(cube.body, rodC.body, pivotCube_G, btVector3(-LEN.c / 2, 0, z_ground_l - z_rodC_l))

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
-- foot: a flat pad welded (not hinged) to rodH at F, extending it in Z
-- for a real contact patch (same weld-via-locked-slider trick as
-- cheby_normal6.lua's buildFoot, simplified since each leg already sits
-- on its own dedicated Z-plane stack -- no inward/outward asymmetry
-- needed the way cheby's shared-centerline feet required).
-- ---------------------------------------------------------------------

function buildFoot(lk, color)
  local F = lk.F
  local z = lk.z_foot
  local foot_x, foot_y, foot_z = 9.0, 1.4, 8.0

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

  local legFront = buildJansenLeg(x_offset, false, phase, SPEED, laneBase)
  local legBack  = buildJansenLeg(x_offset, true, phase, SPEED, laneBase)
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

-- R: reverse the gait cycle direction. Every leg's motion comes from ONE
-- motorized hinge (crank<->cube at O); the other 15 hinges per leg are
-- passive, just following along -- so reversing the gait is as simple as
-- flipping every crank motor's target angular velocity sign. Since the
-- foot traces a CLOSED loop (theta -> theta+2*pi returns to the same
-- pose), running theta backward retraces that exact same loop in reverse,
-- including the flat "stance" portion -- so the foot sweeps the ground in
-- the opposite X direction during stance. In an earlier (spread-along-X)
-- layout this literally walked the cube backward; in this side-by-side
-- layout the cube doesn't travel either direction (see the "HONEST
-- CAVEAT" header note), so what's actually visible here is each foot's
-- stance sweep reversing direction, not a body reversing course. The
-- three pairs' relative phase offsets (0/120/240 degrees, baked in at
-- construction via each crank's initial angle -- see buildJansenLeg) stay
-- staggered the same way under a sign flip, so the continuous-support
-- property survives the reversal too. Each leg's OWN baseSpeed is what
-- gets flipped here (currently always equal to the shared SPEED -- see
-- the "MIRRORED LEGS" header note for why it's still threaded through
-- per-leg rather than inlined), multiplying walkDir onto it.
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
-- static marker on the floor every TRAIL_INTERVAL frames at the cube's
-- current (x,z), to visualize the walker's trajectory over time.
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30
local trail_frame_count = 0

v:preSim(function(N)
  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    local marker = Cube(3.0, 0.2, 3.0, 0)
    marker.col = "red"
    marker.pos = btVector3(cube.pos.x, FLOOR_TOP_Y, cube.pos.z)
    v:add(marker)
  end
end)

-- ---------------------------------------------------------------------
-- camera -- follow the walker's center, same fixed-offset chase style as
-- cheby_normal6.lua, scaled up for Jansen's much larger native units.
-- ---------------------------------------------------------------------

v:postSim(function(N)
  common.setCamera(btVector3(cube.pos.x - 500, cube.pos.y + 200, cube.pos.z + 500),
                    btVector3(cube.pos.x, cube.pos.y - 50, cube.pos.z), 0.5)
end)

common.gravity(-9.8)

-- EOF
