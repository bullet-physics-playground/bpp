-- domino-lines.lua -- Babbage's Hall, the Domino Half Adder
--
-- Laying domino lines out: along "turtle" paths of straights and arcs, and
-- the few junctions the machine is built from, each one checked in the
-- simulation before it was used (see FINDINGS.md). Pure Lua -- no bpp calls --
-- so the same layout drives the simulation and the printed template.
--
-- The board as you see it from in front: x to the right, z away from you
-- (up the page of a drawing), centimetres. A pose is { x, z, h }: a place
-- and a heading h, the way a wave travels through a domino there, as the
-- direction (sin h, cos h). A domino stands with its broad face across its
-- heading, so it falls along it. h = 0 runs away from you, pi/2 to the right.

local M = {}
M.W, M.H, M.T = 2.4, 4.8, 0.75     -- domino: width, height, thickness (cm)
M.SP = 2.6                          -- spacing along a line (cm)

local function adv(p, d) return { x = p.x + d * math.sin(p.h), z = p.z + d * math.cos(p.h), h = p.h } end
local function side(p, d)            -- d to the RIGHT of the heading (as drawn)
  return { x = p.x + d * math.cos(p.h), z = p.z - d * math.sin(p.h), h = p.h }
end
M.adv, M.side = adv, side

-- path(start, cmds): the poses along it, every ds of arc length.
--   { "s", L }        straight on L
--   { "a", R, deg }   arc of radius R turning deg (positive: to the left, as drawn)
local function trace(start, cmds, ds)
  local pts = { { x = start.x, z = start.z, h = start.h } }
  local p = pts[1]
  for _, c in ipairs(cmds) do
    if c[1] == "s" then
      local n = math.max(1, math.ceil(c[2] / ds))
      for i = 1, n do p = adv(p, c[2] / n); pts[#pts + 1] = p end
    else
      local R, a = c[2], math.rad(c[3])
      local n = math.max(1, math.ceil(math.abs(a) * R / ds))
      local da = a / n
      for i = 1, n do
        -- chord step of an arc: turn half, go, turn half
        local q = { x = p.x, z = p.z, h = p.h - da / 2 }
        q = adv(q, 2 * R * math.sin(math.abs(da) / 2))
        q.h = q.h - da / 2
        p = q; pts[#pts + 1] = p
      end
    end
  end
  return pts
end

-- dominoes along a path, every SP; first at 'from' (arc length) along it.
-- Returns the list of poses and the end pose (one SP past the last domino).
function M.line(start, cmds, opts)
  opts = opts or {}
  local sp = opts.sp or M.SP
  local from = opts.from or 0
  local pts = trace(start, cmds, 0.05)
  if opts.fit then
    -- spacing adjusted so that dominoes stand at both ends exactly
    local total = 0
    for i = 2, #pts do total = total + math.sqrt((pts[i].x - pts[i - 1].x) ^ 2 + (pts[i].z - pts[i - 1].z) ^ 2) end
    local n = math.max(1, math.floor(total / sp + 0.5))
    sp = total / n
    from = 0
    opts.sp_used = sp
  end
  local out, acc, nextAt = {}, 0, from
  for i = 1, #pts do
    if i > 1 then acc = acc + math.sqrt((pts[i].x - pts[i - 1].x) ^ 2 + (pts[i].z - pts[i - 1].z) ^ 2) end
    if acc >= nextAt - 1e-6 then
      out[#out + 1] = { x = pts[i].x, z = pts[i].z, h = pts[i].h }
      nextAt = nextAt + sp
    end
  end
  local last = pts[#pts]
  if opts.fit then
    local q = out[#out]
    if math.sqrt((q.x - last.x) ^ 2 + (q.z - last.z) ^ 2) > 0.3 then out[#out + 1] = { x = last.x, z = last.z, h = last.h }
    else out[#out] = { x = last.x, z = last.z, h = last.h } end
  end
  return out, { x = last.x, z = last.z, h = last.h }, acc
end

-- the end of a path, with no dominoes (to find where something ends up)
function M.endOf(start, cmds)
  local pts = trace(start, cmds, 0.05)
  local acc = 0
  for i = 2, #pts do acc = acc + math.sqrt((pts[i].x - pts[i - 1].x) ^ 2 + (pts[i].z - pts[i - 1].z) ^ 2) end
  return pts[#pts], acc
end

-- connect(p, q, R): commands for the shortest arc-straight-arc path (radius
-- R) from pose p to pose q. Found by trying all four turn pairs and both
-- tangents, keeping those that really end at q.
local function wrap(a) a = a % (2 * math.pi); return a end
function M.connect(p, q, R)
  local best, bestLen
  local function center(pp, s)       -- s = +1: an arc that decreases h (a left turn, trace's positive)
    return side(pp, -s * R)
  end
  for _, s1 in ipairs({ 1, -1 }) do
    for _, s2 in ipairs({ 1, -1 }) do
      local c1, c2 = center(p, s1), center(q, s2)
      local dx, dz = c2.x - c1.x, c2.z - c1.z
      local d = math.sqrt(dx * dx + dz * dz)
      local base = math.atan2(dx, dz)
      local cands = {}
      if s1 == s2 then cands = { { base, d } }
      elseif d > 2 * R then
        local off = math.asin(2 * R / d)
        local ls = math.sqrt(d * d - 4 * R * R)
        cands = { { base + off, ls }, { base - off, ls } }
      end
      for _, c in ipairs(cands) do
        local ht, ls = c[1], c[2]
        local a1 = (s1 > 0) and wrap(p.h - ht) or -wrap(ht - p.h)
        local a2 = (s2 > 0) and wrap(ht - q.h) or -wrap(q.h - ht)
        local cmds = { { "a", R, math.deg(a1) }, { "s", ls }, { "a", R, math.deg(a2) } }
        local e = M.endOf(p, cmds)
        local err = math.sqrt((e.x - q.x) ^ 2 + (e.z - q.z) ^ 2)
        local len = R * (math.abs(a1) + math.abs(a2)) + ls
        if err < 0.1 and (not bestLen or len < bestLen) then best, bestLen = cmds, len end
      end
    end
  end
  assert(best, "connect: no path")
  return best, bestLen
end

-- The template's pocket walls round a set of domino poses, as boxes
-- { x, z, h, sx, sz } (sx across the domino's heading, sz along it), for the
-- simulation. As on the printed tile (frames minus pockets), no wall stands
-- inside another domino's pocket: walls are cut into pieces no longer than
-- PIECE and those that would overlap another pocket are left out. A pose may
-- carry its own w and t (the tell-tales are bigger than a domino).
M.POCKET_C, M.WALL_W, M.WALL_H = 0.04, 0.12, 0.16
function M.pocketWalls(poses)
  local PC, PW = M.POCKET_C, M.WALL_W
  local PIECE = 0.4
  local function halves(p) return (p.w or M.W) / 2 + PC, (p.t or M.T) / 2 + PC end    -- a pocket's half sizes
  -- a spatial hash of the pockets
  local cell, grid = 8, {}
  local function key(i, j) return i * 100003 + j end
  for idx, p in ipairs(poses) do
    local k = key(math.floor(p.x / cell), math.floor(p.z / cell))
    grid[k] = grid[k] or {}
    table.insert(grid[k], idx)
  end
  -- does a rectangle (centre, heading, half sizes a across, b along) overlap pocket q?
  local function overlaps(cx, cz, h, a, b, q)
    local axes = { { math.cos(h), -math.sin(h) }, { math.sin(h), math.cos(h) },
                   { math.cos(q.h), -math.sin(q.h) }, { math.sin(q.h), math.cos(q.h) } }
    local dx, dz = q.x - cx, q.z - cz
    for _, ax in ipairs(axes) do
      local function rad(hh, ha, hb)
        local u = { math.cos(hh), -math.sin(hh) }
        local w = { math.sin(hh), math.cos(hh) }
        return ha * math.abs(u[1] * ax[1] + u[2] * ax[2]) + hb * math.abs(w[1] * ax[1] + w[2] * ax[2])
      end
      local dist = math.abs(dx * ax[1] + dz * ax[2])
      local qa, qb = halves(q)
      if dist >= rad(h, a, b) + rad(q.h, qa, qb) - 1e-4 then return false end
    end
    return true
  end
  local walls = {}
  for idx, p in ipairs(poses) do
    local hw, ht = halves(p)
    local ux, uz = math.sin(p.h), math.cos(p.h)              -- along
    local vx, vz = math.cos(p.h), -math.sin(p.h)             -- across
    -- the four walls: { across offset, along offset, length, direction ("across" or "along") }
    local defs = {
      { 0, ht + PW / 2, 2 * (hw + PW), "across" }, { 0, -ht - PW / 2, 2 * (hw + PW), "across" },
      { hw + PW / 2, 0, 2 * ht, "along" }, { -hw - PW / 2, 0, 2 * ht, "along" },
    }
    for _, d in ipairs(defs) do
      local n = math.max(1, math.ceil(d[3] / PIECE))
      local seg = d[3] / n
      -- runs of consecutive clear pieces become one box
      local runStart
      local function flush(kEnd)
        if not runStart then return end
        local t0 = -d[3] / 2 + (runStart - 1) * seg
        local t1 = -d[3] / 2 + kEnd * seg
        local t, L = (t0 + t1) / 2, t1 - t0
        local a, b = d[1], d[2]
        local sa, sb
        if d[4] == "across" then a = a + t; sa, sb = L, PW else b = b + t; sa, sb = PW, L end
        walls[#walls + 1] = { x = p.x + a * vx + b * ux, z = p.z + a * vz + b * uz, h = p.h, sx = sa, sz = sb }
        runStart = nil
      end
      for k = 1, n do
        local t = -d[3] / 2 + (k - 0.5) * seg
        local a, b = d[1], d[2]
        local sa, sb
        if d[4] == "across" then a = a + t; sa, sb = seg, PW else b = b + t; sa, sb = PW, seg end
        local cx, cz = p.x + a * vx + b * ux, p.z + a * vz + b * uz
        local clear = true
        local gi, gj = math.floor(cx / cell), math.floor(cz / cell)
        for di = -1, 1 do for dj = -1, 1 do
          for _, j in ipairs(grid[key(gi + di, gj + dj)] or {}) do
            if j ~= idx and clear and overlaps(cx, cz, p.h, sa / 2, sb / 2, poses[j]) then clear = false end
          end
        end end
        if clear then runStart = runStart or k else flush(k - 1) end
      end
      flush(n)
    end
  end
  return walls
end

-- in the frame of pose G (its heading as +z): local (lx, lz) -> world
local function frame(G, lx, lz)
  -- lx to the right of the heading (side() convention), lz along it
  local s = side(G, lx)
  return adv(s, lz)
end
M.frame = frame

-- mirror a pose across the vertical line x = cx
function M.mirror(p, cx) return { x = 2 * cx - p.x, z = p.z, h = -p.h } end

-- a feeder: a straight line of length Lf ending so that its last domino
-- strikes the domino standing at G from one side (sgn = +1: from G's right,
-- -1: from its left), at angle ang to G's heading. Verified as a merge:
-- offset 0.3-0.7 cm, angle 15-35 deg all work; 0.5 and 25-30 used.
M.FEED_OFF, M.FEED_ANG = 0.5, math.rad(30)
function M.feeder(G, sgn, Lf)
  local h = G.h - sgn * M.FEED_ANG
  local e = side(G, sgn * M.FEED_OFF)
  local start = { x = e.x - Lf * math.sin(h), z = e.z - Lf * math.cos(h), h = h }
  -- (spaced to fit exactly: its last domino one SP short of e)
  return (M.line(start, { { "s", Lf - M.SP } }, { fit = true })), start
end

-- a tap: where a branch leaves a continuing line (between two of its
-- dominoes), to the side sgn (+1 right, -1 left), heading off at ang to the line.
-- Verified: taken by a wave running toward its heading, and NOT by one
-- running the other way (which knocks only its first domino).
M.TAP_OFF, M.TAP_ANG = 1.4, math.rad(25)
function M.tapStart(Pd, sgn)
  -- Pd: the line's domino pose just before the tap point
  local s = frame(Pd, sgn * M.TAP_OFF, M.SP / 2)
  s.h = Pd.h + sgn * M.TAP_ANG
  return s
end

return M
