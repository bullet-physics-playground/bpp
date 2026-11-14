-- Bullet's default constructors leave btQuaternion, btVector3, btMatrix3x3
-- and btTransform uninitialised. In a script, btQuaternion() and friends
-- mean "no rotation" / "zero", so bpp gives them those values: identity
-- quaternion, zero vector, identity matrix, identity transform. (Scripts
-- that used them as such got whatever was in memory, sometimes NaN.)

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": " .. tostring(detail))
    fail = fail + 1
  end
end

-- Leave freed memory full of non-zero values, for the objects below to
-- be made in.
local junk = {}
for i = 1, 2000 do
  junk[#junk + 1] = btQuaternion(0.3, -7, 11, 13)
  junk[#junk + 1] = btVector3(5, -9, 17)
  junk[#junk + 1] = btMatrix3x3(2, 3, 4, 5, 6, 7, 8, 9, 10)
  junk[#junk + 1] = btTransform(btQuaternion(0.3, -7, 11, 13), btVector3(5, -9, 17))
end
junk = nil
collectgarbage("collect")
collectgarbage("collect")

local function quatIsIdentity(q)
  return q:x() == 0 and q:y() == 0 and q:z() == 0 and q:w() == 1
end

local function vecIsZero(v)
  return v.x == 0 and v.y == 0 and v.z == 0
end

local function matIsIdentity(m)
  for r = 0, 2 do
    local row = m:getRow(r)
    for c = 0, 2 do
      local want = (r == c) and 1 or 0
      if ({row.x, row.y, row.z})[c + 1] ~= want then return false end
    end
  end
  return true
end

local identity = btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0))
local q, vz, m, t = true, true, true, true
for i = 1, 50 do
  q = q and quatIsIdentity(btQuaternion())
  vz = vz and vecIsZero(btVector3())
  m = m and matIsIdentity(btMatrix3x3())
  t = t and (btTransform() == identity)
end
check("btQuaternion() is the identity rotation", q)
check("btVector3() is zero", vz)
check("btMatrix3x3() is the identity matrix", m)
check("btTransform() is the identity transform", t)

-- The constructors with arguments are unchanged.
local q2 = btQuaternion(btVector3(0, 1, 0), 0.5)
check("btQuaternion(axis, angle)", math.abs(q2:y() - math.sin(0.25)) < 1e-6
      and math.abs(q2:w() - math.cos(0.25)) < 1e-6, q2)
local q4 = btQuaternion(0, 0, 0.6, 0.8)
check("btQuaternion(x, y, z, w)", q4:z() == btQuaternion(0, 0, 0.6, 0.8):z() and math.abs(q4:w() - 0.8) < 1e-6, q4)
local v3 = btVector3(1, 2, 3)
check("btVector3(x, y, z)", v3.x == 1 and v3.y == 2 and v3.z == 3, v3)
local m9 = btMatrix3x3(1, 2, 3, 4, 5, 6, 7, 8, 9)
check("btMatrix3x3(9 values)", m9:getRow(1).y == 5, m9:getRow(1).y)
local tr = btTransform(btQuaternion(0, 0, 0, 1), btVector3(1, 2, 3))
local back = tr:invXform(btVector3(1, 2, 3))
check("btTransform(q, origin)", vecIsZero(back), back)

-- They are still the classes: a script can test and extend them.
check("btQuaternion is still the class", class_info(btQuaternion).name == "btQuaternion")

-- An empty joystick report says what it holds (it printed "JoystickInfo()").
check("JoystickInfo() prints its axes and buttons",
      tostring(JoystickInfo()) == "JoystickInfo(axes={}, buttons={})", tostring(JoystickInfo()))

print(string.format("\n%d passed, %d failed", pass, fail))
