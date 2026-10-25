--
-- Test square, plated builds: the nine builds with side plates, as built
-- (each side's two legs welded to one plate, so they move together: the
-- sides gait, the two sides half a turn apart), each without and then with
-- its pendants held at their angle to the body (PENDANT_HOLD, as the diag
-- builds with outside braces have them), at the Earth standard (as
-- test-square-earth.lua). The plates are low (PLATE_LOW): each a 1.074 cm
-- bar at its diag cousin's bottom brace's clearance; PLATE_LOW = false
-- below shows them as built.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
--
-- What to look for: with the body free to pitch and roll, the sides gait
-- tips the body onto one side's feet (why the sides gaits were dropped).
-- With the body free, held pendants slow the cranks (the sliders' most);
-- with the body damped they walk about as fast held as free.
-- To see them with the body damped every way, as the walkers' own files
-- have it (they walked that way before 21 October), set BODY_ANG_DAMP = 1
-- below.
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1
-- every bar 1.0 cm wide (LINK_WIDTH, handover section 4b); false: each file's own width
if LINK_WIDTH == nil then LINK_WIDTH = 1.0 end
-- BODY_ANG_DAMP = 1
if PLATE_LOW == nil then PLATE_LOW = true end

local PLATED = { "Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken-Spears 4-bar", "Hoecken-Spears long-stance",
                 "Spears lift 44", "Spears lift 53", "Hoecken slider", "Hoecken-Spears slider" }
VIEWS = {}
for _, n in ipairs(PLATED) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "plates, sides (as built), forward", hold = false }
  VIEWS[#VIEWS + 1] = { walker = n, label = "plates, pendants held, sides (as built), forward", hold = true }
end
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Spears lift 44 and 53, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

TEST_TRACK = true
ARENA_X = ARENA_X or 700
ARENA_Z = ARENA_Z or 700

dofile("walker-room.lua")
