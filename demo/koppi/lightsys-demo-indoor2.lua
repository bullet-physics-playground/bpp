--
-- LightSys indoor scene, ported from demo_indoor2.pov (LightSys IV by Ive, 2003)
--
-- A furnished room lit with LightSys: fluorescent tubes, incandescent lamps,
-- a spotlight and a window/daylight source, all through CIE XYZ color
-- management. The lighting "tune" matches the #switch (Tune) in the original.
-- The lights are bpp's light classes (LIGHTS.md), so they light the 3D view
-- as well as the render.
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
-- pigment declarations and texture definitions. (The light sources are the
-- light classes below; their LightSys colours are the LC* declared here.)
--
-- This is raw POV-Ray SDL, written verbatim into the exported .pov, so
-- coordinates here are POV-space (z as in the original .pov). bpp objects
-- added with v:add() live in Bullet space and are mirrored through Z on
-- export, so their positions negate z relative to the .pov.
local function buildPreSDL(tune)
  return [==[
#include "colors.inc"
#include "math.inc"
#include "bpp_CIE_tools.inc"
#include "bpp_lightsys.inc"
#include "bpp_lightsys_constants.inc"
#include "rspd_aster.inc"
#include "rspd_jvp.inc"
#include "rspd_pantone_coated.inc"
#include "rspd_pantone_matte.inc"

#declare Lightsys_Brightness = 0.67;

// (the original's AreaLight switch is AREA in the Lua below)

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
  #break
  #case (Incandescent_Tune)
    #declare Film_Temperature = Kt_Indoor_Film;
  #break
  #case (Fluorescent_Tune)
    #declare Film_Temperature = Kt_Fluorescent_Film;
  #break
  #else // User_Tune
    #declare Film_Temperature = Kt_TungstenA_Film;
#end

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
      [0.0 rgb <0.3,0.3,0.25> ]
      [0.1 rgb <0.12,0.18,0.10>]
    }
    scale 12
  }
}

#declare T_Brick_Wall = texture {
  pigment {brick color <0.5,0.5,0.5> color <0.75,0.25,0.25> scale 2.5 turbulence 0.05}
  normal {brick scale 2.5 turbulence 0.05}
  rotate y*90
  translate <0.5, 0.1,0>
}

#declare T_White_Wall = texture {
  pigment { wrinkles
    color_map {
      [0.0 rgb <0.95,0.95,0.95>]
      [1.0 rgb <0.87,0.87,0.87>]
    }
    scale 7
  }
}

#declare T_Black_Plastic = texture {
  pigment {rgb <0.05,0.05,0.05>}
  finish {diffuse 0.8 specular 0.3 roughness 0.009}
}

#declare T_Chrome = texture {
  pigment {rgb <0.7,0.7,0.8>}
  finish {diffuse 0.3 brilliance 4 metallic reflection{0.7 metallic} }
}

#declare T_DeskWood = texture {
  pigment{
    wood
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

#declare T_WindowGlass = texture {
  pigment {rgbt <1,1,1,0.4>}
  finish {diffuse 0.1 specular 0.4 roughness 0.05 reflection {0.1}}
}

#declare F_Mondrian = finish {specular 0.3 brilliance 2 roughness 0.011}

#declare F_Chair = finish {
  diffuse 0.9 brilliance 2 specular 0.275 roughness 0.012
  reflection {0.02 0.1 falloff 2  metallic 0.4}
}

global_settings {
  assumed_gamma 1.0
  max_trace_level 15
}
]==]
end

-- ---------------------------------------------------------------------------
-- Light sources: bpp's light classes. Each is where the original's fixture
-- puts its light, carried to the world through the fixture's own rotate
-- and translate (POV-Ray worked them out), with z negated for Bullet
-- space. lightsys is the spectrum declared in the preamble, lumens the
-- original's; col is only the hue the 3D view shows (it can't read a
-- LightSys colour). A LightSys "cosine falloff" lamp (Light_Spot_Cos_Falloff)
-- is a spot of radius -89.9, falloff 89.9, tightness 1.
-- ---------------------------------------------------------------------------

-- The original's AreaLight switch: soft shadows in the render, slower.
local AREA = false

-- (the 3D view: little ambient light, so where the lamps' light falls
-- shows; POV-Ray has radiosity for that)
v.glAmbient = 0.08
v.glModelAmbient = 0.08

local function cosineSpot(pos, at)
  local l = SpotLight(pos, at)
  l.radius, l.falloff, l.tightness = -89.9, 89.9, 1
  return l
end

local function area(l, axis1, axis2, n1, n2, roundLamp)
  if not AREA then return end
  l.axis1, l.axis2, l.n1, l.n2 = axis1, axis2, n1, n2
  l.adaptive, l.jitter = 2, true
  l.circular, l.orient = roundLamp, roundLamp
end

local lights = { L1 = {}, L2 = {}, L3 = {}, LD = {} }

-- L1: two fluorescent tubes on the right wall, three lights in each
-- (LM1 lumens shared between them)
for _, z in ipairs({ 46, 66, 86, -46, -66, -86 }) do
  local l = PointLight(btVector3(194, 228, z))
  l.lightsys, l.lumens, l.col = "LC1", 300 / 3, "#eaf2ff"
  area(l, btVector3(0, 0, 20), btVector3(0, -7, 0), 3, 2, false)
  table.insert(lights.L1, l)
end

-- L2: two incandescent lamps hanging over the room, shining down
for _, x in ipairs({ 65, -65 }) do
  local l = cosineSpot(btVector3(x, 186, -40), btVector3(x, 185, -40))
  l.lightsys, l.lumens, l.col = "LC2", 890, "#ffcf9a"   -- (Lm_Incandescent_60w)
  area(l, btVector3(7, 0, 0), btVector3(0, 0, -7), 4, 4, true)
  table.insert(lights.L2, l)
end

-- L3: the spotlight on the Mondrian, tilted 32 degrees toward it
do
  local l = SpotLight(btVector3(38, 275.848, -179.4701), btVector3(38, 275, -180))
  l.radius, l.falloff, l.tightness = 24, 35, 15
  l.lightsys, l.lumens, l.col = "LC3", 965, "#f2f5ff"
  area(l, btVector3(5, 0, 0), btVector3(0, 2.6496, -4.2402), 4, 4, true)
  table.insert(lights.L3, l)
end

-- LD: daylight through the window in the left wall, into the room
do
  local l = cosineSpot(btVector3(-200, 160, 60), btVector3(-199, 160, 60))
  l.lightsys, l.lumens, l.col = "LCD", 2100, "#f0f4ff"
  area(l, btVector3(0, 0, 80), btVector3(0, 120, 0), 6, 8, false)
  table.insert(lights.LD, l)
end

-- Which lights each tune has (the original's #switch (Tune))
local TUNES = {
  [0] = { "L1", "L2", "L3" },   -- user
  [1] = { "LD" },               -- daylight
  [2] = { "L2", "L3" },         -- incandescent
  [3] = { "L1", "L3" },         -- fluorescent
}

local function applyTune(tune)
  v.pre_sdl = buildPreSDL(tune)
  for _, group in pairs(lights) do
    for _, l in ipairs(group) do v:remove(l) end
  end
  for _, name in ipairs(TUNES[tune] or TUNES[2]) do
    for _, l in ipairs(lights[name]) do v:add(l) end
  end
end

applyTune(v:getParam("tune"))

-- ---------------------------------------------------------------------------
-- Room geometry (Bullet space: z is negated on POV export, so negate z
-- relative to the original .pov coordinates)
-- ---------------------------------------------------------------------------

local roomObjs = {}

local function addRoom()
  -- floor: plane at y=0, crackle texture
  local floor = Cube(400, 0.2, 500, 0)
  floor.pos = btVector3(0, 0, 0)
  floor.col = color.white
  floor.mass = 0
  floor.sdl = [[
    texture { T_Floor }
  ]]
  v:add(floor)
  table.insert(roomObjs, floor)

  -- ceiling: box <-200,290,-250> <200,300,250> => center (0,295,0), size (400,10,500)
  local ceiling = Cube(400, 10, 500, 0)
  ceiling.pos = btVector3(0, 295, 0)
  ceiling.col = color.white
  ceiling.mass = 0
  ceiling.sdl = [[
    texture { pigment { color ReferenceRGB(LightWood) } }
  ]]
  v:add(ceiling)
  table.insert(roomObjs, ceiling)

  -- front wall: box <-205,0,250> <205,300,255> => center (0,150,252.5), size (410,300,5)
  -- bpp z = -252.5
  local frontWall = Cube(410, 300, 5, 0)
  frontWall.pos = btVector3(0, 150, -252.5)
  frontWall.col = color.white
  frontWall.mass = 0
  frontWall.sdl = [[
    texture { T_White_Wall }
  ]]
  v:add(frontWall)
  table.insert(roomObjs, frontWall)

  -- front baseboard: box <-200,0,249> <200,4,250> => center (0,2,249.5), size (400,4,1)
  -- bpp z = -249.5
  local frontBase = Cube(400, 4, 1, 0)
  frontBase.pos = btVector3(0, 2, -249.5)
  frontBase.col = color.black
  frontBase.mass = 0
  frontBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(frontBase)
  table.insert(roomObjs, frontBase)

  -- right wall: box <200,0,-250> <205,300,250> => center (202.5,150,0), size (5,300,500)
  local rightWall = Cube(5, 300, 500, 0)
  rightWall.pos = btVector3(202.5, 150, 0)
  rightWall.col = color.darkred
  rightWall.mass = 0
  rightWall.sdl = [[
    texture { T_Brick_Wall }
  ]]
  v:add(rightWall)
  table.insert(roomObjs, rightWall)

  -- right baseboard: box <199,0,-250> <200,4,250> => center (199.5,2,0), size (1,4,500)
  local rightBase = Cube(1, 4, 500, 0)
  rightBase.pos = btVector3(199.5, 2, 0)
  rightBase.col = color.black
  rightBase.mass = 0
  rightBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(rightBase)
  table.insert(roomObjs, rightBase)

  -- The left wall is added by addWindow() below, with the window opening cut out.

  -- left baseboard: box <-199,0,-250> <-200,4,250> => center (-199.5,2,0), size (1,4,500)
  local leftBase = Cube(1, 4, 500, 0)
  leftBase.pos = btVector3(-199.5, 2, 0)
  leftBase.col = color.black
  leftBase.mass = 0
  leftBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(leftBase)
  table.insert(roomObjs, leftBase)

  -- rear wall: box <-205,0,-250> <205,300,-255> => center (0,150,-252.5), size (410,300,5)
  -- bpp z = 252.5
  local rearWall = Cube(410, 300, 5, 0)
  rearWall.pos = btVector3(0, 150, 252.5)
  rearWall.col = color.white
  rearWall.mass = 0
  rearWall.sdl = [[
    texture { T_White_Wall }
  ]]
  v:add(rearWall)
  table.insert(roomObjs, rearWall)

  -- rear baseboard: box <-200,0,-249> <200,4,-250> => center (0,2,-249.5), size (400,4,1)
  -- bpp z = 249.5
  local rearBase = Cube(400, 4, 1, 0)
  rearBase.pos = btVector3(0, 2, 249.5)
  rearBase.col = color.black
  rearBase.mass = 0
  rearBase.sdl = [[
    texture { T_Black_Plastic }
  ]]
  v:add(rearBase)
  table.insert(roomObjs, rearBase)

  -- pipes at right wall: cylinders <197,0,130>..<197,290,130> and ..139, radius 3
  -- center (197,145,z), length 290. bpp z negated.
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
-- map of Piet Mondrian's "Composition with Red, Yellow and Blue", ryb.png,
-- applied as the .tex texture).
-- POV: box {0,1 texture {T_Mondrian} scale <35,39,2>*2.5 translate <-6,112,247>}
-- => center (-6,112,247), size (87.5,97.5,5). bpp z = -247.
local mondrianObj = nil
local function addMondrian()
  mondrianObj = Cube(87.5, 97.5, 5, 0)
  mondrianObj.pos = btVector3(-6, 112, -247)
  mondrianObj.col = color.white
  mondrianObj.mass = 0
  mondrianObj.tex = "ryb.png"
  v:add(mondrianObj)
  table.insert(roomObjs, mondrianObj)
end

-- Window in the left wall. The original cuts an opening through the wall
-- (box <-200,0,-250>..<-210,300,250> minus box <-199,90,-110>..<-211,230,-10>)
-- and puts a frame + glass pane in it, rotate y*90 translate <-209,90,-60>.
-- Both the wall and the frame are hollow OpenSCAD meshes so daylight can pass
-- through the glass instead of hitting solid geometry.
local LEFT_WALL_SCAD = [===[
scale([1, 1, -1]) {
  difference() {
    translate([-205, 150, 0]) cube([10, 300, 500], center = true);
    translate([-205, 160, -60]) cube([12, 140, 100], center = true);
  }
}
]===]

local WINDOW_FRAME_SCAD = [===[
scale([1, 1, -1]) {
  difference() {
    cube([100, 140, 1], center = true);
    cube([80, 120, 2], center = true);
  }
}
]===]

local windowObj = nil
local function addWindow()
  -- left wall, with the window opening cut out
  local leftWall = OpenSCAD(LEFT_WALL_SCAD, 0, false)
  leftWall.col = color.white
  leftWall.mass = 0
  leftWall.sdl = [[ texture { T_White_Wall } ]]
  v:add(leftWall)
  table.insert(roomObjs, leftWall)

  -- window frame: a 10-unit border around the 80x120 opening
  windowObj = OpenSCAD(WINDOW_FRAME_SCAD, 0, false)
  windowObj.col = color.white
  windowObj.mass = 0
  windowObj.trans = btTransform(common.quat(math.rad(90), 0, 0),
                                btVector3(-209, 160, 60))
  windowObj.sdl = [[
    texture {
      pigment{ rgb ReflectiveSpectrum(RS_Warm_Gray_3_C) }
      finish{diffuse 0.1 specular 0.4 roughness 0.05}
    }
  ]]
  v:add(windowObj)
  table.insert(roomObjs, windowObj)

  -- glass pane: transparent in the view and in the render. Like the original's
  -- LD glass, it casts no shadow so the daylight reaches the room.
  local glass = Cube(80, 120, 0.1, 0)
  glass.pos = btVector3(-209, 160, 60)
  glass.col = color.white
  glass.mass = 0
  glass.transparency = 0.6
  glass.castShadow = false
  glass.trans = btTransform(common.quat(math.rad(90), 0, 0),
                            btVector3(-209, 160, 60))
  glass.sdl = [[
    texture {
      pigment {rgbt <1,1,1,0.6>}
      finish {diffuse 0.1 specular 0.4 roughness 0.05 reflection {0.1}}
    }
  ]]
  v:add(glass)
  table.insert(roomObjs, glass)
end

-- The chairs from demo_indoor2.pov, generated from OpenSCAD: a bowl-cut
-- superellipsoid seat, the clipped torus backrest with its spokes, and four
-- tapered legs. The source below works in POV-Ray space and mirrors Z at the
-- end, matching bpp's export. The three chairs share the same generated mesh.
-- Original positions (POV): <-45,0,195> rot -y*15, <68,0,185> rot y*12,
-- <150,0,170> rot y*30. bpp z negated, rotation sign negated about Y.
local CHAIR_SCAD = [===[
$fn = 24;
R = 75;

function unit(v) = v / sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
function rotY(p, a) = [
  p[0]*cos(a) + p[2]*sin(a), p[1],
  -p[0]*sin(a) + p[2]*cos(a)
];

// Half-space n . p < 0, for clipping the backrest to its front arc.
module cut_negative(n) {
  n = unit(n);
  u = unit(cross([0, 0, 1], n));
  w = cross(n, u);
  L = 1000;
  multmatrix([
    [n[0], u[0], w[0], 0],
    [n[1], u[1], w[1], 0],
    [n[2], u[2], w[2], 0],
    [0, 0, 0, 1]
  ]) translate([-L/2, 0, 0]) cube([L, 2*L, 2*L], center = true);
}

// A capsule between two points (the original's sphere/cylinder/sphere rod).
module rod(a, b, r) {
  hull() {
    translate(a) sphere(r);
    translate(b) sphere(r);
  }
}

module torus_y(r, rt) {
  rotate([90, 0, 0]) rotate_extrude($fn = 48)
    translate([r, 0, 0]) circle(rt, $fn = 12);
}

// superellipsoid <0.25,0.25> scale <25,2.5,25>, with its bowl cut out
module seat() {
  translate([0, 50, 0]) difference() {
    minkowski() {
      rotate([-90, 0, 0]) cylinder(h = 0.2, r = 22.6, center = true);
      sphere(2.4, $fn = 12);
    }
    translate([0, 6.1, 0]) scale([33, 5, 33]) sphere(1, $fn = 24);
  }
}

// Hollow, rounded band of the R=75 torus clipped to its +-18 degree front arc,
// with the end caps and five spokes of the original.
module backrest() {
  difference() {
    union() {
      torus_y(R, 1.4);
      rotate([-90, 0, 0]) cylinder(h = 6, r = R + 1.4);
      translate([0, 6, 0]) torus_y(R, 1.4);
    }
    rotate([-90, 0, 0]) translate([0, 0, -0.1]) cylinder(h = 6.2, r = R - 1.4);
    cut_negative([ cos(13)*cos(18),  sin(13), cos(13)*sin(18)]);
    cut_negative([-cos(13)*cos(18), -sin(13), cos(13)*sin(18)]);
  }

  p1 = rotY([0, 0, R], -18);
  p2 = rotY([0, 6, R], -19.2);
  rod(p1, p2, 1.4);
  rod([-p1[0], p1[1], p1[2]], [-p2[0], p2[1], p2[2]], 1.4);

  for (a = [-6, -3, 0, 3, 6])
    rotate([0, -(8/3)*a, 0]) rotate([0, 0, a])
      translate([0, -50, R]) rotate([-90, 0, 0])
        cylinder(h = 55, r = 1.3);
}

scale([1, 1, -1]) {
  seat();
  translate([0, 110, -R + 29.5]) rotate([7, 0, 0]) backrest();
  for (x = [-21, 21]) for (z = [-21, 21])
    translate([x, -1, z]) rotate([-90, 0, 0])
      cylinder(h = 51, r1 = 1.9, r2 = 2.8);
}
]===]

local chairObjs = {}
local function addChairs()
  local chairs = {
    { pos = btVector3(-80, 0, -195), col = color.yellow, rot =  15 },
    { pos = btVector3( 50, 0, -185), col = color.blue,   rot = 0 },
    { pos = btVector3(130, 0, -170), col = color.red,    rot = -30 },
  }
  for _, c in ipairs(chairs) do
    local r, g, b = color.col2rgb(c.col)
    local ch = OpenSCAD(CHAIR_SCAD, 0, false)
    ch.col = c.col
    ch.trans = btTransform(common.quat(math.rad(c.rot), 0, 0), c.pos)
    ch.sdl = string.format([=[
      texture {
        pigment { color <%g,%g,%g> }
        finish {F_Chair}
      }
    ]=], r / 255, g / 255, b / 255)
    v:add(ch)
    table.insert(chairObjs, ch)
  end
end

-- Light fixtures from demo_indoor2.pov: the wall tubes, the two hanging lamps
-- and the spotlight. They are split into housing/stem/bulb meshes so each can
-- keep its own material, and share one mesh per part across their instances.
-- As with the chairs, the source is written in POV-Ray coordinates and mirrored
-- through Z at the end. The light objects above do the actual lighting.
local TUBE_HOUSING_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  cube([64, 4, 6], center = true);
  translate([-31, -2, 0]) rotate([0, 90, 0])
    cylinder(h = 2, r = 3, center = true);
  translate([31, -2, 0]) rotate([0, 90, 0])
    cylinder(h = 2, r = 3, center = true);
}
]===]

local TUBE_EMITTER_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, -4, 0]) rotate([0, 90, 0])
    cylinder(h = 66, r = 4, center = true);
}
]===]

local LAMP_SHADE_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, -1.2, 0]) difference() {
    sphere(10);
    sphere(9.9);
    translate([-500, -999, -500]) cube([1000, 1000, 1000]);
  }
  translate([0, 11.5, 0]) rotate([-90, 0, 0])
    cylinder(h = 7, r1 = 4.2, r2 = 3.2, center = true);
}
]===]

local LAMP_STEM_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, 66.5, 0]) rotate([-90, 0, 0])
    cylinder(h = 107, r = 0.45, center = true);
}
]===]

local LAMP_BULB_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, 0.5, 0]) sphere(2.8);
}
]===]

local SPOT_SHADE_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  difference() {
    sphere(8);
    sphere(7.9);
    translate([-500, -500, -500]) cube([1000, 500.01, 1000]);
  }
  translate([0, 10.75, 0]) rotate([-90, 0, 0])
    cylinder(h = 8.5, r1 = 4, r2 = 3, center = true);
}
]===]

local SPOT_STEM_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, 10, 0]) rotate([30, 0, 0])
    translate([0, 45.5, 0]) rotate([-90, 0, 0])
      cylinder(h = 89, r = 1, center = true);
}
]===]

local SPOT_BULB_SCAD = [===[
$fn = 24;
scale([1, 1, -1]) {
  translate([0, 0.8, 0]) sphere(2.5);
}
]===]

local fixtureObjs = {}
local function addLightFixtures()
  local chrome = [[ texture { T_Chrome } ]]
  local plastic = [[ texture { T_Black_Plastic } ]]

  local function bulbSDL(r, g, b)
    return string.format([=[
      texture {
        pigment { color rgb <%g,%g,%g> }
        finish { ambient 0.15 diffuse 0.35 emission rgb <%g,%g,%g> }
      }
    ]=], r, g, b, r, g, b)
  end

  local function addPart(scad, trans, col, sdl, emission)
    local o = OpenSCAD(scad, 0, false)
    o.col = col
    o.trans = trans
    o.sdl = sdl
    -- The bulbs and housings sit on top of the light sources: if they cast
    -- shadows they black out the very light they belong to.
    o.castShadow = false
    if emission then o.emission = emission end
    v:add(o)
    table.insert(fixtureObjs, o)
  end

  -- Tube: POV rotate <90,90,0>, translate <200,228,±66>. The emitted z here
  -- is already in Bullet space, the mirror of the original's ±66.
  local tubeBulb = bulbSDL(234/255, 242/255, 1)
  local tubeHousing = [[
    texture {
      pigment { rgb ReflectiveSpectrum(RS_Warm_Gray_4_C) }
      finish { ambient 0.6 diffuse 0.01 }
    }
  ]]
  for _, z in ipairs({ -66, 66 }) do
    local trans = common.transform(math.rad(-90), math.rad(-90), 0, 200, 228, z)
    addPart(TUBE_HOUSING_SCAD, trans, "#a8a39c", tubeHousing)
    addPart(TUBE_EMITTER_SCAD, trans, "#eaf2ff", tubeBulb, "#eaf2ff")
  end

  -- Lamp: POV translate <±65,185,40>, no rotation.
  local lampBulb = bulbSDL(1, 207/255, 154/255)
  for _, x in ipairs({ 65, -65 }) do
    local trans = common.transform(0, 0, 0, x, 185, -40)
    addPart(LAMP_SHADE_SCAD, trans, "#b2b2ba", chrome)
    addPart(LAMP_STEM_SCAD, trans, "#111111", plastic)
    addPart(LAMP_BULB_SCAD, trans, "#ffcf9a", lampBulb, "#ffcf9a")
  end

  -- Spot: POV rotate -x*32, translate <38,275,180>.
  addPart(SPOT_SHADE_SCAD,
          common.transform(0, math.rad(32), 0, 38, 275, -180),
          "#b2b2ba", chrome)
  addPart(SPOT_STEM_SCAD,
          common.transform(0, math.rad(32), 0, 38, 275, -180),
          "#111111", plastic)
  addPart(SPOT_BULB_SCAD,
          common.transform(0, math.rad(32), 0, 38, 275, -180),
          "#f2f5ff", bulbSDL(242/255, 245/255, 1), "#f2f5ff")
end

-- Simplified desk (original: wood top + 4 chrome legs).
-- POV: Desk rotate y*3 translate <-8,0,-40>. bpp: translate (-8,73.5,40),
-- rotate -3 deg about Y.
local deskObjs = {}
local function addDesk()
  -- desk top: box <-65,72,-41> <65,75,41> => center (0,73.5,0), size (130,3,82)
  local top = Cube(130, 3, 82, 0)
  top.pos = btVector3(-8, 73.5, 40)
  top.col = color.saddlebrown
  top.mass = 0
  top.trans = btTransform(common.quat(0, math.rad(-3), 0), top.pos)
  -- The original desk uses the procedural T_DeskWood texture.
  top.sdl = [[ texture { T_DeskWood } ]]
  v:add(top)
  table.insert(deskObjs, top)

  -- 4 chrome legs at corners (±57, ±33), y from 0 to 72, radius 0.45
  local deskYaw = math.rad(-3)
  local ca, sa = math.cos(deskYaw), math.sin(deskYaw)
  for _, lz in ipairs({-33, 33}) do
    for _, lx in ipairs({-57, 57}) do
      -- leg center in world space: desk rotate -3deg about Y, then translate (-8,36,40)
      local wx = -8 + lx * ca - lz * sa
      local wz = 40 + lx * sa + lz * ca
      local leg = Cylinder(0.45, 72, 0)
      -- stand cylinder up (-pi/2 about X) and apply desk yaw
      leg.trans = common.transform(deskYaw, -math.pi / 2, 0, wx, 36, wz)
      leg.col = color.gray
      leg.mass = 0
      leg.sdl = [[
        texture { T_Chrome }
      ]]
      v:add(leg)
      table.insert(deskObjs, leg)
    end
  end

  -- An LP sleeve on the desk. POV: object{LP rotate y*120 translate
  -- <25,75,-65> } with scale 30.8, LP = thin cylinder with an image map.
  -- The original's sleeve was a real album cover; kelvin.png is an original
  -- one instead: rings of blackbody colour, 1900 K to 10000 K.
  local lp = Cylinder(0.49 * 30.8, 0.008 * 30.8, 0)
  lp.col = color.white
  lp.mass = 0
  -- stand cylinder up (local Z -> world Y) then apply desk yaw; center at
  -- y = 75.015 + half height so the bottom sits on the desk surface
  lp.trans = common.transform(math.rad(-120), -math.pi / 2, 0,
                              25, 75.015 + 0.004 * 30.8, 65)
  lp.tex = "kelvin.png"
  v:add(lp)
  table.insert(deskObjs, lp)
end

-- GretagMacbeth Colour Checker Chart, from demo_indoor2.pov. The swatches are
-- bpp cubes so the chart is visible in the OpenGL view too; their sdl keeps
-- the original spectral pigments in the POV export. Hex colours approximate
-- those pigments in the view. The text label is left out: it needs a font.
local ChartSwatches = {
  {0.4398, 0.3802,  9.941, "#7a4e35"}, {0.4150, 0.3764, 35.933, "#d0946f"},
  {0.2764, 0.3022, 18.545, "#677a88"}, {0.3654, 0.4513, 13.265, "#606b35"},
  {0.3007, 0.2865, 23.347, "#8d809a"}, {0.2865, 0.3893, 41.598, "#76bb94"},
  {0.5317, 0.4116, 30.209, "#e4790d"}, {0.2356, 0.2177, 11.179, "#505b90"},
  {0.5001, 0.3293, 19.806, "#ce5252"}, {0.3282, 0.2522,  6.534, "#613c5c"},
  {0.4001, 0.5001, 43.776, "#adb929"}, {0.4938, 0.4435, 44.867, "#f3a20b"},
  {0.2022, 0.1585,  5.748, "#343d86"}, {0.3266, 0.5105, 23.111, "#539338"},
  {0.5783, 0.3253, 12.502, "#bd282d"}, {0.4681, 0.4718, 61.095, "#fdc600"},
  {0.4201, 0.2708, 19.576, "#c7517f"}, {0.2130, 0.3003, 18.429, "#008492"},
  {0.3491, 0.3628, 88.558, "#ffefcd"}, {0.3460, 0.3589, 58.449, "#d8c7ad"},
  {0.3454, 0.3587, 35.642, "#ad9f8b"}, {0.3473, 0.3602, 19.488, "#847968"},
  {0.3445, 0.3582,  8.687, "#5a5247"}, {0.3462, 0.3566,  3.122, "#36312a"},
}

local function addColorChart()
  -- Original: translate z*11 rotate -x*35 rotate -y*6 translate <-27,75,-60>.
  -- Exporting mirrors Z, so bpp uses +35 around X, +6 around Y and +60 in Z.
  local yaw, pitch = math.rad(6), math.rad(35)
  local cp, sp = math.cos(pitch), math.sin(pitch)
  local cy, sy = math.cos(yaw), math.sin(yaw)

  local function place(o, x, y, z)
    local y1 = y * cp - z * sp
    local z1 = y * sp + z * cp
    o.trans = common.transform(yaw, pitch, 0,
                               x * cy + z1 * sy - 27,
                               y1 + 75,
                               -x * sy + z1 * cy + 60)
    o.mass = 0
    o.decoration = true
    v:add(o)
  end

  local base = Cube(32, 0.1, 22, 0)
  base.col = color.black
  base.sdl = [[ texture { pigment {rgb ReflectiveSpectrum(RS_Black_4_M)} } ]]
  -- The original chart is shifted +11 in POV z before it tilts; exported
  -- that is -11 in bpp z. Without it the base cuts through the desk top.
  place(base, 0, 0.05, -11)

  for row = 0, 3 do
    for col = 0, 5 do
      local s = ChartSwatches[row * 6 + col + 1]
      local patch = Cube(4.4, 0.055, 4.4, 0)
      patch.col = s[4]
      patch.sdl = string.format([=[
        texture {
          pigment {rgb MapGamut(xyz2RGB(ChromaMatchSource(xyY2xyz(<%g,%g,%g>))))}
          finish {diffuse 0.95 specular 0.05 roughness 0.009}
        }
      ]=], s[1], s[2], s[3] / 100)
      place(patch, -12.5 + col * 5, 0.0775, -18.5 + row * 5)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Build the scene
-- ---------------------------------------------------------------------------

addRoom()
addMondrian()
addWindow()
addChairs()
addLightFixtures()
addDesk()
addColorChart()

-- Camera: same location/look_at as the original .pov, z negated for bpp's
-- POV export mirroring. angle 75 deg horizontal field of view.
common.setCamera(btVector3(-8, 135, 236), btVector3(34, 128, 0), math.rad(75),
                 { horizontal = true })

common.setTiming(1 / 25)

-- ---------------------------------------------------------------------------
-- Parameter handling: the tune's lights and film when the tune changes.
-- ---------------------------------------------------------------------------

v:onParamChanged(function(N, name, value)
  if name == "tune" then
    applyTune(tonumber(value))
  end
end)

-- EOF
