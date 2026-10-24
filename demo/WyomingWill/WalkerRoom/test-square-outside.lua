--
-- Test square, outside braces: Chebyshev-Spears diag and Hoecken-Spears
-- 4-bar diag with both braces built outside their pendants (walker-room.lua,
-- DIAG_OUTSIDE) and their pendants held at their angle to the body
-- (PENDANT_HOLD), each next to its guides cousin, at the Earth standard
-- (as test-square-earth.lua).
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
--
-- DIAG_LIGHT = 0.5 (uncomment below) builds the braces at half their
-- weight.
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1

DIAG_OUTSIDE = true
PENDANT_HOLD = { ["Chebyshev-Spears diag"] = true, ["Hoecken-Spears 4-bar diag"] = true }
-- DIAG_LIGHT = 0.5

local TROT = { 0, 180, 180, 0 }
VIEWS = {
  { walker = "Chebyshev-Spears diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Chebyshev-Spears", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Hoecken-Spears 4-bar diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Hoecken-Spears 4-bar", label = "guides, trot, forward", gait = TROT, unbraced = true },
}
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
