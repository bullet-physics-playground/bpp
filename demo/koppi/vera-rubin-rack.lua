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
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.4]
          [0.25 color rgb <1,1,1> * 1.6]
          [0.50 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.4]
          [0.75 color rgb <1,1,1> * 1.6]
          [1.00 color rgb <]] .. string.match(col,"#(%x%x)(%x%x)(%x%x)") and
            string.format("%g,%g,%g", tonumber(string.match(col,"#(%x%x)%x%x%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x(%x%x)%x%x") or "00",16)/255,
                                        tonumber(string.match(col,"#%x%x%x%x(%x%x)") or "00",16)/255) or "0.12,0.61,1.0" .. [[> * 0.4]
        }
        turbulence 0.08
        scale <1, 0.18, 1>
        translate y * clock
      }
      finish { diffuse 0.7 specular 0.4 roughness 0.02 }
    }
  ]]
  o.collides = false
  v:add(o)
  built[#built + 1] = o
  flowPipes[#flowPipes + 1] = { obj = o, phase = math.random()*10, dir = dir or 1, speed = speed or 1.0 }
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
  box("rack", rack, RACK_W, BASE_H, RACK_D, x, SLAB_H + BASE_H / 2, z, "#101316")
  box("rack", rack, RACK_W - 0.5, RACK_H - BASE_H - 0.3, RACK_D - 0.4,
      x, SLAB_H + midY, z, "#272d33")
  box("rack", rack, RACK_W + 0.12, 0.35, RACK_D + 0.12,
      x, SLAB_H + RACK_H + 0.08, z, "#0c0e10")

  -- Recessed front bezel
  local bezelZ = z + front * (RACK_D / 2 + 0.16)
  box("rack", rack, RACK_W - 0.55, RACK_H - 1.15, 0.30,
      x, SLAB_H + (1.0 + RACK_H - 0.15) / 2, bezelZ, "#0d1012")

  -- Tray faces
  local trayBottom = 1.0
  local switchH    = 3.2
  local computeTop = RACK_H - 0.9 - switchH
  local pitch      = (computeTop - trayBottom) / COMPUTE_TRAYS
  local faceZ      = z + front * (RACK_D / 2 + 0.33)
  local ledZ       = z + front * (RACK_D / 2 + 0.42)

  for t = 1, COMPUTE_TRAYS do
    local y = trayBottom + (t - 0.5) * pitch
    local shade = (t % 3 == 0) and "#2c333a" or "#21272d"
    box("rack", rack, RACK_W - 1.05, pitch * 0.72, 0.18, x, SLAB_H + y, faceZ, shade)

    local ledCol
    local m = (t * 7 + row * 3 + col + t) % 13
    if m == 0 then
      ledCol = "#ffb020"
    elseif m < 4 then
      ledCol = "#35d6ff"
    elseif m < 8 then
      ledCol = "#39ff88"
    else
      ledCol = "#9dffb3"
    end
    local led = box("rack", rack, 0.24, math.min(0.16, pitch * 0.26), 0.07,
                    x - RACK_W / 2 + 0.78, SLAB_H + y, ledZ, ledCol, ledCol)
    rack.leds = rack.leds or {}
    rack.leds[#rack.leds + 1] = { obj = led, base = ledCol, phase = (t + row * 5 + col * 7) }
  end

  -- Switch tray block
  local switchBottom = computeTop + 0.35
  local switchPitch  = (switchH - 0.55) / SWITCH_TRAYS
  for t = 1, SWITCH_TRAYS do
    local y = switchBottom + (t - 0.5) * switchPitch
    box("rack", rack, RACK_W - 1.05, switchPitch * 0.55, 0.16,
        x, SLAB_H + y, faceZ, "#1a2025")
  end

  -- NVIDIA green edge bars
  local stripX = RACK_W / 2 - 0.23
  for _, sx in ipairs({ -1, 1 }) do
    local bar = box("rack", rack, 0.13, RACK_H - 2.2, 0.10,
                    x + sx * stripX, SLAB_H + (2.0 + RACK_H - 0.2) / 2,
                    z + front * (RACK_D / 2 + 0.25),
                    "#76b900", "#76b900")
    rack.bars[#rack.bars + 1] = bar
  end
  box("rack", rack, RACK_W - 0.8, 0.16, 0.16,
      x, SLAB_H + RACK_H - 0.38, z + front * (RACK_D / 2 + 0.30),
      "#76b900", "#76b900")

  -- Status LED
  rack.blink = box("rack", rack, 0.30, 0.18, 0.08,
                   x + RACK_W / 2 - 0.85, SLAB_H + RACK_H - 0.75,
                   z + front * (RACK_D / 2 + 0.38),
                   "#39ff88", "#39ff88")

  -- D2C liquid manifolds (rear/top) - supply/return pipes and manifold block
  local rearZ = z - front * (RACK_D / 2 + 0.2)
  box("rack", rack, RACK_W - 0.9, 1.6, 0.4,
      x, SLAB_H + RACK_H - 1.0, rearZ, "#2a3138")
  -- supply pipe (cold) with animated flow
  flowPipe(RACK_W - 1.0, 0.18, 0.22,
      x - 0.8, SLAB_H + RACK_H - 0.6, rearZ + 0.35, "#1f9bff", 1, 1.2)
  -- return pipe (warm) with animated flow
  flowPipe(RACK_W - 1.0, 0.18, 0.22,
      x + 0.8, SLAB_H + RACK_H - 0.6, rearZ + 0.35, "#ff5a2a", -1, 1.0)

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
  box("cdu", cdu, 14.0, 3.0, 6.0, x, y, z, "#262b32")
  box("cdu", cdu, 13.6, 2.6, 5.6, x, y, z - 0.1, "#2f363d")
  -- coil/heat exchanger (copper)
  box("cdu", cdu, 13.0, 0.6, 5.0, x, y - 0.8, z - 0.1, "#b87333")
  -- pumps/headers
  box("cdu", cdu, 2.0, 2.2, 1.2, x - 5.0, y + 0.2, z + 2.8, "#1a1f24")
  box("cdu", cdu, 2.0, 2.2, 1.2, x + 5.0, y + 0.2, z + 2.8, "#1a1f24")
  -- supply/return manifolds (cold/hot)
  box("cdu", cdu, 13.2, 0.16, 0.24, x, y + 1.2, z + 3.0, "#1f9bff", "#1f9bff")
  box("cdu", cdu, 13.2, 0.16, 0.24, x, y + 0.8, z + 3.0, "#ff5a2a", "#ff5a2a")
  -- status indicators
  cdu.led = box("cdu", cdu, 0.6, 0.25, 0.12, x + 6.0, y + 1.25, z + 3.1, "#39ff88", "#39ff88")
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
      flowPipe(rowWidth + 4.6, 0.14, 0.26,
          0, SLAB_H + RACK_H + 2.35, z + dz - 0.25, "#1f9bff", 1, 0.9)
      flowPipe(rowWidth + 4.6, 0.14, 0.26,
          0, SLAB_H + RACK_H + 2.35, z + dz + 0.25, "#ff5a2a", -1, 0.8)
    end
  end

  -- Room walls (75% transparent)
  local function wall(x,y,z,w,h,d)
    local o = box(nil, nil, w,h,d,x,y,z,"#1a1f24")
    if o then o.transparency = 0.75 end
    return o
  end
  wall(0, SLAB_H + roomH / 2, -roomD / 2, roomW, roomH, 0.6)
  wall(0, SLAB_H + roomH / 2, roomD / 2, roomW, roomH, 0.6)
  wall(-roomW / 2, SLAB_H + roomH / 2, 0, 0.6, roomH, roomD)
  wall(roomW / 2, SLAB_H + roomH / 2, 0, 0.6, roomH, roomD)
  -- ceiling (transparent)
  local ceil = box(nil, nil, roomW, 0.8, roomD, 0, SLAB_H + roomH - 0.4, 0, "#15181c")
  if ceil then ceil.transparency = 0.75 end

  -- Liquid cooling plant on top of the room (roof)
  local roofY = SLAB_H + roomH + 1.6
  local plantW = math.min(roomW + 16.0, 72.0)
  -- chiller skid
  box(nil, nil, plantW * 0.5, 3.0, 10.0, -roomW * 0.25, roofY, -roomD * 0.25, "#2a3138")
  box(nil, nil, plantW * 0.48, 2.6, 9.0, -roomW * 0.25, roofY + 0.1, -roomD * 0.25, "#333a42")
  box(nil, nil, plantW * 0.5, 3.0, 10.0, roomW * 0.25, roofY, -roomD * 0.25, "#2a3138")
  box(nil, nil, plantW * 0.48, 2.6, 9.0, roomW * 0.25, roofY + 0.1, -roomD * 0.25, "#333a42")
  -- cooling towers
  for _, cx in ipairs({ -roomW * 0.18, -roomW * 0.12, roomW * 0.12, roomW * 0.18 }) do
    box(nil, nil, 5.0, 6.0, 5.0, cx, roofY + 4.0, roomD * 0.18, "#3b424a")
    box(nil, nil, 4.6, 5.6, 4.6, cx, roofY + 4.1, roomD * 0.18, "#444b54")
    box(nil, nil, 4.0, 0.4, 4.0, cx, roofY + 7.0, roomD * 0.18, "#5a626a", "#9dffb3")
  end
  -- main headers on roof with flow
  flowPipe(roomW + 20.0, 0.4, 0.6, 0, roofY + 3.2, -roomD * 0.25, "#1f9bff", 1, 1.4)
  flowPipe(roomW + 20.0, 0.4, 0.6, 0, roofY + 2.8, -roomD * 0.25, "#ff5a2a", -1, 1.2)
  -- risers down to room with flow
  for _, rx in ipairs({ -rowWidth / 3, 0, rowWidth / 3 }) do
    flowPipe(0.6, (roomH - PLENUM_H + 6.0), 0.6, rx, SLAB_H + (roomH - PLENUM_H + 6.0) / 2, -roomD / 2 - 1.2, "#1f9bff", 1, 1.0)
    flowPipe(0.6, (roomH - PLENUM_H + 6.0), 0.6, rx + 1.0, SLAB_H + (roomH - PLENUM_H + 6.0) / 2, -roomD / 2 - 1.2, "#ff5a2a", -1, 0.9)
  end

  -- Overhead CDUs/heat exchangers on ceiling trusses
  local cduY = SLAB_H + roomH - 4.2
  if rows >= 2 then
    addCDU(-rowWidth / 4, cduY, -rowZ[1] - ROW_GAP * 0.25, 1)
    addCDU(rowWidth / 4, cduY, -rowZ[1] - ROW_GAP * 0.25, 2)
  end
  if rows >= 2 then
    addCDU(-rowWidth / 4, cduY, rowZ[2] - ROW_GAP * 0.25, 3)
    addCDU(rowWidth / 4, cduY, rowZ[2] - ROW_GAP * 0.25, 4)
  end
  if rows >= 3 then
    addCDU(-rowWidth / 4, cduY, rowZ[3] - ROW_GAP * 0.25, 5)
    addCDU(rowWidth / 4, cduY, rowZ[3] - ROW_GAP * 0.25, 6)
  end
  if rows >= 4 then
    addCDU(-rowWidth / 4, cduY, rowZ[4] - ROW_GAP * 0.25, 7)
    addCDU(rowWidth / 4, cduY, rowZ[4] - ROW_GAP * 0.25, 8)
  end
  -- supply/return mains between CDUs and rows with flow
  for i = 1, #cdus do
    local c = cdus[i]
    local mz = nil
    if i <= 2 then mz = -rowZ[1] - ROW_GAP * 0.25
    elseif i <= 4 then mz = rowZ[2] - ROW_GAP * 0.25
    elseif i <= 6 then mz = rowZ[3] - ROW_GAP * 0.25
    else mz = rowZ[4] - ROW_GAP * 0.25
    end
    flowPipe(0.24, 0.24, rowWidth + 12.0, 0, cduY + 1.6, mz, "#1f9bff", 1, 0.8)
    flowPipe(0.24, 0.24, rowWidth + 12.0, 0, cduY + 1.25, mz, "#ff5a2a", -1, 0.7)
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
