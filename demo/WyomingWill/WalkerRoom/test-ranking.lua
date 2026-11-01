--
-- Test track: the walkers that could really be built (diag builds with
-- their outside braces, and Klann, Jansen and Spears 4-bar on their own
-- frames), best first (31 October, handover section 4m). First written for
-- the 29 October ranking (section 4h), at its standard: 200 solver
-- iterations, the motor at 0.5 a crank, 1.0 cm links, trot, forward;
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
MOTOR_STRENGTH = MOTOR_STRENGTH or 2   -- (0.5 a crank, weight x stride units: 2 shared by the 4 cranks)
GRAVITY = 981
ANKLE_SPRING = ANKLE_SPRING or { stiffness = 42000, damping = 4200 }
YAW_DAMP = YAW_DAMP or 1
LINK_WIDTH = 1.0
DIAG_OUTSIDE = true

local TROT = { 0, 180, 180, 0 }
local function guides(name) return { walker = name, label = "guides, trot, forward", gait = TROT, unbraced = true, hold = false } end
local function diag(name) return { walker = name, label = "outside braces, pendants held (trot), forward", hold = true } end
local function own(name) return { walker = name, label = "its own frame, trot, forward", gait = TROT, hold = false } end
VIEWS = {   -- (31 October: the builds that could really be built -- diag and own frame, no guides -- best first in the
            -- 21-build table, handover section 4m: fast setting, nine rough terrains, 5 seeds; mean cm/s)
  diag("Chebyshev-Spears lift 51 diag"),       --  7.77
  diag("Chebyshev-Spears lift 62 diag"),       --  7.00
  diag("Chebyshev-Spears diag"),               --  6.97
  diag("Hoecken-Spears 4-bar diag"),           --  6.84
  diag("Hoecken-Spears slider diag"),          --  6.23 (toes)
  own("Klann"),                                --  6.05
  own("Jansen"),                               --  5.91
  diag("Hoecken slider diag"),                 --  5.39
  diag("Hoecken 4-bar diag"),                  --  4.88
  diag("Chebyshev diag"),                      --  4.50
  own("Spears 4-bar"),                         --  4.10
  -- (left out: the guides builds -- the guides are not really there, so they are not for viewing; they stay in the
  -- repo and the runs -- and Hoecken-Spears 4-bar duty 85 diag, 6.61, which adds little. VIEWS_ALL = true: these too.)
}
if VIEWS_ALL then
  for _, n in ipairs({ "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 62", "Chebyshev-Spears", "Hoecken-Spears 4-bar",
                       "Hoecken-Spears slider", "Hoecken slider", "Hoecken 4-bar", "Chebyshev", "Hoecken-Spears 4-bar duty 85" }) do
    VIEWS[#VIEWS + 1] = guides(n)
  end
  VIEWS[#VIEWS + 1] = diag("Hoecken-Spears 4-bar duty 85 diag")
end
VIEW = VIEW or 1

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds and the sliders' diag builds)
dofile("spears-lift-walkers.lua")   -- (Chebyshev-Spears lift 51 and 62, and their diag builds)

TERRAIN = TERRAIN or "logs"
AMP = AMP or 7
BUMP = BUMP or 15
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60

dofile("test-track.lua")
