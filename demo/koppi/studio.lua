--
-- Studio Lighting Kit demo, ported from includes/studio-light-demo.pov
--
-- Shows the Studio Lighting Kit: a generic room, studio lights and
-- accessories, a curved backdrop, and simple demo products (soap bar +
-- bottles) lit for a product-photography look.
--
-- Original POV-Ray scene: includes/studio-light-demo.pov
-- Author: Jaime Vives Piqueres (Feb 2013)
--
-- Usage: bpp -f demo/koppi/studio.lua
--

local common = require "common"
local color  = require "color"

-- Which predefined rig from includes/i_studio_sets.inc's #switch to light
-- the scene with: 0=none, 1-6=preset (1: softbox+umbrella key light; 2:
-- daylight softbox pair + xenon fill + umbrella; 3/5: five-softbox ring;
-- 4: halogen umbrella + two daylight softboxes; 6: xenon umbrella + two
-- filtered softboxes). Every setup is fully replicated as real bpp
-- OpenSCAD objects, positioned/rotated/scaled to match i_studio_sets.inc's
-- #case blocks exactly (see STUDIO_SETUPS and addLightFixtures() below),
-- so predefined_studio_setup is always left at 0 in the exported POV SDL
-- (i_studio_sets.inc's #switch has no #case(0), so it renders nothing
-- there) -- letting the raw SDL render too would just duplicate them.
v:addParam("predefined_studio_setup", 1, 0, 6, 1,
  "studio lighting rig from i_studio_sets.inc (0=none, 1-6=preset)")

-- 1=direct: the Studio Lighting Kit macros (room/backdrop/lights, all
-- ported to bpp objects elsewhere in this file) light the scene. 2=HDRI:
-- a big sphere wearing a pre-baked studio-light-to-hdr.pov environment map
-- as its own emissive texture lights it instead (see the #if(demo_mode=2)
-- block below) -- an entirely different POV-SDL-only rendering approach
-- with no bpp-object equivalent here, so (unlike predefined_studio_setup)
-- this parameter has to actually change what's spliced into v.pre_sdl,
-- rebuilt by buildPreSDL() below on every change.
v:addParam("demo_mode", 1, 1, 2, 1,
  "1=direct (Studio Lighting Kit), 2=HDRI (studio-light-to-hdr.pov environment sphere)")

local PRE_SDL_PART1 = [==[

#include "colors.inc"

// *** control center ***
#declare demo_mode     =]==]

local PRE_SDL_PART2 = [==[;  // 1=direct, 2=HDRI
#declare use_blur    =7*0;  // blur samples (0=off)
#ifndef(use_radiosity) // pass this variable on the command line with the apropiate value depending on +RFO/+RFI
  #declare use_radiosity =1;  // 0=off, 1=load pass , 2=save pass
#end

// *** global ***
global_settings{
 assumed_gamma 1.0
 #if (use_radiosity)
   #include "rad_def.inc"
   radiosity{Rad_Settings(Radiosity_IndoorHQ, off, off)}
   //radiosity{Rad_Settings(Radiosity_OutdoorHQ, off, off)}
 #end
}
#default{texture{finish{ambient 0}}}


// *************************
// *** direct usage demo ***
// *************************
// uses ligthsys and the studio lighting kit includes
#if (demo_mode=1)

// Include CIE color transformation macros by Ive
// needed by the Studio Lighting Kit
#include "bpp_CIE.inc"
CIE_ColorSystemWhitepoint(sRGB_ColSys, Illuminant_D65)
#include "lightsys.inc"
#include "lightsys_constants.inc"
#declare Lightsys_Brightness=.015; // adjust for brighter/dimmer radiosity on the first pass, and for brighter/dimmer reflections on the second pass

// *** STUDIO LIGHTING KIT ***
// i_studio_room.inc (generic room: walls + checkered floor) is added below
// instead, as real bpp Cube objects -- see addWalls()/addFloor().
#include "i_studio_lighting.inc" // studio lights and accesories
// studio set up examples (1-6) -- always left unselected (0) here; see the
// predefined_studio_setup addParam comment above for why.
#declare predefined_studio_setup=0;  // select predefined setup
#include "i_studio_sets.inc"

#end // direct demo usage


// ***********************
// *** HDRI usage demo ***
// ***********************
// uses .hdr generated with studio-light-to-hdr.pov
#if (demo_mode=2)

sphere {
  0,1
  pigment {
   image_map {
    hdr "studio-light-to-hdr" once interpolate 2 map_type 1
   }
  }
  finish { emission .5 diffuse 0} // adjust emission for each .hdr
  scale <-1,1,1>*300 rotate -90*y
  hollow
}

#end // HDRI usage demo


// *******************************************
// *** common demo product on the backdrop ***
// *******************************************
#declare t_backdrop1=
texture{
 pigment{
  wrinkles
  color_map{
   [0 White]
   [1 SkyBlue]
  }
 }
 scale .25
}
#declare t_backdrop2=
texture{
 pigment{Gray10}
 #if (use_radiosity<2)
 finish{reflection{.1,.33}}
 #end
}
//#declare t_backdrop=t_backdrop1

]==]

local function buildPreSDL(demoMode)
  return PRE_SDL_PART1 .. demoMode .. PRE_SDL_PART2
end

v.pre_sdl = buildPreSDL(v:getParam("demo_mode"))

-- Generic studio room from includes/i_studio_room.inc: a big white hollow
-- box for the walls/ceiling (1000x300x1000, centered at y=150 so it spans
-- y=0..300, matching the original's "translate 150*y") and a thin
-- checkered floor slab (1000x0.1x1000, centered at y=0, no translate in
-- the original). Both are plain boxes (no mesh2 data), so bpp's native
-- Cube maps directly -- no STL conversion needed, unlike the backdrop/
-- softbox/umbrella above. Cube is centered on its local origin like
-- Cylinder (see addPovodorCan() below), matching the original's box{-.5,.5
-- scale<...>} being centered before its translate. "hollow" is kept on the
-- walls (as a raw modifier appended via o.sdl, same mechanism as the
-- texture) since the camera and every other object sit inside this box;
-- POV's radiosity can shade an enclosing solid box oddly otherwise.
--
-- walls.transparency only affects the OpenGL live view (Object::
-- glApplyColor()'s alpha blending, src/objects/object.cpp) -- it feeds
-- into POV export solely through the default povPigment(), which is
-- skipped whenever a custom o.sdl is set, like here, so the POV render
-- keeps its plain solid-white texture regardless.
--
-- The walls are only added for demo_mode=1: in demo_mode=2 (HDRI) the
-- scene is lit and surrounded by the studio-light-to-hdr.pov environment
-- sphere instead, and the walls -- an opaque box enclosing that whole
-- sphere -- would just block it from view. addWalls()/removeWalls() are
-- called (rather than folding this into a single always-run addRoom())
-- so the demo_mode onParamChanged handler below can toggle them live,
-- same as predefined_studio_setup already does for the light fixtures.
local wallsObj = nil

local function addWalls()
  local walls = Cube(1000, 300, 1000, 0)
  walls.pos = btVector3(0, 150, 0)
  walls.col = color.white
  walls.transparency = 0.5
  walls.sdl = [[
    texture{ pigment{White} finish{diffuse 1} }
    hollow
  ]]
  v:add(walls)
  wallsObj = walls
end

local function removeWalls()
  if wallsObj ~= nil then
    v:remove(wallsObj)
    wallsObj = nil
  end
end

local function addFloor()
  local floor = Cube(1000, 0.1, 1000, 0)
  floor.pos = btVector3(0, 0, 0)
  floor.col = color.lightgray
  floor.sdl = [[
    texture{
      pigment{ checker color Gray10 color White }
      finish{diffuse 1}
      scale 50
    }
  ]]
  v:add(floor)
end

-- Curved studio backdrop, converted from the mesh2{} declared in
-- includes/i_studio_backdrop.inc (418 vertices, 832 faces, exported from
-- Wings 3D) into demo/mesh/studio_backdrop.stl. The mesh's own trailing
-- "scale <1,1,-1>" and the original usage site's "scale 60" (see the old
-- "object{backdrop scale 60 translate 80*y}" this replaces) are both baked
-- into the STL's vertex coordinates at conversion time, since bpp's Mesh
-- has no separate scale property -- only "translate 80*y" remains, applied
-- here via .trans, plus a 180 degree turn around Y (the mesh's own local
-- origin, before the translate) to face the room the other way. Unlike
-- bpp's native Cylinder, a loaded Mesh has no implicit "rests along Z" (see
-- addPovodorCan() below), so yaw alone (no compensating pitch) is enough.
-- STL has no per-vertex/smooth normal data, and bpp's mesh loader (Assimp,
-- aiProcessPreset_TargetRealtime_Fast) doesn't regenerate smooth ones, so
-- the curve renders faceted across its 832 triangles rather than perfectly
-- smooth like the original mesh2's normal_vectors gave it.
local function addBackdrop()
  local bd = Mesh("demo/mesh/studio_backdrop.stl", 0, false)
  bd.trans = common.transform(math.pi, 0, 0, 0, 80, 0)
  bd.col = color.white
  bd.sdl = [[
    texture{ pigment{White} }
  ]]
  v:add(bd)
end

-- Softbox and umbrella light modifiers, converted from the mesh2{} shapes
-- declared in includes/i_studio_softbox.inc (two mesh2 parts: frame +
-- diffuser panel) and includes/i_studio_umbrella.inc into raw OpenSCAD
-- polyhedron() literals (SOFTBOX_SCAD/UMBRELLA_SCAD below), rather than a
-- fixed-scale STL like the backdrop: i_studio_sets.inc's 6 setups use
-- these fixtures at many different sizes (softbox sides range 50..200,
-- umbrella 60..80), and bpp's Mesh/OpenSCAD objects have no scale
-- property to resize a pre-baked mesh per instance -- OpenSCAD's own
-- scale() wrapping the same polyhedron data at each call site sidesteps
-- that (see softboxObj()/umbrellaObj() below).
--
-- These are every setup's only light sources in the original .pov (see
-- i_studio_sets.inc) -- there's no separate light_source{}, they light
-- the scene entirely through an emissive texture on their front/inner
-- faces (t_sb_screen / t_umbrella_i, active whenever a call passes
-- lumens>0; some softbox calls pass lumens=0 for a plain gray bounce
-- panel instead). STL/OpenSCAD's mesh pipeline has no per-face material,
-- so that emissive/non-emissive split can't be represented on the merged
-- mesh; each whole fixture is made either emissive white or plain gray
-- instead of Lightsys's exact per-light color, which keeps the scene lit
-- and visually distinguishes "key" vs "bounce" panels without hand-coding
-- Lightsys's spectral color math in Lua.
local SOFTBOX_SCAD = [==[
union(){
polyhedron(points=[[-0.5,-0.5,0.0446539],[-0.5,0.5,0.0446539],[0.5,0.5,0.0446539],[0.5,-0.5,0.0446539],[0.390334,-0.390334,-0.455346],[0.390334,0.390334,-0.455346],[-0.390334,0.390334,-0.455346],[-0.390334,-0.390334,-0.455346],[-0.2845,-0.2845,-0.455346],[0.2845,-0.2845,-0.455346],[0.2845,0.2845,-0.455346],[-0.2845,0.2845,-0.455346]],faces=[[0,1,6],[2,5,6],[3,0,7],[3,4,5],[4,7,6],[5,2,3],[6,1,2],[6,5,4],[6,7,0],[7,4,3],[8,9,10],[10,11,8],[0,8,11],[2,1,11],[3,2,10],[3,9,8],[8,0,3],[10,9,3],[11,1,0],[11,10,2]]);
polyhedron(points=[[-0.482,-0.482,-0.00195996],[-0.482,0.482,-0.00195996],[0.482,0.482,-0.00195996],[0.482,-0.482,-0.00195996],[-0.482,-0.482,-0.01196],[-0.482,0.482,-0.01196],[0.482,0.482,-0.01196],[0.482,-0.482,-0.01196]],faces=[[0,3,2],[0,4,3],[1,5,0],[2,1,0],[2,6,1],[3,7,2],[4,7,3],[5,4,0],[5,6,7],[5,7,4],[6,5,1],[7,6,2]]);
}]==]

local UMBRELLA_SCAD = [==[
polyhedron(points=[[0.382683,0.544447,0],[0.270598,0.544447,0.270598],[2.34318e-17,0.544447,0.382683],[-0.270598,0.544447,0.270598],[-0.382683,0.544447,4.68637e-17],[-0.270598,0.544447,-0.270598],[-7.02955e-17,0.544447,-0.382683],[0.270598,0.544447,-0.270598],[0.707107,0.327674,0],[0.5,0.327674,0.5],[4.32964e-17,0.327674,0.707107],[-0.5,0.327674,0.5],[-0.707107,0.327674,8.65927e-17],[-0.5,0.327674,-0.5],[-1.29889e-16,0.327674,-0.707107],[0.5,0.327674,-0.5],[0.92388,0.00325046,0],[0.653281,0.00325046,0.653281],[5.65694e-17,0.00325046,0.92388],[-0.653281,0.00325046,0.653281],[-0.92388,0.00325046,1.13139e-16],[-0.653281,0.00325046,-0.653281],[-1.69708e-16,0.00325046,-0.92388],[0.653281,0.00325046,-0.653281],[0,0.620567,0],[0.376948,0.532552,2.25396e-18],[0.266542,0.532552,0.266542],[2.36636e-17,0.532552,0.376948],[-0.266542,0.532552,0.266542],[-0.376948,0.532552,4.32848e-17],[-0.266542,0.532552,-0.266542],[-7.07256e-17,0.532552,-0.376948],[0.266542,0.532552,-0.266542],[0.696807,0.318829,-5.05372e-19],[0.492717,0.318829,0.492717],[4.29372e-17,0.318829,0.696807],[-0.492717,0.318829,0.492717],[-0.696807,0.318829,8.4867e-17],[-0.492717,0.318829,-0.492717],[-1.26694e-16,0.318829,-0.696807],[0.492717,0.318829,-0.492717],[0.912673,-0.00423735,3.95646e-19],[0.645357,-0.00423735,0.645357],[5.57781e-17,-0.00423735,0.912673],[-0.645357,-0.00423735,0.645357],[-0.912673,-0.00423735,1.11556e-16],[-0.645357,-0.00423735,-0.645357],[-1.67334e-16,-0.00423735,-0.912673],[0.645357,-0.00423735,-0.645357],[1.97789e-18,0.607532,4.01959e-18]],faces=[[25,33,34],[25,34,26],[25,49,32],[26,34,35],[26,49,25],[27,35,28],[27,49,26],[28,36,37],[28,49,27],[29,37,30],[29,49,28],[30,38,39],[30,39,31],[30,49,29],[31,39,40],[31,40,32],[31,49,30],[32,33,25],[32,40,33],[32,49,31],[33,41,42],[33,42,34],[34,42,35],[35,27,26],[35,36,28],[35,43,36],[36,44,45],[37,29,28],[37,38,30],[37,45,38],[38,46,47],[38,47,39],[39,47,48],[39,48,40],[40,41,33],[40,48,41],[42,43,35],[43,44,36],[45,37,36],[45,46,38],[0,8,7],[0,24,1],[1,9,8],[1,24,2],[2,9,1],[2,10,9],[2,24,3],[3,4,12],[3,10,2],[3,11,10],[3,24,4],[4,24,5],[5,12,4],[5,13,12],[5,24,6],[6,14,5],[6,24,7],[7,15,6],[7,24,0],[8,0,1],[8,15,7],[8,16,15],[9,17,8],[10,17,9],[10,18,17],[11,12,20],[11,18,10],[11,19,18],[12,11,3],[13,20,12],[13,21,20],[14,13,5],[14,22,13],[15,14,6],[15,23,14],[16,23,15],[16,41,48],[17,16,8],[17,42,41],[18,19,44],[18,42,17],[18,43,42],[20,19,11],[20,21,46],[20,44,19],[20,45,44],[22,21,13],[22,47,46],[23,22,14],[23,48,22],[41,16,17],[44,43,18],[46,21,22],[46,45,20],[48,23,16],[48,47,22]]);]==]

local function softboxObj(sx, sy, sz, emissive)
  local o = OpenSCAD(string.format("scale([%g,%g,%g]) { %s }", sx, sy, sz, SOFTBOX_SCAD), 0, false)
  o.col = color.white
  if emissive then
    o.sdl = [[ texture{ pigment{White} finish{diffuse 0 emission 1} } ]]
  else
    o.sdl = [[ texture{ pigment{Gray} finish{diffuse 1} } ]]
  end
  return o
end

local function umbrellaObj(s, emissive)
  local o = OpenSCAD(string.format("scale([%g,%g,%g]) { %s }", s, s, s, UMBRELLA_SCAD), 0, false)
  o.col = color.white
  if emissive then
    o.sdl = [[ texture{ pigment{White} finish{diffuse 0 emission 1} } ]]
  else
    o.sdl = [[ texture{ pigment{Gray} finish{diffuse 1} } ]]
  end
  return o
end

-- q?(deg) build single-axis quaternions in bullet space (see
-- addPovodorCan()'s comment on common.transform()/setEuler()'s real
-- yaw=Y/pitch=X/roll=Z argument order); composeRotation() multiplies a
-- list of them together in listed order (first = applied first =
-- innermost), for the setups below whose original object{} chains apply
-- more than one rotate.
local function qY(deg) return common.quat(math.rad(deg), 0, 0) end
local function qX(deg) return common.quat(0, math.rad(deg), 0) end

local function composeRotation(steps)
  local q = btQuaternion(0, 0, 0, 1)
  for _, step in ipairs(steps) do
    local axis, deg = step[1], step[2]
    q = (axis == "x" and qX(deg) or qY(deg)) * q
  end
  return q
end

-- One entry per object{} call in i_studio_sets.inc's #case(1..6), each
-- pre-computed (see the derivation in addPovodorCan()'s comment on the
-- Z-flip/setEuler quirks, applied here to full translate+rotate*2 chains
-- via matrix composition rather than by hand): pos is bullet-space
-- (POV-space x,y unchanged, z negated); rot is the bullet-space
-- {axis,degrees} list for composeRotation(), in the same order as the
-- original POV chain's rotate steps (each angle negated, since a Z-flip
-- conjugation reverses the sign of any rotation about an axis that isn't
-- itself flipped -- X and Y both qualify, and no #case here rotates
-- about Z).
local STUDIO_SETUPS = {
  [1] = {
    { kind="softbox", scale={100,100,100}, emissive=true, pos={-129.904,150,75}, rot={{"y",-60}} },
    { kind="umbrella", scale=60, emissive=true, pos={0,190,-0}, rot={} },
  },
  [2] = {
    { kind="softbox", scale={150,150,150}, emissive=true, pos={86.9333,110,23.2937}, rot={{"x",-45},{"y",75}} },
    { kind="softbox", scale={50,50,50}, emissive=true, pos={-74.5649,110,-106.49}, rot={{"x",-15},{"y",-145}} },
    { kind="umbrella", scale=80, emissive=true, pos={-84.8528,180,84.8528}, rot={{"y",-45}} },
  },
  [3] = {
    { kind="softbox", scale={200,200,200}, emissive=true, pos={0,140,-0}, rot={{"x",-90}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={-100,100,0}, rot={{"y",-90}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={100,100,0}, rot={{"y",90}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={0,100,100}, rot={{"y",0}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={-0,100,-100}, rot={{"y",-180}} },
  },
  [4] = {
    { kind="umbrella", scale=60, emissive=true, pos={-95.2628,170,55}, rot={{"x",40},{"y",-60}} },
    { kind="softbox", scale={100,100,100}, emissive=true, pos={93.9693,150,34.202}, rot={{"y",70}} },
    { kind="softbox", scale={60,60,60}, emissive=true, pos={0,190,-0}, rot={{"x",-45}} },
  },
  [5] = {
    { kind="softbox", scale={200,200,200}, emissive=false, pos={0,250,-0}, rot={{"x",-90}} },
    { kind="softbox", scale={200,200,200}, emissive=true, pos={-100,150,0}, rot={{"y",-90}} },
    { kind="softbox", scale={200,200,200}, emissive=true, pos={100,150,0}, rot={{"y",90}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={0,150,100}, rot={{"y",0}} },
    { kind="softbox", scale={200,200,200}, emissive=false, pos={-0,150,-100}, rot={{"y",-180}} },
  },
  [6] = {
    { kind="umbrella", scale=60, emissive=true, pos={50,190,86.6025}, rot={{"x",60},{"y",30}} },
    { kind="softbox", scale={100,100,100}, emissive=true, pos={-98.4808,150,17.3648}, rot={{"y",-80}} },
    { kind="softbox", scale={60,60,60}, emissive=true, pos={98.4808,190,-17.3648}, rot={{"y",100}} },
  },
}

local lightFixtureObjects = {}

local function addLightFixtures(setupNum)
  local setup = STUDIO_SETUPS[setupNum]
  if setup == nil then return end
  for _, spec in ipairs(setup) do
    local obj
    if spec.kind == "softbox" then
      obj = softboxObj(spec.scale[1], spec.scale[2], spec.scale[3], spec.emissive)
    else
      obj = umbrellaObj(spec.scale, spec.emissive)
    end
    obj.trans = btTransform(composeRotation(spec.rot), btVector3(spec.pos[1], spec.pos[2], spec.pos[3]))
    v:add(obj)
    table.insert(lightFixtureObjects, obj)
  end
end

local function removeLightFixtures()
  for _, obj in ipairs(lightFixtureObjects) do
    v:remove(obj)
  end
  lightFixtureObjects = {}
end

-- POVODOR aerosol can, ported from the povodor union in
-- includes/i_demo_subjects.inc as three separate bpp Cylinder objects (base
-- ring, body, narrower cap) rather than one merged OpenSCAD mesh: textures
-- only survive OpenSCAD's STL round-trip as flat mesh color (STL carries no
-- per-face material/UV data), so getting the original's three distinct
-- per-part textures back means three separate Objects, each with its own
-- o.sdl. bpp's Cylinder rests along its local Z axis (centered on it), so
-- parts stack by offsetting along the can's own up axis.
--
-- common.transform(a, b, c, ...) forwards to btQuaternion::setEuler(a, b, c),
-- whose real signature is (yaw=Y, pitch=X, roll=Z) despite the a/b/c-ish
-- naming -- confirmed empirically (see demo/koppi/_rot_test.lua) with a
-- Cylinder, which rests lying along Z by default. So pitch (2nd arg) is
-- fixed at -pi/2 here to stand each part up (tips local Z to world Y), and
-- yaw (1st arg) is the free parameter for which way the can faces -- a pure
-- Y-axis rotation, so it doesn't disturb the vertical stacking below.
--
-- x, z, y are the can's base position (bpp/world coords, already
-- z-flip-corrected -- see the note on products() below); yaw is the can's
-- facing rotation about Y, in radians.
local function addPovodorCan(x, y, z, yaw)
  local base = Cylinder(4.75, 1, 0)
  base.trans = common.transform(yaw, -math.pi / 2, 0, x, y + 0.5, z)
  base.col = color.gold
  base.sdl = [[
    texture{
      pigment{Gold}
      finish{reflection{.3,.6}}
    }
  ]]
  v:add(base)

  local body = Cylinder(4.75, 26, 0)
  body.trans = common.transform(yaw, -math.pi / 2, 0, x, y + 1 + 13, z)
  body.col = color.yellow
  -- POV's cylindrical image_map wraps around the pigment's local Y axis by
  -- default; the body cylinder's long axis is local Z, so the pigment is
  -- rotated -90*x to match, then scaled/translated from the default unit
  -- cylinder onto the body's actual radius 4.75 x height 26 extent.
  body.sdl = [[
    texture{
      pigment{
        image_map{ jpeg "im_povodor.jpg" map_type 2 }
        scale <4.75,26,4.75>
        rotate -90*x
        translate 13*z
      }
      finish{reflection{.1,.2}}
    }
  ]]
  v:add(body)

  local cap = Cylinder(4.3, 8, 0)
  cap.trans = common.transform(yaw, -math.pi / 2, 0, x, y + 27 + 4, z)
  cap.col = color.orangered
  cap.sdl = [[
    texture{
      pigment{ OrangeRed*.75 }
      finish{reflection{.1,.2}}
    }
  ]]
  v:add(cap)
end

-- The demo products from i_demo_subjects.inc (two povodor cans + a soap
-- sphere), ported to real bpp Objects at the same positions the original
-- had relative to the backdrop (i_studio_backdrop.inc's surface sits at
-- world y=80, folded into these coordinates the same way the .pov's
-- "translate 80*y" did). Kept static (mass=0): the backdrop is decorative
-- POV-Ray SDL only, with no Bullet collision counterpart, so a dynamic body
-- would fall straight through it onto the y=0 ground plane instead.
--
-- bpp's POV export mirrors the whole scene through Z (see
-- Object::povMatrixFromGL() in src/objects/object.cpp), so matching the
-- original .pov's coordinates means negating z on every position here, and
-- negating the original's rotate 90*y / rotate -140*y facing angles (a
-- Y-axis rotation is its own mirror image under a Z-flip, just with the
-- opposite sign).
function products()
  addPovodorCan(-5, 80.17, -10, -math.pi / 2)
  addPovodorCan(4.5, 80.05, 10, 140 * math.pi / 180)

  local soap = Sphere(8, 0)
  soap.pos = btVector3(-9, 88, 12)
  soap.col = color.darkgreen
  soap.sdl = [[
    texture{
      pigment{ DarkGreen }
      normal{ crackle poly_wave .05 turbulence .1 scale 4 }
      finish{ reflection{.1,.3} }
    }
  ]]
  v:add(soap)
end

addFloor()
if v:getParam("demo_mode") == 1 then
  addWalls()
end
addBackdrop()
addLightFixtures(v:getParam("predefined_studio_setup"))
products()

-- v:onParamChanged only ever holds one callback (Viewer::_cb_onParamChanged
-- is a single field, overwritten by each call, not a list), so both
-- demo_mode and predefined_studio_setup are handled in this one function
-- rather than each registering their own.
v:onParamChanged(function(N, name, value)
  if name == "predefined_studio_setup" then
    removeLightFixtures()
    addLightFixtures(tonumber(value))
  elseif name == "demo_mode" then
    local newMode = tonumber(value)
    v.pre_sdl = buildPreSDL(newMode)
    removeWalls()
    if newMode == 1 then
      addWalls()
    end
  end
end)

-- camera: same location/look_at as studio-light-demo.pov's cl/la (with the
-- scene's 80*y translate folded in), z negated to compensate for bpp's POV
-- export mirroring the scene through Z (see Viewer's camera "location <
-- ..., -pos.z >" in src/viewer.cpp).
--
-- fov: the original sets its field of view via up/right/direction vector
-- lengths (up 3.2*y right 2.4*x direction 5*z) rather than an "angle"
-- keyword. That's a horizontal half-angle of atan(2.4/(2*5)) -- 26.9915deg
-- full angle (matching the file's own "aspect ratio 3/4 !!!" comment:
-- 2.4/3.2 = 3/4). The POV export writes "angle " .. 180*
-- camera()->horizontalFieldOfView()/pi (src/viewer.cpp), and QGLViewer's
-- Camera (src/objects/cam.h's base class) defines
-- horizontalFieldOfView() = 2*atan(tan(fieldOfView()/2) * aspectRatio())
-- and setHorizontalFieldOfView(hfov) as its exact inverse -- so as long as
-- aspectRatio() doesn't change between this call and export (true for a
-- single headless run), the two conversions cancel and
-- setHorizontalFieldOfView() reproduces the original's horizontal angle
-- exactly regardless of whatever aspect ratio is actually live.
common.setCamera(btVector3(0, 125, 95), btVector3(0, 97, 0), math.rad(26.9915),
                 { horizontal = true,
                   up = btVector3(0, 1, 0),
                   focal_blur = 0, focal_aperture = 5 })
