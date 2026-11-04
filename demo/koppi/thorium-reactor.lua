--
-- Thorium Reactor Simulation
--
-- A molten salt thorium breeder/reactor simulation inspired by liquid fluoride
-- thorium reactor (LFTR) concepts. Unlike uranium/plutonium reactors, thorium-232
-- is fertile and breeds U-233 for fission. The system uses a molten salt fuel
-- loop, heat exchangers, a steam cycle, turbine and generator.
--
-- Power flows from the thorium reactor to a nearby NVIDIA Vera Rubin datacenter
-- via electrical transmission lines. The datacenter is connected over IP to a
-- nearby office building with workstations running AI agents that process robotics
-- and manufacturing data for space exploration to Mars.
--
-- Usage: bpp -f demo/koppi/thorium-reactor.lua
--

local common = require "common"

common.setTiming(1 / 25)

v.pre_sdl = [[
#include "colors.inc"
#include "metals.inc"
#include "glass.inc"
]]

local HOVER = {}
local function addHover(o, text)
  if not o or not text then return o end
  if type(objectKey) == "function" then
    pcall(function() HOVER[objectKey(o)] = text end)
  end
  pcall(function() o.hoverText = text end)
  return o
end

if v.onHover and type(objectKey) == "function" then
  v:onHover(function(N, obj, x, y, z)
    if obj then
      local key = objectKey(obj)
      if key and HOVER[key] then
        return HOVER[key]
      end
      if obj.hoverText then
        return obj.hoverText
      end
    end
    return nil
  end)
end

v:postSim(function(N)
  -- also update status if possible
  if HOVER and type(objectKey) == "function" and v.hoverObject then
    local obj = v:hoverObject()
    if obj then
      local key = objectKey(obj)
      if key and HOVER[key] then
        v.statusText = HOVER[key]
        return
      end
      if obj.hoverText then
        v.statusText = obj.hoverText
        return
      end
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Reactor parameters
-- ---------------------------------------------------------------------------
local REACTOR_POWER_MW = 300        -- thermal power
local ELECTRICAL_EFF = 0.42         -- thermal to electrical efficiency
local COOLANT_TEMP_HOT = 700        -- °C hot salt
local COOLANT_TEMP_COLD = 565       -- °C cold salt
local FUEL_SALT_FLOW = 850          -- kg/s equivalent

-- Datacenter
local DC_PWR_MW = 120
local RACKS = 8

-- ---------------------------------------------------------------------------
-- Parameters
-- ---------------------------------------------------------------------------
v:addParam("reactorPower", 300, 100, 1000, 10, "Reactor thermal power (MWth)")
v:addParam("loadFactor", 95, 0, 100, 5, "Plant load factor (%)")
v:addParam("dcLoad", 85, 0, 100, 5, "Datacenter load (%)")
v:addParam("coolantFlow", 850, 100, 1500, 10, "Coolant flow rate (kg/s)")
v:addParam("turbineSpeed", 3000, 1500, 3600, 50, "Turbine speed (RPM)")
v:addParam("pue", 1.12, 1.0, 1.6, 0.01, "Datacenter PUE")
v:addParam("netExport", 0, -200, 200, 10, "Grid export/import (MW)")
v:addParam("ambientTemp", 25, -10, 50, 1, "Ambient temp (°C)")

-- ---------------------------------------------------------------------------
-- Scene setup
-- ---------------------------------------------------------------------------
local floor = Plane(0, 1, 0, 0, 1000)
floor.col = "#151820"
floor.friction = 1
floor.sdl = [[
  texture {
    pigment {
      checker
      color rgb <0.09,0.1,0.13>
      color rgb <0.12,0.14,0.17>
      scale 8
    }
    finish { ambient 0.12 diffuse 0.6 specular 0.4 roughness 0.02 reflection 0.05 }
    normal { bumps 0.01 scale 4 }
  }
]]
v:add(floor)

local function hexToRGB(col)
  if type(col) ~= "string" then return "0.2,0.22,0.25" end
  local r,g,b = col:match("#(%x%x)(%x%x)(%x%x)")
  if not r then return "0.2,0.22,0.25" end
  return string.format("%g,%g,%g", tonumber(r,16)/255, tonumber(g,16)/255, tonumber(b,16)/255)
end

local function metalBox(x,y,z,w,h,d,col,emission)
  local o = Cube(w,h,d,0)
  o.pos = btVector3(x,y,z)
  o.col = col or "#2a3038"
  o.friction = 0.8
  o.collides = false
  if emission then o.emission = emission end
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(o.col) .. [[> }
      finish { ambient 0.06 diffuse 0.5 specular 0.9 roughness 0.003 reflection 0.25 metallic }
      normal { bumps 0.005 scale 2 }
    }
  ]]
  v:add(o)
  return o
end

local function glassBox(x,y,z,w,h,d,col)
  local o = Cube(w,h,d,0)
  o.pos = btVector3(x,y,z)
  o.col = col or "#76b900"
  o.friction = 0.8
  o.collides = false
  o.emission = col or "#76b900"
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(o.col) .. [[> transmit 0.2 }
      finish { ambient 0.01 diffuse 0.3 specular 0.95 roughness 0.0005 reflection 0.5 }
    }
    interior { ior 1.52 }
  ]]
  v:add(o)
  return o
end

-- ---------------------------------------------------------------------------
-- Thorium Reactor Building
-- ---------------------------------------------------------------------------
local reactorX, reactorZ = -400, 1100
local rb = metalBox(reactorX, 12, reactorZ, 40, 24, 40, "#1f242b")
rb.transparency = 0.35
rb.sdl = [[
  texture {
    pigment { color rgb <0.12,0.14,0.17> transmit 0.35 }
    finish { ambient 0.06 diffuse 0.4 specular 0.7 roughness 0.01 reflection 0.15 }
  }
]]
local rb2 = metalBox(reactorX, 12, reactorZ, 38, 22, 38, "#252b33")
rb2.transparency = 0.45
rb2.sdl = [[
  texture {
    pigment { color rgb <0.15,0.17,0.2> transmit 0.45 }
    finish { ambient 0.05 diffuse 0.35 specular 0.7 roughness 0.01 reflection 0.12 }
  }
]]
-- Containment dome
local cont = Sphere(12, 0)
cont.pos = btVector3(reactorX, 28, reactorZ)
cont.col = "#2a313a"
cont.collides = false
cont.sdl = [[
  texture {
    pigment { color rgb <0.16,0.19,0.23> }
    finish { ambient 0.06 diffuse 0.45 specular 0.85 roughness 0.006 reflection 0.25 metallic }
    normal { bumps 0.008 scale 3 }
  }
]]
v:add(cont)
-- Reactor vessel
local vessel = addHover(metalBox(reactorX, 18, reactorZ, 10, 16, 10, "#3a424b"), "Thorium Molten Salt Reactor\nFuel: Th-232 -> U-233\nThermal Power: ~300 MWth\nCoolant: FLiBe molten salt")
vessel.sdl = [[
  texture {
    pigment { color rgb <0.23,0.26,0.3> }
    finish { ambient 0.06 diffuse 0.5 specular 0.9 roughness 0.003 reflection 0.28 metallic }
    normal { bumps 0.006 scale 2 }
  }
]]
metalBox(reactorX, 18, reactorZ, 9, 15, 9, "#444c56")
-- Glow
local coreGlow = Sphere(3.5, 0)
coreGlow.pos = btVector3(reactorX, 18, reactorZ)
coreGlow.col = "#ff6b00"
coreGlow.emission = "#ff6b00"
coreGlow.collides = false
coreGlow.sdl = [[
  texture {
    pigment { color rgb <1.0,0.42,0> transmit 0.3 }
    finish { ambient 0.3 diffuse 0.4 specular 0.8 roughness 0.001 emission 0.6 }
  }
]]
coreGlow = addHover(coreGlow, "Reactor Core\nFission: U-233 chain reaction\nHeat generation")
v:add(coreGlow)
-- Heat exchangers
metalBox(reactorX + 25, 10, reactorZ, 12, 8, 16, "#2f363d")
metalBox(reactorX + 25, 10, reactorZ, 11, 7, 15, "#363d45")
-- Steam generators
metalBox(reactorX + 25, 10, reactorZ + 20, 10, 8, 12, "#2f363d")
metalBox(reactorX + 25, 10, reactorZ + 20, 9, 7, 11, "#363d45")
-- Control room
metalBox(reactorX - 25, 8, reactorZ, 12, 12, 16, "#242a31")
glassBox(reactorX - 25, 12, reactorZ + 8, 10, 4, 0.5, "#9dffb3")

-- ---------------------------------------------------------------------------
-- Turbine Hall
-- ---------------------------------------------------------------------------
local turbineX, turbineZ = -100, 1100
local tb = metalBox(turbineX, 10, turbineZ, 50, 20, 30, "#20262d")
tb.transparency = 0.3
tb.sdl = [[
  texture {
    pigment { color rgb <0.13,0.15,0.18> transmit 0.3 }
    finish { ambient 0.06 diffuse 0.4 specular 0.7 roughness 0.01 reflection 0.12 }
  }
]]
local tb2 = metalBox(turbineX, 10, turbineZ, 48, 18, 28, "#262c34")
tb2.transparency = 0.4
tb2.sdl = [[
  texture {
    pigment { color rgb <0.15,0.17,0.2> transmit 0.4 }
    finish { ambient 0.05 diffuse 0.35 specular 0.7 roughness 0.01 reflection 0.1 }
  }
]]
-- Turbine
local turbine = addHover(metalBox(turbineX, 12, turbineZ, 16, 10, 8, "#3a424b"), "Steam Turbine\nConverts thermal to mechanical")
turbine.sdl = [[
  texture {
    pigment { color rgb <0.23,0.26,0.3> }
    finish { ambient 0.06 diffuse 0.5 specular 0.9 roughness 0.003 reflection 0.3 metallic }
    normal { bumps 0.004 scale 2 }
  }
]]
local turbineRotor = addHover(metalBox(turbineX, 12, turbineZ, 14, 8, 6, "#555d66"), "Turbine Rotor (rotating)")
turbineRotor.sdl = [[
  texture {
    pigment { color rgb <0.33,0.36,0.4> }
    finish { ambient 0.06 diffuse 0.5 specular 0.95 roughness 0.002 reflection 0.35 metallic }
    normal { bumps 0.003 scale 1.5 }
  }
]]
-- Generator
local generator = addHover(metalBox(turbineX + 18, 12, turbineZ, 12, 10, 8, "#3a424b"), "Electrical Generator\nMechanical -> Electrical")
generator.sdl = [[
  texture {
    pigment { color rgb <0.23,0.26,0.3> }
    finish { ambient 0.06 diffuse 0.5 specular 0.9 roughness 0.003 reflection 0.3 metallic }
    normal { bumps 0.004 scale 2 }
  }
]]
local genRotor = addHover(metalBox(turbineX + 18, 12, turbineZ, 10, 8, 6, "#555d66"), "Generator Rotor (rotating)")
genRotor.sdl = [[
  texture {
    pigment { color rgb <0.33,0.36,0.4> }
    finish { ambient 0.06 diffuse 0.5 specular 0.95 roughness 0.002 reflection 0.35 metallic }
    normal { bumps 0.003 scale 1.5 }
  }
]]
local genGlow = addHover(glassBox(turbineX + 18, 16, turbineZ, 2, 2, 0.3, "#ffd700"), "Generator Output\nAC Power")
genGlow.emission = "#ffd700"
-- Condenser
metalBox(turbineX - 18, 8, turbineZ, 14, 6, 20, "#2f363d")
metalBox(turbineX - 18, 8, turbineZ, 13, 5, 19, "#363d45")

-- ---------------------------------------------------------------------------
-- Switchyard / Transmission
-- ---------------------------------------------------------------------------
local switchX, switchZ = 200, 1100
local sb = metalBox(switchX, 6, switchZ, 30, 12, 20, "#252b33")
sb.transparency = 0.25
sb.sdl = [[
  texture {
    pigment { color rgb <0.15,0.17,0.2> transmit 0.25 }
    finish { ambient 0.06 diffuse 0.4 specular 0.7 roughness 0.01 reflection 0.1 }
  }
]]
for i = 1, 4 do
  metalBox(switchX - 12 + (i-1)*8, 14, switchZ, 3, 16, 3, "#3a424b")
  glassBox(switchX - 12 + (i-1)*8, 22, switchZ, 1, 1, 0.2, "#ff6b00")
end

-- ---------------------------------------------------------------------------
-- Electrical lines to Datacenter
-- ---------------------------------------------------------------------------
local powerLines = {}
for i = 1, 3 do
  local p = Cube(80, 0.8, 0.8, 0)
  p.pos = btVector3(250, 18 + i*2, 1100)
  p.col = "#ff6b00"
  p.emission = "#ff6b00"
  p.collides = false
  p.sdl = [[
    texture {
      pigment {
        gradient x
        color_map {
          [0.0 color rgb <1.0,0.42,0>]
          [0.2 color rgb <1,1,0.5>]
          [0.4 color rgb <1.0,0.42,0>]
          [0.6 color rgb <1,1,0.5>]
          [0.8 color rgb <1.0,0.42,0>]
          [1.0 color rgb <1,1,0.5>]
        }
        scale 1.5
        translate x * clock * 2
      }
      finish { ambient 0.3 diffuse 0.6 specular 0.6 emission 0.4 }
    }
  ]]
  v:add(p)
  powerLines[#powerLines+1] = p
  -- Towers
  for x = 270, 320, 25 do
    metalBox(x, 12, 1100, 2, 24, 2, "#3a424b")
    metalBox(x, 24, 1100, 4, 1, 4, "#444c56")
  end
end

-- ---------------------------------------------------------------------------
-- NVIDIA Vera Rubin Datacenter (NSA-scale)
-- ---------------------------------------------------------------------------
local dcX, dcZ = 600, 1100
local function dcMetal(x,y,z,w,h,d,col)
  local o = Cube(w,h,d,0)
  o.pos = btVector3(x,y,z)
  o.col = col or "#1f242b"
  o.friction = 0.8
  o.collides = false
  o.sdl = [[
    texture {
      pigment { color rgb <]] .. hexToRGB(col or "#1f242b") .. [[> }
      finish { ambient 0.08 diffuse 0.55 specular 0.7 roughness 0.008 reflection 0.2 metallic }
    }
  ]]
  v:add(o)
  return o
end
local dcW, dcD = 220, 160
dcMetal(dcX, 0.5, dcZ, dcW, 1, dcD, "#14181d")
dcMetal(dcX, 4, dcZ, dcW-2, 7, dcD-2, "#101418")
-- translucent edged room
for i = 1, 4 do
  local ex,ez = dcX, dcZ
  if i==1 then ex=dcX+dcW/2 end
  if i==2 then ez=dcZ+dcD/2 end
  if i==3 then ex=dcX-dcW/2 end
  if i==4 then ez=dcZ-dcD/2 end
  local e = Cube(i%2==1 and 1.2 or dcW, 0.8, i%2==1 and dcD or 1.2, 0)
  e.pos = btVector3(ex, 0.4, ez)
  e.col = "#76b900"
  e.emission = "#76b900"
  e.transparency = 0.95
  e.collides = false
  e.sdl = [[
    texture {
      pigment { color rgb <0.46,0.725,0> transmit 0.95 }
      finish { ambient 0.08 diffuse 0.25 specular 0.85 roughness 0.01 emission 0.35 }
    }
  ]]
  e.hoverText = "NSA-scale AI datacenter perimeter"
  v:add(e)
  local e2 = Cube(i%2==1 and 1.2 or dcW, 0.8, i%2==1 and dcD or 1.2, 0)
  e2.pos = btVector3(ex, 7.2, ez)
  e2.col = "#76b900"
  e2.emission = "#76b900"
  e2.transparency = 0.95
  e2.collides = false
  e2.sdl = [[
    texture {
      pigment { color rgb <0.46,0.725,0> transmit 0.95 }
      finish { ambient 0.08 diffuse 0.25 specular 0.85 roughness 0.01 emission 0.35 }
    }
  ]]
  e2.hoverText = "NSA-scale AI datacenter perimeter"
  v:add(e2)
end
-- many rows of racks (NSA scale)
local rows = 8
local perRow = 8
for ri = 1, rows do
  local rz = dcZ - (rows-1)*16/2 + (ri-1)*16
  local front = (ri % 2 == 1) and 1 or -1
  for j = 1, perRow do
    local rx = dcX - (perRow-1)*14/2 + (j-1)*14
    local r = dcMetal(rx, 6.5, rz, 8, 13, 9, "#141820")
    r.hoverText = "NVIDIA Vera Rubin NVL72 (NSA-scale)\n72 GPUs | 20.7 TB HBM4\nLiquid cooled D2C\nAI training/inference"
    dcMetal(rx, 6.5, rz, 7.5, 12, 8.5, "#1a2028")
    local led1 = glassBox(rx - 3.8, 6.5, rz + front*4.8, 0.25, 11, 0.12, "#39ff88")
    led1.emission = "#39ff88"
    led1.hoverText = "Rack status LEDs"
    local led2 = glassBox(rx + 3.8, 6.5, rz + front*4.8, 0.25, 11, 0.12, "#35d6ff")
    led2.emission = "#35d6ff"
    led2.hoverText = "Rack network/thermal LEDs"
    glassBox(rx, 13, rz, 7.4, 0.18, 8.4, "#76b900")
    dcMetal(rx, 12, rz - front*5.2, 7.4, 1.4, 0.35, "#262c33")
    dcMetal(rx, 14, rz, 12, 2.2, 4.5, "#242a31")
    local cdu = glassBox(rx, 15.4, rz, 0.5, 0.25, 0.12, "#39ff88")
    cdu.hoverText = "Overhead CDU/Heat Exchanger"
  end
end
-- massive pipes
for i = 1, 6 do
  local p = Cube(dcW-10, 0.4, 0.4, 0)
  p.pos = btVector3(dcX, 13.8 + i*0.5, dcZ)
  p.col = "#1f9bff"
  p.emission = "#1f9bff"
  p.collides = false
  p.sdl = [[
    texture {
      pigment {
        gradient z
        color_map {
          [0.0 color rgb <0.12,0.61,1.0>]
          [0.25 color rgb <1,1,1>]
          [0.5 color rgb <0.12,0.61,1.0>]
          [0.75 color rgb <1,1,1>]
          [1.0 color rgb <0.12,0.61,1.0>]
        }
        scale 2
        translate z * clock
      }
      finish { ambient 0.3 diffuse 0.5 specular 0.6 emission 0.4 }
    }
  ]]
  v:add(p)
end
-- Network
glassBox(dcX + dcW/2 + 2, 8, dcZ, 3, 6, 3, "#1f9bff")
glassBox(dcX + dcW/2 + 2, 8, dcZ, 2.5, 5.5, 2.5, "#35d6ff")

-- ---------------------------------------------------------------------------
-- Fiber optic / IP connection to Office
-- ---------------------------------------------------------------------------
fibers = {}
for i = 1, 2 do
  local f = Cube(60, 0.4, 0.4, 0)
  f.pos = btVector3(880, 14 + i*0.6, 1100)
  f.col = "#1f9bff"
  f.emission = "#1f9bff"
  f.collides = false
  f.sdl = [[
    texture {
      pigment {
        gradient x
        color_map {
          [0.0 color rgb <0.12,0.61,1.0>]
          [0.25 color rgb <1,1,1>]
          [0.5 color rgb <0.12,0.61,1.0>]
          [0.75 color rgb <1,1,1>]
          [1.0 color rgb <0.12,0.61,1.0>]
        }
        scale 3
        translate x * clock
      }
      finish { ambient 0.3 diffuse 0.5 specular 0.6 emission 0.4 }
    }
  ]]
  v:add(f)
  fibers[#fibers+1] = f
end
metalBox(920, 8, 1100, 2, 16, 2, "#3a424b")
metalBox(920, 16, 1100, 4, 1, 4, "#444c56")

-- ---------------------------------------------------------------------------
-- Office Building with Workstations & AI Agents
-- ---------------------------------------------------------------------------
local offX, offZ = 1050, 1100
local ob = metalBox(offX, 12, offZ, 40, 24, 30, "#20262d")
ob.transparency = 0.25
ob.sdl = [[
  texture {
    pigment { color rgb <0.13,0.15,0.18> transmit 0.25 }
    finish { ambient 0.06 diffuse 0.4 specular 0.7 roughness 0.01 reflection 0.12 }
  }
]]
local ob2 = metalBox(offX, 12, offZ, 38, 22, 28, "#262c34")
ob2.transparency = 0.35
ob2.sdl = [[
  texture {
    pigment { color rgb <0.15,0.17,0.2> transmit 0.35 }
    finish { ambient 0.05 diffuse 0.35 specular 0.7 roughness 0.01 reflection 0.1 }
  }
]]
glassBox(offX, 24, offZ, 38, 0.5, 28, "#9dffb3")
for x = -14, 14, 7 do
  for z = -10, 10, 10 do
    metalBox(offX + x, 10, offZ + z, 4, 6, 3, "#1f252d")
    glassBox(offX + x, 12.5, offZ + z + 1.6, 3.5, 2.5, 0.1, "#35d6ff")
    glassBox(offX + x + 1.5, 10.5, offZ + z - 1.6, 0.8, 0.8, 0.1, "#39ff88")
  end
end
-- Server racks in office
for i = 1, 4 do
  metalBox(offX - 16, 10, offZ - 8 + (i-1)*6, 3, 12, 4, "#181d24")
  glassBox(offX - 16, 10, offZ - 8 + (i-1)*6 + 2.1, 2.5, 10, 0.1, "#1f9bff")
end

-- ---------------------------------------------------------------------------
-- Status
-- ---------------------------------------------------------------------------
local function getParams()
  local rp = tonumber(v:getParam("reactorPower")) or REACTOR_POWER_MW
  local lf = (tonumber(v:getParam("loadFactor")) or 95) / 100.0
  local dl = (tonumber(v:getParam("dcLoad")) or 85) / 100.0
  local flow = tonumber(v:getParam("coolantFlow")) or FUEL_SALT_FLOW
  local rpm = tonumber(v:getParam("turbineSpeed")) or 3000
  local pue = tonumber(v:getParam("pue")) or 1.12
  local net = tonumber(v:getParam("netExport")) or 0
  local amb = tonumber(v:getParam("ambientTemp")) or 25
  local thermal = rp * lf
  local elec = thermal * ELECTRICAL_EFF
  local heat = thermal * (1 - ELECTRICAL_EFF)
  local dcPwr = DC_PWR_MW * dl * pue
  return thermal, elec, heat, dcPwr, lf, dl, flow, rpm, pue, net, amb
end

v.statusText = "Thorium Reactor | Turbine-Generator | Vera Rubin DC | IP to Office/AI Agents | Mars Robotics/Manufacturing"

v:preStart(function()
  local thermal, elec, heat, dcPwr = getParams()
  print(string.format("Thorium-Reactor: %.0f MWth | %.0f MWe | %.0f MW heat | DC %.0f MW | Connected to Office AI agents (Mars robotics/manufacturing)", thermal, elec, heat, dcPwr))
end)

v:postSim(function(N)
  local thermal, elec, heat, dcPwr, lf, dl, flow, rpm, pue, net, amb = getParams()
  local t = N * (v.timeStep or 0.04)
  v.statusText = string.format("Thorium LFTR | Th-232->U-233 | %.0f MWth (%.0f%%) | %.0f MWe | %.0f MW heat | Flow %.0f kg/s | RPM %d | PUE %.2f | Net %+d MW | Amb %d°C | DC NSA-scale %.0f MW (%.0f%%) | IP: Office AI->Mars Robotics/Manufacturing | Flow active", thermal, lf*100, elec, heat, flow, rpm, pue, net, amb, dcPwr, dl*100)
  if coreGlow then
    coreGlow.emission = string.format("#%02x%02x00", math.floor(255*(0.85+0.15*math.sin(t*1.7))), math.floor(107*(0.8+0.2*math.cos(t*2.1))))
  end
  if genGlow then
    genGlow.emission = string.format("#%02x%02x00", math.floor(255*(0.92+0.08*math.sin(t*3))), math.floor(215*(0.9+0.1*math.cos(t*2.5))))
  end
  local ang = math.rad(rpm/60*360*(v.timeStep or 0.04))
  if turbineRotor and turbineRotor.rotate then
    turbineRotor:rotate(btVector3(0,0,1), ang)
  elseif turbineRotor then
    if not turbineRotor._ang then turbineRotor._ang = 0 end
    turbineRotor._ang = turbineRotor._ang + ang
  end
  if genRotor and genRotor.rotate then
    genRotor:rotate(btVector3(0,0,1), ang)
  elseif genRotor then
    if not genRotor._ang then genRotor._ang = 0 end
    genRotor._ang = genRotor._ang + ang
  end
  -- animate power lines
  for _, p in ipairs(powerLines) do
    p.emission = string.format("#%02x%02x00", math.floor(255*(0.9+0.1*math.sin(t*4))), math.floor(107*(0.9+0.1*math.cos(t*3.5))))
  end
  for _, f in ipairs(fibers) do
    f.emission = string.format("#%02x%02x%02x", math.floor(31+224*math.sin(t*6)), math.floor(156+99*math.cos(t*5)), 255)
  end

  -- City traffic on the harbour-town ways (scene coords: city spans X[-1500,1500], Z[-2500,0]).
  if cityCars then
    for _, c in ipairs(cityCars) do
      local x, z = c.pos.x, c.pos.z
      if c._axis == "x" then
        if c._dir == 1 then x = x + c._speed else x = x - c._speed end
        if x > 1500 then x = -1450 elseif x < -1500 then x = 1450 end
      else
        if c._dir == 1 then z = z + c._speed else z = z - c._speed end
        if z > 0 then z = -2400 elseif z < -2500 then z = -100 end
      end
      c.pos = btVector3(x, c.pos.y, z)
    end
  end
  if cityPeds then
    for _, p in ipairs(cityPeds) do
      local x, z = p.pos.x, p.pos.z
      if p._axis == "x" then
        if p._dir == 1 then x = x + p._speed else x = x - p._speed end
        if x > 1500 then x = -1450 elseif x < -1500 then x = 1450 end
      else
        if p._dir == 1 then z = z + p._speed else z = z - p._speed end
        if z > 0 then z = -2400 elseif z < -2500 then z = -100 end
      end
      p.pos = btVector3(x, p.pos.y, z)
      if p._head then
        p._head.pos = btVector3(x, p.pos.y + 1.2, z)
      end
    end
  end
end)

common.setCamera(btVector3(1250, 180, 900), btVector3(350, 20, 1100), math.rad(55), { horizontal = true })

-- EOF

-- City environment via ArtificialPhysics world generator (harbour town) + sun/clouds + cars/people
do
  local here = "/home/koppi/bpp/demo/WyomingWill/ArtificialPhysics"
  package.path = here .. "/?.lua;" .. here .. "/?/init.lua;" .. package.path
  local ok, World = pcall(require, "lib.world")
  if ok then
    local w = World.preset("harbour-town", { seed = 42 })
    local S = 1.0
    local b = w.bounds
    local cx = -((b.x0 + b.x1) / 2) * S
    local cy = -((b.y0 + b.y1) / 2) * S
    local objs = w:toBPP(v, { scale = S, colors = { obstacle = "#6b6b6b", wall = "#b8b8b8", floor = "#151820", water = "#1a4d73" } })
    for _,o in ipairs(objs) do
      if o and o.pos then
        local p = o.pos
        -- World uses toBPP with World.bppZ mapping; just center in XZ around origin
        o.pos = btVector3(p.x + cx, p.y, p.z)
      end
    end
  else
    local lake = Plane(0,1,0,-0.5,2000)
    lake.col = "#1a4d73"; lake.collides=false
    lake.sdl=[[ texture { pigment { color rgb <0.1,0.3,0.45> } finish { ambient 0.25 diffuse 0.35 specular 0.95 roughness 0.01 reflection 0.4 } } ]]
    v:add(lake)
  end
  -- Sun
  local sun = Sphere(12,0)
  sun.pos = btVector3(80,320,-600)
  sun.col = "#ffd93d"; sun.emission = "#ffd93d"; sun.collides=false
  sun.sdl=[[ texture { pigment { color rgb <1.0,0.85,0.24> } finish { ambient 0.9 diffuse 0.15 specular 0.9 roughness 0.001 emission 1.0 } } ]]
  v:add(sun)
  -- Clouds
  for i=1,35 do
    local c=Sphere(18 + math.random()*14,0)
    c.pos=btVector3(0 + i*80 + math.random()*80, 180 + math.random()*90, -700 + math.random()*500)
    c.col="#f0f4ff"; c.transparency=0.2; c.collides=false
    c.sdl=[[ texture { pigment { color rgb <0.95,0.97,1.0> transmit 0.2 } finish { ambient 0.6 diffuse 0.18 specular 0.5 roughness 0.1 emission 0.2 } } ]]
    v:add(c)
  end
  -- City traffic on the harbour-town ways (scene coords: city spans X[-1500,1500], Z[-2500,0]).
  cityCars = {}
  local function streetCar(x, z, col, dir, speed, axis)
    axis = axis or "x"
    local c = Cube(4.6, 1.7, 2.5, 0)
    c.pos = btVector3(x, 0.95, z)
    c.col = col; c.collides = false
    c._axis = axis; c._dir = dir; c._speed = speed
    c._lane = (axis == "x") and z or x
    c.sdl = [[ texture { pigment { color rgb <]] .. hexToRGB(col) .. [[> } finish { ambient 0.07 diffuse 0.6 specular 0.78 roughness 0.006 reflection 0.2 metallic } } ]]
    v:add(c); cityCars[#cityCars + 1] = c
  end

  -- Arterial A: north-south, west-central (scene X ~ -250)
  for i = 1, 5 do
    streetCar(-260, -1200 - i * 200, "#c44536",  1, 0.24, "z")
    streetCar(-240, -2400 + i * 200, "#3a7ca5", -1, 0.20, "z")
  end
  -- Arterial B: east-west, south side (scene Z ~ -1475 / -1675)
  for i = 1, 6 do
    streetCar(300 + i * 180, -1475,  "#f4e06a", 1, 0.20, "x")
    streetCar(1300 - i * 180, -1675, "#8b5cf6", -1, 0.18, "x")
  end

  -- Pedestrians on the city sidewalks
  cityPeds = {}
  local function sidewalkPed(x, z, dir, speed, axis)
    axis = axis or "x"
    local p = Cylinder(0.36, 2.0, 0)
    p.pos = btVector3(x, 1.0, z)
    p.col = "#d97757"; p.collides = false
    p._axis = axis; p._dir = dir; p._speed = speed
    p._lane = (axis == "x") and z or x
    p.sdl = [[ texture { pigment { color rgb <0.73,0.47,0.34> } finish { ambient 0.24 diffuse 0.7 specular 0.24 roughness 0.14 } } ]]
    v:add(p); cityPeds[#cityPeds + 1] = p
    local head = Sphere(0.32, 0)
    head.pos = btVector3(x, 2.2, z)
    head.col = "#fbbf24"; head.collides = false
    head.sdl = [[ texture { pigment { color rgb <0.98,0.75,0.14> } finish { ambient 0.28 diffuse 0.64 specular 0.28 roughness 0.16 } } ]]
    v:add(head)
    p._head = head
  end
  for i = 1, 6 do
    sidewalkPed(-280, -1300 - i * 150,  1, 0.10, "z")
    sidewalkPed(-220, -2300 + i * 150, -1, 0.09, "z")
    sidewalkPed(250 + i * 160, -1600,  1, 0.09, "x")
    sidewalkPed(1200 - i * 160, -1400, -1, 0.10, "x")
  end
end

