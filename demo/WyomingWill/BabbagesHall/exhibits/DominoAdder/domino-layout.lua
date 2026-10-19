-- domino-layout.lua -- Babbage's Hall, the Domino Half Adder
--
-- The machine's layout: every domino's place, as named lines of poses (see
-- domino-lines.lua for the conventions). Pure Lua. Used as
--   local L = dofile("domino-lines.lua")
--   local lines, starts, info = dofile("domino-layout.lua")(L).machine()
--
-- THE MACHINE (drawn with the start at the bottom, as you see it):
--   GO       the start domino; a fork sends the wave to both inputs
--   Ain/Bin  the inputs, mirror images (so both waves arrive together), each
--            with a SWITCH: two dominoes standing (input 1) or taken out
--            (input 0: a gap of three spacings, which no wave can jump)
--   A, B     the feeders: they strike the two ends of
--   C        the collision line. A's wave runs along it to the right, B's to
--            the left; if both come, they meet in the middle and stop.
--   Tr, Tl   taps near C's ends, each taken only by a wave running toward
--            it: Tr by A's (running right), Tl by B's. They merge into
--   SUM      = A XOR B
--   A3       A's carry branch: a long delay line (the serpentine), then up to
--            the CARRY. Its wave gets there late on purpose:
--   INH      a branch of SUM that cuts A3 (knocks out a domino where A3 is
--            spaced wide) before A's own wave arrives. So the carry runs
--            through only if A fired and SUM didn't: A AND NOT (A XOR B)
--            = A AND B.
--   the tell-tales: each output turns back toward you at its end and knocks
--            over a printed tile showing 0; it lands showing the 1 on its
--            back. CARRY is on the left, SUM on the right: read together
--            they are A + B in binary.

return function(L)
local SP = L.SP

local M = {}
function M.xor(opts)
  opts = opts or {}
  local NC = opts.nc or 23                  -- dominoes in the collision line C
  local R = opts.r or 7
  local lines = {}
  -- C: the collision line, along +x
  local C = L.line({ x = 0, z = 0, h = math.pi / 2 }, { { "s", (NC - 1) * SP + 0.01 } })
  local Lc = (NC - 1) * SP
  lines.C = C
  -- A feeds C's left end from below, B its right end from below
  local CA = C[1]
  local CB = { x = C[NC].x, z = C[NC].z, h = -math.pi / 2 }
  lines.A = L.feeder(CA, 1, opts.lf or 30)
  lines.B = L.feeder(CB, -1, opts.lf or 30)
  -- Tr: taken by a wave running right (from A); Tl by one running left
  local k = opts.tapk or 4
  local sR = L.tapStart(C[NC - k + 1], -1)
  local cmds = { { "s", 3 }, { "a", R, math.deg(sR.h) }, { "s", opts.rise or 10 }, { "a", R, 30 } }
  local P = L.endOf(sR, cmds)
  local G = { x = Lc / 2, z = 0, h = 0 }
  local e = L.side({ x = G.x, z = 0, h = 0 }, L.FEED_OFF)            -- (where the right feeder ends: G's right, +x)
  local t = (P.x - e.x) / math.sin(L.FEED_ANG)
  G.z = P.z + t * math.cos(L.FEED_ANG)
  cmds[#cmds + 1] = { "s", t - SP }
  lines.Tr = (L.line(sR, cmds))
  lines.Tl = {}
  for i, p in ipairs(lines.Tr) do lines.Tl[i] = L.mirror(p, Lc / 2) end
  lines.SUM = (L.line(G, { { "s", opts.sumlen or 25 } }))
  return lines, { A = "A", B = "B" }, { G = G, Lc = Lc }
end

-- arc length of a list of poses (straight segments between dominoes)
local function len(poses)
  local s = 0
  for i = 2, #poses do s = s + math.sqrt((poses[i].x - poses[i - 1].x) ^ 2 + (poses[i].z - poses[i - 1].z) ^ 2) end
  return s
end
M.len = len

-- the half adder: SUM = A XOR B (the collision gate above), CARRY = A AND B,
-- made as A inhibited by SUM: A's carry branch is a long delay line, cut by
-- a branch of SUM when SUM fires (A alone, or B alone); when both fire SUM
-- doesn't, and the carry runs through.
function M.half(opts)
  opts = opts or {}
  local R = opts.r or 7
  local GX = opts.gx or 3.6               -- the inhibitor's end, from A3's centre line (3.2-4.0 verified)
  local lines, ins, X = M.xor({ nc = opts.nc or 11, tapk = 3, rise = 6, lf = opts.lf or 40, sumlen = 1 })
  local G, Lc = X.G, X.Lc
  local cx = Lc / 2
  -- the A feeder: its first dominoes are the input path's end; A3 taps it
  local feedA = lines.A
  local tapA = L.tapStart(feedA[opts.tapa or 3], -1)                 -- (to its upper-left side)
  -- SUM: up from the merge; a tap two dominoes up sends the inhibitor left
  local Zi = G.z + (opts.zi or 20)
  local XA3 = opts.xa3 or -12
  local SUM = L.line(G, { { "s", opts.sumlen or 45 } })
  lines.SUM = SUM
  local tapS = L.tapStart(SUM[2], -1)                   -- (-1: to its left, toward -x)
  local inhEnd = { x = XA3 + GX, z = Zi, h = -math.pi / 2 }
  local inh = L.line(tapS, (L.connect(tapS, inhEnd, R)), { fit = true })
  lines.INH = inh
  -- A3: from the tap, a serpentine to the left, then up past the inhibitor
  -- to the carry. Its length up to the inhibitor is made to exceed the
  -- SUM route's (from the same tap) by MARGIN.
  -- the serpentine: from the tap, turn to head left (-x), then horizontal
  -- legs stacked upward (U-turns of radius R), the right-going ones ending
  -- R short of XA3; then a quarter turn up the line x = XA3, past the
  -- inhibitor at Zi, to the carry's end.
  local legs = opts.legs or 2          -- left-going legs (each followed by a right-going one)
  local function a3cmds(Lh)
    local c = { { "s", 2 }, { "a", R, math.deg(tapA.h) + 90 } }      -- (to heading -90: left)
    local p = L.endOf(tapA, c)
    -- the first left leg runs from p.x to xl; the right legs run back to XA3 - R
    local xl = XA3 - R - Lh
    c[#c + 1] = { "s", p.x - xl }
    for i = 1, legs do
      c[#c + 1] = { "a", R, -180 }                 -- up and round to the right
      c[#c + 1] = { "s", (XA3 - R) - xl }
      if i < legs then
        c[#c + 1] = { "a", R, 180 }                -- up and round to the left
        c[#c + 1] = { "s", (XA3 - R) - xl }
      end
    end
    c[#c + 1] = { "a", R, 90 }                     -- up
    local q = L.endOf(tapA, c)
    return c, q
  end
  -- the SUM route from tapA's point: rest of feeder, C, Tr, SUM to its tap, the inhibitor
  local sumRoute = len(feedA) - L.SP + len(lines.C) + len(lines.Tr) + 2 * L.SP + len(inh)
  local MARGIN = opts.margin or 40
  local Ls, A3, a3len
  local q
  for try = 0, 400 do
    Ls = 10 + try * 0.5
    local c
    c, q = a3cmds(Ls)
    A3 = L.line(tapA, c)
    -- the vertical leg, up x = XA3: regular spacing, but around the cut
    -- three dominoes CUT_SP apart, the middle one on the inhibitor's row,
    -- so knocking out that one leaves a gap no wave can jump
    local last = A3[#A3]
    local z = last.z
    local CUT_SP = opts.cutsp or 4.25                 -- (4.1-4.4 verified at friction 0.3 and 0.5)
    while z + L.SP < Zi - CUT_SP - 0.01 do z = z + L.SP; A3[#A3 + 1] = { x = XA3, z = z, h = 0 } end
    -- (the step into the wide section: between SP and CUT_SP)
    for _, dz in ipairs({ -CUT_SP, 0, CUT_SP }) do A3[#A3 + 1] = { x = XA3, z = Zi + dz, h = 0 } end
    z = Zi + CUT_SP
    while z < Zi + (opts.carrylen or 30) do z = z + L.SP; A3[#A3 + 1] = { x = XA3, z = z, h = 0 } end
    -- its length up to the inhibitor's row
    local s, upTo = 0, 0
    for i = 2, #A3 do
      s = s + math.sqrt((A3[i].x - A3[i - 1].x) ^ 2 + (A3[i].z - A3[i - 1].z) ^ 2)
      if A3[i].z <= Zi and math.abs(A3[i].x - XA3) < 0.5 then upTo = s end
    end
    a3len = upTo
    if a3len > sumRoute + MARGIN then break end
  end
  lines.A3 = A3
  assert(q.z < Zi - 8, string.format('the serpentine reaches z=%.1f, too near the inhibitor at %.1f', q.z, Zi))
  X.sumRoute, X.a3len, X.Zi, X.XA3 = sumRoute, a3len, Zi, XA3
  return lines, ins, X
end

-- the whole machine: the half adder, fed from one start domino (GO) through
-- a fork into the two inputs, each with a SWITCH: two dominoes that are
-- either standing (input 1) or taken out (input 0: a gap of three spacings,
-- which no wave can jump). The two input paths are mirror images, so both
-- waves reach the gate together.
function M.machine(opts)
  opts = opts or {}
  local R = opts.r or 7
  local lines, ins, X = M.half(opts)
  local cx = X.Lc / 2
  local SA = lines.A[1]
  local zgo = opts.zgo or (SA.z - 32)
  local GO, E = L.line({ x = cx, z = zgo, h = 0 }, { { "s", opts.golen or 12 } })
  lines.GO = GO
  -- the fork at GO's end: A's branch toward -x
  local FA = L.side(E, -L.TAP_OFF); FA.h = -L.TAP_ANG
  local endA = L.adv(SA, -L.SP)
  local Ain = L.line(FA, (L.connect(FA, endA, R)), { fit = true })
  lines.Ain = Ain
  local Bin = {}
  for i, p in ipairs(Ain) do Bin[i] = L.mirror(p, cx) end
  lines.Bin = Bin
  local k = opts.switchAt or 8
  X.switch = { Ain = { k, k + 1 }, Bin = { k, k + 1 } }
  -- the outputs' ends: SUM goes on up as high as A3; then each turns right
  -- and back toward you, and stands its tell-tale one spacing past its last
  -- domino, side by side (CARRY on the left, SUM on the right)
  local SUM, A3 = lines.SUM, lines.A3
  while SUM[#SUM].z + L.SP <= A3[#A3].z + 0.01 do SUM[#SUM + 1] = L.adv(SUM[#SUM], L.SP) end
  local function uturn(line)
    local start = L.adv(line[#line], L.SP)
    local more = L.line(start, { { "a", R, -180 }, { "s", opts.back or 4 } })
    for _, p in ipairs(more) do line[#line + 1] = p end
    return L.adv(line[#line], L.SP)
  end
  X.tell = { CARRY = uturn(A3), SUM = uturn(SUM) }
  X.go = "GO"
  X.outputs = { SUM = "SUM", CARRY = "A3" }
  return lines, { GO = "GO" }, X
end

  return M
end
