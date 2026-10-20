--
-- Test square, every build on soft-spring ankles: as test-square-all.lua,
-- but each foot hinged to its leg and held level to the body by a soft
-- spring about the ankle's axis (ANKLE_SPRING, walker-room.lua), so it
-- swings level, lands level and can still rock on a bump.
--
-- Open this file in bpp and click the 3D view first, then:
--   Tab, Shift+Tab   the next (or the one before) build
--   1 2 3 4          the ground: waves, random, logs, steps
--   O                look over the whole square
--
-- Units: centimetres and seconds.
--

ANKLE_SPRING = ANKLE_SPRING or { stiffness = 3000, damping = 300 }
dofile("test-square-all.lua")
