-- Try the drag shoe (handover/STEERING.md, stage 2): open this file in bpp
-- from the WalkerRoom folder. The ranking viewer (test-ranking.lua: the
-- builds as they are now, outside braces and held pendants on the diag
-- builds, Tab and Shift+Tab for the next or previous) with a ball dragged
-- on one side of every walker, 3 cm out beyond its feet; each should curve
-- toward the ball.
--
-- Change these:
VIEW = 7                -- the walker to start with, test-ranking.lua's order: 1 Chebyshev-Spears lift 51 diag,
                        -- 2 lift 62 diag, 3 Chebyshev-Spears diag, 4 Hoecken-Spears 4-bar diag, 5 Hoecken-Spears
                        -- slider diag, 6 Klann, 7 Jansen, 8 Hoecken slider diag, 9 Hoecken 4-bar diag,
                        -- 10 Chebyshev diag, 11 Spears 4-bar
SHOE_SIDE = "L"         -- "L" or "R" (the walker's own left or right), or false: no shoe
SHOE_WEIGHT = 0.25      -- the ball's weight, as a share of the walker's (0.1 turns about half as much)
TERRAIN = "waves"; AMP = 0                -- (flat; AMP = 2 for waves 2)

YAW_DAMP = 0            -- (0, not false: false leaves each file's own damping, which holds it straight)
ARENA_Z = 800           -- (the strip 8 m wide: test-ranking's fast setting makes it 3 m, and a curving walker
                        -- would reach its wall)
STEER = SHOE_SIDE and { mech = "drag", side = SHOE_SIDE, amount = SHOE_WEIGHT } or false
dofile("test-ranking.lua")
