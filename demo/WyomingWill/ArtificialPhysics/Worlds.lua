--
-- Worlds -- a viewer for the world generator's book presets (lib/world.lua)
--
-- Shows the worlds every chapter port will take from one place (BOOK.md
-- G21), so they can be checked by eye against the book's figures:
--
--   preset 1  Ch. 3.6  formation_goal_obs, Fig. 3.25: 12 obstacle discs of
--             radius 10 between the particles' start (green) and the goal
--             (blue), measured from the figure.
--   preset 2  Ch. 3.6, Fig. 3.26: a different field (obstacles are placed by
--             mouse clicks), 6 discs of radius 45 merged into the wall the
--             formation rotates around, measured from the figure.
--             Choosing preset 1 or 2 sets obstacleRadius to the figure's
--             value; move it to experiment.
--   preset 3  Ch. 4.3 / Ch. 11: the 84 x 84 coverage box in nine cells
--             (blue corners, green sides, red centre, as in the NetLogo model).
--   preset 4  Ch. 7: the 1000" x 5000" corridor with random rectangles,
--             triangles and circles covering obstaclePercent of it, on the
--             50 x 250 cell grid; showShadow marks the "shadow" cells just
--             downstream of obstacles in magenta.
--
-- DEFINITIONS (status line): the world's name and size in the book's units
-- (patches for Ch. 3 and 4, inches for Ch. 7); its pieces by kind; the cell
-- grid used by the metrics; for the corridor, "covered" = share of the
-- corridor's area under obstacles (overlaps counted once) and "shadow
-- cells" = free cells whose neighbour toward the start is more than half
-- obstacle (Ch. 7's cells just downstream of obstacles, Fig. 7.9).
--
-- Sliders rebuild the world at once. worldSeed picks the random layout
-- (preset 4); the same seed always gives the same corridor. Nothing moves:
-- this is geometry only. Status line: the world's summary.
--

local common = require "common"
local World = require "lib.world"

common.setTiming(1 / 30, 1, 1 / 30)
common.gravity(0)

v:addParam("preset", 1, 1, 4, 1, "1 = Ch. 3 Fig. 3.25, 2 = Ch. 3 Fig. 3.26, 3 = Ch. 4 coverage box, 4 = Ch. 7 corridor")
local RADIUS_COMMENT = "Ch. 3: obstacleF, the discs' radius (Fig. 3.25: 10; Fig. 3.26: 45 measured, 50 in the text)"
v:addParam("obstacleRadius", 10, 5, 60, 1, RADIUS_COMMENT)
v:addParam("obstaclePercent", 30, 0, 50, 1, "Ch. 7: share of the corridor covered by obstacles")
v:addParam("worldSeed", 1, 1, 1000, 1, "Ch. 7: random layout; the same seed gives the same corridor")
v:addParam("showCells", true, "colour the metric cells")
v:addParam("showShadow", true, "Ch. 7: mark the shadow cells (just downstream of obstacles)")

local objs, lastKey = {}, nil
local SCALE = { 0.25, 0.25, 1, 0.02 }  -- world units -> BPP units, per preset

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
    w = World.preset("ch03-wall", { radius = v:getParam("obstacleRadius") })
  elseif p == 3 then
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
  if p == 3 and v:getParam("showCells") then
    opts.cellFloor = true
    opts.cellColor = function(i, j)          -- blue corners, green sides, red centre
      local edge = (i == 1 and 1 or 0) + (j == 1 and 1 or 0)
      return ({ [0] = "#0000ff", [1] = "#00c000", [2] = "#ff0000" })[edge]
    end
  elseif p == 4 and v:getParam("showCells") then
    opts.cellFloor = true
    if v:getParam("showShadow") then opts.mask = w:shadowCells() end
  end
  objs = w:toBPP(v, opts)

  local b = w.bounds
  local cx, cz = (b.x0 + b.x1) / 2 * S, World.bppZ((b.y0 + b.y1) / 2, S)
  local span = math.max(b.x1 - b.x0, b.y1 - b.y0) * S
  if moveCamera then
    if p == 4 then
      -- from just behind the start, looking down the corridor toward the goal
      local z0 = World.bppZ(b.y0, S)
      common.setCamera(btVector3(cx + 0.12 * span, 0.16 * span, z0 + 0.10 * span),
                       btVector3(cx, 0, z0 - 0.30 * span))
    elseif p == 3 then
      common.setCamera(btVector3(cx, 1.25 * span, cz + 0.95 * span), btVector3(cx, 0, cz))
    else
      common.setCamera(btVector3(cx, 0.95 * span, cz + 0.75 * span), btVector3(cx, 0, cz))
    end
  end

  local extra = ""
  if p == 4 then
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
  if name == "preset" and p ~= lastPreset and (p == 1 or p == 2) then
    lastPreset = p
    -- the figure's own radius; this addParam calls back here and rebuilds
    v:addParam("obstacleRadius", p == 1 and 10 or 45, 5, 60, 1, RADIUS_COMMENT)
    lastKey = nil
    build(true)
    return
  end
  build(p ~= lastPreset)
  lastPreset = p
end)

pcall(function() v:setHelpText([[
Worlds: the world generator's book presets (lib/world.lua)

preset 1  Ch. 3.6 obstacle discs, Fig. 3.25 (radius 10)
preset 2  Ch. 3.6 obstacle wall, Fig. 3.26 (6 discs, radius 45)
preset 3  Ch. 4.3 / Ch. 11 coverage box, nine cells
preset 4  Ch. 7 corridor (obstaclePercent, worldSeed; magenta = shadow cells)

Sliders rebuild at once. The camera moves only when the preset changes.]]) end)

lastPreset = math.floor(v:getParam("preset") + 0.5)
build(true)

-- EOF
