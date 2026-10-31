--
-- Test square, free body: every build on soft-spring ankles with its body
-- free to pitch and roll -- only its turning about the vertical damped
-- (YAW_DAMP, walker-room.lua), where the walkers' own files damp every
-- way the body turns (1.0, which also holds up a walker standing on one
-- side's feet). Tab goes through each build as built, then the builds
-- that can trot, trotting: Jansen, Klann and Spears 4-bar on their own
-- frames, the plated builds on guides.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) build
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
--
-- Units: centimetres and seconds.
--

package.path = "../../module/?.lua;" .. package.path

ANKLE_SPRING = ANKLE_SPRING or { stiffness = 3000, damping = 300 }
YAW_DAMP = YAW_DAMP or 1

local TROT = { 0, 180, 180, 0 }
VIEWS = {}
for _, n in ipairs({ "Jansen", "Klann", "Spears 4-bar",
                     "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag",
                     "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider",
                     "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag",
                     "Hoecken-Spears 4-bar duty 85", "Hoecken-Spears 4-bar duty 85 diag",
                     "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62", "Chebyshev-Spears lift 62 diag" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "as built, free body" }
end
for _, n in ipairs({ "Jansen", "Klann", "Spears 4-bar" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "own frame, trot, free body", gait = TROT }
end
for _, n in ipairs({ "Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken slider", "Hoecken-Spears slider",
                     "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar duty 85", "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 62" }) do
  VIEWS[#VIEWS + 1] = { walker = n, label = "guides, trot, free body", gait = TROT, unbraced = true }
end
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
