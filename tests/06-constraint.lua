-- Test all btTypeConstraint derived classes bound with luabind

local pass = 0
local fail = 0

local function assert_eq(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local function assert_type(name, val, expected_type)
  if type(val) == expected_type then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got type=" .. type(val) .. " expected=" .. expected_type)
    fail = fail + 1
  end
end

local function assert_userdata(name, val)
  if type(val) == "userdata" then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got type=" .. type(val) .. " expected=userdata")
    fail = fail + 1
  end
end

local function assert_callable(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": " .. tostring(err))
    fail = fail + 1
  end
end

local function assert_gt(name, got, threshold)
  if got > threshold then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected > " .. tostring(threshold))
    fail = fail + 1
  end
end

-- ============================================================================
-- Section 1: btPoint2PointConstraint
-- ============================================================================

local p2p_base = Cube(2,1,2,1)
p2p_base.pos = btVector3(0, 0.5, 0)
p2p_base.col = "#444444"
v:add(p2p_base)

local p2p_slave = Cube(1,1,1,1)
p2p_slave.pos = btVector3(0, 2, 0)
p2p_slave.col = "#ff0000"
v:add(p2p_slave)

local pivotA = btVector3(0, 0.5, 0)
local pivotB = btVector3(0, -0.5, 0)

local p2p = btPoint2PointConstraint(p2p_base.body, p2p_slave.body, pivotA, pivotB)
assert_userdata("btPoint2PointConstraint created", p2p)

assert_callable("btPoint2PointConstraint added to world", function()
  v:addConstraint(p2p)
end)

p2p_base = nil
p2p_slave = nil
pivotA = nil
pivotB = nil
p2p = nil
collectgarbage("collect")

-- ============================================================================
-- Section 2: btHingeConstraint (two-body)
-- ============================================================================

local hinge_base = Cube(2,1,2,1)
hinge_base.pos = btVector3(10, 0.5, 0)
hinge_base.col = "#444444"
v:add(hinge_base)

local hinge_slave = Cube(1,1,1,1)
hinge_slave.pos = btVector3(10, 2, 0)
hinge_slave.col = "#00ff00"
v:add(hinge_slave)

local hinge_pivot = btVector3(0, 0.5, 0)
local hinge_axis = btVector3(0, 1, 0)
local hinge_ref = btVector3(1, 0, 0)

local hinge = btHingeConstraint(hinge_base.body, hinge_slave.body, hinge_pivot, hinge_axis, hinge_ref, hinge_ref)
assert_userdata("btHingeConstraint two-body created", hinge)

assert_callable("btHingeConstraint:setAxis", function()
  hinge:setAxis(btVector3(0, 1, 0))
end)

assert_callable("btHingeConstraint:setLimit", function()
  hinge:setLimit(-math.pi / 4, math.pi / 4, 0.9, 0.3, 1)
end)

assert_callable("btHingeConstraint:enableAngularMotor", function()
  hinge:enableAngularMotor(true, 2, 10)
end)

assert_callable("btHingeConstraint added to world", function()
  v:addConstraint(hinge)
end)

hinge_base = nil
hinge_slave = nil
hinge_pivot = nil
hinge_axis = nil
hinge_ref = nil
hinge = nil
collectgarbage("collect")

-- ============================================================================
-- Section 3: btHingeConstraint (single-body)
-- ============================================================================

local hinge1_base = Cube(2,1,2,1)
hinge1_base.pos = btVector3(20, 0.5, 0)
hinge1_base.col = "#444444"
v:add(hinge1_base)

local hinge1_axis = btVector3(0, 1, 0)
local hinge1_ref = btVector3(1, 0, 0)

local hinge1 = btHingeConstraint(hinge1_base.body, hinge1_axis, hinge1_ref)
assert_userdata("btHingeConstraint single-body created", hinge1)

assert_callable("btHingeConstraint single:setLimit", function()
  hinge1:setLimit(-math.pi / 2, math.pi / 2, 0.9, 0.3, 1)
end)

assert_callable("btHingeConstraint single-body added to world", function()
  v:addConstraint(hinge1)
end)

hinge1_base = nil
hinge1_axis = nil
hinge1_ref = nil
hinge1 = nil
collectgarbage("collect")

-- ============================================================================
-- Section 4: btConeTwistConstraint
-- ============================================================================

local ct_base = Cube(2,1,2,1)
ct_base.pos = btVector3(30, 0.5, 0)
ct_base.col = "#444444"
v:add(ct_base)

local ct_slave = Cube(1,1,1,1)
ct_slave.pos = btVector3(30, 2, 0)
ct_slave.col = "#0000ff"
v:add(ct_slave)

local ct_frameA = btTransform()
ct_frameA:setIdentity()
ct_frameA:setOrigin(btVector3(0, 0.5, 0))

local ct_frameB = btTransform()
ct_frameB:setIdentity()
ct_frameB:setOrigin(btVector3(0, -0.5, 0))

local ct = btConeTwistConstraint(ct_base.body, ct_slave.body, ct_frameA, ct_frameB)
assert_userdata("btConeTwistConstraint created", ct)

assert_callable("btConeTwistConstraint:setLimit(3,value)", function()
  ct:setLimit(3, math.pi * 0.8)
end)

assert_callable("btConeTwistConstraint:setLimit(4,value)", function()
  ct:setLimit(4, math.pi * 0.25)
end)

assert_callable("btConeTwistConstraint:setLimit(5,value)", function()
  ct:setLimit(5, math.pi * 0.8)
end)

assert_eq("btConeTwistConstraint:getLimit(3)", math.abs(ct:getLimit(3) - math.pi * 0.8) < 1e-6, true)
assert_eq("btConeTwistConstraint:getLimit(4)", math.abs(ct:getLimit(4) - math.pi * 0.25) < 1e-6, true)
assert_eq("btConeTwistConstraint:getLimit(5)", math.abs(ct:getLimit(5) - math.pi * 0.8) < 1e-6, true)
assert_eq("btConeTwistConstraint:isMotorEnabled before", ct:isMotorEnabled(), false)

assert_callable("btConeTwistConstraint:enableMotor", function()
  ct:enableMotor(true)
end)

assert_eq("btConeTwistConstraint:isMotorEnabled after", ct:isMotorEnabled(), true)

assert_callable("btConeTwistConstraint:setMotorTarget", function()
  ct:setMotorTarget(btQuaternion(0, 0, 0, 1))
end)

assert_callable("btConeTwistConstraint:setMaxMotorImpulse", function()
  ct:setMaxMotorImpulse(10)
end)

assert_callable("btConeTwistConstraint added to world", function()
  v:addConstraint(ct)
end)

ct_base = nil
ct_slave = nil
ct_frameA = nil
ct_frameB = nil
ct = nil
collectgarbage("collect")

-- ============================================================================
-- Section 5: btSliderConstraint
-- ============================================================================

local slider_base = Cube(3,0.5,2,1)
slider_base.pos = btVector3(40, 0.5, 0)
slider_base.col = "#444444"
v:add(slider_base)

local slider_slide = Cube(2,0.5,2,1)
slider_slide.pos = btVector3(40, 1, 0)
slider_slide.col = "#ff6600"
v:add(slider_slide)

local slider_frameA = btTransform()
slider_frameA:setIdentity()
slider_frameA:setOrigin(btVector3(0, 0.5, 0))

local slider_frameB = btTransform()
slider_frameB:setIdentity()
slider_frameB:setOrigin(btVector3(0, -0.25, 0))

local slider = btSliderConstraint(slider_base.body, slider_slide.body, slider_frameA, slider_frameB, true)
assert_userdata("btSliderConstraint created", slider)

assert_callable("btSliderConstraint:setLowerLinLimit", function()
  slider:setLowerLinLimit(-2)
  slider:setUpperLinLimit(2)
end)

assert_callable("btSliderConstraint:setPoweredLinMotor", function()
  slider:setPoweredLinMotor(true)
end)

assert_callable("btSliderConstraint:setTargetLinMotorVelocity", function()
  slider:setTargetLinMotorVelocity(5)
end)

assert_callable("btSliderConstraint:setMaxLinMotorForce", function()
  slider:setMaxLinMotorForce(100)
end)

assert_callable("btSliderConstraint:setPoweredAngMotor", function()
  slider:setPoweredAngMotor(true)
end)

assert_callable("btSliderConstraint:setTargetAngMotorVelocity", function()
  slider:setTargetAngMotorVelocity(2)
end)

assert_callable("btSliderConstraint:setMaxAngMotorForce", function()
  slider:setMaxAngMotorForce(50)
end)

assert_callable("btSliderConstraint added to world", function()
  v:addConstraint(slider)
end)

slider_base = nil
slider_slide = nil
slider_frameA = nil
slider_frameB = nil
slider = nil
collectgarbage("collect")

-- ============================================================================
-- Section 6: btGeneric6DofConstraint
-- ============================================================================

local g6d_base = Cube(2,1,2,1)
g6d_base.pos = btVector3(50, 0.5, 0)
g6d_base.col = "#444444"
v:add(g6d_base)

local g6d_slave = Cube(1,1,1,1)
g6d_slave.pos = btVector3(50, 2, 0)
g6d_slave.col = "#ffff00"
v:add(g6d_slave)

local g6d_frameA = btTransform()
g6d_frameA:setIdentity()
g6d_frameA:setOrigin(btVector3(0, 0.5, 0))

local g6d_frameB = btTransform()
g6d_frameB:setIdentity()
g6d_frameB:setOrigin(btVector3(0, -0.5, 0))

local g6d = btGeneric6DofConstraint(g6d_base.body, g6d_slave.body, g6d_frameA, g6d_frameB, true)
assert_userdata("btGeneric6DofConstraint created", g6d)

assert_callable("btGeneric6DofConstraint:setLinearLowerLimit", function()
  g6d:setLinearLowerLimit(btVector3(-1, -1, -1))
end)

assert_callable("btGeneric6DofConstraint:setLinearUpperLimit", function()
  g6d:setLinearUpperLimit(btVector3(1, 1, 1))
end)

assert_callable("btGeneric6DofConstraint:setAngularLowerLimit", function()
  g6d:setAngularLowerLimit(btVector3(-math.pi/4, -math.pi/4, -math.pi/4))
end)

assert_callable("btGeneric6DofConstraint:setAngularUpperLimit", function()
  g6d:setAngularUpperLimit(btVector3(math.pi/4, math.pi/4, math.pi/4))
end)

assert_callable("btGeneric6DofConstraint:setLimit", function()
  g6d:setLimit(0, -1, 1)
end)

assert_callable("btGeneric6DofConstraint added to world", function()
  v:addConstraint(g6d)
end)

g6d_base = nil
g6d_slave = nil
g6d_frameA = nil
g6d_frameB = nil
g6d = nil
collectgarbage("collect")

-- ============================================================================
-- Section 7: btGeneric6DofSpringConstraint
-- ============================================================================

local spring_base = Cube(2,1,2,1)
spring_base.pos = btVector3(60, 0.5, 0)
spring_base.col = "#444444"
v:add(spring_base)

local spring_slave = Cube(1,1,1,1)
spring_slave.pos = btVector3(60, 2, 0)
spring_slave.col = "#ff00ff"
v:add(spring_slave)

local spring_frameA = btTransform()
spring_frameA:setIdentity()
spring_frameA:setOrigin(btVector3(0, 0.5, 0))

local spring_frameB = btTransform()
spring_frameB:setIdentity()
spring_frameB:setOrigin(btVector3(0, -0.5, 0))

local spring = btGeneric6DofSpringConstraint(spring_base.body, spring_slave.body, spring_frameA, spring_frameB, true)
assert_userdata("btGeneric6DofSpringConstraint created", spring)

assert_callable("btGeneric6DofSpringConstraint:setLinearLowerLimit", function()
  spring:setLinearLowerLimit(btVector3(-2, -2, -2))
end)

assert_callable("btGeneric6DofSpringConstraint:setLinearUpperLimit", function()
  spring:setLinearUpperLimit(btVector3(2, 2, 2))
end)

assert_callable("btGeneric6DofSpringConstraint:enableSpring", function()
  spring:enableSpring(0, true)
end)

assert_callable("btGeneric6DofSpringConstraint:setStiffness", function()
  spring:setStiffness(0, 50)
end)

assert_callable("btGeneric6DofSpringConstraint:setDamping", function()
  spring:setDamping(0, 5)
end)

assert_callable("btGeneric6DofSpringConstraint:setEquilibriumPoint()", function()
  spring:setEquilibriumPoint()
end)

assert_callable("btGeneric6DofSpringConstraint:setEquilibriumPoint(int)", function()
  spring:setEquilibriumPoint(0)
end)

assert_callable("btGeneric6DofSpringConstraint:setEquilibriumPoint(int,btScalar)", function()
  spring:setEquilibriumPoint(0, 0)
end)

assert_callable("btGeneric6DofSpringConstraint added to world", function()
  v:addConstraint(spring)
end)

spring_base = nil
spring_slave = nil
spring_frameA = nil
spring_frameB = nil
spring = nil
collectgarbage("collect")

-- ============================================================================
-- Section 8: btUniversalConstraint
-- ============================================================================

local univ_base = Cube(2,1,2,1)
univ_base.pos = btVector3(70, 0.5, 0)
univ_base.col = "#444444"
v:add(univ_base)

local univ_slave = Cube(1,1,1,1)
univ_slave.pos = btVector3(70, 2, 0)
univ_slave.col = "#00ffff"
v:add(univ_slave)

local univ_axis1 = btVector3(0, 1, 0)
local univ_axis2 = btVector3(1, 0, 0)
local univ_pivot = btVector3(0, 1, 0)

local univ = btUniversalConstraint(univ_base.body, univ_slave.body, univ_axis1, univ_axis2, univ_pivot)
assert_userdata("btUniversalConstraint created", univ)

assert_callable("btUniversalConstraint:setAxis", function()
  univ:setAxis(btVector3(0, 1, 0), btVector3(1, 0, 0))
end)

assert_callable("btUniversalConstraint added to world", function()
  v:addConstraint(univ)
end)

univ_base = nil
univ_slave = nil
univ_axis1 = nil
univ_axis2 = nil
univ_pivot = nil
univ = nil
collectgarbage("collect")

-- ============================================================================
-- Section 9: btGearConstraint
-- ============================================================================

local gear_a = Cube(2,1,2,1)
gear_a.pos = btVector3(80, 0.5, 0)
gear_a.col = "#444444"
v:add(gear_a)

local gear_b = Cube(2,1,2,1)
gear_b.pos = btVector3(82, 1.5, 0)
gear_b.col = "#ff8800"
v:add(gear_b)

local gear_axisA = btVector3(0, 0, 1)
local gear_axisB = btVector3(0, 0, 1)

local gear = btGearConstraint(gear_a.body, gear_b.body, gear_axisA, gear_axisB, 2)
assert_userdata("btGearConstraint created", gear)

assert_callable("btGearConstraint:setAxisA", function()
  gear:setAxisA(btVector3(0, 0, 1))
end)

assert_callable("btGearConstraint:setAxisB", function()
  gear:setAxisB(btVector3(0, 0, 1))
end)

assert_callable("btGearConstraint:setRatio", function()
  gear:setRatio(2)
end)

assert_callable("btGearConstraint added to world", function()
  v:addConstraint(gear)
end)

gear_a = nil
gear_b = nil
gear_axisA = nil
gear_axisB = nil
gear = nil
collectgarbage("collect")

-- ============================================================================
-- Summary
-- ============================================================================

print(string.format("\n%d passed, %d failed", pass, fail))