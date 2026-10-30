--
-- Test track, 29 October: the 5-seed ranking's builds (handover section
-- 4h), best first, at the standard the ranking was run at: 200 solver
-- iterations, the motor at 0.25 a crank, 1.0 cm links, trot, forward;
-- diag builds with outside braces and held pendants, guides builds
-- with their legs held by guides; both Hoecken-Spears slider builds with
-- their feet's ends turned up (their specs' footTips), everyone else flat
-- feet. It starts on 7 cm logs, seed 1.
--
-- QUALITY = "accurate" at the top of this file runs it as measured (see below).
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) walker
--   N                the next seed, 1 to 4 (where it starts)
--   1 2 3 4          the ground: waves, random, logs, steps
--   M                the ground mirrored left for right, or back
--   O                look over the whole track
-- The TerrainHeight slider sets the bumps' height (the ranking used
-- waves 2/4/6, logs 3/5/7 and steps 3/5/7). After 60 s each prints its
-- speed in the output pane (the ranking's runs were 20 s, speed from 5 s
-- on).
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
local function guides(name) return { walker = name, label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false } end
local function diag(name) return { walker = name, label = "outside braces, pendants held (trot), forward", hold = true } end
local function own(name) return { walker = name, label = "its own frame, trot, forward", gait = TROT, hold = false } end
VIEWS = {   -- (the ranking's order: nine rough terrains, 5 seeds)
  guides("Spears lift 44"),                    --  1  7.84
  diag("Spears lift 44 diag"),                 --  2  7.59
  guides("Spears lift 53"),                    --  3  7.04
  diag("Chebyshev-Spears diag"),               --  4  6.90
  diag("Hoecken-Spears 4-bar diag"),           --  5  6.86
  diag("Spears lift 53 diag"),                 --  6  6.83
  diag("Hoecken-Spears long-stance diag"),     --  7  6.81
  diag("Hoecken-Spears slider diag"),          --  8  6.43 (toes)
  guides("Hoecken-Spears slider"),             --  9  6.35 (toes)
  guides("Hoecken-Spears 4-bar"),              -- 10  6.30
  own("Klann"),                                -- 11  6.22
  own("Jansen"),                               -- 12  6.18
  guides("Hoecken-Spears long-stance"),        -- 13  5.23
  -- (and the originals the Spears builds came from, below the ranking)
  guides("Hoecken slider"),
  guides("Hoecken 4-bar"),
  guides("Chebyshev"),
  own("Spears 4-bar"),
}
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds and the sliders' diag builds)
dofile("spears-lift-walkers.lua")   -- (Spears lift 44 and 53, and their diag builds)

TERRAIN = TERRAIN or "logs"
AMP = AMP or 7
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

dofile("test-track.lua")
