--
-- Orbital objects around the Earth (all objects)
--

local color = require "color"
local common = require "common"

local DT = 1 / 60
common.setTiming(DT, 0, DT)
v.animationPeriod = 16
v.gravity = btVector3(0, 0, 0)

v:addParam("speed", 1 / 60, 1 / 60, 60, 1 / 60,
           "minutes of orbit time per real second (1/60 = real time)")

local R_EARTH  = 10
local KM       = R_EARTH / 6371
local GM       = 398600.4418
local ALT      = 0.12
local TRAIL_R  = 0.005
local TRAIL_MIN = 2
local TRAIL_SEG = 2
local ORIGIN   = btVector3(0, 0, 0)
local YAXIS    = btVector3(0, 1, 0)

local DIR = ""
for _, d in ipairs({ "", "demo/koppi/" }) do
  local f = io.open(d .. "orbital.tle", "r")
  if f then f:close(); DIR = d; break end
  local f2 = io.open(d .. "gps.tle", "r")
  if f2 then f2:close(); DIR = d; break end
end

local tlePath = DIR .. "orbital.tle"
local fcheck = io.open(tlePath, "r")
if not fcheck then tlePath = DIR .. "gps.tle" else fcheck:close() end

local fh = assert(io.open(tlePath, "r"))
local tleText = fh:read("*a")
fh:close()
local TEX = DIR .. "earth-nasa.jpg"

local function julianNoon(year, month, day)
  local a = math.floor((14 - month) / 12)
  local y = year + 4800 - a
  local m = month + 12 * a - 3
  return day + math.floor((153 * m + 2) / 5) + 365 * y + math.floor(y / 4)
       - math.floor(y / 100) + math.floor(y / 400) - 32045
end

local function gmstDeg(jd)
  return (280.46061837 + 360.98564736629 * (jd - 2451545.0)) % 360
end

local function utc(jd)
  local n = math.floor(jd + 0.5)
  local f = jd + 0.5 - n
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
  return string.format("%04d-%02d-%02d %02d:%02d:%02d UTC", year, month, day, h, m, s)
end

local function orbitRadius(n)
  local a = (GM / (n * 2 * math.pi / 86400) ^ 2) ^ (1 / 3)
  return R_EARTH + (a * KM - R_EARTH) * ALT, a
end

local lines = {}
for l in tleText:gmatch("[^\r\n]+") do lines[#lines + 1] = l end

local sats = {}
local i = 1
while i <= #lines - 2 do
  local l1, l2 = lines[i + 1], lines[i + 2]
  if l1 and l2 and l1:sub(1, 1) == "1" and l2:sub(1, 1) == "2" then
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
        name = (lines[i]:match("^%s*(.-)%s*$")) or "UNKNOWN",
        inc = inc, node = node, w = argp, M0 = M0, n = n,
        a = a, alt = akm - 6371,
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

if #sats == 0 then error("no elements found") end
local JD0 = sats[1].jd
for _, s in ipairs(sats) do s.djd = s.jd - JD0 end

local function satAt(s, days)
  local M = (s.M0 + 360 * s.n * (days - s.djd)) % 360
  local u = math.rad(s.w + M)
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

local earth = Sphere(R_EARTH, 0)
earth.col = "#ffffff"
earth.tex = TEX
earth.castShadow = false
earth.collides = false
v:add(earth)

local function getColorForSat(name)
  name = string.upper(name)
  if name:match("^GPS") or name:match("NAVSTAR") then return "#3c9cd0" end
  if name:match("^GLONASS") or name:match("^COSMOS") or name:match("^LUCH") or name:match("KOSMOS") or name:match("URAGAN") then return "#d62828" end
  if name:match("^BEIDOU") or name:match("^BDS") then return "#ffbe0b" end
  if name:match("^GALILEO") then return "#0052b4" end
  if name:match("^GSAT%d") or name:match("^IRNSS") or name:match("^NVS") then return "#138808" end
  if name:match("^QZS") then return "#bc002d" end
  if name:match("^EUTELSAT") then return "#0077b6" end
  if name:match("^STARLINK") then return "#90ee90" end
  if name:match("^ONEWEB") then return "#ff69b4" end
  if name:match("^IRIDIUM") then return "#ffd700" end
  if name:match("^GLOBALSTAR") then return "#87ceeb" end
  if name:match("^ORBCOMM") then return "#20b2aa" end
  if name:match("^ISS") or name:match("ZARYA") or name:match("^TIANGONG") or name:match("^CSS") or name:match("CREW") then return "#ff3333" end
  if name:match("^NOAA") or name:match("^METOP") or name:match("^GOES") or name:match("^FENGYUN") or name:match("^METEOR") or name:match("^SUOMI") then return "#00ced1" end
  if name:match(" R/B$") or name:match(" DEB$") or name:match("^SL-") then return "#666666" end
  return "#cccccc"
end

for _, s in ipairs(sats) do
  s.col = getColorForSat(s.name)
  s.sph = Sphere(0.05, 0)
  s.sph.col = s.col
  s.sph.emission = s.col
  s.sph.castShadow = false
  s.sph.collides = false
  v:add(s.sph)
  if TRAIL_SEG > 0 then
    local step = 2 * math.pi * s.n * (TRAIL_MIN / TRAIL_SEG) / 1440
    local chord = 2 * s.a * math.sin(step / 2)
    s.segs = {}
    for k = 1, TRAIL_SEG do
      local cy = Cylinder(TRAIL_R, chord, 0)
      cy.col = s.col
      cy.emission = s.col
      cy.transparency = 0.6
      cy.castShadow = false
      cy.collides = false
      v:add(cy)
      s.segs[k] = cy
    end
  else
    s.segs = {}
  end
end

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
    local ax, ay = -dy, dx
    local al = math.sqrt(ax * ax + ay * ay)
    q = btQuaternion(btVector3(ax / al, ay / al, 0), math.acos(dz))
  end
  cyl.trans = btTransform(q, btVector3((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2))
end

local now = os.date("!*t")
local days = julianNoon(now.year, now.month, now.day) - 0.5
           + (now.hour * 3600 + now.min * 60 + now.sec) / 86400 - JD0
local BACK = TRAIL_MIN / TRAIL_SEG / 1440

local function place(day)
  earth.trans = btTransform(btQuaternion(YAXIS, math.rad(gmstDeg(JD0 + day))), ORIGIN)
  for _, s in ipairs(sats) do
    local x0, y0, z0 = satAt(s, day)
    s.sph.trans = btTransform(btQuaternion(0, 0, 0, 1), btVector3(x0, y0, z0))
    local px, py, pz = x0, y0, z0
    for k = 1, TRAIL_SEG do
      local x, y, z = satAt(s, day - BACK * k)
      if s.segs[k] then
        stand(s.segs[k], px, py, pz, x, y, z)
      end
      px, py, pz = x, y, z
    end
  end
end

common.setCamera(btVector3(0, 0, 50), btVector3(0, 0, 0), nil, { up = btVector3(0, 1, 0) })
place(days)

local owner = {}
for _, s in ipairs(sats) do
  owner[objectKey(s.sph)] = s
  for _, cy in ipairs(s.segs) do if cy then owner[objectKey(cy)] = s end end
end

local function card(s)
  local px, py, pz = satAt(s, days)
  local r = math.sqrt(px * px + py * py + pz * pz)
  local lat = math.deg(math.asin(py / r))
  local lon = (math.deg(math.atan2(-pz, px)) - gmstDeg(JD0 + days) + 180) % 360 - 180
  return string.format("%s\n%.1f°%s %.1f°%s   %d km alt", s.name,
                       math.abs(lat), lat < 0 and "S" or "N",
                       math.abs(lon), lon < 0 and "W" or "E",
                       math.floor(s.alt + 0.5))
end

v:onHover(function(N, obj, x, y, z)
  local s = owner[objectKey(obj)]
  if not s then return end
  return card(s)
end)

v:preStart(function(N)
  v.statusText = utc(JD0 + days)
  print(string.format("orbital-objects: %d objects from %s", #sats, tlePath))
end)

v:preSim(function(N)
  local speed = tonumber(v:getParam("speed")) or 1 / 60
  days = days + DT * speed / 1440
  place(days)
  v.statusText = utc(JD0 + days)
end)
