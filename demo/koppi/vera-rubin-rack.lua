--
-- NVIDIA Vera Rubin virtual datacenter
--
-- An enclosed AI datacenter room housing 8 NVIDIA Vera Rubin NVL72 racks
-- (two facing rows of four).  Each NVL72 has 72 Rubin GPUs and 288 GB of
-- HBM4 per GPU (20.7 TB per rack).  The scene models direct-to-chip (D2C)
-- liquid cooling: warm coolant leaves the rack manifolds at the rear/top,
-- goes to overhead CDUs/heat exchangers in the ceiling plenum, is chilled
-- and pumped back through supply lines to the cold-aisle distribution.
--
-- A simple thermal model simulates heat absorption/generation and cooling
-- power: per rack thermal load scales with load %, cooling duty tracks
-- supply/return temps and CDU effectiveness.  The status bar shows rack
-- count, GPUs, HBM4, capex, IT load, cooling power, delta-T and PUE.
-- Resting the mouse on any part of a rack/CDU brings up its thermal card.
--
-- Pricing (NVIDIA has not published a fixed list price):
--   * Vera Rubin NVL72 (VR200): estimated at $5M-$7M per rack by industry
--     reporting, with Morgan Stanley / industry trackers putting the bill
--     of materials nearer $7.8M.
--   * Rubin Ultra NVL144 (VR300): early quotes around $7M-$8.8M+ per rack.
--   * The jump over Blackwell is driven heavily by HBM4 (288 GB per GPU)
--     and pre-assembled compute trays.
--
-- Usage: bpp -f demo/koppi/vera-rubin-rack.lua
--

local common = require "common"

common.setTiming(1 / 25)

-- Add lightsys lighting for more realistic illumination
v.pre_sdl = [[
#include "colors.inc"
#include "metals.inc"
#include "glass.inc"
#include "bpp_lightsys.inc"
#include "bpp_lightsys_constants.inc"
]]

-- ---------------------------------------------------------------------------
-- Rack geometry and layout
-- ---------------------------------------------------------------------------
local RACK_W    = 6.0   -- 0.6 m
local RACK_D    = 12.0  -- 1.2 m
local RACK_H    = 22.0  -- 2.2 m
local RACK_PITCH = 6.5  -- rack width plus a service gap
local ROW_GAP   = 24.0  -- centre-to-centre row spacing: two 1.2 m deep rows
                        -- plus a 1.2 m cold aisle
local BASE_H    = 0.4

local GPUS_PER_RACK = 72
local HBM_PER_GPU   = 288 -- GB of HBM4

-- The NVL72's front, top to bottom: two 1U ToR switches, two 3U power
-- shelves, ten 1U compute trays, nine 1U NVLink switch trays and eight more
-- compute trays.
local COMPUTE_TRAYS = 18
local SWITCH_TRAYS  = 9

-- ---------------------------------------------------------------------------
-- Room / cooling layout
-- ---------------------------------------------------------------------------
local ROOM_W    = 92.0  -- datacenter room width
local ROOM_D    = 64.0  -- datacenter room depth
local ROOM_H    = 36.0  -- room height up to slab
local SLAB_H    = 1.0
local PLENUM_H  = 6.0   -- raised floor cold air/plenum height
local CEIL_CLEAR = 8.0  -- overhead space above racks for CDUs/pipe runs

-- Thermal model (approximate)
local KW_PER_GPU_FULL = 1.20 -- ~86 kW per NVL72 at full load
local CDU_EFF = 0.88         -- heat exchanger effectiveness
local T_SUPPLY  = 18.0       -- °C supply coolant/air
local T_AMBIENT = 24.0       -- °C ambient

-- ---------------------------------------------------------------------------
-- Parameters
-- ---------------------------------------------------------------------------
v:addParam("rows", 2, 1, 4, 1, "number of rows")
v:addParam("racksPerRow", 4, 2, 6, 1, "racks in each row")
v:addParam("loadPercent", 80, 0, 100, 5, "IT load % of rated power")
v:addParam("coolingMode", "liquid_d2c", "cooling mode (direct-to-chip liquid)")
v:addParam("pricePerRack", 6.5, 5.0, 8.8, 0.1,
           "assumed capex per NVL72 rack in $M (VR200 $5-7M, BOM ~$7.8M; VR300 $7-8.8M+)")
           
local rows        = 2
local racksPerRow = 4

-- ---------------------------------------------------------------------------
-- Static scenery: room shell, raised floor, plenum, slab
-- ---------------------------------------------------------------------------
local floor = Plane(0, 1, 0, 0, 400)
floor.col = "#101318"
floor.friction = 1
v:add(floor)

-- ---------------------------------------------------------------------------
-- Rebuildable part of the hall/room
-- ---------------------------------------------------------------------------
local racks      = {} -- one entry per rack
local built      = {} -- every object removeBuilt() has to take out again
local rackOwner  = {} -- objectKey -> rack, for hover cards
local cduOwner   = {} -- objectKey -> cdu
local cdus       = {}
local flowPipes  = {} -- {obj, phase, dir, speed}

local function removeBuilt()
  for _, o in ipairs(built) do
    pcall(function() v:remove(o) end)
  end
  built = {}
  rackOwner = {}
  cduOwner = {}
  racks = {}
  cdus = {}
  flowPipes = {}
end

local function addBuilt(o, ownerType, ownerObj)
  o.collides = false
  v:add(o)
  built[#built + 1] = o
  if ownerType == "rack" and ownerObj then
    rackOwner[objectKey(o)] = ownerObj
  elseif ownerType == "cdu" and ownerObj then
    cduOwner[objectKey(o)] = ownerObj
  end
  return o
end

local function hexToRGB(col)
  if type(col) ~= "string" then return "0.2,0.22,0.25" end
  local r,g,b = col:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return "0.2,0.22,0.25" end
  return string.format("%g,%g,%g", tonumber(r,16)/255, tonumber(g,16)/255, tonumber(b,16)/255)
end

local function box(ownerType, ownerObj, w, h, d, x, y, z, col, emission)
  local o = Cube(w, h, d, 0)
  o.pos = btVector3(x, y, z)
  o.col = col
  o.friction = 0.8
  if emission then
    o.emission = emission
  end
  return addBuilt(o, ownerType, ownerObj)
end

local function metalBox(ownerType, ownerObj, w, h, d, x, y, z, col, emission, gloss)
  local o = Cube(w, h, d, 0)
  o.pos = btVector3(x, y, z)
  o.col = col
  o.friction = 0.8
  if emission then
    o.emission = emission
  end
  local g = gloss or 0.6
  local r = math.min(0.25, g * 0.25)
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(col) .. [[> }
      finish { ambient 0.08 diffuse 0.55 specular ]] .. tostring(g) .. [[ roughness 0.008 reflection ]] .. tostring(r) .. [[ metallic }
    }
  ]]
  return addBuilt(o, ownerType, ownerObj)
end

local function glassBox(ownerType, ownerObj, w, h, d, x, y, z, col, emission)
  local o = Cube(w, h, d, 0)
  o.pos = btVector3(x, y, z)
  o.col = col or "#76b900"
  o.friction = 0.8
  if emission then
    o.emission = emission
  else
    o.emission = col or "#76b900"
  end
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(o.col) .. [[> transmit 0.3 }
      finish { ambient 0.02 diffuse 0.4 specular 0.9 roughness 0.001 reflection 0.4 }
    }
    interior { ior 1.5 }
  ]]
  return addBuilt(o, ownerType, ownerObj)
end

local function flowPipe(w,h,d,x,y,z,col,dir,speed)
  local o = Cube(w,h,d,0)
  o.pos = btVector3(x,y,z)
  o.col = col
  o.friction = 0.8
  o.sdl = [[
    texture {
      pigment {
        gradient y
        color_map {
          [0.00 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.3]
          [0.15 color rgb <1,1,1> * 2.0]
          [0.3 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.3]
          [0.5 color rgb <1,1,1> * 2.0]
          [0.7 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.3]
          [0.85 color rgb <1,1,1> * 2.0]
          [1.00 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.3]
        }
        turbulence 0.18
        scale <1, 0.12, 1>
        translate y * clock
      }
      finish { ambient 0.08 diffuse 0.65 specular 0.8 roughness 0.008 }
    }
  ]]
  o.collides = false
  v:add(o)
  built[#built + 1] = o
  flowPipes[#flowPipes + 1] = { obj = o, phase = math.random()*10, dir = dir or 1, speed = speed or 1.0 }
  -- metallic pipe support
  local sup = Cube(w * 1.05, h * 1.3, d * 0.6, 0)
  sup.pos = btVector3(x, y, z)
  sup.col = "#b8bcc2"
  sup.friction = 0.8
  sup.collides = false
  sup.sdl = [[
    texture {
      pigment { color rgb <0.72,0.74,0.76> }
      finish { ambient 0.1 diffuse 0.5 specular 0.9 roughness 0.005 reflection 0.15 metallic }
    }
  ]]
  v:add(sup)
  built[#built + 1] = sup
  return o
end

local function pipeElbow(x,y,z,r,axis,col)
  local o = Cube(r*2, r*2, r*2, 0)
  o.pos = btVector3(x,y,z)
  o.col = col
  o.friction = 0.8
  o.collides = false
  v:add(o)
  built[#built + 1] = o
  flowPipes[#flowPipes + 1] = { obj = o, phase = math.random()*10, dir = 1, speed = 0.8 }
  return o
end

local function nvidiaGreen(level)
  return string.format("#%02x%02x00",
                       math.floor(118 * level + 0.5),
                       math.floor(185 * level + 0.5))
end

local function heatColor(tReturn)
  -- map return temp to color
  local t = tReturn
  if t < 28 then return "#35d6ff" end
  if t < 32 then return "#39ff88" end
  if t < 36 then return "#ffb020" end
  return "#ff4020"
end

-- ---------------------------------------------------------------------------
-- One NVL72 rack with D2C liquid manifolds
-- ---------------------------------------------------------------------------
local function addRack(x, z, front, row, col)
  local rack = {
    row = row,
    col = col,
    bars = {},
    blink = nil,
    blinkOn = false,
    phase = (#racks + 1) * 0.9,
    itKw = 0,
    coolKw = 0,
    tSupply = T_SUPPLY,
    tReturn = T_SUPPLY + 8,
  }

  local midY = SLAB_H + BASE_H + (RACK_H - BASE_H) / 2

  -- plinth, chassis and top cap
  metalBox("rack", rack, RACK_W, BASE_H, RACK_D, x, SLAB_H + BASE_H / 2, z, "#0b0e12", nil, 0.75)
  metalBox("rack", rack, RACK_W - 0.38, RACK_H - BASE_H - 0.22, RACK_D - 0.32,
      x, SLAB_H + midY, z, "#181d24", nil, 0.7)
  metalBox("rack", rack, 0.09, RACK_H - BASE_H - 0.28, RACK_D - 0.36,
      x - RACK_W / 2 + 0.27, SLAB_H + midY, z, "#101419", nil, 0.8)
  metalBox("rack", rack, 0.09, RACK_H - BASE_H - 0.28, RACK_D - 0.36,
      x + RACK_W / 2 - 0.27, SLAB_H + midY, z, "#101419", nil, 0.8)
  metalBox("rack", rack, RACK_W + 0.16, 0.4, RACK_D + 0.16,
      x, SLAB_H + RACK_H + 0.1, z, "#07090b", nil, 0.85)

  -- Recessed front bezel
  local bezelZ = z + front * (RACK_D / 2 + 0.18)
  metalBox("rack", rack, RACK_W - 0.52, RACK_H - 1.12, 0.32,
      x, SLAB_H + (1.0 + RACK_H - 0.12) / 2, bezelZ, "#0a0d11", nil, 0.65)

  -- Tray faces
  local trayBottom = 1.0
  local switchH    = 3.2
  local computeTop = RACK_H - 0.9 - switchH
  local pitch      = (computeTop - trayBottom) / COMPUTE_TRAYS
  local faceZ      = z + front * (RACK_D / 2 + 0.33)
  local ledZ       = z + front * (RACK_D / 2 + 0.42)

  for t = 1, COMPUTE_TRAYS do
    local y = trayBottom + (t - 0.5) * pitch
    local shade = (t % 3 == 0) and "#242a32" or "#1d232a"
    metalBox("rack", rack, RACK_W - 1.02, pitch * 0.74, 0.2, x, SLAB_H + y, faceZ, shade, nil, 0.55)
    metalBox("rack", rack, RACK_W - 1.0, pitch * 0.08, 0.01, x, SLAB_H + y + pitch * 0.38, faceZ + 0.105, "#15191f", nil, 0.7)

    local ledCol
    local m = (t * 11 + row * 3 + col + t * 2) % 17
    if m == 0 then ledCol = "#ffb020"
    elseif m < 5 then ledCol = "#35d6ff"
    elseif m < 10 then ledCol = "#39ff88"
    else ledCol = "#9dffb3"
    end
    local led = glassBox("rack", rack, 0.26, math.min(0.18, pitch * 0.28), 0.08,
                    x - RACK_W / 2 + 0.8, SLAB_H + y, ledZ, ledCol)
    led.emission = ledCol
    rack.leds = rack.leds or {}
    rack.leds[#rack.leds + 1] = { obj = led, base = ledCol, phase = (t + row * 6 + col * 9) }
  end

  -- Switch tray block with ports
  local switchBottom = computeTop + 0.4
  local switchPitch  = (switchH - 0.6) / SWITCH_TRAYS
  for t = 1, SWITCH_TRAYS do
    local y = switchBottom + (t - 0.5) * switchPitch
    metalBox("rack", rack, RACK_W - 1.02, switchPitch * 0.58, 0.18,
        x, SLAB_H + y, faceZ, "#161b22", nil, 0.6)
    for px = 1, 4 do
      metalBox("rack", rack, 0.16, 0.1, 0.01,
          x - RACK_W / 2 + 1.0 + (px-1)*0.22, SLAB_H + y, faceZ + 0.095, "#090b0d", nil, 0.8)
    end
  end

  -- NVIDIA green edge bars and badge
  local stripX = RACK_W / 2 - 0.24
  for _, sx in ipairs({ -1, 1 }) do
    local bar = glassBox("rack", rack, 0.14, RACK_H - 2.0, 0.12,
                    x + sx * stripX, SLAB_H + (2.1 + RACK_H - 0.1) / 2,
                    z + front * (RACK_D / 2 + 0.28),
                    "#76b900")
    rack.bars[#rack.bars + 1] = bar
  end
  glassBox("rack", rack, RACK_W - 0.78, 0.18, 0.18,
      x, SLAB_H + RACK_H - 0.36, z + front * (RACK_D / 2 + 0.32),
      "#76b900")
  metalBox("rack", rack, 0.9, 0.12, 0.01,
      x, SLAB_H + RACK_H - 0.36, z + front * (RACK_D / 2 + 0.42), "#d6ff9d", "#d6ff9d", 0.9)

  -- Status LED
  rack.blink = glassBox("rack", rack, 0.32, 0.2, 0.1,
                   x + RACK_W / 2 - 0.88, SLAB_H + RACK_H - 0.72,
                   z + front * (RACK_D / 2 + 0.4),
                   "#39ff88")
  if rack.blink then 
    rack.blink.emission = "#39ff88"
  end

  -- D2C liquid manifolds (rear/top) - supply/return pipes and manifold block
  local rearZ = z - front * (RACK_D / 2 + 0.22)
  metalBox("rack", rack, RACK_W - 0.88, 1.7, 0.44,
      x, SLAB_H + RACK_H - 0.98, rearZ, "#262c33", nil, 0.7)
  flowPipe(RACK_W - 0.98, 0.2, 0.24,
      x - 0.8, SLAB_H + RACK_H - 0.58, rearZ + 0.38, "#1f9bff", 1, 1.2)
  flowPipe(RACK_W - 0.98, 0.2, 0.24,
      x + 0.8, SLAB_H + RACK_H - 0.58, rearZ + 0.38, "#ff5a2a", -1, 1.0)
  for _, qx in ipairs({ -0.8, 0.8 }) do
    metalBox("rack", rack, 0.28, 0.28, 0.12,
        x + qx, SLAB_H + RACK_H - 0.58, rearZ + 0.52, "#3a424a", nil, 0.75)
  end

  racks[#racks + 1] = rack
  return rack
end

-- ---------------------------------------------------------------------------
-- CDU / Heat Exchanger units on ceiling/plenum level
-- ---------------------------------------------------------------------------
local function addCDU(x, y, z, idx)
  local cdu = {
    idx = idx,
    tSupply = T_SUPPLY,
    tReturn = T_SUPPLY + 10,
    coolKw = 0,
    flow = 0.9,
  }
  -- chassis
  metalBox("cdu", cdu, 14.0, 3.0, 6.0, x, y, z, "#242a31", nil, 0.7)
  metalBox("cdu", cdu, 13.6, 2.6, 5.6, x, y, z - 0.1, "#2b323a", nil, 0.68)
  -- coil/heat exchanger (copper)
  metalBox("cdu", cdu, 13.0, 0.6, 5.0, x, y - 0.8, z - 0.1, "#b87333", "#ffb347", 0.5)
  -- pumps/headers
  metalBox("cdu", cdu, 2.0, 2.2, 1.2, x - 5.0, y + 0.2, z + 2.8, "#171c22", nil, 0.75)
  metalBox("cdu", cdu, 2.0, 2.2, 1.2, x + 5.0, y + 0.2, z + 2.8, "#171c22", nil, 0.75)
  -- supply/return manifolds (cold/hot) with flow
  flowPipe(13.2, 0.16, 0.24, x, y + 1.2, z + 3.0, "#1f9bff", 1, 1.0)
  flowPipe(13.2, 0.16, 0.24, x, y + 0.8, z + 3.0, "#ff5a2a", -1, 0.9)
  -- status indicators
  cdu.led = glassBox("cdu", cdu, 0.6, 0.25, 0.12, x + 6.0, y + 1.25, z + 3.1, "#39ff88")
  if cdu.led then 
    cdu.led.emission = "#39ff88"
  end
  cdus[#cdus + 1] = cdu
  return cdu
end

-- ---------------------------------------------------------------------------
-- Build room, floor, cooling, racks
-- ---------------------------------------------------------------------------
local updateStatus -- forward

local function build()
  removeBuilt()

  racksPerRow = math.floor(tonumber(v:getParam("racksPerRow")) or 4)
  rows = math.floor(tonumber(v:getParam("rows")) or 2)
  if rows < 1 then rows = 1 end
  if rows > 4 then rows = 4 end
  if racksPerRow < 1 then racksPerRow = 1 end
  if racksPerRow > 6 then racksPerRow = 6 end

  local rowWidth = (racksPerRow - 1) * RACK_PITCH
  local rowZ = {}
  for i = 1, rows do
    rowZ[i] = (i - (rows + 1) / 2) * ROW_GAP
  end

  local roomW = math.max(ROOM_W, rowWidth + 40.0)
  local roomD = math.max(ROOM_D, rows * ROW_GAP + 40.0)
  local roomH = ROOM_H

  -- Concrete slab
  box(nil, nil, roomW, SLAB_H, roomD, 0, SLAB_H / 2, 0, "#1b2026")

  -- Raised floor tiles and plenum
  box(nil, nil, roomW - 2.0, PLENUM_H, roomD - 2.0, 0, SLAB_H + PLENUM_H / 2, 0, "#151a1f")
  local tilesX = math.max(12, math.floor((roomW - 8.0) / 7.2) + 2)
  local tilesZ = math.max(8, math.floor((roomD - 8.0) / 7.0) + 2)
  for i = 1, tilesX do
    for j = 1, tilesZ do
      box(nil, nil, 6.0, 0.08, 6.0, (i - (tilesX + 1) / 2) * 7.2, SLAB_H + PLENUM_H + 0.04, (j - (tilesZ + 1) / 2) * 7.0, "#20262d")
    end
  end
  -- Perforated tiles in cold aisles
  for i = 1, rows, 2 do
    if i + 1 <= rows then
      local aisleZ = (rowZ[i] + rowZ[i + 1]) / 2
      box(nil, nil, rowWidth + 8.0, 0.06, ROW_GAP - RACK_D - 1.0,
          0, SLAB_H + PLENUM_H + 0.03, aisleZ, "#27404a", "#102a33")
    end
  end

  -- Racks
  for i = 1, rows do
    local front = (i % 2 == 1) and 1 or -1
    local z = rowZ[i]
    for j = 1, racksPerRow do
      local x = (j - (racksPerRow + 1) / 2) * RACK_PITCH
      addRack(x, z, front, i, j)
    end
    -- overhead cable/pipe trays above hot/cold sides
    for _, dz in ipairs({ -RACK_D * 0.26, RACK_D * 0.26 }) do
      box(nil, nil, rowWidth + 5.0, 0.32, 1.4,
          0, SLAB_H + RACK_H + 2.2, z + dz, "#3b4146")
      -- liquid supply/return on trays with flow
      flowPipe(rowWidth + 4.6, 0.16, 0.28,
          0, SLAB_H + RACK_H + 2.38, z + dz - 0.3, "#1f9bff", 1, 1.0)
      flowPipe(rowWidth + 4.6, 0.16, 0.28,
          0, SLAB_H + RACK_H + 2.38, z + dz + 0.3, "#ff5a2a", -1, 0.9)
      -- electrical busway
      box(nil, nil, rowWidth + 4.4, 0.14, 0.22,
          0, SLAB_H + RACK_H + 2.42, z + dz, "#c0c0c0")
      box(nil, nil, rowWidth + 4.2, 0.1, 0.16,
          0, SLAB_H + RACK_H + 2.42, z + dz, "#ffd700", "#ffd700")
      -- power conduits
      box(nil, nil, rowWidth + 3.8, 0.08, 0.08,
          0, SLAB_H + RACK_H + 2.55, z + dz - 0.12, "#ff6b00")
      box(nil, nil, rowWidth + 3.8, 0.08, 0.08,
          0, SLAB_H + RACK_H + 2.55, z + dz + 0.12, "#ff6b00")
    end
  end

  -- Room walls - only edges painted, walls translucent
  local function wallEdge(x,y,z,w,h,d)
    local o = box(nil, nil, w,h,d,x,y,z,"#76b900")
    if o then 
      o.transparency = 0.95
      o.emission = "#76b900"
      o.sdl = [[
        texture {
          pigment { color rgb <0.46,0.725,0> transmit 0.95 }
          finish { ambient 0.1 diffuse 0.4 specular 0.8 roughness 0.01 emission 0.3 }
        }
      ]]
    end
    return o
  end
  local function wallPanel(x,y,z,w,h,d)
    local o = box(nil, nil, w,h,d,x,y,z,"#1a1f24")
    if o then 
      o.transparency = 0.9
      o.sdl = [[
        texture {
          pigment { color rgb <0.1,0.12,0.15> transmit 0.9 }
          finish { ambient 0.02 diffuse 0.2 specular 0.4 roughness 0.01 }
        }
      ]]
    end
    return o
  end
  -- corners/edges only
  wallEdge(0, SLAB_H + 0.3, -roomD / 2, roomW, 0.6, 0.8)
  wallEdge(0, SLAB_H + roomH - 0.3, -roomD / 2, roomW, 0.6, 0.8)
  wallEdge(0, SLAB_H + 0.3, roomD / 2, roomW, 0.6, 0.8)
  wallEdge(0, SLAB_H + roomH - 0.3, roomD / 2, roomW, 0.6, 0.8)
  wallEdge(-roomW / 2, SLAB_H + 0.3, 0, 0.8, 0.6, roomD)
  wallEdge(-roomW / 2, SLAB_H + roomH - 0.3, 0, 0.8, 0.6, roomD)
  wallEdge(roomW / 2, SLAB_H + 0.3, 0, 0.8, 0.6, roomD)
  wallEdge(roomW / 2, SLAB_H + roomH - 0.3, 0, 0.8, 0.6, roomD)
  -- thin translucent panels
  wallPanel(0, SLAB_H + roomH / 2, -roomD / 2, roomW, roomH - 1.2, 0.3)
  wallPanel(0, SLAB_H + roomH / 2, roomD / 2, roomW, roomH - 1.2, 0.3)
  wallPanel(-roomW / 2, SLAB_H + roomH / 2, 0, 0.3, roomH - 1.2, roomD)
  wallPanel(roomW / 2, SLAB_H + roomH / 2, 0, 0.3, roomH - 1.2, roomD)
  -- ceiling edges only
  box(nil, nil, roomW, 0.4, 0.6, 0, SLAB_H + roomH - 0.2, -roomD / 2 + 0.1, "#76b900", "#76b900")
  box(nil, nil, roomW, 0.4, 0.6, 0, SLAB_H + roomH - 0.2, roomD / 2 - 0.1, "#76b900", "#76b900")
  box(nil, nil, 0.6, 0.4, roomD, -roomW / 2 + 0.1, SLAB_H + roomH - 0.2, 0, "#76b900", "#76b900")
  box(nil, nil, 0.6, 0.4, roomD, roomW / 2 - 0.1, SLAB_H + roomH - 0.2, 0, "#76b900", "#76b900")

  -- Liquid cooling plant on top of the room (roof)
  local roofY = SLAB_H + roomH + 1.6
  local plantW = math.min(roomW + 16.0, 72.0)
  -- chiller skid
  metalBox(nil, nil, plantW * 0.5, 3.0, 10.0, -roomW * 0.25, roofY, -roomD * 0.25, "#23282f", nil, 0.72)
  metalBox(nil, nil, plantW * 0.48, 2.6, 9.0, -roomW * 0.25, roofY + 0.1, -roomD * 0.25, "#2c333b", nil, 0.7)
  metalBox(nil, nil, plantW * 0.5, 3.0, 10.0, roomW * 0.25, roofY, -roomD * 0.25, "#23282f", nil, 0.72)
  metalBox(nil, nil, plantW * 0.48, 2.6, 9.0, roomW * 0.25, roofY + 0.1, -roomD * 0.25, "#2c333b", nil, 0.7)
  -- electrical transformers/PDUs
  metalBox(nil, nil, 10.0, 3.0, 6.0, roomW * 0.1, roofY, roomD * 0.25, "#2a2f36", nil, 0.7)
  box(nil, nil, 9.6, 2.6, 5.6, roomW * 0.1, roofY + 0.1, roomD * 0.25, "#353a42")
  box(nil, nil, 0.4, 2.0, 0.4, roomW * 0.1, roofY + 0.5, roomD * 0.25 + 3.2, "#ffd700", "#ffd700")
  -- cooling towers
  for _, cx in ipairs({ -roomW * 0.18, -roomW * 0.12, roomW * 0.12, roomW * 0.18 }) do
    metalBox(nil, nil, 5.0, 6.0, 5.0, cx, roofY + 4.0, roomD * 0.18, "#343a42", nil, 0.68)
    metalBox(nil, nil, 4.6, 5.6, 4.6, cx, roofY + 4.1, roomD * 0.18, "#3a4149", nil, 0.66)
    metalBox(nil, nil, 4.0, 0.4, 4.0, cx, roofY + 7.0, roomD * 0.18, "#5a626a", "#9dffb3", 0.6)
  end
  -- main headers on roof with flow
  flowPipe(roomW + 32.0, 0.7, 0.9, 0, roofY + 3.8, -roomD * 0.25, "#1f9bff", 1, 1.7)
  flowPipe(roomW + 32.0, 0.7, 0.9, 0, roofY + 3.2, -roomD * 0.25, "#ff5a2a", -1, 1.5)
  -- connect headers to chillers/towers
  flowPipe(12.0, 0.6, 0.6, -roomW * 0.25, roofY + 3.8, -roomD * 0.25 + 5.0, "#1f9bff", 1, 1.4)
  flowPipe(12.0, 0.6, 0.6, -roomW * 0.25, roofY + 3.2, -roomD * 0.25 + 5.0, "#ff5a2a", -1, 1.3)
  flowPipe(12.0, 0.6, 0.6, roomW * 0.25, roofY + 3.8, -roomD * 0.25 + 5.0, "#1f9bff", 1, 1.4)
  flowPipe(12.0, 0.6, 0.6, roomW * 0.25, roofY + 3.2, -roomD * 0.25 + 5.0, "#ff5a2a", -1, 1.3)
  pipeElbow(0, roofY + 3.8, -roomD * 0.25, 0.3, "z", "#1f9bff")
  pipeElbow(0, roofY + 3.2, -roomD * 0.25, 0.3, "z", "#ff5a2a")
  -- risers down to room with flow (connected)
  for _, rx in ipairs({ -rowWidth / 3, 0, rowWidth / 3 }) do
    flowPipe(0.9, (roomH - PLENUM_H + 12.0), 0.9, rx, SLAB_H + (roomH - PLENUM_H + 12.0) / 2, -roomD / 2 - 1.8, "#1f9bff", 1, 1.3)
    flowPipe(0.9, (roomH - PLENUM_H + 12.0), 0.9, rx + 1.6, SLAB_H + (roomH - PLENUM_H + 12.0) / 2, -roomD / 2 - 1.8, "#ff5a2a", -1, 1.2)
    pipeElbow(rx, SLAB_H + roomH + 0.7, -roomD / 2 - 1.8, 0.45, "z", "#1f9bff")
    pipeElbow(rx + 1.6, SLAB_H + roomH + 0.7, -roomD / 2 - 1.8, 0.45, "z", "#ff5a2a")
    flowPipe(0.3, 8.0, 0.3, rx, roofY - 2.0, -roomD / 2 - 1.8, "#1f9bff", 1, 1.0)
    flowPipe(0.3, 8.0, 0.3, rx + 1.6, roofY - 2.0, -roomD / 2 - 1.8, "#ff5a2a", -1, 1.0)
    pipeElbow(rx, roofY + 3.5, -roomD / 2 - 1.8, 0.35, "z", "#1f9bff")
    pipeElbow(rx + 1.6, roofY + 3.0, -roomD / 2 - 1.8, 0.35, "z", "#ff5a2a")
  end

  -- Overhead CDUs/heat exchangers on ceiling trusses above every rack
  local cduY = SLAB_H + roomH - 4.2
  local cduIdx = 0
  for i = 1, rows do
    local z = rowZ[i]
    for j = 1, racksPerRow do
      local x = (j - (racksPerRow + 1) / 2) * RACK_PITCH
      cduIdx = cduIdx + 1
      addCDU(x, cduY, z, cduIdx)
    end
  end
  -- supply/return mains between CDUs and roof with flow
  for i = 1, #cdus do
    local c = cdus[i]
    local mz = rowZ[math.min(rows, math.ceil(i / math.max(1, racksPerRow)))] or 0
    local hx = (i % math.max(1, racksPerRow) == 0) and (racksPerRow) or (i % math.max(1, racksPerRow))
    hx = (hx - (racksPerRow + 1) / 2) * RACK_PITCH
    -- connect each CDU to main headers
    flowPipe(math.abs(hx) + 24.0, 0.34, 0.34, hx / 2, cduY + 2.2, mz, "#1f9bff", 1, 1.2)
    flowPipe(math.abs(hx) + 24.0, 0.34, 0.34, hx / 2, cduY + 1.8, mz, "#ff5a2a", -1, 1.2)
    pipeElbow(hx, cduY + 2.0, mz - 2.4, 0.17, "z", "#1f9bff")
    pipeElbow(hx, cduY + 1.6, mz - 2.4, 0.17, "z", "#ff5a2a")
    -- connect to rack trays
    flowPipe(0.32, 7.0, 0.32, hx, cduY - 2.0, mz + RACK_D * 0.36, "#1f9bff", 1, 1.3)
    flowPipe(0.32, 7.0, 0.32, hx, cduY - 2.8, mz - RACK_D * 0.36, "#ff5a2a", -1, 1.3)
    pipeElbow(hx, cduY + 1.0, mz + RACK_D * 0.36, 0.16, "z", "#1f9bff")
    pipeElbow(hx, cduY + 0.4, mz - RACK_D * 0.36, 0.16, "z", "#ff5a2a")
    flowPipe(0.3, 2.6, 0.3, hx, SLAB_H + RACK_H + 2.2, mz + RACK_D * 0.36, "#1f9bff", 1, 1.2)
    flowPipe(0.3, 2.6, 0.3, hx, SLAB_H + RACK_H + 2.0, mz - RACK_D * 0.36, "#ff5a2a", -1, 1.2)
    -- connect to CDU manifold
    flowPipe(0.34, 2.2, 0.34, hx, cduY - 0.5, mz - 3.6, "#1f9bff", 1, 1.2)
    flowPipe(0.34, 2.2, 0.34, hx, cduY - 0.9, mz - 3.6, "#ff5a2a", -1, 1.2)
    -- add junctions
    pipeElbow(hx, cduY + 1.9, mz + RACK_D * 0.1, 0.16, "z", "#1f9bff")
    pipeElbow(hx, cduY + 1.5, mz - RACK_D * 0.1, 0.16, "z", "#ff5a2a")
  end

  -- Add lightsys fluorescent area lights between rows / in cold aisles
  if not v.post_sdl then v.post_sdl = "" end
  local aisleLightCount = math.max(2, rows + 1)
  for i = 1, aisleLightCount do
    local az = (i - (aisleLightCount + 1) / 2) * ROW_GAP
    if math.abs(az) < roomD / 2 - 10 then
      local ly = SLAB_H + roomH - 2.0
      local lightSdl = "\nlight_source {\n" ..
        "  <" .. tostring(0) .. ", " .. tostring(ly) .. ", " .. tostring(az) .. ">\n" ..
        "  color rgb <0.9,1.0,0.95> * 3.0\n" ..
        "  area_light <4.0, 0, 0>, <0, 0, 1.0>, 4, 1\n" ..
        "  adaptive 1\n" ..
        "  jitter\n" ..
        "}\n"
      v.post_sdl = v.post_sdl .. lightSdl
      -- add visible fixture
      metalBox(nil, nil, 8.0, 0.3, 2.8, 0, ly + 0.1, az, "#252a31", nil, 0.72)
    end
  end

  -- Camera looking down cold aisle
  local aisleZ = (rowZ[1] and rowZ[2] and ((rowZ[1] + rowZ[2]) / 2) or (rowZ[1] or 0))
  local camX = rowWidth / 2 + math.max(52, rowWidth * 0.8)
  common.setCamera(btVector3(camX, SLAB_H + 26, aisleZ - 4),
                   btVector3(-rowWidth * 0.02, SLAB_H + 12, aisleZ),
                   math.rad(52), { horizontal = true })

  updateStatus()
  if updateHelp then updateHelp() end
end

-- ---------------------------------------------------------------------------
-- Thermal model and totals
-- ---------------------------------------------------------------------------
local function pricePerRackM()
  return tonumber(v:getParam("pricePerRack")) or 6.5
end

local function loadPct()
  return math.max(0, math.min(100, tonumber(v:getParam("loadPercent")) or 80))
end

local function summary()
  local n = #racks
  local gpus = n * GPUS_PER_RACK
  local hbmTB = gpus * HBM_PER_GPU / 1000
  local capex = n * pricePerRackM()
  local lp = loadPct() / 100.0
  local itKw = n * KW_PER_GPU_FULL * GPUS_PER_RACK * lp
  -- cooling must absorb IT + losses; with CDU effectiveness
  local coolKw = itKw / CDU_EFF
  local pue = (itKw + (coolKw - itKw)) / math.max(1e-6, itKw)
  local tReturn = T_SUPPLY + (itKw / n) * 0.12 -- approx
  return n, gpus, hbmTB, capex, itKw, coolKw, pue, tReturn
end

updateStatus = function()
  local n, gpus, hbmTB, capex, itKw, coolKw, pue, tReturn = summary()
  if n == 0 then
    v.statusText = "no racks"
    return
  end
  v.statusText = string.format(
    "%d x NVL72 (D2C liquid) | %d GPUs | %.1f TB HBM4 | $%.1fM | IT %.0f kW | Cool %.0f kW | T_ret %.1f °C | PUE %.2f",
    n, gpus, hbmTB, capex, itKw, coolKw, tReturn, pue)
end

local function updateHelp()
  local n, gpus, hbmTB, capex, itKw, coolKw, pue, tReturn = summary()
  v:setHelpText(string.format([[
NVIDIA Vera Rubin virtual datacenter - Liquid cooled room

%d NVL72 racks (2x%d), %d GPUs, %.1f TB HBM4, $%.1fM capex.

Cooling: direct-to-chip liquid, overhead CDUs/heat exchangers, raised-floor
plenum.  Supply ~%d °C, rack return ~%.1f °C.  IT %.0f kW, cooling duty %.0f kW, PUE %.2f.

Pricing assumptions (no fixed NVIDIA list price):
  Vera Rubin NVL72 (VR200): $5M-$7M per rack; BOM ~$7.8M
  Rubin Ultra NVL144 (VR300): ~$7M-$8.8M+ per rack
  HBM4 (288 GB per GPU) and pre-assembled compute trays drive cost.

Hover racks/CDUs for thermal details.  Params: load %% , price per rack ($M).
]], n, racksPerRow, gpus, hbmTB, capex, T_SUPPLY, tReturn, itKw, coolKw, pue))
end

local function refreshText()
  updateStatus()
  updateHelp()
  -- update rack/cdu thermal state
  local n, gpus, hbmTB, capex, itKw, coolKw, pue, tReturn = summary()
  local lp = loadPct() / 100.0
  for i, rack in ipairs(racks) do
    rack.itKw = itKw / n
    rack.coolKw = coolKw / n
    rack.tSupply = T_SUPPLY
    rack.tReturn = tReturn + (math.sin(i) * 0.6)
  end
  for i, cdu in ipairs(cdus) do
    cdu.coolKw = coolKw / math.max(1, #cdus)
    cdu.tSupply = T_SUPPLY - 0.5
    cdu.tReturn = tReturn + 1.5
    if cdu.led then
      local eff = (loadPct() > 0) and ((pue < 1.4) and "#39ff88" or "#ffb020") or "#555555"
      cdu.led.emission = eff
    end
  end
end

v:onHover(function(N, obj, x, y, z)
  local rack = rackOwner[objectKey(obj)]
  if rack then
    local price = pricePerRackM()
    return string.format(
      "NVIDIA Vera Rubin NVL72 (VR200) - D2C Liquid\n" ..
      "Row %d, rack %d\n" ..
      "%d Rubin GPUs | 20.7 TB HBM4\n" ..
      "IT %.1f kW | Cool %.1f kW | T_sup %d °C | T_ret %.1f °C\n" ..
      "$%.2fM capex | $%.0fk/GPU",
      rack.row, rack.col, GPUS_PER_RACK,
      rack.itKw or 0, rack.coolKw or 0, T_SUPPLY, rack.tReturn or (T_SUPPLY+8),
      price, price * 1e6 / GPUS_PER_RACK / 1000)
  end
  local cdu = cduOwner[objectKey(obj)]
  if cdu then
    local _, _, _, _, _, coolKw, pue, tReturn = summary()
    return string.format(
      "Overhead CDU / Liquid-to-Liquid HX\n" ..
      "Unit %d | Load shared\n" ..
      "Cooling duty %.0f kW total | PUE %.2f\n" ..
      "T_sup %.1f °C | T_ret %.1f °C\n" ..
      "D2C manifolds + facility water side",
      cdu.idx, coolKw, pue, cdu.tSupply or (T_SUPPLY-0.5), tReturn + 1.5)
  end
  return nil
end)

-- Animation
v:postSim(function(N)
  local t = N * (v.timeStep or (1 / 25))
  local lp = loadPct()
  for _, rack in ipairs(racks) do
    local intensity = (lp / 100.0) * (0.5 + 0.5 * math.sin(t * 1.6 + rack.phase))
    local green = nvidiaGreen(0.4 + 0.6 * intensity)
    for _, bar in ipairs(rack.bars) do
      bar.emission = green
    end
    -- blink compute tray LEDs
    if rack.leds then
      for i, led in ipairs(rack.leds) do
        if led.obj then
          local p = led.phase or i
          local on = ((N + p * 3) % 7) < 2
          if on and lp > 0 then
            if p % 5 == 0 then
              led.obj.emission = "#35d6ff"
            elseif p % 7 == 0 then
              led.obj.emission = "#ffb020"
            else
              led.obj.emission = led.base or "#39ff88"
            end
          else
            led.obj.emission = "#0b1a12"
          end
        end
      end
    end
    if rack.blink then
      if (N + rack.row * 7 + rack.col * 13) % 16 == 0 then
        rack.blinkOn = not rack.blinkOn
        if rack.blinkOn and lp > 0 then
          rack.blink.emission = heatColor(rack.tReturn or 32)
        else
          rack.blink.emission = "#0b2416"
        end
      end
    end
  end
  for _, cdu in ipairs(cdus) do
    if cdu.led then
      if (N % 10) == 0 then
        if lp > 0 then
          cdu.led.emission = ((N % 20) < 10) and "#39ff88" or "#1f9bff"
        else
          cdu.led.emission = "#555555"
        end
      end
    end
  end
  -- animate pipe flow
  if lp > 0 then
    local flow = (0.6 + 0.4 * (lp / 100.0)) * t
    for _, p in ipairs(flowPipes) do
      if p.obj then
        p.obj.sdl = [[
    texture {
      pigment {
        gradient y
        color_map {
          [0.00 color rgb <]] .. (p.dir and (p.dir > 0 and "0.12,0.61,1.0" or "1.0,0.35,0.16")) .. [[> * 0.4]
          [0.25 color rgb <1,1,1> * ]] .. tostring(1.6 + lp / 200.0) .. [[]
          [0.50 color rgb <]] .. (p.dir and (p.dir > 0 and "0.12,0.61,1.0" or "1.0,0.35,0.16")) .. [[> * 0.4]
          [0.75 color rgb <1,1,1> * ]] .. tostring(1.6 + lp / 200.0) .. [[]
          [1.00 color rgb <]] .. (p.dir and (p.dir > 0 and "0.12,0.61,1.0" or "1.0,0.35,0.16")) .. [[> * 0.4]
        }
        turbulence 0.12
        scale <1, 0.22, 1>
        translate y * ]] .. tostring(flow * (p.speed or 1.0) * (p.dir or 1)) .. [[
      }
      finish { diffuse 0.7 specular 0.5 roughness 0.01 }
    }
  ]]
      end
    end
  end
  refreshText()
end)

v:onParamChanged(function(N, name, value)
  if name == "racksPerRow" or name == "rows" then
    build()
  elseif name == "loadPercent" or name == "pricePerRack" then
    refreshText()
  end
end)

v:preStart(function(N)
  local n, gpus, hbmTB, capex, itKw, coolKw, pue, tReturn = summary()
  print(string.format("vera-rubin-rack: %d NVL72 racks, %d GPUs, %.1f TB HBM4, $%.1fM, IT %.0f kW, PUE %.2f",
                      n, gpus, hbmTB, capex, itKw, pue))
  refreshText()
  updateHelp()
end)

build()

-- EOF
