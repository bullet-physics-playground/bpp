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
blob.pos    = btVector3(-6, 2, -4)
blob.col    = color.red
blob.mass   = 1
blob:addSphereComponent(btVector3(0, 0, 0), 1.2, 1.0)
blob:addSphereComponent(btVector3(1.0, 0.5, 0.0), 0.8, 0.8)
blob:addCylinderComponent(btVector3(-0.8, -0.5, 0.0),
                          btVector3(0, 1, 0), 0.5, 1.5, 0.6)
blob.transparency = 0.3
blob.hollow = true
blob.no_reflection = false
blob.post_sdl = [=[
  photons { pass_through }
}
]=]
v:add(blob)
local text = TrueType("Generic.ttf", "BPP", 1.5, 1)
text.pos    = btVector3(-2, 2, -4)
text.col    = color.blue
text.mass   = 1
text.hollow = true
text.no_reflection = true
v:add(text)
local patch = Patch(2.0, 1)
patch.pos   = btVector3(2, 2, -4)
patch.col   = color.green
patch.mass  = 1
patch.hollow = true
patch.no_reflection = false
v:add(patch)
local sq = SuperQuadric(0.5, 0.5, 1.2, 1)
sq.pos    = btVector3(-2, 2, 0)
sq.col    = color.purple
sq.mass   = 1
sq.hollow = true
v:add(sq)
local sq2 = SuperQuadric(0.3, 0.8, 1.0, 1)
sq2.pos   = btVector3(2, 2, 0)
sq2.col   = color.cyan
sq2.mass  = 1
sq2.hollow = true
v:add(sq2)
print("ALL OBJECTS EXCEPT BOUND ADDED WITH TRANSPARENCY")
