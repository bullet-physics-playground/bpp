local color = require "color"
local common = require "common"
common.setTiming(1/25, 60, 1/60)
v.cam.pos   = btVector3(0, 8, -16)
v.cam.look  = btVector3(0, 0, 0)
v.cam.up    = btVector3(0, 1, 0)
local ground = Plane(0, 1, 0, 0, 200)
ground.pos   = btVector3(0, 0, 0)
ground.col   = color.white
ground.mass  = 0
ground.hollow = true
ground.no_reflection = true
v:add(ground)
local sweep = Sweep(0, btVector3(0, 1, 0), 0.0, 1)
sweep:addProfilePoint(0.5, 0.0)
sweep:addProfilePoint(0.8, 0.5)
sweep.pos = btVector3(-6, 2, 0)
sweep.col = color.orange
sweep.mass = 1
v:add(sweep)
local blob = Blob(1.0, 1)
blob.pos = btVector3(-6, 2, -4)
blob.col = color.red
blob.mass = 1
blob:addSphereComponent(btVector3(0, 0, 0), 1.2, 1.0)
blob.hollow = true
v:add(blob)
local text = TrueType("Generic.ttf", "BPP", 1.5, 1)
text.pos = btVector3(-2, 2, -4)
text.col = color.blue
text.mass = 1
text.hollow = true
v:add(text)
local patch = Patch(2.0, 1)
patch.pos = btVector3(2, 2, -4)
patch.col = color.green
patch.mass = 1
patch.hollow = true
v:add(patch)
local sq = SuperQuadric(0.5, 0.5, 1.2, 1)
sq.pos = btVector3(-2, 2, 0)
sq.col = color.purple
sq.mass = 1
sq.hollow = true
v:add(sq)
local sq2 = SuperQuadric(0.3, 0.8, 1.0, 1)
sq2.pos = btVector3(2, 2, 0)
sq2.col = color.cyan
sq2.mass = 1
sq2.hollow = true
v:add(sq2)
local bound = Bound(btSphereShape(0.8), 1)
bound.pos = btVector3(6, 2, -4)
bound.col = color.yellow
bound.mass = 1
bound.hollow = true
v:add(bound)
local ref = ReferenceObject("RefCube")
ref.pos = btVector3(6, 2, 0)
ref.col = color.white
ref.mass = 0
ref.hollow = true
v:add(ref)
v.pre_sdl = [=[
#version 3.8;
global_settings {
  assumed_gamma 1.0
  max_trace_level 15
}
]=]
v:preSim(function(N)
  sq.rot = btQuaternion(btVector3(0, 1, 0), N * 0.03)
  sq2.rot = btQuaternion(btVector3(0, 1, 0), -N * 0.025)
  sweep.rot = btQuaternion(btVector3(0, 1, 0), N * 0.02)
end)
print("ALL OBJECTS WITH PRE_SDL AND PRE_SIM OK")
