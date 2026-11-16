-- bpp's own Lua functions that take a pointer, given nil (a null pointer in
-- C++): a script's mistake must be an error or do nothing, never crash bpp.
-- Of these, three crashed: v:addVehicle(nil) (a null vehicle in the world,
-- which crashed the next step) and StatisticsVisitor/FindObjectVisitor
-- :Visiting(nil). The rest, each a pointer argument as tests/api lists them,
-- stay here so none starts to. (Adding the same vehicle twice broke the
-- script's handle, as adding a constraint twice did: 29-constraint-ownership.)

local cases = {
  {"Bound(nil)", function() return Bound(nil) end},
  {"Bound(nil, 1)", function() return Bound(nil, 1) end},
  {"CsgNode(nil)", function() return CsgNode(nil) end},
  {"CsgNode(0, nil, nil)", function() return CsgNode(0, nil, nil) end},
  {"CsgObject(nil)", function() local c = CsgObject(nil); v:add(c); return c end},
  {"CsgObject(nil, 1)", function() local c = CsgObject(nil, 1); v:add(c); return c end},
  {"CsgObject:setRoot(nil)", function() local c = CsgObject(CsgNode(Cube(1, 1, 1, 0))); c:setRoot(nil); v:add(c) end},
  {"CsgNode(0, node, nil) in object", function()
    local c = CsgObject(CsgNode(0, CsgNode(Cube(1, 1, 1, 0)), nil)); v:add(c) end},
  {"DemBed:attach(0, nil)", function() DemBed():attach(0, nil) end},
  {"DemBed:attachGlued(0, 0, nil)", function() DemBed():attachGlued(0, 0, nil) end},
  {"StatisticsVisitor:Visiting(nil)", function() return StatisticsVisitor():Visiting(nil) end},
  {"FindObjectVisitor:Visiting(nil)", function() return FindObjectVisitor("x"):Visiting(nil) end},
  {"LayerManager:assignObject(nil, nil)", function() LayerManager():assignObject(nil, nil) end},
  {"LayerManager:assignObject(cube, nil)", function() LayerManager():assignObject(Cube(1, 1, 1, 0), nil) end},
  {"LayerManager:moveLayer(nil, 0)", function() LayerManager():moveLayer(nil, 0) end},
  {"LayerManager:objectLayer(nil)", function() return LayerManager():objectLayer(nil) end},
  {"LayerManager:removeLayer(nil, nil)", function() LayerManager():removeLayer(nil, nil) end},
  {"LayerManager:removeObject(nil)", function() LayerManager():removeObject(nil) end},
  {"LayerManager:setActiveLayer(nil)", function() LayerManager():setActiveLayer(nil) end},
  {"PovScriptWriter:addObject(nil, '')", function() PovScriptWriter():addObject(nil, "") end},
  {"ReferenceObject('x', nil)", function() local r = ReferenceObject("x", nil); v:add(r); return r end},
  {"SoftBody:appendAnchor(0, nil)", function() SoftBody(1, 1):appendAnchor(0, nil) end},
  {"SoftBody:appendAnchor(0, nil, true)", function() SoftBody(1, 1):appendAnchor(0, nil, true) end},
  {"v:addVehicle(nil)", function() v:addVehicle(nil) end},
  {"v:attach(nil, nil)", function() v:attach(nil, nil) end},
  {"v:detach(nil)", function() v:detach(nil) end},
  {"v:setCam(nil)", function() v:setCam(nil) end},
  {"cube:addChild(nil)", function() Cube(1, 1, 1, 0):addChild(nil) end},
  {"cube:removeChild(nil)", function() Cube(1, 1, 1, 0):removeChild(nil) end},
  {"v:add(nil)", function() v:add(nil) end},
  {"v:remove(nil)", function() v:remove(nil) end},
  {"v:remove(never added)", function() v:remove(Cube(1, 1, 1, 0)) end},
  {"body:setMotionState(nil)", function() local c = Cube(1, 1, 1, 1); v:add(c); c.body:setMotionState(nil); local _ = c.pos end},
  {"obj.body = nil", function() local c = Cube(1, 1, 1, 1); c.body = nil; v:add(c) end},
  {"obj.shape = nil", function() local c = Cube(1, 1, 1, 1); c.shape = nil; v:add(c) end},
  {"obj.pos = nil", function() local c = Cube(1, 1, 1, 1); c.pos = nil end},
  {"obj.trans = nil", function() local c = Cube(1, 1, 1, 1); c.trans = nil end},
  {"obj.col = nil", function() local c = Cube(1, 1, 1, 1); c.col = nil end},
  {"btRaycastVehicle(tuning, nil, nil)", function() return btRaycastVehicle(btVehicleTuning(), nil, nil) end},
  {"btRigidBody(1, nil, nil, v3)", function() return btRigidBody(1, nil, nil, btVector3(0, 0, 0)) end},
  {"btHingeConstraint(nil, v3, v3)", function() return btHingeConstraint(nil, btVector3(0, 0, 0), btVector3(0, 0, 1)) end},
}


local pass = 0
local fail = 0
for _, c in ipairs(cases) do
  pcall(c[2])                         -- (an error or not: both fine)
  print("PASS " .. c[1])
  pass = pass + 1
end

-- the same vehicle added twice: the second does nothing, the handle stays good
local chassis = Cube(2, 1, 4, 10); chassis.pos = btVector3(20, 2, 0); v:add(chassis)
local veh = btRaycastVehicle(btVehicleTuning(), chassis.body, v:createVehicleRaycaster())
v:addVehicle(veh)
local ok, err = pcall(function() v:addVehicle(veh); veh:setCoordinateSystem(0, 1, 2) end)
if ok then print("PASS vehicle added twice"); pass = pass + 1
else print("FAIL vehicle added twice: " .. tostring(err)); fail = fail + 1 end
if not pcall(function() v:addVehicle(nil) end) then print("PASS addVehicle(nil) is an error"); pass = pass + 1
else print("FAIL addVehicle(nil) is no error"); fail = fail + 1 end

-- and the frames after: whatever went in must step
for _ = 1, 3 do v:stepSimulation(1 / 60, 1, 1 / 60) end
print("PASS stepped after")
pass = pass + 1

print(string.format("\n%d passed, %d failed", pass, fail))
