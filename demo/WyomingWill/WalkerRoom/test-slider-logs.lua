--
-- Test track, 28 October: Chebyshev-Spears diag against Hoecken-Spears
-- slider diag (and the Hoecken slider diag, and both Spears builds on
-- guides), on 7 cm logs, seed 1 -- where the slider stalls and
-- Chebyshev-Spears gets over. The standard of the 28 October table
-- (handover sections 4d and 4e): 200 solver iterations, the motor at 0.25 a
-- crank, 1.0 cm links, outside braces with held pendants, trot, forward.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   N                the next seed, 1 to 4 (where it starts)
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole track
-- In the 20 s runs the slider's back foot swings forward at about 5 cm,
-- meets the log's side every turn and slides back, its body staying level;
-- Chebyshev-Spears' back foot meets the log's side too, but its body tips
-- and it works its way over (about 12 s in).
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

v:setSolverInfo("residual", 0.01)   -- (stop iterating once settled: about 15% faster, the same result)
SOLVER_ITERATIONS = SOLVER_ITERATIONS or 200
MOTOR_STRENGTH = MOTOR_STRENGTH or 2   -- (0.25 a crank in effect: the hinge motors reach half their set torque)
GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1
LINK_WIDTH = 1.0
DIAG_OUTSIDE = true

local TROT = { 0, 180, 180, 0 }
VIEWS = {
  { walker = "Chebyshev-Spears diag", label = "outside braces, pendants held (trot), forward", hold = true },
  { walker = "Hoecken-Spears slider diag", label = "outside braces, pendants held (trot), forward", hold = true },
  { walker = "Hoecken slider diag", label = "outside braces, pendants held (trot), forward", hold = true },
  { walker = "Chebyshev-Spears", label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false },
  { walker = "Hoecken-Spears slider", label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false },
}
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds and the sliders' diag builds)
dofile("spears-lift-walkers.lua")

TERRAIN = TERRAIN or "logs"
AMP = AMP or 7
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

dofile("test-track.lua")
