--
-- Spline flythrough camera demo
--
-- Demonstrates camera animation along a spline path with object tracking.
-- Shows an automatic camera that flies through the scene looking at different objects.
--
-- Usage: bpp demo/basic/14-spline-flythrough.lua

local spline = require "spline"
local color = require "color"

math.randomseed(1)

local floor = Plane(0, 1, 0, 0, 50)
floor.col = "#222222"
floor.friction = 0.8
floor.sdl = [[
  pigment {
    checker
    color rgb <0.2, 0.2, 0.2>
    color rgb <0.35, 0.35, 0.35>
    scale 2
  }
  finish {
    specular 0.1
    roughness 0.05
    reflection 0.1
  }
 ]]
v:add(floor)

local objects = {}

for i = 1, 70 do
  local s = Sphere(1 + math.random() * 2, 1)
  local range = 20
  s.pos = btVector3(
    (math.random() - 0.5) * range * 2,
    3 + math.random() * 10,
    (math.random() - 0.5) * range * 2
  )
  s.col = color.random_chrome()
  s.friction = 0.6
  s.restitution = 0.5
  s.sdl = [[
  material {
    texture {
      pigment { color rgbf <1, 1, 1, 0.9> }
      finish {
        specular 1
        roughness 0.001
        reflection 0.3
        ambient 0
        diffuse 0.1
      }
    }
    interior {
      ior 1.5
      caustics 1
    }
  }
 ]]
  v:add(s)
  table.insert(objects, s)
end

for i = 1, 70 do
  local size = 1 + math.random() * 2.5
  local c = Cube(size, size, size, 1)
  local range = 18
  c.pos = btVector3(
    (math.random() - 0.5) * range * 2,
    3 + math.random() * 12,
    (math.random() - 0.5) * range * 2
  )
  c.col = color.random_chrome()
  c.friction = 0.5
  c.restitution = 0.3
  v:add(c)
  table.insert(objects, c)
end

for i = 1, 7 do
  local r = 0.5 + math.random() * 1.5
  local h = 2 + math.random() * 4
  local c = Cylinder(r, h, 1)
  local range = 16
  c.pos = btVector3(
    (math.random() - 0.5) * range * 2,
    3 + math.random() * 8,
    (math.random() - 0.5) * range * 2
  )
  c.col = color.random_chrome()
  c.friction = 0.5
  v:add(c)
  table.insert(objects, c)
end

local cam_path_points = {}
local num_points = 16
for i = 0, num_points - 1 do
  local angle = (i / num_points) * math.pi * 2
  local radius = 35
  local height = 20 + 8 * math.sin(angle * 2)
  local x = radius * math.cos(angle)
  local z = radius * math.sin(angle)
  local y = height
  cam_path_points[i + 1] = btVector3(x, y, z)
end

v.cam.pos  = btVector3(cam_path_points[1].x, cam_path_points[1].y, cam_path_points[1].z)
v.cam.look = btVector3(cam_path_points[2].x, cam_path_points[2].y, cam_path_points[2].z)

local cam_spline = spline.CatmullRom(cam_path_points)

local anim_duration = 300
local anim_frame = 0
local animating = true
local current_target_idx = 1
local look_transition = 0
local zoom_in_frames = 50
local hold_frames = 20
local transition_frames = 30
local current_look = btVector3(0, 0, 0)
local prev_target_pos = btVector3(0, 0, 0)
local manual_mode = false
local manual_transition_frame = 0
local from_look = btVector3(0, 0, 0)
local to_look = btVector3(0, 0, 0)
local transition_spline = nil

function cycle_object(direction)
  manual_mode = true
  from_look = current_look
  manual_transition_frame = 0

  local new_target_idx = current_target_idx + direction
  if new_target_idx > #objects then
    new_target_idx = 1
  elseif new_target_idx < 1 then
    new_target_idx = #objects
  end
  current_target_idx = new_target_idx

  local to_obj = objects[current_target_idx]
  to_look = btVector3(to_obj.pos.x, to_obj.pos.y, to_obj.pos.z)

  local from_pos = { x = from_look.x, y = from_look.y, z = from_look.z }
  local to_pos = { x = to_look.x, y = to_look.y, z = to_look.z }
  local mid_pos = {
    x = (from_pos.x + to_pos.x) / 2,
    y = (from_pos.y + to_pos.y) / 2 + 3,
    z = (from_pos.z + to_pos.z) / 2,
  }
  transition_spline = spline.CatmullRom({from_pos, mid_pos, to_pos})
end

v:postSim(function(N)
  if not animating then return end

  local progress = anim_frame / anim_duration

  if progress > 1 then
    progress = progress - 1
    anim_frame = 0
  end

  local t = progress * cam_spline.num_segments

  local p = cam_spline:eval(t)
  v.cam.pos = btVector3(p.x, p.y, p.z)

  if manual_mode then
    manual_transition_frame = manual_transition_frame + 1
    if transition_spline and manual_transition_frame <= zoom_in_frames then
      local blend = manual_transition_frame / zoom_in_frames
      local sp = transition_spline:eval(blend * transition_spline.num_segments)
      current_look = btVector3(sp.x, sp.y, sp.z)
    else
      current_look = to_look
    end
  else
    look_transition = look_transition + 1
    local cycle_frames = zoom_in_frames + hold_frames + transition_frames
    local phase = look_transition % cycle_frames

    if look_transition > cycle_frames - 1 then
      look_transition = 0
      prev_target_pos = current_look
      current_target_idx = (current_target_idx % #objects) + 1
    end

    local target = objects[current_target_idx]
    local target_pos = btVector3(target.pos.x, target.pos.y, target.pos.z)

    if phase < zoom_in_frames then
      local blend = phase / zoom_in_frames
      current_look = btVector3(
        prev_target_pos.x + (target_pos.x - prev_target_pos.x) * blend,
        prev_target_pos.y + (target_pos.y - prev_target_pos.y) * blend,
        prev_target_pos.z + (target_pos.z - prev_target_pos.z) * blend
      )
    elseif phase < zoom_in_frames + hold_frames then
      current_look = target_pos
    else
      current_look = target_pos
    end
  end

  v.cam.look = current_look

  local forward = {
    x = current_look.x - p.x,
    y = current_look.y - p.y,
    z = current_look.z - p.z,
  }
  local len = math.sqrt(forward.x^2 + forward.y^2 + forward.z^2)
  if len > 0.001 then
    forward.x = forward.x / len
    forward.y = forward.y / len
    forward.z = forward.z / len
  end

  local default_up = { x = 0, y = 1, z = 0 }
  local right = {
    x = forward.y * default_up.z - forward.z * default_up.y,
    y = forward.z * default_up.x - forward.x * default_up.z,
    z = forward.x * default_up.y - forward.y * default_up.x,
  }
  local rlen = math.sqrt(right.x^2 + right.y^2 + right.z^2)
  if rlen > 0.001 then
    right.x = right.x / rlen
    right.y = right.y / rlen
    right.z = right.z / rlen

    local new_up = {
      x = right.y * forward.z - right.z * forward.y,
      y = right.z * forward.x - right.x * forward.z,
      z = right.x * forward.y - right.y * forward.x,
    }
    v.cam:setUpVector(btVector3(new_up.x, new_up.y, new_up.z), true)
  end

  anim_frame = anim_frame + 1
end)

v:preDraw(function(N)
  if not animating then return end

  for _, obj in ipairs(objects) do
    local p = obj.pos
    if p.y < -50 then
      obj.pos = btVector3(
        (math.random() - 0.5) * 30,
        10 + math.random() * 10,
        (math.random() - 0.5) * 30
      )
      obj.vel = btVector3(0, 0, 0)
    end
  end
end)

function restart()
  anim_frame = 0
  animating = true
end
