--
-- Test square: the test track on a square of ground, for watching each
-- walker's best version (README, "The factorial runs") walk over each kind
-- of ground -- and how much of the time it is off the ground.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker, built, timed and
--                    turned its own best way
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
-- The TerrainHeight and BumpLength sliders (Params pane) build it again.
-- The status line (bottom) shows the walker's speed so far and the share
-- of the time it has been off the ground (its lowest part more than
-- 0.5 cm up); its body turns red whenever it is.
--
-- The walkers, best first (mean speed over the four kinds of ground, the
-- crank never turned faster than its normal speed). Each is set as in the
-- test runs: REVERSE, GAIT (trot: diagonal legs together), UNBRACED
-- (plates off, each leg held at its angle to the body by a guide) and its
-- crank speed (CRANK_SCALE).
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

local TROT = { 0, 180, 180, 0 }
VIEWS = {
  { walker = "Klann", label = "own frame, trot, reversed", reverse = true, gait = TROT, crank = 0.9504 },
  { walker = "Spears lift 44 diag", label = "diagonal braces (trot), forward" },
  { walker = "Jansen", label = "own frame, trot, reversed", reverse = true, gait = TROT },
  { walker = "Spears 4-bar", label = "own frame, trot, reversed", reverse = true, gait = TROT },
  { walker = "Spears lift 53", label = "guides, trot, forward", gait = TROT, unbraced = true },
  { walker = "Chebyshev-Spears diag", label = "diagonal braces (trot), reversed", reverse = true },
  { walker = "Hoecken-Spears long-stance diag", label = "diagonal braces (trot), reversed", reverse = true },
  { walker = "Hoecken-Spears 4-bar diag", label = "diagonal braces (trot), reversed", reverse = true },
  { walker = "Hoecken 4-bar", label = "guides, trot, reversed", reverse = true, gait = TROT, unbraced = true },
  { walker = "Hoecken-Spears slider", label = "guides, trot, reversed", reverse = true, gait = TROT, unbraced = true },
  { walker = "Hoecken slider", label = "guides, trot, reversed", reverse = true, gait = TROT, unbraced = true },
  { walker = "Chebyshev", label = "guides, trot, reversed", reverse = true, gait = TROT, unbraced = true },
}
VIEW = VIEW or 1                    -- the one it starts with

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Spears lift 44 and 53, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4                      -- bump height, cm
BUMP = BUMP or 15                   -- bump length, cm (every stride is 15)
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60       -- it prints how far it got after this long, and carries on

TEST_TRACK = true
ARENA_X = ARENA_X or 700            -- the square: 7 m each way
ARENA_Z = ARENA_Z or 700

dofile("walker-room.lua")
