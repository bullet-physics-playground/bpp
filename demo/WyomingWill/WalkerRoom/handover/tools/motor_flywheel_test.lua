-- A free cube on a motor hinge, no gravity: does the motor give impulse / FIXED?
local FIXED = FIXED or 1 / 3840
v.timeStep = 1 / 60; v.fixedTimeStep = FIXED; v.maxSubSteps = math.ceil((1 / 60) / FIXED)
v.gravity = btVector3(0, 0, 0)
if SOLVER then v:setSolver(SOLVER) end
v:setSolverInfo("iterations", ITERS or 40)
local c = Cube(10, 10, 10, 1); c.pos = btVector3(0, 50, 0); v:add(c)
local h = btHingeConstraint(c.body, btVector3(0, 0, 0), btVector3(0, 0, 1))
local T = 1000
h:enableAngularMotor(true, 1e6, T * FIXED)
v:addConstraint(h)
h:enableForces()
local I = 1 * (10 * 10 + 10 * 10) / 12
v:postSim(function(N)
  if N == 60 then
    local w = c.body:getAngularVelocity()
    print(string.format("FLY FIXED=1/%d set %.1f  from spin %.1f  from feedback %.1f  (inertia %.2f, bullet's 1/I_z %.5f)",
      math.floor(1 / FIXED + 0.5), T, math.abs(w.z) * I, math.abs(h:torqueB().z) + math.abs(h:torqueA().z) * 0, I, c.body:getInvInertiaDiagLocal().z))
  end
end)
