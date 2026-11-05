--
-- The room with four walkers: Klann and Jansen always, and two of the nine
-- other walkers that could really be built (the diag builds, with their
-- outside braces, and Spears 4-bar), walking freely in the walled room and
-- steering round the walls and each other -- to watch them walk side by side.
--
-- Open this file in bpp and click the 3D view first, then:
--   F                follow the next of the four
--   Tab, Shift+Tab   put the next (or the one before) of the nine in place of
--                    the walker followed; it walks on from there, and the
--                    others carry on (Klann and Jansen stay)
--   O                look over the whole room (O again, or F: follow again)
--   1 2 3 4          the ground: waves, random, logs, steps (built again)
--   T                clear the trails
-- The TerrainHeight slider sets the bumps' height (the room built again).
--
-- At the fast setting, as test-ranking.lua: the solver carrying each joint's
-- force over from step to step, 40 iterations, a 1/1920 s step. Four walkers
-- cost about four times one, so it runs slower than real time.
--
-- THREADS (default 0): solve the walkers side by side on this many threads.
-- Needs bpp built with Bullet with threads (scripts/bullet-threads.sh, then
-- qmake CONFIG+=bundled_bullet); otherwise it says so and runs on one. With
-- any number of threads the room walks the same, move for move; with none it
-- walks as before (without threads Bullet solves two or three walkers
-- together and stops when the group has settled; with threads each walker
-- stops on its own).
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

v:setSolver("si-warm"); v:setSolverInfo("residual", 0.01)
THREADS = THREADS or 0
if THREADS > 0 then v:setThreads(THREADS) end
SOLVER_ITERATIONS = 40; FIXED = 1 / 1920
MOTOR_STRENGTH = 2; GRAVITY = 981; YAW_DAMP = 1
ANKLE_SPRING = { stiffness = 42000, damping = 4200 }
LINK_WIDTH = 1.0; GAIT = { 0, 180, 180, 0 }; DIAG_OUTSIDE = true

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds and the sliders' diag builds)
dofile("spears-lift-walkers.lua")   -- (the Chebyshev-Spears lift builds and their diag builds)

-- the nine, best first in the 21-build table (handover section 4m)
ROOM_SWAP = { "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62 diag", "Chebyshev-Spears diag",
              "Hoecken-Spears 4-bar diag", "Hoecken-Spears slider diag", "Hoecken slider diag",
              "Hoecken 4-bar diag", "Chebyshev diag", "Spears 4-bar" }
ROOM_FIXED = { ["Klann"] = true, ["Jansen"] = true }
ONLY = { ["Klann"] = true, ["Jansen"] = true, [ROOM_SWAP[1]] = true, [ROOM_SWAP[2]] = true }
PENDANT_HOLD = {}   -- (the diag builds' pendants held at their angle to the body, as on the test track)
for _, n in ipairs(ROOM_SWAP) do if n:find("diag$") then PENDANT_HOLD[n] = true end end

TERRAIN = TERRAIN or "waves"
AMP = AMP or 2

dofile("walker-room.lua")
