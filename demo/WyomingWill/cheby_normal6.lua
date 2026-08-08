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

local common = require "common"

common.setTiming(1/10, 20, 1/480)

-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------

local g_len, a_len, f_len, h_len, p_len = 2.5, 1.0, 5.0, 2.5, 10.0
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.4                     -- spacing between staggered planes
local cube_d = 2.5--5.0                        -- cube's own depth (Z) -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically

local z_ground, z_crank, z_coupler, z_rocker, z_pendant, z_crossbar =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap, cube_d/2 + 5*plane_gap

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
function makeLink(p1, p2, z, mass, color)
  local len = math.sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2)
  local mid = midpoint(p1, p2)
  local q = zrotVec(p2.x - p1.x, p2.y - p1.y)
  local obj = Cube(len, rod_w, rod_d, mass)
  obj.col = color
  obj.trans = btTransform(q, btVector3(mid.x, mid.y, z))
  obj.friction = 0.5
  v:add(obj)
  return obj
end

-- ---------------------------------------------------------------------
-- ground: one wide cube shared by both linkages. Wide enough to carry
-- both g-mountings (10 units apart) plus a margin on each outer side.
-- ---------------------------------------------------------------------

local linkage_spacing = 10
local cube_margin = 2.5
local cube_w = linkage_spacing + 2*cube_margin   -- 15
local cube_center_x = linkage_spacing / 2         -- 5, midway between the two

cube = Cube(cube_w, 1.5, cube_d, 10.0)   -- small mass -> now dynamic, affected by gravity
cube.col = "#29c235"
cube.pos = btVector3(cube_center_x, 0, 0)
cube.friction = 0.5
v:add(cube)

-- ---------------------------------------------------------------------
-- floor: static, placed just below the lowest point any foot reaches
-- over a full crank rotation. Checked numerically (same kind of sweep
-- as the earlier clearance check) -- every linkage cycles through the
-- same B.y range regardless of its phase offset, and the lowest point
-- across that whole range is about y=-5.33 (foot's bottom surface).
-- The floor's top sits at -5.4, a small margin below that, so nothing
-- starts out already penetrating it.
-- ---------------------------------------------------------------------

local floor_top_y = -5.4
local floor_w, floor_th, floor_d = 300, 1.0, 300

floor = Cube(floor_w, floor_th, floor_d, 0)   -- mass 0 -> static
floor.col = "#694811"
floor.pos = btVector3(cube_center_x, floor_top_y - floor_th/2, 0)
floor.friction = 0.8
v:add(floor)

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

  local g_center = { x = x_offset, y = 1.25 }
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

  local crank   = makeLink(O2, A, z_crank_l, 0.3, "coral")
  local coupler = makeLink(A, B, z_coupler_l, 0.6, "teal")
  local rocker  = makeLink(M, O4, z_rocker_l, 0.3, "purple")
  local pendant = makeLink(B, C, z_pendant_l, 1.0, "goldenrod")
  pendant.damp_ang = 0.00--0.15   -- bleeds off some oscillation energy -- helps at higher speeds, raise if it still overshoots

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank
  local pivotCube_O2  = btVector3(O2.x - cube.pos.x, O2.y - cube.pos.y, z_ground_l - cube.pos.z)
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  hingeO2:enableAngularMotor(true, speed, 8.0)   -- this is the driven joint -- raise the 3rd arg (maxMotorImpulse) further if you raise the 2nd (target speed)
  v:addConstraint(hingeO2)

  -- A: crank <-> coupler
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-f_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  v:addConstraint(hingeA)

  -- M: coupler <-> rocker (M is the coupler's own center, so its local pivot is 0,0,0)
  local pivotCoupler_M = btVector3(0, 0, 0)
  local pivotRocker_M  = btVector3(-h_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeM = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_M, pivotRocker_M, axis, axis)
  v:addConstraint(hingeM)

  -- O4: rocker <-> cube (this is the pin that has to bridge all three planes)
  local pivotRocker_O4 = btVector3(h_len/2, 0, z_ground_l - z_rocker_l)
  local pivotCube_O4   = btVector3(O4.x - cube.pos.x, O4.y - cube.pos.y, z_ground_l - cube.pos.z)
  local hingeO4 = btHingeConstraint(rocker.body, cube.body, pivotRocker_O4, pivotCube_O4, axis, axis)
  v:addConstraint(hingeO4)

  -- B: coupler <-> pendant (free hinge, no motor -- it just swings)
  local pivotCoupler_B = btVector3(f_len/2, 0, 0)
  local pivotPendant_B = btVector3(-p_len/2, 0, z_coupler_l - z_pendant_l)
  local hingeB = btHingeConstraint(coupler.body, pendant.body, pivotCoupler_B, pivotPendant_B, axis, axis)
  v:addConstraint(hingeB)

  return {
    crank = crank, coupler = coupler, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeM = hingeM, hingeO4 = hingeO4, hingeB = hingeB,
    z_pendant = z_pendant_l, C = C,
  }
end

linkage1 = buildLinkage(0, 0, false, 0, 2.6)                 -- front face, x=0,  phase 
linkage2 = buildLinkage(linkage_spacing, 0, false, 0, 2.6)    -- front face, x=10, phase 0
linkage3 = buildLinkage(0, 0, true, 180, 2.6)                  -- back face,  x=0,  phase 90
linkage4 = buildLinkage(linkage_spacing, 0, true, 180, 2.6)    -- back face,  x=10, phase 90

-- ---------------------------------------------------------------------
-- crossbar builder: joins the pendant midpoints of two linkages that
-- are identical and driven identically (so their pendants always stay
-- a fixed distance apart with zero relative rotation -- see header).
-- z_pos is the crossbar's own Z-plane; sign matches which face it's on.
-- attach_height raises (positive) or lowers (negative) the bar above
-- the pendant's own Y position -- 0 reproduces the original behavior
-- exactly. Since the bar is built unrotated (identity), this is a
-- plain Y-offset, no rotation bookkeeping needed: the weld frame just
-- needs to reach back DOWN by attach_height to find the pendant's
-- actual (unmoved) position.
-- ---------------------------------------------------------------------

function buildCrossbar(lkA, lkB, z_pos, color, attach_height)
  --attach_height = attach_height or 0
  attach_height = attach_height or 4.5
  local PA, PB = lkA.pendant.pos, lkB.pendant.pos
  local len = math.sqrt((PB.x-PA.x)^2 + (PB.y-PA.y)^2)   -- should equal linkage_spacing, by symmetry
  local mid_x = (PA.x + PB.x) / 2

  local bar = Cube(len, rod_w, rod_d, 1.0)
  bar.col = color
  bar.trans = btTransform(IDENTITY_QUAT, btVector3(mid_x, PA.y + attach_height, z_pos))
  bar.damp_ang = 0.15
  v:add(bar)

  -- both pendants in a pair share the same orientation at construction
  -- (same geometry, just translated), so this one quaternion is the
  -- correct weld-frame rotation for both ends.
  local pendant_quat = lkA.pendant.trans:getRotation()

  local frameInBar_A = btTransform(pendant_quat, btVector3(-len/2, -attach_height, lkA.z_pendant - z_pos))
  local frameInA      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldA = btSliderConstraint(bar.body, lkA.pendant.body, frameInBar_A, frameInA, true)
  weldA:setLowerLinLimit(0)   -- btSliderConstraint defaults to FREE translation unless set --
  weldA:setUpperLinLimit(0)   -- these two calls are what actually makes this a rigid weld
  v:addConstraint(weldA)

  local frameInBar_B = btTransform(pendant_quat, btVector3(len/2, -attach_height, lkB.z_pendant - z_pos))
  local frameInB      = btTransform(IDENTITY_QUAT, btVector3(0, 0, 0))
  local weldB = btSliderConstraint(bar.body, lkB.pendant.body, frameInBar_B, frameInB, true)
  weldB:setLowerLinLimit(0)
  weldB:setUpperLinLimit(0)
  v:addConstraint(weldB)

  return bar
end

crossbarFront = buildCrossbar(linkage1, linkage2, z_crossbar, "slateblue", -4.5)
crossbarBack  = buildCrossbar(linkage3, linkage4, -z_crossbar, "slateblue", -4.5)

crossbarFront2 = buildCrossbar(linkage1, linkage2, z_crossbar, "slateblue", 4.5)
crossbarBack2  = buildCrossbar(linkage3, linkage4, -z_crossbar, "slateblue", 4.5)

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
  local outward_extra = 2.0            -- how far the foot reaches PAST the pendant, away from the body
  local inner_gap = -1.0--0.3                -- stops short of z=0 by this much, so opposing feet don't touch at the center

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 2.0, 0.3      -- wide (x) and flat (y) -- much wider than the 0.18 pendant rod

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.2)   -- heavier than before (was 0.5)
  foot.col = color
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  v:add(foot)

  local pendant_quat = lk.pendant.trans:getRotation()
  -- the pendant attaches at z=zp, which is now partway along the foot's
  -- length (not at its end), since the foot extends past it on both sides
  local frameInFoot    = btTransform(pendant_quat, btVector3(0, 0, zp - foot_center_z))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(p_len/2, 0, 0))   -- C is the pendant's own "+X end"
  local weld = btSliderConstraint(foot.body, lk.pendant.body, frameInFoot, frameInPendant, true)
  weld:setLowerLinLimit(0)   -- see the earlier note: slider defaults to FREE translation unless locked
  weld:setUpperLinLimit(0)
  v:addConstraint(weld)

  return foot
end

foot1 = buildFoot(linkage1, "yellow")
foot2 = buildFoot(linkage2, "yellow")
foot3 = buildFoot(linkage3, "blue")
foot4 = buildFoot(linkage4, "blue")

-- ---------------------------------------------------------------------
-- CENTROID TRAIL: drops a small marker on the floor every
-- TRAIL_INTERVAL frames at the mechanism's current (x,z) position, to
-- visualize its trajectory over time (turning, drifting, straight-line
-- travel, etc.).
--
-- Uses the CUBE's position as a practical stand-in for the true mass-
-- weighted centroid, rather than summing every body in the mechanism
-- every frame -- the cube alone is close to half the total mass, so
-- its path should closely track the true centroid's shape without
-- that bookkeeping.
--
-- Markers are static (mass 0) AND mostly buried in the floor -- only
-- about 0.02 units poke above the surface, thin enough that a foot
-- crossing one shouldn't meaningfully disturb the walk. (Originally
-- tried setCollisionFlags(4) for CF_NO_CONTACT_RESPONSE to make them
-- fully non-colliding, but this binding only exposes a getter-style
-- setCollisionFlags with no way to pass a value -- confirmed by the
-- runtime error, not a guess. Burying them is a lower-risk fix that
-- doesn't depend on an uncertain API.)
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30   -- frames between markers (0.5s at 60fps) -- lower = finer trail, more markers over a long run
local trail_frame_count = 0

v:preSim(function(N)
  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    local marker = Cube(1.0, 0.05, 1.0, 0)   -- static, thin
    marker.col = "red"
    marker.pos = btVector3(cube.pos.x, floor_top_y, cube.pos.z)   -- centered AT floor surface -- half buried, ~0.02 protrusion
    v:add(marker)
  end
end)

-- ---------------------------------------------------------------------
-- camera -- follow the walker's center: look target and camera position
-- both track the cube body's current position (cube.pos -- the same
-- stand-in for the true mass-weighted centroid used by the trail
-- markers), keeping the walker framed as it walks. The camera keeps its
-- fixed offset (-120*CAM_SCALE, 0, +120*CAM_SCALE) relative to the
-- walker's center, and the distance scales with cube_w so it stays
-- correctly framed if linkage_spacing changes. 15 is the reference
-- cube_w at the current linkage_spacing=10 (cube_w = linkage_spacing +
-- 2*cube_margin = 15).
-- ---------------------------------------------------------------------

v:postSim(function(N)
  local CAM_SCALE = cube_w / 15

  common.setCamera(btVector3(cube.pos.x - 120*CAM_SCALE, cube.pos.y, cube.pos.z + 120*CAM_SCALE),
                   btVector3(cube.pos.x, cube.pos.y, cube.pos.z), 0.15)
end)

common.gravity(-9.8)