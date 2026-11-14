-- galton-geometry.lua -- Babbage's Hall, the Galton board
--
-- Every size of the board in one place (millimetres). The simulation builds
-- its contact shapes from these, and galton.lua writes them out for
-- OpenSCAD (parts/geometry.scad), from which the printed parts are made.
-- So what is printed is what is simulated.
--
-- The board as you face it: x to the right, y up, z toward you. The balls
-- run between the back plate's face (z = 0) and the front sheet (z = GAP).
-- y = 0 is the first row's middle pin.
--
--   the hopper    holds the balls, its floor two 60-degree slopes down to
--   the wheels    two metering wheels, mirror images geared together and
--                 turned by one crank: each slot carries one ball round
--                 under its housing and drops it into a funnel and a short
--                 neck over the first row's middle pin. A hopper
--                 emptying through a neck jams in two dimensions, or floods
--                 the pins and spreads the balls too wide (FINDINGS)
--   the pins      on a triangular lattice, each centred under the gap above
--                 it: 12 rows from the middle pin down, so 12 times a ball
--                 goes left or right; the side walls run where the next pin
--                 out would be, with half pins standing out of them there
--   the bins      13, between dividers that stand under the last row's pins;
--                 a slide under them lets the balls down into
--   the drawer    which the operator empties back into the hopper

local sqrt, tan, rad, cos, sin = math.sqrt, math.tan, math.rad, math.cos, math.sin
local T30 = tan(rad(30))

-- (o: sizes to change, for trying them: { S = 13, PIN_D = 3 })
local function build(o)
  o = o or {}
  local G = {}
  G.BALL_D = o.BALL_D or 6.0              -- steel balls, 6 mm
  G.BALL_MASS = 0.000884                  -- kg (7.8 g/cm^3)
  G.PIN_D = o.PIN_D or 4.0                -- printed pins
  -- The pitch: a ball must pass between two pins (S - PIN_D = 8 mm), but the
  -- lattice's straight diagonals (S sin 60 - PIN_D = 6.4) must be too narrow
  -- for it to run down one touching nothing. One ball at a time, the spread
  -- in the bins is the binomial's at 12 mm; narrower at 11, far wider at 13
  -- (FINDINGS).
  G.S = o.S or 12.0
  G.V = o.V or G.S * sqrt(3) / 2          -- the rows' spacing (an equilateral lattice)
  G.ROWS = o.ROWS or 14                   -- the lattice's rows, counted from its apex
  G.TOP = 2                               -- the first row printed: three pins, the middle one under the wheel
  G.DIV_T = 1.6                           -- a bin's divider
  G.BIN_H = o.BIN_H or 210                -- the bins, from the dividers' tops to the slide
  G.RES_H = o.RES_H or 13                 -- the hopper's straight sides, above its slopes
  G.GAP = 7.0                             -- the ball space: a ball and 1 mm
  G.BACK_T = 4.0                          -- the printed back plate
  G.FRONT_T = 3.0                         -- the front sheet (clear acrylic, bought)
  G.RIM = 6.0                             -- the outer wall
  G.NBALLS = o.NBALLS or 150              -- the balls the board is made for (its printed curve)

  -- the balls come in over the first row's middle pin: each row after it is
  -- one decision, and there is one more bin than there are decisions
  G.DECISIONS = G.ROWS - G.TOP
  G.NBINS = G.DECISIONS + 1
  -- the inner half width: the outer bins as wide as the others
  G.W = G.NBINS / 2 * G.S - G.DIV_T / 2

  -- the metering wheels: two, mirror images, side by side under the hopper
  -- (their centres WHEEL_X either side of the middle), geared together
  -- behind the board, so that the left turns clockwise and the right
  -- anticlockwise (as you face it), on the one crank. Each has SLOTS slots
  -- SLOT_W wide and SLOT_D deep in its rim; a ball in a slot has its centre
  -- at R - SLOT_D + BALL_D / 2. A slot comes up the wheel's outer side
  -- empty, under the hopper (its opening between INLET_L and INLET_R
  -- degrees round the wheel), down its inner side with its ball held in by
  -- the housing, and lets the ball drop at the bottom (between OUT_R and
  -- OUT_L) into the funnel, which leads both wheels' balls into a straight
  -- neck over the first row's middle pin. The right wheel's slots are half a
  -- slot behind the left's, so the balls come from each in turn.
  -- One wheel hands every ball on in the same way: whichever way it turned,
  -- the board leant that way (FINDINGS). The pair is symmetric: what one
  -- wheel's balls do, the other's do mirrored.
  G.WHEEL_R = o.WHEEL_R or 16
  G.SLOTS = o.SLOTS or 6
  G.SLOT_W = o.SLOT_W or 6.8
  G.SLOT_D = o.SLOT_D or 5.0
  G.HOUSING = G.WHEEL_R + (o.CLEAR or 2.0)  -- the housing's inside: a slotted ball clears it, a loose one can't get in
  G.RING = 2.0                            -- the housing's wall
  G.BALL_IN_SLOT = G.WHEEL_R - G.SLOT_D + G.BALL_D / 2
  G.WHEEL_X = o.WHEEL_X or (G.HOUSING + G.RING + 1)
  G.WHEEL_Y = o.WHEEL_Y or 60
  G.INLET_L, G.INLET_R = 120, 60          -- the hopper's opening over each wheel (degrees round it, from +x)
  G.OUT_R, G.OUT_L = -60, -120            -- the outlet under each wheel
  G.CHUTE = o.CHUTE or 4.0                -- the neck, half its width (a ball and 2 mm)
  G.CHUTE_T = 1.2                         -- the funnel's and neck's walls
  G.CHUTE_Y = o.CHUTE_Y or (G.PIN_D / 2 + G.BALL_D / 2 + 3)  -- the neck's foot (8): a ball leaving it touches the pin
  G.NECK_L = o.NECK_L or 8                -- the neck's length
  G.WHEEL_T = 6.0                         -- the wheels' thickness (in the 7 mm space)
  G.WHEEL_MASS = 0.004                    -- kg (PLA, with its axle)
  G.CRANK_R = 25                          -- the crank's handle, from the left axle (in front of the sheet)
  -- the gears behind the board: two alike, meshing, on the wheels' axles
  G.GEAR_Z = 28
  G.GEAR_M = 2 * G.WHEEL_X / G.GEAR_Z     -- (their pitch circles meet midway)
  G.GEAR_T = 5
  -- a point on a circle of r round a wheel (side -1 the left, 1 the right)
  local function onCircle(r, deg, side)
    return (side or 1) * G.WHEEL_X + r * cos(rad(deg)), G.WHEEL_Y + r * sin(rad(deg))
  end
  G.onCircle = onCircle
  -- the funnel's mouth: from each outlet's outer edge; its ceiling, between
  -- the two outlets' inner edges
  G.MOUTH_X, G.MOUTH_Y = onCircle(G.HOUSING, G.OUT_R, 1)
  G.CEIL_X = onCircle(G.HOUSING, G.OUT_L, 1)

  -- the pins' side walls: on the line through the pins one place beyond
  -- each row's last (x = (r/2 + 1) S at row r), with half pins standing out
  -- of them there, so a ball at the edge meets a pin where it would have,
  -- not a smooth 60-degree ramp it can run down (FINDINGS).
  -- x = X0 - y tan 30 (the right side).
  G.X0 = (G.TOP / 2 + 1) * G.S
  -- ... down to where they meet the bins' outer walls
  G.Y_SIDE = -(G.W - G.X0) / T30
  -- ... and up to where they meet the outside of the funnel's wall
  do
    local x1, y1 = G.CHUTE + G.CHUTE_T, G.CHUTE_Y + G.NECK_L
    local x2, y2 = G.MOUTH_X + G.CHUTE_T, G.MOUTH_Y
    local k = (x2 - x1) / (y2 - y1)
    G.Y_MEET = (G.X0 - x1 + k * y1) / (k + T30)
    G.X_MEET = G.X0 - G.Y_MEET * T30
    assert(G.Y_MEET > y1 and G.Y_MEET < y2, "the funnel's wall misses the pins' wall")
  end
  -- the dividers stand under the last row's pins, a row below it; the slide
  -- below them
  G.Y_DIV = -(G.ROWS - G.TOP) * G.V
  G.Y_FLOOR = G.Y_DIV - G.BIN_H
  G.SLIDE_T = 3.0                         -- the slide (printed), in a slot through the board
  G.DRAWER_H = 46                         -- the drawer under it: 40 mm was too little, the balls heap up in it (FINDINGS)
  G.Y_DRAWER = G.Y_FLOOR - G.SLIDE_T - G.DRAWER_H
  -- the hopper: from the wheels' openings, slopes up at 60 degrees to the
  -- sides, then straight up; between the openings, a ridge
  local ixO, iyO = onCircle(G.HOUSING, G.INLET_R, 1)              -- (the right opening's outer edge)
  local ixI = onCircle(G.HOUSING, G.INLET_L, 1)                   -- (its inner edge)
  G.Y_RIDGE = iyO + ixI / T30
  G.Y_FUNNEL = iyO + (G.W - ixO) / T30
  G.Y_TOP = G.Y_FUNNEL + G.RES_H

  -- the pins: { x, y }, cut off by the bins' walls. A pin whose middle is
  -- more than a ball's radius from a wall but leaves less than a ball's
  -- width and a millimetre beside it makes a cradle: a ball came to rest on
  -- it against the wall (FINDINGS). Such a pin is left out, and the wall has
  -- a half pin there instead (a ball can't rest on a half pin: it rolls off
  -- away from the wall).
  G.pins, G.bumps = {}, {}
  local close = G.PIN_D / 2 + G.BALL_D + 1
  for r = G.TOP, G.ROWS - 1 do
    local y = -(r - G.TOP) * G.V
    for k = 0, r do
      local x = (k - r / 2) * G.S
      if math.abs(x) <= G.W - close then G.pins[#G.pins + 1] = { x, y } end
    end
    -- the half pins: on the 60-degree walls where the next pin out would
    -- be; on the bins' straight walls, level with every row
    if y > G.Y_SIDE + G.PIN_D / 2 and y < G.Y_MEET - G.PIN_D / 2 then
      local x = (r / 2 + 1) * G.S
      G.bumps[#G.bumps + 1] = { -x, y }; G.bumps[#G.bumps + 1] = { x, y }
    elseif y <= G.Y_SIDE - G.PIN_D / 2 then
      G.bumps[#G.bumps + 1] = { -G.W, y }; G.bumps[#G.bumps + 1] = { G.W, y }
    end
  end
  -- the bins: each one's centre x; the dividers' x
  G.bins, G.dividers = {}, {}
  for k = 0, G.NBINS - 1 do G.bins[#G.bins + 1] = (k - (G.NBINS - 1) / 2) * G.S end
  for j = 1, G.NBINS - 1 do G.dividers[#G.dividers + 1] = (j - G.NBINS / 2) * G.S end
  function G.binOf(x)
    local k = math.floor(x / G.S + (G.NBINS - 1) / 2 + 0.5) + 1
    return math.max(1, math.min(G.NBINS, k))
  end

  -- The walls, as segments { x1, y1, x2, y2 } with the balls' side on the
  -- left going from the first point to the second (so outlines go round
  -- anticlockwise). Arcs are cut into segments of about ARC degrees.
  local ARC = 7.5
  -- (t: the wall's thickness behind its face, if not the usual)
  local function arc(list, r, a0, a1, side, t)     -- from a0 to a1 degrees, either way
    local n = math.max(1, math.ceil(math.abs(a1 - a0) / ARC))
    local pts = {}
    for i = 0, n do pts[#pts + 1] = { onCircle(r, a0 + (a1 - a0) * i / n, side) } end
    for i = 1, n do list[#list + 1] = { pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], t = t } end
  end
  local function seg(list, x1, y1, x2, y2, t) list[#list + 1] = { x1, y1, x2, y2, t = t } end
  G.walls = {}
  local Wl = G.walls
  local T, C, ny = G.CHUTE_T, G.CHUTE, G.CHUTE_Y + G.NECK_L
  -- the main space: the slide, the bins, the pins' side walls, the funnel's
  -- outside and the neck's, the neck's inside and the funnel's, the ceiling
  -- between the outlets, and the same down the left side
  seg(Wl, -G.W, G.Y_FLOOR, G.W, G.Y_FLOOR)
  Wl[#Wl].slide = true                    -- (the slide's top: it moves)
  seg(Wl, G.W, G.Y_FLOOR, G.W, G.Y_SIDE)
  seg(Wl, G.W, G.Y_SIDE, G.X_MEET, G.Y_MEET)
  seg(Wl, G.X_MEET, G.Y_MEET, C + T, ny, T)
  seg(Wl, C + T, ny, C + T, G.CHUTE_Y, T)
  seg(Wl, C, G.CHUTE_Y, C, ny, T)
  seg(Wl, C, ny, G.MOUTH_X, G.MOUTH_Y, T)
  seg(Wl, G.CEIL_X, G.MOUTH_Y, -G.CEIL_X, G.MOUTH_Y, 1)        -- (thin: the wheels pass just above its ends)
  seg(Wl, -G.MOUTH_X, G.MOUTH_Y, -C, ny, T)
  seg(Wl, -C, ny, -C, G.CHUTE_Y, T)
  seg(Wl, -C - T, G.CHUTE_Y, -C - T, ny, T)
  seg(Wl, -C - T, ny, -G.X_MEET, G.Y_MEET, T)
  seg(Wl, -G.X_MEET, G.Y_MEET, -G.W, G.Y_SIDE)
  seg(Wl, -G.W, G.Y_SIDE, -G.W, G.Y_FLOOR)
  -- the housings' insides, round each wheel (anticlockwise: the wheel's
  -- side is inside): from the outlet up to the opening on its right, from
  -- the opening down to the outlet on its left
  for _, side in ipairs({ -1, 1 }) do
    arc(Wl, G.HOUSING, G.OUT_R, G.INLET_R, side, G.RING)
    arc(Wl, G.HOUSING, G.INLET_L, 360 + G.OUT_L, side, G.RING)
  end
  -- the hopper, and its ridge between the openings
  local ixO, iyO = onCircle(G.HOUSING, G.INLET_R, 1)
  local ixI = onCircle(G.HOUSING, G.INLET_L, 1)
  seg(Wl, ixO, iyO, G.W, G.Y_FUNNEL)
  seg(Wl, G.W, G.Y_FUNNEL, G.W, G.Y_TOP)
  seg(Wl, G.W, G.Y_TOP, -G.W, G.Y_TOP)
  seg(Wl, -G.W, G.Y_TOP, -G.W, G.Y_FUNNEL)
  seg(Wl, -G.W, G.Y_FUNNEL, -ixO, iyO)
  seg(Wl, -ixI, iyO, 0, G.Y_RIDGE)
  seg(Wl, 0, G.Y_RIDGE, ixI, iyO)
  -- the drawer, under the slide
  seg(Wl, -G.W, G.Y_DRAWER, G.W, G.Y_DRAWER)
  seg(Wl, G.W, G.Y_DRAWER, G.W, G.Y_FLOOR - G.SLIDE_T)
  seg(Wl, -G.W, G.Y_FLOOR - G.SLIDE_T, -G.W, G.Y_DRAWER)

  -- the ball spaces as outlines, for the print (anticlockwise); the wheels'
  -- recesses, circles of HOUSING round them, are cut as well. Where an
  -- outline opens into a recess it runs on along its wall's line well
  -- inside it, to the wheel's centre (an outline that only touched the
  -- circle left slivers OpenSCAD could not close)
  local function beyond(x0, y0, x1, y1, d)      -- (x1, y1) moved d further from (x0, y0)
    local L = sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    return { x1 + (x1 - x0) / L * d, y1 + (y1 - y0) / L * d }
  end
  local XW, WY, MX, MY, CX = G.WHEEL_X, G.WHEEL_Y, G.MOUTH_X, G.MOUTH_Y, G.CEIL_X
  local main = { { -G.W, G.Y_FLOOR }, { G.W, G.Y_FLOOR }, { G.W, G.Y_SIDE }, { G.X_MEET, G.Y_MEET },
    { C + T, ny }, { C + T, G.CHUTE_Y }, { C, G.CHUTE_Y }, { C, ny },
    beyond(C, ny, MX, MY, 3), { XW, WY }, { CX + 3, MY }, { -CX - 3, MY }, { -XW, WY }, beyond(-C, ny, -MX, MY, 3),
    { -C, ny }, { -C, G.CHUTE_Y }, { -C - T, G.CHUTE_Y }, { -C - T, ny },
    { -G.X_MEET, G.Y_MEET }, { -G.W, G.Y_SIDE } }
  local hopper = { beyond(-G.W, G.Y_FUNNEL, -ixO, iyO, 3), { -XW, WY }, beyond(0, G.Y_RIDGE, -ixI, iyO, 3), { 0, G.Y_RIDGE },
    beyond(0, G.Y_RIDGE, ixI, iyO, 3), { XW, WY }, beyond(G.W, G.Y_FUNNEL, ixO, iyO, 3),
    { G.W, G.Y_FUNNEL }, { G.W, G.Y_TOP }, { -G.W, G.Y_TOP }, { -G.W, G.Y_FUNNEL } }
  G.spaces = { main = main, hopper = hopper }

  -- the wheel's slots: each straight-sided, SLOT_W wide and SLOT_D deep,
  -- centred on a radius; the angles of their middles when the wheel is at 0
  G.slotAngles = {}
  for k = 0, G.SLOTS - 1 do G.slotAngles[#G.slotAngles + 1] = 90 + k * 360 / G.SLOTS end

  -- the board's outside
  G.OUT_W = 2 * (G.W + G.RIM)
  G.OUT_Y0, G.OUT_Y1 = G.Y_DRAWER - G.RIM, G.Y_TOP + G.RIM
  G.OUT_H = G.OUT_Y1 - G.OUT_Y0
  G.THICK = G.BACK_T + G.GAP + G.FRONT_T  -- back, balls, front
  -- the filling slot in the top, for pouring the drawer back in
  G.FILL_W = 60
  -- printed in three tiles, each under 200 mm, cut at these heights and
  -- joined by a splice plate glued across the back of each joint (and the
  -- front sheet's screws along the rim)
  G.CUTS = { 5, -191 }
  G.SCREW_PITCH = 50
  G.SCREW_D = 2.5                         -- (pilot holes for M3 screws in the rim)
  G.AXLE_D = 3.0                          -- the wheel's axle, a 3 mm steel rod
  -- the stand: a foot with a lip in front of the board and one behind it
  -- (the board's foot stands between them), and two gussets behind
  G.FOOT_W, G.FOOT_D, G.FOOT_T = G.OUT_W + 30, 90, 8
  G.LIP_H, G.LIP_T = 15, 4

  -- the expected heights in the bins: two staggered columns, a ball every
  -- PACK mm
  G.BIN_IN = G.S - G.DIV_T
  G.PACK = sqrt(G.BALL_D ^ 2 - (G.BIN_IN - G.BALL_D) ^ 2)
  local function choose(n, k)
    local c = 1
    for i = 1, k do c = c * (n - i + 1) / i end
    return c
  end
  G.choose = choose
  -- the count expected in bin k (1 .. NBINS) of n balls, if every pin were a fair coin
  function G.expected(n, k) return n * choose(G.DECISIONS, k - 1) / 2 ^ G.DECISIONS end
  -- the height a count fills, from the slide
  function G.fill(count) return count <= 0 and 0 or G.BALL_D + (count - 1) * G.PACK end

  G.build = build
  return G
end

return build()
