--
-- Test track, the 24 October check: Chebyshev-Spears and Hoecken-Spears
-- 4-bar, each on guides (trot) and with outside braces and held pendants,
-- forward, as handover section 4b's check runs: waves 4, bump 15, the 6 m
-- track, the Earth standard with the standard ankle springs, and the
-- advances measured in trot.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   M                the ground mirrored left for right, or back
--   N                the next seed, 1 to 4 (where it starts)
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole track
-- After 60 s each prints its speed in the output pane; the check runs'
-- speeds are in handover/data/chk36.txt.
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1
DIAG_OUTSIDE = true

local TROT = { 0, 180, 180, 0 }
VIEWS = {
  { walker = "Chebyshev-Spears", label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false },
  { walker = "Chebyshev-Spears diag", label = "outside braces, pendants held (trot), forward", hold = true },
  { walker = "Hoecken-Spears 4-bar", label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false },
  { walker = "Hoecken-Spears 4-bar diag", label = "outside braces, pendants held (trot), forward", hold = true },
}
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Chebyshev-Spears lift 51 and 62, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

dofile("test-track.lua")            -- (the test track: 10 m long, 8 m wide since 25 October. The check runs had
                                    -- 6 m; a different width changes runs a little, as another start would, so
                                    -- for the check runs themselves add ARENA_Z = 600 at the top of this file)
