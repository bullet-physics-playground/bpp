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
--   Left, Right      brake the left (right) wheel of the walker followed: it
--                    turns that way; the same key again frees it
--   Down             the walker followed backs up (again: walks on); with a
--                    wheel braked it turns the other way
--   T                clear the trails
--   G                build the room with the sliders' height and length
-- The TerrainHeight slider sets the bumps' height and BumpLength their length
-- (15 cm, the stride, as on the test track), in whole cm; G builds the room
-- with them (and the 1-4 keys do).
--
-- At the fast setting, as test-ranking.lua: the solver carrying each joint's
-- force over from step to step, 40 iterations, a 1/1920 s step. Four walkers
-- cost about four times one, so it runs slower than real time.
--
-- The Threads slider (THREADS sets where it starts, default 4; in
-- walker-room.lua) solves the walkers side by side on that many threads,
-- while it runs, and the status line shows how fast. Needs bpp built with
-- Bullet with threads (scripts/bullet-threads.sh, then qmake
-- CONFIG+=bundled_bullet); otherwise the status line says so. With
-- any number of threads the room walks the same, move for move; with none it
-- walks as before (without threads Bullet solves two or three walkers
-- together and stops when the group has settled; with threads each walker
-- stops on its own).
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

v:setSolver("si-warm"); v:setSolverInfo("residual", 0.01)
SOLVER_ITERATIONS = 40; FIXED = 1 / 1920
MOTOR_STRENGTH = 2; GRAVITY = 981; YAW_DAMP = 1
ANKLE_SPRING = { stiffness = 42000, damping = 4200 }
LINK_WIDTH = 1.0; DIAG_OUTSIDE = true
if GAIT == nil then GAIT = { 0, 180, 180, 0 }; GAIT_DEFAULT = true end   -- (a trot, unless set by hand: then it wins over lib/gaits.lua)

dofile("lib/trotting-walkers.lua")      -- (the Hoecken diag builds and the sliders' diag builds)
dofile("lib/spears-lift-walkers.lua")   -- (the Chebyshev-Spears lift builds and their diag builds)

-- the nine, best first in the 21-build table (handover section 4m)
ROOM_SWAP = { "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62 diag", "Chebyshev-Spears diag",
              "Hoecken-Spears 4-bar diag", "Hoecken-Spears slider diag", "Hoecken slider diag",
              "Hoecken 4-bar diag", "Chebyshev diag", "Spears 4-bar" }
ROOM_FIXED = { ["Klann"] = true, ["Jansen"] = true }
REVERSE = { ["Klann"] = true, ["Spears 4-bar"] = true }   -- (each walker its better way: handover section 4w)
ONLY = { ["Klann"] = true, ["Jansen"] = true, [ROOM_SWAP[1]] = true, [ROOM_SWAP[2]] = true }
PENDANT_HOLD = {}   -- (the diag builds' pendants held at their angle to the body, as on the test track)
for _, n in ipairs(ROOM_SWAP) do if n:find("diag$") then PENDANT_HOLD[n] = true end end

TERRAIN = TERRAIN or "waves"
AMP = AMP or 2
BUMP = BUMP or 15   -- (bumps 15 cm long, as on the test track and in the tables; walker-room.lua's own default is 22)
if SHOES == nil then SHOES = {} end   -- (a wheel on each side of each walker, walker-room.lua's SHOES: the arrow keys)
if BEST_GAITS == nil then BEST_GAITS = true end   -- (each walker's best gait for the room's ground: lib/gaits.lua)
ARENA = ARENA or 1500   -- (a 15 m room, not walker-room.lua's 10: room to walk straight between turns, which take
                        -- about 20 s by the wheels; the physics costs the same)

dofile("walker-room.lua")
