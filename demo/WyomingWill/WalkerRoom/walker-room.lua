--
-- Walker room: WyomingWill's walkers on one meadow, each scaled to the
-- same stride, walking freely inside a walled arena. They turn away from the
-- walls and from each other; one that falls is stood up again. The
-- TerrainHeight slider raises the bumps (G builds the room with them). Tab / Shift+Tab follow a
-- walker, O looks over the room, T clears the trails (README.md).
--
-- Each walker is built by its own ../Walkers_For_Room/<name>_parts.lua --
-- a copy of the build its standalone file uses, with a few options added
-- (see that folder's README) -- at a scale that makes its stride
-- (the length of its foot's path) STRIDE cm, under the same gravity as
-- every other walker (GRAVITY), with its motors made stronger or weaker
-- to match, on the same feet (FOOT_LENGTH ...), with its cranks kept in
-- step (LOCK_CRANKS) and its cranks turning so that it would cross flat
-- ground at FLAT_SPEED if its feet never slipped. A
-- bump is then the same obstacle to every walker's step, each walker's
-- foot lifts as high, for its stride, as its linkage lifts it, and on
-- flat ground they should all go the same speed: one that doesn't has
-- something wrong with its build.
-- All of them share one world, one terrain and one physics step.
--
-- Units: centimetres and seconds.
--
-- Opened on its own (no launcher before it -- every launcher loads the
-- walker files first, so EXTRA_WALKERS is still unset): the room with the
-- 11 walkers that could really be built, as they are now -- the diag builds
-- with their outside braces and held pendants; Klann, Jansen and Spears
-- 4-bar on their own frames, Klann and Spears 4-bar reversed
-- (test-ranking.lua's list) -- at room-four.lua's
-- settings, each with a wheel on each side (SHOES: the arrow keys steer the
-- walker followed). This file's own defaults below are the old ones (plated
-- builds, the old braces, gravity 70), which the launchers override.
--

if EXTRA_WALKERS == nil then
  package.path = "../../module/?.lua;" .. package.path
  v:setSolver("si-warm"); v:setSolverInfo("residual", 0.01)
  SOLVER_ITERATIONS = SOLVER_ITERATIONS or 40; FIXED = FIXED or 1 / 1920
  MOTOR_STRENGTH = MOTOR_STRENGTH or 2; GRAVITY = GRAVITY or 981; YAW_DAMP = YAW_DAMP or 1
  ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
  LINK_WIDTH = LINK_WIDTH or 1.0; GAIT = GAIT or { 0, 180, 180, 0 }; DIAG_OUTSIDE = true
  dofile("lib/trotting-walkers.lua"); dofile("lib/spears-lift-walkers.lua")
  local BUILDABLE = { "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62 diag", "Chebyshev-Spears diag",
                      "Hoecken-Spears 4-bar diag", "Hoecken-Spears slider diag", "Klann", "Jansen",
                      "Hoecken slider diag", "Hoecken 4-bar diag", "Chebyshev diag", "Spears 4-bar" }
  if ONLY == nil then ONLY = {}; for _, n in ipairs(BUILDABLE) do ONLY[n] = true end end
  if PENDANT_HOLD == nil then
    PENDANT_HOLD = {}; for _, n in ipairs(BUILDABLE) do if n:find("diag$") then PENDANT_HOLD[n] = true end end
  end
  TERRAIN = TERRAIN or "waves"; AMP = AMP or 2; BUMP = BUMP or 15
  if REVERSE == nil then REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true } end   -- (their better way: section 4w)
  if SHOES == nil then SHOES = {} end   -- (a wheel each side: the arrow keys steer the walker followed)
  ARENA = ARENA or 1500   -- (15 m: room to walk straight between turns)
end

local common = require "common"
v.shadows = false

-- where the walkers' parts files are, relative to this file (bpp runs a
-- script from its own folder); a launcher elsewhere can set WALKERS_DIR
local WALKERS_DIR = WALKERS_DIR or "../Walkers_For_Room/"

-- ---------------------------------------------------------------------
-- settings
-- ---------------------------------------------------------------------

local STRIDE = STRIDE or 15  -- every walker's stride: the length of its foot's path, cm
-- every walker's crank speed is set so that, if its feet never slipped,
-- it would cross flat ground at FLAT_SPEED cm/s: 2 pi FLAT_SPEED / its
-- `advance` (below). CRANK (rad/s), if set, gives every walker that crank
-- speed instead (Walker Room1 and the gravity-70 version: 2.6 for all).
local FLAT_SPEED = FLAT_SPEED or 9
local CRANK = CRANK
-- CRANK_SCALE: a walker's crank speed times this (a number for every
-- walker, or a table by name) -- its measured speed on flat ground
-- differs from FLAT_SPEED by its feet's slip, and differs again with
-- each way it is built, timed and turned, so the test runs measure it
-- for each and set this to bring its flat speed to FLAT_SPEED
local CRANK_SCALE = CRANK_SCALE
-- the chassis every four-legged walker is given (see `chassis` below),
-- for STRIDE = 15; the chassis values in WALKERS were worked out for these
local CLEARANCE, BASE, WIDTH = 12, 35, 30   -- cm: 0.8, 2.33 and 2 strides
local GRAVITY = GRAVITY or 70   -- every walker's gravity, cm/s^2 (see addWalker)
-- LOCK_CRANKS (default on): a walker's cranks are kept in step, at the
-- timing they were built with, as if one motor drove them all through
-- gears (see lockCranks)
LOCK_CRANKS = (LOCK_CRANKS ~= false)
-- every walker's feet: the same flat box, FOOT_LENGTH (along the walk) x
-- FOOT_WIDTH (across) x FOOT_THICK cm, weighing FOOT_MASS (SAME_FEET =
-- false: each keeps its own file's feet, and Jansen and Klann none)
SAME_FEET = (SAME_FEET ~= false)
-- every walker's body the same: SAME_BODY (default on) makes each walker
-- weigh TOTAL_MASS in all (its body making up whatever its legs, feet
-- and braces don't), with its body turning as a BODY_BOX (cm: along the
-- walk, up, across) of that weight would. Its body keeps its own shape
-- for drawing and for touching things (it sits 12 cm up, clear of the
-- ground; its depth also sets where its legs are mounted).
SAME_BODY = (SAME_BODY ~= false)
local TOTAL_MASS = TOTAL_MASS or 100
-- with BAR_MASS (below), the body weighs BODY_MASS in every walker
-- instead, and its legs add what they weigh: more legs, more weight
-- (TOTAL_MASS is then not used)
local BODY_MASS = BODY_MASS or 40
local BODY_BOX = BODY_BOX or { 40, 3, 30 }
-- every walker's motors the same: MOTOR_STRENGTH (default 10) is the
-- most twisting effort all of a walker's crank motors together can give,
-- in units of its weight x gravity x stride -- the same for every walker.
-- (Its own file's motors ranged from 1.4 to 71 in these units.) false:
-- each walker's own file's motors.
MOTOR_STRENGTH = (MOTOR_STRENGTH == nil) and 10 or MOTOR_STRENGTH
-- SOLVER_ITERATIONS (default 40): how many times the physics solver
-- works over each of a walker's joints every step. Bullet's default is
-- 10, and at 10 a walker whose braces close a loop across its body (the
-- diag walkers) has its joints pulled apart on hills and jams. false:
-- Bullet's default (and 40 for the balanced 2-leg Spears, as its own
-- file has it).
SOLVER_ITERATIONS = (SOLVER_ITERATIONS == nil) and 40 or SOLVER_ITERATIONS
-- SLIDER_6DOF (default on): the two sliders' sliding pivot (the bar through
-- its block) made as a generic 6-dof joint, free only along the bar.
-- Bullet's own slider joint let the bar twist up to 10-15 degrees against
-- its block under load, which shook the walker (Hoecken-Spears slider
-- most: its foot link swings about 3 times as fast as the original's).
-- false: the files' slider joint, as before 27 October 2026.
SLIDER_6DOF = (SLIDER_6DOF ~= false)
-- JOINT_FRICTION = { mu = 0.1, pin = 0.25 } (a test; off): friction in every
-- pin joint of every walker, as a real build's oiled pins would have: each
-- step a hinge resists turning with a torque of mu x the force on its pin x
-- the pin's radius (pin, cm), so a joint that carries large forces (a
-- linkage near its smallest transmission angle) costs the motor more; the
-- sliders' sliding pivot resists sliding with mu x its force. A crank's own
-- pin takes its friction off its motor's torque. (bpp's enableForces reads
-- each joint's force; the brake is a motor holding the joint still, capped
-- at that torque.)
JOINT_FRICTION = JOINT_FRICTION or false
-- WIDE (default on): every walker's feet about 38 cm apart side to side
-- (outer foot edge to outer foot edge, as Jansen's own file has them),
-- each walker's body made wide enough for that (see `wide`). false:
-- about 30-31 cm, from the `chassis` body depths
WIDE = (WIDE ~= false)
-- BRACE_CLEARANCE (default 7 cm): the plates and bars joining a walker's
-- legs (its braces) kept at least this far above flat ground while it
-- stands -- above the tallest bumps -- so they never catch on a bump
-- between its feet. A plate loses that much off its bottom (its top stays
-- where it was); a diag walker's low bar is moved up. `brace.gap` is how
-- far above the ground each walker's own braces sit (cm, measured
-- walking on flat ground): as low as 0.9 cm. false: as built.
BRACE_CLEARANCE = (BRACE_CLEARANCE == nil) and 7 or BRACE_CLEARANCE
-- DIAG_ARCH (default on): a diag walker's two braces both over its body,
-- the front-left/back-right one arched up (brace.rise, cm) to
-- pass over the other where they cross. Its bottom brace, lifted clear of
-- bumps (BRACE_CLEARANCE), passed through its body and its cranks; built
-- low, as in its file, it catches on bumps. false: the bottom brace,
-- lifted.
if DIAG_ARCH == nil then DIAG_ARCH = true end
-- DIAG_LOW (cm; default off): a diag walker's front-left/back-right brace
-- built low instead of arched, near the feet, in three pieces (across from
-- the front pendant to the middle, along the middle, across to the back
-- pendant), its bottom DIAG_LOW cm above the feet's bottoms. It passes
-- nothing of the walker; it meets bumps higher than it is. Overrides
-- DIAG_ARCH for that brace.
DIAG_LOW = DIAG_LOW or false
-- DIAG_LOW_BOTH (a test; off): with DIAG_LOW, the other brace built low the
-- same way too; the two cross in the middle, so only for braces made to
-- touch nothing.
DIAG_LOW_BOTH = DIAG_LOW_BOTH or false
-- DIAG_OUTSIDE (default off): every diag build's two braces built
-- outside the pendants instead, each a run
-- along the walk on the outside face of each of its pendants and a
-- diagonal across between them, all at one height: one just over the body,
-- the other just under it (the top one clears the raised letters on the
-- body too). Their pendants then need no
-- extension, so they are built as long as their guides cousins'. The
-- places come from a check through a whole crank turn against every link,
-- foot, the body and its letters (0.3 cm or more from all of them): OUTSIDE_FIT, per
-- walker, { yRel = the brace's bottom above its pendants' lower ends,
-- runFront, runBack = how far each run reaches from its pendant } (cm),
-- and for the five fitted later (handover/tools/outz5.py, 0.4 cm from
-- every link and foot, so 0.3 or more as built) bar = the bars'
-- height, 1.074 cm (Chebyshev-Spears diag's; Hoecken-Spears 4-bar diag's
-- are 1.12, 0.75 of its own units), and extUp = how far its pendants
-- reach above their hinges to the couplers (cm; Hoecken-Spears 4-bar duty 85
-- diag's and Chebyshev-Spears lift 62 diag's top braces reach 0.73 cm above the
-- hinges, so their pendants go 0.8 higher).
DIAG_OUTSIDE = DIAG_OUTSIDE or false
local OUTSIDE_FIT = {
  ["Hoecken slider diag"] = { bar = 1.074, top = { yRel = 15.50, runFront = 9.78, runBack = 9.72 }, bottom = { yRel = 7.01, runFront = 1.10, runBack = 1.15 } },   -- (28 October: outz5.py on sweeps at LINK_WIDTH 1.0, with GHOST_BRACES, 0.4 cm from links; top braces 0.15 higher, to clear the letters by 0.3 walking)
  ["Hoecken-Spears slider diag"] = { bar = 1.074, top = { yRel = 15.19, runFront = 9.70, runBack = 9.76 }, bottom = { yRel = 5.51, runFront = 1.35, runBack = 1.36 } },
  ["Chebyshev-Spears diag"] = { top = { yRel = 14.52, runFront = 1.31, runBack = 10.19 }, bottom = { yRel = 5.75, runFront = 3.84, runBack = 7.68 } },
  ["Hoecken-Spears 4-bar diag"] = { top = { yRel = 14.72, runFront = 1.24, runBack = 10.52 }, bottom = { yRel = 5.63, runFront = 4.61, runBack = 8.91 } },
  ["Chebyshev diag"] = { bar = 1.074, top = { yRel = 17.33, runFront = 8.35, runBack = 14.90 }, bottom = { yRel = 7.72, runFront = 2.81, runBack = 2.70 } },
  ["Hoecken 4-bar diag"] = { bar = 1.074, top = { yRel = 17.58, runFront = 8.54, runBack = 15.46 }, bottom = { yRel = 7.62, runFront = 2.73, runBack = 2.77 } },
  ["Hoecken-Spears 4-bar duty 85 diag"] = { bar = 1.074, extUp = 0.8, top = { yRel = 15.15, runFront = 1.74, runBack = 8.30 }, bottom = { yRel = 5.30, runFront = 4.43, runBack = 8.58 } },
  ["Chebyshev-Spears lift 51 diag"] = { bar = 1.074, top = { yRel = 16.91, runFront = 1.84, runBack = 14.36 }, bottom = { yRel = 3.99, runFront = 4.97, runBack = 13.22 } },
  ["Chebyshev-Spears lift 62 diag"] = { bar = 1.074, extUp = 0.8, top = { yRel = 19.65, runFront = 1.93, runBack = 15.58 }, bottom = { yRel = 4.54, runFront = 3.99, runBack = 15.27 } },
}
-- OUTSIDE_V (default off; with DIAG_OUTSIDE): each diag build's bottom
-- outside brace as a V seen from the side (William, 25 October): its middle
-- piece straight across under the body (as nearly as fits: Chebyshev-Spears lift 62
-- diag's reaches 0.25 cm along the walk), at the height the bottom brace has
-- now, and its runs rising from there to their pendants, their ends higher
-- by half the room between the brace's bottom at its lowest and the body's
-- bottom. Only the middle piece is that low, so less bar runs near the
-- ground. Fitted by handover/tools/vfit.py (0.3 cm or more from every link,
-- foot and the top brace through a whole turn): OUTSIDE_V_FIT, per walker,
-- the bottom brace's runFront, runBack (from each pendant to the middle
-- piece's end) and rise (cm); its yRel stays OUTSIDE_FIT's.
OUTSIDE_V = OUTSIDE_V or false
local OUTSIDE_V_FIT = {
  ["Chebyshev-Spears diag"] = { runFront = 22.38, runBack = 12.61, rise = 3.02 },
  ["Hoecken-Spears 4-bar diag"] = { runFront = 21.90, runBack = 13.11, rise = 3.13 },
  ["Chebyshev diag"] = { runFront = 19.56, runBack = 15.44, rise = 2.12 },
  ["Hoecken 4-bar diag"] = { runFront = 19.48, runBack = 15.52, rise = 2.21 },
  ["Hoecken-Spears 4-bar duty 85 diag"] = { runFront = 20.68, runBack = 14.32, rise = 3.28 },
  ["Chebyshev-Spears lift 51 diag"] = { runFront = 16.47, runBack = 18.47, rise = 4.54 },
  ["Chebyshev-Spears lift 62 diag"] = { runFront = 13.74, runBack = 21.02, rise = 5.33 },
}
-- OUTSIDE_V_FIT_W: the same, at LINK_WIDTH 1.0 (vfit.py on sweep6W)
local OUTSIDE_V_FIT_W = {
  ["Chebyshev-Spears diag"] = { runFront = 22.39, runBack = 12.61, rise = 3.02 },
  ["Hoecken-Spears 4-bar diag"] = { runFront = 21.90, runBack = 13.10, rise = 3.13 },
  ["Chebyshev diag"] = { runFront = 21.17, runBack = 13.83, rise = 2.12 },
  ["Hoecken 4-bar diag"] = { runFront = 20.88, runBack = 14.12, rise = 2.22 },
  ["Hoecken-Spears 4-bar duty 85 diag"] = { runFront = 20.68, runBack = 14.32, rise = 3.28 },
  ["Chebyshev-Spears lift 51 diag"] = { runFront = 16.72, runBack = 18.22, rise = 4.54 },
  ["Chebyshev-Spears lift 62 diag"] = { runFront = 14.24, runBack = 20.77, rise = 5.33 },
}
-- PLATE_LOW (default off): each plated build's side plates built as a bar
-- 1.074 cm tall (the outside braces' bars) instead of the pendants' height,
-- low on the pendants: its bottom, at its lowest in a crank turn, as high
-- above the ground as its diag cousin's bottom brace's (William: the same
-- clearance), and for the two sliders (no diag cousin then) by the diag braces'
-- rule, where a diag build's bottom brace would go: its top 0.3 cm under
-- the body's bottom at its highest. The plates are outside every
-- link, so nothing else limits them. PLATE_FIT: per walker, drop = how far
-- the bar's middle is below the pendants' middles (cm), fitted from a crank
-- turn (handover/tools/platefit.py).
PLATE_LOW = PLATE_LOW or false
-- PLATE_FIT_W: the same, at LINK_WIDTH 1.0 (the diag cousins' bottom braces then
-- 3.84-7.95 cm up)
local PLATE_FIT_W = {
  ["Chebyshev"] = { drop = 7.30 }, ["Chebyshev-Spears"] = { drop = 3.08 }, ["Hoecken 4-bar"] = { drop = 7.28 },
  ["Hoecken-Spears 4-bar"] = { drop = 3.48 }, ["Hoecken-Spears 4-bar duty 85"] = { drop = 2.08 },
  ["Chebyshev-Spears lift 51"] = { drop = 5.25 }, ["Chebyshev-Spears lift 62"] = { drop = 5.17 },
  ["Hoecken slider"] = { drop = 7.30 }, ["Hoecken-Spears slider"] = { drop = 5.25 },
}
local PLATE_FIT = {
  ["Chebyshev"] = { drop = 7.28 }, ["Chebyshev-Spears"] = { drop = 3.05 }, ["Hoecken 4-bar"] = { drop = 7.26 },
  ["Hoecken-Spears 4-bar"] = { drop = 3.46 }, ["Hoecken-Spears 4-bar duty 85"] = { drop = 2.09 },
  ["Chebyshev-Spears lift 51"] = { drop = 4.84 }, ["Chebyshev-Spears lift 62"] = { drop = 4.67 },
  ["Hoecken slider"] = { drop = 7.30 }, ["Hoecken-Spears slider"] = { drop = 5.25 },
}
-- OUTSIDE_FIT_W: the same, at LINK_WIDTH 1.0 (outz5.py on sweep4W, 0.4 cm
-- from every link and foot), every build's bars 1.074 cm tall
local OUTSIDE_FIT_W = {
  ["Hoecken slider diag"] = { bar = 1.074, top = { yRel = 15.50, runFront = 9.78, runBack = 9.72 }, bottom = { yRel = 7.01, runFront = 1.10, runBack = 1.15 } },   -- (28 October: outz5.py on sweeps at LINK_WIDTH 1.0, with GHOST_BRACES, 0.4 cm from links; top braces 0.15 higher, to clear the letters by 0.3 walking)
  ["Hoecken-Spears slider diag"] = { bar = 1.074, top = { yRel = 15.19, runFront = 9.70, runBack = 9.76 }, bottom = { yRel = 5.51, runFront = 1.35, runBack = 1.36 } },
  ["Chebyshev-Spears diag"] = { bar = 1.074, top = { yRel = 14.52, runFront = 1.32, runBack = 10.44 }, bottom = { yRel = 5.75, runFront = 4.60, runBack = 8.67 } },
  ["Hoecken-Spears 4-bar diag"] = { bar = 1.074, top = { yRel = 14.72, runFront = 1.24, runBack = 10.77 }, bottom = { yRel = 5.63, runFront = 4.86, runBack = 9.16 } },
  ["Chebyshev diag"] = { bar = 1.074, top = { yRel = 17.33, runFront = 8.12, runBack = 14.38 }, bottom = { yRel = 7.71, runFront = 1.25, runBack = 1.26 } },
  ["Hoecken 4-bar diag"] = { bar = 1.074, top = { yRel = 17.58, runFront = 8.06, runBack = 14.93 }, bottom = { yRel = 7.61, runFront = 1.19, runBack = 1.05 } },
  ["Hoecken-Spears 4-bar duty 85 diag"] = { bar = 1.074, extUp = 0.8, top = { yRel = 15.14, runFront = 1.67, runBack = 7.83 }, bottom = { yRel = 5.30, runFront = 4.17, runBack = 8.59 } },
  ["Chebyshev-Spears lift 51 diag"] = { bar = 1.074, top = { yRel = 16.54, runFront = 1.11, runBack = 14.09 }, bottom = { yRel = 3.59, runFront = 4.98, runBack = 13.23 } },
  ["Chebyshev-Spears lift 62 diag"] = { bar = 1.074, extUp = 0.8, top = { yRel = 19.16, runFront = 1.45, runBack = 15.05 }, bottom = { yRel = 4.01, runFront = 3.75, runBack = 15.26 } },
}
-- PENDANT_HOLD: true (or a table of names; default off): each leg's
-- pendant (the link its foot hangs from) also held at its angle to the
-- body, free to move with its leg -- as a rigid build's braces hold it,
-- without the give of the long chain of joints between them in the
-- simulation
PENDANT_HOLD = PENDANT_HOLD or false
-- LINK_THICK (default 0.3 cm) and PLANE_GAP (default 0.7 cm): every
-- walker's links the same thickness across, and the planes they move in
-- the same distance apart: 0.4 cm between neighbouring links' faces, the
-- least that kept loaded links (which twist a little at their joints)
-- from touching their neighbours (0.2 did not). Their files' links were
-- 0.18 to 0.46 cm thick, their planes 0.25 to 2.1 cm apart. false: each
-- file's own.
if LINK_THICK == nil then LINK_THICK = 0.3 end
-- LINK_WIDTH (cm; default off): every bar of every walker (what its build
-- makes with makeLink) this wide, as LINK_THICK makes them all as thick
-- (William, 25 October: 1.0, about Jansen's and Klann's own). Off, each
-- keeps its own file's width times the room's scale: 0.43 to 4.28 cm.
-- Triangles (Jansen's, Klann's), the sliders' guide blocks, braces, plates
-- and feet keep their shapes. Weight doesn't change (bars are weighed by
-- length); turning inertia does a little; so do the clearances between
-- bars in a plane, so some walkers need other planes (planesFor).
LINK_WIDTH = LINK_WIDTH or false
-- WIDTH_REFITS_OFF (a test; a table of names): with LINK_WIDTH, those builds
-- get the width but none of its refits (their bodies, planes, braces and
-- plates as with each file's own widths)
WIDTH_REFITS_OFF = WIDTH_REFITS_OFF or {}
-- WIDTH_FIT: what LINK_WIDTH = 1.0 changes in a build besides its bars
-- (handover section 4b): bodyRaise (the 1 cm between a foot's top and the
-- lowest link, which sets the Spears lifts' bodies), cube_d (its 38 cm
-- stance), planes (the fewest planes at that width: Chebyshev-Spears diag 3,
-- as its guides cousin), bodyShift (balance), in the build's own units as
-- in its entry below. Builds not named keep theirs.
local WIDTH_FIT = {
  ["Chebyshev-Spears lift 51"] = { bodyRaise = -1.048 },
  ["Chebyshev-Spears lift 51 diag"] = { bodyRaise = -2.548 },
  ["Chebyshev-Spears lift 62"] = { bodyRaise = -2.188 },
  ["Chebyshev-Spears lift 62 diag"] = { bodyRaise = -3.678 },
  ["Chebyshev-Spears diag"] = { planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, cube_d = 15.223 },
}
if PLANE_GAP == nil then PLANE_GAP = 0.7 end
-- With PLANE_GAP, each walker's links in the fewest planes that keep them
-- from touching (spec.planes: link -> plane, counted out from the body's
-- face): links of one leg may share a plane if they are never in the same
-- place at the same moment, links of different legs only if the areas they
-- sweep never meet (whatever the gait), each with 0.2 cm to spare. Found
-- by sweeping every link through a crank turn; README, "Link planes".
-- BALANCE (default on): each walker's body slid along the walk against
-- its legs (spec.bodyShift, cm) so that the whole walker's centre of mass,
-- averaged over a crank turn, sits midway between its front and back
-- feet's path middles -- its weight shared evenly by its front and back
-- feet. Most files mount their legs off the body's middle: Klann's put
-- 77% of its weight on one pair of feet. The body is then a frame plus a
-- load (spec.frame): the frame spans its leg mounts, 3 cm past the first
-- and last, and the load sits at the balance point, wherever that falls
-- on the frame (its weight and turning are BODY_BOX's whatever the
-- frame's length). false: as built.
if BALANCE == nil then BALANCE = true end
-- DIAG_GIVE (default 0 degrees): how far a diag walker's bars may turn
-- on the legs they are welded to. Their files allow 3 degrees (against
-- crank drift, which LOCK_CRANKS now stops); with it each leg rocks
-- about 6 degrees a turn, which bends its feet's path away from the
-- plated build's. At 0 the two builds' feet trace the same path.
DIAG_GIVE = DIAG_GIVE or 0
-- BAR_MASS (default on): every bar of every walker weighed by one rule,
-- `density` per cm of bar plus `bolt` for each joint on it (a joint
-- between two bars puts a bolt's weight on each). A triangle counts as
-- its three sides; a plate as a bar its width long; ideal guides weigh
-- nothing; feet keep FOOT_MASS. 0.18 per cm is Jansen's and Klann's own
-- 0.04 per unit of their files; 0.15 a joint matches their 0.3 a bar.
-- false: each file's own masses.
if BAR_MASS == nil then BAR_MASS = { density = 0.18, bolt = 0.15 } end
-- MARKS (default on): each walker's body marked with its colours and
-- code (see markBody). false: plain bodies, as the walkers' own files
-- paint them.
MARKS = (MARKS ~= false)
-- ANKLES = true: every walker's feet hinged to its legs about the
-- side-to-side axis, like ankles (as the 2-leg Spears' own files have
-- them), instead of welded (Walker Room1: welded)
ANKLES = ANKLES or false
-- ANKLE_SPRING = { stiffness =, damping = }: ankles as ANKLES, each foot
-- also held level to the body by a spring about the ankle's axis (as a
-- parallel link would hold it), so it swings level and lands level but
-- can still rock on a bump; stiffness in weight-units x cm^2/s^2 per
-- radian. nil: off.
-- ANKLE_STOP (default 30): with ANKLE_SPRING, each foot stops when its
-- sole is that many degrees from its leg link, either way (see addWalker);
-- false: no stop
ANKLE_STOP = (ANKLE_STOP == nil) and 30 or ANKLE_STOP
-- REVERSE: true runs every walker's cranks backward (a table of names,
-- { ["Spears 4-bar"] = true }, just those): each foot goes round its path
-- the other way, so the walker walks the other way, and the end of its
-- foot's swing it came down at is now the one it lifts off at
REVERSE = REVERSE or false
-- GAIT = { four crank phases, degrees }: every leg's phase, for the
-- walkers without braces locking their legs together (Jansen, Klann,
-- Spears 4-bar), in the Spears 4-bar file's order: front face first leg,
-- second leg, back face first leg, second leg. Its own: { 0, 225, 180, 225 }
GAIT = GAIT or nil
-- UNBRACED: true (or a table of names) leaves off the side plates of the
-- walkers that have them (Chebyshev, Chebyshev-Spears, the Hoecken
-- walkers and Hoecken-Spears 4-bars and sliders) and holds each leg at
-- its angle to the body instead (a guide, as the plates did), so their
-- legs are free to take any GAIT, a trot (GAIT = { 0, 180, 180, 0 })
-- among them
UNBRACED = UNBRACED or false
local FOOT = { length = FOOT_LENGTH or 8, width = FOOT_WIDTH or 12, thick = FOOT_THICK or 0.5, mass = FOOT_MASS or 1.5 }
-- FOOT_TIPS = { length =, angle = } (cm, degrees): every foot's ends turned
-- up, toe and heel alike (a walker reversed leads with its heel), as two
-- tips that long, rising at that angle, welded to a flat middle; the foot
-- as long in all along the walk (FOOT_LENGTH), as wide and as heavy. nil:
-- flat feet, unless the walker's own spec.footTips (a builder's tweak:
-- both Hoecken-Spears slider builds, 29 October) gives it tips.
-- BODY_ANG_DAMP = d (0-1): every walker's body's turning damped by d about
-- every axis, instead of its file's value (1.0 in every file, which stops
-- the body turning off course but also stops it pitching and rolling: it
-- loses all its turning speed every physics step). nil: its file's.
-- YAW_DAMP = d (0-1): the body's turning about the vertical damped by d each
-- frame (its turning speed about the vertical times 1 - d), its pitch and
-- roll left free (its own damping BODY_ANG_DAMP, or 0) -- the files'
-- straight-line fix without holding the body's tilt. nil: off.
-- LINK_DAMP (default 0): every link's and brace's own damping (Bullet's: a
-- drag on the body's own motion, not friction in its joints) set to this,
-- moving and turning, the same for every walker; feet keep the room's 0.1
-- moving, the body its own (BODY_ANG_DAMP, YAW_DAMP). Before 31 October
-- each kept its file's: none on most, 0.05 turning on Klann's and Jansen's
-- links, 0.10 / 0.15 and 0.20 / 0.30 on the sliders', 0.10 / 0.15 on Spears
-- 4-bar's, 0.15 turning on the outside braces. false: as its files give.
LINK_DAMP = (LINK_DAMP == nil) and 0 or LINK_DAMP
-- STEER = { mech =, side = "L" or "R", amount = k } (a steering test; off,
-- handover/STEERING.md): a bias on one side of every walker. Left and right
-- are the walker's own, facing the way it walks; a turn to the left is a
-- positive turning rate. Each foot and each crank motor is put on its side
-- and end by where it is in the body's frame when built (w.steer).
--   mech = "friction": that side's feet's friction times k
--   mech = "pair": the diagonal pair whose front foot is on that side (its
--     rear foot on the other) driven at k times its crank speed; the crank
--     lock (lockCranks) then holds each pair's cranks only to each other
--   mech = "side": that side's cranks at k times (lock held per side; a
--     walker with diag braces has each brace tying a left crank to a right)
--   mech = "ballast": a ballast (STEER.mass of its weight, default 0.25)
--     moved k cm to that side by a motor on a slider across its body
--   mech = "drag": a shoe, k of its weight, dragged on that side
--   mech = "sole": that side's soles k cm thicker (a slab welded under)
--   mech = "stiff", "damp": that side's ankle springs k times as stiff, or
--     as damped (ANKLE_SPRING)
--   mech = "linkdamp": the pair's links (as "pair") damped k (as LINK_DAMP)
STEER = STEER or false
-- SHOES = { mass =, radius =, out =, grip =, down = } (handover/STEERING.md,
-- "Stage A"; off): a wheel on each side of every walker, to steer it by
-- drag -- a ball, mass of the walker's weight (default 0.15), radius cm
-- (1.5), out cm (5) out beyond its feet, its friction grip times the
-- feet's (3: braked, it turns the walker about 5 deg/s), always on the ground by its own
-- weight and free up and down (the walker never carries it, so never
-- leans), rolling along the walk. room.setShoe(w, side) while it runs
-- brakes that side's ("L" or "R"; nil for neither) and its skid turns the
-- walker toward it; down = that side braked at the start. While one is
-- braked, that walker's yaw damping (YAW_DAMP) is off, so it turns; freed,
-- the damping holds it on its new heading. The Left and Right arrow keys
-- brake the walker followed's left or right wheel (again: free it).
SHOES = SHOES or false
-- FOOT_POINT = r (cm): no foot at all -- each leg ends in a point, a ball
-- r in radius at the leg's tip, as heavy as a foot (like a ski pole's tip
-- or Klann's and Jansen's own legs); nothing across the walk, so the
-- walker stands only on its leg planes. nil: flat feet.
-- FOOT_ROD = r (cm): every foot a round rod across the walk instead, r in
-- radius, as wide as a flat foot (FOOT_WIDTH) and as heavy -- like a ski
-- pole's tip: it meets the ground along a line, rolls over an edge, and is
-- the same whichever way it is turned (an ankle does nothing for it).
-- nil: flat feet.
local ARENA = ARENA or 1000 -- the arena is ARENA x ARENA cm, centred on 0 ...
local ARENA_X = ARENA_X or ARENA   -- ... or ARENA_X long (along x) and ARENA_Z wide
local ARENA_Z = ARENA_Z or ARENA

-- TEST_TRACK = true: the test track. Only the walker named ONLY, starting near
-- the -x end facing +x, walks straight down the arena (make it long and
-- narrow: ARENA_X, ARENA_Z) with no avoidance turns, for TRACK_SECS
-- seconds, and reports how far it got along x. Its start is moved, by
-- SEED, up to a bump length along and across, so runs with different
-- seeds meet the bumps differently. See lib/test-track.lua.
TEST_TRACK = TEST_TRACK or false
local TRACK_SECS = TRACK_SECS or 60
local CELL_SET = CELL      -- terrain cell, cm: a launcher can fix it; otherwise it follows BumpLength (below)
local FIXED = FIXED or 1 / 960   -- the physics step every walker shares, s
local FRAME = 1 / 60       -- simulated time per drawn frame, s

-- ONLY = "<name>" builds just that walker (for tests), at the centre;
-- ONLY = { ["<name>"] = true, ... } just those, on the room's grid; otherwise all
ONLY = ONLY or nil
SEED = SEED or 1           -- seeds the walkers' starting headings (and, later, their turns)

v.timeStep = FRAME
v.animationPeriod = math.floor(FRAME * 1000)   -- a frame every 16 ms: real time, if the machine keeps up
v.fixedTimeStep = FIXED
v.maxSubSteps = math.ceil(FRAME / FIXED)
v.gravity = btVector3(0, -981, 0)   -- (each walker's own bodies get their own, below)

-- ---------------------------------------------------------------------
-- the terrain: one bumpy meadow for everyone. Its bump height is the
-- TerrainHeight slider and its bumps' length the BumpLength slider, in
-- whole centimetres; moving them builds nothing until G (or a 1-4 key, or
-- on the test track M or N) builds the room again with them (the floor
-- changes shape, and each walker is built to clear the highest bump).
-- ---------------------------------------------------------------------

local AMP = AMP or 1.0     -- bump height, cm: the highest a bump reaches above 0
local AMP_MAX = 8          -- the slider's top: about the walkers' own sliders' tops, scaled to the room
local pendingAmp, pendingBump   -- (the sliders' values, waiting for the next build)
-- the ranking boards (the test track; lib/boards.lua, made from the table runs
-- by runs/boards.py): for the ground it is on -- its terrain, its height
-- rounded to the cm (flat under 0.5) -- every build run there, best first,
-- each one's mean speed over the runs' seeds; shown in the output pane when
-- a walker starts (and on B), with this walker marked, and its own run
-- set beside it at 20 s
if TEST_TRACK and BOARDS == nil then pcall(dofile, "lib/boards.lua") end
local function boardKey()
  local h = math.floor(AMP + 0.5)
  return (h == 0) and "flat 0" or string.format("%s %d", TERRAIN, h)
end
local function boardPlace(b, speed, name)   -- (its place among the others, at this speed)
  local k = 1
  for _, r in ipairs(b) do if r[1] ~= name and r[2] > speed then k = k + 1 end end
  return k
end
local function showBoard(name)
  local b = BOARDS and BOARDS[boardKey()]
  if not b then print("board: no results for " .. boardKey() .. " yet (runs/boards.py makes lib/boards.lua)"); return end
  local t = { string.format("board: %s cm%s -- what to expect (the table runs: each mean over its seeds, the 8 m track, normal ground; cm/s from 5 s to 20 s)",
    boardKey(), TERRAIN_MIRROR and " (this ground is mirrored; the board is for normal ground)" or "") }
  for i, r in ipairs(b) do
    t[#t + 1] = string.format("%s %2d  %-34s %5.2f +- %.2f", r[1] == name and ">" or " ", i, r[1], r[2], r[3])
  end
  print(table.concat(t, "\n"))
end
-- bump length, cm: the middle one of the three sine terms' wavelengths
-- (the other two are 1.25 and 0.84 times it). At 22 (1.5 strides) the
-- bumps are rolling hills the walkers walk up and down; shorter ones are
-- obstacles a foot has to lift over within a step.
local BUMP = BUMP or 22
local BUMP_MIN, BUMP_MAX = 11, 44

-- TERRAIN: the kind of ground (all with bumps AMP high, at a scale set by
-- BUMP), for testing that results don't hang on one landscape:
--   "waves" (default): three sine terms as in the walkers' own terrains
--     (amplitudes 0.5, 0.3 and 0.2: AMP is the highest a bump can reach),
--     their wavelengths all scaled by BUMP -- the same regular pattern
--     everywhere
--   "random": twelve waves with random directions, wavelengths (0.6 to
--     1.6 times BUMP) and offsets, scaled so the highest point reaches
--     AMP: irregular bumps, a different landscape for each TERRAIN_SEED
--   "logs": separate rounded ridges AMP high and BUMP / 2 wide across the
--     way, at random angles (up to 15 degrees) and 1.5 to 4 BUMPs apart
--   "steps": flat ground with sharp-edged ledges AMP high, up and down by
--     turns, 2 to 5 BUMPs apart, at random angles (up to 15 degrees)
-- TERRAIN_SEED (default SEED): which random landscape
TERRAIN = TERRAIN or "waves"
local TERRAIN_SEED_SET = TERRAIN_SEED   -- (set: the N key leaves the landscape alone)
local TERRAIN_SEED = TERRAIN_SEED or SEED
local tseed
local function trand()           -- its own random numbers, leaving the walkers' alone
  tseed = (tseed * 1103515245 + 12345) % 2147483648
  return tseed / 2147483648
end
local WAVES, RIDGES, LEDGES
local ANG_COS, ANG_SIN      -- (the logs' or steps' angles: the least cos and the most |sin| among them)
-- (made again for the 1-4 keys and the N key)
local function makeTerrain()
  tseed = TERRAIN_SEED * 7919 + 17
  WAVES, RIDGES, LEDGES = nil, nil, nil
  if TERRAIN == "random" then
    WAVES = {}
    for i = 1, 12 do
      local th, lam = trand() * math.pi, 0.6 + trand()
      WAVES[i] = { kx = math.cos(th) * 2 * math.pi / lam, kz = math.sin(th) * 2 * math.pi / lam,
                   ph = trand() * 2 * math.pi, a = 0.5 + 0.5 * trand() }
    end
    -- (in units of BUMP) scaled so the highest point over a wide area is
    -- 1, so AMP means the same as for "waves": the highest a bump reaches
    -- (it is gentler on average: root-mean-square height about 0.3 AMP,
    -- against 0.44 for "waves")
    local m = 0
    for i = -400, 400 do for j = -80, 80 do
      local x, z, h = i * 0.12, j * 0.12, 0
      for _, w in ipairs(WAVES) do h = h + w.a * math.sin(w.kx * x + w.kz * z + w.ph) end
      m = math.max(m, math.abs(h))
    end end
    for _, w in ipairs(WAVES) do w.a = w.a / m end
  elseif TERRAIN == "logs" or TERRAIN == "steps" then
    local list, u = {}, -60
    local gap = (TERRAIN == "logs") and { 1.5, 2.5 } or { 2, 3 }
    while u < 60 do               -- (in units of BUMP, along x, both ways from 0)
      list[#list + 1] = { u = u, ang = math.rad(-15 + 30 * trand()) }
      u = u + gap[1] + gap[2] * trand()
    end
    if TERRAIN == "logs" then RIDGES = list else LEDGES = list end
    ANG_COS, ANG_SIN = 1, 0
    for _, l in ipairs(list) do ANG_COS, ANG_SIN = math.min(ANG_COS, math.cos(l.ang)), math.max(ANG_SIN, math.abs(math.sin(l.ang))) end
  end
end
makeTerrain()
-- the first of a list of logs or steps (in order along x) at u or beyond
local function firstFrom(list, u)
  local lo, hi = 1, #list + 1
  while lo < hi do
    local m = math.floor((lo + hi) / 2)
    if list[m].u < u then lo = m + 1 else hi = m end
  end
  return lo
end
-- the ground's shape: its height at (x, z) for bumps 1 cm high (the
-- height is AMP times this). A log or step further along x than W from
-- the point can't reach it (W allows for its angle and the point's
-- distance across the way, with room to spare), so only the near ones are
-- looked at: each gives what it gave when all were, and the steps behind
-- the point are counted, not looked at.
local function shapeAt(x, z)
  if TERRAIN_MIRROR then z = -z end   -- (the same ground mirrored left for right: every terrain)
  if WAVES then
    local X, Z, h = x / BUMP, z / BUMP, 0
    for _, w in ipairs(WAVES) do h = h + w.a * math.sin(w.kx * X + w.kz * Z + w.ph) end
    return h
  elseif RIDGES then
    local X, Z, h = x / BUMP, z / BUMP, 0
    local W = (0.25 + math.abs(Z) * ANG_SIN) / ANG_COS + 1e-3
    for k = firstFrom(RIDGES, X - W), #RIDGES do
      local r = RIDGES[k]
      if r.u > X + W then break end
      local d = (X - r.u) * math.cos(r.ang) + Z * math.sin(r.ang)   -- across the ridge
      if math.abs(d) < 0.25 then h = math.max(h, math.cos(d * 2 * math.pi) ^ 2) end
    end
    return h
  elseif LEDGES then
    local X, Z = x / BUMP, z / BUMP
    local W = math.abs(Z) * ANG_SIN / ANG_COS + 1e-3
    local k0 = firstFrom(LEDGES, X - W)
    local level = (k0 - 1) % 2                  -- (every step behind: up and down by turns)
    for k = k0, #LEDGES do
      local l = LEDGES[k]
      if l.u > X + W then break end
      if (X - l.u) * math.cos(l.ang) + Z * math.sin(l.ang) > 0 then level = 1 - level end
    end
    return level
  end
  local r = 22 / BUMP
  -- (TERRAIN_STRAIGHT, a test: the waves turned 14 degrees, so the troughs of
  -- their second term -- the long ones nearly along the walk -- run straight
  -- along x, the way the test track walks)
  if TERRAIN_STRAIGHT then
    local c, s = math.cos(math.rad(14.04)), math.sin(math.rad(14.04))
    x, z = x * c - z * s, x * s + z * c
  end
  return 0.5 * math.sin((x * 0.19 + z * 0.13) * r) +
         0.3 * math.sin((x * 0.07 - z * 0.28) * r + 1.7) +
         0.2 * math.sin((x * 0.34 + z * 0.045) * r + 4.1)
end
local function terrainHeight(x, z) return AMP * shapeAt(x, z) end

-- the terrain's cells: about a sixth of the shortest wavelength (4 cm
-- at BUMP 22), so short bumps stay round. That is (22 / BUMP)^2 times
-- as many triangles: at BUMP 11, four times as many (500,000), which
-- takes longer to build and to draw.
local CELL, NX, NZ
local X0, Z0 = -ARENA_X / 2, -ARENA_Z / 2
local function setCells()
  CELL = CELL_SET or math.max(2, math.min(8, BUMP / 5.5))
  NX, NZ = math.floor(ARENA_X / CELL), math.floor(ARENA_Z / CELL)
end
setCells()

-- the ground's shape (shapeAt) at every corner of the cells and in the
-- middle of every cell (and of the ring of cells round them, for the
-- colours' slopes), each worked out once: the triangles that meet at a
-- corner, and the cells next to one another, share them (they were worked
-- out up to six times each)
local function groundShape()
  local corner, middle = {}, {}
  for i = 0, NX do
    local x, n = X0 + i * CELL, i * (NZ + 1)
    for j = 0, NZ do corner[n + j + 1] = shapeAt(x, Z0 + j * CELL) end
  end
  for i = -1, NX do
    local x, n = X0 + (i + 0.5) * CELL, (i + 1) * (NZ + 2)
    for j = -1, NZ do middle[n + j + 2] = shapeAt(x, Z0 + (j + 0.5) * CELL) end
  end
  return { corner = corner, middle = middle }
end

-- everything the room adds, to take it all down again for a rebuild (the
-- ground and walls kept apart from the walkers, so the test track can put
-- another walker on the same ground without building the ground again)
local roomObjects, roomConstraints, groundObjects = {}, {}, {}
local building              -- (the walker being built: its parts listed with it too, so it can be taken out alone)
local function addObject(o)
  v:add(o)
  roomObjects[#roomObjects + 1] = o
  if building then building.objects[#building.objects + 1] = o end
  return o
end
local function addGround(o)
  v:add(o)
  groundObjects[#groundObjects + 1] = o
  return o
end

-- meadow colours: grass greener in the hollows and drier on the tops,
-- browner where it is steep, with patches of bare earth
local function noise(i, j, k)
  local s = math.sin(i * 12.9898 + j * 78.233 + (k or 0) * 37.719) * 43758.5453
  return s - math.floor(s)
end
local function clamp(c) return math.max(0, math.min(255, math.floor(c + 0.5))) end
local function mix(a, b, t) return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t } end
local GRASS, GRASS_DRY, DIRT, DIRT_DARK = { 58, 112, 38 }, { 128, 132, 58 }, { 128, 92, 56 }, { 92, 64, 40 }
local groundNow              -- (groundShape's, for the ground standing now)
local function cellColour(i, j)
  local x, z = X0 + (i + 0.5) * CELL, Z0 + (j + 0.5) * CELL
  local middle = groundNow.middle
  local function h(a, b) return AMP * middle[(a + 1) * (NZ + 2) + b + 2] end   -- (cell a, b's middle)
  local y = h(i, j) / math.max(AMP, 1e-6)
  local slope = (math.abs(h(i + 1, j) - h(i - 1, j)) + math.abs(h(i, j + 1) - h(i, j - 1))) / CELL
  local patch = math.sin(x * 0.011 + 1.3) + math.sin(z * 0.013 - 0.4) + 0.6 * math.sin((x + z) * 0.024)
  local t = math.max(0, math.min(1, (patch - 0.9) * 2.5))
  local c = mix(mix(GRASS, GRASS_DRY, math.max(0, math.min(1, y * 0.4 + 0.3))), DIRT, t)
  c = mix(c, DIRT_DARK, math.min(0.5, slope * 0.8))
  local k = 0.93 + 0.14 * noise(i, j)
  return clamp(c[1] * k), clamp(c[2] * k), clamp(c[3] * k)
end
-- a cell's two triangles (the second a shade darker, so the mesh reads)
local function paintCell(i, j, r, g, b)
  local t = 2 * (i * NZ + j)
  floor:setTriangleColor(t, r, g, b)
  floor:setTriangleColor(t + 1, clamp(r * 0.97), clamp(g * 0.97), clamp(b * 0.97))
end

local WALL_H, WALL_T = 20, 10

local function buildTerrain()
  setCells()
  local shape = groundShape()
  groundNow = shape
  floor = Terrain()
  local P = {}   -- (each corner once, shared by the triangles that meet there)
  for i = 0, NX do
    local x, n = X0 + i * CELL, i * (NZ + 1)
    for j = 0, NZ do P[n + j + 1] = btVector3(x, AMP * shape.corner[n + j + 1], Z0 + j * CELL) end
  end
  for i = 0, NX - 1 do
    local a, b = i * (NZ + 1), (i + 1) * (NZ + 1)
    for j = 1, NZ do
      floor:addTriangle(P[a + j], P[a + j + 1], P[b + j])
      floor:addTriangle(P[b + j], P[a + j + 1], P[b + j + 1])
    end
  end
  P = nil
  floor:build()
  floor.col = "#5a7a32"
  floor.friction = 0.8
  addGround(floor)
  for i = 0, NX - 1 do
    for j = 0, NZ - 1 do paintCell(i, j, cellColour(i, j)) end
  end

  -- walls round the arena: low stone blocks
  for side = 0, 3 do
    -- (sides 0 and 2 run along x, at z = +-; 1 and 3 along z, at x = +-)
    local len = ((side % 2 == 0) and ARENA_X or ARENA_Z) + 2 * WALL_T
    local wall = Cube((side % 2 == 0) and len or WALL_T, WALL_H, (side % 2 == 0) and WALL_T or len, 0)
    local off = ((side % 2 == 0) and ARENA_Z or ARENA_X) / 2 + WALL_T / 2
    local x = (side == 1) and off or (side == 3) and -off or 0
    local z = (side == 0) and off or (side == 2) and -off or 0
    wall.pos = btVector3(x, WALL_H / 2 - AMP, z)
    wall.col = (side % 2 == 0) and "#8a8378" or "#827b70"
    wall.friction = 0.5
    addGround(wall)
  end
end

-- ---------------------------------------------------------------------
-- the walkers
--
-- stride: the length (along its heading) of its feet's path, at full
--   size, measured with its body held still in the air and its cranks
--   turned slowly (the mean over its feet). The scale is STRIDE /
--   stride. Measured the same way, every build's foot path matches
--   Walking_Linkages.lua's (and the linkage reference's) duty, lift and
--   flatness. (Four diag builds -- Chebyshev, Chebyshev-Spears, Hoecken
--   4-bar and Hoecken-Spears 4-bar diag -- had their stride recorded
--   10-24% too long, so they were built 9-19% too small, with lower
--   lift; the "different angle" once blamed for their lower lift was
--   that. Now each walks the 15 cm stride on its guides cousin's path.)
-- chassis: the build options that give it the room's chassis, so that
--   only its linkage differs from the others': body clearance CLEARANCE
--   (its body's lowest point above flat ground, walking), front-to-back
--   spacing BASE (between the middles of its front and back feet's
--   paths) and side-to-side width WIDTH (outer foot edge to outer foot
--   edge). linkageSpacing and cube_d are its own file's sliders;
--   bodyRaise is the room's own option (../Walkers_For_Room/), which
--   lengthens its pendants -- or, with no pendant, moves its body --
--   without changing its foot path. Worked out from measurements at
--   bodyRaise 0 and its default spacing and width; each of the three is
--   linear in its option. Jansen and Klann take CLEARANCE only (their
--   rows of legs can't come closer than about 1.8 strides without
--   colliding, and their width is fixed); the two 2-leg Spears, with a
--   single column of legs, keep their own chassis.
-- advance: how far it would go per crank turn if its feet never slipped
--   (cm, at the room's stride; measured with its body held still in the
--   air, cranks turned slowly and in step: at each moment its lowest foot
--   is the one standing, and the body moves as fast as that foot sweeps
--   back). Its crank speed is 2 pi FLAT_SPEED / advance, so that every
--   walker would cross flat ground at the same speed. Measured again 24
--   October 2026 in trot (guides for the plated builds, outside braces for
--   the diag builds, ankles on, each scaled to exactly one crank turn;
--   Chebyshev-Spears, Hoecken-Spears 4-bar and duty 85 diag with their
--   pendants free, since held their cranks fell behind in the sweep:
--   handover/tools/advtrot.py); a guides build and its diag cousin share
--   the mean of theirs (they agree within 0.7%), so their cranks turn alike.
-- fixed: its own physics step; the room steps at FIXED, so its motors'
--   impulse (applied once per step) is scaled by FIXED / fixed
-- lift: how its build is told about the bumps -- "groundTop" (the
--   highest the ground gets) or "terrainLift" (how much to lift it)
-- forward: the direction it walks in its own frame (+1: +x, -1: -x)
-- opts: its standalone file's slider defaults (its crank speed, though,
--   is set by its advance: see addWalker)
-- solverIterations: its joints are solved with this many solver
--   iterations instead of the world's 10, as its standalone file does for
--   the whole world (v:setSolverIterations(40) -- its notes: at 10 its
--   rocking roughly doubles). Here it is set on its own joints only, so
--   the others keep the 10 their own files use.
-- railed: its body is held to move only along its own heading (the
--   balanced Spears' fix for a sideways drift); it turns only in right
--   angles, and the hold is put back along its new heading after each
-- ---------------------------------------------------------------------

-- wide: its chassis for WIDE (its body depth, giving a 38 cm stance)
-- look: how its body is marked, so each walker can be told at a glance
--   (see README.md, Telling the walkers apart): code is drawn on top
--   of its body -- its linkage's inventor(s) (J Jansen, K Klann, C
--   Chebyshev, H Hoecken, S Spears; "-S" a linkage Spears changed), then
--   its number of bars, S for a slider; colour is its linkage's; spears
--   puts a gold rim round its body; diag draws a line across it
local RED, PURPLE, BLUE, MAGENTA, WHITE, GOLD = "#D62828", "#7B2CBF", "#1F6FEB", "#E5007E", "#F2F2F2", "#FFC300"

local WALKERS = {
  { name = "Jansen", bodyShift = -5.94, frame = { length = 49.4, x = 1.74 }, planes = { crank = 1, rodJ = 2, triG = 1, rodK = 3, rodC = 2, rodF = 2, triJ4 = 1 }, look = { code = "J 8", colour = RED, spears = false, diag = false }, wide = { cube_d = 111.366 }, advance = 27.97, parts = "Jansen_6Leg_parts.lua", stride = 67.908, chassis = { bodyRaise = -33.430, rowSpacing = 158.44, cube_d = 114.8 }, fixed = 1 / 240, lift = "groundTop", forward = -1,
    opts = { speed = 2.5, rows = 2, rowPhase = 0, sidePhase = 180, hingeCFM = 0 } },
  { name = "Klann", bodyShift = -29.44, frame = { length = 49.8, x = 25.05 }, planes = { crank = 1, triA = 2, rockerLower = 1, triB = 3, rockerUpper = 1 }, look = { code = "K 6", colour = PURPLE, spears = false, diag = false }, wide = { cube_d = 102.634 }, advance = 29.71, parts = "Klann_6Leg_parts.lua", stride = 70.619, chassis = { bodyRaise = 12.356, rowSpacing = 164.79, cube_d = 129.8 }, fixed = 1 / 240, lift = "groundTop", forward = 1,
    opts = { speed = 2.5, rows = 2, rowPhase = 0, sidePhase = 180, hingeCFM = 0 } },
  { name = "Chebyshev", bodyShift = 5.04, frame = { length = 47.4, x = -5.04 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "C 4", colour = BLUE, spears = false, diag = false }, wide = { cube_d = 6.848 }, brace = { gap = 1.03 }, advance = 25.46, parts = "Chebyshev_normal_parts.lua", stride = 4.712, chassis = { bodyRaise = -0.239, linkageSpacing = 10.995, cube_d = 0.5 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 50, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Chebyshev diag", bodyShift = 5.04, frame = { length = 47.4, x = -5.04 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "C 4", colour = BLUE, spears = false, diag = true }, wide = { cube_d = 6.839 }, brace = { gap = 1.83, diag = true, rise = 10 }, advance = 25.46, parts = "Chebyshev_diag_parts.lua", stride = 4.7057, chassis = { bodyRaise = -0.778, linkageSpacing = 10.981, cube_d = 5.029 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 140, linkageSpacing = 10, motorSpeed = 3.0 } },
  { name = "Chebyshev-Spears", bodyShift = 3.36, frame = { length = 43.5, x = -3.36 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "C-S 4", colour = BLUE, spears = true, diag = false }, wide = { cube_d = 15.221 }, brace = { gap = 0.94 }, advance = 18.60, parts = "Chebyshev_Spears_normal_parts.lua", stride = 10.473, chassis = { bodyRaise = 3.296, linkageSpacing = 24.436, cube_d = 8.131 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180 } },
  { name = "Chebyshev-Spears diag", bodyShift = 3.42, frame = { length = 43.5, x = -3.42 }, planes = { crank = 1, coupler = 3, rocker = 2, pendant = 4 }, look = { code = "C-S 4", colour = BLUE, spears = true, diag = true }, wide = { cube_d = 14.245 }, brace = { gap = 1.60, diag = true, rise = 10 }, advance = 18.60, parts = "Chebyshev_Spears_diag_parts.lua", stride = 10.4745, chassis = { bodyRaise = 1.722, linkageSpacing = 24.441, cube_d = 5.209 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6 } },
  { name = "Hoecken 4-bar", bodyShift = 5.52, frame = { length = 47.8, x = -5.52 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "H 4", colour = MAGENTA, spears = false, diag = false }, wide = { cube_d = 8.001 }, brace = { gap = 3.22 }, advance = 25.67, parts = "Hoecken_normal_parts.lua", stride = 5.505, chassis = { bodyRaise = 1.319, linkageSpacing = 12.845, cube_d = 4.419 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 10, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken slider", bodyShift = -0.28, frame = { length = 41.0, x = 0.28 }, look = { code = "H 2S", colour = WHITE, spears = false, diag = false }, wide = { cube_d = 12.958 }, brace = { gap = 6.54 }, advance = 24.67, parts = "Hoecken_slider_parts.lua", stride = 8.378, chassis = { bodyRaise = 2.692, linkageSpacing = 19.549, cube_d = 2.0 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  -- (footTips: its feet's ends turned up, a builder's tweak, as its diag build's -- handover section 4g)
  { name = "Hoecken-Spears slider", footTips = { length = 1.0, angle = 30 }, bodyShift = -0.32, frame = { length = 41.0, x = 0.32 }, look = { code = "H-S 2S", colour = WHITE, spears = true, diag = false }, wide = { cube_d = 13.037 }, brace = { gap = 3.02 }, advance = 18.31, parts = "Hoecken_Spears_slider_parts.lua", stride = 8.4291, chassis = { bodyRaise = 2.558, linkageSpacing = 19.641, cube_d = 3.656 }, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Spears 4-bar", bodyShift = 19.44, frame = { length = 59.9, x = -19.44 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 1 }, look = { code = "S 4", colour = GOLD, spears = false, diag = false }, wide = { cube_d = 13.651 }, advance = 26.58, parts = "Spears_4Bar_4Leg_parts.lua", stride = 8.324, chassis = { bodyRaise = -9.367, linkageSpacing = 19.423, cube_d = 9.467 }, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, linkageSpacing = 20, speed = 2.6 } },
  -- (linkages of Chebyshev-Spears' kind, built by its file with other
  -- link lengths: see README.md)
  { name = "Hoecken-Spears 4-bar", bodyShift = 3.80, frame = { length = 43.8, x = -3.80 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "H-S 4", colour = MAGENTA, spears = true, diag = false }, wide = { cube_d = 14.582 }, brace = { gap = 1.00 }, advance = 19.68, parts = "Chebyshev_Spears_normal_parts.lua", stride = 10.0334, chassis = { bodyRaise = 3.149, linkageSpacing = 23.411, cube_d = 7.05 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180,
             geometry = { a = 1.875, g = 2.6138, h = 5.8331, leg = 5.8331, legAngle = 90, groundAngle = -45 } } },
  { name = "Hoecken-Spears 4-bar duty 85", bodyShift = 2.97, frame = { length = 44.7, x = -2.97 }, planes = { crank = 1, coupler = 3, rocker = 2, pendant = 4 }, look = { code = "H-S 4", colour = MAGENTA, spears = true, diag = false }, wide = { cube_d = 11.381 }, brace = { gap = 1.12 }, advance = 17.21, parts = "Chebyshev_Spears_normal_parts.lua", stride = 8.3680, chassis = { bodyRaise = -0.907, linkageSpacing = 19.525, cube_d = 4.0 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180,
             geometry = { a = 1.875, g = 2.1842, h = 2.8129, leg = 2.8129, legAngle = 39.80, groundAngle = -20.14 } } },
  { name = "Spears 2-leg", look = { code = "S 4", colour = GOLD, spears = false, diag = false }, twoLeg = true, parts = "Spears_4Bar_2Leg_parts.lua", stride = 8.324, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8 } },
  { name = "Spears 2-leg balanced", look = { code = "S 4", colour = GOLD, spears = false, diag = false }, twoLeg = true, parts = "Spears_4Bar_2Leg_Balanced_parts.lua", stride = 8.335, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 20, cubeMass = 65, speed = 3.8, barLen = 13, tipMass = 70 }, railed = true, solverIterations = 40 },
}
-- EXTRA_WALKERS: more entries like these, added for experiments (set
-- before running this file)
for _, spec in ipairs(EXTRA_WALKERS or {}) do WALKERS[#WALKERS + 1] = spec end

-- the 2-leg Spears are left out unless TWO_LEGS is set (a side experiment:
-- two legs can't be compared fairly with four)
if not TWO_LEGS then
  for i = #WALKERS, 1, -1 do if WALKERS[i].twoLeg then table.remove(WALKERS, i) end end
end

-- ---------------------------------------------------------------------
-- moving a whole walker rigidly: every body turned about a vertical axis
-- through (cx, cz) by yaw radians, then moved by (dx, dy, dz). Hinges
-- are fixed in the bodies' own frames, so a rigid move leaves every
-- joint as it was. Velocities are turned too.
-- ---------------------------------------------------------------------

local function moveWalker(w, cx, cz, yaw, dx, dy, dz)
  local c, s = math.cos(yaw), math.sin(yaw)
  local qs, qc = math.sin(yaw / 2), math.cos(yaw / 2)
  for _, o in ipairs(w.bodies) do
    local b = o.body
    local vx, vy, vz = getVelXYZ(o)
    setVelXYZ(o, c * vx + s * vz, vy, -s * vx + c * vz)
    local ax, ay, az = getAngVelXYZ(o)
    setAngVelXYZ(o, c * ax + s * az, ay, -s * ax + c * az)
    -- (from the body's physics transform: the drawn one, o.trans, can be
    -- a fraction of a step behind it)
    local t = b:getCenterOfMassTransform()
    local p, q = b:getCenterOfMassPosition(), t:getRotation()
    local rx, rz = p.x - cx, p.z - cz
    local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
    -- (0, qs, 0, qc) * (qx, qy, qz, qw)
    local nq = btQuaternion(qc * qx + qs * qz, qc * qy + qs * qw, qc * qz - qs * qx, qc * qw - qs * qy)
    local nt = btTransform(nq, btVector3(cx + c * rx + s * rz + dx, p.y + dy, cz - s * rx + c * rz + dz))
    b:setCenterOfMassTransform(nt)
    o.trans = nt                         -- (and the drawn one)
    b:activate(true)
  end
end

-- quaternions as four numbers (x, y, z, w): a product, and a vector turned
local function qmul(ax, ay, az, aw, bx, by, bz, bw)
  return aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
         aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz
end
local function qrot(qx, qy, qz, qw, vx, vy, vz)
  local tx, ty, tz = 2 * (qy * vz - qz * vy), 2 * (qz * vx - qx * vz), 2 * (qx * vy - qy * vx)
  return vx + qw * tx + (qy * tz - qz * ty), vy + qw * ty + (qz * tx - qx * tz), vz + qw * tz + (qx * ty - qy * tx)
end

-- STEER (above): each foot's and crank motor's side ("L" or "R") and end
-- (front or not) in the body's frame, as built, and the bias put on
-- (a walker's frame for parts added to it, as built: its body's place and
-- turn; each foot's side ("L" or "R") and end in the body's frame; its
-- weight, its feet's friction, half their track and their soles' height;
-- part() adds a part, turned as its body, at a place in its frame; slider()
-- puts a part on a slider to the body. STEER and SHOES, below)
local function walkerGeom(w, made, opts)
  local G = {}
  local c = w.cube.body:getCenterOfMassPosition()
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local fx, fy, fz = qrot(q:x(), q:y(), q:z(), q:w(), w.forward, 0, 0)   -- the way it walks
  local function place(x, y, z)   -- (right = forward x up)
    local dx, dz = x - c.x, z - c.z
    return (dx * -fz + dz * fx > 0) and "R" or "L", dx * fx + dz * fz > 0
  end
  G.c, G.q, G.place = c, q, place
  G.feet = {}
  for _, o in ipairs(w.bodies) do
    if made[o] == "buildFoot" then
      local p = o.body:getCenterOfMassPosition()
      local side, front = place(p.x, p.y, p.z)
      G.feet[#G.feet + 1] = { o = o, side = side, front = front }
    end
  end
  local cq = btQuaternion(q:x(), q:y(), q:z(), q:w())
  local tot, mu, half, bottom = 0, 0, 0, 1e30   -- (its weight; its feet's friction, half their track, their soles' height)
  for _, o in ipairs(w.bodies) do tot = tot + o.mass end
  if SAME_BODY then tot = w.totalMass end   -- (its body's weight is set after this, below)
  for _, f in ipairs(G.feet) do
    local p = f.o.body:getCenterOfMassPosition()
    local _, ly, lz = qrot(-q:x(), -q:y(), -q:z(), q:w(), p.x - c.x, p.y - c.y, p.z - c.z)
    mu, half, bottom = mu + f.o.body:getFriction() / #G.feet, half + math.abs(lz) / #G.feet, math.min(bottom, ly - FOOT.thick / 2)
  end
  G.cq, G.tot, G.mu, G.half, G.bottom = cq, tot, mu, half, bottom
  function G.part(o, lx, ly, lz)   -- (a part added to the walker, turned as its body, at (lx, ly, lz) in its frame)
    local x, y, z = qrot(q:x(), q:y(), q:z(), q:w(), lx, ly, lz)
    o.trans = btTransform(cq, btVector3(c.x + x, c.y + y, c.z + z))
    o.col = "#C08020"
    addObject(o)
    w.bodies[#w.bodies + 1] = o
    return o
  end
  function G.slider(o, inCube, inPart, lo, hi)   -- (o on a slider to the body, along each frame's x; not turning)
    local sl = btSliderConstraint(w.cube.body, o.body, inCube, inPart, true)
    sl:setLowerLinLimit(lo); sl:setUpperLinLimit(hi)
    sl:setLowerAngLimit(0); sl:setUpperAngLimit(0)
    opts.addConstraint(sl)
    if SOLVER_ITERATIONS then sl:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    return sl
  end
  return G
end

local function steerSetup(w, made, opts)
  local G = walkerGeom(w, made, opts)
  local c, q, place = G.c, G.q, G.place
  local S = { feet = G.feet, motors = {} }
  for _, m in ipairs(w.motors) do
    for _, j in ipairs(w.joints) do
      if rawequal(j[4], m.hinge) then
        local a, b = j[1]:getCenterOfMassPosition(), j[2] and j[2]:getCenterOfMassPosition() or j[1]:getCenterOfMassPosition()
        m.side, m.front = place((a.x + b.x) / 2, 0, (a.z + b.z) / 2)
      end
    end
  end
  -- (in the body's frame: forward is (w.forward, 0, 0), up (0, 1, 0), so
  -- the walker's left is (0, 0, -w.forward); d: the bias's side along z)
  local mech, side, k = STEER.mech, STEER.side, STEER.amount or 1
  local d = -w.forward * ((side == "L") and 1 or -1)
  local cq, tot, mu, half, bottom = G.cq, G.tot, G.mu, G.half, G.bottom
  local part, slider = G.part, G.slider
  if mech == "friction" then
    for _, f in ipairs(S.feet) do
      if f.side == side then f.o.body:setFriction(f.o.body:getFriction() * k) end
    end
  elseif mech == "pair" or mech == "side" then
    for _, m in ipairs(w.motors) do
      local on
      if mech == "pair" then on = (m.side == side) == (m.front == true) else on = (m.side == side) end
      m.group = on and 1 or 2
      if on then m.speed = m.speed * k end
    end
  elseif mech == "ballast" then
    -- a ballast, STEER.mass (default 0.25) of the walker's weight, inside
    -- its body (touching nothing), on a slider across it: its motor pushes
    -- it k cm to that side, against a stop, and holds it there
    local m = (STEER.mass or 0.25) * tot
    local o = part(Cube(4, 2, 4, m), 0, 0, 0)
    o.body:setCollisionFlags(o.body:getCollisionFlags() + 4)
    local h = math.rad(-d * 90) / 2   -- (the slider's x across the body, to that side)
    local fr = btTransform(btQuaternion(0, math.sin(h), 0, math.cos(h)), btVector3(0, 0, 0))
    local sl = slider(o, fr, fr, 0, k)
    sl:setPoweredLinMotor(true); sl:setTargetLinMotorVelocity(10); sl:setMaxLinMotorForce(10 * m * GRAVITY)
    S.note = string.format("ballast %.1f g, %g cm", m, k)
  elseif mech == "drag" then
    -- a drag shoe, k of the walker's weight: a 1.5 cm ball on the ground,
    -- 3 cm out beyond that side's feet (on an arm: the slider's frame), on
    -- a slider that leaves it free up and down but not to turn (so it
    -- slides, not rolls); out there it touches none of the legs, even with
    -- the feet tilted on waves 2
    local r = 1.5
    local m, ly, lz = k * tot, bottom + r, d * (half + FOOT.width / 2 + r + 3)
    local o = part(Sphere(r, m), 0, ly, lz)
    o.body:setFriction(mu)
    local h = math.pi / 4   -- (the slider's x up)
    slider(o, btTransform(btQuaternion(0, 0, math.sin(h), math.cos(h)), btVector3(0, ly, lz)),
      btTransform(btQuaternion(0, 0, math.sin(h), math.cos(h)), btVector3(0, 0, 0)), -30, 30)
    S.note = string.format("shoe %.1f g, %.1f cm to the side", m, math.abs(lz))
  elseif mech == "sole" then
    -- that side's soles k cm thicker: a slab, as wide and long as the foot,
    -- welded under it (as heavy as a quarter of a foot)
    local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
    for _, f in ipairs(S.feet) do
      if f.side == side then
        f.o.body:getAabb(lo, hi)
        local fm = FOOT.mass / 4
        local o = Cube(hi.x - lo.x - 0.08, k, hi.z - lo.z - 0.08, fm)
        o.trans = btTransform(cq, btVector3((lo.x + hi.x) / 2, lo.y + 0.04 - k / 2, (lo.z + hi.z) / 2))
        o.col = "#C08020"
        addObject(o)
        w.bodies[#w.bodies + 1] = o
        o.body:setFriction(f.o.body:getFriction())
        local weld = btFixedConstraint(f.o.body, o.body, f.o.body:getCenterOfMassTransform():inverseTimes(o.body:getCenterOfMassTransform()),
          btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)))
        opts.addConstraint(weld)
        if SOLVER_ITERATIONS then weld:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
      end
    end
  elseif mech == "stiff" or mech == "damp" then
    -- that side's ankle springs (ANKLE_SPRING) k times as stiff, or as damped
    assert(ANKLE_SPRING and w.ankleSprings, "STEER " .. mech .. ": needs ANKLE_SPRING")
    for _, f in ipairs(S.feet) do
      local sp = w.ankleSprings[f.o]
      if f.side == side and sp then
        if mech == "stiff" then sp:setStiffness(5, ANKLE_SPRING.stiffness * k, false)
        else sp:setDamping(5, (ANKLE_SPRING.damping or 0) * k, false) end
      end
    end
  elseif mech == "linkdamp" then
    -- one diagonal pair's links' own damping k (as LINK_DAMP, on that pair
    -- only: the pair whose front foot is on that side); braces left alone
    local n = 0
    for _, o in ipairs(w.bodies) do
      if o.mass > 0 and not rawequal(o, w.cube) and made[o] ~= "buildFoot" and not (made[o] or ""):find("Crossbar") then
        local p = o.body:getCenterOfMassPosition()
        local sd, front = place(p.x, p.y, p.z)
        if (sd == side) == front then o.body:setDamping(k, k); n = n + 1 end
      end
    end
    S.note = n .. " links damped"
  end
  w.steer = S
end

-- SHOES (above): a wheel on each side, always down -- a ball that rolls
-- along the walk, resting on the ground by its own weight (on a joint that
-- leaves it free up and down, so the walker never carries it, and never
-- leans), SHOES.out cm (5) out beyond that side's feet. Rolling, it drags
-- next to nothing; setShoe(w, side) brakes that side's ("L" or "R") and
-- frees the other, setShoe(w, nil) frees both; braked, it skids, and its
-- drag turns the walker toward it.
local function setShoe(w, side)
  if not w.wheels then return end
  for s, wh in pairs(w.wheels) do wh.joint:setMaxMotorForce(5, (s == side) and wh.brake or 0) end
  w.shoeDown = side
end
local function shoesSetup(w, made, opts)
  local G = walkerGeom(w, made, opts)
  local r = SHOES.radius or 1.5
  local m = (SHOES.mass or 0.15) * G.tot
  w.wheels = {}
  for _, side in ipairs({ "L", "R" }) do
    local d = -w.forward * ((side == "L") and 1 or -1)   -- (that side, along the body's z)
    local ly, lz = G.bottom + r, d * (G.half + FOOT.width / 2 + r + (SHOES.out or 5))
    local o = G.part(Sphere(r, m), 0, ly, lz)
    o.body:setFriction(G.mu * (SHOES.grip or 3))   -- (grip: the wheel's friction, times the feet's)
    local j = btGeneric6DofSpring2Constraint(w.cube.body, o.body, btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, ly, lz)),
      btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)))
    j:setLimit(0, 0, 0); j:setLimit(1, -30, 30); j:setLimit(2, 0, 0)   -- (only up and down)
    j:setLimit(3, 0, 0); j:setLimit(4, 0, 0); j:setLimit(5, 1, -1)     -- (turning only about the body's z: rolling along the walk)
    j:enableMotor(5, true); j:setTargetVelocity(5, 0); j:setMaxMotorForce(5, 0)   -- (the brake: off)
    opts.addConstraint(j)
    if SOLVER_ITERATIONS then j:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    w.wheels[side] = { o = o, joint = j, brake = 1e9 }
  end
  setShoe(w, SHOES.down)
end

-- the whole walker turned rigidly by the rotation (rx, ry, rz, rw) about
-- the point (cx, cy, cz), with its velocities turned too
local function rotateWalker(w, cx, cy, cz, rx, ry, rz, rw)
  for _, o in ipairs(w.bodies) do
    local b = o.body
    setVelXYZ(o, qrot(rx, ry, rz, rw, getVelXYZ(o)))
    setAngVelXYZ(o, qrot(rx, ry, rz, rw, getAngVelXYZ(o)))
    local t = b:getCenterOfMassTransform()
    local p, q = b:getCenterOfMassPosition(), t:getRotation()
    local px, py, pz = qrot(rx, ry, rz, rw, p.x - cx, p.y - cy, p.z - cz)
    local nx, ny, nz, nw = qmul(rx, ry, rz, rw, q:x(), q:y(), q:z(), q:w())
    local nt = btTransform(btQuaternion(nx, ny, nz, nw), btVector3(cx + px, cy + py, cz + pz))
    b:setCenterOfMassTransform(nt)
    o.trans = nt
    b:activate(true)
  end
end

-- a railed walker's hold: along x (it may not move in z) or along z
-- (Bullet's linear factor stops a body's velocity *changing* along the
-- held axis; whatever velocity it has that way when the hold goes on
-- would last for ever, so that part is taken away first)
local function setRail(w)
  local h = w.heading
  local vx, vy, vz = getVelXYZ(w.cube)
  if math.abs(math.cos(h)) > 0.5 then
    setVelXYZ(w.cube, vx, vy, 0)
    w.cube.body:setLinearFactor(btVector3(1, 1, 0))
  else
    setVelXYZ(w.cube, 0, vy, vz)
    w.cube.body:setLinearFactor(btVector3(0, 1, 1))
  end
end

local walkers = {}
room = { walkers = walkers, groundAt = terrainHeight }   -- (global, for tests and the command line)
room.setShoe = setShoe   -- (SHOES: for launchers, probes and the keys)
-- room.setReverse(w, on): walker w's cranks run backward (on) or as built:
-- it backs up. They ease through a stop over REVERSE_EASE s (default 1),
-- not all at once, which jolted some walkers (lift 62 diag tipped 22
-- degrees on flat). (The crank lock keeps them in step either way: it
-- compares how far each has turned with the others.)
REVERSE_EASE = REVERSE_EASE or 1
function room.setReverse(w, on)
  if (w.backing or false) == (on or false) then return end
  for _, m in ipairs(w.motors) do m.base = m.base or m.speed end
  w.revK = w.revK or 1                 -- (the cranks' speed now, as a share of as built: 1 to -1)
  w.revGoal = on and -1 or 1
  w.backing = on or nil
end
local function easeReverse(w)          -- (each frame, from preSim)
  if not w.revGoal or w.revK == w.revGoal then return end
  local step = (REVERSE_EASE > 0) and 2 * FRAME / REVERSE_EASE or 2
  w.revK = (w.revGoal > w.revK) and math.min(w.revGoal, w.revK + step) or math.max(w.revGoal, w.revK - step)
  for _, m in ipairs(w.motors) do
    m.speed = m.base * w.revK
    if not LOCK_CRANKS then m.hinge:enableAngularMotor(true, m.speed, math.max(0, (m.impulse or 0) - (m.friction or 0))) end
  end
end
local trackLo, trackHi = btVector3(0, 0, 0), btVector3(0, 0, 0)   -- (the test track's air measure)

-- ---------------------------------------------------------------------
-- marking the bodies (spec.look): the body and its braces painted its
-- linkage's colour (its links cyan, LINK_COLOUR, and its feet dark grey),
-- a gold rim round its top edges for a linkage Spears changed, a line
-- across it for a diag build, and its code in raised letters on top.
-- These are for looks only: bodies that touch nothing and weigh nothing,
-- moved with the walker's body every time the room is drawn.
-- ---------------------------------------------------------------------

local CF_KINEMATIC_OBJECT, CF_NO_CONTACT_RESPONSE = 2, 4

-- black or white, whichever reads better on the colour c ("#rrggbb")
local function codeOf(spec) return spec.look and (spec.look.code .. ", ") or "" end

local function ink(c)
  local r, g, b = tonumber(c:sub(2, 3), 16) / 255, tonumber(c:sub(4, 5), 16) / 255, tonumber(c:sub(6, 7), 16) / 255
  return (0.2126 * r + 0.7152 * g + 0.0722 * b > 0.5) and "#111111" or "#FFFFFF"
end

-- a look-only part of a walker's marking, at (x, y, z) in its body's own
-- frame, turned by the quaternion q (x, y, z, w): a decoration, never in
-- Bullet's world, that bpp moves with the body (placeMarks, v:attach)
local function decor(w, o, col, x, y, z, q)
  o.col = col
  o.decoration = true
  addObject(o)
  w.decor = w.decor or {}
  x = x + (w.frame and w.frame.x or 0)   -- (on its frame, which may sit off its load: BALANCE)
  w.decor[#w.decor + 1] = { o = o, p = { x, y, z }, q = q or { 0, 0, 0, 1 } }
end

-- BAR_MASS: each bar of walker w reweighed, density x its length (cm)
-- + a bolt for each joint on it, its turning inertia scaled with it (so
-- a bar keeps its shape's own spread of mass). A body welded to a bar
-- and under 5% of its weight only draws part of that bar (Chebyshev-
-- Spears' bent coupler): its length counts toward the bar, its weld is
-- no joint, and it keeps the same small share of the bar's new weight.
function setBarMasses(w, barLen, joints, scale)
  local isBar = {}
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 and not rawequal(o, w.cube) and w.madeBy[o] ~= "buildFoot" then isBar[#isBar + 1] = o end
  end
  local function find(b)
    if not b then return nil end
    for _, o in ipairs(w.bodies) do if o.body == b then return o end end
  end
  local part = {}                        -- drawing-only body -> the bar it draws part of
  local ends = {}
  for _, j in ipairs(joints) do
    local a, b = find(j[1]), find(j[2])
    if rawequal(a, w.cube) then a = nil end
    if rawequal(b, w.cube) then b = nil end
    if j[3] and a and b and a.mass < 0.05 * b.mass then part[a] = b
    elseif j[3] and a and b and b.mass < 0.05 * a.mass then part[b] = a
    else
      if a then ends[a] = (ends[a] or 0) + 1 end
      if b then ends[b] = (ends[b] or 0) + 1 end
    end
  end
  local L = {}
  for _, o in ipairs(isBar) do
    if not part[o] then L[o] = (L[o] or 0) + (barLen[o] or 0) end
  end
  for p, o in pairs(part) do L[o] = (L[o] or 0) + (barLen[p] or 0) end
  local function reweigh(o, m)
    local inv = o.body:getInvInertiaDiagLocal()
    local k = m / o.mass
    o.body:setMassProps(m, btVector3(k / inv.x, k / inv.y, k / inv.z))
    o.body:updateInertiaTensor()
    o.mass = m
  end
  local share = {}
  for p, o in pairs(part) do share[p] = p.mass / o.mass end
  for _, o in ipairs(isBar) do
    if not part[o] then
      assert(barLen[o], w.spec.name .. ": a bar of unknown length")
      reweigh(o, BAR_MASS.density * L[o] + BAR_MASS.bolt * (ends[o] or 0))
    end
  end
  for p, o in pairs(part) do reweigh(p, share[p] * o.mass) end
end

-- LIFT_PCT: each build's lift, its feet's rise over a turn as a share of its
-- stride, % (31 October 2026: sweeps, body held still, one slow crank turn
-- at trot, as run; stride each foot's centre's travel, lift its lowest
-- point's highest minus lowest, both the mean over the feet;
-- handover/tools/liftpct.py). Shown on the body's top right corner.
LIFT_PCT = LIFT_PCT or {
  ["Chebyshev-Spears lift 62"] = 62, ["Chebyshev-Spears lift 62 diag"] = 62, ["Klann"] = 52,
  ["Chebyshev-Spears lift 51"] = 51, ["Chebyshev-Spears lift 51 diag"] = 51, ["Spears 4-bar"] = 37,
  ["Hoecken-Spears 4-bar duty 85"] = 34, ["Hoecken-Spears 4-bar duty 85 diag"] = 34,
  ["Jansen"] = 33, ["Hoecken-Spears slider"] = 33, ["Hoecken-Spears slider diag"] = 33,
  ["Hoecken-Spears 4-bar"] = 33, ["Hoecken-Spears 4-bar diag"] = 33,
  ["Chebyshev-Spears"] = 31, ["Chebyshev-Spears diag"] = 31,
  ["Hoecken slider"] = 25, ["Hoecken slider diag"] = 25,
  ["Hoecken 4-bar"] = 20, ["Hoecken 4-bar diag"] = 20, ["Chebyshev"] = 19, ["Chebyshev diag"] = 19,
}
local function markBody(w, look)
  w.decor = {}
  if not look then return end
  w.cube.col = look.colour
  -- its braces (the plates and bars between its legs) in its colour too,
  -- its links cyan (LINK_COLOUR: a colour no body, pin or ground uses, so
  -- the links show; grey until 8 November) and its feet dark grey
  for _, o in ipairs(w.bodies) do
    if not rawequal(o, w.cube) then
      local by = w.madeBy and w.madeBy[o] or ""
      if by:find("Crossbar") then o.col = look.colour
      elseif by == "buildFoot" then o.col = "#3C3C3C"
      else o.col = LINK_COLOUR or "#00C8D7" end
    end
  end
  -- the body's size, from its box as built (still lined up with its axes)
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  w.cube.body:getAabb(lo, hi)
  local m = 0.04                                   -- (the box's collision margin)
  local X, H, Z = hi.x - lo.x - 2 * m, hi.y - lo.y - 2 * m, hi.z - lo.z - 2 * m
  local hy = H / 2
  local e = 0.05                                   -- standing just proud of the body, so it shows
  local top = hy + e
  if look.spears then
    -- the gold rim: four strips round the top edges, part way down the sides
    local r, k = math.max(0.07 * math.min(X, Z), 0.8), math.max(0.6 * H, 0.8)   -- (0.2 until 31 October: thinner, to leave the corners room)
    for _, sz in ipairs({ -1, 1 }) do
      decor(w, Cube(X + 2 * e, k, r, 0), GOLD, 0, top - k / 2, sz * (Z / 2 + e - r / 2))
    end
    for _, sx in ipairs({ -1, 1 }) do
      decor(w, Cube(r, k, Z + 2 * e, 0), GOLD, sx * (X / 2 + e - r / 2), top - k / 2, 0)
    end
  end
  -- the letters (the linkage's family: C, C-S, H, H-S, J, K, S, S+) in the
  -- middle, and in the corners as the letters read: its links top left
  -- (from its code, "C-S 4" -> 4), its lift top right (LIFT_PCT), a
  -- triangle bottom left on a diag build (braces joining diagonal legs), and
  -- G bottom right on a build held by guides (not really there: not for
  -- demos). Raised shapes lying on the top, made by OpenSCAD and kept in
  -- bpp's cache; if OpenSCAD can't make them, the walker goes without, and
  -- the output pane says why.
  local letters, links = look.code:match("^(%S+)%s+(%S+)$")
  letters, links = letters or look.code, look.links or links or "4"
  local c = math.sqrt(0.5)
  local up = { -c, 0, 0, c }   -- (turned so the shapes face up: their "up" along -z)
  -- (they read along the body's +x; a walker that walks toward its -x end --
  -- every one but Klann, forward = -1 -- has them turned half round, so
  -- they read the same way along the walk for every walker)
  local flip = (w.forward or 1) < 0
  if flip then up = { 0, c, c, 0 } end   -- (the same, then half a turn about the vertical)
  local function shape(scad, x, z, what)
    local ok, o = pcall(OpenSCAD, "linear_extrude(height = 0.3) " .. scad .. ";", 0, false)
    if not ok then print("walker room: no " .. what .. " on " .. w.spec.name .. "'s body (" .. tostring(o) .. ")"); return end
    if flip then x, z = -x, -z end
    decor(w, o, ink(look.colour), x, top + 0.1, z, up)
  end
  local function text(t, size, h, v)
    return string.format([[text("%s", size = %.3f, font = "Liberation Sans:style=Bold", halign = "%s", valign = "%s")]], t, size, h, v)
  end
  local inset = (look.spears and math.max(0.07 * math.min(X, Z), 0.8) or 0) + 0.6   -- (inside the gold rim)
  local Xi, Zi = X - 2 * inset, Z - 2 * inset
  local cs = 0.2 * Zi                                                                -- corner marks' size
  -- the letters as big as fit between the corners (a corner mark about 2.5 x its size wide)
  local size = math.min(0.75 * Zi, (Xi - 5 * cs - 2) / (0.75 * #letters))
  shape(text(letters, size, "center", "center"), 0, 0, "letters")
  local xl, xr, zt, zb = -X / 2 + inset, X / 2 - inset, -Z / 2 + inset, Z / 2 - inset
  shape(text(links, cs, "left", "top"), xl, zt, "links")
  local lift = LIFT_PCT[w.spec.name]
  if lift then shape(text(string.format("%d%%", lift), cs, "right", "top"), xr, zt, "lift") end
  if look.diag then
    local t = 1.5 * cs
    shape(string.format("polygon([[0, 0], [%.3f, 0], [0, %.3f]])", t, t), xl, zb, "diag mark")
  end
  if w.unbraced and w.guides then shape(text("G", cs, "right", "bottom"), xr, zb, "G") end
end

-- each marking part to where the body now is, and from then on bpp keeps
-- it there (v:attach: placed before each drawing and export)
local function placeMarks(w)
  for _, d in ipairs(w.tips or {}) do   -- (a foot's tips, drawn on it: FOOT_TIPS)
    if d.o then
      local t = d.foot.body:getCenterOfMassTransform()
      local p, q = d.foot.body:getCenterOfMassPosition(), t:getRotation()
      local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
      local dx, dy, dz = qrot(qx, qy, qz, qw, d.p[1], d.p[2], d.p[3])
      local rx, ry, rz, rw = qmul(qx, qy, qz, qw, d.q[1], d.q[2], d.q[3], d.q[4])
      d.o.trans = btTransform(btQuaternion(rx, ry, rz, rw), btVector3(p.x + dx, p.y + dy, p.z + dz))
      v:attach(d.o, d.foot)
    end
  end
  if not w.decor or #w.decor == 0 then return end
  local t = w.cube.body:getCenterOfMassTransform()
  local p, q = w.cube.body:getCenterOfMassPosition(), t:getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  for _, d in ipairs(w.decor) do
    local dx, dy, dz = qrot(qx, qy, qz, qw, d.p[1], d.p[2], d.p[3])
    local rx, ry, rz, rw = qmul(qx, qy, qz, qw, d.q[1], d.q[2], d.q[3], d.q[4])
    d.o.trans = btTransform(btQuaternion(rx, ry, rz, rw), btVector3(p.x + dx, p.y + dy, p.z + dz))
  end
  for _, d in ipairs(w.decor) do v:attach(d.o, w.cube) end
end

local function addWalker(spec, x, z, heading)
  -- its feet's tips: FOOT_TIPS for every walker, or its own spec.footTips (a builder's tweak for that walker;
  -- FOOT_TIPS_OFF, a test, leaves them off)
  local tips = FOOT_TIPS or ((not FOOT_TIPS_OFF) and spec.footTips) or nil
  local flatLen = tips and (FOOT.length - 2 * tips.length * math.cos(math.rad(tips.angle))) or nil
  local W = dofile(WALKERS_DIR .. spec.parts)
  local scale = STRIDE / spec.stride
  local w = { spec = spec, scale = scale, bodies = {}, constraints = {}, objects = {} }
  building = w
  local opts = {}
  for k, val in pairs(spec.opts) do opts[k] = val end
  -- its chassis for the room (see `chassis` above); CHASSIS_TEST, for
  -- tests, overrides it
  for k, val in pairs(spec.chassis or {}) do opts[k] = val end
  if WIDE then for k, val in pairs(spec.wide or {}) do opts[k] = val end end
  local refit = LINK_WIDTH and not WIDTH_REFITS_OFF[spec.name]   -- (LINK_WIDTH's refits, unless WIDTH_REFITS_OFF)
  local wfit = refit and WIDTH_FIT[spec.name]   -- (see WIDTH_FIT)
  if wfit then
    if wfit.bodyRaise then opts.bodyRaise = wfit.bodyRaise end
    if wfit.cube_d and WIDE then opts.cube_d = wfit.cube_d end
  end
  -- (with FOOT_POINT, its legs moved out so the outer edges of its points
  -- are as far apart as a flat foot's outer edges were: a flat foot reaches
  -- FOOT.width / 2 past its leg, a point FOOT_POINT, and each side moves
  -- out by half the change in body depth)
  if WIDE and FOOT_POINT and SAME_FEET and opts.cube_d then
    opts.cube_d = opts.cube_d + (FOOT.width - 2 * FOOT_POINT) / scale
  end
  for k, val in pairs(CHASSIS_TEST or {}) do opts[k] = val end
  if SAME_FEET then
    opts.foot = FOOT
    if flatLen then opts.foot = { length = flatLen, width = FOOT.width, thick = FOOT.thick, mass = FOOT.mass } end
    if FOOT_POINT then opts.foot = { length = 1.4 * FOOT_POINT, width = 1.4 * FOOT_POINT, thick = 1.4 * FOOT_POINT, mass = FOOT.mass } end   -- (the box hidden inside the ball)
    if FOOT_ROD then opts.foot = { length = 1.4 * FOOT_ROD, width = FOOT.width, thick = 1.4 * FOOT_ROD, mass = FOOT.mass } end   -- (the box hidden inside the rod)
  end
  local outside = DIAG_OUTSIDE and spec.brace and spec.brace.diag and (refit and OUTSIDE_FIT_W or OUTSIDE_FIT)[spec.name]
  -- (OUTSIDE_FIT_TEST, a test: { [name] = { top =, bottom = } } puts that build's braces there instead, each
  -- as an OUTSIDE_FIT entry's top or bottom; the other one stays its own)
  if outside and OUTSIDE_FIT_TEST and OUTSIDE_FIT_TEST[spec.name] then
    local t = OUTSIDE_FIT_TEST[spec.name]
    outside = { bar = outside.bar, extUp = outside.extUp, top = t.top or outside.top, bottom = t.bottom or outside.bottom }
  end
  local low = not outside and DIAG_LOW and spec.brace and spec.brace.diag
  local arched = not outside and not low and DIAG_ARCH and spec.brace and spec.brace.diag and spec.brace.rise
  if outside then
    local vfits = refit and OUTSIDE_V_FIT_W or OUTSIDE_V_FIT
    if OUTSIDE_V and vfits[spec.name] then
      local v = vfits[spec.name]
      outside = { bar = outside.bar, extUp = outside.extUp, top = outside.top,
                  bottom = { yRel = outside.bottom.yRel, runFront = v.runFront, runBack = v.runBack, rise = v.rise } }
    end
    opts.outside = outside
    opts.forward = spec.forward                 -- (front and back as built)
    opts.extUp = (outside.extUp or 0) / scale   -- (its pendants as long as its guides cousin's, or as its fit says; the files take their own units)
  elseif low then
    opts.lowBrace = DIAG_LOW                    -- (cm)
    opts.lowBoth = DIAG_LOW_BOTH
  elseif arched then
    opts.archRise = spec.brace.rise             -- (cm)
  elseif BRACE_CLEARANCE and spec.brace then
    local d = math.max(0, BRACE_CLEARANCE - spec.brace.gap)
    if spec.brace.diag then opts.braceRaise = d else opts.braceCut = d end
  end
  local pfits = refit and PLATE_FIT_W or PLATE_FIT
  if PLATE_LOW and pfits[spec.name] then opts.plate = { height = 1.074, drop = pfits[spec.name].drop } end
  opts.ankle = ANKLES or (ANKLE_SPRING and true)
  if DIAG_GIVE then opts.diagGive = DIAG_GIVE end
  if DIAG_EXT_UP and spec.brace and spec.brace.diag then opts.extUp = DIAG_EXT_UP end   -- (a test: see the diag files' opts.extUp)
  if PLANE_GAP then opts.planeGapCm = PLANE_GAP; opts.planeOf = opts.planeOf or (wfit and wfit.planes) or spec.planes end
  if BALANCE and spec.bodyShift then opts.bodyShift = (wfit and wfit.bodyShift) or spec.bodyShift end
  if BALANCE and spec.frame then
    -- its body as a frame spanning its leg mounts, carrying its load at the
    -- balance point: one body, its centre of mass where the load is and its
    -- box (what is drawn and what can bump into things) spec.frame.x cm off
    -- it along the walk, spec.frame.length cm long
    opts.bodyFrame = function(cube)
      local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
      cube.body:getAabb(lo, hi)
      local L, H, D = spec.frame.length, hi.y - lo.y - 0.08, hi.z - lo.z - 0.08
      local c = Cube(0.01, 0.01, 0.01, cube.mass)   -- (its own drawing hidden inside the frame's)
      c.col = cube.col
      local shape = btCompoundShape(true)
      local fx = (wfit and wfit.bodyShift) and -wfit.bodyShift or spec.frame.x   -- (frame.x = -bodyShift)
      -- (BODY_LOAD, a test: { dx =, dy = } cm, or a table of those by name: the load moved that far in the
      -- body's own frame, its box left where it was)
      local bl = BODY_LOAD and (BODY_LOAD[spec.name] or (BODY_LOAD.dx and BODY_LOAD) or BODY_LOAD.dy and BODY_LOAD) or nil
      local ldx, ldy = bl and (bl.dx or 0) or 0, bl and (bl.dy or 0) or 0
      shape:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(fx - ldx, -ldy, 0)), btBoxShape(btVector3(L / 2, H / 2, D / 2)))
      local p = cube.pos
      c.body = btRigidBody(cube.mass, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(p.x + ldx, p.y + ldy, p.z))), shape, btVector3(1, 1, 1))
      c.damp_lin, c.damp_ang = cube.damp_lin, cube.damp_ang   -- (what its file gave the body so far)
      c.friction, c.restitution = cube.friction, cube.restitution
      w.frame = { x = fx - ldx, L = L, H = H, D = D }
      return c
    end
  end
  if LINK_THICK then opts.rodThickCm = LINK_THICK end
  local unbraced = UNBRACED == true or (type(UNBRACED) == "table" and UNBRACED[spec.name])
  if unbraced then opts.noBraces = true; opts.legGuides = true end
  w.unbraced = unbraced
  if GAIT and (spec.opts.rows or spec.parts:find("Spears_4Bar_4Leg") or unbraced) then opts.phases = GAIT end
  -- the room's crank speed (each walker names it its own way)
  local crank = CRANK or (spec.advance and 2 * math.pi * FLAT_SPEED / spec.advance) or 2.6
  local k = (type(CRANK_SCALE) == "table") and CRANK_SCALE[spec.name] or CRANK_SCALE
  if type(k) == "number" then crank = crank * k end
  local rev = REVERSE == true or (type(REVERSE) == "table" and REVERSE[spec.name])
  if rev then crank = -crank end
  w.crank = crank
  w.forward = rev and -spec.forward or spec.forward   -- which way along its body it walks
  for _, k in ipairs({ "speed", "leftSpeed", "rightSpeed", "motorSpeed" }) do
    if opts[k] then opts[k] = crank end
  end
  opts.add = function(o)
    addObject(o)
    o.body:setActivationState(4)        -- DISABLE_DEACTIVATION: a sleeping body ignores its motor
    w.bodies[#w.bodies + 1] = o
  end
  opts.addConstraint = function(con)
    v:addConstraint(con)
    w.constraints[#w.constraints + 1] = con
    roomConstraints[#roomConstraints + 1] = con
  end
  opts.scale = scale
  -- gravity: the same for every walker. Each standalone file uses 9.8
  -- units/s^2, but the walkers are built at very different sizes in
  -- those units (hips from about 4 units high to about 92), so scaling
  -- each one's gravity with it left them under gravities from 1.3 cm/s^2
  -- (Jansen) to 30 (Chebyshev-Spears) -- Klann, at 1.9, floated off the
  -- ground for seconds at a time. Even at 20 (Walker Room1), the
  -- walkers whose feet lift most (Klann, Chebyshev-Spears, Hoecken-Spears
  -- slider) had no foot on the ground 17-31% of the time: a small push
  -- up kept them in the air for a long time. At 70 none is off the ground
  -- more than 2% of the time; much higher (200 and more), most walkers
  -- stall. Its motors are made stronger (or weaker) by the same factor
  -- as its gravity, so each can still lift itself as on its own.
  w.gravityFactor = GRAVITY / (9.8 * scale)
  opts.impulseScale = FIXED / spec.fixed * w.gravityFactor
  opts[spec.lift] = AMP                  -- the room's bumps reach AMP above 0
  -- its crank motors, as its build makes them (for lockCranks)
  w.motors = {}
  W.onMotor = function(h, speed, impulse)
    w.motors[#w.motors + 1] = { hinge = h, speed = speed, impulse = impulse, sign = (speed < 0) and -1 or 1 }
  end
  -- (noting which bodies are braces and feet, for marking the walker
  -- below: the builds make them in functions named for them)
  -- (and, for BAR_MASS, each bar's length and the joints the build
  -- makes on it)
  local made, realCube, realScad = {}, Cube, OpenSCAD
  local barLen, joints, realJoint = {}, {}, {}
  local ankleHinges = {}   -- (the hinges its buildFoot makes: ANKLES)
  local boxes = {}         -- each part's boxes, in its own frame: { x, y, z, qx, qy, qz, qw, half x, y, z } (turnStep)
  Cube = function(...)
    local f = debug.getinfo(2, "n")
    local o
    local a = { ... }
    if LINK_WIDTH and f and f.name == "makeLink" and not (LINK_WIDTH_KEEP_OVER and select(1, ...) > LINK_WIDTH_KEEP_OVER) then   -- (every bar LINK_WIDTH wide: see LINK_WIDTH; LINK_WIDTH_KEEP_OVER, a test: bars longer than that, cm, keep their own width)
      a[2] = LINK_WIDTH
      o = realCube(unpack(a, 1, select("#", ...)))
    else
      o = realCube(...)
    end
    boxes[o] = { { 0, 0, 0, 0, 0, 0, 1, a[1] / 2, a[2] / 2, a[3] / 2 } }
    made[o] = f and f.name
    if FOOT_POINT and SAME_FEET and made[o] == "buildFoot" then
      -- (a point: one body, a ball at the leg's tip, drawn by a look-only ball on it)
      local m, r = select(4, ...), FOOT_POINT
      o.body = btRigidBody(m, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))), btSphereShape(r),
        btVector3(0.4 * m * r * r, 0.4 * m * r * r, 0.4 * m * r * r))
      boxes[o] = nil   -- (not a box: turnStep falls back on its bounding box)
      w.tips = w.tips or {}
      w.tips[#w.tips + 1] = { foot = o, p = { 0, 0, 0 }, q = { 0, 0, 0, 1 }, ball = r }
    elseif FOOT_ROD and SAME_FEET and made[o] == "buildFoot" then
      -- (a rod foot: one body, a cylinder across the walk, drawn by a look-only rod on it)
      local L, T, D, m = ...
      local r = FOOT_ROD
      o.body = btRigidBody(m, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))), btCylinderShapeZ(btVector3(r, r, D / 2)),
        btVector3(m / 12 * (3 * r * r + D * D), m / 12 * (3 * r * r + D * D), m / 2 * r * r))
      boxes[o] = nil
      w.tips = w.tips or {}
      w.tips[#w.tips + 1] = { foot = o, p = { 0, 0, 0 }, q = { 0, 0, 0, 1 }, rod = { r, D } }
    elseif flatLen and SAME_FEET and made[o] == "buildFoot" then
      -- (a foot with tips: one body, its shape the flat middle and the two
      -- tips; it turns as a flat foot of its whole length would)
      local L, T, D, m = ...
      local tl, a = tips.length, math.rad(tips.angle)
      local shape = btCompoundShape(true)
      shape:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), btBoxShape(btVector3(L / 2, T / 2, D / 2)))
      w.tips = w.tips or {}
      for _, sgn in ipairs({ 1, -1 }) do
        local q = { 0, 0, math.sin(sgn * a / 2), math.cos(sgn * a / 2) }
        local px, py = sgn * (L / 2 + tl / 2 * math.cos(a)), tl / 2 * math.sin(a)
        shape:addChildShape(btTransform(btQuaternion(q[1], q[2], q[3], q[4]), btVector3(px, py, 0)), btBoxShape(btVector3(tl / 2, T / 2, D / 2)))
        w.tips[#w.tips + 1] = { foot = o, p = { px, py, 0 }, q = q, len = tl, T = T, D = D }
        boxes[o][#boxes[o] + 1] = { px, py, 0, q[1], q[2], q[3], q[4], tl / 2, T / 2, D / 2 }
      end
      local Lt = FOOT.length
      o.body = btRigidBody(m, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))), shape,
        btVector3(m / 12 * (T * T + D * D), m / 12 * (Lt * Lt + D * D), m / 12 * (Lt * Lt + T * T)))
    end
    barLen[o] = math.max(...)
    return o
  end
  OpenSCAD = function(sdl, ...)
    local o = realScad(sdl, ...)
    local p = {}
    local pts = sdl:match("points=%[(.-)%]%)")
    for x, y in (pts or ""):gmatch("%[([-%d.]+),([-%d.]+)%]") do p[#p + 1] = { tonumber(x), tonumber(y) } end
    local L = 0                          -- a triangle: its three sides
    for i = 1, #p do
      local q = p[i % #p + 1]
      L = L + math.sqrt((q[1] - p[i][1]) ^ 2 + (q[2] - p[i][2]) ^ 2)
    end
    barLen[o] = L
    return o
  end
  for _, n in ipairs({ "btHingeConstraint", "btSliderConstraint", "btGeneric6DofConstraint", "btFixedConstraint" }) do
    realJoint[n] = _G[n]
    _G[n] = function(A, B, ...)
      local con = realJoint[n](A, B, ...)
      local f = debug.getinfo(2, "n")
      f = f and f.name or ""
      -- (a Generic6Dof is a joint only as a diag bar's weld; elsewhere
      -- it is a guide, which weighs nothing)
      if n == "btGeneric6DofConstraint" and not f:find("Crossbar") then w.guides = (w.guides or 0) + 1 end   -- (with UNBRACED, a leg's guide: the body mark's G)
      if n ~= "btGeneric6DofConstraint" or f:find("Crossbar") then
        joints[#joints + 1] = { A, type(B) == "userdata" and B or nil, n == "btSliderConstraint" or n == "btFixedConstraint", con, n }
      end
      if n == "btHingeConstraint" and f == "buildFoot" then ankleHinges[#ankleHinges + 1] = con end
      return con
    end
  end
  local ok, built = pcall(W.build, opts)
  Cube, OpenSCAD = realCube, realScad
  for n, f in pairs(realJoint) do _G[n] = f end
  if not ok then error(built, 0) end
  w.madeBy = made
  w.boxes = boxes
  if BAR_MASS then setBarMasses(w, barLen, joints, scale) end
  -- DIAG_LIGHT = k (a test; off): every brace (plates, diag and arched
  -- bars) weighs k times what it would, to see what their weight costs
  if DIAG_LIGHT then
    for _, o in ipairs(w.bodies) do
      if (made[o] or ""):find("Crossbar") and o.mass > 0 then
        local inv, m = o.body:getInvInertiaDiagLocal(), o.mass * DIAG_LIGHT
        o.body:setMassProps(m, btVector3(DIAG_LIGHT / inv.x, DIAG_LIGHT / inv.y, DIAG_LIGHT / inv.z))
        o.body:updateInertiaTensor()
        o.mass = m
      end
    end
  end
  w.joints = joints        -- { body A, body B or nil, slider?, constraint, kind }
  -- a diag walker's low brace, raised (BRACE_CLEARANCE), would cross the
  -- circles its own cranks turn in and jam on them: it passes the
  -- walker's other parts as if built in a plane of its own (a free joint,
  -- holding nothing, to each of them turns off contact between the pair),
  -- and still meets the ground
  if BRACE_CLEARANCE and spec.brace and spec.brace.diag and not arched and not low and not outside then
    local I = btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))
    for _, o in ipairs(w.bodies) do
      if made[o] == "buildDiagonalCrossbar" then
        for _, p in ipairs(w.bodies) do
          if not rawequal(p, o) then
            local free = btGeneric6DofConstraint(o.body, p.body, I, I, true)
            free:setLinearLowerLimit(btVector3(1, 1, 1)); free:setLinearUpperLimit(btVector3(-1, -1, -1))
            free:setAngularLowerLimit(btVector3(1, 1, 1)); free:setAngularUpperLimit(btVector3(-1, -1, -1))
            opts.addConstraint(free)
          end
        end
      end
    end
  end
  for _, m in ipairs(w.motors) do m.last = m.hinge:getHingeAngle(); m.turned = 0 end
  -- the same motors for every walker (MOTOR_STRENGTH, above): Bullet
  -- applies a motor's impulse once per physics step, so its most torque
  -- is impulse / FIXED
  -- its weight in all: TOTAL_MASS, or with BAR_MASS its body's
  -- BODY_MASS plus whatever its legs, feet and braces weigh
  local rest = 0
  for _, o in ipairs(w.bodies) do if o.mass > 0 and not rawequal(o, built.cube) then rest = rest + o.mass end end
  w.totalMass = (SAME_BODY and BAR_MASS) and (BODY_MASS + rest) or TOTAL_MASS
  if MOTOR_STRENGTH and #w.motors > 0 then
    local torque = MOTOR_STRENGTH * w.totalMass * GRAVITY * STRIDE / #w.motors
    for _, m in ipairs(w.motors) do
      m.impulse = torque * FIXED
      m.hinge:enableAngularMotor(true, m.speed, m.impulse)
    end
  end
  if SOLVER_ITERATIONS or spec.solverIterations then
    for _, con in ipairs(w.constraints) do con:setOverrideNumSolverIterations(SOLVER_ITERATIONS or spec.solverIterations) end
  end
  w.cube = built.cube
  w.parts = built
  -- JOINT_FRICTION (above): every hinge between two of its bodies, and the
  -- sliders' sliding pivots, read each step (jointFriction, below)
  if JOINT_FRICTION then
    w.friction = {}
    for _, j in ipairs(joints) do
      if j[5] == "btHingeConstraint" and j[2] then
        local con = j[4]
        local motor
        for _, m in ipairs(w.motors) do if rawequal(m.hinge, con) then motor = m end end
        con:enableForces()
        w.friction[#w.friction + 1] = { con = con, motor = motor }
      end
    end
    for i = 1, 4 do
      local lk = built["linkage" .. i]
      if lk and lk.sliderO4 and SLIDER_6DOF then
        lk.sliderO4:enableForces()
        w.friction[#w.friction + 1] = { con = lk.sliderO4, slide = true }
      end
    end
  end
  if BODY_ANG_DAMP or YAW_DAMP then
    w.cube.body:setDamping(w.cube.body:getLinearDamping(), BODY_ANG_DAMP or 0)
  end
  if LINK_DAMP then   -- (one damping rule, above)
    for _, o in ipairs(w.bodies) do
      if o.mass > 0 and not rawequal(o, w.cube) and made[o] ~= "buildFoot" then o.body:setDamping(LINK_DAMP, LINK_DAMP) end
    end
  end
  -- sprung ankles (ANKLE_SPRING, above): each foot, hinged to its leg,
  -- also held level to the body by an angular spring about the same axis
  -- (its position left to the hinge), as a parallel link would hold it
  if ANKLE_SPRING then
    -- (the ankle hinge's angle is the foot's against its leg link: 0 or 180
    -- degrees with the sole along the link, folded against it. Its files'
    -- +-90 degree limit, counted from there, held a level foot under an
    -- upright link -- 90 degrees as built -- at the limit, so it was taken
    -- off; then a foot could turn on through its own leg. ANKLE_STOP
    -- (default 30 degrees): a stop each side, the sole that far from the
    -- link -- where the foot's top meets the corner of a 1 cm link with the
    -- ankle's pin 0.87 cm below the link's end, in a clevis, as an ankle
    -- could be built (handover/ankle_stop.png); 30 to 150 degrees, +-60
    -- from square. false: no stop.)
    for _, h in ipairs(ankleHinges) do
      if ANKLE_STOP then
        local m = math.rad(ANKLE_STOP)
        if h:getHingeAngle() >= 0 then h:setLimit(m, math.pi - m, 0.9, 0.3, 1.0)
        else h:setLimit(-math.pi + m, -m, 0.9, 0.3, 1.0) end
      else
        h:setLimit(1, -1, 0.9, 0.3, 1.0)
      end
    end
    local cubeT = w.cube.body:getCenterOfMassTransform()
    for _, o in ipairs(w.bodies) do
      if made[o] == "buildFoot" then
        local footT = o.body:getCenterOfMassTransform()
        local inFoot = btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))
        local inCube = cubeT:inverseTimes(footT)   -- (the foot's frame in the body's)
        local spring = btGeneric6DofSpring2Constraint(o.body, w.cube.body, inFoot, inCube)
        spring:setLinearLowerLimit(btVector3(1, 1, 1)); spring:setLinearUpperLimit(btVector3(-1, -1, -1))   -- (free: the hinge holds it)
        spring:setAngularLowerLimit(btVector3(1, 1, 1)); spring:setAngularUpperLimit(btVector3(-1, -1, -1))   -- (free: the hinge holds it; the spring turns it)
        spring:enableSpring(5, true)
        spring:setStiffness(5, ANKLE_SPRING.stiffness, false)
        spring:setDamping(5, ANKLE_SPRING.damping or 0, false)
        spring:setEquilibriumPoint(5, 0)
        opts.addConstraint(spring)
        w.ankleSprings = w.ankleSprings or {}; w.ankleSprings[o] = spring   -- (STEER)
        if SOLVER_ITERATIONS then spring:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
        -- (the hinged foot's own turning left undamped: its files damp it
        -- fully, 1.0, which would hold it against the spring; the spring's
        -- damping does that job)
        o.body:setDamping(0.1, 0)
      end
    end
  end
  -- each pendant held at its angle to the body (PENDANT_HOLD, above): the
  -- links hinged to a foot, each held by a joint to the body that leaves it
  -- free to move but not to turn
  if PENDANT_HOLD == true or (type(PENDANT_HOLD) == "table" and PENDANT_HOLD[spec.name]) then
    local function obj(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
    local held = {}
    local cubeT = w.cube.body:getCenterOfMassTransform()
    for _, j in ipairs(joints) do
      if j[5] == "btHingeConstraint" and j[2] then
        local a, b = obj(j[1]), obj(j[2])
        local fa, fb = a and made[a] == "buildFoot", b and made[b] == "buildFoot"
        local p = (fa and not fb) and b or ((fb and not fa) and a or nil)
        if p and not held[p] then
          held[p] = true
          local g = btGeneric6DofConstraint(w.cube.body, p.body, cubeT:inverseTimes(p.body:getCenterOfMassTransform()),
                                            btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)), true)
          g:setLinearLowerLimit(btVector3(1, 1, 1)); g:setLinearUpperLimit(btVector3(-1, -1, -1))   -- (free to move)
          g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))     -- (not to turn)
          opts.addConstraint(g)
          if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
        end
      end
    end
  end
  -- DIAG_TIE (a test, 31 October; true or a table of names): each pair of
  -- diagonal legs (front left with back right, front right with back left)
  -- welded pendant to pendant by a joint that weighs nothing and touches
  -- nothing -- as a diag build's braces tie them, without the braces
  if DIAG_TIE == true or (type(DIAG_TIE) == "table" and DIAG_TIE[spec.name]) then
    local function obj(b) for _, o in ipairs(w.bodies) do if o.body == b then return o end end end
    local pend, seen = {}, {}
    local cubeT = w.cube.body:getCenterOfMassTransform()
    for _, j in ipairs(joints) do
      if j[5] == "btHingeConstraint" and j[2] then
        local a, b = obj(j[1]), obj(j[2])
        local fa, fb = a and made[a] == "buildFoot", b and made[b] == "buildFoot"
        local p = (fa and not fb) and b or ((fb and not fa) and a or nil)
        if p and not seen[p] then
          seen[p] = true
          local o = cubeT:invXform(p.body:getCenterOfMassPosition())   -- (in the body's own frame)
          pend[#pend + 1] = { o = p, x = o.x, z = o.z }
        end
      end
    end
    assert(#pend == 4, spec.name .. ": DIAG_TIE found " .. #pend .. " pendants, not 4")
    local mx, mz = 0, 0
    for _, q in ipairs(pend) do mx, mz = mx + q.x / 4, mz + q.z / 4 end
    local corner = {}
    for _, q in ipairs(pend) do corner[(q.x > mx and "f" or "b") .. (q.z > mz and "l" or "r")] = q.o end
    w.ties = {}
    for _, pair in ipairs({ { "fl", "br" }, { "fr", "bl" } }) do
      local a, b = corner[pair[1]], corner[pair[2]]
      assert(a and b, spec.name .. ": DIAG_TIE could not pair its legs")
      local g = btGeneric6DofConstraint(a.body, b.body, btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)),
                                        b.body:getCenterOfMassTransform():inverseTimes(a.body:getCenterOfMassTransform()), true)
      g:setLinearLowerLimit(btVector3(0, 0, 0)); g:setLinearUpperLimit(btVector3(0, 0, 0))
      g:setAngularLowerLimit(btVector3(0, 0, 0)); g:setAngularUpperLimit(btVector3(0, 0, 0))
      opts.addConstraint(g)
      if SOLVER_ITERATIONS then g:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
      w.ties[#w.ties + 1] = { a, b }
    end
  end
  -- BRACE_GHOST (a test, 31 October): a diag build's braces kept, weight and
  -- all, but touching nothing (so they cannot catch on a bump)
  if BRACE_GHOST then
    for _, o in ipairs(w.bodies) do
      if (made[o] or ""):find("Crossbar") then
        local f = o.body:getCollisionFlags()
        if math.floor(f / 4) % 2 == 0 then o.body:setCollisionFlags(f + 4) end
      end
    end
  end
  if STEER then steerSetup(w, made, opts) end   -- (after the springs, damping and braces above: it changes them)
  if SHOES then shoesSetup(w, made, opts) end
  -- its radius: half the diagonal of its moving bodies' footprint (from
  -- the moving bodies only: static ones would make it look huge)
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  local x0, x1, z0, z1 = 1e30, -1e30, 1e30, -1e30
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 then
      o.body:getAabb(lo, hi)
      x0, x1, z0, z1 = math.min(x0, lo.x), math.max(x1, hi.x), math.min(z0, lo.z), math.max(z1, hi.z)
    end
  end
  w.radius = 0.5 * math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
  -- the same body for every walker (SAME_BODY, above)
  if SAME_BODY then
    local m = w.totalMass - rest
    assert(m > 0, spec.name .. ": TOTAL_MASS is less than its legs weigh")
    local x, y, z = BODY_BOX[1], BODY_BOX[2], BODY_BOX[3]
    w.cube.mass = m                     -- (first: setting an object's mass gives it its own shape's turning)
    w.cube.body:setMassProps(m, btVector3(m / 12 * (y * y + z * z), m / 12 * (x * x + z * z), m / 12 * (x * x + y * y)))
    w.cube.body:updateInertiaTensor()
    w.bodyMass = m
  end
  -- its gravity, on its moving bodies only
  for _, o in ipairs(w.bodies) do
    if o.mass > 0 then o.body:setGravity(btVector3(0, -GRAVITY, 0)) end
  end
  -- its floor (FLOOR_TOP_Y, its own units) onto the room's (0), then to
  -- its spot, turned to its heading (0: walking along +x)
  local cp = w.cube.body:getCenterOfMassPosition()
  local cx, cz = cp.x, cp.z
  local yaw0 = (w.forward > 0) and 0 or math.pi
  for _, t in ipairs(w.tips or {}) do
    t.o = t.ball and Sphere(t.ball, 0) or t.rod and Cylinder(t.rod[1], t.rod[2], 0) or Cube(t.len, t.T, t.D, 0)
    t.o.col = "#3C3C3C"   -- (the feet's colour, below)
    t.o.decoration = true -- (look-only, as decor's)
    addObject(t.o)
  end
  if MARKS then markBody(w, spec.look) end
  if w.frame then decor(w, Cube(w.frame.L, w.frame.H, w.frame.D, 0), w.cube.col, 0, 0, 0) end   -- (the frame, drawn)
  moveWalker(w, cx, cz, heading - yaw0, x - cx, -(W.FLOOR_TOP_Y or 0) * scale, z - cz)
  placeMarks(w)
  w.heading = heading                    -- (the heading it was set to; heading(w) is the one it has)
  if spec.railed then setRail(w) end
  -- how it was built to stand (some, like the 2-leg Spears, are built
  -- tilted on purpose), to know when it has fallen and to stand it up again
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  w.q0 = { q:x(), q:y(), q:z(), q:w() }
  w.heading0 = heading
  w.tilt0 = math.acos(math.max(-1, math.min(1, 1 - 2 * (q:x() ^ 2 + q:z() ^ 2))))
  walkers[#walkers + 1] = w
  building = nil
  return w
end

-- a seeded random generator (the same seed gives the same room)
local rngState = SEED
local function random()
  rngState = (rngState * 1103515245 + 12345) % 2147483648
  return rngState / 2147483648
end

-- spots: a grid 4 across, as many rows deep as it takes, filling the arena, the walkers in list order
local COLS = 4
local ROWS = math.ceil(#WALKERS / COLS)
if type(ONLY) == "table" then   -- (a few named: as many rows as they fill, so they spread over the room)
  local n = 0
  for _, spec in ipairs(WALKERS) do if ONLY[spec.name] then n = n + 1 end end
  ROWS = math.max(1, math.ceil(n / COLS))
end
local function buildWalkers()
  rngState = SEED
  local n = 0
  for _, spec in ipairs(WALKERS) do
    if ONLY == nil or spec.name == ONLY or (type(ONLY) == "table" and ONLY[spec.name]) then
      local single = type(ONLY) == "string"
      local col, row = n % COLS, math.floor(n / COLS)
      local x = single and 0 or (X0 + (col + 0.5) * ARENA_X / COLS)
      local z = single and 0 or (Z0 + (row + 0.5) * ARENA_Z / ROWS)
      local heading = single and 0 or random() * 2 * math.pi
      if TEST_TRACK then
        -- (near the -x end, facing +x; moved up to a bump length along
        -- and across by SEED, so each seed meets the bumps differently)
        x = X0 + 60 + random() * BUMP
        z = (random() - 0.5) * BUMP
        if TERRAIN_MIRROR then z = -z end   -- (on mirrored ground, the start mirrored too: the seed's run, left for right)
        heading = 0
      end
      -- (a railed walker starts along an axis: see `railed` above)
      if spec.railed and not TEST_TRACK then heading = math.floor(random() * 4) * math.pi / 2 end
      addWalker(spec, x, z, heading)
      n = n + 1
    end
  end
end

-- ---------------------------------------------------------------------
-- turning: a turn of `angle` radians (+ to the left, seen from above) is
-- spread over TURN_TIME seconds, a little each frame, about a vertical
-- axis through the walker's body. Small steps let the feet's contacts
-- settle as it goes, where one big jump could push a foot into a bump.
-- ---------------------------------------------------------------------

local TURN_TIME = 1.0
local LIFT_TOLERANCE = 0.15   -- cm

local function startTurn(w, angle)
  w.turnLeft = angle
  w.turnRate = angle / TURN_TIME
  w.heading = w.heading + angle
  if w.spec.railed then w.cube.body:setLinearFactor(btVector3(1, 1, 1)) end   -- (free while it turns)
end

local function turnStep(w, dt)
  if not w.turnLeft then return end
  local step = w.turnRate * dt
  if math.abs(step) >= math.abs(w.turnLeft) then step = w.turnLeft end
  local p = w.cube.body:getCenterOfMassPosition()
  moveWalker(w, p.x, p.z, step, 0, 0, 0)
  -- turning sweeps the feet sideways, into rising ground on a bumpy
  -- floor; a foot pushed through the (thin) terrain then props the walker
  -- up from underneath. So if any part's lowest point is now below the
  -- ground under that point, lift the whole walker by that much; and a part
  -- swept into a wall, below its top, moves the walker back from it by
  -- that much. (A body resting on the ground sits a hair into it, within
  -- Bullet's contact margin: LIFT_TOLERANCE keeps that from nudging the
  -- walker every frame.) Each box's corners are tested (w.boxes); a part of
  -- another shape, by its bounding box against the highest ground under
  -- it. (Until November 2026 every part was tested that way, which on
  -- waves could ask for a lift no part needed, and the lift kept the
  -- walker's falling speed: through a turn it was lifted, fell, was lifted
  -- again, faster each time, up to 3 m/s, and thrown when the turn ended;
  -- now a lift also stops its fall. HANDOVER.md 4u.)
  local need, out = 0, { 0, 0, 0, 0 }   -- (lift; and past the walls at +x, -x, +z, -z)
  local fx, fz, top = ARENA_X / 2, ARENA_Z / 2, WALL_H - AMP
  local function corner(x, y, z)
    need = math.max(need, terrainHeight(x, z) - y - LIFT_TOLERANCE)
    if y < top then
      out[1] = math.max(out[1], x - fx); out[2] = math.max(out[2], -fx - x)
      out[3] = math.max(out[3], z - fz); out[4] = math.max(out[4], -fz - z)
    end
  end
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  for _, o in ipairs(w.bodies) do
    local bx = w.boxes and w.boxes[o]
    if bx then
      local c, q = o.body:getCenterOfMassPosition(), o.body:getCenterOfMassTransform():getRotation()
      local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
      for _, b in ipairs(bx) do
        for i = 0, 7 do
          local vx, vy, vz = (i % 2 == 0) and b[8] or -b[8], (i % 4 < 2) and b[9] or -b[9], (i < 4) and b[10] or -b[10]
          vx, vy, vz = qrot(b[4], b[5], b[6], b[7], vx, vy, vz)
          vx, vy, vz = qrot(qx, qy, qz, qw, vx + b[1], vy + b[2], vz + b[3])
          corner(c.x + vx, c.y + vy, c.z + vz)
        end
      end
    else
      o.body:getAabb(lo, hi)
      local ground = math.max(terrainHeight(lo.x, lo.z), terrainHeight(lo.x, hi.z),
                              terrainHeight(hi.x, lo.z), terrainHeight(hi.x, hi.z),
                              terrainHeight((lo.x + hi.x) / 2, (lo.z + hi.z) / 2))
      need = math.max(need, ground - lo.y - LIFT_TOLERANCE)
      if lo.y < top then   -- (and the walls, by its box's sides)
        out[1] = math.max(out[1], hi.x - fx); out[2] = math.max(out[2], -fx - lo.x)
        out[3] = math.max(out[3], hi.z - fz); out[4] = math.max(out[4], -fz - lo.z)
      end
    end
  end
  local dx = -math.max(out[1] - LIFT_TOLERANCE, 0) + math.max(out[2] - LIFT_TOLERANCE, 0)
  local dz = -math.max(out[3] - LIFT_TOLERANCE, 0) + math.max(out[4] - LIFT_TOLERANCE, 0)
  if need > 0 or dx ~= 0 or dz ~= 0 then
    moveWalker(w, p.x, p.z, 0, dx, math.max(need, 0), dz)
    if need > 0 then   -- (and no falling: what it fell into, it is now above)
      for _, o in ipairs(w.bodies) do
        local vx, vy, vz = getVelXYZ(o)
        if vy < 0 then setVelXYZ(o, vx, 0, vz) end
      end
    end
  end
  w.lifted = (w.lifted or 0) + math.max(need, 0)   -- (for tools/roomsoak.lua's trace: the lifts since it last looked)
  w.turnLeft = w.turnLeft - step
  if math.abs(w.turnLeft) < 1e-9 then
    w.turnLeft = nil
    if w.spec.railed then setRail(w) end
  end
end

-- the way a walker faces now: its body's own forward axis, in the room
local function heading(w)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local f = w.forward
  -- the body's local x axis in the room, times its forward sign
  local fx = f * (1 - 2 * (qy * qy + qz * qz))
  local fz = f * (2 * (qx * qz - qw * qy))
  return math.atan2(-fz, fx)        -- 0: +x; + : to the left (toward -z)
end
room.heading, room.startTurn = heading, startTurn

-- ---------------------------------------------------------------------
-- avoiding walls and each other. Each walker, unless it is turning or
-- has just turned, looks ahead: if it is heading toward a wall and is
-- within GAP of it, or heading toward another walker (within AHEAD of
-- straight at it) with less than GAP between them, it turns. The new
-- heading is the best of a few seeded random ones: away from walls and
-- walkers near enough to matter.
-- ---------------------------------------------------------------------

local GAP = 40              -- about one body length, cm
local AHEAD = math.rad(60)  -- "in front": within this of straight ahead
local COOLDOWN = 2.0        -- s after a turn ends before it looks again
local CANDIDATES = 12       -- new headings tried per turn
-- ROOM_STEER (handover/STEERING.md, stage C): how the room turns a walker
-- that has its wheels (SHOES), which walks straight the rest of the time.
-- "backup" (the default): a three-point turn -- it backs up BACKUP_PHASE s
-- with the wheel on the far side braked, then walks on BACKUP_PHASE s with
-- the near one braked (both turn it the same way), and so on until it has
-- turned; nearly on the spot, so it looks GAP ahead, as a rigid turn does
-- (a look behind, GAP / 4, ends a backing phase early). "arcs": it walks
-- on with the near wheel braked until it has turned, on a circle of about
-- 80 cm, so it looks WHEEL_GAP ahead. Either way, if the turn takes over
-- WHEEL_TIME, or an arc still comes within GAP / 4 of a wall or a walker,
-- the turn is finished rigidly (a rescue: room.rescues). "rigid": every
-- turn rigid, as without wheels.
ROOM_STEER = ROOM_STEER or "backup"
local BACKUP_PHASE = 4      -- s
local WHEEL_GAP = 120       -- cm
local WHEEL_TIME = 60       -- s
room.rescues = {}           -- a log: { time, walker name, why }
local WALL_X, WALL_Z = ARENA_X / 2, ARENA_Z / 2   -- the walls' inner faces are at x = +-WALL_X, z = +-WALL_Z

local function angleDiff(a, b)       -- a - b, wrapped to (-pi, pi]
  local d = (a - b) % (2 * math.pi)
  if d > math.pi then d = d - 2 * math.pi end
  return d
end

-- how bad heading h would be for walker w at (x, z): the closer what lies
-- that way, the worse
-- how close walkers w (at x, z, moving at vx, vz cm/s) and o will come,
-- edge to edge, over the next PREDICT seconds if both keep their present
-- velocities (o's from its last half second), and when
local PREDICT = 4.0
local function closest(w, x, z, vx, vz, o)
  local ox, _, oz = getPosXYZ(o.cube)
  local rx, rz = ox - x, oz - z
  local ux, uz = (o.vx or 0) - vx, (o.vz or 0) - vz
  local uu = ux * ux + uz * uz
  local t = 0
  if uu > 1e-6 then t = math.max(0, math.min(PREDICT, -(rx * ux + rz * uz) / uu)) end
  local cx, cz = rx + ux * t, rz + uz * t
  return math.sqrt(cx * cx + cz * cz) - w.radius - o.radius, t
end

local function badness(w, x, z, h)
  local fx, fz = math.cos(h), -math.sin(h)
  local bad = 0
  -- walls: the distance to the wall along h, if it is near
  local reach = 4 * GAP
  local dist = 1e30
  if fx > 1e-6 then dist = math.min(dist, (WALL_X - w.radius - x) / fx) end
  if fx < -1e-6 then dist = math.min(dist, (-WALL_X + w.radius - x) / fx) end
  if fz > 1e-6 then dist = math.min(dist, (WALL_Z - w.radius - z) / fz) end
  if fz < -1e-6 then dist = math.min(dist, (-WALL_Z + w.radius - z) / fz) end
  if dist < reach then bad = bad + (reach - dist) / reach end
  -- walkers in that direction
  for _, o in ipairs(walkers) do
    if o ~= w then
      local ox, _, oz = getPosXYZ(o.cube)
      local dx, dz = ox - x, oz - z
      local d = math.sqrt(dx * dx + dz * dz)
      local gap = d - w.radius - o.radius
      if gap < reach and d > 1e-6 and (dx * fx + dz * fz) / d > math.cos(AHEAD) then
        bad = bad + (reach - math.max(gap, 0)) / reach
      end
      -- and how close they'd come with w travelling along h at its
      -- present speed (a crossing path, from any side)
      if gap < reach and w.vx then
        local sp = math.max(math.sqrt(w.vx * w.vx + w.vz * w.vz), 1)
        local g = closest(w, x, z, sp * fx, sp * fz, o)
        if g < GAP then bad = bad + 2 * (GAP - math.max(g, 0)) / GAP end
      end
    end
  end
  return bad
end

-- a turn by a braked wheel isn't on the spot: the walker goes on round a
-- circle about WHEEL_R across in radius as it turns. The badness of such a
-- turn: its end heading's, from where the arc ends, and a lot more if the
-- arc on the way comes within GAP / 4 of a wall (turning toward a wall to
-- come away from it, which on the spot is fine, would run into it)
local WHEEL_R = 80          -- cm (measured: 60-80 on flat and waves 2, grip 3)
local function wheelBadness(w, x, z, h, turn)
  local s, step = (turn > 0) and 1 or -1, math.rad(10)
  local sp = math.max(w.vx and math.sqrt(w.vx * w.vx + w.vz * w.vz) or 6, 1)   -- (cm/s)
  local px, pz, a, bad = x, z, h, 0
  for k = 1, math.floor(math.abs(turn) / step + 0.5) do
    a = a + s * step
    px, pz = px + WHEEL_R * step * math.cos(a), pz - WHEEL_R * step * math.sin(a)
    if math.min(WALL_X - math.abs(px), WALL_Z - math.abs(pz)) - w.radius < GAP / 4 then bad = bad + 10; break end
    -- (and the other walkers, where they'll be by then at their present velocities)
    local t = k * WHEEL_R * step / sp
    for _, o in ipairs(walkers) do
      if o ~= w then
        local ox, _, oz = getPosXYZ(o.cube)
        ox, oz = ox + (o.vx or 0) * t, oz + (o.vz or 0) * t
        if math.sqrt((ox - px) ^ 2 + (oz - pz) ^ 2) - w.radius - o.radius < GAP / 2 then bad = bad + 10; break end
      end
    end
    if bad > 0 then break end
  end
  return bad + badness(w, px, pz, h + turn)
end

local RIGHT_ANGLES = { math.pi / 2, -math.pi / 2, math.pi }
local function chooseTurn(w, x, z, h, byWheel)
  local best, bestBad
  for k = 1, (w.spec.railed and not byWheel) and #RIGHT_ANGLES or CANDIDATES do
    -- a turn of 60 to 180 degrees, left or right (a railed walker: a
    -- right angle, or about turn)
    local turn, b
    if byWheel then   -- (30 to 180 degrees, smaller ones preferred more: it walks straight sooner)
      turn = math.rad(30 + 150 * random()) * ((random() < 0.5) and -1 or 1)
      b = wheelBadness(w, x, z, h, turn) + 0.3 * math.abs(turn) / math.pi
    else
      turn = w.spec.railed and RIGHT_ANGLES[k] or math.rad(60 + 120 * random()) * ((random() < 0.5) and -1 or 1)
      b = badness(w, x, z, h + turn) + 0.1 * math.abs(turn) / math.pi   -- (smaller turns preferred, a little)
    end
    if not bestBad or b < bestBad then best, bestBad = turn, b end
  end
  return best
end

-- what is in front of walker w, if anything: "wall", or another walker.
-- "In front" along heading h, which is checked twice: the way it faces,
-- and the way it has actually been moving (a walker that slides or veers
-- -- the 2-leg Spears does as it rolls over -- can move well off the way
-- it faces)
local function blockedAlong(w, x, z, h, wallGap, walkerGap)
  local fx, fz = math.cos(h), -math.sin(h)
  local WGAP = wallGap or GAP   -- (a wider look ahead for a walker that turns by its wheels: WHEEL_GAP)
  -- each wall: the gap between the walker's edge and it, and how
  -- squarely the walker heads at it (1: straight at it; 0: along it)
  for _, wall in ipairs({ { WALL_X - x, fx }, { WALL_X + x, -fx }, { WALL_Z - z, fz }, { WALL_Z + z, -fz } }) do
    local gap, toward = wall[1] - w.radius, wall[2]
    if (gap < WGAP and toward > math.cos(AHEAD)) or (gap < WGAP / 4 and toward > 0) then return "wall" end
  end
  for _, o in ipairs(walkers) do
    if o ~= w then
      local ox, _, oz = getPosXYZ(o.cube)
      local dx, dz = ox - x, oz - z
      local d = math.sqrt(dx * dx + dz * dz)
      if d - w.radius - o.radius < (walkerGap or WGAP) and d > 1e-6 and (dx * fx + dz * fz) / d > math.cos(AHEAD) then
        return o
      end
    end
  end
end

-- ---------------------------------------------------------------------
-- standing fallen walkers up again. A walker counts as fallen when its
-- body has tipped more than FALL_TILT beyond the tilt it was built with,
-- and has stayed so for FALL_TIME. It is then turned back, rigidly, to
-- the way it was built to stand (facing the way it faces now), lifted
-- clear of the ground, and stopped; it carries on from there.
-- ---------------------------------------------------------------------

local FALL_TILT = math.rad(50)
local FALL_TIME = 2.0
room.righted = {}   -- a log: { time, walker name }

local function tilt(w)
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  return math.acos(math.max(-1, math.min(1, 1 - 2 * (q:x() ^ 2 + q:z() ^ 2))))
end

-- lift walker w so its lowest point is `clear` above the ground under it
-- (or by however much it needs to get there; never down)
local function liftClear(w, clear)
  local need = 0
  local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
  for _, o in ipairs(w.bodies) do
    o.body:getAabb(lo, hi)
    local ground = math.max(terrainHeight(lo.x, lo.z), terrainHeight(lo.x, hi.z),
                            terrainHeight(hi.x, lo.z), terrainHeight(hi.x, hi.z),
                            terrainHeight((lo.x + hi.x) / 2, (lo.z + hi.z) / 2))
    need = math.max(need, ground + clear - lo.y)
  end
  if need > 0 then moveWalker(w, 0, 0, 0, 0, need, 0) end
end

local function standUp(w)
  -- the way it was built to stand, turned to face where it faces now
  local h = heading(w)
  local d = (h - w.heading0) / 2
  local tx, ty, tz, tw = qmul(0, math.sin(d), 0, math.cos(d), w.q0[1], w.q0[2], w.q0[3], w.q0[4])
  local q = w.cube.body:getCenterOfMassTransform():getRotation()
  -- the turn from how it is to how it should be: target x (current)^-1
  local rx, ry, rz, rw = qmul(tx, ty, tz, tw, -q:x(), -q:y(), -q:z(), q:w())
  local p = w.cube.body:getCenterOfMassPosition()
  rotateWalker(w, p.x, p.y, p.z, rx, ry, rz, rw)
  liftClear(w, 0.5)
  for _, o in ipairs(w.bodies) do
    setVelXYZ(o, 0, 0, 0)
    setAngVelXYZ(o, 0, 0, 0)
  end
  w.heading = h
  w.turnLeft = nil
  if w.wheelTurn then setShoe(w, nil); w.wheelTurn = nil end   -- (a wheel turn it was making: dropped)
  if w.backupTurn then setShoe(w, nil); room.setReverse(w, false); w.backupTurn = nil end
  if w.spec.railed then
    -- (back onto the nearest axis, which a railed walker must face along)
    w.heading = math.floor(h / (math.pi / 2) + 0.5) * math.pi / 2
    setRail(w)
  end
end

-- the way a walker actually travels, which isn't always the way it
-- faces: some walk sideways or backwards part of the time (Klann, and
-- Chebyshev-Spears diag after some turns, among others). Each walker
-- keeps a running average of the angle between the two (in its own
-- frame, so it carries over through a turn), updated each half second
-- it isn't turning, and avoidance steers by facing + that angle: a
-- walker that travels backwards turns to face what it should get away
-- from. (A walker that hardly moves, or moves every which way, keeps
-- steering by the way it faces.)
local function noteTravel(w, dx, dz)
  if w.turnLeft or dx * dx + dz * dz < 0.09 then return end   -- (turning, or under 0.3 cm in half a second)
  local off = angleDiff(math.atan2(-dz, dx), heading(w))
  local a = 0.2
  w.offC = (w.offC or 1) * (1 - a) + math.cos(off) * a
  w.offS = (w.offS or 0) * (1 - a) + math.sin(off) * a
end
local function travel(w)
  local c, s = w.offC or 1, w.offS or 0
  if c * c + s * s < 0.09 then return heading(w) end       -- (no clear direction yet)
  return heading(w) + math.atan2(s, c)
end
room.travel = travel

-- a near miss: another walker less than GAP / 4 away and closer than it
-- was half a second ago -- checked even in a walker's calm spell after a
-- turn, so two walkers can't close in on each other while neither looks
local function nearMiss(w, x, z)
  local last = w.track and w.track[#w.track]
  if not last then return nil end
  for _, o in ipairs(walkers) do
    if o ~= w and w.vx then
      local g, t = closest(w, x, z, w.vx, w.vz, o)
      if g < GAP / 4 and t > 0 and t < 2 then return o end
    end
    if o ~= w and o.track and o.track[#o.track] then
      local ox, _, oz = getPosXYZ(o.cube)
      local d = math.sqrt((ox - x) ^ 2 + (oz - z) ^ 2)
      if d - w.radius - o.radius < GAP / 4 then
        local ol = o.track[#o.track]
        local d0 = math.sqrt((ol[1] - last[1]) ^ 2 + (ol[2] - last[2]) ^ 2)
        if d < d0 - 0.2 then return o end
      end
    end
  end
end

local function blocked(w, x, z, h, wallGap)
  local what = blockedAlong(w, x, z, h, wallGap)
  if what then return what end
  local GAP = wallGap or GAP
  -- a walker on a crossing path, from any side: both keep their present
  -- velocities and they'd come within GAP / 2
  if w.vx then
    for _, o in ipairs(walkers) do
      if o ~= w then
        local g, t = closest(w, x, z, w.vx, w.vz, o)
        if g < GAP / 2 and t > 0 then return o end
      end
    end
  end
  local old = w.track and w.track[1]
  if old then
    local dx, dz = x - old[1], z - old[2]
    if dx * dx + dz * dz > 1 then           -- (moved more than 1 cm in the last second)
      return blockedAlong(w, x, z, math.atan2(-dz, dx), wallGap)
    end
  end
end

room.turns = {}   -- a log: { time, walker name, what blocked it, turn in degrees }
local simTime = 0
local TRACK_EVERY = 30      -- frames between samples of where each walker is (half a second)
local PROGRESS_EVERY = 300  -- frames between the samples its distance gone is summed over (5 s)

-- ---------------------------------------------------------------------
-- trails: each walker paints the cell under its body in its own colour
-- as it goes (the walkers take turns, one every frame or two, so the
-- painting is spread out). T clears them; the cells get their meadow
-- colours back.
-- ---------------------------------------------------------------------

local TRAIL_EVERY = 6       -- frames between one walker's marks
local TRAIL_COLOURS = {
  { "red", 230, 30, 30 }, { "orange", 255, 140, 0 }, { "yellow", 255, 225, 0 }, { "white", 250, 250, 250 },
  { "black", 25, 25, 25 }, { "cyan", 0, 210, 230 }, { "blue", 40, 70, 240 }, { "purple", 150, 50, 220 },
  { "pink", 255, 105, 180 }, { "maroon", 120, 0, 40 }, { "teal", 0, 128, 128 }, { "lavender", 200, 170, 255 },
  { "navy", 20, 30, 110 }, { "olive", 128, 128, 0 },
}
local painted = {}          -- [cell] = the walker whose trail is on it

local function cellAt(x, z)
  local i, j = math.floor((x - X0) / CELL), math.floor((z - Z0) / CELL)
  if i < 0 or i >= NX or j < 0 or j >= NZ then return nil end
  return i * NZ + j, i, j
end

local function markTrail(w)
  local x, _, z = getPosXYZ(w.cube)
  local cell, i, j = cellAt(x, z)
  if cell and painted[cell] ~= w then
    painted[cell] = w
    local c = w.colour
    paintCell(i, j, c[2], c[3], c[4])
  end
end

local function clearTrails()
  for cell in pairs(painted) do
    local i, j = math.floor(cell / NZ), cell % NZ
    paintCell(i, j, cellColour(i, j))
  end
  painted = {}
end

-- ---------------------------------------------------------------------
-- building (and building again: G, the 1-4 keys)
-- ---------------------------------------------------------------------

local owner = {}            -- [objectKey(body)] = its walker (for the hover)

-- the walkers alone, on the ground already built (with the ground: buildRoom)
local function placeWalkers()
  buildWalkers()
  owner = {}
  for k, w in ipairs(walkers) do
    w.colour = TRAIL_COLOURS[(k - 1) % #TRAIL_COLOURS + 1]
    w.index = k
    w.travelled = 0
    for _, o in ipairs(w.bodies) do owner[objectKey(o)] = w end
  end
  room.turns, room.righted = {}, {}
  simTime = 0
end
local function buildRoom()
  AMP, BUMP = pendingAmp or AMP, pendingBump or BUMP   -- (the sliders' values, if they were moved)
  if pendingAmp or pendingBump then v.statusText = "" end   -- (the note that they were waiting)
  pendingAmp, pendingBump = nil, nil
  buildTerrain()
  painted = {}
  placeWalkers()
end

-- the walkers taken down (the ground left as it is, its trails cleared)
local function teardownWalkers()
  for _, con in ipairs(roomConstraints) do v:removeConstraint(con) end
  for _, o in ipairs(roomObjects) do v:remove(o) end
  roomObjects, roomConstraints = {}, {}
  for k = #walkers, 1, -1 do walkers[k] = nil end
  clearTrails()
end
local function teardownRoom()
  teardownWalkers()
  for _, o in ipairs(groundObjects) do v:remove(o) end
  groundObjects = {}
end

v:addParam("TerrainHeight", AMP, 0, AMP_MAX, 1, "bump height, cm (G builds the room with it)")
v:addParam("BumpLength", BUMP, BUMP_MIN, BUMP_MAX, 1, "bump length, cm (the stride is 15; G builds the room with it)")
-- THREADS (default 4; the room only, not the test track's one walker): the
-- walkers solved side by side on this many threads; the Threads slider
-- changes it while the room runs, and the status line shows how fast (as
-- ../Testing_Threads.lua). The room walks the same, move for move, at any
-- number of threads; at 0, very slightly differently (without threads
-- Bullet solves two or three walkers together). Needs bpp built with Bullet
-- with threads (scripts/bullet-threads.sh, then qmake CONFIG+=bundled_bullet;
-- THREADS.md); otherwise the status line says so. 4 was the fastest on
-- William's 8-core machine for 4, 11 and 21 walkers, about 2.5 times
-- threads 0 (handover/THREADS.md, 10 November); a machine with fewer
-- hardware threads uses what it has.
THREADS = THREADS or 4
local HAS_THREADS = false
local threadsT0, threadsSpent, threadsFrames, threadsWall0, threadsBase = 0, 0, 0, 0, nil
if not TEST_TRACK then
  HAS_THREADS = v:setThreads(1) > 0   -- (how many it uses: 0 with the system Bullet)
  v:setThreads(THREADS)
  v:addParam("Threads", THREADS, 0, 16, 1, "threads solving the walkers side by side (0: as without threads)")
  threadsWall0 = v:getTime()
end
-- VIEWS (test track): a list of { walker =, label =, reverse =, gait =,
-- unbraced =, crank =, hold = } -- see test-ranking.lua. Tab goes through those
-- instead of the walkers, each built, timed and turned its own way (the
-- room's REVERSE, GAIT, UNBRACED and CRANK_SCALE, set for it, and
-- PENDANT_HOLD when the view gives hold); the track starts with
-- VIEWS[VIEW or 1].
local viewAt = 0
local function setView(k)
  local c = VIEWS[k]
  viewAt = k
  ONLY = c.walker
  REVERSE, GAIT, UNBRACED, CRANK_SCALE = c.reverse or false, c.gait, c.unbraced or false, c.crank
  if c.hold ~= nil then PENDANT_HOLD = c.hold end
end
if TEST_TRACK and VIEWS then setView(VIEW or 1) end
buildRoom()

-- ---------------------------------------------------------------------
-- keeping a walker's cranks in step. Each crank has its own motor in most
-- builds, and nothing else keeps them in step: over a minute or two their
-- legs drift out of the timing they were built with (Klann's within half
-- a minute, into walking back and forth). Here, every frame, each motor's
-- speed is nudged by how far its crank has got ahead of or behind the
-- average of the walker's cranks (since it was built): LOCK_GAIN rad/s
-- for each radian, up to LOCK_MAX rad/s. Their average still turns as the
-- load lets it, at up to its crank speed; only their timing is held, as a gear
-- train from one motor would hold it. (The 2-leg Spears' legs share one
-- crank, so there is nothing to hold.)
-- ---------------------------------------------------------------------

local LOCK_GAIN, LOCK_MAX = 4, 1.5

-- JOINT_FRICTION (above): each hinge's brake set from the force its pin
-- carried last step; a crank's motor torque cut by its pin's friction
local function jointFriction(w)
  if not w.friction then return end
  local mu, r = JOINT_FRICTION.mu or 0.1, JOINT_FRICTION.pin or 0.25
  for _, f in ipairs(w.friction) do
    local F = f.con:forceA()
    local mag = math.sqrt(F.x * F.x + F.y * F.y + F.z * F.z)
    if f.slide then
      f.con:setLinearMotor(0, true, 0, mu * mag)
    elseif f.motor then
      f.motor.friction = mu * r * mag * FIXED
      if not LOCK_CRANKS then f.motor.hinge:enableAngularMotor(true, f.motor.speed, math.max(0, f.motor.impulse - f.motor.friction)) end
    else
      f.con:enableAngularMotor(true, 0, mu * r * mag * FIXED)
    end
  end
end

local function lockCranks(w)
  local n = #w.motors
  if n < 2 then return end
  local sum, cnt = {}, {}   -- (by m.group: STEER's loosened lock; one group otherwise)
  for _, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    local d = a - m.last
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    m.turned, m.last = m.turned + d * m.sign, a
    local g = m.group or 1
    sum[g], cnt[g] = (sum[g] or 0) + m.turned, (cnt[g] or 0) + 1
  end
  for _, m in ipairs(w.motors) do
    local g = m.group or 1
    local mean = sum[g] / cnt[g]
    local nudge = math.max(-LOCK_MAX, math.min(LOCK_MAX, LOCK_GAIN * (mean - m.turned)))
    m.hinge:enableAngularMotor(true, m.speed + m.sign * nudge, math.max(0, m.impulse - (m.friction or 0)))
  end
end

v:preSim(function(N)
  threadsT0 = v:getTime()   -- (the Threads readout: a frame's time, from here to the start of postSim)
  simTime = simTime + FRAME
  for k, w in ipairs(walkers) do
    if JOINT_FRICTION then jointFriction(w) end
    easeReverse(w)
    if LOCK_CRANKS then lockCranks(w) end
    if YAW_DAMP and not w.shoeDown then   -- (its turning about the vertical damped: YAW_DAMP; not while a wheel is braked, SHOES)
      local ax, ay, az = getAngVelXYZ(w.cube)
      setAngVelXYZ(w.cube, ax, ay * (1 - YAW_DAMP), az)
    end
    if ROLL_DAMP then   -- (a test: its rolling, turning about the walk, world x, damped by ROLL_DAMP each frame, as YAW_DAMP)
      local ax, ay, az = getAngVelXYZ(w.cube)
      setAngVelXYZ(w.cube, ax * (1 - ROLL_DAMP), ay, az)
    end
    if TURN_TEST then
      -- (a test: every walker turns 90 degrees to the left every 10 s)
      if not w.turnLeft and simTime >= (w.nextTest or 10) then
        startTurn(w, math.pi / 2)
        w.nextTest = (w.nextTest or 10) + 10
      end
    elseif not TEST_TRACK and not w.turnLeft and w.byHand then
      -- (a wheel braked by hand, the arrow keys: the room leaves it alone)
    elseif not TEST_TRACK and not w.turnLeft and w.backupTurn then
      -- (a three-point turn: backing with the far wheel braked, then on with the near one)
      local sh = w.backupTurn
      local x, _, z = getPosXYZ(w.cube)
      local sgn = (sh.turn > 0) and 1 or -1
      local done = angleDiff(heading(w), sh.from) * sgn
      if done >= math.abs(sh.turn) or simTime > sh.by then
        setShoe(w, nil); room.setReverse(w, false)
        w.backupTurn = nil
        w.calmUntil = simTime + COOLDOWN
        if done < math.abs(sh.turn) then
          startTurn(w, (math.abs(sh.turn) - math.max(done, 0)) * sgn)
          w.calmUntil = simTime + TURN_TIME + COOLDOWN
          room.rescues[#room.rescues + 1] = { simTime, w.spec.name, "too slow" }
        end
      else
        local h = travel(w)
        local ahead = blockedAlong(w, x, z, sh.back and (h + math.pi) or h, GAP / 4, GAP / 4)
        if simTime >= sh.next or ahead then   -- (the other phase)
          sh.back = not sh.back
          sh.next = simTime + BACKUP_PHASE
          room.setReverse(w, sh.back)
          setShoe(w, ((sgn > 0) == (not sh.back)) and "L" or "R")
        end
      end
    elseif not TEST_TRACK and not w.turnLeft and w.wheelTurn then
      -- (turning by a braked wheel: done when it has turned that far)
      local wt = w.wheelTurn
      local x, _, z = getPosXYZ(w.cube)
      local done = angleDiff(heading(w), wt.from) * (wt.turn > 0 and 1 or -1)
      local close = blockedAlong(w, x, z, travel(w), GAP / 4, GAP / 4) or nearMiss(w, x, z)
      if done >= math.abs(wt.turn) or close or simTime > wt.by then
        setShoe(w, nil)
        w.wheelTurn = nil
        w.calmUntil = simTime + COOLDOWN
        if done < math.abs(wt.turn) then   -- (a rescue: the rest of the turn, rigidly)
          startTurn(w, (math.abs(wt.turn) - math.max(done, 0)) * (wt.turn > 0 and 1 or -1))
          w.calmUntil = simTime + TURN_TIME + COOLDOWN
          room.rescues[#room.rescues + 1] = { simTime, w.spec.name, close and ((close == "wall") and "wall" or close.spec.name) or "too slow" }
        end
      end
    elseif not TEST_TRACK and not w.turnLeft then
      local x, _, z = getPosXYZ(w.cube)
      local h = travel(w)
      local byWheel = w.wheels and ROOM_STEER == "arcs"
      local what
      if simTime >= (w.calmUntil or 0) then what = blocked(w, x, z, h, byWheel and WHEEL_GAP or GAP) else what = nearMiss(w, x, z) end
      if what then
        local turn = chooseTurn(w, x, z, h, byWheel)
        if w.wheels and ROOM_STEER == "backup" then   -- (backing first, the far wheel braked)
          w.backupTurn = { from = heading(w), turn = turn, back = true, next = simTime + BACKUP_PHASE, by = simTime + WHEEL_TIME }
          room.setReverse(w, true)
          setShoe(w, (turn > 0) and "R" or "L")
        elseif byWheel then
          setShoe(w, (turn > 0) and "L" or "R")
          w.wheelTurn = { from = heading(w), turn = turn, by = simTime + WHEEL_TIME }
        else
          startTurn(w, turn)
          w.calmUntil = simTime + TURN_TIME + COOLDOWN
        end
        room.turns[#room.turns + 1] = { simTime, w.spec.name, (what == "wall") and "wall" or what.spec.name, math.deg(turn) }
        w.turns = (w.turns or 0) + 1
      end
    end
    -- (how far it has gone: in 5 s steps, so rocking in place, back and
    -- forth within a step, doesn't count as getting anywhere)
    if N % PROGRESS_EVERY == 0 then
      local x, _, z = getPosXYZ(w.cube)
      if w.p5 then
        w.travelled = w.travelled + math.sqrt((x - w.p5[1]) ^ 2 + (z - w.p5[2]) ^ 2)
        w.p5[1], w.p5[2] = x, z
      else
        w.p5 = { x, z }
      end
    end
    -- (where it was half a second and a second ago: its actual motion)
    if N % TRACK_EVERY == 0 then
      local x, _, z = getPosXYZ(w.cube)
      w.track = w.track or {}
      local last = w.track[#w.track]
      if last then
        noteTravel(w, x - last[1], z - last[2])
        w.vx, w.vz = (x - last[1]) / (TRACK_EVERY * FRAME), (z - last[2]) / (TRACK_EVERY * FRAME)
      end
      if #w.track >= 2 then
        -- (the oldest sample's table is reused: no garbage)
        local old = table.remove(w.track, 1)
        old[1], old[2] = x, z
        w.track[2] = old
      else
        w.track[#w.track + 1] = { x, z }
      end
    end
    if (N + 2 * k) % TRAIL_EVERY == 0 then markTrail(w) end
    -- (fallen? checked every frame: a cheap test on one body)
    if tilt(w) > w.tilt0 + FALL_TILT then
      w.fallenSince = w.fallenSince or simTime
      if simTime - w.fallenSince >= FALL_TIME then
        standUp(w)
        w.fallenSince = nil
        w.calmUntil = simTime + COOLDOWN
        room.righted[#room.righted + 1] = { simTime, w.spec.name }
        w.stoodUp = (w.stoodUp or 0) + 1
      end
    else
      w.fallenSince = nil
    end
    turnStep(w, FRAME)
    -- (the test track: how far it got along x, reported once)
    if TEST_TRACK then
      local x, _, z = getPosXYZ(w.cube)
      if not w.trackStart then w.trackStart = { x, z, simTime }; w.airFrames, w.allFrames = 0, 0; showBoard(w.spec.name) end
      -- (its own run against the board: its speed from 5 s to 20 s, as the table runs measure it)
      local tt = simTime - w.trackStart[3]
      if not w.x5 and tt >= 5 then w.x5 = x end
      if w.x5 and not w.boardDone and tt >= 20 then
        w.boardDone = true
        local sp = (x - w.x5) / 15
        local b = BOARDS and BOARDS[boardKey()]
        local mine
        for _, r in ipairs(b or {}) do if r[1] == w.spec.name then mine = r end end
        print(string.format("board: %s, this run %.2f cm/s from 5 s to 20 s%s", w.spec.name, sp,
          b and string.format(" -- %s; it would place %d of %d", mine and string.format("the board expects %.2f +- %.2f", mine[2], mine[3]) or "not on the board", boardPlace(b, sp, w.spec.name), #b + (mine and 0 or 1)) or ""))
      end
      -- (air: the share of frames its lowest moving part is more than
      -- 0.5 cm above the ground under it -- the whole walker off the ground)
      do
        local gap = 1e9
        for _, o in ipairs(w.bodies) do
          if o.mass > 0 and not (w.wheels and (rawequal(o, w.wheels.L.o) or rawequal(o, w.wheels.R.o))) then   -- (not the wheels, always down)
            o.body:getAabb(trackLo, trackHi)
            local top = -1e9
            for i = 0, 2 do for j = 0, 2 do
              top = math.max(top, terrainHeight(trackLo.x + (trackHi.x - trackLo.x) * i / 2, trackLo.z + (trackHi.z - trackLo.z) * j / 2))
            end end
            gap = math.min(gap, trackLo.y - top)
          end
        end
        w.airGap = gap
        if not w.trackDone then
          w.allFrames = w.allFrames + 1
          if gap > 0.5 then w.airFrames = w.airFrames + 1 end
        end
      end
      if not w.trackDone and simTime - w.trackStart[3] >= TRACK_SECS then
        w.trackDone = true
        local d = x - w.trackStart[1]
        print(string.format("TRACK %s|height %.2f|length %.1f|seed %d|forward %.1f cm|%.2f cm/s|sideways %.1f cm|stood up %d|air %.1f%%%s",
          w.spec.name, AMP, BUMP, SEED, d, d / TRACK_SECS, z - w.trackStart[2], w.stoodUp or 0, 100 * w.airFrames / w.allFrames,
          TERRAIN_MIRROR and "|ground mirrored" or ""))
      end
    end
  end
end)

-- ---------------------------------------------------------------------
-- camera: an overview of the room (O), or following one walker (Tab and
-- Shift+Tab go round them). Following moves the view with the walker but
-- does not turn it, so the mouse still turns and zooms it.
-- ---------------------------------------------------------------------

local OVERVIEW = { pos = btVector3(-620, 520, 760), look = btVector3(0, -40, 40) }
local FOLLOW_OFFSET = { -70, 60, 85 }   -- cm from the walker, the same way the overview looks
local following, followX, followZ        -- the walker followed (nil: the overview), and where it was
local lastFollowed                        -- (the last one followed: O goes back to it)

-- the wheels (SHOES): the arrow keys' lines for the help, and the status line's note
local function wheelHelp()
  if not SHOES then return "" end
  return "Left Right  brake the left (right) wheel of the walker" .. (TEST_TRACK and "" or " followed") .. ": it turns\n" ..
         "            that way; the same key again frees it, and it walks on\n" ..
         "            straight from there\n"
end
local function wheelNote(w)
  if not (w and w.wheels) then return "" end
  return (w.shoeDown == "L" and "left wheel braked" or w.shoeDown == "R" and "right wheel braked" or "wheels free") .. " | "
end

local function helpText()
  if TEST_TRACK then
    local h = "TEST TRACK -- " .. (walkers[1] and (walkers[1].spec.name .. " (" .. (walkers[1].spec.look and walkers[1].spec.look.code or "") .. ")") or "") .. "\n\n"
    if VIEWS and viewAt > 0 then h = h .. VIEWS[viewAt].label .. "\n\n" end
    h = h .. "Tab         put the next walker on the track (built again): the next\n"
    h = h .. "            down this ground's ranking board\n"
    h = h .. "Shift+Tab   the one before\n"
    h = h .. wheelHelp()
    h = h .. "1 2 3 4     the ground: waves, random, logs, steps (now " .. TERRAIN .. ")\n"
    h = h .. "M           the ground mirrored left for right, or back (now " .. (TERRAIN_MIRROR and "mirrored" or "normal") .. ")\n"
    h = h .. "N           the next seed, 1 to 4 (now " .. SEED .. ")\n"
    h = h .. "O           look over the whole track (O again: follow it again)\n"
    h = h .. "F           follow the walker again\n"
    h = h .. "B           the ranking board for this ground (output pane)\n"
    h = h .. "G           build the track again with the sliders' height and length\n"
    h = h .. "Mouse       turn and zoom the view (while following, it still follows)\n\n"
    h = h .. "It walks straight for " .. TRACK_SECS .. " s, then prints how far it got (the\n"
    h = h .. "output pane), and carries on. TerrainHeight and BumpLength (Params\n"
    h = h .. "pane) set the next ground; G builds it, with the same walker (1-4, M\n"
    h = h .. "and N build with them too).\n\n"
    h = h .. "Each time it starts, the output pane shows the ranking board for\n"
    h = h .. "this ground (terrain and height to the cm): every walker's mean speed\n"
    h = h .. "there in the table runs, this one marked; at 20 s, its own run beside it.\n\n"
    h = h .. "The status line (bottom) shows its speed so far and how much of the\n"
    h = h .. "time it has been off the ground (its lowest part more than 0.5 cm\n"
    h = h .. "up); its body turns red whenever it is.\n"
    return h
  end
  local h = "WALKER ROOM -- " .. (following and ("following " .. following.spec.name .. " (" .. codeOf(following.spec) .. "trail " .. following.colour[1] .. ")")
                                           or "looking over the room") .. "\n\n"
  if ROOM_SWAP then
    h = h .. "F           follow the next walker\n"
    h = h .. "Tab         put the next walker in place of the one followed (it walks\n"
    h = h .. "            on from there; the others carry on)\n"
    h = h .. "Shift+Tab   the one before\n"
  else
    h = h .. "Tab         follow the next walker\n"
    h = h .. "Shift+Tab   follow the one before\n"
  end
  h = h .. wheelHelp()
  h = h .. "1 2 3 4     the ground: waves, random, logs, steps (now " .. TERRAIN .. "; built again)\n"
  h = h .. "O           look over the whole room (O again: follow again)\n"
  h = h .. "T           clear the trails\n"
  h = h .. "G           build the room again with the sliders' height and length\n"
  h = h .. "Mouse       turn and zoom the view (while following, it still follows)\n\n"
  h = h .. "Rest the pointer on a walker, or on a trail, to see whose it is,\n"
  h = h .. "how far it has gone, its average speed, and how often it has turned\nor been stood up.\n\n"
  h = h .. "TerrainHeight (Params pane): how high the bumps are, 0 to " .. AMP_MAX .. " cm.\n"
  h = h .. "BumpLength: how long they are, " .. BUMP_MIN .. " to " .. BUMP_MAX .. " cm (every walker's stride is " .. STRIDE .. " cm).\n"
  h = h .. "Moving them builds nothing: G builds the room with them, every walker\n"
  h = h .. "back at its start (the 1-4 keys build with them too).\n\n"
  h = h .. "Each body shows its walker's code: its linkage's inventor(s) -- J Jansen,\n"
  h = h .. "K Klann, C Chebyshev, H Hoecken, S Spears; -S: a linkage Spears changed,\n"
  h = h .. "which also has a gold rim -- then its number of bars, S if a slider. A\n"
  h = h .. "line across the body: a diag build. The colour is the linkage's.\n\n"
  h = h .. "Walkers and their trails:\n"
  for _, w in ipairs(walkers) do
    h = h .. string.format("  %-7s %-27s %s\n", w.spec.look and w.spec.look.code or "", w.spec.name, w.colour[1])
  end
  return h
end

local function follow(w)
  following = w
  if w then lastFollowed = w end
  if w then
    local x, y, z = getPosXYZ(w.cube)
    common.setCamera(btVector3(x + FOLLOW_OFFSET[1], y + FOLLOW_OFFSET[2], z + FOLLOW_OFFSET[3]), btVector3(x, y, z), 0.75)
    followX, followZ = x, z
  else
    common.setCamera(OVERVIEW.pos, OVERVIEW.look, 0.75)
  end
  v:setHelpText(helpText())
end

v:postSim(function(N)
  threadsSpent, threadsFrames = threadsSpent + (v:getTime() - threadsT0), threadsFrames + 1
  if following then
    -- (moved by how far the walker has gone across the ground; not up and
    -- down, so the view doesn't bob with its gait)
    local x, _, z = getPosXYZ(following.cube)
    local dx, dz = x - followX, z - followZ
    if dx * dx + dz * dz > 0.01 then
      local c = v.cam
      local p, l = c.pos, c.look
      c.pos = btVector3(p.x + dx, p.y, p.z + dz)
      c.look = btVector3(l.x + dx, l.y, l.z + dz)
      followX, followZ = x, z
    end
  end
end)

-- on the test track, Tab and Shift+Tab put the next (or the one before)
-- walker on the track instead, on the same ground (its trail cleared);
-- a new ground (1-4) builds the track again
-- (with VIEWS it goes through those instead: see setView, above)
local function rebuildTrack()
  teardownRoom()
  makeTerrain()
  buildRoom()
  follow(walkers[1])
end
local function replaceWalker()
  teardownWalkers()
  placeWalkers()
  follow(walkers[1])
end
local function trackNext(step)
  local b = BOARDS and BOARDS[boardKey()]
  if VIEWS and b then
    -- (in the order of this ground's board, best first; any view not on it after, in VIEWS' order)
    local rank, order = {}, {}
    for i, r in ipairs(b) do rank[r[1]] = i end
    for i = 1, #VIEWS do order[#order + 1] = i end
    table.sort(order, function(i, j)
      local a, c = rank[VIEWS[i].walker] or (#b + i), rank[VIEWS[j].walker] or (#b + j)
      return a < c
    end)
    local at = 1
    for k, i in ipairs(order) do if i == viewAt then at = k end end
    setView(order[(at - 1 + step) % #order + 1])
  elseif VIEWS then
    setView((viewAt - 1 + step) % #VIEWS + 1)
  else
    local k = 1
    for i, spec in ipairs(WALKERS) do if spec.name == ONLY then k = i end end
    k = (k - 1 + step) % #WALKERS + 1
    ONLY = WALKERS[k].name
  end
  replaceWalker()
  print("test track: " .. ONLY .. (VIEWS and (" -- " .. VIEWS[viewAt].label) or ""))
end
-- the test track's ground: 1 waves, 2 random, 3 logs, 4 steps (built again)
local TERRAIN_KEYS = { ["1"] = "waves", ["2"] = "random", ["3"] = "logs", ["4"] = "steps" }
-- (and M: the same ground mirrored left for right, or back; N: the next
-- seed, 1 to 4 -- where it starts, and the random landscape -- as the
-- headless runs' SEED)

-- ROOM_SWAP (the room, not the test track; room-four.lua): a list of
-- walkers. Tab / Shift+Tab put the next (or the one before) of them not in
-- the room already in place of the walker followed -- where it is, facing
-- its way -- while the others walk on; F follows the next walker (Tab's job
-- without ROOM_SWAP). ROOM_FIXED: { [name] = true } stay put.
local function swapWalker(w, step)
  if not w then print("room: follow a walker first (F)"); return end
  if ROOM_FIXED and ROOM_FIXED[w.spec.name] then print("room: " .. w.spec.name .. " stays (F follows another)"); return end
  local inRoom, at = {}, 0
  for _, o in ipairs(walkers) do inRoom[o.spec.name] = true end
  for i, n in ipairs(ROOM_SWAP) do if n == w.spec.name then at = i end end
  local name
  for i = 1, #ROOM_SWAP do
    local n = ROOM_SWAP[(at - 1 + step * i) % #ROOM_SWAP + 1]
    if not inRoom[n] then name = n; break end
  end
  local spec
  for _, sp in ipairs(WALKERS) do if sp.name == name then spec = sp end end
  if not spec then print("room: no other walker to put in"); return end
  -- the old one out: its joints, its parts and marks, its trail
  local x, _, z = getPosXYZ(w.cube)
  local hd, k = heading(w), w.index
  local out = {}
  for _, con in ipairs(w.constraints) do v:removeConstraint(con); out[con] = true end
  for _, o in ipairs(w.objects) do v:remove(o); out[o] = true end
  local keep = {}
  for _, con in ipairs(roomConstraints) do if not out[con] then keep[#keep + 1] = con end end
  roomConstraints = keep
  keep = {}
  for _, o in ipairs(roomObjects) do if not out[o] then keep[#keep + 1] = o end end
  roomObjects = keep
  for _, o in ipairs(w.bodies) do owner[objectKey(o)] = nil end
  for cell, by in pairs(painted) do
    if by == w then painted[cell] = nil; local i, j = math.floor(cell / NZ), cell % NZ; paintCell(i, j, cellColour(i, j)) end
  end
  table.remove(walkers, k)
  -- the new one in its place, facing its way, with its colour and its place in the list
  local nw = addWalker(spec, x, z, hd)
  table.remove(walkers, #walkers)
  table.insert(walkers, k, nw)
  nw.colour, nw.index, nw.travelled = w.colour, k, 0
  for _, o in ipairs(nw.bodies) do owner[objectKey(o)] = nw end
  if type(ONLY) == "table" then ONLY[w.spec.name] = nil; ONLY[name] = true end   -- (so building the room again keeps it)
  print("room: " .. name .. " in place of " .. w.spec.name)
  follow(nw)
end

-- what the sliders are waiting to build ("" when nothing)
local function slidersNote()
  if not (pendingAmp or pendingBump) then return "" end
  return string.format("TerrainHeight %d, BumpLength %d: press G to build (now %g, %g)",
    pendingAmp or AMP, pendingBump or BUMP, AMP, BUMP)
end
-- G: the room (or the track) built again with the sliders' values, the
-- same walkers on it, the same one followed
local function buildWithSliders()
  if not (pendingAmp or pendingBump) then
    print(string.format("G: the ground is already TerrainHeight %g, BumpLength %g (move a slider first)", AMP, BUMP))
    return
  end
  local k = following and following.index
  local c0 = os.clock()
  teardownRoom()
  buildRoom()
  follow(k and walkers[k] or nil)
  print(string.format("TerrainHeight = %g cm, BumpLength = %g cm (built again in %.1f s)", AMP, BUMP, os.clock() - c0))
end

v:onKey(function(N, key, down)
  if key == "G" then
    if down then buildWithSliders() end
    return true
  end
  if TEST_TRACK and (key == "Tab" or key == "Backtab") then
    if down then trackNext(key == "Tab" and 1 or -1) end
    return true
  end
  if TEST_TRACK and TERRAIN_KEYS[key] then
    if down then
      TERRAIN = TERRAIN_KEYS[key]
      rebuildTrack()
      print("test track: " .. TERRAIN)
    end
    return true
  end
  if TEST_TRACK and key == "F" then   -- (follow the walker again, after the overview)
    if down and walkers[1] then follow(walkers[1]) end
    return true
  end
  if TEST_TRACK and key == "B" then
    if down and walkers[1] then showBoard(walkers[1].spec.name) end
    return true
  end
  if TEST_TRACK and (key == "M" or key == "N") then
    if down then
      if key == "M" then TERRAIN_MIRROR = not TERRAIN_MIRROR
      else
        SEED = SEED % 4 + 1
        if not TERRAIN_SEED_SET then TERRAIN_SEED = SEED end
      end
      rebuildTrack()
      print("test track: " .. TERRAIN .. (TERRAIN_MIRROR and ", mirrored" or "") .. ", seed " .. SEED)
    end
    return true
  end
  if ROOM_SWAP and (key == "Tab" or key == "Backtab") then
    if down then swapWalker(following, key == "Tab" and 1 or -1) end
    return true
  end
  if key == "Left" or key == "Right" then   -- (the wheels, SHOES: brake one side's, or free it)
    if down then
      local w = TEST_TRACK and walkers[1] or following
      if not SHOES then print("the wheels are off (SHOES = false)")
      elseif not w then print("room: follow a walker first (" .. (ROOM_SWAP and "F" or "Tab") .. ")")
      else
        local side = (key == "Left") and "L" or "R"
        w.wheelTurn = nil   -- (a turn the room was making: yours now)
        if w.backupTurn then w.backupTurn = nil; room.setReverse(w, false) end
        room.setShoe(w, (w.shoeDown ~= side) and side or nil)
        w.byHand = w.shoeDown and true or nil   -- (the room leaves it alone while it's braked)
        print(w.spec.name .. ": " .. wheelNote(w):sub(1, -4))
      end
    end
    return true   -- (not the camera's: bpp would move the view)
  end
  if not TEST_TRACK and TERRAIN_KEYS[key] then   -- (the room's ground, built again with the same walkers)
    if down then
      TERRAIN = TERRAIN_KEYS[key]
      makeTerrain()   -- (the new kind's bumps; without it the room was built again on the old ground)
      local k = following and following.index
      teardownRoom()
      buildRoom()
      follow(k and walkers[k] or nil)
      print("room: " .. TERRAIN)
    end
    return true
  end
  if key == "Tab" or key == "Backtab" or (ROOM_SWAP and key == "F") then
    if down and #walkers > 0 then
      local k = following and following.index or 0
      if key == "Backtab" then k = (k - 2) % #walkers + 1 else k = k % #walkers + 1 end
      follow(walkers[k])
    end
    return true
  elseif key == "O" then   -- (the overview, or back to following)
    if down then
      if following then follow(nil)
      else
        local back = walkers[1]
        for _, o in ipairs(walkers) do if o == lastFollowed then back = o end end
        follow(back)
      end
    end
    return true
  elseif key == "T" then
    if down then clearTrails() end
    return true
  end
end)

-- the hover: whose walker or trail is under the pointer
v:onHover(function(N, obj, x, y, z)
  local w = owner[objectKey(obj)]
  local first
  if w then
    first = w.spec.name .. " (" .. codeOf(w.spec) .. "trail " .. w.colour[1] .. ")"
  elseif rawequal(obj, floor) then
    local cell = cellAt(x, z)
    w = cell and painted[cell]
    first = w and ("the " .. w.colour[1] .. " trail of " .. w.spec.name)
  end
  if not w then return nil end
  return string.format("%s\nhas gone %.0f cm in %.0f s (%.1f cm/s)\nturned %d times, stood up %d times",
    first, w.travelled, simTime, w.travelled / math.max(simTime, 1e-9), w.turns or 0, w.stoodUp or 0)
end)

-- the TerrainHeight and BumpLength sliders, in whole centimetres: they
-- only set the next ground's height and length (pendingAmp, pendingBump),
-- shown on the status line, and G (or any key that builds) builds it
local draws = 0
v:onParamChanged(function(N, name, value)
  value = math.floor(value + 0.5)
  if name == "TerrainHeight" then pendingAmp = (value ~= AMP) and value or nil end
  if name == "BumpLength" then pendingBump = (value ~= BUMP) and value or nil end
  if name == "Threads" then
    THREADS = value
    v:setThreads(THREADS)
    threadsSpent, threadsFrames, threadsWall0 = 0, 0, v:getTime()
  end
  v.statusText = slidersNote()
end)
local AIR_COLOUR = "#FF2020"
v:preDraw(function(N)
  draws = draws + 1
  -- (the room: the status line shows how fast, about once a second when it
  -- keeps up, as ../Testing_Threads.lua; and in the terminal, to copy)
  if not TEST_TRACK and threadsFrames >= 60 then
    local per, now = threadsSpent / threadsFrames, v:getTime()
    local seen = threadsFrames * FRAME / (now - threadsWall0)
    if THREADS == 0 then threadsBase = per end
    local line
    if not HAS_THREADS and THREADS > 0 then
      line = "this bpp has no threads: build it with scripts/bullet-threads.sh and qmake CONFIG+=bundled_bullet"
    else
      line = string.format("threads %d | physics %.1f ms a frame: %.2fx real time | you see %.2fx", THREADS,
        per * 1000, FRAME / per, seen)
      if threadsBase and THREADS > 0 then line = line .. string.format(" | %.1fx as fast as no threads", threadsBase / per) end
      if not threadsBase then line = line .. " | set Threads to 0 for a while to measure it without" end
    end
    local note = slidersNote()
    v.statusText = (note ~= "" and (note .. " | ") or "") .. wheelNote(following) .. line
    io.stdout:write("room: ", line, "\n"); io.stdout:flush()
    threadsSpent, threadsFrames, threadsWall0 = 0, 0, now
  end
  -- (the test track: the status line shows where the walker is at, and
  -- its body turns red while it is off the ground)
  local w = TEST_TRACK and walkers[1]
  if w and w.allFrames then
    local up = (w.airGap or 0) > 0.5
    if w.bodyColour == nil then w.bodyColour = w.cube.col end
    if up ~= w.shownUp then w.cube.col = up and AIR_COLOUR or w.bodyColour; w.shownUp = up end
    if draws % 10 == 0 then
      local x = getPosXYZ(w.cube)
      local t = simTime - w.trackStart[3]
      local note = slidersNote()
      v.statusText = (note ~= "" and (note .. " | ") or "") .. wheelNote(w) ..
        string.format("%s%s | %s | %.0f s | %.2f cm/s | off the ground %.0f%% of the time | now %.1f cm up",
        w.spec.name, VIEWS and viewAt > 0 and (" (" .. VIEWS[viewAt].label .. ")") or "", TERRAIN, t,
        (x - w.trackStart[1]) / math.max(t, 1e-9), 100 * w.airFrames / math.max(w.allFrames, 1), math.max(w.airGap or 0, 0))
    end
  end
end)

follow(TEST_TRACK and walkers[1] or nil)
