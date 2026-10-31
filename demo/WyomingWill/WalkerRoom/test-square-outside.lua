--
-- Test square, outside braces: every diag build (Chebyshev-Spears,
-- Hoecken-Spears 4-bar, Chebyshev, Hoecken 4-bar, Hoecken-Spears
-- duty 85, Chebyshev-Spears lift 51 and 62) with both braces built outside its
-- pendants (walker-room.lua, DIAG_OUTSIDE) and its pendants held at their
-- angle to the body (PENDANT_HOLD), each next to its guides cousin, at the
-- Earth standard (as test-square-earth.lua).
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
-- every bar 1.0 cm wide (LINK_WIDTH, handover section 4b); false: each file's own width
if LINK_WIDTH == nil then LINK_WIDTH = 1.0 end

DIAG_OUTSIDE = true
-- OUTSIDE_V = true: the bottom brace a V seen from the side (William, 25 October: left off; option A
-- found it about 0.2 cm/s slower); off, flat, as patch 33 built it
OUTSIDE_V = OUTSIDE_V or false
PENDANT_HOLD = { ["Chebyshev-Spears diag"] = true, ["Hoecken-Spears 4-bar diag"] = true, ["Chebyshev diag"] = true,
  ["Hoecken 4-bar diag"] = true, ["Hoecken-Spears 4-bar duty 85 diag"] = true, ["Chebyshev-Spears lift 51 diag"] = true,
  ["Chebyshev-Spears lift 62 diag"] = true }
-- DIAG_LIGHT = 0.5

local TROT = { 0, 180, 180, 0 }
VIEWS = {
  { walker = "Chebyshev-Spears diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Chebyshev-Spears", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Hoecken-Spears 4-bar diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Hoecken-Spears 4-bar", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Chebyshev diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Chebyshev", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Hoecken 4-bar diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Hoecken 4-bar", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Hoecken-Spears 4-bar duty 85 diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Hoecken-Spears 4-bar duty 85", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Chebyshev-Spears lift 51 diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Chebyshev-Spears lift 51", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Chebyshev-Spears lift 62 diag", label = "outside braces, pendants held (trot), forward" },
  { walker = "Chebyshev-Spears lift 62", label = "guides, trot, forward", gait = TROT, unbraced = true },
}
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Chebyshev-Spears lift 51 and 62, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

TEST_TRACK = true
ARENA_X = ARENA_X or 700
ARENA_Z = ARENA_Z or 700

dofile("walker-room.lua")
