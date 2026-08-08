--
-- Dice demo
--
-- Shows falling dice with physics simulation.
-- Uses custom dice and text modules.
--
-- Usage: bpp -f demo/basic/10-dice.lua

local color  = require "color"
local dice   = require "povray/dice"
local text   = require "scad/text"
local common = require "common"

common.setTiming(1/5, 20, 1/120)

v.pre_sdl = [==[
#include "finish.inc"
#include "textures.inc"
#include "dice.inc"
]==]

p = Plane(0,1,0,0,10)
p.col = color.pov_tan
p.friction = 100
--p.sdl = [[ texture { pigment { color White } }]]
v:add(p)

v:add(text.new({ str = "Bullet Physics Playground",
  size = 1, height = 1, y = 8, z = -2, mass = 0}))

function run()
  d = dice.new({ mass = 10, col = color.random_google() })
  d.friction = 100
  d.pos=btVector3(0,0.45,0)
  v:add(d)
end

run()run()

v:postSim(function(N)
  if (N % 1 == 0 and N < 1000) then
    run()
  end

  c = 2.5
  i = math.sin(N/100)*c/2
  j = math.cos(N/100)*c/2
--  v.gravity = btVector3(0,-c,0)
  v.gravity = btVector3(i,-c,j)

  tmp = v.cam.pos tmp.z = tmp.z + 0.1 v.cam.pos = tmp
  tmp = v.cam.pos tmp.y = tmp.y + 0.1 v.cam.pos = tmp
  tmp = v.cam.look tmp.y = tmp.y + 0.001 v.cam.look = tmp
end)

v:onCommand(function(N, cmd)
  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

common.setCamera(btVector3(0, 4, 550), btVector3(0, 4, 0), 0.025,
                 { noMove = false })
