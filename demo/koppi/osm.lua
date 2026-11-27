-- OSM Geometry Import for BPP - Augsburg (streaming version)
-- Parses OSM at startup, streams mesh objects only when visible in camera view
local common = require "common"
common.setTiming(1 / 30)

v.pre_sdl = [[
#include "colors.inc"
#include "metals.inc"
#include "glass.inc"
]]

v:addParam("scale", 1.0, 0.1, 10.0, 0.1, "Scale factor")

local floor = Plane(0, 1, 0, 0, 5000)
floor.col = "#1f3f1f"
floor.friction = 1
floor.sdl = [[
  texture {
    pigment { checker color rgb <0.12,0.25,0.12> color rgb <0.14,0.28,0.14> scale 15 }
    finish { ambient 0.18 diffuse 0.65 specular 0.15 roughness 0.05 }
  }
]]
v:add(floor)

-- Streaming parameters.  The OSM data spans roughly 5.6 km, so a range that
-- covers the whole dataset would build every mesh in one frame and stall the
-- OpenGL view.  Only build what is close to, and in front of, the camera --
-- a few objects per frame keeps interaction smooth while the scene fills in.
local streamRange = 1600           -- add objects within this range (units)
local streamMaxPerFrame = 96       -- hard cap on new meshes per frame
local streamMaxMsPerFrame = 4      -- time budget for streaming in one frame
local streamCellSize = 256         -- spatial grid cell size (units)
local streamCosSq = 0.25           -- cos(60 degrees)^2: generous view cone
local streamNearSq = 100 * 100     -- always keep very close objects
local grid = {}                    -- grid cell key -> entries overlapping it

-- Tile support (raster tiles pre-downloaded to tiles/ from tile.openstreetmap.org)
local tile_zoom = 17
local tile_cache = {}
local export_tiles = {}

local function deg2num(lat_deg, lon_deg, zoom)
    local lat_rad = math.rad(lat_deg)
    local n = 2 ^ zoom
    local x = math.floor((lon_deg + 180) / 360 * n)
    local y = math.floor((1 - math.log(math.tan(lat_rad) + 1 / math.cos(lat_rad)) / math.pi) / 2 * n)
    return x, y
end

local function get_tile(z, x, y)
    if not x or not y then return nil end
    local key = z .. "_" .. x .. "_" .. y
    if tile_cache[key] then return tile_cache[key] end
    local fname = "tiles/tile_" .. z .. "_" .. x .. "_" .. y .. ".png"
    local f = io.open(fname, "r")
    if f then
        f:close()
        tile_cache[key] = fname
        export_tiles[key] = {z=z, x=x, y=y}
        return fname
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Mesh creation functions
-- ---------------------------------------------------------------------------

local function makeBoxMesh(w, h, d)
  local m = btTriangleMesh()
  local hw, hh, hd = w/2, h/2, d/2
  local pts = {
    btVector3(-hw, -hh, -hd), btVector3(hw, -hh, -hd), btVector3(hw, hh, -hd), btVector3(-hw, hh, -hd),
    btVector3(-hw, -hh, hd),  btVector3(hw, -hh, hd),  btVector3(hw, hh, hd),  btVector3(-hw, hh, hd)
  }
  local faces = {
    {0,1,2,3}, {4,5,6,7}, {0,1,5,4}, {2,3,7,6}, {1,2,6,5}, {3,0,4,7}
  }
  for _, f in ipairs(faces) do
    local a,b,c,d = pts[f[1]+1], pts[f[2]+1], pts[f[3]+1], pts[f[4]+1]
    m:addTriangle(a,b,c,true); m:addTriangle(a,c,d,true)
  end
  return m
end

-- Create extruded building polygon mesh from XZ footprint points
-- Uses ear-clipping triangulation to match arbitrary OSM polygon footprints
local function makeBuildingMesh(pts, height)
  local m = btTriangleMesh()
  local n = #pts
  if n < 3 then return m end

  local xy = {}
  for i = 1, n do xy[i] = {x = pts[i].x, z = pts[i].z} end

  local area = 0
  for i = 1, n do
    local j = i % n + 1
    area = area + xy[i].x * xy[j].z - xy[j].x * xy[i].z
  end
  if area < 0 then
    local rev = {}
    for i = 1, n do rev[i] = xy[n - i + 1] end
    xy = rev
  end

  local remaining = {}
  for i = 1, n do remaining[i] = i end
  local triangles = {}
  local maxIter = n * 10
  local iter = 0

  while #remaining > 3 and iter < maxIter do
    iter = iter + 1
    local mlen = #remaining
    local found = false

    for vi = 1, mlen do
      local pi = remaining[(vi - 2 + mlen - 1) % mlen + 1]
      local ci = remaining[vi]
      local ni = remaining[(vi % mlen) + 1]

      local ax, az = xy[pi].x, xy[pi].z
      local bx, bz = xy[ci].x, xy[ci].z
      local cx, cz = xy[ni].x, xy[ni].z

      local cross = (bx - ax) * (cz - az) - (bz - az) * (cx - ax)
      if cross > 0 then
        local isEar = true
        for ki = 1, mlen do
          local k = remaining[ki]
          if k ~= pi and k ~= ci and k ~= ni then
            local kx, kz = xy[k].x, xy[k].z
            local d00 = (cx - ax) * (cx - ax) + (cz - az) * (cz - az)
            local d01 = (cx - ax) * (bx - ax) + (cz - az) * (bz - az)
            local d11 = (bx - ax) * (bx - ax) + (bz - az) * (bz - az)
            local d20 = (kx - ax) * (cx - ax) + (kz - az) * (cz - az)
            local d21 = (kx - ax) * (bx - ax) + (kz - az) * (bz - az)
            local denom = d00 * d11 - d01 * d01
            if math.abs(denom) > 1e-10 then
              local v = (d11 * d20 - d01 * d21) / denom
              local w = (d00 * d21 - d01 * d20) / denom
              local u = 1 - v - w
              if u > 1e-6 and v > 1e-6 and w > 1e-6 then
                isEar = false
                break
              end
            end
          end
        end

        if isEar then
          table.insert(triangles, {pi, ci, ni})
          table.remove(remaining, vi)
          found = true
          break
        end
      end
    end

    if not found then break end
  end

  if #remaining == 3 then
    table.insert(triangles, remaining)
  end

  local function addTri(i1, i2, i3, y)
    m:addTriangle(
      btVector3(pts[i1].x, y, pts[i1].z),
      btVector3(pts[i2].x, y, pts[i2].z),
      btVector3(pts[i3].x, y, pts[i3].z),
      true)
  end

  for _, t in ipairs(triangles) do addTri(t[1], t[2], t[3], 0) end
  for _, t in ipairs(triangles) do addTri(t[1], t[3], t[2], height) end
  for i = 1, n do
    local j = i % n + 1
    local p1 = pts[i]; local p2 = pts[j]
    m:addTriangle(btVector3(p1.x, 0, p1.z), btVector3(p2.x, 0, p2.z), btVector3(p1.x, height, p1.z), true)
    m:addTriangle(btVector3(p2.x, 0, p2.z), btVector3(p2.x, height, p2.z), btVector3(p1.x, height, p1.z), true)
  end

  return m
end

local function makeSphereMesh(r, subdiv)
  local m = btTriangleMesh()
  local t = (1 + math.sqrt(5)) / 2
  local pts = {
    btVector3(-1, t, 0), btVector3(1, t, 0), btVector3(-1, -t, 0), btVector3(1, -t, 0),
    btVector3(0, -1, t), btVector3(0, 1, t), btVector3(0, -1, -t), btVector3(0, 1, -t),
    btVector3(t, 0, -1), btVector3(t, 0, 1), btVector3(-t, 0, -1), btVector3(-t, 0, 1)
  }
  for i=1,#pts do pts[i] = pts[i]:normalized() * r end
  local faces = {
    {0,11,5}, {0,5,1}, {0,1,7}, {0,7,10}, {0,10,11},
    {1,5,9}, {5,11,4}, {11,10,2}, {10,7,6}, {7,1,8},
    {3,9,4}, {3,4,2}, {3,2,6}, {3,6,8}, {3,8,9},
    {4,9,5}, {2,4,11}, {6,2,10}, {8,6,7}, {9,8,1}
  }
  for _, f in ipairs(faces) do
    m:addTriangle(pts[f[1]+1], pts[f[2]+1], pts[f[3]+1], true)
  end
  return m
end

-- Create flat extruded polygon mesh from XZ points (fan triangulation, good for convex shapes)
local function makePolygonMesh(pts, height)
  local m = btTriangleMesh()
  local n = #pts
  if n < 3 then return m end
  local cx, cz = 0, 0
  for i = 1, n do cx = cx + pts[i].x; cz = cz + pts[i].z end
  cx = cx / n; cz = cz / n
  for i = 1, n do
    local j = i % n + 1
    m:addTriangle(btVector3(cx, 0, cz), btVector3(pts[i].x, 0, pts[i].z), btVector3(pts[j].x, 0, pts[j].z), true)
  end
  for i = 1, n do
    local j = i % n + 1
    m:addTriangle(btVector3(cx, height, cz), btVector3(pts[j].x, height, pts[j].z), btVector3(pts[i].x, height, pts[i].z), true)
  end
  for i = 1, n do
    local j = i % n + 1
    local p1 = pts[i]; local p2 = pts[j]
    m:addTriangle(btVector3(p1.x, 0, p1.z), btVector3(p2.x, 0, p2.z), btVector3(p1.x, height, p1.z), true)
    m:addTriangle(btVector3(p2.x, 0, p2.z), btVector3(p2.x, height, p2.z), btVector3(p1.x, height, p1.z), true)
  end
  return m
end

-- Create road mesh (polygon strip following OSM polyline path)
local function makeRoadMesh(pts, width, height)
  local m = btTriangleMesh()
  local n = #pts
  if n < 2 then return m end
  local hw = width / 2
  local h = height or 0.04
  for i = 1, n - 1 do
    local p1 = pts[i]
    local p2 = pts[i + 1]
    local dx = p2.x - p1.x
    local dz = p2.z - p1.z
    local len = math.sqrt(dx*dx + dz*dz)
    if len > 0.001 then
      local ux = dx / len
      local uz = dz / len
      local px = -uz * hw
      local pz = ux * hw
      local v1 = btVector3(p1.x + px, h, p1.z + pz)
      local v2 = btVector3(p1.x - px, h, p1.z - pz)
      local v3 = btVector3(p2.x - px, h, p2.z - pz)
      local v4 = btVector3(p2.x + px, h, p2.z + pz)
      m:addTriangle(v1, v2, v3, true)
      m:addTriangle(v1, v3, v4, true)
    end
  end
  return m
end

-- ---------------------------------------------------------------------------
-- Load and parse Augsburg OSM (parse only, no mesh creation yet)
-- ---------------------------------------------------------------------------

local paths = {"demo/koppi/augsburg.osm", "/home/koppi/bpp/demo/koppi/augsburg.osm", "augsburg.osm"}
local osmData = nil
for _, p in ipairs(paths) do
  local f = io.open(p, "r")
  if f then
    osmData = f:read("*a")
    f:close()
    print("OSM: Loaded " .. p)
    break
  end
end

local function parseTags(str)
  local tags = {}
  for k,v in str:gmatch('k="([^"]+)"%s+v="([^"]+)"') do
    tags[k] = v
  end
  return tags
end

if osmData then
  local nodes = {}
  local nodeCount = 0
  for _ in osmData:gmatch("<node%s") do nodeCount = nodeCount + 1 end

  -- The usual OSM attribute order (lat before lon) can be matched with one
  -- cheap gmatch; only if that misses nodes is the reversed order scanned.
  local parsedNodes = 0
  for id, lat, lon in osmData:gmatch('id="([%d%-]+)"[^>]+lat="([%d%.%-]+)"[^>]+lon="([%d%.%-]+)"') do
    nodes[id] = {lat = tonumber(lat), lon = tonumber(lon)}
    parsedNodes = parsedNodes + 1
  end
  if parsedNodes < nodeCount then
    for id, lon, lat in osmData:gmatch('id="([%d%-]+)"[^>]+lon="([%d%.%-]+)"[^>]+lat="([%d%.%-]+)"') do
      if not nodes[id] then nodes[id] = {lat = tonumber(lat), lon = tonumber(lon)} end
    end
  end

  local baseLat,baseLon = 48.365, 10.9
  local scale = 111000
  local function raw_proj(lat,lon)
    return (lon-baseLon)*scale*math.cos(math.rad(baseLat)), -(lat-baseLat)*scale
  end

  -- Compute center of all node positions to center OSM data at world origin
  local cminx, cmaxx, cminz, cmaxz = math.huge, -math.huge, math.huge, -math.huge
  for id, n in pairs(nodes) do
    local x, z = raw_proj(n.lat, n.lon)
    if x < cminx then cminx = x end
    if x > cmaxx then cmaxx = x end
    if z < cminz then cminz = z end
    if z > cmaxz then cmaxz = z end
  end
  local centerX = (cminx + cmaxx) / 2
  local centerZ = (cminz + cmaxz) / 2

  local function proj(lat,lon)
    local x, z = raw_proj(lat, lon)
    return x - centerX, z - centerZ
  end

  -- Convert projected meters back to lat/lon (for tile lookup)
  local function proj_to_latlon(px, pz)
    local lat = baseLat - pz / scale
    local lon = baseLon + px / (scale * math.cos(math.rad(baseLat)))
    return lat, lon
  end

  -- Collect all candidate entries (mesh data created later in streamAdd)
  local entryCount = 0

  local function makeEntry(entryType, pts, height, width, col, collides, name, extra, b)
    -- Callers that already have the projected bounds pass them in, rather
    -- than making makeEntry walk the same points a second time.
    local minx, maxx, minz, maxz
    if b then
      minx, maxx, minz, maxz = b[1], b[2], b[3], b[4]
    else
      minx, maxx = pts[1].x, pts[1].x
      minz, maxz = pts[1].z, pts[1].z
      for i = 2, #pts do
        local x, z = pts[i].x, pts[i].z
        if x < minx then minx = x end
        if x > maxx then maxx = x end
        if z < minz then minz = z end
        if z > maxz then maxz = z end
      end
    end
    local entry = {
      type = entryType,
      pts = pts,
      height = height,
      width = width,
      col = col,
      collides = collides,
      name = name,
      centerX = (minx + maxx) / 2,
      centerY = (height or 0) * 0.5,
      centerZ = (minz + maxz) / 2,
      minx = minx, maxx = maxx, minz = minz, maxz = maxz,
    }
    if extra then for k, v in pairs(extra) do entry[k] = v end end
    entryCount = entryCount + 1

    -- Index by every grid cell the bounding box touches, so a long road is
    -- still found when only part of it is near the camera.
    local gx0, gx1 = math.floor(minx / streamCellSize), math.floor(maxx / streamCellSize)
    local gz0, gz1 = math.floor(minz / streamCellSize), math.floor(maxz / streamCellSize)
    for gx = gx0, gx1 do
      for gz = gz0, gz1 do
        local key = gx .. ":" .. gz
        local cell = grid[key]
        if not cell then cell = {}; grid[key] = cell end
        cell[#cell + 1] = entry
      end
    end
    return entry
  end

  -- Classify ways in one pass.  Four full gmatches over a 92 MB file were the
  -- biggest part of startup; each way is scanned for tags and node refs once.
  local buildingCount, rcount, wcount, pcount = 0, 0, 0, 0

  local function projectedPoints(way)
    local xs, zs = {}, {}
    for ref in way:gmatch('<nd%s+ref="([%d]+)"') do
      local n = nodes[ref]
      if n then
        local x, z = proj(n.lat, n.lon)
        xs[#xs+1] = x; zs[#zs+1] = z
      end
    end
    return xs, zs
  end

  local function bounds(xs, zs)
    local minx, maxx, minz, maxz = xs[1], xs[1], zs[1], zs[1]
    for i = 2, #xs do
      if xs[i] < minx then minx = xs[i] end
      if xs[i] > maxx then maxx = xs[i] end
    end
    for i = 2, #zs do
      if zs[i] < minz then minz = zs[i] end
      if zs[i] > maxz then maxz = zs[i] end
    end
    return minx, maxx, minz, maxz
  end

  local function toPoints(xs, zs)
    local pts = {}
    for i = 1, #xs do pts[i] = btVector3(xs[i], 0, zs[i]) end
    return pts
  end

  for way in osmData:gmatch("<way%s[^>]+>.-</way>") do
    local tags = parseTags(way)

    if tags.building and not tags["building:part"] then
      local xs, zs = projectedPoints(way)
      if #xs >= 3 and #zs >= 3 then
        local minx, maxx, minz, maxz = bounds(xs, zs)
        local w, d = maxx - minx, maxz - minz
        if w > 1 and d > 1 and w < 400 and d < 400 then
          local height = tonumber(tags["height"])
          if not height then
            local levels = tonumber(tags["building:levels"]) or 1
            height = levels * 3.5 + math.random() * 3
          end
          local btype = tags.building
          local col = "#3a3f45"
          if btype == "residential" then col = "#5a4a3a"
          elseif btype == "commercial" then col = "#4a4a5a"
          elseif btype == "industrial" then col = "#3a3a3a"
          elseif btype == "house" then col = "#6a5a4a"
          elseif btype == "apartments" then col = "#4a5a4a"
          elseif btype == "school" then col = "#5a5a3a"
          elseif btype == "hospital" then col = "#5a3a3a"
          elseif btype == "church" then col = "#5a3a5a" end
          makeEntry("building", toPoints(xs, zs), height, nil, col, false,
            tags.name or "Building",
            {btype = btype, levels = tags["building:levels"],
             baseZ = tonumber(tags["min_height"]) or 0},
            {minx, maxx, minz, maxz})
          buildingCount = buildingCount + 1
        end
      end
    end

    if tags.highway then
      local xs, zs = projectedPoints(way)
      if #xs >= 2 then
        local htype = tags.highway
        local rcol = "#1a1a1a"
        local width = 6
        local rheight = tonumber(tags["height"]) or 0.04
        if htype == "motorway" then rcol = "#0a0a0a"; width = 16
        elseif htype == "trunk" then rcol = "#101010"; width = 12
        elseif htype == "primary" then rcol = "#151515"; width = 10
        elseif htype == "secondary" then rcol = "#1a1a1a"; width = 8
        elseif htype == "tertiary" then rcol = "#1e1e1e"; width = 7
        elseif htype == "residential" then rcol = "#252525"; width = 6
        elseif htype == "service" then rcol = "#2a2a2a"; width = 5
        elseif htype == "footway" or htype == "path" or htype == "cycleway" then
          rcol = "#3a3a3a"; width = 3
        end
        makeEntry("road", toPoints(xs, zs), rheight, width, rcol, true,
          tags.name or "Road", {htype = htype})
        rcount = rcount + 1
      end
    end

    if tags.natural == "water" or tags.waterway or tags.landuse == "water" then
      local xs, zs = projectedPoints(way)
      if #xs >= 3 and #zs >= 3 then
        local minx, maxx, minz, maxz = bounds(xs, zs)
        local ww, dd = maxx - minx, maxz - minz
        if ww > 5 and dd > 5 and ww < 500 then
          makeEntry("water", toPoints(xs, zs), tonumber(tags["height"]) or 0.02,
            nil, "#1a4d73", false, "Water", nil, {minx, maxx, minz, maxz})
          wcount = wcount + 1
        end
      end
    end

    if tags.leisure == "park" or tags.landuse == "forest" or tags.natural == "wood" then
      local xs, zs = projectedPoints(way)
      if #xs >= 3 and #zs >= 3 then
        local minx, maxx, minz, maxz = bounds(xs, zs)
        local ww, dd = maxx - minx, maxz - minz
        if ww > 10 and dd > 10 and ww < 1000 then
          makeEntry("park", toPoints(xs, zs), tonumber(tags["height"]) or 0.01,
            nil, "#2a5a2a", false, "Park", nil, {minx, maxx, minz, maxz})
          pcount = pcount + 1
        end
      end
    end
  end

  print(string.format("OSM: Parsed %d entries (%d buildings, %d roads, %d water, %d parks)",
    entryCount, buildingCount, rcount, wcount, pcount))

  -- Streaming state
  local addedObjects = {}   -- entry -> Mesh object

  -- Cheap range + view-cone test.  Everything is compared in squared form;
  -- only the normalized camera direction needs a square root per frame.
  local function inView(entry, cx, cy, cz, fx, fy, fz, rangeSq)
    local ex = entry.centerX - cx
    local ey = entry.centerY - cy
    local ez = entry.centerZ - cz
    local distSq = ex*ex + ey*ey + ez*ez
    if distSq > rangeSq then return false end
    local along = ex*fx + ey*fy + ez*fz
    if along <= 0 then return distSq < streamNearSq end
    return along*along >= streamCosSq * distSq
  end

  -- streamAdd: create mesh object from entry and add to world
  local function streamAdd(entry)
    local o
    if entry.type == "building" then
      local baseZ = entry.baseZ or 0
      local meshData = makeBuildingMesh(entry.pts, entry.height)
      local shape = btGImpactMeshShape(meshData)
      shape:updateBound()
      local ms = btDefaultMotionState(common.transform(0, 0, 0, 0, baseZ + entry.height/2, 0))
      local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
      o = Mesh()
      o.mesh = meshData
      o.shape = shape
      o.body = body
      o.mass = 0
      o.pos = btVector3(0, baseZ + entry.height/2, 0)
      o.col = entry.col
      o.collides = false   -- buildings do not collide in physics
      -- Tile texture from raster tiles
      local blat, blon = proj_to_latlon(entry.centerX, entry.centerZ)
      local tx, ty = deg2num(blat, blon, tile_zoom)
      local tpath = get_tile(tile_zoom, tx, ty)
      if tpath then
        local tkey = tile_zoom .. "_" .. tx .. "_" .. ty
        o.sdl = string.format("texture { pigment { uv_mapping image_map { \"%s.png\" interpolate 2 } } scale <1,-1,1> translate <0,1,0> } finish { ambient 0.12 diffuse 0.65 specular 0.25 roughness 0.02 } }", tkey)
      else
        o.sdl = [[ texture { pigment { color rgb <0.12,0.12,0.14> } finish { ambient 0.12 diffuse 0.65 specular 0.25 roughness 0.02 } } ]]
      end
      o.hoverText = entry.name .. " (" .. entry.btype .. (entry.levels and ", " .. entry.levels .. " levels" or "") .. ")"
    elseif entry.type == "road" then
      local rheight = entry.height or 0.04
      local meshData = makeRoadMesh(entry.pts, entry.width, rheight)
      local shape = btGImpactMeshShape(meshData)
      shape:updateBound()
      local ms = btDefaultMotionState(common.transform(0, 0, 0, 0, rheight/2, 0))
      local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
      o = Mesh()
      o.mesh = meshData
      o.shape = shape
      o.body = body
      o.mass = 0
      o.pos = btVector3(0, rheight/2, 0)
      o.col = entry.col
      o.collides = false   -- roads are decoration; keep them out of Bullet
      o.sdl = [[ texture { pigment { color rgb <0.12,0.12,0.14> } finish { ambient 0.12 diffuse 0.65 specular 0.25 roughness 0.02 } } ]]
      o.hoverText = (entry.name or "Road") .. " (" .. entry.htype .. ")"
    elseif entry.type == "water" then
      local wheight = entry.height or 0.02
      local meshData = makePolygonMesh(entry.pts, wheight)
      local shape = btGImpactMeshShape(meshData)
      shape:updateBound()
      local ms = btDefaultMotionState(common.transform(0, 0, 0, 0, wheight/2, 0))
      local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
      o = Mesh()
      o.mesh = meshData
      o.shape = shape
      o.body = body
      o.mass = 0
      o.pos = btVector3(0, wheight/2, 0)
      o.col = entry.col
      o.collides = false
      o.sdl = [[ texture { pigment { color rgb <0.12,0.35,0.5> } finish { ambient 0.25 diffuse 0.4 specular 0.9 roughness 0.01 reflection 0.35 } } ]]
    elseif entry.type == "park" then
      local pheight = entry.height or 0.01
      local meshData = makePolygonMesh(entry.pts, pheight)
      local shape = btGImpactMeshShape(meshData)
      shape:updateBound()
      local ms = btDefaultMotionState(common.transform(0, 0, 0, 0, pheight/2, 0))
      local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
      o = Mesh()
      o.mesh = meshData
      o.shape = shape
      o.body = body
      o.mass = 0
      o.pos = btVector3(0, pheight/2, 0)
      o.col = entry.col
      o.collides = false
      o.sdl = [[ texture { pigment { color rgb <0.15,0.35,0.15> } finish { ambient 0.2 diffuse 0.7 } } ]]
    end

    if o then
      o.entry = entry
      v:add(o)
      addedObjects[entry] = o
    end
    return o
  end

  -- streamUpdate: runs in preDraw, i.e. once per drawn frame, so panning the
  -- OpenGL view streams geometry even when the simulation is paused.  Objects
  -- stay in the world once built: rebuilding them on every pass would cost far
  -- more than the few display lists they occupy, and the renderer culls them
  -- when they leave the view.
  local function streamUpdate()
    local cam = v.cam
    if not cam then return end
    local cp, cd = cam.pos, cam.dir
    if not cp or not cd then return end
    local cx, cy, cz = cp.x, cp.y, cp.z
    local fx, fy, fz = cd.x, cd.y, cd.z
    local len = math.sqrt(fx*fx + fy*fy + fz*fz)
    if len < 1e-6 then return end
    fx, fy, fz = fx / len, fy / len, fz / len

    -- Zooming out should reveal more of the city instead of an empty plane.
    local viewRange = streamRange + math.max(0, cy - 100)
    local rangeSq = viewRange * viewRange
    local started = os.clock()
    local added = 0
    local gcx = math.floor(cx / streamCellSize)
    local gcz = math.floor(cz / streamCellSize)
    local maxRing = math.ceil(viewRange / streamCellSize)

    -- Visit grid cells nearest the camera first, so the visible area is
    -- filled from the inside out without sorting a candidate list.
    for ring = 0, maxRing do
      for ox = -ring, ring do
        for oz = -ring, ring do
          if ring == 0 or math.max(math.abs(ox), math.abs(oz)) == ring then
            local cell = grid[(gcx + ox) .. ":" .. (gcz + oz)]
            if cell then
              for i = 1, #cell do
                local entry = cell[i]
                if not addedObjects[entry] and inView(entry, cx, cy, cz, fx, fy, fz, rangeSq) then
                  streamAdd(entry)
                  added = added + 1
                  if added >= streamMaxPerFrame or
                     (os.clock() - started) * 1000 >= streamMaxMsPerFrame then
                    return
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  v:preDraw(streamUpdate)

  -- Camera and status
  common.setCamera(btVector3(200, 150, 200), btVector3(0, 20, 0), math.rad(50))
  v.statusText = "Augsburg OSM streaming"
  v:onHover(function(N, obj, x, y, z)
    if obj and obj.entry then
      v.statusText = obj.entry.type .. " at " .. string.format("%.0f,%.0f", obj.entry.centerX, obj.entry.centerZ)
    elseif obj and obj.hoverText then
      v.statusText = obj.hoverText
    end
  end)
  v:preStart(function()
    print("Augsburg OSM streaming running")
  end)

  print("OSM: Streaming import complete")
else
  print("OSM: No data found")
end

print("OSM: Import complete")
