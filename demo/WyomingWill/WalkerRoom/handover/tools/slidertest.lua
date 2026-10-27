-- The sliders' sliding pivot (O4: a block hinged to the body, slider-jointed to the bar). Test switches, applied
-- after the walker is built (set before dofile):
--   SL_6DOF = true      the block-bar slider joint replaced by a generic 6-dof joint (bar free only along its length)
--   SL_BAR_HALF = true  each slider bar (coupler) at half its mass
--   SL_NODAMP = true    every link's own damping off (the slider files damp bar, block, pendant; Chebyshev-Spears none)
-- (SOLVER_ITERATIONS is the room's own switch.) Measures, each frame from frame 120 on, for each slider linkage:
--   off   how far the block's centre is off the bar's line (cm)
--   twist the angle between block and bar (deg; the slider holds it at 0)
--   drift how far the block has moved in the body's frame from where it was built (cm; the O4 hinge holds it)
-- SLIDER <name>|off mean .. max ..|twist mean .. max ..|drift mean .. max ..|links damped: ..
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local cube = w.cube
local L = {}
for i = 1, 4 do local lk = w.parts and w.parts["linkage" .. i]; if lk and lk.sliderO4 then L[#L + 1] = lk end end
local damped = 0
for _, o in ipairs(w.bodies) do
  if not rawequal(o, cube) and w.madeBy[o] ~= "buildFoot" then
    local b = o.body
    if b:getLinearDamping() > 0 or b:getAngularDamping() > 0 then
      damped = damped + 1
      if SL_NODAMP then b:setDamping(0, 0) end
    end
  end
end
local home = {}
for _, lk in ipairs(L) do
  local pb = lk.block.body:getCenterOfMassPosition()
  home[lk] = cube.body:getCenterOfMassTransform():invXform(pb)
  if SL_BAR_HALF then lk.coupler.mass = lk.coupler.mass / 2 end
  if SL_6DOF then
    realv:removeConstraint(lk.sliderO4)
    local p = lk.coupler.body:getCenterOfMassTransform():invXform(pb)
    local id = btQuaternion(0, 0, 0, 1)
    local c = btGeneric6DofConstraint(lk.block.body, lk.coupler.body, btTransform(id, btVector3(0, 0, 0)), btTransform(id, p), true)
    c:setLinearLowerLimit(btVector3(1, 0, 0)); c:setLinearUpperLimit(btVector3(-1, 0, 0))   -- (lower above upper: free)
    c:setAngularLowerLimit(btVector3(0, 0, 0)); c:setAngularUpperLimit(btVector3(0, 0, 0))
    if SOLVER_ITERATIONS then c:setOverrideNumSolverIterations(SOLVER_ITERATIONS) end
    realv:addConstraint(c)
    lk.sliderO4 = c
  end
end
local S = { off = { 0, 0 }, twist = { 0, 0 }, drift = { 0, 0 } }; local n = 0
local function acc(k, x) S[k][1] = S[k][1] + x; if x > S[k][2] then S[k][2] = x end end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N == 3699 and #L == 0 then SLIDER_REPORT() end
  if N < 120 or #L == 0 then return end
  local Tcube = cube.body:getCenterOfMassTransform()
  for _, lk in ipairs(L) do
    local Tb, Tc = lk.block.body:getCenterOfMassTransform(), lk.coupler.body:getCenterOfMassTransform()
    local pb = lk.block.body:getCenterOfMassPosition()
    local q = Tc:invXform(pb); acc("off", math.sqrt(q.y * q.y + q.z * q.z))
    local d = math.abs(Tb:getRotation():dot(Tc:getRotation())); if d > 1 then d = 1 end
    acc("twist", math.deg(2 * math.acos(d)))
    local h = Tcube:invXform(pb); local hm = home[lk]
    acc("drift", math.sqrt((h.x - hm.x) ^ 2 + (h.y - hm.y) ^ 2 + (h.z - hm.z) ^ 2))
    n = n + 1
  end
  if N == 3699 then SLIDER_REPORT() end
end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
function SLIDER_REPORT()
  if n == 0 then print(string.format("SLIDER %s|no slider|links damped: %d", w.spec and w.spec.name or "?", damped)); return end
  print(string.format("SLIDER %s|off mean %.3f max %.3f|twist mean %.3f max %.3f|drift mean %.3f max %.3f|links damped: %d",
    w.spec and w.spec.name or "?", S.off[1] / n, S.off[2], S.twist[1] / n, S.twist[2], S.drift[1] / n, S.drift[2], damped))
end
