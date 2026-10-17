-- More of Spears' walkers, found in the walker room's tests (README,
-- "The factorial runs"):
--   Spears lift 44, Spears lift 53: the Chebyshev-Spears kind of linkage,
--     hill-climbed from Chebyshev-Spears for more foot lift (44% and 53%,
--     against its 26%), every length and angle free to change -- the
--     rocker (r) and the leg (its length, and its angle off the coupler)
--     no longer tied to the coupler. Side plates, as Chebyshev-Spears.
--   Spears lift 44 diag, Spears lift 53 diag, Hoecken-Spears long-stance
--     diag: those two and the long-stance 4-bar built to trot, with braces
--     joining diagonal legs (Chebyshev-Spears diag's file).
-- Calibrated to the room's stride, flat speed and chassis like the room's
-- own walkers. This file adds them to EXTRA_WALKERS (load it after any
-- file that sets EXTRA_WALKERS, such as trotting-walkers.lua):
--   dofile("spears-lift-walkers.lua"); ONLY = "Spears lift 44 diag"; dofile("test-track.lua")
EXTRA_WALKERS = EXTRA_WALKERS or {}
for _, spec in ipairs({
  { name = "Spears lift 44", look = { code = "S+", colour = "#1F6FEB", spears = true, diag = false }, wide = { cube_d = 3.961 }, brace = { gap = 1.31 }, advance = 20.295, parts = "Chebyshev_Spears_normal_parts.lua", stride = 6.9440, chassis = { bodyRaise = -1.223, linkageSpacing = 16.210, cube_d = 8.131 }, fixed = 1 / 480, lift = "terrainLift", forward = -1, opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180, geometry = { a = 1.875, g = 2.7782, h = 5.8271, r = 5.4817, leg = 5.6839, legAngle = 105.99, groundAngle = -46.40 } } },
  { name = "Spears lift 53", look = { code = "S+", colour = "#1F6FEB", spears = true, diag = false }, wide = { cube_d = -0.013 }, brace = { gap = 1.47 }, advance = 21.209, parts = "Chebyshev_Spears_normal_parts.lua", stride = 5.8290, chassis = { bodyRaise = -2.852, linkageSpacing = 13.617, cube_d = 8.131 }, fixed = 1 / 480, lift = "terrainLift", forward = -1, opts = { cube_d = 4.5, linkageSpacing = 10, leftSpeed = 2.6, rightSpeed = 2.6, sidePhase = 180, geometry = { a = 1.875, g = 2.7566, h = 5.6784, r = 5.2037, leg = 5.4757, legAngle = 113.39, groundAngle = -47.38 } } },
  { name = "Hoecken-Spears long-stance diag", look = { code = "H-S 4L", colour = "#E5007E", spears = true, diag = true }, wide = { cube_d = 3.012 }, brace = { gap = 1.90, diag = true }, advance = 16.695, parts = "Chebyshev_Spears_diag_parts.lua", stride = 8.5437, chassis = { bodyRaise = -2.447, linkageSpacing = 19.895, cube_d = 4.000 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6, geometry = { a = 1.875, g = 2.1842, h = 2.8129, leg = 2.8129, legAngle = 39.80, groundAngle = -20.14 } } },
  { name = "Spears lift 44 diag", look = { code = "S+", colour = "#1F6FEB", spears = true, diag = true }, wide = { cube_d = -0.643 }, brace = { gap = 2.29, diag = true }, advance = 20.271, parts = "Chebyshev_Spears_diag_parts.lua", stride = 6.9482, chassis = { bodyRaise = -2.835, linkageSpacing = 16.205, cube_d = 8.131 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6, geometry = { a = 1.875, g = 2.7782, h = 5.8271, r = 5.4817, leg = 5.6839, legAngle = 105.99, groundAngle = -46.40 } } },
  { name = "Spears lift 53 diag", look = { code = "S+", colour = "#1F6FEB", spears = true, diag = true }, wide = { cube_d = -3.153 }, brace = { gap = 9.81, diag = true }, advance = 20.806, parts = "Chebyshev_Spears_diag_parts.lua", stride = 5.8662, chassis = { bodyRaise = -4.745, linkageSpacing = 13.672, cube_d = 8.131 },
    fixed = 1 / 480, lift = "terrainLift", forward = -1,
    opts = { cube_d = 4.5, cubeMass = 50, linkageSpacing = 18, motorSpeed = 2.6, geometry = { a = 1.875, g = 2.7566, h = 5.6784, r = 5.2037, leg = 5.4757, legAngle = 113.39, groundAngle = -47.38 } } }
}) do EXTRA_WALKERS[#EXTRA_WALKERS + 1] = spec end
