--
-- ch13/uavscene.lua -- drawing and running a ch13/uav.lua world in BPP
--
-- Shared by UAV-Targets.lua and UAV-Attractor.lua. The book's plane (x, y)
-- is drawn as BPP (x, -z) with y up (lib/world.lua's mapping), seen from
-- straight above, in metres. UAVs are white darts (length DART m) pointing
-- along their heading, targets red spheres, trails one dot every TRAIL_EVERY
-- seconds per UAV (the last TRAIL dots). BPP runs a scene as soon as it
-- loads; R restarts it.
--
-- STATUS LINE (from the start of the run):
--   t        flight time, s
--   over     share of the UAV samples inside the targets' rectangle so far
--   |Omega|  mean turn rate so far, rad/s (Omega_max 0.129)
--   spread   RMS distance of the UAVs from the targets' centroid, now, m
--   minSep   least distance between two UAVs so far, m
--
package.path = "../?.lua;" .. package.path
local common = require "common"
local U = require "ch13.uav"
local FW = require "fixedwing.model"
local status = require "lib.status"

local S = {}
local CF_STATIC, CF_NO_CONTACT = 1, 4
local function quiet(o)
  o.collides = false
  pcall(function() o.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end)
  return o
end
local DART, TRAIL, TRAIL_EVERY = 12, 400, 1
local COLS = { "#ffffff", "#ffd040", "#60c0ff", "#80ff80", "#ff80ff", "#ffa060", "#a0a0ff" }

-- opts: title; build() -> world; camHeight (m); help
function S.run(opts)
  common.setTiming(1 / 30, 1, 1 / 30)
  common.gravity(0)
  v:addParam("ticksPerFrame", 10, 1, 200, 1, "outer-loop ticks (0.1 s each) per drawn frame: display speed only")
  local w, darts, tobjs, trail, nextDot, ticks = nil, {}, {}, {}, 1, 0
  local acc = { n = 0, inside = 0, om = 0, minSep = math.huge }
  local function P(x, y, h) return btVector3(x, h or 0, -y) end

  local function clearAll()
    for _, o in ipairs(darts) do v:remove(o) end
    for _, o in ipairs(tobjs) do v:remove(o) end
    for _, o in ipairs(trail) do v:remove(o.obj) end
    darts, tobjs, trail, nextDot, ticks = {}, {}, {}, 1, 0
    acc = { n = 0, inside = 0, om = 0, minSep = math.huge }
  end

  local function draw()
    for i, u in ipairs(w.uavs) do
      local o = darts[i]
      o.trans = btTransform(btQuaternion(btVector3(0, 1, 0), u.psi), P(u.x, u.y, 2))
    end
    local cx, cy = 0, 0
    for _, tg in ipairs(w.targets) do cx, cy = cx + tg.x / #w.targets, cy + tg.y / #w.targets end
    local d2 = 0
    for _, u in ipairs(w.uavs) do d2 = d2 + (u.x - cx) ^ 2 + (u.y - cy) ^ 2 end
    status.show({ opts.title, status.num("t", w.t, 0, false, 6),
      status.pct("over", acc.n > 0 and 100 * acc.inside / acc.n or 0, 1),
      status.num("|Omega|", acc.n > 0 and acc.om / acc.n or 0, 3, false),
      status.num("spread", math.sqrt(d2 / #w.uavs), 0, false, 6),
      status.num("minSep", acc.minSep < math.huge and acc.minSep or 0, 1, false, 7) })
  end

  function setup()
    clearAll()
    w = opts.build()
    for i = 1, #w.uavs do
      local o = quiet(Cube(DART, 1.5, DART / 3, 0))
      o.col = COLS[(i - 1) % #COLS + 1]
      v:add(o)
      darts[i] = o
    end
    for _, tg in ipairs(w.targets) do
      local o = quiet(Sphere(3, 0)); o.col = "#ff3030"; o.pos = P(tg.x, tg.y, 0); v:add(o)
      tobjs[#tobjs + 1] = o
    end
    local o = quiet(Cube(U.RECT.w, 0.2, U.RECT.h, 0)); o.col = "#402020"; o.pos = P(0, 0, -1); v:add(o)
    tobjs[#tobjs + 1] = o
    draw()
    print("setup: " .. opts.title)
  end

  v:onParamChanged(function(N, name, value)
    if name ~= "ticksPerFrame" and w then setup() end
  end)
  v:addShortcut("R", function() setup() end)
  v:postSim(function(N)
    if not w then return end
    for _ = 1, math.max(1, math.floor(v:getParam("ticksPerFrame"))) do
      U.step(w)
      ticks = ticks + 1
      for i, u in ipairs(w.uavs) do
        acc.n = acc.n + 1
        if math.abs(u.x) <= U.RECT.w / 2 and math.abs(u.y) <= U.RECT.h / 2 then acc.inside = acc.inside + 1 end
        acc.om = acc.om + math.abs(u.omega)
        for j = i + 1, #w.uavs do
          local o = w.uavs[j]
          acc.minSep = math.min(acc.minSep, math.sqrt((u.x - o.x) ^ 2 + (u.y - o.y) ^ 2))
        end
        if ticks % (TRAIL_EVERY * FW.HZ) == 0 then
          local dot = trail[nextDot]
          if not dot then
            dot = { obj = quiet(Sphere(1.5, 0)) }
            v:add(dot.obj)
            trail[nextDot] = dot
          end
          dot.obj.col = COLS[(i - 1) % #COLS + 1]
          dot.obj.pos = P(u.x, u.y, 0)
          nextDot = nextDot % (TRAIL * #w.uavs) + 1
        end
      end
    end
    draw()
  end)
  common.setCamera(btVector3(0, opts.camHeight or 1100, 0), btVector3(0, 0, 0), nil, { up = btVector3(0, 0, -1) })
  pcall(function() v:setHelpText(opts.help or opts.title) end)
  setup()
end

return S
