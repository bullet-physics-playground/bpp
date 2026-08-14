--
-- Jansen Walker -- a physically-simulated Theo Jansen ("Strandbeest") leg
-- mechanism, four copies mounted on a shared cube body, built the same way
-- as demo/WyomingWill/cheby_normal6.lua: real Bullet rigid bodies + hinge
-- constraints (one of them motorized), not analytic forward kinematics.
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
-- WHY NO X-MIRRORING: mechanisms.c's own branch signs (-1,-1,+1,-1,+1)
-- were verified crossing-free for THIS specific (unmirrored) leg. A true
-- left/right mirror would flip handedness and could need re-verifying
-- those signs don't reintroduce a crossing -- extra risk not worth taking
-- here. Instead, every leg uses the identical unmirrored geometry, just
-- offset in X by enough to clear the mechanism's own ~122x125-unit
-- footprint (measured by sampling compute(theta) over a full cycle, same
-- technique as cheby_normal6.lua's floor-height derivation) -- so the
-- walker's left and right legs aren't mirror images of each other, just
-- two copies of the same design far enough apart not to collide. Front and
-- back copies mirror in Z exactly like cheby_normal6.lua's back face
-- (every hinge axis is world Z, so flipping the whole staggered Z-plane
-- stack's sign is enough -- no X,Y geometry has to change for that).
--
-- HONEST CAVEAT (stability): CFM softening (see v:setCfm below) was
-- needed just to keep one leg's own closed-loop network from diverging
-- (see the CFM note below for why). It also drifts sideways over a long
-- walk rather than tracking straight, likely compounding from the
-- unmirrored left/right legs noted above.
--
-- SIX LEGS, NOT FOUR: the original 4-leg build (2 rows x front/back,
-- phases 0/180) walked for a while but eventually tipped and fell -- with
-- only two phase groups 180 degrees apart, and each leg's own duty cycle
-- only ~62% of the cycle in ground contact (see linkage.lua's metrics for
-- this same mechanism), there are stretches where neither phase group has
-- solid contact, and the walker is momentarily balanced on very little
-- support. A third row at a THIRD phase (0/120/240 degrees, not 0/180)
-- fills that gap: with duty ~62% and 3 phase groups spread evenly, at
-- least one (usually two) of the three is in stance at any instant, so
-- the cube is never left standing on a near-empty base the way the 2-row
-- version was. Within a row, front and back (the Z-mirrored pair) share
-- the SAME phase -- they move together for left/right symmetry -- while
-- the three rows (spaced along X, the walking direction) are what's
-- staggered for continuous support. Verified: the 4-leg build's standing
-- height held for only ~20 simulated seconds before it sagged into a
-- lower stance; with 6 legs that stretches to ~45 seconds (checked out to
-- 1200 frames / 60s), and it still doesn't collapse further after
-- sagging -- it just keeps walking from the lower stance instead.
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

local ROD_W, ROD_D = 1.8, 0.8   -- rod cross-section (Z-thickness ROD_D must stay
                                 -- under plane_gap below, or adjacent Z-planes'
                                 -- rods would overlap and collide)
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
-- Z-plane stack -- one plane per rod, staggered out from the cube's own
-- face so the 11 rotating rods never collide with each other or the cube
-- (same technique as cheby_normal6.lua's z_ground/z_crank/z_coupler/...).
-- ---------------------------------------------------------------------

local plane_gap = 1.2   -- > ROD_D, so adjacent planes' rod boxes never touch
local cube_d = 50.0     -- cube's own Z-depth

local z_ground = cube_d / 2   -- reference only (cube's own surface) -- not a rod
local z_crank  = z_ground + 1  * plane_gap
local z_rodJ   = z_ground + 2  * plane_gap
local z_rodB   = z_ground + 3  * plane_gap
local z_rodE   = z_ground + 4  * plane_gap
local z_rodD   = z_ground + 5  * plane_gap
local z_rodK   = z_ground + 6  * plane_gap
local z_rodC   = z_ground + 7  * plane_gap
local z_rodF   = z_ground + 8  * plane_gap
local z_rodG   = z_ground + 9  * plane_gap
local z_rodI   = z_ground + 10 * plane_gap
local z_rodH   = z_ground + 11 * plane_gap

-- ---------------------------------------------------------------------
-- cube body + floor
--
-- O_ABOVE_CUBE / JANSEN_YMIN / FOOT_CLEARANCE below were derived the same
-- way as cheby_normal6.lua's floor_top_y: sampling compute(theta) over a
-- full crank rotation. JANSEN_YMIN=-91.83 is foot F's lowest point
-- relative to O (measured numerically -- see the header note on why no
-- mirroring is needed; the same sweep also gives the leg's full footprint,
-- x in [-107.17,15.00] y in [-91.83,33.70] relative to O, which sets
-- ROW_SPACING below).
-- ---------------------------------------------------------------------

local ROW_SPACING = 220    -- > leg's own ~122-unit X footprint, so consecutive
                            -- rows (all unmirrored, see header) never overlap
local NUM_ROWS    = 3      -- 3 rows x front/back = 6 legs -- see the "SIX LEGS"
                            -- header note for why 3, not 2
local CUBE_MARGIN = 60
local CUBE_W        = (NUM_ROWS - 1) * ROW_SPACING + 2 * CUBE_MARGIN
local CUBE_H         = 10.0
local CUBE_CENTER_X  = (NUM_ROWS - 1) * ROW_SPACING / 2   -- middle row's X

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
cube = Cube(CUBE_W, CUBE_H, cube_d, 220.0)
cube.col = "#29c235"
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
-- one full Jansen leg: 11 rods + 16 hinges (1 motorized), mounted at
-- world X = x_offset, with O at world Y = O_MOUNT_Y. mirror flips the
-- whole Z-plane stack's sign (back face); phase (degrees) offsets the
-- crank's initial angle, same role as cheby_normal6.lua's buildLinkage
-- `phase` argument.
-- ---------------------------------------------------------------------

function buildJansenLeg(x_offset, mirror, phase, speed)
  local zSign = mirror and -1 or 1
  local z_ground_l = zSign * z_ground
  local z_crank_l  = zSign * z_crank
  local z_rodJ_l   = zSign * z_rodJ
  local z_rodB_l   = zSign * z_rodB
  local z_rodE_l   = zSign * z_rodE
  local z_rodD_l   = zSign * z_rodD
  local z_rodK_l   = zSign * z_rodK
  local z_rodC_l   = zSign * z_rodC
  local z_rodF_l   = zSign * z_rodF
  local z_rodG_l   = zSign * z_rodG
  local z_rodI_l   = zSign * z_rodI
  local z_rodH_l   = zSign * z_rodH

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

  local crank = makeLink(O, J1, z_crank_l, "coral")
  local rodJ  = makeLink(J1, J2, z_rodJ_l, "teal")
  local rodB  = makeLink(G, J2, z_rodB_l, "purple")
  local rodE  = makeLink(J2, J3, z_rodE_l, "goldenrod")
  local rodD  = makeLink(G, J3, z_rodD_l, "purple")
  local rodK  = makeLink(J1, J4, z_rodK_l, "teal")
  local rodC  = makeLink(G, J4, z_rodC_l, "purple")
  local rodF  = makeLink(J3, J5, z_rodF_l, "goldenrod")
  local rodG  = makeLink(J4, J5, z_rodG_l, "steelblue")
  local rodI  = makeLink(J4, F, z_rodI_l, "orangered")
  local rodH  = makeLink(J5, F, z_rodH_l, "orangered")

  local MOTOR_SPEED = speed
  local MOTOR_IMPULSE = 3000.0

  -- O: cube (ground) <-> crank -- the one driven joint. Both pivot sides
  -- are expressed relative to z_ground_l (the cube's own surface plane,
  -- not either body's resting plane) -- same "neutral third reference"
  -- convention as cheby_normal6.lua's pivotCube_O2/pivotCrank_O2, so the
  -- two sides' world Z actually agree instead of fighting each other.
  local pivotCube_O  = btVector3(O.x - cube.pos.x, O.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O = btVector3(-LEN.m / 2, 0, z_ground_l - z_crank_l)
  hinge(cube.body, crank.body, pivotCube_O, pivotCrank_O, MOTOR_SPEED, MOTOR_IMPULSE)

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
    footRod = rodH, z_foot = z_rodH_l, F = F,
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
-- six legs: NUM_ROWS rows along X (the walking direction) x front/back
-- (Z-mirrored). Front and back within a row share the same phase (they
-- move together, for left/right symmetry); rows are staggered 360/NUM_ROWS
-- degrees apart -- see the "SIX LEGS" header note for why this beats the
-- original 2-row/0-180-degree scheme for stability.
-- ---------------------------------------------------------------------

local SPEED = 0.5

legs, feet = {}, {}
for row = 0, NUM_ROWS - 1 do
  local x_offset = row * ROW_SPACING
  local phase = row * (360.0 / NUM_ROWS)

  local legFront = buildJansenLeg(x_offset, false, phase, SPEED)
  local legBack  = buildJansenLeg(x_offset, true, phase, SPEED)
  table.insert(legs, legFront)
  table.insert(legs, legBack)

  table.insert(feet, buildFoot(legFront, "yellow"))
  table.insert(feet, buildFoot(legBack, "blue"))
end

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
