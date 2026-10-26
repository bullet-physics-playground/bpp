--
-- Test square, one link width: every walker that goes into the runs, as it
-- is run (Jansen, Klann and Spears 4-bar on their own frames, the others on
-- guides, and the diag builds with outside braces and held pendants),
-- trotting forward, with every bar 1.0 cm wide (walker-room.lua, LINK_WIDTH;
-- handover section 4b), at the Earth standard. LINK_WIDTH = false below
-- shows them with their own files' widths, to compare.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   M                the ground mirrored left for right, or back
--   N                the next seed, 1 to 4
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole track
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1
if LINK_WIDTH == nil then LINK_WIDTH = 1.0 end
DIAG_OUTSIDE = true
OUTSIDE_V = OUTSIDE_V or false   -- (true: V bottom braces; left off, 25 October)

local TROT = { 0, 180, 180, 0 }
VIEWS = {}
for _, n in ipairs({ "Jansen", "Klann", "Spears 4-bar" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "own frame, trot, forward", gait = TROT, hold = false }
end
for _, n in ipairs({ "Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken-Spears 4-bar", "Hoecken-Spears long-stance",
                     "Spears lift 44", "Spears lift 53" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false }
  VIEWS[#VIEWS + 1] = { walker = n .. " diag", label = "outside braces, pendants held (trot), forward", hold = true }
end
for _, n in ipairs({ "Hoecken slider", "Hoecken-Spears slider" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false }
end
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Spears lift 44 and 53, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

dofile("test-track.lua")            -- (the 8 m track)
