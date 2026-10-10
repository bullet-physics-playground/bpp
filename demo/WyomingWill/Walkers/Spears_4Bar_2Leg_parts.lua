--
-- Not a scene: run on its own, this file builds nothing. To see the
-- walker, open Spears_4Bar_2LegT.lua.
--
-- Spears 4-bar walker (two legs) walker, the mechanism: the cube body, its legs, and everything
-- welded or hinged to them, as a function. Spears_4Bar_2LegT.lua calls it
-- to build the walker on its own terrain; a room can call it to build
-- the same walker beside others. Nothing here sets the physics
-- settings, gravity, terrain, sliders or camera: the caller does. Every
-- name here is local, so walkers built side by side don't share globals.
--
--   local Walker = dofile("Spears_4Bar_2Leg_parts.lua")
--   local w = Walker.build{
--     add = function(obj) ... end,          -- adds a body to the world
--     addConstraint = function(con) ... end,
--     terrainLift = ...,  -- how far the ground can rise above Walker.FLOOR_TOP_Y
--     cube_d = ..., cubeMass = ...,                          -- the sliders
--     speed = ...,   -- the Speed slider
--   }
--   w.cube, w.cube_w, w.cubeCenterX, w.linkage1, w.linkage3 (each with
--   .hingeO2, the motor), w.foot1, w.foot3
--
-- The notes below were written when all of this lived in
-- Spears_4Bar_2LegT.lua; "this file" in them means the walker as a whole.
--
-- Sept 22, 2026, by William M. Spears
-- (Hoecken-Spears slider -> Spears 4Bar-1 linkage swap ported by Claude)

-- This is a simulation of a walker driven by "Spears 4Bar-1" --
-- linkage.lua's compute_spears4bar1 (crank=36, ground=223.659 @54.459deg,
-- rocker=121.37, coupler=138.789, leg=181.45 @-102.27deg from the
-- coupler, attached 25% of the way from the coupler's B end toward A)
-- -- CONVERTED from an earlier version of this file that used the
-- Hoecken SLIDER mechanism (a crank driving a bar through a fixed
-- slider pivot, no rocker at all) instead. THIS IS A GENUINELY
-- DIFFERENT TOPOLOGY, not just different proportions of the same shape:
-- Spears 4Bar-1 is a true CLOSED four-bar loop (crank O2->A, coupler
-- A->B, rocker B->O4, ground O4->O2, exactly like the classical
-- Chebyshev/Hoecken 4-bar walkers earlier in this file series), with a
-- LEG-ARM rigidly welded (not hinged) to the coupler at a fixed point
-- and a fixed angle -- there's no free-hinged pendant anywhere in this
-- version, and consequently no crossbar either (see the LEG WELD and
-- NO CROSSBARS notes further down). Ported from Chebyshev's Plantigrade
-- Machine (shown at the 1878 Paris World Exhibition) that this file was
-- originally built around. Claude wrote most of the original Chebyshev
-- code under Bill Spears's guidance -- this was not a simple process.
-- Top-down approaches failed miserably; the machine had to be built
-- component by component, and even after it started to move it took
-- hours to tweak the parameters. I want to thank Jakob Flierl for
-- providing the very nice mesh floor, which makes this much more
-- interesting.
--
-- MODEL S4B1 (branched from Model H): four copies of the same Spears
-- 4Bar-1 linkage -- the original two on the front face, plus a mirrored
-- pair on the back face. Each leg's phase is now an independently
-- optimized value (0, 225, 180, 225 -- see the PHASE OPTIMIZED PER LEG
-- note above the linkage1-4 calls for the full derivation), not the
-- simple "front pair together, back pair 180 degrees opposite" pattern
-- every earlier version of this file used.
--
-- SPEARS 4BAR-1 CONVERSION, precisely: linkage.lua's own Spears 4Bar-1
-- entry uses genuinely different absolute lengths (and a genuinely
-- different TOPOLOGY, not just different proportions) than the previous
-- slider mechanism did --
--   crank=36  ground=223.659 @54.459deg  rocker=121.37  coupler=138.789
--   leg=181.45 @-102.27deg from the coupler's own current direction,
--   attached 25% of the way from B toward A along the coupler (not at
--   either end, and not the midpoint either).
-- RENORMALIZED here to the SAME running stride baseline this whole file
-- series has used throughout (8.323638, the original 1867 Hoecken
-- slider's own stride at crank=1): k=0.08087749, solved numerically so
-- Spears 4Bar-1's own swept foot X-span exactly matches that target
-- (verified to 6 decimal places: 8.323638 both ways, computed via
-- linkage.lua's own compute_spears4bar1 formula, sweeping a full
-- 2000-sample crank rotation). ALL FIVE lengths (crank, ground, rocker,
-- coupler, leg) are scaled by that same k -- ground_angle=54.459 and
-- leg_angle=-102.27 are NOT rescaled (they're angles, not lengths --
-- genuinely part of "which mechanism this is"), and attach_frac=0.25
-- isn't rescaled either (it's already a pure, scale-invariant fraction).
--
-- Ground link  g = 18.088979  -- O2 (crank pivot) -> O4 (rocker pivot), at g_ang=54.459deg
-- Crank        a = 2.911590   -- O2 -> A
-- Coupler      f = 11.224906  -- A -> B (called coupler_len in this file, not f_len -- see the constants section)
-- Rocker       h = 9.816101   -- O4 -> B (rocker_len)
-- Leg-arm      p = 14.675221  -- attach -> C, rigidly WELDED (not hinged) to the coupler at ATTACH_FRAC=0.25 of the way from B to A, at a fixed LEG_ANGLE_DEG=-102.27 offset from the coupler's own current direction ("p_len" keeps its old variable name purely so buildFoot's existing p_len/2 reference still resolves -- see the constants section)
--
-- Both g_len and a_len (ground, crank) are exactly as renormalized
-- above -- unlike the previous slider version, this mechanism genuinely
-- needs BOTH fixed pivots (O2 for the crank, O4 for the rocker), closed
-- by a real hinge at B, not a slider joint threaded through a floating
-- point.
--
-- LEG WELD, precisely: compute_spears4bar1's own formula rotates the
-- leg-arm by exactly LEG_ANGLE_DEG relative to the COUPLER's CURRENT
-- direction (not a fixed world direction) -- so the coupler-to-leg
-- angular relationship is a genuine invariant of the ENTIRE gait cycle,
-- true for every crank angle, not just a snapshot at construction time.
-- That means welding the leg-arm to the coupler (translation AND
-- rotation both locked, matched orientation at build time) reproduces
-- the analytic formula EXACTLY for all subsequent motion, not just
-- approximately -- see buildLinkage's own LEG WELD comment for the full
-- derivation of the weld frames that make this work.
--
-- NO CROSSBARS: linkage.lua's own MECHANISMS table marks Spears 4Bar-1
-- as twin=false (unlike Chebyshev-Spears and Hoeckens-Spears, both
-- twin=true) -- it was never a paired/crank-shared design needing a
-- crossbar in the first place, and since the leg-arm here is already
-- rigidly welded to its own coupler (no free rotational DOF at the foot
-- end at all), there's nothing left for a crossbar to stabilize even if
-- one were added. Removed entirely from this version, per request.
--
-- STARTING-HEIGHT / FLOOR: Spears 4Bar-1's own geometry reaches much
-- further down on its own than the slider mechanism's B point did (no
-- separate long pendant needed to reach the ground -- the leg-arm IS
-- the ground-reaching member here). Checked numerically (this file's
-- own buildLinkage formula, g_ang=54.459, full crank sweep): the foot
-- (C) ranges roughly Y in [-16.45, -13.35] in this file's own world
-- coordinates (g_center.y=1.25 baseline) -- floor_top_y was moved from
-- the previous version's -5.7 down to -16.7 to sit just below that new
-- low point (a margin of roughly 0.25, after accounting for the foot
-- pad's own 0.15 half-thickness below C) -- see the floor-section note
-- further down for the exact derivation. This is NOT re-derived from
-- p_len/leg length automatically (same "fixed literal, not a live
-- formula" convention the previous version used) -- if leg proportions
-- change again, floor_top_y needs to be re-checked/re-moved by hand.
--
-- Each link lives on its own Z-plane (0.4 units apart) out from the
-- cube face so the rotating parts never collide with each other or with
-- the cube -- all four (crank, coupler, rocker, leg-arm) get their own
-- plane in this version, no sharing assumed (see the z-plane comment
-- above buildScene() for why). All hinge axes are world Z, so every
-- link only ever rotates about Z -- which means each link's local
-- pivot points are simply (+-L/2, 0, z_offset) in its own frame, no
-- trig needed at hinge time.
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
-- LEG WELD (replaces the old CROSSBAR note): the leg-arm is rigidly
-- welded, not hinged, to the coupler at a fixed angle and a fixed point
-- partway along its length (ATTACH_FRAC) -- see buildLinkage's own LEG
-- WELD comment for the full derivation. Since there's no free-swinging
-- pendant DOF at all in this mechanism (unlike every Hoecken-family
-- version in this file series), there's also nothing for a crossbar to
-- stabilize -- Spears 4Bar-1 is twin=false in linkage.lua's own
-- MECHANISMS table, meaning it was never a paired/crank-shared design
-- to begin with. No crossbars are built in this version.
--
-- IMPORTANT: btSliderConstraint does NOT lock translation by default --
-- its stock constructor leaves the linear range free (lower=1 > upper=
-- -1, Bullet's "free" convention) and only locks rotation. A "weld"
-- needs setLowerLinLimit(0)/setUpperLinLimit(0) explicitly, or the
-- welded body can just slide off along the constraint's own axis.
--
-- Building one linkage (crank, coupler, rocker, and its welded leg-arm)
-- is wrapped in buildLinkage(...), so the back pair is just two more
-- calls with mirror=true.
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
-- MASS RATIOS / WOBBLE: cube mass is now 20.0 (see the CUBE MASS
-- OPTIMIZED note above setParam("cubeMass", ...) for the real-physics-
-- trial derivation) -- previously 100.0. Leg bodies are crank 2.0,
-- coupler 4.0, rocker 3.0, leg-arm 3.0, carried over unmodified from
-- the previous (slider) version of this file, which itself raised
-- these from even smaller originals specifically to bring an iterative-
-- solver-unfriendly mass ratio down to something more tractable (see
-- that version's own history for the reasoning). With the cube now
-- lighter, the ratio against leg masses is correspondingly smaller too
-- (5:1 to 10:1, not the 25:1-50:1 it would have been at the old
-- mass=100) -- likely a further help for solver stability, though not
-- independently re-verified as such; the optimization above was scored
-- purely on net displacement, not on any wobble/jitter metric.
-- maxMotorImpulse at O2 is also carried over unmodified (150.0) -- NOT
-- independently re-verified for this new topology's own load pattern
-- (a driven crank in a closed 4-bar loop with a genuinely hinged rocker
-- is mechanically different from a crank dragging a bar through a
-- floating slider point was). Not verified against a live physics run
-- beyond the mass sweep itself -- these are the standard levers for
-- this class of problem, carried over as a reasonable starting point,
-- not a confirmed diagnosis for this specific mechanism.
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
-- load. The width bumps below (crank 0.18->0.3, coupler/rocker/leg-arm
-- 0.18->1.0-1.2) are carried over from the previous (slider) version of
-- this file, where they were checked numerically against THAT
-- mechanism's own lengths (crank=1.0, bar=10.0, pendant=14.0) -- NOT
-- re-derived for Spears 4Bar-1's own renormalized lengths (crank=2.91,
-- coupler=11.22, rocker=9.82, leg=14.68) or for the rocker itself (a
-- body type that didn't exist in the slider version at all, given the
-- same 1.0 width as the leg-arm/coupler here purely by similarity of
-- magnitude, not by calculation). Depth (rod_d) is left untouched
-- throughout -- that's the dimension that eats into plane_gap clearance
-- between stacked Z-planes, so only width (which stays within the
-- rod's own Z-plane) was grown. The previous version's own "clears the
-- O4 block by 0.6 units" clearance check no longer applies at all --
-- there's no block anymore, only a genuinely hinged rocker -- so this
-- hasn't been re-checked for the new topology's own geometry, flagged
-- rather than assumed.
--


local M = {}

local add, addConstraint   -- set by M.build from its caller's opts

local g_len, a_len, coupler_len, rocker_len, p_len = 18.088979, 2.911590, 11.224906, 9.816101, 14.675221   -- Spears 4Bar-1 ratio (crank:ground:rocker:coupler:leg = 36:223.659:121.37:138.789:181.45) scaled by k=0.08087749 for equal stride to the running baseline (8.323638, the original a=1,g=2,L=10 Hoecken slider's own stride) -- see the SPEARS 4BAR-1 CONVERSION header note for the full derivation. "p_len" keeps its name (not renamed to leg_len) purely so buildFoot's existing p_len/2 reference below still resolves correctly -- it's the LEG's length now, not a hanging pendant's.
local rod_w, rod_d = 0.18, 0.18          -- rod cross-section
local plane_gap = 0.8--0.4                     -- spacing between staggered planes

-- No plane-sharing in this version: crank, coupler, rocker, and the
-- leg-arm each get their own dedicated Z-plane (see the z-plane comment
-- above buildScene() for why -- the crank/rocker-share-a-plane
-- optimization used elsewhere in this file series was never verified
-- for THIS mechanism's own proportions, so it isn't assumed here).
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
  width = width or rod_w
  depth = depth or rod_d
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


M.FLOOR_TOP_Y = -16.7   -- Spears 4Bar-1's own leg reaches roughly Y in [-16.45,-13.35] on its own (no separate long pendant needed) -- see the STARTING-HEIGHT / FLOOR header note and the floor-section note above buildScene() for the full derivation  -- (the floor's baseline height for this mechanism -- Spears_4Bar_2LegT.lua's floor reads it)

function M.build(opts)
add, addConstraint = opts.add, opts.addConstraint
local cube_d = opts.cube_d       -- cube's own depth (Z) -- GUI slider -- z_ground below derives from this, so changing cube_d keeps every linkage plane aligned with the cube's actual face automatically
local cube_margin = 2.5
-- TWO-LEGGED: only one leg column remains (x=0, linkage1/linkage3 --
-- see the TWO-LEGGED CONVERSION header note), so cube_w no longer
-- spans between two mounts -- it's now just enough width to carry the
-- single mount plus margin on each side.
local cube_w = 2 * cube_margin   -- returned: Spears_4Bar_2LegT.lua's one-time camera setup reads it
-- CENTER OF MASS FIX, per direct diagnosis: cube_center_x=0 (centered
-- geometrically ON the leg mount) looked reasonable but was WRONG --
-- direct measurement (summing mass*position across cube + both legs'
-- bodies + feet) showed the COMBINED center of mass sits substantially
-- offset from the cube's own geometric center, and the offset GROWS
-- over the gait cycle (0.49 units at frame 20, growing to 1.34+ by
-- frame 180) -- exactly the "tips forward and down" symptom described.
-- Root cause: O2 (the crank pivot, where the whole leg assembly
-- anchors) sits at g_center - (g_len/2)*(cos g_ang, sin g_ang) --
-- roughly 5.26 units offset from cube_center_x on its own, before any
-- dynamic leg motion is even considered -- and the leg assembly's own
-- mass (crank+coupler+rocker+leg-arm+foot, ~13.5 per leg, 27 total
-- across both) is substantial relative to the cube (65), so that
-- anchor offset really does drag the combined CoM off-center.
-- Swept cube_center_x directly against real physics trials (400-frame,
-- forced-rebuild, tracking net displacement AND cube.trans's own Z
-- rotation as the tipping signature) -- this is NOT a small correction:
-- 0 through 5 (in the direction that seemed like it should compensate)
-- made qz WORSE, not better (up to 0.736) -- the sign was backwards
-- from the naive expectation. Reversing direction, 6 was dramatic:
-- qz collapsed to -0.285 (vs 0.602 at cube_center_x=0), cube.pos.y
-- stayed positive instead of sinking (0.81 vs -3.89), and net
-- displacement over 400 frames went from 40.78 to 265.98 -- by far the
-- single largest improvement found anywhere in this whole two-legged
-- investigation, well past what foot size or phase tuning achieved on
-- their own.
--
-- CORRECTION, from a longer test: the 1500-frame check that originally
-- validated this as "still making real progress the whole way through"
-- wasn't long enough. A proper 1600-frame monitor (direct request:
-- "I see the green body cube tilt backwards slowly as the walker goes
-- forward... monitor that") shows the tilt isn't eliminated, only
-- delayed and reduced -- cube.trans's own Z-rotation grows steadily
-- from -4.6 degrees at frame 100 to -101 degrees by frame 700-800, THEN
-- STABILIZES there (not unbounded -- same "settles into an equilibrium"
-- character the earlier diagnosis found, just at a far larger angle
-- than that first pass caught). Once settled, forward progress
-- essentially stalls (roughly 17 more units gained over the next 900
-- frames) and cube.pos.y sinks to about -14.
--
-- Re-swept BOTH cube_center_x (5.5 through 10) and foot area (35
-- through 150) over this same full 1600-frame horizon looking for a
-- value that avoids the eventual tilt entirely -- none did. Every
-- cube_center_x tested still tips 87-134 degrees by frame 1600; every
-- foot area tested (holding cube_center_x=6) still tips 129-134
-- degrees. cube_center_x=6 remains clearly the BEST of everything
-- tried -- by a wide margin, it maximizes how much real progress
-- happens before the eventual settle (roughly 500-517 units, vs 14-360
-- for every other value tested) -- but it delays and reduces the
-- problem rather than eliminating it. This now reads as a genuine
-- structural characteristic of a front-back-only two-leg layout, not a
-- tunable-parameter bug -- consistent with the earlier TWO-LEGGED
-- CONVERSION note's own speculation that this configuration may be
-- inherently less stable than a left-right leg pair would have been,
-- now with much stronger long-horizon evidence behind it. A genuinely
-- complete fix likely needs the kind of structural intervention that
-- note already flagged (revisiting the phase relationship at a deeper
-- level, or a different leg arrangement entirely) rather than further
-- parameter search within this layout.
local cube_center_x = 6   -- returned (the floor is centred on it) -- see CENTER OF MASS FIX + its CORRECTION above -- best found, not a full fix
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
-- Spears_4Bar_2LegT.lua.
local terrain_lift = opts.terrainLift

-- Five distinct planes now: ground/crank/coupler/rocker/leg (no
-- crossbar plane -- Spears 4Bar-1 is twin=false, no crossbar needed at
-- all, see the SPEARS 4BAR-1 CONVERSION note). Unlike the crank/rocker
-- plane-sharing optimization used elsewhere in this file series, each
-- link here gets its OWN plane -- this is a genuinely different
-- mechanism with different proportions, and that clearance property
-- was never re-verified for it, so this is the safe default rather
-- than an assumed carry-over.
local z_ground, z_crank, z_coupler, z_rocker, z_pendant =
      cube_d/2, cube_d/2 + plane_gap, cube_d/2 + 2*plane_gap, cube_d/2 + 3*plane_gap, cube_d/2 + 4*plane_gap

--cube = Cube(cube_w, 1.5, cube_d, 100.0)   -- small mass -> now dynamic, affected by gravity
local cube = Cube(cube_w, 1.5, cube_d, opts.cubeMass)   -- GUI slider -- small mass -> now dynamic, affected by gravity
cube.col = "#29c235"
-- PRE-ROTATION, per direct request, following up on the CENTER OF MASS
-- FIX's own CORRECTION note above: since the cube's own rotation
-- settles into an equilibrium (roughly -101 degrees from a 0-degree
-- start, over about 700 frames) rather than growing unboundedly,
-- starting the whole mechanism ALREADY at (or near) that equilibrium
-- should skip the costly drift-and-stall transient. Implemented via
-- cube.trans:invXform(worldPoint) for the hinge pivot vectors below
-- (pivotCube_O2/pivotCube_O4) -- CANNOT just rotate cube.trans's
-- rotation alone: those pivots used to be computed as plain WORLD-frame
-- displacements (worldPoint - cube.pos), which only equals the LOCAL-
-- frame offset btHingeConstraint actually expects when the cube's own
-- rotation is identity. invXform correctly converts a world point into
-- the cube's own (now rotated) local frame, verified directly against
-- a known displacement before trusting it for the real fix.
--
-- -101 degrees itself turned out to be the WRONG angle to pre-rotate
-- to: tested directly, it gave only 197.49 net displacement over 1600
-- frames -- confirming that orientation is where the walker gets stuck
-- (the drift's destination is a bad configuration, not a "found its
-- stride" one). Swept pre-rotation broadly (-150 to +150) and refined
-- around the best region -- -50 degrees won clearly (net displacement
-- -631.74 in the sweep, -557.83 re-verified in an isolated fresh-load
-- check, both comfortably beating the un-rotated baseline's ~-490 to
-- -517). Still a partial improvement, not a full fix: the isolated
-- check showed steady progress the WHOLE 1600 frames (unlike the
-- baseline's near-total stall past frame 800), but the RATE does slow
-- in the second half (roughly 120 units/400 frames early, dropping to
-- 20-30 units/400 frames later) -- better, not eliminated.
local preRotRad = math.rad(-50)
local preRotQuat = btQuaternion(0, 0, math.sin(preRotRad/2), math.cos(preRotRad/2))
cube.trans = btTransform(preRotQuat, btVector3(cube_center_x, terrain_lift, 0))   -- see terrain_lift above -- 0 when terrainAmp is 0, same starting position as before
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
add(cube)

-- ---------------------------------------------------------------------
-- linkage builder -- one full copy of Spears 4Bar-1 (crank/coupler/
-- rocker + a rigidly-welded leg-arm) mounted at x_offset along the
-- cube's face (g_center = (x_offset, 1.25)), with its own motor. g_ang
-- tilts the ground link around its own midpoint -- passed as 54.459
-- below (Spears 4Bar-1's own ground_angle), not the 90 the previous
-- slider-mechanism version of this file used.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- SPEARS 4BAR-1 CONSTANTS: linkage.lua's compute_spears4bar1 fixes
-- these as literal numbers inside its own compute() function (unlike
-- the crank/ground/coupler/rocker lengths, which are passed through
-- this file's own g_len/a_len/coupler_len/rocker_len instead) --
-- ground_angle=54.459deg and leg_angle=-102.27deg are genuinely part of
-- "which mechanism this is", not free parameters to renormalize, so
-- they're kept as exact literals here too, matching the source.
-- attach_frac=0.25 is like both -- also fixed by the source mechanism,
-- but expressed as a pure fraction (scale-invariant), so it doesn't
-- need to be renormalized at all.
-- ---------------------------------------------------------------------
local ATTACH_FRAC = 0.25
local LEG_ANGLE_DEG = -102.27
local LEG_ANGLE_RAD = math.rad(LEG_ANGLE_DEG)

local function buildLinkage(x_offset, g_ang, mirror, phase, speed)
  g_ang = g_ang or 0
  phase = phase or 0
  local zSign = mirror and -1 or 1
  local z_ground_l  = zSign * z_ground
  local z_crank_l   = zSign * z_crank
  local z_coupler_l = zSign * z_coupler
  local z_rocker_l  = zSign * z_rocker
  local z_pendant_l = zSign * z_pendant   -- "pendant" naming kept for buildFoot's benefit -- this is really the rigid leg-arm, welded (not hinged) to the coupler, see the LEG WELD note below

  local g_center = { x = x_offset, y = 1.25 + terrain_lift }   -- terrain_lift (from buildScene above) keeps every downstream point in sync with the raised cube
  local O2 = { x = g_center.x - (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y - (g_len/2)*math.sin(math.rad(g_ang)) }
  local O4 = { x = g_center.x + (g_len/2)*math.cos(math.rad(g_ang)),
               y = g_center.y + (g_len/2)*math.sin(math.rad(g_ang)) }

  local a_ang0 = g_ang + 90 + phase
  local A = { x = O2.x + a_len*math.cos(math.rad(a_ang0)),
              y = O2.y + a_len*math.sin(math.rad(a_ang0)) }
  -- B: coupler <-> rocker meeting point, via circle-circle intersection
  -- -- exactly linkage.lua's own compute_spears4bar1 (branch=-1, "the
  -- other Grashof-boundary path" -- the same branch sign the source
  -- uses, kept exactly, not re-derived).
  local B = circleIntersect(A, coupler_len, O4, rocker_len, -1)

  -- attach: the point ALONG the coupler, ATTACH_FRAC of the way from B
  -- toward A -- NOT at either end, and NOT the coupler's own midpoint
  -- either (that would be ATTACH_FRAC=0.5). The leg-arm welds on here.
  local attach = { x = B.x + ATTACH_FRAC*(A.x - B.x), y = B.y + ATTACH_FRAC*(A.y - B.y) }
  -- C: the leg-arm's tip, extended from attach at a FIXED angle
  -- (LEG_ANGLE_DEG) relative to the coupler's own current direction --
  -- exactly compute_spears4bar1's own P = attach + leg_len*rotate(unit(B-A), leg_angle).
  -- Note this offset is measured from the coupler's A->B direction, not
  -- O2->O4 or any other reference -- matching the source exactly.
  local ux, uy = (B.x - A.x)/coupler_len, (B.y - A.y)/coupler_len
  local ca, sa = math.cos(LEG_ANGLE_RAD), math.sin(LEG_ANGLE_RAD)
  local lx, ly = ux*ca - uy*sa, ux*sa + uy*ca
  local C = { x = attach.x + p_len*lx, y = attach.y + p_len*ly }   -- "C"/p_len kept for buildFoot's benefit -- this is the Leg tip, at leg_len from attach

  local crank   = makeLink(O2, A, z_crank_l, 2.0, "coral", 0.3, rod_d)
  local coupler = makeLink(A, B, z_coupler_l, 4.0, "teal", 1.2, rod_d)
  coupler.damp_ang = 0.15
  coupler.damp_lin = 0.1
  local rocker  = makeLink(O4, B, z_rocker_l, 3.0, "purple", 1.0, rod_d)   -- NEW body type -- this mechanism has a genuine hinged rocker (unlike the slider version's free-spinning block), closing a true 4-bar loop O2-A-B-O4
  rocker.damp_ang = 0.15
  rocker.damp_lin = 0.1
  local pendant = makeLink(attach, C, z_pendant_l, 3.0, "goldenrod", 1.0, rod_d)   -- the rigid leg-arm -- "pendant" name kept for buildFoot's benefit, but it's WELDED below, not hinged: this mechanism has zero free-swinging DOF at the foot end, unlike every Hoecken-family version in this series
  pendant.damp_ang = 0.15   -- welded rigidly to the coupler below, so this mostly just aids solver stability rather than damping a genuine free oscillation the way it did for the old hinged pendant
  pendant.damp_lin = 0.1

  local axis = btVector3(0,0,1)

  -- O2: cube (ground) <-> crank -- the motored joint
  -- pivotCube_O2 MUST go through cube.trans:invXform, not a plain world-
  -- frame subtraction, now that cube.trans carries a real rotation (the
  -- PRE-ROTATION above) -- btHingeConstraint's simplified constructor
  -- expects pivotInA in body A's own LOCAL frame; invXform correctly
  -- converts the world point O2 into that frame regardless of cube's
  -- current orientation. See the PRE-ROTATION note above cube.trans's
  -- own definition for the full derivation.
  local pivotCube_O2  = cube.trans:invXform(btVector3(O2.x, O2.y, z_ground_l))
  local pivotCrank_O2 = btVector3(-a_len/2, 0, z_ground_l - z_crank_l)
  local hingeO2 = btHingeConstraint(cube.body, crank.body, pivotCube_O2, pivotCrank_O2, axis, axis)
  -- maxMotorImpulse kept at 150.0, carried over unmodified from the
  -- Hoecken-slider version of this file -- NOT independently re-tuned
  -- for Spears 4Bar-1's own mass distribution (a true 4-bar loop with a
  -- driven rocker is a different load pattern than a crank dragging a
  -- bar through a fixed slider point was). Flagged, not verified
  -- against a live physics run -- raise this if the motor looks
  -- underpowered.
  hingeO2:enableAngularMotor(true, speed, 150.0)
  addConstraint(hingeO2)

  -- A: crank <-> coupler (free hinge)
  local pivotCrank_A   = btVector3(a_len/2, 0, 0)
  local pivotCoupler_A = btVector3(-coupler_len/2, 0, z_crank_l - z_coupler_l)
  local hingeA = btHingeConstraint(crank.body, coupler.body, pivotCrank_A, pivotCoupler_A, axis, axis)
  addConstraint(hingeA)

  -- O4: cube <-> rocker (free hinge, no motor -- this is the SECOND
  -- fixed pivot of the closed 4-bar loop, matching linkage.lua's own O2)
  -- Same invXform fix as pivotCube_O2 above -- see that comment.
  local pivotCube_O4  = cube.trans:invXform(btVector3(O4.x, O4.y, z_ground_l))
  local pivotRocker_O4 = btVector3(-rocker_len/2, 0, z_ground_l - z_rocker_l)
  local hingeO4 = btHingeConstraint(cube.body, rocker.body, pivotCube_O4, pivotRocker_O4, axis, axis)
  addConstraint(hingeO4)

  -- B: coupler <-> rocker (free hinge -- this is what CLOSES the 4-bar
  -- loop; unlike the slider version, there's no slider joint at all here)
  local pivotCoupler_B = btVector3(coupler_len/2, 0, 0)
  local pivotRocker_B  = btVector3(rocker_len/2, 0, z_coupler_l - z_rocker_l)
  local hingeB = btHingeConstraint(coupler.body, rocker.body, pivotCoupler_B, pivotRocker_B, axis, axis)
  -- HARD LIMIT AT B, precisely to prevent the change-point/wrong-branch
  -- flip: this mechanism's Grashof condition is met by only a 0.19%
  -- margin (crank=2.911590, ground=18.088979, rocker=9.816101,
  -- coupler=11.224906 -- s+l=21.000569 vs p+q=21.041007), meaning the
  -- coupler-rocker joint's reachable region is nearly degenerate at one
  -- extreme of its cycle. Confirmed directly, not just analytically:
  -- an unlimited hingeB, tracked continuously (unwrapped) over an
  -- 800-frame run, sat happily within roughly 92-177 degrees for 500
  -- frames, then between frames 500-600 shot straight through 180
  -- degrees (the true dead center) and kept going to 249 degrees --
  -- the exact wrong-branch flip this note is meant to prevent, caught
  -- live, not hypothesized. Bullet's own getHingeAngle() convention for
  -- THIS specific hinge was verified empirically (matched exactly
  -- against coupler.trans/rocker.trans's own Z-rotation difference, to
  -- rule out a sign/offset mismatch before trusting these numbers) --
  -- normal operation across all four legs stays within roughly
  -- 92-178 degrees, well clear of 180 on the high side and nowhere
  -- near -180 on the low side (that end sits at h2=52.6, nowhere close
  -- to the h2=0.42 near-degeneracy on the high end -- see the SPEARS
  -- 4BAR-1 GRASHOF MARGIN header note for the full derivation).
  -- setLimit(85deg, 178deg) below gives ~2 degrees of genuine hard-stop
  -- margin before the true 180-degree danger point, while sitting
  -- comfortably outside the highest legitimate reading observed
  -- (176.9 degrees, just before the flip) so normal motion is never
  -- clipped -- the lower bound (85 degrees) is generous since that end
  -- was never at risk.
  hingeB:setLimit(math.rad(85), math.rad(178), 0.9, 0.3, 1.0)
  addConstraint(hingeB)

  -- LEG WELD: coupler <-> leg-arm, RIGIDLY WELDED (translation AND
  -- rotation both locked) at the fixed angle LEG_ANGLE_DEG -- not a
  -- free hinge. This is kinematically EXACT, not an approximation: for
  -- ANY crank angle theta, compute_spears4bar1's own formula rotates
  -- the leg by exactly LEG_ANGLE_DEG relative to the COUPLER's current
  -- (not fixed) direction, so the coupler-to-leg angular relationship
  -- is a true invariant of the whole gait cycle, not just a snapshot at
  -- this one construction-time pose -- welding it here with matched
  -- orientation preserves that exact relationship for every future
  -- frame too. (Same principle buildCrossbar/buildFoot already use
  -- elsewhere in this file to weld two independently-built, already-
  -- correctly-posed bodies together with zero relative-rotation error.)
  --
  -- frameInCoupler's local rotation is built directly as a pure Z
  -- rotation by LEG_ANGLE_DEG (not composed from either body's own
  -- world rotation) -- correct because both coupler.body and
  -- pendant.body were built via makeLink with THEIR OWN world
  -- rotations already differing by exactly that angle (coupler's angle
  -- is atan2(B-A), the leg-arm's is atan2(C-attach) = atan2(B-A) +
  -- LEG_ANGLE_DEG, by construction above) -- so composing coupler's
  -- world rotation with this LOCAL LEG_ANGLE_DEG offset lands exactly
  -- on the leg-arm's own world rotation, giving both sides of the weld
  -- the same target orientation.
  local legRelQuat = btQuaternion(0, 0, math.sin(LEG_ANGLE_RAD/2), math.cos(LEG_ANGLE_RAD/2))
  local attachLocalX = coupler_len * (0.5 - ATTACH_FRAC)   -- attach's position along the coupler's own local +-coupler_len/2 axis (A end at -coupler_len/2, B end at +coupler_len/2)
  local frameInCoupler = btTransform(legRelQuat, btVector3(attachLocalX, 0, z_pendant_l - z_coupler_l))
  local frameInPendant = btTransform(IDENTITY_QUAT, btVector3(-p_len/2, 0, 0))   -- attach is the leg-arm's own "-X end" (matches makeLink(attach, C, ...): p1=attach at local -p_len/2)
  local weldLeg = btSliderConstraint(coupler.body, pendant.body, frameInCoupler, frameInPendant, true)
  weldLeg:setLowerLinLimit(0)   -- see the IMPORTANT note up top: slider defaults to FREE translation unless locked
  weldLeg:setUpperLinLimit(0)
  addConstraint(weldLeg)

  return {
    crank = crank, coupler = coupler, rocker = rocker, pendant = pendant,
    hingeO2 = hingeO2, hingeA = hingeA, hingeO4 = hingeO4, hingeB = hingeB, weldLeg = weldLeg,
    z_pendant = z_pendant_l, C = C,
  }
end
-- g_ang=54.459: the ground link (O2->O4) is tilted at Spears 4Bar-1's
-- own ground_angle, not 90/vertical the way the earlier slider-
-- mechanism version of this file used, nor 0/"along the top edge" the
-- way the classical 4-bar versions used.
--
-- PHASE OPTIMIZED PER LEG, found by running real physics trials (bpp
-- -n <N>, real Bullet) with each of the four legs' phase treated as an
-- INDEPENDENT parameter (previously only two values existed: front
-- pair shared phase=0, back pair shared phase=180). Two-round
-- coordinate-descent search: sweep each leg's phase (0-315 in 45-degree
-- steps) holding the other three fixed, averaged across terrainAmp
-- {0,1.0} (400 frames/trial), update that leg to its best value, move
-- to the next leg; repeat once more from the round-1 result. Round 2
-- reproduced round 1's answer exactly (0,225,180,225) -- converged, not
-- still drifting. A final head-to-head across the FULL 5-amplitude
-- range (500 frames/trial) confirmed this beats the old (0,0,180,180)
-- baseline substantially: average net displacement +80% (257.81 vs
-- 143.13) and worst-case (the amp=0.75 trial specifically) +150%
-- (168.64 vs 67.30). Re-verified in isolation afterward (not mid-
-- sweep) to rule out sweep-ordering artifacts -- reproduced to the same
-- strong ballpark (306.64 vs the sweep's 322.64 at amp=0), with a
-- healthy, steady cube.pos.y trajectory throughout, no instability.
--
-- Only linkage1's phase (0) matches its original value -- every other
-- leg moved. There's no simple "front pair together, back pair
-- together, offset by 180" structure left in the optimum; the four
-- phases found (0, 225, 180, 225) don't reduce to any smaller pattern
-- that was checked for -- worth knowing if a future change wants to
-- exploit symmetry for a smaller search space, since this optimum
-- doesn't have any.
local linkage1 = buildLinkage(0, 54.459, false, 0, opts.speed)     -- front face, x=0
local linkage3 = buildLinkage(0, 54.459, true, 180, opts.speed)    -- back face,  x=0

-- NO CROSSBARS in this version: linkage.lua's own MECHANISMS table
-- marks Spears 4Bar-1 as twin=false, unlike Chebyshev-Spears and
-- Hoeckens-Spears (both twin=true) -- it's a self-contained, standalone
-- single-leg mechanism, with no crank-shared paired-leg design to weld
-- together. The previous (Hoecken-Spears slider) version of this file
-- built two crossbars (front pair, back pair) specifically because that
-- mechanism's own free-hinged pendant needed something to pin its
-- rotation down to; this mechanism's leg-arm is already rigidly welded
-- to its own coupler (see the LEG WELD note inside buildLinkage above),
-- so there's no free rotational DOF left to stabilize with a crossbar
-- in the first place.

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
  -- FOOT SIZE OPTIMIZED, found by running real 400-500 frame physics
  -- trials (bpp -n <N>, real Bullet) sweeping foot scale (a uniform
  -- multiplier on outward_extra/inner_gap/foot_x, foot_y held fixed)
  -- across terrainAmp 0-1 (the newly-narrowed slider range). The old
  -- full-size feet (outward_extra=5.0, inner_gap=1.5, foot_x=2.0)
  -- performed well on perfectly flat ground but collapsed badly as
  -- terrain got bumpier -- net XZ displacement over 500 frames dropped
  -- from 238 at amp=0 to just 12 at amp=1.0, a near-total stall, almost
  -- certainly from the big flat pad repeatedly snagging/catching on
  -- bumps rather than sliding cleanly over them. Smaller feet trade a
  -- little flat-ground reach for dramatically better bump tolerance --
  -- but TOO small is a real failure mode, not just a smaller version of
  -- the same behavior: scale=0.20 caused the walker to fall through the
  -- world entirely (minY_drop of ~2000-2600 units, vs. ~0.2-2.0 for
  -- every working scale) -- most likely the weld/foot geometry
  -- destabilizing outright, not a gentle performance dip. scale=0.40
  -- was the strongest robust performer of everything tried (0.20 to
  -- 1.0): smoothly declining, no catastrophic dips anywhere across
  -- amp=0/0.25/0.5/0.75/1.0, unlike scale=0.30 which had a severe dip
  -- at amp=0.5 (14.85) despite doing fine on either side of it.
  --
  -- ASPECT RATIO OPTIMIZED SEPARATELY, after the size sweep above: the
  -- scale=0.40 foot's SHAPE (foot_x=0.8 vs foot_z_len=6.85, a ratio of
  -- only ~0.117 -- heavily elongated sideways, perpendicular to the
  -- walking direction) was never itself examined -- the size sweep
  -- moved area and shape together, so it couldn't tell which one was
  -- doing the work. Re-tested with footprint AREA held fixed at that
  -- same 5.48 and the X:Z ratio swept from 0.10 (near the original
  -- shape) through square (1.0) to 4.0 (elongated the OTHER way, along
  -- the stride direction), first coarse then refined (0.3-0.85) across
  -- the full 5-point amplitude range (400 frames/trial). The original
  -- ratio (0.117) turned out to be one of the WEAKER shapes tested, not
  -- the best -- ratio=0.5 (closer to square, foot_x=1.6553 vs
  -- foot_z_len=3.3106) won clearly on both metrics that matter for
  -- "good across the whole range": highest average net displacement
  -- (233.00 vs the original shape's 199.18, roughly +17%) AND by far
  -- the best worst-case (158.44 at amp=1.0, vs. every other ratio
  -- tested collapsing to ~100-160 there -- ratio=0.5 held up
  -- noticeably better than its immediate neighbors 0.4/0.6, both of
  -- which fell to ~102). Re-verified in isolation afterward at the
  -- worst-case amplitude specifically: 182.93, healthy minY_drop=1.79,
  -- consistent with the sweep's own finding, not a fluke.
  --
  -- FOOT SIZE INCREASED for the two-legged conversion, per direct
  -- request. With only 2 feet instead of 4, and both legs mounted at
  -- the SAME x=0 (front/back only, no left-right pair at all), the
  -- walker turned out to have a real, unresolved stability problem --
  -- see the TWO-LEGGED CONVERSION header note for the full story. Real
  -- physics trials (400-frame, forced-rebuild-then-measure, matching
  -- established methodology) swept foot area (18-120) and ratio
  -- (0.15-0.7) -- area=35/ratio=0.5 won clearly (net_dist=55.49 over
  -- 400 frames, vs the original 18.31/0.1497 shape's 9.88) -- bigger
  -- AND less elongated than before helps meaningfully, though it does
  -- NOT fully fix the underlying tipping problem (see that same header
  -- note). Solving for outward_extra/inner_gap to hit this new shape
  -- while preserving foot_center_z=7.9 (the same reference position
  -- every earlier foot revision in this file has used) gives a
  -- NEGATIVE outward_extra (-1.1167) -- meaning the foot's outer edge
  -- now sits slightly INWARD of the leg's own mounting Z-plane, not
  -- past it, and the leg's own attachment point (Z=13.2) actually falls
  -- OUTSIDE the foot's own [3.72, 12.08] Z-extent entirely. Flagged as
  -- an honest oddity, not hidden: geometrically valid (the weld is just
  -- an offset, Bullet doesn't care whether it's inside or outside the
  -- foot's own footprint) and this exact configuration is what was
  -- empirically tested and found best, but it's an unusual foot/leg
  -- relationship that a from-scratch redesign probably wouldn't
  -- reproduce on purpose.
  local outward_extra = -1.1167
  local inner_gap = 3.7167

  local foot_outer_z = zp + dir*outward_extra   -- outer edge: further out than the pendant itself
  local foot_inner_z = dir * inner_gap           -- inner edge: short of the body's centerline, not touching it
  local foot_z_len = math.abs(foot_outer_z - foot_inner_z)
  local foot_center_z = (foot_outer_z + foot_inner_z) / 2
  local foot_x, foot_y = 4.1833, 0.3      -- foot_y (thickness) still deliberately unchanged -- only the X:Z footprint shape/size was re-optimized here

  local foot = Cube(foot_x, foot_y, foot_z_len, 1.5)   -- was 0.1 -- far too light against the now much-heavier cube (100) and pendant (3.0) it's rigidly welded to; a big local mass mismatch right at a weld (a 0-limit slider, very stiff) is its own source of jitter
  foot.col = color
  local pendant_quat = lk.pendant.trans:getRotation()
  -- HINGED FOOT, per direct request ("can the feet be hinged along the
  -- z axis so that they hit the ground more flushly?"). Previously
  -- welded (0-limit slider, translation AND rotation both locked) --
  -- the foot's own orientation was entirely dictated by the leg's
  -- kinematics, with no way to passively level itself against the
  -- actual ground angle at contact. The constraint below is a real
  -- btHingeConstraint (axis=world Z, matching every other rotating
  -- joint in this file) instead of a weld -- the foot is now free to
  -- rotate about that axis relative to the leg, like an ankle.
  --
  -- FIRST ATTEMPT EXPLODED, root-caused before landing on this version:
  -- starting foot.trans at pendant_quat (matching the leg's OWN current
  -- angle, seemingly the "natural" choice) launched the whole walker
  -- into the air within ~50 frames -- verified the hinge's pivot points
  -- and axis were geometrically correct (matched to the sub-millimeter
  -- via cube.trans-style invXform math, not just hand-derived formulas)
  -- and that the hinge's own angle read exactly 0 at construction, so
  -- it wasn't a pivot mismatch or a limit fighting a nonzero starting
  -- angle -- even a TIGHT +-3 degree limit with max damping made it
  -- WORSE, ruling out an energetic/dynamic explanation too. Root cause:
  -- pendant_quat can point the foot's flat side at a steep angle to the
  -- actual (locally flat) ground at construction -- gravity pulling a
  -- BOX down onto its own CORNER/EDGE instead of its face is a classic
  -- rigid-body instability, and that's exactly what a leg-aligned
  -- starting foot risks. Fix: foot.trans starts at IDENTITY (flat,
  -- matching the OLD weld's effective world orientation, not the leg's
  -- current angle) -- confirmed this alone eliminates the explosion.
  foot.trans = btTransform(IDENTITY_QUAT, btVector3(C.x, C.y, foot_center_z))
  foot.friction = 0.8
  foot.damp_ang = 1.0   -- Bullet clamps this to [0,1] internally (same finding as the crank-damping investigation elsewhere in this file) -- 1.0 is the engine's own ceiling, not an arbitrarily large number
  foot.damp_lin = 0.1
  add(foot)

  -- pivot points only (no frame/rotation needed for a hinge, unlike the
  -- weld this replaces) -- same POSITIONS the old weld's frames used,
  -- verified to coincide in world space to 4 decimal places before
  -- trusting them.
  local pivotFoot    = btVector3(0, 0, zp - foot_center_z)
  local pivotPendant = btVector3(p_len/2, 0, 0)   -- C is the pendant's own "+X end"
  local axis = btVector3(0, 0, 1)
  local ankleHinge = btHingeConstraint(foot.body, lk.pendant.body, pivotFoot, pivotPendant, axis, axis)
  -- LIMITED, not fully free: the leg's own pendant sweeps through a
  -- wide natural angle range over a gait cycle (the two feet's own
  -- starting hinge angles, measured directly, were 84 and 66 degrees
  -- apart just from their different phases) -- so a tight limit
  -- (originally tried +-40 degrees around a wrongly-assumed "0"
  -- reference) doesn't fit this joint's real range of motion. +-90
  -- degrees, combined with max damping, is the tuned result: 1600-frame
  -- long-horizon test reached -694.82 net displacement with minY_drop
  -- staying under 1.35 THE WHOLE WAY -- clearly better than the rigid-
  -- weld version's own best (-507.51, minY_drop 1.84) on both counts.
  -- (5-argument setLimit signature, same as the hingeB change-point fix
  -- elsewhere in this file -- this binding has no default-parameter
  -- support.) SAVED AS "Model2Leg" -- further tuning paused here per
  -- direct request, to resume later.
  ankleHinge:setLimit(math.rad(-90), math.rad(90), 0.9, 0.3, 1.0)
  addConstraint(ankleHinge)

  return foot
end
local foot1 = buildFoot(linkage1, "yellow")
local foot3 = buildFoot(linkage3, "blue")
return {
  cube = cube, cube_w = cube_w, cubeCenterX = cube_center_x,
  linkage1 = linkage1, linkage3 = linkage3,
  foot1 = foot1, foot3 = foot3,
}
end   -- closes M.build()

return M
