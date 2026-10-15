-- Foot-path variants: linkages of Chebyshev-Spears' kind (its file, with
-- other link lengths and a leg of its own length and angle), each
-- changing one thing about Chebyshev-Spears' foot path and holding the
-- others (see README.md, "Why the Spears changes work"), calibrated to
-- the room's stride, flat speed and chassis like the room's own walkers.
--
--   V duty 72     its foot down 72% of each turn instead of 84%
--   V front low   its foot lower at the front of its swing (0.150 of the
--                 stride, against 0.174)
--   V front high  higher there (0.216), and more lift (29% against 26%)
--
-- To run one on the test track, from a launcher in this folder:
--   dofile("foot-path-variants.lua"); ONLY = "V front high"; dofile("test-track.lua")
-- (in the room, they join the other walkers).
EXTRA_WALKERS = {
  { name = "V duty 72", look = { code = "V", colour = "#9A9A9A", spears = true, diag = false }, wide = { cube_d = 7.074 }, brace = { gap = 1.18 }, advance = 20.951, parts = "Chebyshev_Spears_normal_parts.lua", stride = 8.0040, chassis = { bodyRaise = 0.787, linkageSpacing = 18.668, cube_d = 8.131 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6,
             sidePhase = 180, geometry = { a = 1.875, g = 2.8596, h = 4.4396, leg = 3.4356, legAngle = 52.98, groundAngle = -18.54 } } },
  { name = "V front low", look = { code = "V", colour = "#9A9A9A", spears = true, diag = false }, wide = { cube_d = 7.464 }, brace = { gap = 1.15 }, advance = 17.886, parts = "Chebyshev_Spears_normal_parts.lua", stride = 8.1530, chassis = { bodyRaise = -0.220, linkageSpacing = 18.973, cube_d = 8.131 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6,
             sidePhase = 180, geometry = { a = 1.875, g = 2.4564, h = 3.3272, leg = 2.8159, legAngle = 34.13, groundAngle = -12.63 } } },
  { name = "V front high", look = { code = "V", colour = "#9A9A9A", spears = true, diag = false }, wide = { cube_d = 15.607 }, brace = { gap = 0.88 }, advance = 16.502, parts = "Chebyshev_Spears_normal_parts.lua", stride = 11.4390, chassis = { bodyRaise = 3.981, linkageSpacing = 26.640, cube_d = 8.131 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6,
             sidePhase = 180, geometry = { a = 1.875, g = 2.3876, h = 4.5744, leg = 6.5882, legAngle = 84.32, groundAngle = -58.22 } } }
}
