-- Light sources (LIGHTS.md, step 2): PointLight, SpotLight, CylinderLight,
-- ParallelLight and AreaLight, each written as POV-Ray's light_source
-- (z negated, as the export does for everything); the area settings on any
-- kind; the modifiers; a LightSys light (lumens) through LightSys's own
-- Light_Color() and Light_Fading(); and v:add / v:remove taking lights.
-- (That an export writes them, and tells settings.inc to make none of its
-- own, is the render suite's check: tests/render/lights.lua.)

local pass = 0
local fail = 0

local function assert_eq(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ":\n got=" .. tostring(got) .. "\n expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local function sdl(lines)
  return table.concat(lines, "\n") .. "\n"
end

-- each kind, as made
assert_eq("PointLight", PointLight(btVector3(1, 2, 3)):toPOV(), sdl{
  "light_source {",
  "  <1, 2, -3>",
  "  color rgb <1, 1, 1> * 1",
  "}"})

assert_eq("SpotLight", SpotLight(btVector3(0, 100, 0), btVector3(0, 0, 10)):toPOV(), sdl{
  "light_source {",
  "  <0, 100, 0>",
  "  color rgb <1, 1, 1> * 1",
  "  spotlight",
  "  point_at <0, 0, -10>",
  "  radius 30 falloff 45 tightness 0",
  "}"})

assert_eq("CylinderLight", CylinderLight(btVector3(0, 100, 0), btVector3(0, 0, 0)):toPOV(), sdl{
  "light_source {",
  "  <0, 100, 0>",
  "  color rgb <1, 1, 1> * 1",
  "  cylinder",
  "  point_at <0, 0, 0>",
  "  radius 0.75 falloff 1 tightness 0",
  "}"})

assert_eq("ParallelLight", ParallelLight(btVector3(0, 1000, 500), btVector3(0, 0, 0)):toPOV(), sdl{
  "light_source {",
  "  <0, 1000, -500>",
  "  color rgb <1, 1, 1> * 1",
  "  parallel",
  "  point_at <0, 0, 0>",
  "}"})

assert_eq("AreaLight", AreaLight(btVector3(0, 200, 0)):toPOV(), sdl{
  "light_source {",
  "  <0, 200, 0>",
  "  color rgb <1, 1, 1> * 1",
  "  area_light <40, 0, 0>, <0, 0, -40>, 4, 4",
  "  adaptive 1",
  "  jitter",
  "}"})

assert_eq("default constructors", PointLight():toPOV() .. ParallelLight():toPOV(), sdl{
  "light_source {",
  "  <0, 0, 0>",
  "  color rgb <1, 1, 1> * 1",
  "}",
  "light_source {",
  "  <0, 0, 0>",
  "  color rgb <1, 1, 1> * 1",
  "  parallel",
  "  point_at <0, 0, 1>",
  "}"})

assert_eq("tostring", tostring(SpotLight()) .. " " .. tostring(AreaLight()), "SpotLight AreaLight")

-- the modifiers
local p = PointLight(btVector3(0, 50, 0))
p.col = "#ff8000"
p.power = 2
p.fade_distance = 100
p.fade_power = 2
p.shadowless = true
p.media_interaction = false
p.media_attenuation = true
assert_eq("col reads back", p.col, "#ff8000")
assert_eq("modifiers", p:toPOV(), sdl{
  "light_source {",
  "  <0, 50, 0>",
  "  color rgb <1, 0.501961, 0> * 2",
  "  fade_distance 100 fade_power 2",
  "  shadowless",
  "  media_interaction off",
  "  media_attenuation on",
  "}"})

-- a spot that is an area light too, round and turned toward what it lights
local s = SpotLight(btVector3(0, 100, 0), btVector3(0, 0, 0))
s.radius, s.falloff, s.tightness = 10, 20, 5
s.axis1, s.axis2 = btVector3(9, 0, 0), btVector3(0, 0, 9)
s.n1, s.n2 = 3, 3
s.circular, s.orient = true, true
assert_eq("area spot", s:toPOV(), sdl{
  "light_source {",
  "  <0, 100, 0>",
  "  color rgb <1, 1, 1> * 1",
  "  spotlight",
  "  point_at <0, 0, 0>",
  "  radius 10 falloff 20 tightness 5",
  "  area_light <9, 0, 0>, <0, 0, -9>, 3, 3",
  "  circular",
  "  orient",
  "}"})

-- LightSys: demo_indoor1.pov's halogen, as it writes it (in bpp's z)
local h = SpotLight(btVector3(-130, 249.9, -175), btVector3(-130, -0.1, -175))
h.lumens = 1000
h.lightsys = "Cl_Halogen"
h.radius, h.falloff, h.tightness = 15, 45, 0
h.axis1, h.axis2, h.n1, h.n2 = btVector3(9, 0, 0), btVector3(0, 0, 9), 4, 4
h.adaptive, h.jitter, h.circular = 1, true, true
h.fade_distance = 50                           -- (LightSys fades its own way)
assert_eq("LightSys spot", h:toPOV(), sdl{
  "light_source {",
  "  <-130, 249.9, 175>",
  "  Light_Color(Cl_Halogen, 1000)",
  "  spotlight",
  "  point_at <-130, -0.1, 175>",
  "  radius 15 falloff 45 tightness 0",
  "  area_light <9, 0, 0>, <0, 0, -9>, 4, 4",
  "  adaptive 1",
  "  jitter",
  "  circular",
  "  Light_Fading()",
  "}"})

-- no LightSys colour: its own, as rgb; a parallel LightSys light doesn't fade
local sun = ParallelLight(btVector3(0, 1000, 0), btVector3(0, 0, 0))
sun.lumens = 1
sun.col = "#ffffff"
assert_eq("LightSys parallel", sun:toPOV(), sdl{
  "light_source {",
  "  <0, 1000, 0>",
  "  Light_Color(<1, 1, 1>, 1)",
  "  parallel",
  "  point_at <0, 0, 0>",
  "}"})

-- v:add and v:remove take lights, a table of them too; twice is harmless,
-- and a removed light is still the script's
local a, b = PointLight(btVector3(0, 10, 0)), AreaLight(btVector3(0, 20, 0))
v:add(a)
v:add(a)
v:add({ b })
local back = v:remove(b)
assert_eq("v:remove gives the light back", back, b)
b.pos = btVector3(0, 30, 0)
assert_eq("a removed light is usable", b.pos.y, 30)
v:add(b)
a.pos.x = 5                                     -- (a light added is changed in place)
assert_eq("a light added can be moved", a.pos.x, 5)

print(pass .. " passed, " .. fail .. " failed")
