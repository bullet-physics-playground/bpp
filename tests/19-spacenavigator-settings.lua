-- The 3D mouse settings, set from a script (as demo/basic/README.md says
-- they can be). Each setter took Viewer's mutex, which bpp already holds
-- while a script runs, so the first assignment hung bpp for good.

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

for _, mode in ipairs({ 1, 0 }) do
  v.snMode = mode
  check("snMode = " .. mode, v.snMode == mode, v.snMode)
end
for _, name in ipairs({ "snLockHorizon", "snAutoFlySpeed", "snShowOrbitAxis", "snZoomForward", "snPanZoom" }) do
  local was = v[name]
  v[name] = not was
  check(name .. " turns over", v[name] == not was, v[name])
  v[name] = was
  check(name .. " turns back", v[name] == was, v[name])
end

print(string.format("\n%d passed, %d failed", pass, fail))
