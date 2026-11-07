-- A soak test of the room (November 2026): runs room-four.lua headless for SOAK_MINUTES simulated minutes (default
-- 180), pressing Tab every SOAK_TAB simulated seconds (default 20; Shift+Tab every third time) and moving to the next
-- ground (keys 1-4) every SOAK_GROUND simulated minutes (default 15). Each simulated minute it prints a SOAK line:
-- the minute, the wall time so far, the four walkers' names, and the lowest and highest body height. Every 0.1
-- simulated s it checks each walker's body: past a wall (the arena's edge), more than 30 cm below the ground under
-- it, or not a number, it prints SOAK LOST, then the walker's last 5 s (a SOAKTRACE line every 0.1 s: its body's
-- place, the ground's height under it, its distance inside the walls, its speed and upward speed, how far its
-- farthest part is from its body, its fastest part's speed, how high its lowest part's centre is above the ground
-- under it, and how far inside the walls its part nearest a wall is; a part is named by its number in the walker and
-- what made it, as Foot or Crank; the look-only marks are left out), and stops. The window's keys follow the third
-- walker (F three times), so Tab swaps it. A run repeats exactly on one machine with any number of threads, not on
-- another machine (another compiler or C library changes the odd last digit, and over minutes the walk).
--
--   (in WalkerRoom) printf 'THREADS = 8\ndofile("handover/tools/roomsoak.lua")\n' > _soak.lua
--   QT_QPA_PLATFORM=offscreen bpp -f _soak.lua -n 99999999 2>&1 | grep -a SOAK
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
local MIN, TAB, GROUND = SOAK_MINUTES or 180, SOAK_TAB or 20, SOAK_GROUND or 15
local HALF_X, HALF_Z = (ARENA_X or ARENA or 1000) / 2, (ARENA_Z or ARENA or 1000) / 2   -- (as walker-room.lua)
-- (bpp's print holds its lines until Qt's buffer fills; these go out at once, each line, also into a file)
local function say(line) io.stdout:write(line, "\n"); io.stdout:flush() end
v = P
dofile("room-four.lua")   -- (sets THREADS on, if THREADS is set)
v = realv
local t0 = realv:getTime()
local tabs, ground = 0, 1
local function key(N, k) hooks.onKey(N, k, true); hooks.onKey(N, k, false) end
local past = setmetatable({}, { __mode = "k" })   -- each walker's last 5 s, every 0.1 s
local function look(N, w)
  local b = w.cube.body
  local p, u = b:getCenterOfMassPosition(), b:getLinearVelocity()
  local spread, fast, fastI = 0, 0, 0
  local low, lowI, near, nearI = math.huge, 0, math.huge, 0
  for i, o in ipairs(w.objects or {}) do
    if o.body and o.collides ~= false then   -- (not the look-only marks)
      local q, s = o.body:getCenterOfMassPosition(), o.body:getLinearVelocity()
      spread = math.max(spread, math.sqrt((q.x - p.x) ^ 2 + (q.y - p.y) ^ 2 + (q.z - p.z) ^ 2))
      local sp = math.sqrt(s.x ^ 2 + s.y ^ 2 + s.z ^ 2)
      if sp > fast then fast, fastI = sp, i end
      local above = q.y - room.groundAt(q.x, q.z)
      if above < low then low, lowI = above, i end
      local inn = math.min(HALF_X - math.abs(q.x), HALF_Z - math.abs(q.z))
      if inn < near then near, nearI = inn, i end
    end
  end
  local function part(i)
    local o = w.objects[i]
    if not o then return "-" end
    local by = rawequal(o, w.cube) and "body" or (w.madeBy and w.madeBy[o]) or "?"
    return string.format("#%d %s", i, (by:gsub("^build", "")))
  end
  local g = room.groundAt(p.x, p.z)
  local inside = math.min(HALF_X - math.abs(p.x), HALF_Z - math.abs(p.z))
  local line = string.format("SOAKTRACE %.1f s  body %.1f %.1f %.1f  ground %.1f  inside walls %.1f  speed %.1f (up %.1f)  parts within %.1f  fastest part %.1f %s  lowest part %.1f above ground %s  nearest the wall %.1f inside %s",
    N / 60, p.x, p.y, p.z, g, inside, math.sqrt(u.x ^ 2 + u.y ^ 2 + u.z ^ 2), u.y, spread, fast, part(fastI),
    low, part(lowI), near, part(nearI))
  local h = past[w] or {}
  past[w] = h
  h[#h + 1] = line
  if #h > 50 then table.remove(h, 1) end
  local why = (p.x ~= p.x or p.y ~= p.y or p.z ~= p.z) and "not a number" or inside < 0 and "past a wall"
    or p.y < g - 30 and "below the ground" or nil
  if why then
    say(string.format("SOAK LOST %.1f s (minute %.1f): %s, %s; its last 5 s:", N / 60, N / 3600, w.spec.name, why))
    for _, l in ipairs(h) do say(l) end
    os.exit(1)
  end
end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if hooks.preDraw then hooks.preDraw(N) end   -- (the room's marks and steering, as in the window)
  if N == 60 then key(N, "F"); key(N, "F"); key(N, "F") end
  if N > 60 and N % 6 == 0 then
    for _, w in ipairs(room.walkers) do look(N, w) end
  end
  if N % 3600 == 0 then
    local lo, hi, names = math.huge, -math.huge, {}
    for _, w in ipairs(room.walkers) do
      local p = w.cube.body:getCenterOfMassPosition()
      lo, hi = math.min(lo, p.y), math.max(hi, p.y)
      names[#names + 1] = w.spec.name
    end
    say(string.format("SOAK minute %d  wall %.0f s  bodies %.1f-%.1f cm  %s", N / 3600, realv:getTime() - t0, lo, hi,
      table.concat(names, ", ")))
    if N / 3600 >= MIN then say("SOAK DONE"); os.exit(0) end
  end
  if N > 60 and N % (60 * TAB) == 0 then
    tabs = tabs + 1
    key(N, tabs % 3 == 0 and "Backtab" or "Tab")
  end
  if N > 60 and N % (3600 * GROUND) == 0 then
    ground = ground % 4 + 1
    key(N, tostring(ground))   -- (the room built again; it keeps following the same place in the four)
  end
end)
