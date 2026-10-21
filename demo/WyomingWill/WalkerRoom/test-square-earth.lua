--
-- Test square at Earth gravity: as test-square-yaw.lua (soft-spring feet,
-- body free to pitch and roll, only its turning about the vertical damped),
-- with gravity 981 cm/s^2. Everything happens sqrt(981/70) = 3.7 times
-- faster than at 70, so the physics step is 4 times shorter (1/3840 s
-- instead of 1/960) -- at 1/960 the joints give and the feet sink -- and
-- the ankle springs are 981/70 = 14 times stiffer, to hold the feet the
-- same way under the heavier load. The motors scale with gravity by
-- themselves.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) build (1-19 as built,
--                    20-31 trotting)
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
--
-- Units: centimetres and seconds.
--

GRAVITY = 981
FIXED = 1 / 3840
ANKLE_SPRING = { stiffness = 42000, damping = 4200 }
dofile("test-square-yaw.lua")
