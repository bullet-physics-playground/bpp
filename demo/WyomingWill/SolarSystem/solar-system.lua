--
-- The Solar System -- Euler's Cabinet of Curiosities
--
-- The Sun, the eight planets, Pluto, five asteroids (Ceres, Pallas, Juno,
-- Vesta, Hygiea) and twenty-two moons, from 2026 January 1 on, moving as
-- gravity moves them -- worked out here, from where JPL had them that day.
--
--   the orrery    the Sun on its column, the planets, Pluto and the
--                 asteroids round it, on their orbits. Their distances
--                 from the Sun are square-rooted (Mercury 11 cm, the
--                 Earth 18 cm, Neptune 99 cm, Pluto out to 126) so that
--                 all of them fit; their directions, and their heights
--                 above and below the Earth's orbit (the ecliptic), are
--                 true. The bodies are drawn much bigger than they are.
--   the vitrines  along the back, each planet with its moons: the Earth
--                 and the Moon, Mars, Jupiter, Saturn (and its rings),
--                 Uranus (lying on its side), Neptune (Triton going round
--                 backwards), Pluto and Charon (going round each other).
--                 In each, distances from the planet are square-rooted
--                 too; directions true. North -- the Earth's orbit's north
--                 -- is up everywhere.
--   the date      in front.
--
-- The time goes 5 days a second to start with (keys 1-5: a quarter of a
-- day, 1, 5, 25 or 100 days a second).
--
-- PHYSICS, and the checks (see solar-engine.lua and README.md):
--   * everything pulls everything (Newton), the Sun's pull with Einstein's
--     correction, the Earth's flattening on the Moon, each giant planet's
--     flattening on its moons, the Sun's tides on them;
--   * the Sun, the planets, the Moon, Pluto and the asteroids stepped by
--     Bulirsch-Stoer (tenth order) a day at a time; the moons about their
--     planets by Wisdom and Holman's mapping, sixteen steps to the
--     innermost one's orbit;
--   * every year the console compares the planets and the Moon with JPL's
--     DE421 ephemeris (the planets come within a few kilometres in ten
--     years, the Moon within 40), and with Horizons for the moons and
--     asteroids, when solar-data.lua has its data;
--   * a Mercury without Einstein, alongside: it falls behind, 1800 km in
--     ten years; Mercury's perihelion turned by Einstein, against 43
--     seconds of arc a century; the Laplace resonance of Io, Europa and
--     Ganymede; how close Neptune and Pluto come (never closer than 17 AU,
--     though their orbits cross); the energy and angular momentum.
--
-- Keys
--   1 2 3 4 5   a quarter of a day, 1, 5, 25, 100 days a second
--   R           back to 2026 January 1
--
-- Units: centimetres in the room; AU, days and the ICRF inside.
-- Headless testing: SS_RATE (days a second), SS_YEARS (years before it
-- starts again; at most 25: DE421 ends in 2053).
--

local common = require "common"

local DIR = ""
for _, d in ipairs({ "", "demo/WyomingWill/SolarSystem/" }) do
  local f = io.open(d .. "solar-data.lua", "r")
  if f then f:close(); DIR = d; break end
end
local D = dofile(DIR .. "solar-data.lua")
local makeEngine = dofile(DIR .. "solar-engine.lua")
local MESH = DIR .. "solar-meshes/"

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local RATES = { 0.25, 1, 5, 25, 100 }
v:addParam("days", envnum("SS_RATE", 5), 0.05, 200, 0.05, "days a second (keys 1-5)")
local YEARS = math.min(25, envnum("SS_YEARS", 25))

v.animationPeriod = 16
common.setTiming(1 / 60, 0, 1 / 60)
v.gravity = btVector3(0, 0, 0)

local sqrt, sin, cos, abs, floor, pi = math.sqrt, math.sin, math.cos, math.abs, math.floor, math.pi
local AUKM = D.AU_KM
local Q0 = btQuaternion(0, 0, 0, 1)
local HIDE = btTransform(Q0, btVector3(0, -500, 0))
local KEYS = {}
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end
local function ball(r, col)
  local s = Sphere(r, 0)
  s.col = col
  s.collides = false
  v:add(s)
  return s
end
local function mesh(file, col, x, y, z)
  local m = Mesh(MESH .. file, 0, false)
  m.col = col
  m.collides = false
  m.trans = btTransform(Q0, btVector3(x or 0, y or 0, z or 0))
  v:add(m)
  return m
end
local function column(x, y0, y1, z, r, col)
  local c = Cylinder(r, y1 - y0, 0)
  c.trans = btTransform(btQuaternion(btVector3(1, 0, 0), pi / 2), btVector3(x, (y0 + y1) / 2, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ICRF -> the room's axes: x the ecliptic's x (toward the March equinox),
-- y the ecliptic's north (up), z minus the ecliptic's y (toward you)
local CE, SE = cos(D.OBLIQUITY), sin(D.OBLIQUITY)
local function room(x, y, z)
  return x, -SE * y + CE * z, -(CE * y + SE * z)
end

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(400, 3, 300, 0, TABLE_Y - 1.5, 0, "#2b2522")
for _, x in ipairs({ -196, 196 }) do
  for _, z in ipairs({ -146, 146 }) do block(4, 72, 4, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor_ = Plane(0, 1, 0, TABLE_Y - 75, 500)
floor_.col = "#3b3f45"
v:add(floor_)

-- ---------------------------------------------------------------------
-- the orrery
-- ---------------------------------------------------------------------
local OC = { 0, TABLE_Y + 45, 18 }
local S = D.ORRERY_S
local sun = ball(3.0, "#ffd35a")
sun.trans = btTransform(Q0, btVector3(OC[1], OC[2], OC[3]))
column(OC[1], TABLE_Y, OC[2] - 3, OC[3], 0.8, "#b08d3c")
block(8, 1.2, 8, OC[1], TABLE_Y + 0.6, OC[3], "#b08d3c")
KEYS[objectKey(sun)] = { kind = "sun" }
local ORB = {}           -- the orrery's bodies: { i (main index), obj }
local function orreryRadius(rkm)
  return math.max(0.35, 0.33 * sqrt(rkm / 1000))
end
for i, b in ipairs(D.main) do
  if b.name ~= "Sun" and b.name ~= "Moon" then
    local o = ball(b.asteroid and 0.35 or orreryRadius(b.r * AUKM), b.col)
    ORB[#ORB + 1] = { i = i, obj = o, name = b.name, asteroid = b.asteroid }
    KEYS[objectKey(o)] = { kind = "orrery", i = i, name = b.name }
    local m = mesh("orbit-" .. b.name:lower() .. ".obj", b.asteroid and "#55595f" or "#6b6f76", OC[1], OC[2], OC[3])
    KEYS[objectKey(m)] = { kind = "orbit", name = b.name }
  end
end

-- ---------------------------------------------------------------------
-- the vitrines
-- ---------------------------------------------------------------------
local VR = D.VITRINE_R
local VIT = {}
local VNAMES = { "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto" }
local PCOL = {}
for _, b in ipairs(D.main) do PCOL[b.name] = b.col end
local RADIUS = { Earth = 6371, Mars = 3389.5, Jupiter = 69911, Saturn = 58232, Uranus = 25362, Neptune = 24622, Pluto = 1188.3 }
local SYSBY = {}
for si, s in ipairs(D.systems) do SYSBY[s.planet] = si end
for k, name in ipairs(VNAMES) do
  local cx, cy, cz = -168 + 56 * (k - 1), TABLE_Y + 92, -122
  local reach = (name == "Earth") and D.EARTH_REACH or D.systems[SYSBY[name]].reach
  local V = { name = name, c = { cx, cy, cz }, reach = reach, si = SYSBY[name], bodies = {} }
  column(cx, TABLE_Y, cy - VR - 4, cz, 1.0, "#b08d3c")
  block(10, 1.2, 10, cx, TABLE_Y + 0.6, cz, "#b08d3c")
  local nm = mesh("name-" .. name:lower() .. ".obj", "#c9a646", cx, cy - VR - 8, cz + 1.2)
  -- the planet (Pluto's vitrine: Pluto and Charon about their barycentre)
  local function size(rkm) return math.max(0.5, VR * sqrt(rkm / AUKM / reach)) end
  mesh("hoop.obj", "#8a6d2c", cx, cy, cz)
  V.planet = ball(size(RADIUS[name]), PCOL[name])
  KEYS[objectKey(V.planet)] = { kind = "vplanet", v = V }
  if name ~= "Pluto" then V.planet.trans = btTransform(Q0, btVector3(cx, cy, cz)) end
  if name == "Earth" then
    V.bodies[1] = { obj = ball(size(1737.4), "#c9c9c9"), name = "the Moon" }
  else
    for mk, m in ipairs(D.systems[V.si].moons) do
      V.bodies[mk] = { obj = ball(size(m.r * AUKM), "#cfc8bd"), name = m.name, k = mk }
    end
  end
  for _, b in ipairs(V.bodies) do KEYS[objectKey(b.obj)] = { kind = "moon", v = V, b = b } end
  if name == "Saturn" then
    mesh("saturn-ring-c.obj", "#6e6553", cx, cy, cz)
    mesh("saturn-ring-b.obj", "#d8c99a", cx, cy, cz)
    mesh("saturn-ring-a.obj", "#b3a57d", cx, cy, cz)
  end
  VIT[k] = V
end

-- ---------------------------------------------------------------------
-- the date: YYYY-MM-DD, above the vitrines
-- ---------------------------------------------------------------------
local DATE_Y, DATE_Z, DATE_W = TABLE_Y + 128, -124, 2.7
block(34, 7, 0.6, 0, DATE_Y + 2, DATE_Z - 0.6, "#151515")
local DIGITS = {}
local SLOTS = { 1, 2, 3, 4, 6, 7, 9, 10 }
for _, p in ipairs({ 5, 8 }) do mesh("digit-dash.obj", "#e8d38a", (p - 5.5) * DATE_W, DATE_Y, DATE_Z) end
for _, p in ipairs(SLOTS) do
  DIGITS[p] = {}
  for dgt = 0, 9 do
    local m = mesh("digit-" .. dgt .. ".obj", "#e8d38a")
    m.trans = HIDE
    DIGITS[p][dgt] = m
  end
end
local shownDate = {}
local function showDate(str)
  for _, p in ipairs(SLOTS) do
    local c = tonumber(str:sub(p, p))
    if shownDate[p] ~= c then
      if shownDate[p] then DIGITS[p][shownDate[p]].trans = HIDE end
      DIGITS[p][c].trans = btTransform(Q0, btVector3((p - 5.5) * DATE_W, DATE_Y, DATE_Z))
      shownDate[p] = c
    end
  end
end
-- Julian date -> calendar (Meeus)
local function calendar(jd)
  local z = floor(jd + 0.5)
  local f = jd + 0.5 - z
  local a = z
  if z >= 2299161 then
    local al = floor((z - 1867216.25) / 36524.25)
    a = z + 1 + al - floor(al / 4)
  end
  local b = a + 1524
  local c = floor((b - 122.1) / 365.25)
  local d = floor(365.25 * c)
  local e = floor((b - d) / 30.6001)
  local day = b - d - floor(30.6001 * e) + f
  local month = (e < 14) and e - 1 or e - 13
  local year = (month > 2) and c - 4716 or c - 4715
  return year, month, floor(day)
end
local function dateStr(jd)
  local y, m, d = calendar(jd)
  return string.format("%04d-%02d-%02d", y, m, d)
end

-- ---------------------------------------------------------------------
-- the engine, and the checks
-- ---------------------------------------------------------------------
local E, t, nextCheck, nextH, stats
local iSun, iEarth, iMoon = 0, 0, 0
local function start()
  E = makeEngine(D)
  iSun, iEarth, iMoon = E.IDX.Sun, E.IDX.Earth, E.IDX.Moon
  t = 0
  nextCheck, nextH = 1, 1
  local E0, L0 = E.invariants()
  stats = { E0 = E0, L0 = L0, lapN = 0, lapS = 0, lapSS = 0, npMin = 1e9,
            bin = 0, binS = 0, binN = 0, lastBin = nil, ups = {}, lapLo = 1e9, lapHi = -1e9 }
  print(string.format("\n--- the solar system, from %s (again every %d years) ---", dateStr(D.JD0), YEARS))
  print("  where it all starts:")
  for _, s in ipairs(D.sources) do print("    " .. s) end
  print(string.format("  the Sun, %d planets and Pluto, the Moon, %d asteroids: Bulirsch-Stoer, %g day steps; Einstein's correction" ..
                      "\n  to the Sun's pull; the Earth's flattening on the Moon", 8, 5, E.H))
  local hs = {}
  for _, Sy in ipairs(E.SYS) do hs[#hs + 1] = string.format("%s %.3f", Sy.planet, Sy.h) end
  print("  the moons: Wisdom-Holman, steps (days): " .. table.concat(hs, ", "))
end

-- a moon's mean longitude about its planet, in the planet's equator
local function meanLongitude(Sy, k)
  local m = Sy.moons[k]
  local x, y, z = E.moonPos(Sy, k, t)
  -- its velocity: Kepler from the last step too (by a tiny difference)
  local dt = 1e-4
  local x2, y2, z2 = E.moonPos(Sy, k, t + dt)
  local vx, vy, vz = (x2 - x) / dt, (y2 - y) / dt, (z2 - z) / dt
  local px, py, pz = Sy.px, Sy.py, Sy.pz
  -- axes in the equator
  local e1x, e1y, e1z = -py, px, 0
  local n1 = sqrt(e1x * e1x + e1y * e1y)
  e1x, e1y = e1x / n1, e1y / n1
  local e2x, e2y, e2z = py * e1z - pz * e1y, pz * e1x - px * e1z, px * e1y - py * e1x
  local theta = math.atan2(x * e2x + y * e2y + z * e2z, x * e1x + y * e1y + z * e1z)
  -- its orbit: eccentricity vector, true and mean anomaly
  local mu = m.mu
  local hx, hy, hz = y * vz - z * vy, z * vx - x * vz, x * vy - y * vx
  local r = sqrt(x * x + y * y + z * z)
  local ex = (vy * hz - vz * hy) / mu - x / r
  local ey = (vz * hx - vx * hz) / mu - y / r
  local ez = (vx * hy - vy * hx) / mu - z / r
  local e = sqrt(ex * ex + ey * ey + ez * ez)
  local hn = sqrt(hx * hx + hy * hy + hz * hz)
  local cx, cy, cz = ey * z - ez * y, ez * x - ex * z, ex * y - ey * x
  local nu = math.atan2((cx * hx + cy * hy + cz * hz) / hn, ex * x + ey * y + ez * z)
  local Ea = 2 * math.atan(sqrt((1 - e) / (1 + e)) * math.tan(nu / 2))
  local M = Ea - e * sin(Ea)
  return theta - nu + M
end
local function wrap(a) return (a + pi) % (2 * pi) - pi end

local function km(d) return d * AUKM end
local function checks()
  -- DE421, every year
  local c = D.checks[nextCheck]
  if c and D.JD0 + t >= c.jd - 1e-9 and c.jd - D.JD0 <= YEARS * 365.25 + 1 then
    nextCheck = nextCheck + 1
    E.advance(c.jd - D.JD0)
    local sx, sy, sz = E.mainPos(iSun, E.t)
    local ex, ey, ez = E.mainPos(iEarth, E.t)
    local parts = {}
    for _, n in ipairs({ "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto" }) do
      local x, y, z = E.mainPos(E.IDX[n], E.t)
      local r = c[n]
      parts[#parts + 1] = string.format("%s %.0f", n, km(sqrt((x - sx - r[1]) ^ 2 + (y - sy - r[2]) ^ 2 + (z - sz - r[3]) ^ 2)))
    end
    local mx, my, mz = E.mainPos(iMoon, E.t)
    local r = c.Moon
    local dMoon = km(sqrt((mx - ex - r[1]) ^ 2 + (my - ey - r[2]) ^ 2 + (mz - ez - r[3]) ^ 2))
    local nx, ny, nz = E.mainPos(E.iNewtonMercury, E.t)
    r = c.Mercury
    local dNewton = km(sqrt((nx - sx - r[1]) ^ 2 + (ny - sy - r[2]) ^ 2 + (nz - sz - r[3]) ^ 2))
    local En, Ln = E.invariants()
    local rate, n = E.mercGR.advance(E.t)
    print(string.format("  %s  against JPL's DE421, km off, from the Sun: %s;\n              the Moon, from the Earth: %.0f km" ..
                        "\n              a Mercury without Einstein's correction: %.0f km off" ..
                        "\n              energy steady to %.1e, angular momentum to %.1e (Newton's; Einstein's correction is" ..
                        " a few parts in 1e8)", c.date, table.concat(parts, ", "), dMoon, dNewton,
                        (En - stats.E0) / abs(stats.E0), (Ln - stats.L0) / stats.L0))
    if rate then
      print(string.format("              Mercury's perihelion turned by Einstein: %.3f\" a century, over %d orbits" ..
                          " (theory, 6 pi G M / (c^2 a (1 - e^2)) an orbit: %.3f\")", rate * 206264.806 * 36525, n,
                          E.mercGR.theory * 206264.806 * 36525))
    end
    if stats.lapN > 1 then
      local m = stats.lapS / stats.lapN
      print(string.format("              Io, Europa, Ganymede: L_I - 3 L_E + 2 L_G (their mean longitudes) averaged %.2f degrees" ..
                          " over the year,\n                spread %.2f (Laplace's resonance holds it at 180)", m,
                          sqrt(math.max(0, stats.lapSS / stats.lapN - m * m))))
      stats.lapN, stats.lapS, stats.lapSS = 0, 0, 0
      local u = stats.ups
      if #u >= 2 then
        print(string.format("                it librates about 180, between %.2f and %.2f so far: a period of %.0f days over %d" ..
                            " (the theory, and Io's\n                and its partners' observed motions: about 2070 days)",
                            stats.lapLo, stats.lapHi, (u[#u] - u[1]) / (#u - 1), #u - 1))
      end
    end
    local P = function(n)
      local x, y, z = E.mainPos(E.IDX[n], E.t)
      local vx, vy, vz = select(4, E.mainState(E.IDX[n]))
      local svx, svy, svz = select(4, E.mainState(iSun))
      local r = sqrt((x - sx) ^ 2 + (y - sy) ^ 2 + (z - sz) ^ 2)
      local a = 1 / (2 / r - ((vx - svx) ^ 2 + (vy - svy) ^ 2 + (vz - svz) ^ 2) / (E.GM[iSun] + E.GM[E.IDX[n]]))
      return a ^ 1.5
    end
    print(string.format("              Neptune and Pluto: closest so far %.2f AU; Pluto's year now %.3f of Neptune's" ..
                        " (their orbits cross,\n                but the 3:2 resonance keeps them over 17 AU apart)", stats.npMin,
                        P("Pluto") / P("Neptune")))
  end
  -- Horizons
  local h = D.hchecks[nextH]
  if h and D.JD0 + t >= h.jd - 1e-9 then
    nextH = nextH + 1
    E.advance(h.jd - D.JD0)
    local parts = {}
    for _, Sy in ipairs(E.SYS) do
      for k, m in ipairs(Sy.moons) do
        local r = h[m.name]
        if r then
          local x, y, z = E.moonPos(Sy, k, E.t)
          parts[#parts + 1] = string.format("%s %.0f", m.name, km(sqrt((x - r[1]) ^ 2 + (y - r[2]) ^ 2 + (z - r[3]) ^ 2)))
        end
      end
    end
    for _, b in ipairs(D.main) do
      local r = h[b.name]
      if r then
        local x, y, z = E.mainPos(E.IDX[b.name], E.t)
        parts[#parts + 1] = string.format("%s %.0f", b.name, km(sqrt((x - r[1]) ^ 2 + (y - r[2]) ^ 2 + (z - r[3]) ^ 2)))
      end
    end
    if #parts > 0 then print(string.format("  %s  against Horizons, km off: %s", dateStr(h.jd), table.concat(parts, ", "))) end
  end
end

-- ---------------------------------------------------------------------
-- drawing
-- ---------------------------------------------------------------------
local function at(obj, x, y, z) obj.trans = btTransform(Q0, btVector3(x, y, z)) end
local function show()
  local sx, sy, sz = E.mainPos(iSun, t)
  for _, o in ipairs(ORB) do
    local x, y, z = E.mainPos(o.i, t)
    local X, Y, Z = room(x - sx, y - sy, z - sz)
    local r = sqrt(X * X + Y * Y + Z * Z)
    local f = S * sqrt(r) / r
    at(o.obj, OC[1] + X * f, OC[2] + Y * f, OC[3] + Z * f)
  end
  for _, V in ipairs(VIT) do
    local cx, cy, cz = V.c[1], V.c[2], V.c[3]
    local function put(obj, x, y, z)
      local X, Y, Z = room(x, y, z)
      local r = sqrt(X * X + Y * Y + Z * Z)
      if r <= 0 then at(obj, cx, cy, cz); return end
      local f = VR * sqrt(r / V.reach) / r
      at(obj, cx + X * f, cy + Y * f, cz + Z * f)
    end
    if V.name == "Earth" then
      local ex, ey, ez = E.mainPos(iEarth, t)
      local mx, my, mz = E.mainPos(iMoon, t)
      put(V.bodies[1].obj, mx - ex, my - ey, mz - ez)
    else
      local Sy = E.SYS[V.si]
      if V.name == "Pluto" then
        local x, y, z = E.moonPos(Sy, 1, t)
        local m = Sy.moons[1]
        local fc, fp = Sy.gmp / Sy.gmsys, m.gm / Sy.gmsys
        put(V.bodies[1].obj, x * fc, y * fc, z * fc)
        put(V.planet, -x * fp, -y * fp, -z * fp)
      else
        for k, b in ipairs(V.bodies) do
          local x, y, z = E.moonPos(Sy, k, t)
          put(b.obj, x, y, z)
        end
      end
    end
  end
  showDate(dateStr(D.JD0 + t))
end

v:preSim(function(N_)
  local dt = v:getParam("days") / 60
  t = t + dt
  E.advance(t)
  -- the Laplace resonance, Neptune and Pluto
  local J = E.SYS[SYSBY.Jupiter]
  local lap = math.deg(wrap(meanLongitude(J, 1) - 3 * meanLongitude(J, 2) + 2 * meanLongitude(J, 3))) % 360
  stats.lapN, stats.lapS, stats.lapSS = stats.lapN + 1, stats.lapS + lap, stats.lapSS + lap * lap
  -- its slow libration: 20-day means, and when they cross 180 going up
  local bin = floor(t / 20)
  if bin ~= stats.bin then
    if stats.binN > 0 then
      local m = stats.binS / stats.binN
      local tc = (stats.bin + 0.5) * 20
      stats.lapLo, stats.lapHi = math.min(stats.lapLo, m), math.max(stats.lapHi, m)
      if stats.lastBin and stats.lastBin.m < 180 and m >= 180 then
        stats.ups[#stats.ups + 1] = stats.lastBin.t + (tc - stats.lastBin.t) * (180 - stats.lastBin.m) / (m - stats.lastBin.m)
      end
      stats.lastBin = { t = tc, m = m }
    end
    stats.bin, stats.binS, stats.binN = bin, 0, 0
  end
  stats.binS, stats.binN = stats.binS + lap, stats.binN + 1
  local ax, ay, az = E.mainPos(E.IDX.Neptune, t)
  local bx, by, bz = E.mainPos(E.IDX.Pluto, t)
  stats.npMin = math.min(stats.npMin, sqrt((ax - bx) ^ 2 + (ay - by) ^ 2 + (az - bz) ^ 2))
  checks()
end)
v:postSim(function(N_)
  show()
  if t >= YEARS * 365.25 then start(); show() end
end)

-- ---------------------------------------------------------------------
-- keys, help, hovering
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 125, 255), btVector3(0, 60, -25))
for k, r in ipairs(RATES) do
  v:addShortcut(tostring(k), function(N_) v:addParam("days", r, 0.05, 200, 0.05, "days a second (keys 1-5)") end)
end
v:addShortcut("R", function(N_) start(); show() end)
v:setHelpText(table.concat({
  "The solar system (Euler's Cabinet of Curiosities)",
  "",
  "The Sun, the planets, Pluto, five asteroids and 22 moons,",
  "moved by gravity from where JPL had them on 2026-01-01.",
  "The orrery: distances from the Sun square-rooted, so all",
  "fit. Behind: each planet's moons, square-rooted the same.",
  "",
  "1-5  a quarter of a day, 1, 5, 25, 100 days a second",
  "R    back to 2026-01-01",
  "",
  "Slider: days (a second).",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local k = KEYS[objectKey(obj)]
    if not k then return nil end
    local sx, sy, sz = E.mainPos(iSun, t)
    if k.kind == "sun" then
      return string.format("The Sun\n%s, going %g days a second", dateStr(D.JD0 + t), v:getParam("days"))
    elseif k.kind == "orrery" then
      local bx, by, bz = E.mainPos(k.i, t)
      local ex, ey, ez = E.mainPos(iEarth, t)
      return string.format("%s\n%.3f AU from the Sun, %.3f AU from the Earth", k.name,
                           sqrt((bx - sx) ^ 2 + (by - sy) ^ 2 + (bz - sz) ^ 2), sqrt((bx - ex) ^ 2 + (by - ey) ^ 2 + (bz - ez) ^ 2))
    elseif k.kind == "orbit" then
      return k.name .. "'s orbit (as it is in 2026; the orrery's distances are square-rooted)"
    elseif k.kind == "vplanet" then
      return k.v.name == "Earth" and "The Earth" or k.v.name
    elseif k.kind == "moon" then
      local V, b = k.v, k.b
      if V.name == "Earth" then
        local ex, ey, ez = E.mainPos(iEarth, t)
        local mx, my, mz = E.mainPos(iMoon, t)
        return string.format("The Moon\n%.0f km from the Earth", km(sqrt((mx - ex) ^ 2 + (my - ey) ^ 2 + (mz - ez) ^ 2)))
      end
      local Sy = E.SYS[V.si]
      local mx, my, mz = E.moonPos(Sy, b.k, t)
      return string.format("%s\n%.0f km from %s (%s)", b.name, km(sqrt(mx * mx + my * my + mz * mz)), V.name,
                           Sy.moons[b.k].source == "Horizons" and "JPL Horizons' start" or "start: " .. Sy.moons[b.k].source)
    end
  end)
end

start()
show()
