--
-- GPS / GNSS constellations around the Earth
--
-- A NASA Blue Marble Earth (demo/koppi/earth-nasa.jpg, "Blue Marble:
-- Next Generation", NASA Visible Earth) turning once a sidereal day, with
-- every satellite of the navigation constellations in demo/koppi/gps.tle
-- flying its own orbit round it and dragging a trail of the path it
-- covered in the last minutes.
--
-- The orbits are drawn much nearer the Earth than they really are: the
-- height above the surface is squeezed by ALT (see below), so that the
-- fleet flies in a shell just above the globe instead of out at its true
-- distance, twenty thousand kilometres and more, where the satellites
-- would be specks far outside the frame.  Everything else is as it is in
-- space: the mean motion gives the size of the orbit, the epoch, mean
-- anomaly and argument of perigee where the satellite is along it, the
-- inclination and node the plane it flies in, and the Earth turns by the
-- same clock, from the epoch's Greenwich sidereal time, so the ground a
-- satellite is over is where it really was.
--
-- Each satellite is a compound of three meshes sharing one frame (see
-- their headers): demo/koppi/gps-bus.obj, the spacecraft bus;
-- gps-panels.obj, the two solar wings; and gps-antenna.obj, the L-band
-- antenna array that faces the Earth.  They are a GPS satellite drawn
-- from its published dimensions and scaled up to the stage, and aimed
-- every frame so that the antenna looks at the ground and the wings lie
-- across the track, the way a nadir-pointed satellite flies.
--
-- Every satellite wears the colours of the flag of the country that flies
-- it -- red, white and blue for the American GPS birds, gold and red for
-- the Chinese BeiDou ones, and so on -- so that the constellations can be
-- told apart at a glance; its trail is drawn in the same colours.
--
-- Rest the mouse on a satellite -- on one of its three parts, or on a
-- piece of its trail -- and a card comes up with its name, the country
-- that flies it, the place on the Earth it is over and how high it really
-- is.
--
-- Usage: bpp -f demo/koppi/gps.lua
--

local color = require "color"
local common = require "common"

-- ---------------------------------------------------------------------------
-- the clock: a frame is a sixtieth of a second, and the GUI timer runs at
-- the same rate, so "speed" minutes of orbit time pass a second on the
-- wall; the default of 1/60 of them is real time
-- ---------------------------------------------------------------------------
local DT = 1 / 60
common.setTiming(DT, 0, DT)
v.animationPeriod = 16
v.gravity = btVector3(0, 0, 0)

v:addParam("speed", 1 / 60, 1 / 60, 60, 1 / 60,
           "minutes of orbit time per real second (1/60 = real time)")

-- ---------------------------------------------------------------------------
-- sizes: the Earth is 10 units across its radius, and a kilometre is
-- whatever that makes it
-- ---------------------------------------------------------------------------
local R_EARTH  = 10
local KM       = R_EARTH / 6371
local GM       = 398600.4418
-- The height above the Earth's surface is squeezed by this factor.  At its
-- true height a navigation satellite would be 20,000 km or more out, a
-- speck far outside the frame, so the fleet is drawn in a shell just above
-- the globe: the low ones (GLONASS, 19,100 km) innermost, the
-- geostationary ones (35,800 km) outermost.
local ALT      = 0.06
local TRAIL_R  = 0.015
local TRAIL_MIN = 8
local TRAIL_SEG = 10
local ORIGIN   = btVector3(0, 0, 0)
local YAXIS    = btVector3(0, 1, 0)

-- ---------------------------------------------------------------------------
-- the two files, looked for beside the script and then in demo/koppi/ (the
-- same pair of places, in either order, depending on where bpp was started)
-- ---------------------------------------------------------------------------
local DIR = ""
for _, d in ipairs({ "", "demo/koppi/" }) do
  local f = io.open(d .. "gps.tle", "r")
  if f then f:close(); DIR = d; break end
end

local fh = assert(io.open(DIR .. "gps.tle", "r"), "gps.tle not found")
local tleText = fh:read("*a")
fh:close()

local TEX = DIR .. "earth-nasa.jpg"

-- ---------------------------------------------------------------------------
-- the flag colours of the countries that fly the satellites in the file
-- ---------------------------------------------------------------------------
-- The name of a satellite gives its constellation away, and with it the
-- country that flies it: GPS is American, COSMOS and LUCH Russian,
-- BEIDOU Chinese, IRNSS, NVS and the hyphenated GSAT Indian, the
-- unhyphenated GSAT and GALAXY European (they are ESA's Galileo birds),
-- QZS Japanese, EUTELSAT French, SES and ASTRA Luxembourgish, and
-- INMARSAT British.  A satellite paints its bus, its solar wings, its
-- antenna array and its trail in the colours of its flag.
local FLAGS = {
  { pattern = "^GPS",      country = "USA", bus = "#b31942", panels = "#0a3161",
    antenna = "#ffffff", trail = "#6ea8ff" },
  { pattern = "^COSMOS",   country = "Russia", bus = "#0039a6", panels = "#ffffff",
    antenna = "#d52b1e", trail = "#e02020" },
  { pattern = "^LUCH",     country = "Russia", bus = "#0039a6", panels = "#ffffff",
    antenna = "#d52b1e", trail = "#e02020" },
  { pattern = "^BEIDOU",   country = "China", bus = "#de2910", panels = "#ffde00",
    antenna = "#de2910", trail = "#ffc400" },
  { pattern = "^IRNSS",    country = "India", bus = "#ff9933", panels = "#138808",
    antenna = "#ffffff", trail = "#18a558" },
  { pattern = "^NVS",      country = "India", bus = "#ff9933", panels = "#138808",
    antenna = "#ffffff", trail = "#18a558" },
  { pattern = "^GSAT%-",   country = "India", bus = "#ff9933", panels = "#138808",
    antenna = "#ffffff", trail = "#18a558" },
  { pattern = "^GSAT%d",   country = "Europe", bus = "#003399", panels = "#ffcc00",
    antenna = "#003399", trail = "#2440c0" },
  { pattern = "^GALAXY",   country = "Europe", bus = "#003399", panels = "#ffcc00",
    antenna = "#003399", trail = "#2440c0" },
  { pattern = "^QZS",      country = "Japan", bus = "#bc002d", panels = "#ffffff",
    antenna = "#bc002d", trail = "#ffffff" },
  { pattern = "^EUTELSAT", country = "France", bus = "#002395", panels = "#ffffff",
    antenna = "#ed2939", trail = "#0055a4" },
  { pattern = "^SES",      country = "Luxembourg", bus = "#00a1de", panels = "#ff0000",
    antenna = "#ffffff", trail = "#00c8f0" },
  { pattern = "^ASTRA",    country = "Luxembourg", bus = "#00a1de", panels = "#ff0000",
    antenna = "#ffffff", trail = "#00c8f0" },
  { pattern = "^INMARSAT", country = "UK", bus = "#012169", panels = "#ffffff",
    antenna = "#c8102e", trail = "#c8102e" },
}

-- The flag of the country that flies a satellite, by the name of its
-- constellation.
local function flagOf(name)
  for _, f in ipairs(FLAGS) do
    if name:match(f.pattern) then return f end
  end
  error("no flag colours for " .. name)
end

-- ---------------------------------------------------------------------------
-- the parts of one satellite: three meshes in the same coordinate frame,
-- so the same transform stands all three -- that is what makes the
-- compound.  The scale is baked into each file, its header says which.
-- ---------------------------------------------------------------------------
local PARTS = {
  { mesh = "gps-bus.obj",     key = "bus" },
  { mesh = "gps-panels.obj",  key = "panels" },
  { mesh = "gps-antenna.obj", key = "antenna" },
}

for _, p in ipairs(PARTS) do
  local f = assert(io.open(DIR .. p.mesh, "r"),
                   p.mesh .. " not found beside this script or in demo/koppi/")
  f:close()
end

-- A dimmed colour, for the glow that keeps the night side of a satellite
-- readable in its own country's colours.
local function dim(hex, f)
  local r, g, b = color.col2rgb(hex)
  return color.rgb2col(math.floor(r * f), math.floor(g * f), math.floor(b * f))
end

-- ---------------------------------------------------------------------------
-- the elements
-- ---------------------------------------------------------------------------
-- Julian day of noon on a Gregorian date (the classic algorithm), so that
-- the epoch day-of-year on line 1 of a TLE becomes a date.
local function julianNoon(year, month, day)
  local a = math.floor((14 - month) / 12)
  local y = year + 4800 - a
  local m = month + 12 * a - 3
  return day + math.floor((153 * m + 2) / 5) + 365 * y + math.floor(y / 4)
       - math.floor(y / 100) + math.floor(y / 400) - 32045
end

-- Greenwich mean sidereal time in degrees: how far the prime meridian has
-- turned from the March equinox, which is exactly the angle the Earth's
-- texture has to be turned by.
local function gmstDeg(jd)
  return (280.46061837 + 360.98564736629 * (jd - 2451545.0)) % 360
end

-- The status bar's clock: the inverse of julianNoon above -- the calendar
-- date and time of day (UTC) that a Julian day falls on, so the window can
-- show the simulation's own date and time instead of a bare day count.
local function utc(jd)
  local n = math.floor(jd + 0.5)          -- the date's Julian day number
  local f = jd + 0.5 - n                  -- and the time of day left over
  -- Julian day number to Gregorian year, month, day
  -- (Fliegel & van Flandern)
  local l = n + 68569
  local nn = math.floor(4 * l / 146097)
  l = l - math.floor((146097 * nn + 3) / 4)
  local i = math.floor(4000 * (l + 1) / 1461001)
  l = l - math.floor(1461 * i / 4) + 31
  local j = math.floor(80 * l / 2447)
  local day = l - math.floor(2447 * j / 80)
  l = math.floor(j / 11)
  local month = j + 2 - 12 * l
  local year = 100 * (nn - 49) + i + l
  local h = math.floor(f * 24)
  local m = math.floor((f * 24 - h) * 60)
  local s = math.floor(((f * 24 - h) * 60 - m) * 60)
  return string.format("%04d-%02d-%02d %02d:%02d:%02d UTC",
                       year, month, day, h, m, s)
end

-- The radius of a circular orbit: the mean motion gives the true radius,
-- and the height above the Earth's surface is then squeezed by ALT, which
-- brings the orbit down to the shell the fleet is drawn in.  Both come
-- back: the radius in scene units, to place the satellite and its trail,
-- and the true one in kilometres, to say how high the satellite really is.
local function orbitRadius(n)
  local a = (GM / (n * 2 * math.pi / 86400) ^ 2) ^ (1 / 3)      -- km
  return R_EARTH + (a * KM - R_EARTH) * ALT, a
end

local lines = {}
for l in tleText:gmatch("[^\r\n]+") do lines[#lines + 1] = l end

local sats = {}
local i = 1
while i <= #lines - 2 do
  local l1, l2 = lines[i + 1], lines[i + 2]
  if l1:sub(1, 1) == "1" and l2:sub(1, 1) == "2" then
    local yy   = tonumber(l1:sub(19, 20))
    local doy  = tonumber(l1:sub(21, 32))
    local inc  = tonumber(l2:sub(9, 16))
    local node = tonumber(l2:sub(18, 25))
    local argp = tonumber(l2:sub(35, 42))
    local M0   = tonumber(l2:sub(44, 51))
    local n    = tonumber(l2:sub(53, 63))
    if yy and doy and inc and node and argp and M0 and n then
      local year = yy < 57 and (2000 + yy) or (1900 + yy)
      local jd = julianNoon(year, 1, 1) - 0.5 + doy - 1
      local a, akm = orbitRadius(n)
      sats[#sats + 1] = {
        name = lines[i]:match("^%s*(.-)%s*$"),
        inc = inc, node = node, w = argp, M0 = M0, n = n,
        a = a,
        alt = akm - 6371,              -- the height over the surface, in km
        hx = math.sin(math.rad(inc)) * math.sin(math.rad(node)),
        hy = math.cos(math.rad(inc)),
        hz = math.sin(math.rad(inc)) * math.cos(math.rad(node)),
        djd = 0, jd = jd,
      }
    end
    i = i + 3
  else
    i = i + 1
  end
end
assert(#sats > 0, "no elements found in " .. DIR .. "gps.tle")

-- One reference epoch for them all (they differ by minutes): the first.
local JD0 = sats[1].jd
for _, s in ipairs(sats) do s.djd = s.jd - JD0 end

-- ---------------------------------------------------------------------------
-- the orbits
-- ---------------------------------------------------------------------------
-- Where a satellite is at a given time, in scene coordinates. The elements
-- place it in the usual earth-centred inertial frame (x at the March
-- equinox, y at the June solstice, z at the north pole); the scene keeps
-- north up and faces the viewer with minus that middle axis, which is the
-- same turn again: (x, y, z) -> (x, z, -y).
local function satAt(s, days)
  local M = (s.M0 + 360 * s.n * (days - s.djd)) % 360
  local u = math.rad(s.w + M)              -- angle up from the node
  local O = math.rad(s.node)
  local ci = math.cos(math.rad(s.inc))
  local si = math.sin(math.rad(s.inc))
  local cu, su = math.cos(u), math.sin(u)
  local cO, sO = math.cos(O), math.sin(O)
  local x = s.a * (cO * cu - sO * su * ci)
  local y = s.a * (sO * cu + cO * su * ci)
  local z = s.a * (su * si)
  return x, z, -y
end

-- ---------------------------------------------------------------------------
-- the Earth and the fleet
-- ---------------------------------------------------------------------------
local earth = Sphere(R_EARTH, 0)
earth.col = "#ffffff"                    -- white under the map, as it must be
earth.tex = TEX
earth.castShadow = false
earth.collides = false
v:add(earth)

for _, s in ipairs(sats) do
  local flag = flagOf(s.name)
  s.country = flag.country

  -- Three parts make one satellite; the geometry behind each is loaded
  -- once (the scale is baked into the file, its header says which) and
  -- shared by the whole fleet through bpp's mesh cache.  Each part wears
  -- the colour its flag gives it.
  s.parts = {}
  for _, p in ipairs(PARTS) do
    local part = Mesh(DIR .. p.mesh, 0, false)
    part.col = flag[p.key]
    part.emission = dim(flag[p.key], 0.45)  -- lit from behind, it still shows
    part.castShadow = false
    part.collides = false
    v:add(part)
    s.parts[#s.parts + 1] = part
  end

  -- The trail is a chain of fixed-length cylinders: every piece spans the
  -- same angle of the orbit (the orbit is a circle), so its length never
  -- changes and only the transform has to be set each frame.
  local step = 2 * math.pi * s.n * (TRAIL_MIN / TRAIL_SEG) / 1440
  local chord = 2 * s.a * math.sin(step / 2)
  s.segs = {}
  for k = 1, TRAIL_SEG do
    local cy = Cylinder(TRAIL_R, chord, 0)
    cy.col = flag.trail
    cy.emission = flag.trail
    cy.transparency = 0.5                -- half transparent
    cy.castShadow = false
    cy.collides = false
    v:add(cy)
    s.segs[k] = cy
  end
end

-- Stand a cylinder (whose local +Z axis is its length) from one point to
-- another: the same turn common.orientBetween() works out, kept in plain
-- numbers because it runs TRAIL_SEG times #sats every frame.
local function stand(cyl, x1, y1, z1, x2, y2, z2)
  local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  if len < 1e-9 then return end
  dx, dy, dz = dx / len, dy / len, dz / len
  local q
  if dz > 0.999999 then
    q = btQuaternion(0, 0, 0, 1)
  elseif dz < -0.999999 then
    q = btQuaternion(1, 0, 0, math.pi)
  else
    local ax, ay = -dy, dx                 -- (0,0,1) cross (dx,dy,dz)
    local al = math.sqrt(ax * ax + ay * ay)
    q = btQuaternion(btVector3(ax / al, ay / al, 0), math.acos(dz))
  end
  cyl.trans = btTransform(q, btVector3((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2))
end

-- Aim a satellite at the ground: its local x axis along travel (h cross
-- r, the orbit's normal crossed with the position), its local y across
-- the track (along the normal itself) and its local z up (along the
-- position), which leaves the antenna array on the underside looking down.
-- Those three directions are the columns of a rotation matrix, turned
-- into a quaternion by the usual trace-and-cases formulas -- plain
-- numbers again, since it runs once per satellite per frame.  All three
-- parts live in the satellite's frame, so the one transform places each
-- of them.
local function aim(sat, px, py, pz, hx, hy, hz, a)
  local rx, ry, rz = px / a, py / a, pz / a   -- up, out along the radius
  local vx = hy * rz - hz * ry                -- travel: h cross r
  local vy = hz * rx - hx * rz
  local vz = hx * ry - hy * rx
  local x, y, z, w
  local tr = vx + hy + rz
  if tr > 0 then
    local s = math.sqrt(tr + 1) * 2
    w, x, y, z = 0.25 * s, (hz - ry) / s, (rx - vz) / s, (vy - hx) / s
  elseif vx > hy and vx > rz then
    local s = math.sqrt(1 + vx - hy - rz) * 2
    w, x, y, z = (hz - ry) / s, 0.25 * s, (hx + vy) / s, (rx + vz) / s
  elseif hy > rz then
    local s = math.sqrt(1 + hy - vx - rz) * 2
    w, x, y, z = (rx - vz) / s, (hx + vy) / s, 0.25 * s, (ry + hz) / s
  else
    local s = math.sqrt(1 + rz - vx - hy) * 2
    w, x, y, z = (vy - hx) / s, (rx + vz) / s, (ry + hz) / s, 0.25 * s
  end
  local t = btTransform(btQuaternion(x, y, z, w), btVector3(px, py, pz))
  for _, part in ipairs(sat.parts) do
    part.trans = t
  end
end

-- ---------------------------------------------------------------------------
-- every frame: the Earth turned to the sidereal time, the satellites and
-- their trails flown back along their orbits by however far behind they hang
-- ---------------------------------------------------------------------------
-- Where the run starts: the present moment, not the epoch -- the fleet
-- where it is right now, in days since the elements were taken. os.date
-- ("!") is UTC, so it is the same instant everywhere on Earth.
local now = os.date("!*t")
local days = julianNoon(now.year, now.month, now.day) - 0.5
           + (now.hour * 3600 + now.min * 60 + now.sec) / 86400 - JD0
local BACK = TRAIL_MIN / TRAIL_SEG / 1440 -- one trail piece, in days

local function place(day)
  earth.trans = btTransform(btQuaternion(YAXIS, math.rad(gmstDeg(JD0 + day))), ORIGIN)

  for _, s in ipairs(sats) do
    local x0, y0, z0 = satAt(s, day)
    aim(s, x0, y0, z0, s.hx, s.hy, s.hz, s.a)
    local px, py, pz = x0, y0, z0
    for k = 1, TRAIL_SEG do
      local x, y, z = satAt(s, day - BACK * k)
      stand(s.segs[k], px, py, pz, x, y, z)
      px, py, pz = x, y, z
    end
  end
end

-- Open on the whole stage: out beyond the fleet's highest orbit, north
-- up (the view's up is the pole, as the head of this file says).
common.setCamera(btVector3(0, 0, 42), btVector3(0, 0, 0), nil,
                 { up = btVector3(0, 1, 0) })

place(days)

-- ---------------------------------------------------------------------------
-- the hover: rest the mouse on a satellite -- on one of its three parts, or
-- on a piece of its trail -- and a card comes up with its name, the country
-- that flies it, the place on the Earth it is over and how high it really
-- is.  The position is satAt's own, so the card always agrees with the
-- picture: scene y is north, so that part is the latitude; scene z is minus
-- the middle axis of satAt's frame, so atan2 of the other two is where the
-- satellite hangs inertially, and taking the same sidereal angle off it
-- that the Earth shows turns that into a longitude on the map.
-- ---------------------------------------------------------------------------
local owner = {}                    -- objectKey -> the satellite it belongs to
for _, s in ipairs(sats) do
  for _, part in ipairs(s.parts) do owner[objectKey(part)] = s end
  for _, cy in ipairs(s.segs) do owner[objectKey(cy)] = s end
end

local function card(s)
  local px, py, pz = satAt(s, days)
  local r = math.sqrt(px * px + py * py + pz * pz)
  local lat = math.deg(math.asin(py / r))
  local lon = (math.deg(math.atan2(-pz, px)) - gmstDeg(JD0 + days) + 180) % 360 - 180
  return string.format("%s (%s)\n%.1f°%s %.1f°%s   %d km", s.name, s.country,
                       math.abs(lat), lat < 0 and "S" or "N",
                       math.abs(lon), lon < 0 and "W" or "E",
                       s.alt)
end

v:onHover(function(N, obj, x, y, z)
  local s = owner[objectKey(obj)]
  if not s then return end           -- the Earth itself: no card
  return card(s)
end)

v:preStart(function(N)
  v.statusText = utc(JD0 + days)
  print(string.format("gps: %d satellites from %sgps.tle, epoch %.4f, map %s, model %s (+2 parts)",
                      #sats, DIR, JD0, TEX, DIR .. PARTS[1].mesh))
end)

v:preSim(function(N)
  local speed = tonumber(v:getParam("speed")) or 1 / 60
  days = days + DT * speed / 1440
  place(days)
  v.statusText = utc(JD0 + days)         -- the status bar's clock, running
end)

-- EOF
