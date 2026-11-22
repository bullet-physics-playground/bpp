--
-- lock.lua -- the combination lock's geometry and its working, with no
-- physics (Babbage's Hall). The exhibit builds its bodies from these sizes
-- and pieces; lock-test.lua tries every combination with the model here;
-- `lua lock.lua scad` writes parts/lock-geometry.scad, which every printed
-- part takes its sizes from; `lua lock.lua gates 31 72 46` gives the wheels'
-- gate angles for a combination (make-stls.sh uses it).
--
-- THE LOCK (Sargent & Greenleaf's arrangement, as in a safe's door): the dial
-- turns a spindle, and the spindle the drive cam; behind the cam three
-- wheels turn loose on a fixed post. A steel pin through each wheel, and one
-- in the cam's back, make the lost motion: turning the dial, the cam's pin
-- comes round to wheel 3's pin and carries it on; wheel 3's to wheel 2's;
-- wheel 2's to wheel 1's. Each wheel has a gate (a notch) in its rim. A
-- lever, pivoted on the bolt, lays a steel rod (the fence) across the rims
-- of all three wheels and the cam; the cam is 0.4 mm bigger, so the rod
-- rests on the cam, clear of the wheels, which turn freely under it. When
-- the cam's notch comes under the rod it can fall, but only as far as the
-- wheels let it: into their gates if all three are under it, else 0.4 mm
-- onto their rims. Turning right, the notch's steep wall hooks a rod that
-- has fallen in and pulls it, the lever and the bolt; a rod that only
-- touched the rims rides up out of it.
--
-- NUMBERS: angles are counted in the dial's numbers, 100 to a turn (3.6
-- degrees each), anticlockwise as you face the dial (turning it LEFT), from
-- the +x axis. The dial reads D mod 100 when it has turned D numbers left
-- from 0. Wheel 1 (at the back) holds the first number, wheel 3 (next to the
-- cam) the last.
--
-- Lengths in millimetres. The lock's frame: x to the right, y up, z toward
-- you; the origin on the spindle's axis, at the back plate's front face.
--

local L = {}

local G = {
  -- the wheels
  R_W = 40, T_W = 5,                 -- radius (wheel 1's, the largest), thickness
  R_WHEELS = { 40.0, 39.9, 39.8 },   -- each wheel's: not quite alike, as real ones never are (here on
                                     -- purpose, and more: so the safecracker's way can feel which holds the fence up)
  GATE_HALF = 7.0,                   -- degrees either side of its middle (radial walls): 9.8 mm at the rim
  GATE_DEPTH = 5.5,
  HUB_R = 6.2,                       -- the bore, on the 12 mm post
  Z_W = { 6, 17, 28 },               -- wheels 1, 2, 3: their back faces
  -- the drive cam (on the spindle)
  R_C = 40.4, T_C = 6, Z_C = 39,     -- 0.4 mm over the wheels' rims: the fence rests on the cam
  NOTCH_R = 36.4,                    -- the notch's floor (4 mm deep)
  NOTCH_W = 10,                      -- degrees of floor
  RAMP = 72,                         -- the leading wall (the one turning left meets): degrees from the floor
  CHAMFER = 0.8, CHAMFER_ANG = 25,   -- both walls' top edges: chamfered so deep, at so many degrees from the rim
  -- the pins: steel, 3 mm, through each wheel and in the cam's back
  PIN_R = 25, PIN_D = 3, PIN_L = 14, CAM_PIN_OUT = 4.5, CAM_PIN_IN = 5,
  PIN_AT = 270,                      -- degrees, in each part's own frame
  -- the fence: a 4 mm steel rod on the lever
  ROD_D = 4, ROD_Z0 = 3, ROD_Z1 = 51,
  -- the lever: pivoted on the bolt, the rod at its right end
  PIVOT_X = -60, LEVER_Z0 = 47, LEVER_Z1 = 51,
  LEVER_PRESS = 0.3,                 -- N: its spring, at the rod
  -- the bolt: slides along x; 0 thrown, BOLT_TRAVEL drawn back
  BOLT_TRAVEL = 12, BOLT_W = 10, BOLT_Z0 = 36, BOLT_Z1 = 46, BOLT_END = -122,
  BOLT_DRAG = 0.6,                   -- N: its friction in the guides
  -- the frame
  POST_R = 6, POST_Z1 = 36,
  WASHER_R = 18,
  SPINDLE_R = 4,
  STAND_Z0 = 56, STAND_Z1 = 62,      -- the front standard (the door), the dial's bearing
  DIAL_R = 40, DIAL_Z0 = 65, DIAL_Z1 = 71, KNOB_R = 14, KNOB_Z1 = 85,
  AXIS_H = 75,                       -- the spindle's height above the table
  BACK_T = 6,
}
G.ROD_Y = G.R_C + G.ROD_D / 2         -- the rod's centre, resting on the cam
L.G = G

L.N = 100                             -- numbers on the dial
L.DEG = 360 / L.N
L.TOP = 90 / L.DEG                    -- straight up, in numbers (25)
L.DELTA = 2 * math.deg(math.asin(G.PIN_D / 2 / G.PIN_R)) / L.DEG   -- two pins touching: 1.91 numbers apart
L.PIN = G.PIN_AT / L.DEG              -- every pin's place in its own part's frame (75)
L.OPEN_AT = 0                         -- the dial's reading when the cam's notch is under the rod
L.HOOK_DROP = G.ROD_Y - (G.R_C - G.CHAMFER)   -- the fence's centre down to the top of the notch's steep wall, which then hooks it (2.8 mm)
L.WHEELS = { "1", "2", "3" }

local function wrap(x, m) m = m or L.N; return x - m * math.floor(x / m) end
local function centred(x) return wrap(x + L.N / 2) - L.N / 2 end
L.wrap, L.centred = wrap, centred

-- ---------------------------------------------------------------------
-- the pieces: each part's outline cut into convex pieces (for Bullet; the
-- model's rod uses the same). A piece is a list of {x, y} in its part's
-- own frame. Arcs are drawn every 2.5 degrees, as OpenSCAD's $fn = 144.
-- ---------------------------------------------------------------------
local ARC = 2.5
local function arc(r, a0, a1)        -- the points from a0 to a1 (degrees), every ARC or less
  local n = math.max(1, math.ceil(math.abs(a1 - a0) / ARC - 1e-9))
  local pts = {}
  for i = 0, n do
    local a = math.rad(a0 + (a1 - a0) * i / n)
    pts[#pts + 1] = { r * math.cos(a), r * math.sin(a) }
  end
  return pts
end
local function sector(r, a0, a1, rin)    -- a ring's sector, as one convex piece (under 180 degrees)
  rin = rin or G.HUB_R
  local p = arc(r, a0, a1)
  p[#p + 1] = { rin * math.cos(math.rad(a1)), rin * math.sin(math.rad(a1)) }
  p[#p + 1] = { rin * math.cos(math.rad(a0)), rin * math.sin(math.rad(a0)) }
  return p
end
local function sectors(r, a0, a1, out)   -- a0 to a1 (a1 > a0) in pieces of 30 degrees or less
  local n = math.max(1, math.ceil((a1 - a0) / 30 - 1e-9))
  for i = 0, n - 1 do out[#out + 1] = sector(r, a0 + (a1 - a0) * i / n, a0 + (a1 - a0) * (i + 1) / n) end
  return out
end

-- wheel i (1 if not given), its gate's middle at gateDeg (its own frame)
function L.wheelPieces(gateDeg, i)
  local h, r = G.GATE_HALF, G.R_WHEELS[i or 1]
  local out = { sector(r - G.GATE_DEPTH, gateDeg - h, gateDeg + h) }
  return sectors(r, gateDeg + h, gateDeg - h + 360, out)
end

-- the cam: its notch's floor from aL to aT (own frame), at the top when
-- the dial reads OPEN_AT. The trailing wall (at aT: the one that pulls the
-- rod when the dial turns right) is radial, its top edge chamfered (a rod
-- that has only fallen onto the wheels' rims meets the chamfer alone, and
-- is lifted out); the leading wall leans out at RAMP degrees from the floor,
-- its top edge chamfered too (the rod is let down onto the wheels at the
-- cam's pace, not dropped).
L.NOTCH_MID = 90 - L.DEG * L.OPEN_AT
function L.camNotch()
  local aL, aT = L.NOTCH_MID - G.NOTCH_W / 2, L.NOTCH_MID + G.NOTCH_W / 2
  -- the leading wall: from the floor's corner at aL, going clockwise (toward
  -- smaller angles) and out, RAMP degrees from the floor's tangent
  local c = { G.NOTCH_R * math.cos(math.rad(aL)), G.NOTCH_R * math.sin(math.rad(aL)) }
  local t = { math.sin(math.rad(aL)), -math.cos(math.rad(aL)) }        -- the tangent, clockwise
  local n = { math.cos(math.rad(aL)), math.sin(math.rad(aL)) }         -- outward
  local d = { t[1] * math.cos(math.rad(G.RAMP)) + n[1] * math.sin(math.rad(G.RAMP)),
              t[2] * math.cos(math.rad(G.RAMP)) + n[2] * math.sin(math.rad(G.RAMP)) }
  -- up to the chamfer's foot: |c + s d| = R_C - CHAMFER
  local rch = G.R_C - G.CHAMFER
  local b = c[1] * d[1] + c[2] * d[2]
  local s = -b + math.sqrt(b * b - (G.NOTCH_R ^ 2 - rch ^ 2))
  local foot = { c[1] + s * d[1], c[2] + s * d[2] }
  -- then the chamfer: clockwise and out, CHAMFER_ANG from the tangent, to the rim
  local af = math.atan2(foot[2], foot[1])
  local tf, nf = { math.sin(af), -math.cos(af) }, { math.cos(af), math.sin(af) }
  local d2 = { tf[1] * math.cos(math.rad(G.CHAMFER_ANG)) + nf[1] * math.sin(math.rad(G.CHAMFER_ANG)),
               tf[2] * math.cos(math.rad(G.CHAMFER_ANG)) + nf[2] * math.sin(math.rad(G.CHAMFER_ANG)) }
  local b3 = foot[1] * d2[1] + foot[2] * d2[2]
  local s3 = -b3 + math.sqrt(b3 * b3 - (rch ^ 2 - G.R_C ^ 2))
  local top = { foot[1] + s3 * d2[1], foot[2] + s3 * d2[2] }
  local aR = math.deg(math.atan2(top[2], top[1]))
  while aR > aL do aR = aR - 360 end
  while aR < aL - 180 do aR = aR + 360 end
  -- the chamfer: from the steep wall's top (R_C - CHAMFER at aT), anticlockwise
  -- and out at CHAMFER_ANG from the tangent, to the rim at aC
  local p1 = { rch * math.cos(math.rad(aT)), rch * math.sin(math.rad(aT)) }
  local tc = { -math.sin(math.rad(aT)), math.cos(math.rad(aT)) }
  local nc = { math.cos(math.rad(aT)), math.sin(math.rad(aT)) }
  local dc = { tc[1] * math.cos(math.rad(G.CHAMFER_ANG)) + nc[1] * math.sin(math.rad(G.CHAMFER_ANG)),
               tc[2] * math.cos(math.rad(G.CHAMFER_ANG)) + nc[2] * math.sin(math.rad(G.CHAMFER_ANG)) }
  local b2 = p1[1] * dc[1] + p1[2] * dc[2]
  local s2 = -b2 + math.sqrt(b2 * b2 - (rch ^ 2 - G.R_C ^ 2))
  local p2 = { p1[1] + s2 * dc[1], p1[2] + s2 * dc[2] }
  local aC = math.deg(math.atan2(p2[2], p2[1]))
  while aC < aT do aC = aC + 360 end
  return { aL = aL, aT = aT, aR = aR, aC = aC, corner = c, top = top, rampFoot = foot, chamferFoot = p1, chamferTop = p2 }
end
function L.camPieces()
  local k = L.camNotch()
  local out = { sector(G.NOTCH_R, k.aL, k.aT) }
  -- (the leading wall's piece: 25 degrees of rim up to the chamfer's top,
  -- the chamfer and the wall down to the floor's corner, the ray at aL. It
  -- takes in that much rim so that no seam between pieces is near the
  -- notch: the fence sliding over a seam can catch on the next piece's side,
  -- which the safecracker's gentle feeling stopped at)
  local rin = G.HUB_R
  local a0 = k.aR - 25
  local p = arc(G.R_C, a0, k.aR)
  p[#p + 1] = k.rampFoot
  p[#p + 1] = k.corner
  p[#p + 1] = { rin * math.cos(math.rad(k.aL)), rin * math.sin(math.rad(k.aL)) }
  p[#p + 1] = { rin * math.cos(math.rad(a0)), rin * math.sin(math.rad(a0)) }
  out[#out + 1] = p
  -- (the chamfer's piece: the ray at aT up to the chamfer's foot, the
  -- chamfer, the rim on to aC + 20)
  local a1 = k.aC + 20
  local q = { { rin * math.cos(math.rad(k.aT)), rin * math.sin(math.rad(k.aT)) }, k.chamferFoot }
  for _, pt in ipairs(arc(G.R_C, k.aC, a1)) do q[#q + 1] = pt end
  q[#q + 1] = { rin * math.cos(math.rad(a1)), rin * math.sin(math.rad(a1)) }
  out[#out + 1] = q
  return sectors(G.R_C, a1, a0 + 360, out)
end
-- the cam's whole outline, anticlockwise (for OpenSCAD)
function L.camOutline()
  local k = L.camNotch()
  local pts = {}
  for _, q in ipairs(arc(G.R_C, k.aC, k.aC + 20)) do pts[#pts + 1] = q end
  table.remove(pts)
  for _, q in ipairs(arc(G.R_C, k.aC + 20, k.aR + 360)) do pts[#pts + 1] = q end
  table.remove(pts)                        -- (the wall's top, added next as itself)
  pts[#pts + 1] = k.top
  pts[#pts + 1] = k.rampFoot
  pts[#pts + 1] = k.corner
  for _, q in ipairs(arc(G.NOTCH_R, k.aL, k.aT)) do pts[#pts + 1] = q end
  pts[#pts + 1] = k.chamferFoot
  return pts
end
-- (a polygon's area, signed: positive anticlockwise)
function L.area(p)
  local s = 0
  for i = 1, #p do
    local a, b = p[i], p[i % #p + 1]
    s = s + a[1] * b[2] - b[1] * a[2]
  end
  return s / 2
end

-- ---------------------------------------------------------------------
-- a combination's gates. Wheel 1 is set last turning left with the cam,
-- wheel 3 and wheel 2 pushing it: its pin 3 DELTA ahead of the cam's. Wheel
-- 2, turning right, 2 DELTA behind; wheel 3, turning left, 1 DELTA ahead.
-- Returns each gate's middle in its wheel's own frame, in numbers.
-- ---------------------------------------------------------------------
function L.gates(a, b, c)
  local d = L.DELTA
  return { wrap(L.TOP - (a + 3 * d)), wrap(L.TOP - (b - 2 * d)), wrap(L.TOP - (c + d)) }
end

-- ---------------------------------------------------------------------
-- the model: the dial's place D and each pin's lead over the pin behind it
-- (rel, kept from DELTA to 100 - DELTA: the pins can't pass each other). A
-- wheel turns only when the pin behind it pushes; a turn of any size in one
-- direction is exact.
-- ---------------------------------------------------------------------
function L.new(D, w)                 -- w: each wheel's turn, in numbers (wheel 1, 2, 3)
  local s = { D = D or 0, rel = {} }
  local drv = s.D
  for i = 3, 1, -1 do
    local r = wrap(w[i] - drv)
    if r < L.DELTA then r = L.DELTA elseif r > L.N - L.DELTA then r = L.N - L.DELTA end
    s.rel[i] = r
    drv = drv + r
  end
  return s
end
function L.wheel(s, i)               -- wheel i's turn
  local w = s.D
  for k = 3, i, -1 do w = w + s.rel[k] end
  return w
end
function L.turn(s, dD)               -- the dial turned dD numbers (left +); returns how far each wheel went
  s.D = s.D + dD
  local moved, m = {}, dD
  for i = 3, 1, -1 do
    local r = s.rel[i] - m
    local c = math.max(L.DELTA, math.min(L.N - L.DELTA, r))
    m = c - r                        -- (pushed: the wheel turns as far as the pin behind it went past)
    s.rel[i] = c
    moved[i] = m
  end
  return moved
end
function L.copy(s) return { D = s.D, rel = { s.rel[1], s.rel[2], s.rel[3] } } end
-- each gate's distance from under the rod, in numbers (+: anticlockwise of it)
function L.gateOffsets(s, gates)
  local e = {}
  for i = 1, 3 do e[i] = centred(L.wheel(s, i) + gates[i] - L.TOP) end
  return e
end

-- ---------------------------------------------------------------------
-- how far the fence can fall: its round section, coming straight down at
-- x = 0 from resting on the cam, against each part's pieces as they are
-- turned. In mm, up to the cam's notch's floor.
-- ---------------------------------------------------------------------
local function dist2(px, py, poly)   -- the squared distance from a point to a convex polygon (0 inside)
  local inside, best = true, math.huge
  local n = #poly
  local sgn = L.area(poly) > 0 and 1 or -1
  for i = 1, n do
    local a, b = poly[i], poly[i % n + 1]
    local ex, ey = b[1] - a[1], b[2] - a[2]
    local cr = (ex * (py - a[2]) - ey * (px - a[1])) * sgn
    if cr < 0 then inside = false end
    local t = ((px - a[1]) * ex + (py - a[2]) * ey) / (ex * ex + ey * ey)
    t = math.max(0, math.min(1, t))
    local dx, dy = px - (a[1] + t * ex), py - (a[2] + t * ey)
    best = math.min(best, dx * dx + dy * dy)
  end
  return inside and 0 or best
end
local function hits(pieces, turnDeg, y)
  local c, s = math.cos(math.rad(-turnDeg)), math.sin(math.rad(-turnDeg))
  local px, py = -s * y, c * y                -- (the fence's centre (0, y), in the part's frame)
  local r2 = (G.ROD_D / 2) ^ 2
  for _, p in ipairs(pieces) do if dist2(px, py, p) < r2 - 1e-9 then return true end end
  return false
end
L.hits = hits
function L.fall(pieces, turnDeg, maxDrop)
  maxDrop = maxDrop or 8
  local d = 0
  while d < maxDrop do
    if hits(pieces, turnDeg, G.ROD_Y - (d + 0.01)) then return d end
    d = d + 0.01
  end
  return maxDrop
end
-- the rod's fall with the dial at D and the wheels as s has them (cached pieces)
function L.rodFall(s, gates, wheelPieces, camPieces)
  local d = L.fall(camPieces, L.DEG * s.D, 8)
  for i = 1, 3 do d = math.min(d, L.fall(wheelPieces[i], L.DEG * L.wheel(s, i), d)) end
  return d
end

-- ---------------------------------------------------------------------
-- the contact points: with the cam's notch under the fence, the fence
-- rests on the largest wheel whose gate isn't under it. Rocking the dial,
-- it meets the notch's chamfered walls: the dial's readings there, below
-- and above OPEN_AT. The deeper the fence, the further in it meets them,
-- so a gate coming under the wheel that holds the fence up brings the two
-- together. In numbers, to the nearest 0.0005.
-- ---------------------------------------------------------------------
function L.fenceOnWheels(s, wheelPieces)       -- the fence's fall onto the wheels, mm (the cam left out)
  local d = 8
  for i = 1, 3 do d = math.min(d, L.fall(wheelPieces[i], L.DEG * L.wheel(s, i), d)) end
  return d
end
function L.contacts(s, wheelPieces, camPieces)
  local y = G.ROD_Y - L.fenceOnWheels(s, wheelPieces)
  local function touches(d) return hits(camPieces, L.DEG * (L.OPEN_AT + d), y) end
  local function edge(dir)                     -- (out from the middle in steps of 0.05, then halving to 0.0005)
    local a, b = 0, 0.05
    while b < 10 and not touches(dir * b) do a, b = b, b + 0.05 end
    while b - a > 0.0005 do
      local m = (a + b) / 2
      if touches(dir * m) then b = m else a = m end
    end
    return L.OPEN_AT + dir * b
  end
  local lo, hi = edge(-1), edge(1)
  return lo, hi, hi - lo
end
-- the safecracker's parking: all three wheels left together on x (turning
-- left), and the dial's places for each step of feeling the contacts
L.FEEL_FROM = 4.5                     -- (numbers either side of OPEN_AT: where the hand slows to feel)

-- ---------------------------------------------------------------------
-- dialling: the four moves for a combination, from the dial as it stands.
-- Each { dir = 1 (left) or -1 (right), to = D's target, num, times, say }.
-- "Left four times to a": a comes under the index four times, the last
-- time stopping there; starting on it (within half a number) doesn't count.
-- ---------------------------------------------------------------------
local function goTo(D, dir, num, times)
  local r = wrap(D)
  local d = wrap(dir * (num - r))
  if d < 0.5 then d = d + L.N end
  return D + dir * (d + L.N * (times - 1))
end
L.goTo = goTo
function L.plan(D, a, b, c)
  local m = {}
  m[1] = { dir = 1, num = a, times = 4, say = "left4" }
  m[2] = { dir = -1, num = b, times = 3, say = "right3" }
  m[3] = { dir = 1, num = c, times = 2, say = "left2" }
  for _, s in ipairs(m) do s.to = goTo(D, s.dir, s.num, s.times); D = s.to end
  return m
end
-- (turning right from the last number to where the notch is under the
-- fence; on it already, within half a number either way, is there)
function L.toOpen(D) return D - (wrap(D - L.OPEN_AT + 0.5) - 0.5) end
-- the dial's travel right from the notch arriving to the bolt drawn back:
-- the notch's floor passing under the rod, and the pull (the rod's centre on
-- a circle of the floor's radius plus its own, moved the bolt's travel)
L.PULL = (G.NOTCH_W / 2 + math.deg(math.asin(G.BOLT_TRAVEL / (G.NOTCH_R + G.ROD_D / 2)))) / L.DEG

-- the combination as text
function L.text(a, b, c)
  local function f(x) return (x == math.floor(x)) and string.format("%d", x) or string.format("%.1f", x) end
  return f(a) .. "-" .. f(b) .. "-" .. f(c)
end

-- ---------------------------------------------------------------------
-- parts/lock-geometry.scad: the sizes, and the cam's outline
-- ---------------------------------------------------------------------
function L.writeScad(path)
  local f = assert(io.open(path, "w"))
  f:write("// lock-geometry.scad -- written by lock.lua (lua lock.lua scad): don't edit\n")
  local keys = {}
  for k in pairs(G) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local v = G[k]
    if type(v) == "table" then
      local t = {}
      for i, x in ipairs(v) do t[i] = string.format("%g", x) end
      f:write(string.format("%s = [%s];\n", k, table.concat(t, ", ")))
    else f:write(string.format("%s = %s;\n", k, string.format("%.6g", v))) end
  end
  f:write(string.format("PIN_DELTA = %.6g;   // two pins touching, in numbers\n", L.DELTA))
  f:write(string.format("OPEN_AT = %g;\n", L.OPEN_AT))
  local pts = {}
  for _, p in ipairs(L.camOutline()) do pts[#pts + 1] = string.format("[%.4f, %.4f]", p[1], p[2]) end
  f:write("CAM_OUTLINE = [" .. table.concat(pts, ", ") .. "];\n")
  f:close()
end

-- (run as a program: lua lock.lua scad | gates a b c)
if arg and arg[0] and arg[0]:match("lock%.lua$") then
  local cmd = arg[1]
  if cmd == "scad" then
    local dir = arg[0]:gsub("lock%.lua$", "")
    L.writeScad(dir .. "parts/lock-geometry.scad")
    print("wrote " .. dir .. "parts/lock-geometry.scad")
  elseif cmd == "gates" then
    local g = L.gates(tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]))
    print(string.format("%.4f %.4f %.4f", g[1] * L.DEG, g[2] * L.DEG, g[3] * L.DEG))
  end
end

return L
