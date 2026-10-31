-- (30 October 2026; run: dofile("handover/tools/crank_torque_test.lua") from WalkerRoom) A crank (a bar, pivot at one end, as the walkers' cranks are) on a motor hinge to the world, its other end
-- pinned to the world: the motor pushes at its full set torque (stalled). What does torqueB read?
local FIXED = 1 / 3840
v.timeStep = 1 / 60; v.fixedTimeStep = FIXED; v.maxSubSteps = 64
v.gravity = btVector3(0, 0, 0)
v:setSolverInfo("iterations", 200)
local L = 10
local c = Cube(L, 1, 1, 1); c.pos = btVector3(0, 50, 0); v:add(c)
local h = btHingeConstraint(c.body, btVector3(-L / 2, 0, 0), btVector3(0, 0, 1))   -- the motor, at one end
local T = 1000
h:enableAngularMotor(true, 1e6, T * FIXED)
v:addConstraint(h)
h:enableForces()
local pin = btHingeConstraint(c.body, btVector3(L / 2, 0, 0), btVector3(0, 0, 1))                -- the far end held
v:addConstraint(pin)
v:postSim(function(N)
  if N == 30 then
    local F = h:forceB()
    print(string.format("CRANK set %.1f  torqueB.z %.1f  (about its centre)  torqueB.z + pivot moment %.1f  (about the pivot)  motorTorque %.1f",
      T, math.abs(h:torqueB().z), math.abs(h:torqueB().z + (L / 2) * F.y), math.abs(h:motorTorque())))   -- (pivot at -L/2 along x from the centre)
  end
end)
