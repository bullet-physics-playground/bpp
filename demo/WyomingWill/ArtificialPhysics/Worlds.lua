--
-- Worlds -- a viewer for the world generator's book presets (lib/world.lua)
--
-- Shows the worlds every chapter port will take from one place (BOOK.md
-- G21), so they can be checked by eye against the book's figures:
--
--   preset 1  Ch. 3.6  formation_goal_obs: 12 obstacle discs between the
--             particles' start (green) and the goal (blue). obstacleRadius
--             10 is Fig. 3.25; 50 merges them into Fig. 3.26's wall.
--   preset 2  Ch. 4.3 / Ch. 11: the 84 x 84 coverage box in nine cells
--             (blue corners, green sides, red centre, as in the NetLogo model).
--   preset 3  Ch. 7: the 1000" x 5000" corridor with random rectangles,
--             triangles and circles covering obstaclePercent of it, on the
--             50 x 250 cell grid; showShadow marks the "shadow" cells just
--             downstream of obstacles in magenta.
--
-- Sliders rebuild the world at once. worldSeed picks the random layout
-- (preset 3); the same seed always gives the same corridor. Nothing moves:
-- this is geometry only. Status line: the world's summary.
--

local common = require "common"
local World = require "lib.world"

common.setTiming(1 / 30, 1, 1 / 30)
common.gravity(0)

v:addParam("preset", 1, 1, 3, 1, "1 = Ch. 3 obstacle discs, 2 = Ch. 4 coverage box, 3 = Ch. 7 corridor")
v:addParam("obstacleRadius", 10, 5, 60, 1, "Ch. 3: obstacleF, the discs' radius (10 in Fig. 3.25, 50 in Fig. 3.26)")
v:addParam("obstaclePercent", 30, 0, 50, 1, "Ch. 7: share of the corridor covered by obstacles")
v:addParam("worldSeed", 1, 1, 1000, 1, "Ch. 7: random layout; the same seed gives the same corridor")
v:addParam("showCells", true, "colour the metric cells")
v:addParam("showShadow", true, "Ch. 7: mark the shadow cells (just downstream of obstacles)")

local objs, lastKey = {}, nil
local SCALE = { 0.25, 1, 0.02 }        -- world units -> BPP units, per preset

local function clear()
  for _, o in ipairs(objs) do v:remove(o) end
  objs = {}
end

local function build(moveCamera)
  local p = math.floor(v:getParam("preset") + 0.5)
  local w
  if p == 1 then
    w = World.preset("ch03-obstacles", { radius = v:getParam("obstacleRadius") })
  elseif p == 2 then
    w = World.preset("ch04-coverage")
  else
    w = World.preset("ch07-corridor", { percent = v:getParam("obstaclePercent"),
                                        seed = math.floor(v:getParam("worldSeed")) })
  end
  local key = table.concat({ p, v:getParam("obstacleRadius"), v:getParam("obstaclePercent"),
                             v:getParam("worldSeed"), tostring(v:getParam("showCells")),
                             tostring(v:getParam("showShadow")) }, "|")
  if key == lastKey then return end
  lastKey = key
  clear()

  local S = SCALE[p]
  local opts = { scale = S, colors = { obstacle = "#8c8c8c", wall = "#ffff00", floor = "#202028" } }
  if p == 2 and v:getParam("showCells") then
    opts.cellFloor = true
    opts.cellColor = function(i, j)          -- blue corners, green sides, red centre
      local edge = (i == 1 and 1 or 0) + (j == 1 and 1 or 0)
      return ({ [0] = "#0000ff", [1] = "#00c000", [2] = "#ff0000" })[edge]
    end
  elseif p == 3 and v:getParam("showCells") then
    opts.cellFloor = true
    if v:getParam("showShadow") then opts.mask = w:shadowCells() end
  end
  objs = w:toBPP(v, opts)

  local b = w.bounds
  local cx, cz = (b.x0 + b.x1) / 2 * S, World.bppZ((b.y0 + b.y1) / 2, S)
  local span = math.max(b.x1 - b.x0, b.y1 - b.y0) * S
  if moveCamera then
    if p == 3 then
      -- from just behind the start, looking down the corridor toward the goal
      local z0 = World.bppZ(b.y0, S)
      common.setCamera(btVector3(cx + 0.12 * span, 0.16 * span, z0 + 0.10 * span),
                       btVector3(cx, 0, z0 - 0.30 * span))
    elseif p == 2 then
      common.setCamera(btVector3(cx, 1.25 * span, cz + 0.95 * span), btVector3(cx, 0, cz))
    else
      common.setCamera(btVector3(cx, 0.95 * span, cz + 0.75 * span), btVector3(cx, 0, cz))
    end
  end

  local extra = ""
  if p == 3 then
    local _, nShadow = w:shadowCells()
    extra = string.format("  |  covered %.1f%%  |  %d shadow cells", 100 * (w.reached or 0), nShadow)
  end
  local line = w:summary() .. extra
  pcall(function() v.statusText = line end)
  print(line)
  for _, n in ipairs(w.notes) do print("  note: " .. n) end
end

local lastPreset = nil
v:onParamChanged(function(N, name, value)
  local p = math.floor(v:getParam("preset") + 0.5)
  build(p ~= lastPreset)
  lastPreset = p
end)

pcall(function() v:setHelpText([[
Worlds: the world generator's book presets (lib/world.lua)

preset 1  Ch. 3.6 obstacle discs (obstacleRadius 10 = Fig. 3.25, 50 = Fig. 3.26)
preset 2  Ch. 4.3 / Ch. 11 coverage box, nine cells
preset 3  Ch. 7 corridor (obstaclePercent, worldSeed; magenta = shadow cells)

Sliders rebuild at once. The camera moves only when the preset changes.]]) end)

lastPreset = math.floor(v:getParam("preset") + 0.5)
build(true)

-- EOF
