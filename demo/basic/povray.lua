--
-- POV-Ray 3.8 photons demo
--
-- Demonstrates POV-Ray 3.8 export features:
--   * #version 3.8 semantics
--   * Radiosity block (count, error_bound, pretrace_start/end)
--   * Photons block (count, media, spacing)
--   * Fog (constant fog with color)
--   * Multiple light sources (spotlight, fill, directional)
--   * Object modifiers: hollow, no_image, no_reflection
--   * Photons pass_through on the glass box
--   * Photons target reflection on the reflective floor
--   * Photons reflection off on the fill light
--
-- Run with: bpp -f demo/basic/povray.lua -e
--

local color = require "color"
local common = require "common"

common.setTiming(1/25, 60, 1/60)

-- Camera: look into the room from the corner
v.cam.pos   = btVector3(-12, 6, -12)
v.cam.look  = btVector3(0, 0, 0)
v.cam.up    = btVector3(0, 1, 0)

-- ---------------------------------------------------------------------------
-- ROOM
-- ---------------------------------------------------------------------------

-- Reflective floor with colored reflection (copper-like) and photons target
local floor = Plane(0, 1, 0, 0, 200)
floor.pos   = btVector3(0, 0, 0)
floor.col   = color.white
floor.mass  = 0
floor.hollow = true
floor.no_image = false
floor.no_reflection = false
floor.post_sdl = [=[
  finish { reflection <0.5, 0.4, 0.2> }
  photons { target reflection on }
}
]=]
v:add(floor)

-- Back wall
local back = Plane(0, 0, 1, 0, 200)
back.pos   = btVector3(0, 0, 20)
back.col   = color.white
back.mass  = 0
back.hollow = true
back.no_reflection = true
v:add(back)

-- Left wall
local left = Plane(1, 0, 0, 0, 200)
left.pos   = btVector3(-20, 0, 0)
left.col   = color.white
left.mass  = 0
left.hollow = true
left.no_reflection = true
v:add(left)

-- Right wall
local right = Plane(1, 0, 0, 0, 200)
right.pos   = btVector3(20, 0, 0)
right.col   = color.white
right.mass  = 0
right.hollow = true
right.no_reflection = true
v:add(right)

-- Ceiling
local ceil = Plane(0, 1, 0, 0, 200)
ceil.pos   = btVector3(0, 20, 0)
ceil.col   = color.white
ceil.mass  = 0
ceil.hollow = true
ceil.no_reflection = true
v:add(ceil)

-- ---------------------------------------------------------------------------
-- GLASS BOX (photons pass through it)
-- ---------------------------------------------------------------------------
--
-- A semi-transparent glass box. photons { pass_through } lets photons enter
-- and exit, so the spotlight beam is visible passing through it.
--

local glass_box = Cube(6, 6, 6, 0)
glass_box.pos     = btVector3(0, 3, 0)
glass_box.col     = color.white
glass_box.mass    = 0
glass_box.hollow  = true
glass_box.no_image = false
glass_box.no_reflection = true
glass_box.transparency = 0.3
glass_box.post_sdl = [=[
  photons { pass_through }
}
]=]
v:add(glass_box)

-- ---------------------------------------------------------------------------
-- LIGHTS
-- ---------------------------------------------------------------------------

-- Main spotlight: beam entering through the "window", passing through glass
local spot = Sphere(0.2, 0)
spot.pos    = btVector3(-8, 15, -8)
spot.col    = color.white
spot.mass   = 0
spot.no_image = true
spot.no_reflection = true
v:add(spot)

-- Fill light: photons turned off so it only illuminates, doesn't emit photons
local fill = Sphere(0.2, 0)
fill.pos    = btVector3(8, 12, 8)
fill.col    = color.white
fill.mass   = 0
fill.no_image = true
fill.no_reflection = true
fill.post_sdl = [=[
  photons { reflection off }
}
]=]
v:add(fill)

-- ---------------------------------------------------------------------------
-- POV-RAY 3.8 SCENE SETTINGS
-- ---------------------------------------------------------------------------

v.pov_settings_inc = "settings.inc"

v.pre_sdl = [=[

#version 3.8;

global_settings {
  assumed_gamma 1.0
  max_trace_level 15
  adc_bailout 0.001

  // Photons interact with scattering media (media 100 = 100% interaction)
  photons {
    count 20000
    media 100
  }
}

// --- Fog (background haze) ---
fog {
  fog_type 1
  distance 200
  color rgb <0.85, 0.9, 0.95>
}

// --- Lights ---

// Spotlight beam entering the room, passing through the glass box
light_source {
  <-8, 15, -8>
  color rgb <1, 1, 1>
  spotlight
  point_at <0, 3, 0>
  radius 0.5
  tightness 80
  falloff 50
}

// Fill light: illuminates the interior but emits no photons
light_source {
  <8, 12, 8>
  color rgb <0.7, 0.8, 1>
  photons { reflection off }
}

// Directional rim light from behind
light_source {
  <0, -1, -1>
  color rgb <0.8, 0.8, 1>
  parallel
}
]=]

-- ---------------------------------------------------------------------------
-- ANIMATION
-- ---------------------------------------------------------------------------

-- Slowly move the spotlight so the beam sweeps through the glass box
v:preSim(function(N)
  spot.pos = btVector3(-8 + 4 * math.sin(N * 0.03), 15, -8 + 4 * math.cos(N * 0.03))
end)

print("Photons demo loaded. Run with -e to export frames for rendering.")
