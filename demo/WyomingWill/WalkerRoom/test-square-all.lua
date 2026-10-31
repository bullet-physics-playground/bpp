--
-- Test square, every build: as test-square.lua, but Tab goes through all
-- 19 builds of the room, each as built -- its own timing, forward, its
-- own crank speed -- for looking them over (no settings from the factorial
-- runs).
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) build
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
-- The TerrainHeight and BumpLength sliders (Params pane) build it again.
-- The status line shows the speed so far and the share of the time the
-- walker has been off the ground; its body turns red whenever it is.
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

VIEWS = {}
for _, n in ipairs({ "Jansen", "Klann", "Spears 4-bar",
                     "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag",
                     "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider",
                     "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag",
                     "Hoecken-Spears 4-bar duty 85", "Hoecken-Spears 4-bar duty 85 diag",
                     "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62", "Chebyshev-Spears lift 62 diag" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "as built" }
end
VIEW = VIEW or 1                    -- the one it starts with

dofile("trotting-walkers.lua")      -- (the Hoecken diag builds)
dofile("spears-lift-walkers.lua")   -- (Chebyshev-Spears lift 51 and 62, and their diag builds)

TERRAIN = TERRAIN or "waves"
AMP = AMP or 4                      -- bump height, cm
BUMP = BUMP or 15                   -- bump length, cm (every stride is 15)
SEED = SEED or 1
TRACK_SECS = TRACK_SECS or 60       -- it prints how far it got after this long, and carries on

TEST_TRACK = true
ARENA_X = ARENA_X or 700            -- the square: 7 m each way
ARENA_Z = ARENA_Z or 700

dofile("walker-room.lua")
