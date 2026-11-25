--
-- LightSys indoor scene, ported from demo_indoor2.pov (LightSys IV by Ive, 2003)
--
-- A furnished room lit with LightSys: fluorescent tubes, incandescent lamps,
-- a spotlight and a window/daylight source, all through CIE XYZ color
-- management. The lighting "tune" matches the #switch (Tune) in the original.
--
-- Original POV-Ray scene: demo_indoor2.pov
-- Author: Ive, Mai-2003
--
-- Usage: bpp -f demo/koppi/lightsys-demo-indoor2.lua
--

local color  = require "color"
local common = require "common"

-- Lighting "tune" (matches the #switch (Tune) in the original .pov):
--   0 = User       (tubes + lamps + spotlight, no window)
--   1 = Daylight   (window only)
--   2 = Incandescent (lamps + spotlight, warm 3200 K)  [default]
--   3 = Fluorescent (tubes + spotlight)
v:addParam("tune", 2, 0, 3, 1,
  "lighting tune: 0=user (all), 1=daylight, 2=incandescent, 3=fluorescent")

-- Build the POV-Ray preamble: CIE + LightSys includes, spectra, lumens,
-- pigment declarations and the light sources themselves.
--
-- This is raw POV-Ray SDL, written verbatim into the exported .pov, so
-- coordinates here are POV-space (z as in the original .pov). bpp objects
-- added with v:add() live in Bullet space and are mirrored through Z on
-- export, so their positions negate z relative to the .pov.
local function buildPreSDL(tune)
  return [==[
#include "colors.inc"
#include "math.inc"
#include "bpp_CIE.inc"
#include "bpp_CIE_tools.inc"
#include "bpp_lightsys.inc"
#include "bpp_lightsys_constants.inc"
#include "rspd_aster.inc"
#include "rspd_jvp.inc"
#include "rspd_pantone_coated.inc"

#declare Lightsys_Brightness = 0.67;

#declare AreaLight = off;

#declare PutMondrian = off;
#declare PutChairs   = on;
#declare PutDesk     = on;

#declare User_Tune         = 0;
#declare Daylight_Tune     = 1;
#declare Incandescent_Tune = 2;
#declare Fluorescent_Tune  = 3;

#declare Tune = ]==] .. tune .. [==[;  // select 0..3

#switch (Tune)
  #case (Daylight_Tune)
    #declare Film_Temperature = Kt_Daylight_Film;
    #declare L1  = off;// neon tubes
    #declare L2  = off;// incandescent lamps
    #declare L3  = off;// spotlight
    #declare LD  = on; // window
  #break
  #case (Incandescent_Tune)
    #declare Film_Temperature = Kt_Indoor_Film;
    #declare L1  = off;// neon tubes
    #declare L2  = on; // incandescent lamps
    #declare L3  = on; // spotlight
    #declare LD  = off;// window
  #break
  #case (Fluorescent_Tune)
    #declare Film_Temperature = Kt_Fluorescent_Film;
    #declare L1  = on; // neon tubes
    #declare L2  = off;// incandescent lamps
    #declare L3  = on; // spotlight
    #declare LD  = off;// window
  #break
  #else // User_Tune
    #declare Film_Temperature = Kt_TungstenA_Film;
    #declare L1  = on; // neon tubes
    #declare L2  = on; // incandescent lamps
    #declare L3  = on; // spotlight
    #declare LD  = off;// window
#end

// use the Judd/Vos modified observer
//CIE_Observer(CIE_1978)

// ColorSystem and Whitepoint for light sources
CIE_ColorSystemWhitepoint(Beta_ColSys, Blackbody2Whitepoint(Film_Temperature))

// ColorSystem and Whitepoint used for ALL pigment colors
CIE_ColorSystem(Beta_ColSys)

// spectra and lumens for light sources
// LS_Neon/LS_Argon line-spectrum identifiers are not defined in bpp's
// includes, so the fluorescent tubes use a predefined cool-white
// fluorescent spectrum instead.
#declare LC1 = EmissiveSpectrum(ES_GTE_341_Cool);
#declare LM1 = 300;

#declare LC2 = EmissiveSpectrum(ES_Incandescent_60w);
#declare LM2 = Lm_Incandescent_60w;

#declare LC3 = EmissiveSpectrum(ES_Mitsubishi_Standard_Fluorescent);
#declare LM3 = 965;

#declare LCD = Daylight(6600);
#declare LMD = 2100;

// colors for pigment/texture definitions
#declare Wall_Color   = ReflectiveSpectrum(RS_White_Paint_1);
#declare Brick_Color  = ReflectiveSpectrum(RS_Red_smooth_faced_Brick);
#declare Mortar_Color = ReflectiveSpectrum(RS_Construction_Concrete_1);
#declare Floor_Color  = rgb <0.12, 0.18, 0.10>; // dark greenish floor

// texture definitions
#declare T_Floor = texture {
  pigment { crackle
    color_map {
      [0.0 rgb Mortar_Color*0.5 ]
      [0.1 rgb Floor_Color]
    }
    scale 12
  }
}

#declare T_Brick_Wall = texture {
  pigment {brick color Mortar_Color color Brick_Color scale 2.5 turbulence 0.05}
  normal {brick scale 2.5 turbulence 0.05}
  rotate y*90
  translate <0.5, 0.1,0>
}

#declare T_White_Wall = texture {
  pigment { wrinkles
    color_map {
      [0 rgb Wall_Color]
      [1 rgb Wall_Color*0.92]
    }
    scale 7
  }
}

#declare T_Black_Plastic = texture {
  pigment{rgb ReflectiveSpectrum(RS_Black_5_C)}
  finish {diffuse 0.8 specular 0.3 roughness 0.009}
}

#declare F_Mondrian = finish {specular 0.3 brilliance 2 roughness 0.011}

global_settings {
  assumed_gamma 1.0
  max_trace_level 15
}

// ------------------------------------------------------------
// Light sources
// ------------------------------------------------------------

// Neon tubes (fluorescent), three tubes along the ceiling
#if (L1)
#declare C1 = Light_Color(LC1, LM1 * 1/3);
light_source { 0, rgb C1
   Light_Fading()
   translate <-20,-6,0>
}
light_source { 0, rgb C1
   Light_Fading()
   translate < 0,-6,0>
}
light_source { 0, rgb C1
   Light_Fading()
   translate < 20,-6,0>
}
#end

// Incandescent lamps
#if (L2)
#declare C2 = Light_Color(LC2, LM2);
light_source { 0, rgb C2
   Light_Fading()
   translate < 65,185,40>
}
light_source { 0, rgb C2
   Light_Fading()
   translate <-65,185,40>
}
#end

// Spotlight pointing at the back wall
#if (L3)
#declare C3 = Light_Color(LC3, LM3);
light_source { 0, rgb C3
   spotlight radius 24 falloff 35 tightness 15 point_at <0,128,0>
   Light_Fading()
   translate < 38,275,180>
}
#end

// Window / daylight
#if (LD)
#declare CD = Light_Color(LCD, LMD);
light_source { 0, rgb CD
   area_light <80,0,0>, <0,120,0>, 6, 8 adaptive 2 jitter
   Light_Fading()
   Light_Spot_Cos_Falloff(z)
   translate <0,70,9>
}
#end
]==]
end

v.pre_sdl = buildPreSDL(v:getParam("tune"))

-- ---------------------------------------------------------------------------
-- Room geometry (Bullet space: z is negated on POV export, so negate z
-- relative to the original .pov coordinates)
-- ---------------------------------------------------------------------------

local roomObjs = {}

local function addRoom()
  -- floor: plane at y=0, crackle texture
  local floor = Cube(500, 0.2, 500, 0)
  floor.pos = btVector3(0, 0, 0)
  floor.col = color.lightgray
  floor.mass = 0
  floor.sdl = [[
    texture { T_Floor }
  ]]
  v:add(floor)
  table.insert(roomObjs, floor)

  -- ceiling: box at y=290..300, light wood
  local ceiling = Cube(420, 10, 520, 0)
  ceiling.pos = btVector3(0, 295, 0)
  ceiling.col = color.white
  ceiling.mass = 0
  ceiling.sdl = [[
    texture { pigment { color ReferenceRGB(LightWood) } }
  ]]
  v:add(ceiling)
  table.insert(roomObjs, ceiling)

  -- front wall (with where Mondrian would go)
  local frontWall = Cube(430, 300, 10, 0)
  frontWall.pos = btVector3(0, 150, -250)
  frontWall.col = color.white
  frontWall.mass = 0
  frontWall.sdl = [[
    texture { T_White_Wall }
  ]]
  v:add(frontWall)
  table.insert(roomObjs, frontWall)

  -- baseboard at front
  local frontBase = Cube(420, 4, 8, 0)
  frontBase.pos = btVector3(0, 2, -246)
  frontBase.col = color.black
  frontBase.mass = 0
  frontBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(frontBase)
  table.insert(roomObjs, frontBase)

  -- right wall (brick)
  local rightWall = Cube(10, 300, 500, 0)
  rightWall.pos = btVector3(200, 150, 0)
  rightWall.col = color.darkred
  rightWall.mass = 0
  rightWall.sdl = [[
    texture { T_Brick_Wall }
  ]]
  v:add(rightWall)
  table.insert(roomObjs, rightWall)

  local rightBase = Cube(8, 4, 500, 0)
  rightBase.pos = btVector3(196, 2, 0)
  rightBase.col = color.black
  rightBase.mass = 0
  rightBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(rightBase)
  table.insert(roomObjs, rightBase)

  -- left wall (with window opening)
  local leftWall = Cube(10, 300, 500, 0)
  leftWall.pos = btVector3(-200, 150, 0)
  leftWall.col = color.white
  leftWall.mass = 0
  leftWall.sdl = [[
    texture { T_White_Wall }
  ]]
  v:add(leftWall)
  table.insert(roomObjs, leftWall)

  local leftBase = Cube(8, 4, 500, 0)
  leftBase.pos = btVector3(-196, 2, 0)
  leftBase.col = color.black
  leftBase.mass = 0
  leftBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(leftBase)
  table.insert(roomObjs, leftBase)

  -- rear wall
  local rearWall = Cube(430, 300, 10, 0)
  rearWall.pos = btVector3(0, 150, 250)
  rearWall.col = color.white
  rearWall.mass = 0
  rearWall.sdl = [[
    texture { T_White_Wall }
  ]]
  v:add(rearWall)
  table.insert(roomObjs, rearWall)

  local rearBase = Cube(420, 4, 8, 0)
  rearBase.pos = btVector3(0, 2, 246)
  rearBase.col = color.black
  rearBase.mass = 0
  rearBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(rearBase)
  table.insert(roomObjs, rearBase)

  -- pipes at right wall
  for _, pz in ipairs({-130, -139}) do
    local pipe = Cylinder(3, 290, 0)
    pipe.pos = btVector3(197, 145, pz)
    pipe.col = color.olive
    pipe.mass = 0
    pipe.sdl = [[
      texture {
        pigment{ rgb ReflectiveSpectrum(RS_Olive_green_gloss_paint) }
        finish {diffuse 0.8 brilliance 2 specular 0.33 roughness 0.009 metallic 0.4
                reflection{0.01 0.075 falloff 2} }
        normal {wrinkles 0.1}
      }
    ]]
    v:add(pipe)
    table.insert(roomObjs, pipe)
  end
end

-- Simplified Mondrian picture on the front wall (the original uses an image
-- map of Piet Mondrian's "Composition with Red, Yellow and Blue", which is
-- not available here; a colored panel stands in).
local mondrianObj = nil
local function addMondrian()
  mondrianObj = Cube(35 * 2.5, 39 * 2.5, 2, 0)
  mondrianObj.pos = btVector3(-6, 112, -247)
  mondrianObj.col = color.white
  mondrianObj.mass = 0
  mondrianObj.sdl = [[
    texture {
      pigment{ color <0.9,0.9,0.85> }
      finish {F_Mondrian}
    }
  ]]
  v:add(mondrianObj)
  table.insert(roomObjs, mondrianObj)
end

-- Simplified chairs (the original uses a complex superellipsoid + torus
-- union; a textured box stands in, at the same positions with z negated).
local chairObjs = {}
local function addChairs()
  local chairs = {
    { pos = btVector3(-45, 0, -195), col = color.yellow, rot = -15 },
    { pos = btVector3( 68, 0, -185), col = color.blue,   rot =  12 },
    { pos = btVector3(150, 0, -170), col = color.red,    rot =  30 },
  }
  for _, c in ipairs(chairs) do
    local ch = Cube(30, 6, 30, 0)
    ch.pos = c.pos
    ch.col = c.col
    ch.mass = 0
    ch.trans = btTransform(common.quat(0, math.rad(c.rot), 0), c.pos)
    ch.sdl = [[
      texture {
        pigment { color <0.8,0.8,0.9> }
        finish { diffuse 0.9 brilliance 2 specular 0.275 roughness 0.012
                 reflection {0.02 0.1 falloff 2 metallic 0.4} }
      }
    ]]
    v:add(ch)
    table.insert(chairObjs, ch)
  end
end

-- Simplified desk (original: wood top + 4 chrome legs).
local deskObjs = {}
local function addDesk()
  local top = Cube(130, 3, 82, 0)
  top.pos = btVector3(-8, 73, 40)
  top.col = color.saddlebrown
  top.mass = 0
  top.trans = btTransform(common.quat(0, math.rad(3), 0), top.pos)
  top.sdl = [[
    texture {
      pigment{ wood
        color_map {
          [0.0 rgb <0.2,0.1,0.05>]
          [0.3 rgb <0.3,0.15,0.08>]
          [0.5 rgb <0.4,0.2,0.1>]
          [1.0 rgb <0.5,0.25,0.12>]
        }
        turbulence 0.12
      }
      finish {diffuse 0.8 brilliance 2 specular 0.25 roughness 0.007 reflection{0.09 falloff 2}}
      scale 2.5
      rotate y*90
    }
  ]]
  v:add(top)
  table.insert(deskObjs, top)

  for _, lz in ipairs({-33, 33}) do
    for _, lx in ipairs({-57, 57}) do
      local leg = Cylinder(2, 72, 0)
      leg.pos = btVector3(lx, 36, lz)
      leg.col = color.gray
      leg.mass = 0
      leg.trans = btTransform(common.quat(0, math.rad(3), 0), btVector3(lx, 36, lz))
      leg.sdl = [[
        texture { pigment{ color <0.7,0.7,0.8> } finish{reflection{0.3 0.6}} }
      ]]
      v:add(leg)
      table.insert(deskObjs, leg)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Build the scene
-- ---------------------------------------------------------------------------

addRoom()
addMondrian()
addChairs()
addDesk()

-- Camera: same location/look_at as the original .pov, z negated for bpp's
-- POV export mirroring. angle 75 deg horizontal field of view.
common.setCamera(btVector3(-8, 135, 236), btVector3(34, 128, 0), math.rad(75),
                 { horizontal = true })

common.setTiming(1 / 25)

-- ---------------------------------------------------------------------------
-- Parameter handling: rebuild the POV preamble (lights) when the tune changes.
-- ---------------------------------------------------------------------------

v:onParamChanged(function(N, name, value)
  if name == "tune" then
    v.pre_sdl = buildPreSDL(tonumber(value))
  end
end)

-- EOF
