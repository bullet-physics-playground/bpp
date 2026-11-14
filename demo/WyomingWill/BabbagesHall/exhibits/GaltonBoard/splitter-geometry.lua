-- splitter-geometry.lua -- Babbage's Hall, the splitter board
--
-- Every size of the splitter board in one place (millimetres), as
-- galton-geometry.lua is for the Galton board, whose hopper, metering
-- wheels, funnel and neck, plates, slide and drawer it shares (so those are
-- the Galton board's own sizes, read from it). splitter-board.lua runs it
-- through galton.lua; the parts are drawn by parts/splitter.scad from
-- parts/splitter-geometry.scad, written from these.
--
-- In place of the pins, rows of splitters (SPLITTERS.md): each a steel pin
-- carrying a printed tooth, a wedge whose sides slope down into straight
-- necks; each neck drops a ball onto the pin below, half a pitch to the
-- side. Every tooth is the same height, its slope taking what its neck
-- leaves, so a set of teeth with another neck length fits the same rows:
-- that is how the board is tuned to its balls' bounce.
--
-- Swallowing walls (WALL_L, WALL_R: places from the start; 0 for none). A
-- ball reaching that column drops out: the tooth that would be under it is
-- an exit block whose top slopes outward, onto a ramp to its own tube, one
-- tube for each row a ball can be caught at. The tubes stand on the slide,
-- so it empties them with the bins. The first tube is the outermost and
-- highest; each ramp passes over the later, lower tubes.
--
-- Places: a ball's place after n decisions is u (n's parity), at x = u S/2;
-- row r's pins (y = -r V) are at the places of r's parity.

local sqrt, tan, rad = math.sqrt, math.tan, math.rad
local HERE = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or ""   -- (this file's folder)

local function build(o)
  o = o or {}
  local GB = dofile(HERE .. "galton-geometry.lua")
  local G = GB.build({})                  -- the shared parts: the Galton board's own sizes
  G.WH = G.W                              -- the hopper keeps the Galton board's width
  G.NAME = "splitter"

  -- the splitters (SPLITTERS.md): a 30 mm pitch, necks 8 mm wide; teeth of
  -- one height, 29.05 mm from the pin's centre to the necks' foot, which is
  -- FOOT above the next pin (as the feed's neck is above the first)
  G.S = 30
  G.PLACE = G.S / 2
  G.PIN_D = 4.0
  G.NECK_W = 8
  G.TOTAL = 29.05
  G.TOOTH_NECK = o.TOOTH_NECK or 10       -- the set of teeth: 10, 12, 14 or 20 (SPLITTERS.md)
  G.HW = G.S / 2 - G.NECK_W / 2           -- a tooth's half width
  G.TH = G.TOTAL - G.TOOTH_NECK           -- its slope's drop
  G.FOOT = G.CHUTE_Y
  G.V = G.TOTAL + G.FOOT                  -- row to row
  G.SLOPE = math.deg(math.atan(G.TH / G.HW))
  G.DECISIONS = o.DECISIONS or 12
  G.ROWS = G.DECISIONS
  G.TOP = 0
  G.WALL_L = o.WALL_L or 2
  G.WALL_R = o.WALL_R or 0
  G.EXIT_TOP = 20                         -- an exit block's top, degrees down outward
  G.RAMP = 6                              -- the ramps to the tubes, degrees
  G.RAMP_T = 2.0
  G.TUBE_IN = 7.0                         -- a tube's inside: one ball, single file
  G.TUBE_WALL = 2.0
  G.TUBE_PITCH = G.TUBE_IN + G.TUBE_WALL

  -- the bins: one at each place a survivor can end at (13, as on the Galton
  -- board, 30 mm wide), between dividers under the last row's teeth
  G.NBINS = G.DECISIONS + 1
  G.W = G.NBINS / 2 * G.S - G.DIV_T / 2
  local function rowY(r) return -r * G.V end
  G.rowY = rowY
  G.BIN_H = o.BIN_H or 120
  G.Y_DIV = rowY(G.DECISIONS - 1) - G.TOTAL
  G.Y_FLOOR = G.Y_DIV - G.BIN_H
  G.Y_DRAWER = G.Y_FLOOR - G.SLIDE_T - G.DRAWER_H
  G.Y_SIDE = G.Y_FLOOR                    -- (not used: no slanting side walls)

  local a, b = G.WALL_L, G.WALL_R
  local function alive(u, n) return math.abs(u) <= n and (a == 0 or u > -a) and (b == 0 or u < b) end
  local function exitAt(u, n) return math.abs(u) <= n and ((a > 0 and u == -a) or (b > 0 and u == b)) end
  local function neckLive(v, r) return alive(v, r + 1) or exitAt(v, r + 1) end

  -- the exact chances for independent fair pins (as walls.py works them):
  -- caught on each side at each decision, and each place after the last
  do
    local p = { [0] = 1.0 }
    G.exactLeft, G.exactRight = {}, {}
    for n = 1, G.DECISIONS do
      local q = {}
      for u, w in pairs(p) do
        q[u - 1] = (q[u - 1] or 0) + w / 2
        q[u + 1] = (q[u + 1] or 0) + w / 2
      end
      G.exactLeft[n], G.exactRight[n] = 0, 0
      local keep = {}
      for u, w in pairs(q) do
        if a > 0 and u <= -a then G.exactLeft[n] = G.exactLeft[n] + w
        elseif b > 0 and u >= b then G.exactRight[n] = G.exactRight[n] + w
        else keep[u] = w end
      end
      p = keep
    end
    G.exactPile = p
  end

  -- the teeth, pins, exit blocks; the catches (row, side) in order
  G.pins, G.bumps, G.teeth, G.solids = {}, {}, {}, {}
  local catches = { [-1] = {}, [1] = {} }
  local blocks = {}
  local te = tan(rad(G.EXIT_TOP))
  for r = 0, G.DECISIONS do
    for u = -G.DECISIONS, G.DECISIONS do
      if (u - r) % 2 == 0 then
        local x, y = u * G.PLACE, rowY(r)
        if r >= 1 and exitAt(u, r) then
          local s = u < 0 and -1 or 1     -- the wall's side; inward is -s
          local d = -s
          local q = { { x + d * G.HW, y - 1 }, { x + d * G.HW, y - G.TOTAL }, { x - d * G.HW, y - G.TOTAL },
                      { x - d * G.HW, y - 1 - 2 * G.HW * te } }
          G.solids[#G.solids + 1] = q
          blocks[#blocks + 1] = { r = r, s = s, x = x - d * G.HW, y = y - 1 - 2 * G.HW * te, poly = q }
          table.insert(catches[s], r)
        elseif r < G.DECISIONS and math.abs(u) <= G.DECISIONS and (neckLive(u - 1, r) or neckLive(u + 1, r)) then
          G.teeth[#G.teeth + 1] = { { x, y }, { x + G.HW, y - G.TH }, { x + G.HW, y - G.TOTAL },
                                    { x - G.HW, y - G.TOTAL }, { x - G.HW, y - G.TH } }
          if alive(u, r) then G.pins[#G.pins + 1] = { x, y } end
        end
      end
    end
  end

  -- the tubes, and a ramp from each exit block to its tube
  G.tubes = {}
  local tr = tan(rad(G.RAMP))
  for _, s in ipairs({ -1, 1 }) do
    table.sort(catches[s])
    local m = #catches[s]
    for j, r in ipairs(catches[s]) do
      local X = s * (G.W - G.TUBE_IN / 2 - (j - 1) * G.TUBE_PITCH)
      local blk
      for _, bk in ipairs(blocks) do if bk.r == r and bk.s == s then blk = bk end end
      local xe = X - s * G.TUBE_IN / 2                -- the tube's inner side
      local ye = blk.y - math.abs(xe - blk.x) * tr
      G.solids[#G.solids + 1] = { { blk.x, blk.y }, { blk.x, blk.y - G.RAMP_T }, { xe, ye - G.RAMP_T }, { xe, ye } }
      G.tubes[#G.tubes + 1] = { x = X, e = ye, row = r, side = s, j = j,
                                p = (s < 0 and G.exactLeft or G.exactRight)[r] }
    end
    -- each tube's inner wall: up to just under its ramp's end, so a ball
    -- that comes off the ramp, meets the tube's outer wall and bounces back
    -- can't clear it into the next tube (it did, at first: the row 2 tube
    -- got a third of its balls, the row 4 tube twice its). It is the next
    -- tube's outer wall too, far above that tube's ramp.
    for j = 1, m do
      local t = G.tubes[#G.tubes - m + j]
      local top = t.e - G.RAMP_T - 0.2
      local x0 = t.x - s * G.TUBE_IN / 2
      local x1 = x0 - s * G.TUBE_WALL
      G.solids[#G.solids + 1] = { { math.min(x0, x1), G.Y_FLOOR }, { math.max(x0, x1), G.Y_FLOOR },
                                  { math.max(x0, x1), top }, { math.min(x0, x1), top } }
    end
  end
  function G.tubeOf(x, y)
    for i, t in ipairs(G.tubes) do
      if math.abs(x - t.x) < G.TUBE_IN / 2 + 0.5 and y > G.Y_FLOOR - 1 and y < t.e + 8 then return i end
    end
  end

  -- a ramp must pass over or under everything else with room for a ball
  local function yAt(p0, p1, x) return p0[2] + (p1[2] - p0[2]) * (x - p0[1]) / (p1[1] - p0[1]) end
  for _, t in ipairs(G.tubes) do
    local ramp
    for _, q in ipairs(G.solids) do
      if #q == 4 and q[4][2] == t.e and q[1][1] ~= q[4][1] then ramp = q end
    end
    local xa, xb = math.min(ramp[1][1], ramp[4][1]), math.max(ramp[1][1], ramp[4][1])
    for _, list in ipairs({ G.teeth, G.solids }) do
      for _, q in ipairs(list) do
        if q ~= ramp then
          local qa, qb, ya, yb = math.huge, -math.huge, math.huge, -math.huge
          for _, p in ipairs(q) do
            qa, qb = math.min(qa, p[1]), math.max(qb, p[1]); ya, yb = math.min(ya, p[2]), math.max(yb, p[2])
          end
          local lo, hi = math.max(xa, qa), math.min(xb, qb)
          if hi > lo + 0.01 then
            local top = math.max(yAt(ramp[1], ramp[4], lo), yAt(ramp[1], ramp[4], hi))
            local bottom = math.min(yAt(ramp[1], ramp[4], lo), yAt(ramp[1], ramp[4], hi)) - G.RAMP_T
            assert(ya >= top + G.BALL_D + 1 or yb <= bottom + 0.01 or q[4][2] == t.e,
              string.format("the splitter board: the ramp from row %d hits something at x %.1f", t.row, lo))
          end
        end
      end
    end
  end

  -- the bins and their dividers: under the last row's teeth, between the
  -- places a survivor can end at
  G.bins, G.dividers = {}, {}
  for k = 0, G.NBINS - 1 do G.bins[#G.bins + 1] = (k - (G.NBINS - 1) / 2) * G.S end
  -- (the survivors end at places of the last decision's parity, between
  -- the walls; a divider either side of each, where the board's side walls
  -- are not)
  local N = G.DECISIONS
  local lo, hi
  for u = -N, N, 2 do
    if alive(u, N) then lo = lo or u; hi = u end
  end
  for u = lo - 1, hi + 1, 2 do
    if math.abs(u) < N + 1 then G.dividers[#G.dividers + 1] = u * G.PLACE end
  end
  function G.binOf(x)
    local k = math.floor(x / G.S + (G.NBINS - 1) / 2 + 0.5) + 1
    return math.max(1, math.min(G.NBINS, k))
  end
  -- the count expected in bin k of n balls, and in tube i
  function G.expected(n, k) return n * (G.exactPile[2 * (k - 1) - G.DECISIONS] or 0) end
  function G.tubeExpected(n, i) return n * G.tubes[i].p end
  -- the height a count fills: a bin (30 mm: about 4.5 balls a layer, 5.2 mm
  -- a layer), a tube (single file)
  function G.fill(count) return count <= 0 and 0 or G.BALL_D + (count / 4.5 - 1) * 5.2 end
  function G.tubeFill(count) return count * G.BALL_D end

  -- the levels at which a ball's place is read (just inside each row's necks)
  G.levels = {}
  for r = 0, G.DECISIONS - 1 do G.levels[#G.levels + 1] = rowY(r) - G.TH - 2 end

  -- the walls: the slide, the sides, a ceiling over the rows from the sides
  -- to the feed's neck, the neck and the funnel (as on the Galton board),
  -- the housings, the hopper (the Galton board's width), the drawer
  local function seg(list, x1, y1, x2, y2, t) list[#list + 1] = { x1, y1, x2, y2, t = t } end
  local base = G.walls
  G.walls = {}
  local Wl = G.walls
  local T, C, ny = G.CHUTE_T, G.CHUTE, G.CHUTE_Y + G.NECK_L
  seg(Wl, -G.W, G.Y_FLOOR, G.W, G.Y_FLOOR)
  Wl[#Wl].slide = true
  seg(Wl, G.W, G.Y_FLOOR, G.W, ny)
  seg(Wl, G.W, ny, C + T, ny)
  seg(Wl, C + T, ny, C + T, G.CHUTE_Y, T)
  seg(Wl, C, G.CHUTE_Y, C, ny, T)
  seg(Wl, C, ny, G.MOUTH_X, G.MOUTH_Y, T)
  seg(Wl, G.CEIL_X, G.MOUTH_Y, -G.CEIL_X, G.MOUTH_Y, 1)
  seg(Wl, -G.MOUTH_X, G.MOUTH_Y, -C, ny, T)
  seg(Wl, -C, ny, -C, G.CHUTE_Y, T)
  seg(Wl, -C - T, G.CHUTE_Y, -C - T, ny, T)
  seg(Wl, -C - T, ny, -G.W, ny)
  seg(Wl, -G.W, ny, -G.W, G.Y_FLOOR)
  for _, w in ipairs(base) do     -- the housings and the hopper, as they were (the Galton board's)
    if math.min(w[2], w[4]) > G.MOUTH_Y - 0.01 and not (w[2] == G.MOUTH_Y and w[4] == G.MOUTH_Y) then
      Wl[#Wl + 1] = w
    end
  end
  seg(Wl, -G.W, G.Y_DRAWER, G.W, G.Y_DRAWER)
  seg(Wl, G.W, G.Y_DRAWER, G.W, G.Y_FLOOR - G.SLIDE_T)
  seg(Wl, -G.W, G.Y_FLOOR - G.SLIDE_T, -G.W, G.Y_DRAWER)

  -- the main ball space, for the print: the rows' space and the neck and
  -- funnel up to the wheels (the hopper's is the Galton board's)
  local function beyond(x0, y0, x1, y1, d)
    local L = sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    return { x1 + (x1 - x0) / L * d, y1 + (y1 - y0) / L * d }
  end
  local XW, WY, MX, MY, CX = G.WHEEL_X, G.WHEEL_Y, G.MOUTH_X, G.MOUTH_Y, G.CEIL_X
  G.spaces.main = { { -G.W, G.Y_FLOOR }, { G.W, G.Y_FLOOR }, { G.W, ny }, { C + T, ny }, { C + T, G.CHUTE_Y },
    { C, G.CHUTE_Y }, { C, ny }, beyond(C, ny, MX, MY, 3), { XW, WY }, { CX + 3, MY }, { -CX - 3, MY }, { -XW, WY },
    beyond(-C, ny, -MX, MY, 3), { -C, ny }, { -C, G.CHUTE_Y }, { -C - T, G.CHUTE_Y }, { -C - T, ny }, { -G.W, ny } }

  -- the board's outside, the stand
  G.OUT_W = 2 * (G.W + G.RIM)
  G.OUT_Y0, G.OUT_Y1 = G.Y_DRAWER - G.RIM, G.Y_TOP + G.RIM
  G.OUT_H = G.OUT_Y1 - G.OUT_Y0
  G.FOOT_W = G.OUT_W + 30
  G.CUTS = { G.rowY(4), G.rowY(9) }

  G.build = build
  return G
end

return build()
