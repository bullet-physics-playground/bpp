--
-- The Solar System -- Euler's Cabinet of Curiosities
--
-- The Sun, the eight planets, Pluto, five asteroids (Ceres, Pallas, Juno,
-- Vesta, Hygiea) and twenty-one moons, from 2026 January 1 on, moving as
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
-- Every body wears a map of its surface and turns as it does, by the
-- IAU's models of each one's pole and turning (solar-rotation.lua):
-- the Moon and nearly all the moons keeping one face to their planets,
-- Mercury turning three times in two of its years. Rest the mouse on one
-- for its size, its turning and day, its tilt, its distances and year.
--
-- The time goes 5 days a second to start with (keys 1-5: a quarter of a
-- day, 1, 5, 25 or 100 days a second; slow down to watch them turn).
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
local ROT = dofile(DIR .. "solar-rotation.lua")
local MESH = DIR .. "solar-meshes/"
local here = cabinetPath or function(p) return p end      -- (in the hall, found from there)

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local RATES = { 0.25, 1, 5, 25, 100 }
v:addParam("days", envnum("SS_RATE", 5), 0.05, 200, 0.05, "days a second (keys 1-5)")
local YEARS = math.min(25, envnum("SS_YEARS", 25))

v.animationPeriod = 16
common.setTiming(1 / 60, 0, 1 / 60)
local function applyTiming() common.setTiming(1 / 60, 0, 1 / 60) end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
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
  s.collides = true          -- (for the mouse: bpp's hover only finds what collides; nothing here moves under physics)
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
-- each body wears a map of its surface (make-textures.py), and is turned
-- as it turns: its pole and prime meridian from the IAU's rotation models
-- (solar-rotation.lua). bpp wraps a map round a sphere with its longitude
-- 0 on the sphere's +x, 90 east on -z, and north on +y.
-- ---------------------------------------------------------------------
local function wear(obj, name)
  if ROT.models[name] then
    obj.col = "#ffffff"
    obj.tex = here(MESH .. "tex-" .. name:lower() .. ".jpg")
  end
end
local QC, QJD = {}, nil          -- (each body's turn, worked out once a frame)
local function turned(name, jd)
  if not name or not ROT.models[name] then return Q0 end
  if QJD ~= jd then QC, QJD = {}, jd end
  local q = QC[name]
  if q then return q end
  local x, y, p = ROT.rotation(name, jd)
  -- the sphere's axes in the room: +x the prime meridian, +y the pole, +z 90 west
  local a = { room(x[1], x[2], x[3]) }
  local b = { room(p[1], p[2], p[3]) }
  local c = { room(-y[1], -y[2], -y[3]) }
  local m00, m01, m02, m10, m11, m12, m20, m21, m22 = a[1], b[1], c[1], a[2], b[2], c[2], a[3], b[3], c[3]
  local tr = m00 + m11 + m22
  local qx, qy, qz, qw
  if tr > 0 then
    local s = sqrt(tr + 1) * 2
    qw, qx, qy, qz = 0.25 * s, (m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s
  elseif m00 > m11 and m00 > m22 then
    local s = sqrt(1 + m00 - m11 - m22) * 2
    qw, qx, qy, qz = (m21 - m12) / s, 0.25 * s, (m01 + m10) / s, (m02 + m20) / s
  elseif m11 > m22 then
    local s = sqrt(1 + m11 - m00 - m22) * 2
    qw, qx, qy, qz = (m02 - m20) / s, (m01 + m10) / s, 0.25 * s, (m12 + m21) / s
  else
    local s = sqrt(1 + m22 - m00 - m11) * 2
    qw, qx, qy, qz = (m10 - m01) / s, (m02 + m20) / s, (m12 + m21) / s, 0.25 * s
  end
  q = btQuaternion(qx, qy, qz, qw)
  QC[name] = q
  return q
end
-- where a direction (ICRF) points on a body: its latitude and east longitude, degrees
local function onBody(name, jd, ux, uy, uz)
  local x, y, p = ROT.rotation(name, jd)
  local n = sqrt(ux * ux + uy * uy + uz * uz)
  ux, uy, uz = ux / n, uy / n, uz / n
  return math.deg(math.asin(ux * p[1] + uy * p[2] + uz * p[3])),
         math.deg(math.atan2(ux * y[1] + uy * y[2] + uz * y[3], ux * x[1] + uy * x[2] + uz * x[3]))
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
wear(sun, "Sun")
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
    wear(o, b.name)
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
  wear(V.planet, name)
  KEYS[objectKey(V.planet)] = { kind = "vplanet", v = V }
  if name ~= "Pluto" then V.planet.trans = btTransform(Q0, btVector3(cx, cy, cz)) end
  if name == "Earth" then
    V.bodies[1] = { obj = ball(size(1737.4), "#c9c9c9"), name = "the Moon", rot = "Moon" }
  else
    for mk, m in ipairs(D.systems[V.si].moons) do
      V.bodies[mk] = { obj = ball(size(m.r * AUKM), "#cfc8bd"), name = m.name, k = mk, rot = m.name }
    end
  end
  for _, b in ipairs(V.bodies) do KEYS[objectKey(b.obj)] = { kind = "moon", v = V, b = b }; wear(b.obj, b.rot) end
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
  holdStart()
  E = makeEngine(D)
  iSun, iEarth, iMoon = E.IDX.Sun, E.IDX.Earth, E.IDX.Moon
  t = 0
  nextCheck, nextH = 1, 1
  local E0, L0 = E.invariants()
  stats = { E0 = E0, L0 = L0, lapN = 0, lapS = 0, lapSS = 0, npMin = 1e9,
            bin = 0, binS = 0, binN = 0, bins = {}, lapLo = 1e9, lapHi = -1e9,
            lib = { 1e9, -1e9, 1e9, -1e9 }, merc = {}, mr = {} }
  print(string.format("\n--- the solar system, from %s (again every %d years) ---", dateStr(D.JD0), YEARS))
  print("  where it all starts:")
  for _, s in ipairs(D.sources) do print("    " .. s) end
  print(string.format("  the Sun, %d planets and Pluto, the Moon, %d asteroids: Bulirsch-Stoer, %g day steps; Einstein's correction" ..
                      "\n  to the Sun's pull; the Earth's flattening on the Moon", 8, 5, E.H))
  local hs = {}
  for _, Sy in ipairs(E.SYS) do hs[#hs + 1] = string.format("%s %.3f", Sy.planet, Sy.h) end
  print("  the moons: Wisdom-Holman, steps (days): " .. table.concat(hs, ", "))
  -- the bodies' turning (the IAU's models), checked: where the Sun is
  -- overhead on the Earth at the start
  local sx, sy, sz = E.mainPos(iSun, 0)
  local ex, ey, ez = E.mainPos(iEarth, 0)
  local la, lo = onBody("Earth", D.JD0, sx - ex, sy - ey, sz - ez)
  print(string.format("  each body turns as the IAU's models have it (pole and prime meridian; see solar-rotation.lua)." ..
                      "\n  the Earth: on %s at 0h (TDB) the Sun is overhead at %.2f %s, %.2f %s (the IERS's Earth, its turning as" ..
                      "\n    measured, through Skyfield: 23.02 S, 178.87 W; the IAU's simpler model is within a tenth of a degree)",
                      dateStr(D.JD0), abs(la), la < 0 and "S" or "N", abs(lo), lo < 0 and "W" or "E"))
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
      if stats.lapHi > stats.lapLo then
        print(string.format("                its 20-day means so far: %.2f to %.2f (Io's free libration about 180 is 0.07 degrees;" ..
                            " the rest is\n                the moons' other slow wobbles)", stats.lapLo, stats.lapHi))
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
    local L = stats.lib
    print(string.format("              the Moon's face: the Earth overhead at %.1f %s to %.1f %s, %.1f %s to %.1f %s on it" ..
                        "\n                (the librations, which let us see 59%% of it: up to 7.9 degrees east and west, and" ..
                        " 6.7 to 6.8\n                north and south, the tilt of its equator to its orbit)", abs(L[1]), L[1] < 0 and "W" or "E", abs(L[2]), L[2] < 0 and "W" or "E",
                        abs(L[3]), L[3] < 0 and "S" or "N", abs(L[4]), L[4] < 0 and "S" or "N"))
    stats.lib = { 1e9, -1e9, 1e9, -1e9 }
    if #stats.merc > 0 then
      local ls = {}
      for _, lo in ipairs(stats.merc) do ls[#ls + 1] = string.format("%.1f", lo) end
      print("              Mercury at perihelion, the Sun overhead at longitude " .. table.concat(ls, ", ") ..
            "\n                (it turns 3 times in 2 of its years: at each perihelion one of its two hot poles," ..
            " at 0 or 180, faces the Sun)")
      stats.merc = {}
    end
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
local function at(obj, x, y, z, q) obj.trans = btTransform(q or Q0, btVector3(x, y, z)) end
local function show()
  local jd = D.JD0 + t
  local sx, sy, sz = E.mainPos(iSun, t)
  at(sun, OC[1], OC[2], OC[3], turned("Sun", jd))
  for _, o in ipairs(ORB) do
    local x, y, z = E.mainPos(o.i, t)
    local X, Y, Z = room(x - sx, y - sy, z - sz)
    local r = sqrt(X * X + Y * Y + Z * Z)
    local f = S * sqrt(r) / r
    at(o.obj, OC[1] + X * f, OC[2] + Y * f, OC[3] + Z * f, turned(o.name, jd))
  end
  for _, V in ipairs(VIT) do
    local cx, cy, cz = V.c[1], V.c[2], V.c[3]
    local function put(obj, x, y, z, q)
      local X, Y, Z = room(x, y, z)
      local r = sqrt(X * X + Y * Y + Z * Z)
      if r <= 0 then at(obj, cx, cy, cz, q); return end
      local f = VR * sqrt(r / V.reach) / r
      at(obj, cx + X * f, cy + Y * f, cz + Z * f, q)
    end
    if V.name == "Earth" then
      local ex, ey, ez = E.mainPos(iEarth, t)
      local mx, my, mz = E.mainPos(iMoon, t)
      put(V.bodies[1].obj, mx - ex, my - ey, mz - ez, turned("Moon", jd))
      at(V.planet, cx, cy, cz, turned("Earth", jd))
    else
      local Sy = E.SYS[V.si]
      if V.name == "Pluto" then
        local x, y, z = E.moonPos(Sy, 1, t)
        local m = Sy.moons[1]
        local fc, fp = Sy.gmp / Sy.gmsys, m.gm / Sy.gmsys
        put(V.bodies[1].obj, x * fc, y * fc, z * fc, turned("Charon", jd))
        put(V.planet, -x * fp, -y * fp, -z * fp, turned("Pluto", jd))
      else
        at(V.planet, cx, cy, cz, turned(V.name, jd))
        for k, b in ipairs(V.bodies) do
          local x, y, z = E.moonPos(Sy, k, t)
          put(b.obj, x, y, z, turned(b.rot, jd))
        end
      end
    end
  end
  showDate(dateStr(D.JD0 + t))
end

v:preSim(function(N_)
  if holdPre() then return end
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
      stats.bins[#stats.bins + 1] = { t = tc, m = m }
    end
    stats.bin, stats.binS, stats.binN = bin, 0, 0
  end
  stats.binS, stats.binN = stats.binS + lap, stats.binN + 1
  local ax, ay, az = E.mainPos(E.IDX.Neptune, t)
  local bx, by, bz = E.mainPos(E.IDX.Pluto, t)
  stats.npMin = math.min(stats.npMin, sqrt((ax - bx) ^ 2 + (ay - by) ^ 2 + (az - bz) ^ 2))
  -- the Moon's face toward the Earth: where on the Moon the Earth is overhead
  local jd = D.JD0 + t
  local ex, ey, ez = E.mainPos(iEarth, t)
  local mx, my, mz = E.mainPos(iMoon, t)
  local la, lo = onBody("Moon", jd, ex - mx, ey - my, ez - mz)
  local L = stats.lib
  L[1], L[2], L[3], L[4] = math.min(L[1], lo), math.max(L[2], lo), math.min(L[3], la), math.max(L[4], la)
  -- Mercury at each perihelion: where on it the Sun is overhead
  local sx, sy, sz = E.mainPos(iSun, t)
  local qx, qy, qz = E.mainPos(E.IDX.Mercury, t)
  local r = sqrt((qx - sx) ^ 2 + (qy - sy) ^ 2 + (qz - sz) ^ 2)
  local R = stats.mr
  if R[1] and R[2] and R[1] > R[2] and r > R[2] then stats.merc[#stats.merc + 1] = R.lon end
  R[1], R[2] = R[2], r
  R.lon = select(2, onBody("Mercury", jd, sx - qx, sy - qy, sz - qz))
  checks()
end)
v:postSim(function(N_)
  if holdNow then return end
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
  "The Sun, the planets, Pluto, five asteroids and 21 moons,",
  "moved by gravity from where JPL had them on 2026-01-01.",
  "The orrery: distances from the Sun square-rooted, so all",
  "fit. Behind: each planet's moons, square-rooted the same.",
  "",
  "Each wears a map of its surface, and turns as it does:",
  "slow down (1: a quarter of a day a second) to watch.",
  "Rest the mouse on one for what it's like.",
  "",
  "1-5  a quarter of a day, 1, 5, 25, 100 days a second",
  "R    back to 2026-01-01",
  "",
  "Slider: days (a second).",
}, "\n"))
-- what a body is like, for the mouse: its size, its turning, its tilt
local FACTS = {
  Sun = { r = 695700, note = "Its sunspots come and go; these are an example. It turns faster at its equator than near its poles; this is its\nturning at about 16 degrees north and south (Carrington's)." },
  Mercury = { r = 2439.4, note = "It turns three times in two of its years: so its day, noon to noon, is two of its years long." },
  Venus = { r = 6051.8, note = "Shown as radar sees its ground, under the clouds (they go round in 4 days)." },
  Earth = { r = 6371.0 }, Moon = { r = 1737.4 }, Mars = { r = 3389.5 },
  Jupiter = { r = 69911, note = "The Great Red Spot drifts round, against the turning that's measured by Jupiter's radio waves (System III);\nit's put down here as an example." },
  Saturn = { r = 58232, note = "The hexagon round its north pole turns with it." },
  Uranus = { r = 25362, note = "It lies on its side. Its few bright clouds are an example." },
  Neptune = { r = 24622, note = "Its dark spots and clouds come and go; these are an example." },
  Pluto = { r = 1188.3, note = "It and Charon keep the same faces to each other." }, Charon = { r = 606 },
  Titan = { r = 2574.7, note = "Its haze hides its ground." },
  Iapetus = { r = 734.5, note = "The side it leads with, as it goes round, is dark." },
}
local function span(days)
  local d = abs(days)
  if d < 1 / 24 then return string.format("%.0f min", d * 1440) end
  if d < 2 then
    local m = floor(d * 1440 + 0.5)
    return string.format("%d h %02d min", floor(m / 60), m % 60)
  end
  if d < 1000 then return string.format("%.2f days", d) end
  return string.format("%.1f years", d / 365.25)
end
local function angle(ax, ay, az, bx, by, bz)
  local c = (ax * bx + ay * by + az * bz) / sqrt((ax * ax + ay * ay + az * az) * (bx * bx + by * by + bz * bz))
  return math.deg(math.acos(math.max(-1, math.min(1, c))))
end
-- its orbit (relative position, velocity, the pair's GM): its period, in days, and its pole
local function orbit(x, y, z, vx, vy, vz, mu)
  local r = sqrt(x * x + y * y + z * z)
  local a = 1 / (2 / r - (vx * vx + vy * vy + vz * vz) / mu)
  return 2 * pi * sqrt(a ^ 3 / mu), y * vz - z * vy, z * vx - x * vz, x * vy - y * vx
end
for _, b in ipairs(D.main) do
  if not FACTS[b.name] then FACTS[b.name] = { r = b.r * AUKM } end
end
local function commas(x) return (string.format("%.0f", x):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
-- the pole it turns anticlockwise about (the IAU's north, or for a body
-- turning the other way, its south)
local function spinPole(name)
  local _, _, p = ROT.rotation(name, D.JD0 + t)
  if ROT.period(name) < 0 then return -p[1], -p[2], -p[3] end
  return p[1], p[2], p[3]
end
-- a body's lines: its size, its turning, its axis's tilt to its orbit
local function about(name, around, P, hx, hy, hz)
  local lines = {}
  local f = FACTS[name]
  if f then lines[#lines + 1] = "radius " .. commas(f.r) .. " km" end
  local rot = ROT.period(name)
  if rot then
    local px, py, pz = spinPole(name)
    local tilt = hx and angle(px, py, pz, hx, hy, hz)
    local s = "turns once in " .. span(rot) .. ((tilt and tilt > 90) and ", backwards (against its going round)" or "")
    if P and abs(abs(rot) - P) / P < 0.02 then
      s = s .. string.format(",\nonce each time round %s: it keeps one face toward it", around)
    elseif P and around == "the Sun" then
      local day = 1 / (1 / abs(rot) - (tilt > 90 and -1 or 1) / P)
      s = s .. string.format("; its day, noon to noon, %s", span(day))
    end
    lines[#lines + 1] = s
    if tilt then lines[#lines + 1] = string.format("its axis tilted %.1f degrees to its orbit", tilt) end
  end
  if f and f.note then lines[#lines + 1] = f.note end
  return table.concat(lines, "\n")
end
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local k = KEYS[objectKey(obj)]
    if not k then return nil end
    local sx, sy, sz = E.mainPos(iSun, t)
    local ex, ey, ez = E.mainPos(iEarth, t)
    -- a planet (or Pluto, or an asteroid) about the Sun
    local function planet(name, i)
      local bx, by, bz = E.mainPos(i, t)
      local X, Y, Z, VX, VY, VZ = E.mainState(i)
      if name == "Earth" then                -- (the Earth and the Moon go round the Sun together)
        local mX, mY, mZ, mVX, mVY, mVZ = E.mainState(iMoon)
        local a, b = E.GM[iEarth], E.GM[iMoon]
        local w = function(p, q) return (a * p + b * q) / (a + b) end
        X, Y, Z, VX, VY, VZ = w(X, mX), w(Y, mY), w(Z, mZ), w(VX, mVX), w(VY, mVY), w(VZ, mVZ)
        i = iMoon                             -- (for the pair's GM, below: the Sun's plus the Earth's plus the Moon's)
      end
      local _, _, _, SVX, SVY, SVZ = E.mainState(iSun)
      local P, hx, hy, hz = orbit(X - select(1, E.mainState(iSun)), Y - select(2, E.mainState(iSun)), Z - select(3, E.mainState(iSun)),
                                  VX - SVX, VY - SVY, VZ - SVZ, E.GM[iSun] + E.GM[i] + (name == "Earth" and E.GM[iEarth] or 0))
      local de = sqrt((bx - ex) ^ 2 + (by - ey) ^ 2 + (bz - ez) ^ 2)
      local head = string.format("%s\n%.3f AU from the Sun; %s, a year of %s", name,
                                 sqrt((bx - sx) ^ 2 + (by - sy) ^ 2 + (bz - sz) ^ 2), name == "Earth" and "here" or
                                 string.format("%.3f AU from the Earth (light takes %s)", de, span(de * AUKM / 299792.458 / 86400)),
                                 span(P))
      local rest = about(name, "the Sun", P, hx, hy, hz)
      return rest ~= "" and head .. "\n" .. rest or head
    end
    if k.kind == "sun" then
      return string.format("The Sun\n%s, going %g days a second\n%s", dateStr(D.JD0 + t), v:getParam("days"), about("Sun"))
    elseif k.kind == "orrery" then
      return planet(k.name, k.i)
    elseif k.kind == "orbit" then
      return k.name .. "'s orbit (as it is in 2026; the orrery's distances are square-rooted)"
    elseif k.kind == "vplanet" then
      local name = k.v.name
      return (name == "Earth" and "The Earth" or name) .. ", with its moons (distances from it square-rooted)\n" ..
             planet(name, E.IDX[name]):gsub("^[^\n]*\n", "")
    elseif k.kind == "moon" then
      local V, b = k.v, k.b
      local mx, my, mz, vx, vy, vz, mu, around
      if V.name == "Earth" then
        local px, py, pz = E.mainPos(iMoon, t)
        local X, Y, Z, VX, VY, VZ = E.mainState(iMoon)
        local X2, Y2, Z2, VX2, VY2, VZ2 = E.mainState(iEarth)
        mx, my, mz = px - ex, py - ey, pz - ez
        vx, vy, vz, mu, around = VX - VX2, VY - VY2, VZ - VZ2, E.GM[iEarth] + E.GM[iMoon], "the Earth"
        local P, hx, hy, hz = orbit(X - X2, Y - Y2, Z - Z2, vx, vy, vz, mu)
        return string.format("The Moon\n%.0f km from the Earth, round it in %s\n%s", km(sqrt(mx * mx + my * my + mz * mz)), span(P),
                             about("Moon", around, P, hx, hy, hz))
      end
      local Sy = E.SYS[V.si]
      local m = Sy.moons[b.k]
      mx, my, mz = E.moonPos(Sy, b.k, t)
      local dt = 1e-4
      local x2, y2, z2 = E.moonPos(Sy, b.k, t + dt)
      local P, hx, hy, hz = orbit(mx, my, mz, (x2 - mx) / dt, (y2 - my) / dt, (z2 - mz) / dt, m.mu)
      local r = FACTS[b.name] and FACTS[b.name].r or m.r * AUKM
      local lines = string.format("%s\nradius %.0f km\n%.0f km from %s, round it in %s (%s)", b.name, r,
                                  km(sqrt(mx * mx + my * my + mz * mz)), V.name, span(P),
                                  m.source == "Horizons" and "from JPL Horizons' start" or "start: " .. m.source)
      local rest = about(b.name, V.name, P, hx, hy, hz):gsub("^radius[^\n]*\n?", "")
      local qx, qy, qz = spinPole(V.name)
      if V.name ~= "Pluto" and angle(hx, hy, hz, qx, qy, qz) > 90 then
        lines = lines .. "\nIt goes round " .. V.name .. " backwards, against its turning."
      end
      return rest ~= "" and lines .. "\n" .. rest or lines
    end
  end)
end

start()
show()
