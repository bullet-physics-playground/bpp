-- Trotting walkers: the two Hoecken 4-bars built to trot (diagonal legs
-- stepping together) with braces joining diagonal legs, by the diag
-- walkers' files with Hoecken's proportions: Chebyshev-Spears diag's file
-- for the Hoecken-Spears 4-bar, Chebyshev diag's for the Hoecken 4-bar.
-- Calibrated to the room's stride, flat speed and chassis like the room's
-- own walkers. (Any plated walker can also trot with its plates off and
-- its legs held by guides: UNBRACED and GAIT.) Results: README,
-- "Trotting the Hoecken walkers".
--
-- To run one on the test track, from a launcher in this folder:
--   dofile("trotting-walkers.lua"); ONLY = "Hoecken-Spears 4-bar diag"; dofile("test-track.lua")
-- (in the room, they join the other walkers).
EXTRA_WALKERS = {
  { name = "Hoecken-Spears 4-bar diag", bodyShift = 3.86, frame = { length = 43.8, x = -3.86 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "H-S 4", colour = "#E5007E", spears = true, diag = true }, wide = { cube_d = 14.590 }, brace = { gap = 1.63, diag = true, rise = 10 }, advance = 19.68, parts = "Chebyshev_Spears_diag_parts.lua", stride = 10.0390, chassis = { bodyRaise = 1.537, linkageSpacing = 23.426, cube_d = 5.209 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6, geometry = { a = 1.875, g = 2.6138, h = 5.8331, groundAngle = -45 } } },
  { name = "Hoecken 4-bar diag", bodyShift = 5.53, frame = { length = 47.9, x = -5.53 }, planes = { crank = 1, coupler = 2, rocker = 1, pendant = 3 }, look = { code = "H 4", colour = "#E5007E", spears = false, diag = true }, wide = { cube_d = 6.623 }, brace = { gap = 1.89, diag = true, rise = 10 }, advance = 25.67, parts = "Chebyshev_diag_parts.lua", stride = 4.5573, chassis = { bodyRaise = -0.821, linkageSpacing = 10.633, cube_d = 5.029 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 2.5, cubeMass = 140, linkageSpacing = 10, motorSpeed = 3.0, geometry = { a = 1.0, g = 2.0908, h = 2.5455 } } },
  -- the two sliders' diag builds (William, 28 October 2026): their own files with opts.outside (diagonal legs
  -- in step, outside braces joining them; DIAG_OUTSIDE), the same linkage, chassis and advance as their
  -- guides builds. footTips (29 October, a builder's tweak, Hoecken-Spears slider diag, and its guides build): its feet's ends turned up
  -- 1.0 cm at 30 degrees -- its feet come down early and travel the last 2-3 cm low, so a flat toe caught on
  -- the logs' sides (handover section 4g). Tried on the Hoecken slider diag too: no change, so not given it.
  { name = "Hoecken slider diag", bodyShift = -0.28, frame = { length = 41.0, x = 0.28 }, look = { code = "H 2S", colour = "#F2F2F2", spears = false, diag = true }, wide = { cube_d = 12.958 }, brace = { gap = 6.54, diag = true }, advance = 24.67, parts = "Hoecken_slider_parts.lua", stride = 8.378, chassis = { bodyRaise = 2.692, linkageSpacing = 19.549, cube_d = 2.0 }, fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } },
  { name = "Hoecken-Spears slider diag", footTips = { length = 1.0, angle = 30 }, bodyShift = -0.32, frame = { length = 41.0, x = 0.32 }, look = { code = "H-S 2S", colour = "#F2F2F2", spears = true, diag = true }, wide = { cube_d = 13.037 }, brace = { gap = 3.02, diag = true }, advance = 18.31, parts = "Hoecken_Spears_slider_parts.lua", stride = 8.4291, chassis = { bodyRaise = 2.558, linkageSpacing = 19.641, cube_d = 3.656 }, fixed = 1 / 960, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 100, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6 } }
}
