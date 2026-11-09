--
-- Test track: one walker from the walker room -- the same stride, chassis,
-- crank speed and gravity as there -- walking straight down a long, narrow
-- strip of the room's terrain, with no avoidance turns. After TRACK_SECS
-- seconds it prints how far it got along the strip (and how far it drifted
-- sideways):
--
--   TRACK Hoecken|height 4.00|length 11.0|seed 1|forward 412.3 cm|6.87 cm/s|...
--
-- Opened on its own it shows Chebyshev-Spears lift 51 diag as it is now
-- (walker-room.lua's settings for being opened on its own). To watch the
-- walkers that could really be built, one after another, open
-- test-ranking.lua instead: it sets each one up as now (Tab here, from a
-- launcher that names only ONLY, brings in walker-room.lua's old builds
-- for the others). Tab and Shift+Tab put the next or previous
-- walker on the track (click the 3D view first). The TerrainHeight and
-- BumpLength sliders set the next ground, and G builds the track with them, as in the room. runs/run-table.sh runs every walker in
-- every condition headless and collects the results.
--
-- Units: centimetres and seconds.
--

-- (bpp runs a script from its own folder; headless runs need the module
-- folder on the path for common.lua)
package.path = "../../module/?.lua;" .. package.path

if EXTRA_WALKERS == nil then        -- (opened on its own: see above)
  ONLY = ONLY or "Chebyshev-Spears lift 51 diag"; AMP = AMP or 2; BUMP = BUMP or 15
end
ONLY = ONLY or "Chebyshev-Spears"   -- the walker, by its name in walker-room.lua
AMP = AMP or 4                      -- bump height, cm
BUMP = BUMP or 11                   -- bump length, cm (every stride is 15)
SEED = SEED or 1                    -- moves the start up to a bump length along and across
TRACK_SECS = TRACK_SECS or 60       -- how long it walks, s

TEST_TRACK = true
ARENA_X = ARENA_X or 1000           -- the strip: 10 m long ...
ARENA_Z = ARENA_Z or 800            -- ... and 8 m wide (2 m until 24 October 2026: walkers drifting 70-85 cm
                                    -- sideways rubbed its walls; 6 m until 25 October: some drifted 2.6 m)

dofile("walker-room.lua")
