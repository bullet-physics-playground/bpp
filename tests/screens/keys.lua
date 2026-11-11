--
-- Screenshot scene for tests/harness.py screens: the script's keys
-- (v:onKey, v:addShortcut). The harness clicks in the view (no drag, so the
-- camera stays) to give it the keyboard, then presses the keys below. Each
-- ball turns red when its key reaches the script:
--
--   1  X pressed (the hook takes it)     5  Ctrl+B, the shortcut
--   2  X released                        6  the left Shift (LShift)
--   3  S, which the hook takes           7  the right Shift (RShift)
--   4  D, which the hook lets through
--
-- S taken: the simulation keeps running (the green dot top right stays).
-- D let through: bpp's own D turns deactivation off (the yellow dot goes).
--
-- xdotool: mousemove --window WIN 500 400 click 1
-- xdotool: key x
-- xdotool: key s
-- xdotool: key d
-- xdotool: key ctrl+b
-- xdotool: key Shift_L
-- xdotool: key Shift_R
--
v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local balls = {}
for i = 1, 7 do
  local b = Sphere(1, 0)
  b.col = "#7f7f7f"
  b.pos = btVector3((i - 4) * 2.5, 1, 0)
  v:add(b)
  balls[i] = b
end

local function hit(i) balls[i].col = "#d62728" end

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 6, 16)
v.cam.look = btVector3(0, 1, 0)

v:onKey(function(N, key, down)
  if key == "X" then
    hit(down and 1 or 2)
    return true
  end
  if not down then return end
  if key == "S" then hit(3) return true end
  if key == "D" then hit(4) end              -- (not taken: bpp sees it too)
  if key == "LShift" then hit(6) end
  if key == "RShift" then hit(7) end
end)

v:addShortcut("Ctrl+B", function(N) hit(5) end)
