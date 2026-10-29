--
-- OSM Geometry Import for BPP - Augsburg
--
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

local function hexToRGB(col)
  if type(col) ~= "string" then return "0.3,0.32,0.35" end
  local r,g,b = col:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return "0.3,0.32,0.35" end
  return string.format("%g,%g,%g", tonumber(r,16)/255, tonumber(g,16)/255, tonumber(b,16)/255)
end

-- Create box mesh
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

-- Create sphere mesh (icosphere approximation)
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

-- Create road mesh (flat rectangular strip)
local function makeRoadMesh(len, width, height)
  local m = btTriangleMesh()
  local hw, hh = width/2, height/2
  local hl = len/2
  local pts = {
    btVector3(-hl, -hh, -hw), btVector3(hl, -hh, -hw), btVector3(hl, hh, -hw), btVector3(-hl, hh, -hw),
    btVector3(-hl, -hh, hw),  btVector3(hl, -hh, hw),  btVector3(hl, hh, hw),  btVector3(-hl, hh, hw)
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

local function addBoxMesh(x,y,z,w,h,d,col)
  local meshData = makeBoxMesh(w,h,d)
  local shape = btGImpactMeshShape(meshData)
  shape:updateBound()
  local ms = btDefaultMotionState(common.transform(0, 0, 0, x, y, z))
  local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
  local o = Mesh()
  o.mesh = meshData
  o.shape = shape
  o.body = body
  o.mass = 0
  o.pos = btVector3(x,y,z)
  o.col = col or "#3a3f45"
  o.friction = 0.8
  o.collides = true
  o.hoverText = "Building"
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(o.col) .. [[> }
      finish { ambient 0.08 diffuse 0.6 specular 0.4 roughness 0.01 reflection 0.05 }
    }
  ]]
  v:add(o)
  return o
end

local function addSphereMesh(x,y,z,r,col)
  local meshData = makeSphereMesh(r, 1)
  local shape = btGImpactMeshShape(meshData)
  shape:updateBound()
  local ms = btDefaultMotionState(common.transform(0, 0, 0, x, y, z))
  local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
  local o = Mesh()
  o.mesh = meshData
  o.shape = shape
  o.body = body
  o.mass = 0
  o.pos = btVector3(x,y,z)
  o.col = col or "#3a3f45"
  o.collides = true
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(o.col) .. [[> }
      finish { ambient 0.15 diffuse 0.7 }
    }
  ]]
  v:add(o)
  return o
end

local function addBox(x,y,z,w,h,d,col)
  return addBoxMesh(x,y,z,w,h,d,col)
end

local function addRoad(x,y,z,w,d)
  local o = Cube(w,0.08,d,0)
  o.pos = btVector3(x,y,z)
  o.col = "#1a1a1a"
   o.friction = 1
   o.collides = true
   o.hoverText = "Road"
  o.sdl = [[
    texture {
      pigment { color rgb <0.12,0.12,0.14> }
      finish { ambient 0.12 diffuse 0.65 specular 0.25 roughness 0.02 }
    }
  ]]
  v:add(o)
  return o
end

-- Load and parse Augsburg OSM
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

-- Parse all tags from ways
local function parseTags(str)
  local tags = {}
  for k,v in str:gmatch('k="([^"]+)"%s+v="([^"]+)"') do
    tags[k] = v
  end
  return tags
end

if osmData then
  local nodes = {}
  for id,lat,lon in osmData:gmatch('id="([%d%-]+)"[^>]+lat="([%d%.%-]+)"[^>]+lon="([%d%.%-]+)"') do
    nodes[id] = {lat=tonumber(lat), lon=tonumber(lon)}
  end
  for id,lon,lat in osmData:gmatch('id="([%d%-]+)"[^>]+lon="([%d%.%-]+)"[^>]+lat="([%d%.%-]+)"') do
    if not nodes[id] then nodes[id] = {lat=tonumber(lat), lon=tonumber(lon)} end
  end
  local baseLat,baseLon=48.365,10.9
  local function proj(lat,lon)
    local scale=111000
    return (lon-baseLon)*scale*math.cos(math.rad(baseLat)), -(lat-baseLat)*scale
  end
  local count=0
  for way in osmData:gmatch("<way%s[^>]+>.-</way>") do
    local tags = parseTags(way)
    if tags.building and not tags["building:part"] then
      local xs={} local zs={}
      for ref in way:gmatch('<nd%s+ref="([%d]+)"') do
        local n=nodes[ref]
        if n then
          local x,z=proj(n.lat,n.lon)
          xs[#xs+1]=x
          zs[#zs+1]=z
        end
      end
      if #xs>=3 and #zs>=3 then
        local minx,maxx,minz,maxz=xs[1],xs[1],zs[1],zs[1]
        for i=2,#xs do
          if xs[i]<minx then minx=xs[i] end
          if xs[i]>maxx then maxx=xs[i] end
        end
        for i=2,#zs do
          if zs[i]<minz then minz=zs[i] end
          if zs[i]>maxz then maxz=zs[i] end
        end
        local w = maxx-minx
        local d = maxz-minz
        -- Height from building:levels or building:height or random
        local levels = tonumber(tags["building:levels"]) or 1
        local height = tonumber(tags["building:height"])
        if not height then
          height = levels * 3.5 + math.random() * 3
        end
        -- Color by building type
        local btype = tags.building
        local col = "#3a3f45"
        if btype == "residential" then col = "#5a4a3a"
        elseif btype == "commercial" then col = "#4a4a5a"
        elseif btype == "industrial" then col = "#3a3a3a"
        elseif btype == "house" then col = "#6a5a4a"
        elseif btype == "apartments" then col = "#4a5a4a"
        elseif btype == "school" then col = "#5a5a3a"
        elseif btype == "hospital" then col = "#5a3a3a"
        elseif btype == "church" then col = "#5a3a5a"
        end
        if w>1 and d>1 and w<400 and d<400 then
          local o = addBox((minx+maxx)/2,height/2,(minz+maxz)/2,w,d,height,col)
          local name = tags.name or "Building"
          o.hoverText = name .. " (" .. btype .. (tags["building:levels"] and ", " .. tags["building:levels"] .. " levels" or "") .. ")"
          count=count+1
        end
      end
    end
  end
  print(string.format("OSM: Rendered %d buildings from Augsburg", count))
  
  -- Roads with highway type
  local rcount=0
  for way in osmData:gmatch("<way%s[^>]+>.-</way>") do
    local tags = parseTags(way)
    if tags.highway then
      local refs={}
      for ref in way:gmatch('<nd%s+ref="([%d]+)"') do refs[#refs+1]=ref end
      if #refs>=2 then
        for j=1,#refs-1 do
          local n1,n2=nodes[refs[j]],nodes[refs[j+1]]
          if n1 and n2 then
            local x1,z1=proj(n1.lat,n1.lon); local x2,z2=proj(n2.lat,n2.lon)
            local mx,mz=(x1+x2)/2,(z1+z2)/2
            local len=math.sqrt((x2-x1)^2+(z2-z1)^2)
            if len>3 and len<300 then
              local angle = math.atan2(x2-x1, z2-z1)
              local rname = tags.name or "Road"
              local htype = tags.highway
              local rcol = "#1a1a1a"
              local width = 8
              local height = 0.12
              if htype == "motorway" then rcol = "#0a0a0a"; width = 16
              elseif htype == "trunk" then rcol = "#101010"; width = 12
              elseif htype == "primary" then rcol = "#151515"; width = 10
              elseif htype == "secondary" then rcol = "#1a1a1a"; width = 8
              elseif htype == "tertiary" then rcol = "#1e1e1e"; width = 7
              elseif htype == "residential" then rcol = "#252525"; width = 6
              elseif htype == "service" then rcol = "#2a2a2a"; width = 5
              elseif htype == "footway" or htype == "path" or htype == "cycleway" then
                rcol = "#3a3a3a"; width = 3; height = 0.08
              end
              local meshData = makeRoadMesh(len, width, height)
              local shape = btGImpactMeshShape(meshData)
              shape:updateBound()
              local ms = btDefaultMotionState(common.transform(0, angle, 0, mx, height/2, mz))
              local body = btRigidBody(0, ms, shape, btVector3(0,0,0))
              local rw = Mesh()
              rw.mesh = meshData
              rw.shape = shape
              rw.body = body
              rw.mass = 0
              rw.pos = btVector3(mx, height/2, mz)
              rw.rot = common.quat(0, angle, 0)
              rw.hoverText = rname .. " (" .. htype .. ")"
              rw.col = rcol
              rw.collides = true
              rw.sdl = [[ texture { pigment { color rgb <0.12,0.12,0.14> } finish { ambient 0.12 diffuse 0.65 specular 0.25 roughness 0.02 } } ]]
              v:add(rw); rcount=rcount+1
            end
          end
        end
      end
    end
  end
  print(string.format("OSM: Rendered %d road segments", rcount))
  
  -- Water
  local wcount=0
  for way in osmData:gmatch("<way%s[^>]+>.-</way>") do
    local tags = parseTags(way)
    if tags.natural == "water" or tags.waterway or tags.landuse == "water" then
      local xs={} local zs={}
      for ref in way:gmatch('<nd%s+ref="([%d]+)"') do
        local n=nodes[ref]
        if n then local x,z=proj(n.lat,n.lon); xs[#xs+1]=x; zs[#zs+1]=z end
      end
      if #xs>=3 and #zs>=3 then
        local minx,maxx,minz,maxz=xs[1],xs[1],zs[1],zs[1]
        for i=2,#xs do if xs[i]<minx then minx=xs[i] end if xs[i]>maxx then maxx=xs[i] end end
        for i=2,#zs do if zs[i]<minz then minz=zs[i] end if zs[i]>maxz then maxz=zs[i] end end
        local ww,dd=maxx-minx,maxz-minz
        if ww>5 and dd>5 and ww<500 then
          local wat=Cube(ww,0.02,dd,0)
          wat.pos=btVector3((minx+maxx)/2,0.01,(minz+maxz)/2)
          wat.col="#1a4d73"; wat.collides=false
          wat.sdl=[[ texture { pigment { color rgb <0.12,0.35,0.5> } finish { ambient 0.25 diffuse 0.4 specular 0.9 roughness 0.01 reflection 0.35 } } ]]
          v:add(wat); wcount=wcount+1
        end
      end
    end
  end
  print(string.format("OSM: Rendered %d water areas", wcount))
  
  -- Parks/Forests
  local pcount=0
  for way in osmData:gmatch("<way%s[^>]+>.-</way>") do
    local tags = parseTags(way)
    if tags.leisure == "park" or tags.landuse == "forest" or tags.natural == "wood" then
      local xs={} local zs={}
      for ref in way:gmatch('<nd%s+ref="([%d]+)"') do
        local n=nodes[ref]
        if n then local x,z=proj(n.lat,n.lon); xs[#xs+1]=x; zs[#zs+1]=z end
      end
      if #xs>=3 and #zs>=3 then
        local minx,maxx,minz,maxz=xs[1],xs[1],zs[1],zs[1]
        for i=2,#xs do if xs[i]<minx then minx=xs[i] end if xs[i]>maxx then maxx=xs[i] end end
        for i=2,#zs do if zs[i]<minz then minz=zs[i] end if zs[i]>maxz then maxz=zs[i] end end
        local ww,dd=maxx-minx,maxz-minz
        if ww>10 and dd>10 and ww<1000 then
          -- Add grass ground
          local grass=Cube(ww,0.01,dd,0)
          grass.pos=btVector3((minx+maxx)/2,0.005,(minz+maxz)/2)
          grass.col="#2a5a2a"; grass.collides=false
          grass.sdl=[[ texture { pigment { color rgb <0.15,0.35,0.15> } finish { ambient 0.2 diffuse 0.7 } } ]]
          v:add(grass)
          -- Add trees in park
          for i=1,math.min(30, math.floor(ww*dd/2000)) do
            local tx = minx + math.random()*ww
            local tz = minz + math.random()*dd
            local trunk = Cube(1.5, 6, 1.5, 0)
            trunk.pos = btVector3(tx, 3, tz); trunk.col = "#4a3020"; trunk.collides = true
            trunk.sdl = [[ texture { pigment { color rgb <0.3,0.2,0.12> } finish { ambient 0.1 diffuse 0.6 } } ]]
            v:add(trunk)
            local crown = Sphere(4 + math.random()*3, 0)
            crown.pos = btVector3(tx, 8 + math.random()*4, tz); crown.col = "#1a4a1a"; crown.collides = true
            crown.sdl = [[ texture { pigment { color rgb <0.1,0.3,0.1> } finish { ambient 0.15 diffuse 0.7 } } ]]
            v:add(crown)
          end
          pcount=pcount+1
        end
      end
    end
  end
  print(string.format("OSM: Rendered %d park/forest areas", pcount))
else
  print("OSM: No data found")
end

-- Data center system at center of town
local dc1 = addBox(0, 6, 0, 60, 12, 40, "#2a3a5a")
dc1.hoverText = "Data Center"
local dc2 = addBox(0, 14, 0, 50, 4, 30, "#1a2a4a")
dc2.hoverText = "Data Center"

local sun = Sphere(20, 0)
sun.pos = btVector3(500, 400, -800)
sun.col = "#ffd93d"
sun.emission = "#ffd93d"
sun.collides = false
sun.sdl = [[ texture { pigment { color rgb <1.0,0.85,0.24> } finish { ambient 0.9 diffuse 0.15 specular 0.9 roughness 0.001 emission 1.0 } } ]]
v:add(sun)

common.setCamera(btVector3(200, 150, 200), btVector3(0, 20, 0), math.rad(50))
v.statusText = "Augsburg, Germany - OpenStreetMap data imported into BPP"
v:onHover(function(N, obj, x, y, z)
  if obj and obj.hoverText then v.statusText = obj.hoverText end
end)
v:preStart(function()
  print("Augsburg OSM visualization running")
end)
