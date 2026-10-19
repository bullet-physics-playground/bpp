--
-- Iridium round the Earth
--
-- A NASA Blue Marble Earth (demo/koppi/earth-nasa.jpg, "Blue Marble:
-- Next Generation", NASA Visible Earth) turning once a sidereal day, with
-- every satellite of the Iridium fleet flying its own orbit round it and
-- dragging a yellow trail of the path it covered in the last minutes.
--
-- The elements are Celestrak's iridium-NEXT group, snapshotted into
-- demo/koppi/iridium.tle (80 satellites, epoch 2026 October 19). Refresh
-- them and the ground below each satellite stays right:
--
--   curl -o demo/koppi/iridium.tle \
--     'https://celestrak.org/NORAD/elements/gp.php?GROUP=iridium-NEXT&FORMAT=tle'
--
-- Each orbit is propagated from its own elements: the mean motion gives the
-- size of the orbit, the epoch, mean anomaly and argument of perigee where
-- the satellite is along it, the inclination and node the plane it flies
-- in. The orbit is taken as a circle -- Iridium's eccentricity is 0.0002,
-- ten kilometres out of 7800, far less than a satellite is drawn wide --
-- and the node's slow J2 drift (about 0.4 degree a day) is left out, since
-- it moves by less than a hundredth of a degree while this runs. The Earth
-- turns by the same clock, from the epoch's Greenwich sidereal time, so
-- the ground a satellite is over is where it really was. The run starts on
-- the present moment and the speed defaults to real time, so the fleet
-- shows where it is now -- true while the elements are fresh, so refresh
-- them (as above) as they age. The window's status bar carries the same
-- clock: the simulated date and time, in UTC, ticking with the speed.
--
-- The view's up direction is the north celestial pole: the TLE frame is
-- equatorial, so the Earth needs no tilt of its own.
--
-- Each satellite is a compound of three meshes sharing one frame (see
-- their headers): demo/koppi/iridium-bus.obj, the foil-covered bus;
-- iridium-panels.obj, the two solar wings; and iridium-antenna.obj, the
-- 1.4 x 1.4 m L-band main mission antenna deck.  They are an Iridium NEXT
-- drawn from its published dimensions (half hexagonal bus 3.1 x 1.5 x
-- 1.5 m, solar wings 9.4 m tip to tip), scaled up to the stage -- about
-- 25,000 times life size, a real satellite being a few tens of
-- micrometres wide here -- and aimed every frame so that the antenna
-- looks at the ground and the wings lie across the track, the way a
-- nadir-pointed satellite flies.  Each part wears its own texture in the
-- view and, for a POV-Ray render, its own material written by hand in an
-- sdl block: a metal with a patterned pigment, because a POV-Ray mesh2
-- carries no texture coordinates to map an image along.
--
-- Resting the mouse on a satellite -- one of its three parts, its
-- coverage cell or a piece of its trail -- brings up a card with its
-- name and where it is right now: the sub-satellite point's latitude and
-- longitude under the map's own clock, and the altitude above the globe.
--
-- The ground each satellite can see is tinted blue with a hexagon of its
-- coverage footprint laid on the Earth below (demo/koppi/
-- iridium-coverage.obj, whose header works the footprint's size out),
-- rotated to face out under the satellite every frame, and edged by the
-- rim of demo/koppi/iridium-coverage-outline.obj in near-white blue so
-- the cells read as a grid; the tints are 80% transparent and the yellow
-- trails half transparent, so the map still reads through the fleet's
-- overlapping cells.
--
-- A POV-Ray render wants the cells fainter than the view's 80%: the
-- fleet's cells lie on top of one another, eight of them deep over the
-- poles, and at that depth they bury the map under a sheet of blue.  So
-- the two cells get a material of their own for the render, nearly
-- transparent, written out by hand in an sdl block like the satellites'
-- materials above.
--
-- Trails after https://github.com/Sec42/xplanet-anim (satellites/mk_marker).
--
-- Usage: bpp -f demo/koppi/iridium.lua
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
-- whatever that makes it, so the orbits sit at their true height above it
-- ---------------------------------------------------------------------------
local R_EARTH  = 10                    -- Earth's radius, scene units
local KM       = R_EARTH / 6371        -- one kilometre, scene units
local GM       = 398600.4418           -- Earth's gravity constant, km^3/s^2
local TRAIL_R  = 0.025                  -- how thick a satellite's trail is drawn
local TRAIL_MIN = 8                    -- trail: minutes behind the satellite
local TRAIL_SEG = 10                   -- trail: pieces along that stretch
local YEL      = color.yellow
local ORIGIN   = btVector3(0, 0, 0)
local YAXIS    = btVector3(0, 1, 0)

-- ---------------------------------------------------------------------------
-- the two files, looked for beside the script and then in demo/koppi/ (the
-- same pair of places, in either order, depending on where bpp was started)
-- ---------------------------------------------------------------------------
local DIR = ""
for _, d in ipairs({ "", "demo/koppi/" }) do
  local f = io.open(d .. "iridium.tle", "r")
  if f then f:close(); DIR = d; break end
end

local fh = assert(io.open(DIR .. "iridium.tle", "r"),
                  "iridium.tle not found beside this script or in demo/koppi/")
local tleText = fh:read("*a")
fh:close()

local TEX = DIR .. "earth-nasa.jpg"
local COV = DIR .. "iridium-coverage.obj"
local EDGE = DIR .. "iridium-coverage-outline.obj"

-- The colours of the coverage cells: the tint of the ground a satellite
-- can see, and the near-white blue of the rim round it.  Each of them is
-- needed twice -- once for the view, once for the POV-Ray material below.
local COV_COL = "#3399ff"
local COV_EMIT = "#0f3c8c"               -- the night side reads too
local EDGE_COL = "#e6f2ff"
local EDGE_EMIT = "#4477cc"              -- the night side reads too

-- The parts of one satellite: three meshes in the same coordinate frame,
-- so the same transform stands all three -- that is what makes the
-- compound.  Each carries its surface twice: as a texture for the view,
-- and as a POV-Ray material in sdl (which replaces the flat pigment the
-- exporter would otherwise write; no_shadow goes in by hand for the
-- same reason).
local PARTS = {
  { mesh = "iridium-bus.obj", tex = "iridium-bus.png",
    sdl = [[texture {
      pigment {
        bozo
        turbulence 0.35
        color_map {
          [0.40 rgb <0.72, 0.50, 0.14>]
          [0.60 rgb <0.90, 0.72, 0.32>]
          [0.80 rgb <0.58, 0.38, 0.10>]
        }
        scale 0.09
      }
      finish { metallic 0.85 specular 0.85 roughness 0.03 emission rgb <0.2, 0.2, 0.2> }
    }
    no_shadow]] },
  { mesh = "iridium-panels.obj", tex = "iridium-panels.png",
    sdl = [[texture {
      pigment {
        checker
        rgb <0.03, 0.05, 0.13>, rgb <0.08, 0.12, 0.26>
        scale 0.019
      }
      finish { metallic 0.7 specular 0.9 roughness 0.01 emission rgb <0.15, 0.15, 0.15> }
    }
    no_shadow]] },
  { mesh = "iridium-antenna.obj", tex = "iridium-antenna.png",
    sdl = [[texture {
      pigment {
        checker
        rgb <0.78, 0.79, 0.81>, rgb <0.60, 0.61, 0.64>
        scale 0.014
      }
      finish { metallic 0.6 specular 0.5 roughness 0.05 emission rgb <0.18, 0.18, 0.18> }
    }
    no_shadow]] },
}

for _, p in ipairs(PARTS) do
  for _, f in ipairs({ DIR .. p.mesh, DIR .. p.tex }) do
    local fh = assert(io.open(f, "r"),
                      f .. " not found beside this script or in demo/koppi/")
    fh:close()
  end
end

for _, f in ipairs({ COV, EDGE }) do
  local fh = assert(io.open(f, "r"),
                    f .. " not found beside this script or in demo/koppi/")
  fh:close()
end

-- ---------------------------------------------------------------------------
-- the POV-Ray materials of the coverage cells
-- ---------------------------------------------------------------------------
-- A hex colour as the three numbers between 0 and 1 that POV-Ray wants.
local function povRGB(hex)
  local r, g, b = color.col2rgb(hex)
  return string.format("%.6f, %.6f, %.6f", r / 255, g / 255, b / 255)
end

-- The material of a coverage cell in a POV-Ray render: the colour and the
-- glow of the view, but as see-through as the render wants it.  An sdl
-- block replaces the exporter's own pigment and finish, and the no_shadow
-- that goes with them, so all of it is written out here.
local function povTint(col, emit, transmit)
  return string.format([[
  pigment { rgbt <%s> }
  finish { emission rgb <%s> }
  no_shadow
]], povRGB(col) .. ", " .. transmit, povRGB(emit))
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

local lines = {}
for l in tleText:gmatch("[^\r\n]+") do lines[#lines + 1] = l end

local sats = {}
local i = 1
while i <= #lines - 2 do
  local l1, l2 = lines[i + 1], lines[i + 2]
  if l1:sub(1, 1) == "1" and l2:sub(1, 1) == "2" then
    local yy   = tonumber(l1:sub(19, 20))
    local doy  = tonumber(l1:sub(21, 32))
    local inc  = tonumber(l2:sub(9, 16))    -- inclination, degrees
    local node = tonumber(l2:sub(18, 25))   -- right ascension of node, degrees
    local argp = tonumber(l2:sub(35, 42))   -- argument of perigee, degrees
    local M0   = tonumber(l2:sub(44, 51))   -- mean anomaly at epoch, degrees
    local n    = tonumber(l2:sub(53, 63))   -- mean motion, revolutions a day
    if yy and doy and inc and node and argp and M0 and n then
      local year = yy < 57 and (2000 + yy) or (1900 + yy)
      local jd = julianNoon(year, 1, 1) - 0.5 + doy - 1
      sats[#sats + 1] = {
        name = lines[i]:match("^%s*(.-)%s*$"),
        inc  = inc, node = node, w = argp, M0 = M0, n = n,
        -- radius of the circular orbit, in scene units
        a    = (GM / (n * 2 * math.pi / 86400) ^ 2) ^ (1 / 3) * KM,
        -- the plane's unit normal, already in scene coordinates: the
        -- usual (sin i sin O, -sin i cos O, cos i) of an orbit inclined
        -- i with its node at O, put through the same turn as satAt()
        -- below.  Crossed with the satellite's position (h cross r) it
        -- is the direction of travel, which is what the model has to be
        -- aimed along.
        hx   = math.sin(math.rad(inc)) * math.sin(math.rad(node)),
        hy   = math.cos(math.rad(inc)),
        hz   = math.sin(math.rad(inc)) * math.cos(math.rad(node)),
        djd  = 0,                        -- its epoch against the reference, filled below
        jd   = jd,
      }
    end
    i = i + 3
  else
    i = i + 1
  end
end
assert(#sats > 0, "no two-line elements found in " .. DIR .. "iridium.tle")

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
  -- Three parts make one satellite; the geometry behind each is loaded
  -- once (the scale is baked into the file, its header says which) and
  -- shared by the whole fleet through bpp's mesh cache.
  s.parts = {}
  for _, p in ipairs(PARTS) do
    local part = Mesh(DIR .. p.mesh, 0, false)
    part.tex = DIR .. p.tex
    part.col = "#ffffff"
    part.emission = "#404040"            -- lit from behind, it still shows
    part.sdl = p.sdl
    part.castShadow = false
    part.collides = false
    v:add(part)
    s.parts[#s.parts + 1] = part
  end

  -- The coverage hexagon: the ground this satellite can see, one mesh
  -- shared by the fleet (its header works the footprint's size out). It
  -- is centred on the Earth, so only a rotation places it -- pointZ()
  -- aims its local z at the satellite -- which place() does each frame.
  -- The tint is 80% transparent, so the map shows through it.
  local cov = Mesh(COV, 0, false)
  cov.col = COV_COL
  cov.emission = COV_EMIT
  cov.transparency = 0.8
  cov.castShadow = false
  cov.collides = false
  cov.sdl = povTint(COV_COL, COV_EMIT, 0.98)   -- the render wants it fainter
  v:add(cov)
  s.cov = cov

  -- Its outline: the same hexagon as a thin band round the rim, a hair
  -- above the tint so it draws over it, in near-white blue -- which is
  -- what makes the cells read as a grid of hexagons.
  local edge = Mesh(EDGE, 0, false)
  edge.col = EDGE_COL
  edge.emission = EDGE_EMIT
  edge.transparency = 0.35
  edge.castShadow = false
  edge.collides = false
  edge.sdl = povTint(EDGE_COL, EDGE_EMIT, 0.7)
  v:add(edge)
  s.edge = edge

  -- The trail is a chain of fixed-length cylinders: every piece spans the
  -- same angle of the orbit (the orbit is a circle), so its length never
  -- changes and only the transform has to be set each frame.
  local step = 2 * math.pi * s.n * (TRAIL_MIN / TRAIL_SEG) / 1440
  local chord = 2 * s.a * math.sin(step / 2)
  s.segs = {}
  for k = 1, TRAIL_SEG do
    local cy = Cylinder(TRAIL_R, chord, 0)
    cy.col = YEL
    cy.emission = YEL
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

-- Aim a local +z at a unit direction -- the coverage hexagon's case,
-- where that is all its placement is, the hexagon turning about its own
-- axis as it pleases. Axis and angle as ever: (0,0,1) cross the
-- direction, and the angle between the two.
local function pointZ(x, y, z)
  if z > 0.999999 then return btQuaternion(0, 0, 0, 1) end
  if z < -0.999999 then return btQuaternion(1, 0, 0, math.pi) end
  local ax, ay = -y, x                     -- (0,0,1) cross (x,y,z)
  local al = math.sqrt(ax * ax + ay * ay)
  return btQuaternion(btVector3(ax / al, ay / al, 0), math.acos(z))
end

-- Aim a satellite at the ground: its local x axis along travel (h cross
-- r, the orbit's normal crossed with the position), its local y across
-- the track (along the normal itself) and its local z up (along the
-- position), which leaves the antenna face on the underside looking down.
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
    -- the hexagon of this satellite's coverage, on the ground below it:
    -- its centre is the Earth's, so pointing local z at the satellite
    -- (the orbit is a circle, |r| = s.a) is the whole of the placement;
    -- the outline is the same hexagon, so it takes the same transform
    local t = btTransform(pointZ(x0 / s.a, y0 / s.a, z0 / s.a), ORIGIN)
    s.cov.trans = t
    s.edge.trans = t
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
common.setCamera(btVector3(0, 0, 31), btVector3(0, 0, 0), nil,
                 { up = btVector3(0, 1, 0) })

place(days)

-- Hover: rest the mouse on a satellite -- any of its three parts, its
-- coverage cell or a piece of its trail -- and a card comes up with its
-- name and where it is right now. The position is satAt's own, so the
-- card always agrees with the picture: scene y is north, so that part is
-- the latitude; scene z is minus the middle axis of satAt's frame, so
-- atan2 of the other two is where the satellite hangs inertially, and
-- taking the same sidereal angle off it that the Earth shows turns that
-- into a longitude on the map.
local owner = {}                    -- objectKey -> the satellite it belongs to
for _, s in ipairs(sats) do
  for _, part in ipairs(s.parts) do owner[objectKey(part)] = s end
  owner[objectKey(s.cov)] = s
  owner[objectKey(s.edge)] = s
  for _, cy in ipairs(s.segs) do owner[objectKey(cy)] = s end
end

local function card(s)
  local px, py, pz = satAt(s, days)
  local r = math.sqrt(px * px + py * py + pz * pz)
  local lat = math.deg(math.asin(py / r))
  local lon = (math.deg(math.atan2(-pz, px)) - gmstDeg(JD0 + days) + 180) % 360 - 180
  return string.format("%s\n%.1f°%s %.1f°%s  %d km", s.name,
                       math.abs(lat), lat < 0 and "S" or "N",
                       math.abs(lon), lon < 0 and "W" or "E",
                       math.floor(r / KM + 0.5) - 6371)
end

v:onHover(function(N, obj, x, y, z)
  local s = owner[objectKey(obj)]
  if not s then return end           -- the Earth itself: no card
  return card(s)
end)

v:preStart(function(N)
  v.statusText = utc(JD0 + days)
  print(string.format("iridium: %d satellites from %siridium.tle, epoch %.4f, map %s, model %s (+2 parts)",
                      #sats, DIR, JD0, TEX, DIR .. PARTS[1].mesh))
end)

v:preSim(function(N)
  local speed = tonumber(v:getParam("speed")) or 1 / 60
  days = days + DT * speed / 1440
  place(days)
  v.statusText = utc(JD0 + days)         -- the status bar's clock, running
end)

-- EOF
