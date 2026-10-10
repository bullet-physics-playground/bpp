-- test btQuaternion()
--
-- Bullet's btQuaternion() leaves its components uninitialised. A script that
-- writes btTransform(btQuaternion(), pos) means "no rotation", and a garbage
-- quaternion turns into a NaN matrix (getOpenGLMatrix divides by its squared
-- length), which the POV-Ray export then writes out as "matrix <nan,nan,...".
-- So btQuaternion() from Lua is the identity: (0, 0, 0, 1).

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    io.stderr:write("PASS " .. name .. "\n")
    pass = pass + 1
  else
    io.stderr:write("FAIL " .. name .. (detail and (": " .. detail) or "") .. "\n")
    fail = fail + 1
  end
end

local function near(a, b) return math.abs(a - b) < 1e-6 end

local function xyzw(q) return q:getX(), q:getY(), q:getZ(), q:getW() end

-- leave junk in the heap blocks that the next quaternions are likely to reuse
local function dirty_heap()
  for i = 1, 200 do
    local q = btQuaternion(5, 6, 7, 8)
    q:setValue(9, 9, 9, 9)
  end
  collectgarbage("collect")
  collectgarbage("collect")
end

local bad
for i = 1, 100 do
  dirty_heap()
  local x, y, z, w = xyzw(btQuaternion())
  if x ~= 0 or y ~= 0 or z ~= 0 or w ~= 1 then
    bad = string.format("%g %g %g %g", x, y, z, w)
    break
  end
end
check("btQuaternion() is the identity, also on recycled memory", not bad, bad)

-- the other constructors are unchanged
local x, y, z, w = xyzw(btQuaternion(1, 2, 3, 4))
check("btQuaternion(x, y, z, w) keeps its components",
      x == 1 and y == 2 and z == 3 and w == 4, string.format("%g %g %g %g", x, y, z, w))

local q = btQuaternion(btVector3(0, 1, 0), math.pi / 2)
check("btQuaternion(axis, angle) rotates by the angle about the axis",
      near(q:getAngle(), math.pi / 2) and near(q:getAxis():getY(), 1),
      string.format("angle %g axis y %g", q:getAngle(), q:getAxis():getY()))

check("btQuaternion(yaw, pitch, roll) is a unit quaternion",
      near(btQuaternion(0.3, 0.2, 0.1):length(), 1))

-- it works where a btQuaternion is expected, and does not disturb anything
local e = btQuaternion()
local p = e * btQuaternion(btVector3(1, 0, 0), 0.5)
check("identity * q == q", near(p:getAngle(), 0.5))

local c = Cube(1, 1, 1, 1)
c.trans = btTransform(btQuaternion(), btVector3(1, 2, 3))
v:add(c)
local r = c.trans:getRotation()
check("btTransform(btQuaternion(), pos) is an unrotated transform at pos",
      near(r:getW(), 1) and near(c.pos.x, 1) and near(c.pos.y, 2) and near(c.pos.z, 3),
      string.format("w %g pos %g %g %g", r:getW(), c.pos.x, c.pos.y, c.pos.z))

print(string.format("\n%d passed, %d failed", pass, fail))
