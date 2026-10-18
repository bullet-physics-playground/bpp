--
-- ch02/scene.lua -- drawing and running a ch02/models.lua model in BPP
--
-- Shared by Spring1D.lua, Spring2D.lua, Spring3D.lua and SolarSystem.lua.
-- The model's plane (x, y) is drawn as BPP (x, -z) with y up (lib/world.lua's
-- mapping), seen from above; with opts.threeD the model's z is drawn as BPP
-- y (up), seen from an angle. Each frame runs `stepsPerFrame` integrator
-- steps. BPP runs a scene as soon as it loads; S stops and restarts it.
--
-- DEFINITIONS (the status line; units are the NetLogo models' own, patches
-- and model time, with masses as set by the sliders):
--   t     model time: steps x Time_Step
--   sep   separation: distance between the two bodies
--   |P|   size of the total linear momentum, |sum of m v| over both bodies;
--         0 when the forces are equal and opposite and the start is at
--         rest overall (the book shows its components, Lmx and Lmy)
--   L     total angular momentum about the centre of mass,
--         sum of m (r x v), its component out of the plane; negative means
--         clockwise, as in the book
--   KE    kinetic energy, sum of m v^2 / 2
--   PE    potential energy of the pair: spring k (sep - D)^2 / 2; gravity
--         -G m1 m2 / sep (with a force cap, the potential that matches the
--         capped force, ch02/models.lua)
--   E     total energy KE + PE; with the book's integrator it swings a
--         little within each cycle but should not drift (FINDINGS F12)
-- With opts.threeD, L is a vector and the line shows instead:
--   |L|   its size
--   tilt  the angle in degrees between L now and L at the start; 0 means
--         the motion stays in the plane it started in
-- The red dot is the centre of mass; trails follow one body.
--

package.path = "../?.lua;" .. package.path
local common = require "common"
local ch = require "ch02.models"
local rng = require "lib.rng"
local status = require "lib.status"   -- label=value fields, fixed widths

local S = {}
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

local CF_STATIC, CF_NO_CONTACT = 1, 4
local function quiet(o)
  pcall(function() o.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end)
  return o
end

-- opts: build(params) -> model; title; camera height; trail (max dots, 0
-- for none); trailEvery (steps between dots); colors; radius(m);
-- springLine (draw the spring); live(name, value, model) -> true if the
-- change was applied without a reset.
function S.run(opts)
  common.setTiming(1 / 30, 1, 1 / 30)
  common.gravity(0)
  rng.init(v)

  local model, objs, springObj, comObj = nil, {}, nil, nil
  local trail, trailNext, steps = {}, 1, 0
  local t = 0

  local function P(x, y, h) return btVector3(x, h or 0, -y) end
  local function Z(p) return opts.threeD and (p.z or 0) or 0 end
  local L0 = nil

  local function clearAll()
    for _, o in ipairs(objs) do v:remove(o) end
    for _, o in ipairs(trail) do v:remove(o) end
    if springObj then v:remove(springObj); springObj = nil end
    objs, trail, trailNext = {}, {}, 1
  end

  local function draw()
    for i, p in ipairs(model.ps) do
      objs[i].pos = P(p.x or 0, p.y or 0, Z(p))
    end
    local m = ch.measure(model)
    comObj.pos = P(m.cx, m.cy, opts.threeD and m.cz or 0.2)
    if opts.springLine then
      if springObj then v:remove(springObj) end
      local a, b = model.ps[1], model.ps[2]
      springObj = common.placeCylinder(P(a.x or 0, a.y or 0, Z(a)), P(b.x or 0, b.y or 0, Z(b)), 0.6, "#c8c8c8")
      if springObj then quiet(springObj) end
    end
    local Lfield
    if opts.threeD then
      L0 = L0 or m
      -- the angle from |L x L0| and L . L0 (exact near 0, unlike acos)
      local cx = m.ly * L0.lz - m.lz * L0.ly
      local cy = m.lz * L0.lx - m.lx * L0.lz
      local cz = m.lx * L0.ly - m.ly * L0.lx
      local dot = m.lx * L0.lx + m.ly * L0.ly + m.lz * L0.lz
      local tilt = math.deg(atan2(math.sqrt(cx * cx + cy * cy + cz * cz), dot))
      Lfield = status.num("|L|", m.l, 3, false) .. " | " .. status.num("tilt", tilt, 4, false, 8)
    else
      Lfield = status.num("L", m.lz, 3, true)
    end
    status.show({ opts.title,
      status.num("t", t, 2, false, 9), status.num("sep", m.sep, 3, false, 9),
      status.num("|P|", m.p, 3, false, 9), Lfield,
      status.num("KE", m.ke, 3, false), status.num("PE", m.pe, 3, true), status.num("E", m.e, 3, true) })
  end

  function setup()
    rng.reseed()
    clearAll()
    model = opts.build()
    t, L0 = 0, nil
    for i, p in ipairs(model.ps) do
      local o = quiet(Sphere(opts.radius(p.m or 1), 0))
      o.col = (opts.colors or {})[i] or "#ffffff"
      v:add(o)
      objs[i] = o
    end
    if not comObj then
      comObj = quiet(Sphere(0.8, 0)); comObj.col = "#ff2020"; v:add(comObj)
    end
    draw()
    print(string.format("setup: %s", opts.title))
  end

  v:onParamChanged(function(N, name, value)
    if rng.isSeedChange(name) then setup(); return end
    if model and opts.live and opts.live(name, value, model) then draw(); return end
    if model and opts.resetOn and opts.resetOn[name] then setup() end
  end)
  v:addShortcut("R", function() setup() end)

  v:postSim(function(N)
    if not model then return end
    local n = math.max(1, math.floor(v:getParam("stepsPerFrame")))
    for _ = 1, n do
      ch.step(model)
      t = t + model.dt
      steps = steps + 1
      if (opts.trail or 0) > 0 and steps % (opts.trailEvery or 10) == 0 then
        local p = model.ps[opts.trailOf or 2]
        local dot = trail[trailNext]
        if not dot then
          dot = quiet(Sphere(0.35, 0)); dot.col = "#7090ff"; v:add(dot)
          trail[trailNext] = dot
        end
        dot.pos = P(p.x or 0, p.y or 0, opts.threeD and (p.z or 0) or -0.3)
        trailNext = trailNext % opts.trail + 1
      end
    end
    draw()
  end)

  if opts.threeD then
    -- from the front, above and to one side, at the centre of mass (fixed,
    -- since |P| = 0)
    setup()
    local h, c = opts.camHeight or 150, ch.measure(model)
    local tx, ty, tz = c.cx, c.cz, -c.cy
    common.setCamera(btVector3(tx + 0.55 * h, ty + 0.45 * h, tz + 0.75 * h), btVector3(tx, ty, tz))
  else
    -- straight down, with the model's +y at the top of the screen
    common.setCamera(btVector3(opts.cx or 0, opts.camHeight or 150, -(opts.cy or 0)),
                     btVector3(opts.cx or 0, 0, -(opts.cy or 0)), nil, { up = btVector3(0, 0, -1) })
  end
  pcall(function() v:setHelpText(opts.help or opts.title) end)
  if not opts.threeD then setup() end
  return function() return model end
end

return S
