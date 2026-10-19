--
-- junctions.lua -- the Domino Half Adder's test bench (see ../FINDINGS.md)
--
-- Each junction the machine is built from, on its own, and then the
-- machine in parts, headless:
--   bpp -f junctions.lua -n 305 (GATE=...) prints one RESULT line: for each
--   line, how many of its dominoes fell (x fell, . stood).
-- GATE: turn (R, DEG), fork (OFF, ANG), merge (OFF, ANG; IN=A|B|AB),
--   inhibit (GX, DELAY: frames the main line starts after the inhibitor),
--   tap (DIR=1 with the wave, -1 against), headon, xor, half (IN=A|B|AB),
--   machine (SW = the inputs set to 1: "", A, B, AB).
-- Common: FR (friction), POCKET (template wall height, cm: 0.16 is the
--   print's), JIT/JITA (random misplacing, cm and degrees), SEED,
--   FRAMES (when to report), DUMP=file (write every pose, for drawing).
-- Run from this folder.
--
local common = require "common"
local HERE = "../"
for _, d in ipairs({ "../", "demo/WyomingWill/BabbagesHall/exhibits/DominoAdder/" }) do
  local f = io.open(d .. "domino-lines.lua", "r"); if f then f:close(); HERE = d; break end
end
local L = dofile(HERE .. "domino-lines.lua")
local W, H, T, SP = L.W, L.H, L.T, L.SP
local MASS = 0.008
local FR = tonumber(os.getenv("FR") or "0.4")
local GATE = os.getenv("GATE") or "turn"
local IN = os.getenv("IN") or "A"
math.randomseed(tonumber(os.getenv("SEED") or "1"))
local P = function(n, d) return tonumber(os.getenv(n) or "") or d end
v.gravity = btVector3(0, -981, 0)
common.setTiming(1/60, 40, 1/2400)

local floor = Cube(600, 2, 600, 0)
floor.pos = btVector3(0, -1, 0); floor.friction = 0.6
v:add(floor)

local lines, order = {}, {}
local function addLine(name, poses)
  local ln = { name = name, d = {} }
  local J, JA = P("JIT", 0), math.rad(P("JITA", 0))
  for _, p in ipairs(poses) do
    local c = Cube(W, H, T, MASS)
    local jx, jz, jh = 0, 0, 0
    if J > 0 then jx, jz = (math.random() * 2 - 1) * J, (math.random() * 2 - 1) * J end
    if JA > 0 then jh = (math.random() * 2 - 1) * JA end
    c.trans = btTransform(btQuaternion(btVector3(0, 1, 0), p.h + jh), btVector3(p.x + jx, H / 2, p.z + jz))
    c.friction = FR; c.restitution = 0
    v:add(c)
    c.body:setActivationState(4)
    ln.d[#ln.d + 1] = { c = c, p = p }
  end
  lines[name] = ln; order[#order + 1] = name
  return ln
end
local function push(name)
  local rev = name:sub(-3) == "rev"
  if rev then name = name:sub(1, -4) end
  local d = rev and lines[name].d[#lines[name].d] or lines[name].d[1]
  local h, w = d.p.h + (rev and math.pi or 0), 4
  d.c.body:setAngularVelocity(btVector3(w * math.cos(h), 0, -w * math.sin(h)))
  d.c.body:setLinearVelocity(btVector3(w * H / 2 * math.sin(h), w * T / 2, w * H / 2 * math.cos(h)))
end

local inputs = {}
if GATE == "turn" then
  addLine("A", (L.line({ x = 0, z = 0, h = 0 }, { { "s", 15 }, { "a", P("R", 8), P("DEG", 90) }, { "s", 15 } })))
  inputs.A = "A"
elseif GATE == "fork" then
  local trunk, E = L.line({ x = 0, z = 0, h = 0 }, { { "s", 20 } })
  addLine("A", trunk)
  local off, ang = P("OFF", 1.4), math.rad(P("ANG", 25))
  local s1 = L.side(E, off); s1.h = s1.h + ang
  local s2 = L.side(E, -off); s2.h = s2.h - ang
  addLine("L", (L.line(s1, { { "s", 25 } })))
  addLine("R", (L.line(s2, { { "s", 25 } })))
  inputs.A = "A"
elseif GATE == "merge" then
  local ang = math.rad(P("ANG", 30))
  local G = { x = 0, z = 40, h = 0 }
  local off = P("OFF", 1.4)
  -- A comes in from the left, B from the right, each ending one SP short of G
  local function feeder(sgn)
    local h = -sgn * ang
    local e = L.side({ x = G.x, z = G.z, h = 0 }, sgn * off)
    local start = { x = e.x - 30 * math.sin(h), z = e.z - 30 * math.cos(h), h = h }
    return (L.line(start, { { "s", 30 - SP } }))
  end
  addLine("A", feeder(1)); addLine("B", feeder(-1))
  addLine("OUT", (L.line(G, { { "s", 25 } })))
  inputs.A, inputs.B = "A", "B"
elseif GATE == "inhibit" then
  -- main line M along +z through the gate at z = 30; the inhibitor I comes
  -- in from -x and its end knocks M's dominoes over sideways
  addLine("M", (L.line({ x = 0, z = 0, h = 0 }, { { "s", 60 } })))
  local gx = P("GX", 3.2)            -- distance of I's end from M's centre line
  local nEnd = P("NEND", 1)          -- how many end dominoes (side by side, along z)
  local gz = P("GZ", 30)
  local nEndRow = nEnd > 1 and 1 or 0
  local stem = {}
  local x0 = -gx - nEndRow * P("STEMGAP", 3.0)
  for k = 11, 0, -1 do stem[#stem + 1] = { x = x0 - k * SP, z = gz, h = math.pi / 2 } end
  addLine("I", stem)
  if nEnd > 1 then
    local poses = {}
    for k = 1, nEnd do
      local dz = (k - (nEnd + 1) / 2) * P("ENDSP", 2.7)
      poses[#poses + 1] = { x = -gx, z = gz + dz, h = math.pi / 2 }
    end
    addLine("Iend", poses)
  end
  inputs.A, inputs.B = "M", "I"
  -- B (the inhibitor) starts early enough to get there first
elseif GATE == "tap" then
  -- a branch off a continuing line, on its left, pointing WITH the wave
  -- (DIR=1, should be taken) or AGAINST it (DIR=-1, should not be)
  local dir = P("DIR", 1)
  addLine("M", (L.line({ x = 0, z = 0, h = 0 }, { { "s", 60 } })))
  local zb = 12 * SP + P("ZOFF", SP / 2)
  local off, ang = P("OFF", 1.4), math.rad(P("ANG", 25))
  -- left of a +z heading is +x (side() convention); forward-left: h = +ang
  local s0 = { x = off, z = zb, h = (dir > 0) and ang or (math.pi - ang) }
  addLine("Br", (L.line(s0, { { "s", 25 } })))
  inputs.A = "M"
elseif GATE == "xor" or GATE == "half" or GATE == "machine" then
  local HA = dofile(HERE .. "domino-layout.lua")(L)
  local ls, ins, X = HA[GATE]({})
  -- switches: SW lists the inputs set to 1 ("AB", "A", "B", ""); an input
  -- at 0 has its two switch dominoes taken out
  if X.switch then
    local SW = os.getenv("SW") or "AB"
    for name, idx in pairs(X.switch) do
      local key = name:sub(1, 1)
      if not SW:find(key) then
        local keep = {}
        for i, p in ipairs(ls[name]) do if i ~= idx[1] and i ~= idx[2] then keep[#keep + 1] = p end end
        ls[name] = keep
      end
    end
    IN = "GO"
  end
  if X.sumRoute then print(string.format("RESULT layout sumRoute=%.1f a3len=%.1f", X.sumRoute, X.a3len)) end
  local names = {}
  for n in pairs(ls) do names[#names + 1] = n end
  table.sort(names)
  for _, n in ipairs(names) do addLine(n, ls[n]) end
  for k, n in pairs(ins) do inputs[k] = n end
  if os.getenv("DUMP") then
    local f = io.open(os.getenv("DUMP"), "w")
    for _, n in ipairs(names) do for _, q in ipairs(ls[n]) do f:write(string.format("%s %.3f %.3f %.4f\n", n, q.x, q.z, q.h)) end end
    f:close()
  end
elseif GATE == "headon" then
  local ln = L.line({ x = 0, z = 0, h = 0 }, { { "s", 60 } })
  addLine("M", ln)
  inputs.A = "M"
  inputs.B = "Mrev"
end

-- the template's pockets round every domino (POCKET = wall height, cm)
if P("POCKET", 0) > 0 then
  local all = {}
  for _, name in ipairs(order) do for _, d in ipairs(lines[name].d) do all[#all + 1] = d.p end end
  local PH = P("POCKET", 0)
  local walls = L.pocketWalls(all)
  for _, w in ipairs(walls) do
    local c = Cube(w.sx, PH, w.sz, 0)
    c.trans = btTransform(btQuaternion(btVector3(0, 1, 0), w.h), btVector3(w.x, PH / 2, w.z))
    c.friction = 0.6
    v:add(c)
  end
  print("RESULT pockets: " .. #walls .. " wall boxes round " .. #all .. " dominoes")
end
local DELAY = P("DELAY", 0)
local pending = {}
for k, name in pairs(inputs) do if IN:find(k) or k == "GO" then
  if k == "A" and DELAY > 0 then pending[#pending + 1] = name else push(name) end
end end

local fell = {}
local NF = P("FRAMES", 300)
v:postSim(function(N)
  if N == DELAY then for _, nm in ipairs(pending) do push(nm) end end
  for _, name in ipairs(order) do
    for i, d in ipairs(lines[name].d) do
      local key = name .. i
      if not fell[key] then
        local up = d.c.body:getCenterOfMassTransform():getBasis():getColumn(1)
        if up.y < math.cos(math.rad(30)) then fell[key] = N end
      end
    end
  end
  if N == NF then
    local parts = {}
    for _, name in ipairs(order) do
      local n, nd = 0, #lines[name].d
      for i = 1, nd do if fell[name .. i] then n = n + 1 end end
      local s = ""
      for i = 1, nd do s = s .. (fell[name .. i] and "x" or ".") end
      parts[#parts + 1] = string.format("%s %d/%d %s", name, n, nd, s)
    end
    if lines.INH and lines.A3 then
      local ni = #lines.INH.d
      -- A3's domino on the inhibitor's row
      local best, bi = 1e9, nil
      for i, d in ipairs(lines.A3.d) do
        local dd = math.abs(d.p.z - lines.INH.d[ni].p.z) + math.abs(d.p.x - lines.INH.d[ni].p.x)
        if dd < best then best, bi = dd, i end
      end
      local tl = {}
      for i = bi - 4, math.min(#lines.A3.d, bi + 8) do tl[#tl + 1] = i .. ":" .. tostring(fell["A3" .. i]) end
      print("RESULT A3 near cut " .. table.concat(tl, " "))
      print(string.format("RESULT timing INH end fell at %s, A3[%d] (its row) at %s, A3[%d] at %s",
        tostring(fell["INH" .. ni]), bi, tostring(fell["A3" .. bi]), bi - 6, tostring(fell["A3" .. (bi - 6)])))
    end
    print("RESULT " .. (os.getenv("TAG") or "") .. " " .. GATE .. " IN=" .. IN .. "  " .. table.concat(parts, " | "))
  end
end)
