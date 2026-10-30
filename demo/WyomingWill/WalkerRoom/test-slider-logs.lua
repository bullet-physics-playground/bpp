--
-- Test track, 28 October: Chebyshev-Spears diag against Hoecken-Spears
-- slider diag (and the Hoecken slider diag, and both Spears builds on
-- guides), on 7 cm logs, seed 1 -- where the slider stalls and
-- Chebyshev-Spears gets over. The standard of the 28 October table
-- (handover sections 4d and 4e): 200 solver iterations, the motor at 0.25 a
-- crank, 1.0 cm links, outside braces with held pendants, trot, forward.
--
-- QUALITY = "accurate" at the top of this file runs it as measured (see below).
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
-- (29 October: with flat feet. Hoecken-Spears slider diag now has its
-- feet's ends turned up, 1.0 cm at 30 degrees -- spec.footTips, handover
-- section 4g -- and gets over in two seeds of three; FOOT_TIPS_OFF = true at
-- the top of this file shows it as it was.)
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

-- QUALITY: "fast" (the default here, to watch): the solver carrying each joint's force over from one physics
-- step to the next (v:setSolver("si-warm")), 40 iterations, a 1/1920 s step and a 3 m-wide track -- about four
-- times as fast, starting in a few seconds; it walks as the measured runs did, though not move for move (handover
-- section 4i). "accurate": exactly what the 29 October ranking used (Bullet's solver, 200 iterations, a 1/3840 s
-- step, the 8 m track).
QUALITY = QUALITY or "fast"
v:setSolverInfo("residual", 0.01)   -- (stop iterating once settled: about 15% faster, the same result)
if QUALITY == "fast" then
  v:setSolver("si-warm")
  SOLVER_ITERATIONS = SOLVER_ITERATIONS or 40
  FIXED = 1 / 1920
  ARENA_Z = ARENA_Z or 300
else
  SOLVER_ITERATIONS = SOLVER_ITERATIONS or 200
  FIXED = 1 / 3840
end
MOTOR_STRENGTH = MOTOR_STRENGTH or 2   -- (0.25 a crank in effect: the hinge motors reach half their set torque)
GRAVITY = 981
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
