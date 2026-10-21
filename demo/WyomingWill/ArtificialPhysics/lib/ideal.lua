--
-- lib/ideal.lua -- the ideal vehicle: perfect tracking, i.e. the original
-- particle behind the vehicle interface (lib/swarm.lua; BOOK.md G18)
--
-- It goes exactly where AP sends it: given command(d, w, T) at time t0 it
-- moves along the straight line from where it is to w, arriving at
-- t0 + T, and stays there, so at every AP tick AP senses the position it
-- commanded and the formation is the original particle demo's. It has no
-- mass, no limits and no lag, and touches nothing (a sphere drawn at its
-- position, out of every collision group: particles in the originals
-- overlap freely). It deploys at once: placed at its starting height on
-- Setup, ready at the first step.
--
-- Use it as the reference that separates what AP does from what a vehicle
-- adds: any Formations-*-<vehicle>.lua scene runs on it with the
-- environment variable VEHICLE=lib.ideal (e.g. lib/batch.py ... --env
-- VEHICLE=lib.ideal). Quantities: d.px, d.py, d.pz (m) and d.vx, d.vy,
-- d.vz (m/s, the leg's velocity, 0 once there).
--
-- The 2D plane is at PLANE_Y; the 3D lattice is centred on it.
--

local V = {}

V.name   = "particle"
V.noun   = "particles"
V.moving = "moving"
V.can3D  = true
V.fragile = false
V.floorY = 0

local PLANE_Y = 12          -- m, as the drones' default altitude
local RADIUS = 0.2          -- m, drawn size only

function V.planeY() return PLANE_Y end

function V.new(x, z, toAlt)
  local o = Sphere(RADIUS, 0)
  o.col = "#ffffff"
  o.collides = false
  o.pos = btVector3(x, toAlt, z)
  v:add(o)
  return { obj = o, px = x, py = toAlt, pz = z, vx = 0, vy = 0, vz = 0,
           sx = x, sy = toAlt, sz = z, t0 = 0, trT = 0 }
end

function V.remove(d) v:remove(d.obj) end
function V.setColor(d, col) d.obj.col = col end
function V.sync(d) d.obj.pos = btVector3(d.px, d.py, d.pz) end

local function rest(d)
  d.wpx, d.wpy, d.wpz = d.px, d.py, d.pz
  d.sx, d.sy, d.sz, d.trT = d.px, d.py, d.pz, 0
  d.vx, d.vy, d.vz = 0, 0, 0
end

function V.join(d, simTime) rest(d) end
function V.hold(d) rest(d) end

function V.command(d, wx, wy, wz, T, simTime)
  d.wpx, d.wpy, d.wpz = wx, wy, wz
  d.sx, d.sy, d.sz = d.px, d.py, d.pz
  d.t0, d.trT = simTime, T
  d.vx, d.vy, d.vz = (wx - d.px) / T, (wy - d.py) / T, (wz - d.pz) / T
end

function V.guide(d, st, simTime, dt)
  if st == "takeoff" then
    d.ready = true
  elseif st == "ap" and d.trT > 0 then
    local u = simTime + dt - d.t0          -- where it is at the end of this step
    if u >= d.trT then
      d.px, d.py, d.pz = d.wpx, d.wpy, d.wpz
      d.vx, d.vy, d.vz, d.trT = 0, 0, 0, 0
    else
      d.px, d.py, d.pz = d.sx + d.vx * u, d.sy + d.vy * u, d.sz + d.vz * u
    end
  end
end

function V.step(d, dt) end

return V
