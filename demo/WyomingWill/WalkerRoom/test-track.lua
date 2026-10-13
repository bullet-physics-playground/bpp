--
-- Test track: one walker from the walker room -- the same stride, chassis,
-- crank speed and gravity as there -- walking straight down a long, narrow
-- strip of the room's terrain, with no avoidance turns. After TRACK_SECS
-- seconds it prints how far it got along the strip (and how far it drifted
-- sideways):
--
--   TRACK Hoecken|height 4.00|length 11.0|seed 1|forward 412.3 cm|6.87 cm/s|...
--
-- Open this file in bpp to watch one walker: change the settings below
-- (or set them from a launcher). Tab and Shift+Tab put the next or previous
-- walker on the track (click the 3D view first). The TerrainHeight and
-- BumpLength sliders rebuild the track as in the room. test-track-all.sh runs every walker in
-- every condition headless and collects the results.
--
-- Units: centimetres and seconds.
--

-- (bpp runs a script from its own folder; headless runs need the module
-- folder on the path for common.lua)
package.path = "../../module/?.lua;" .. package.path

ONLY = ONLY or "Chebyshev-Spears"   -- the walker, by its name in walker-room.lua
AMP = AMP or 4                      -- bump height, cm
BUMP = BUMP or 11                   -- bump length, cm (every stride is 15)
SEED = SEED or 1                    -- moves the start up to a bump length along and across
TRACK_SECS = TRACK_SECS or 60       -- how long it walks, s

TEST_TRACK = true
ARENA_X = ARENA_X or 1000           -- the strip: 10 m long ...
ARENA_Z = ARENA_Z or 200            -- ... and 2 m wide

dofile("walker-room.lua")
