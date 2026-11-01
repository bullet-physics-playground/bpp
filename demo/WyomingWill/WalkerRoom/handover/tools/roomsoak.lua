-- A soak test of the room (November 2026): runs room-four.lua headless for SOAK_MINUTES simulated minutes (default
-- 180), pressing Tab every SOAK_TAB simulated seconds (default 20; Shift+Tab every third time) and moving to the next
-- ground (keys 1-4) every SOAK_GROUND simulated minutes (default 15). Each simulated minute it prints a SOAK line:
-- the minute, the wall time so far, the four walkers' names, and the lowest and highest body height; a body lost
-- (not a number, or more than 100 cm from the room's floor) prints SOAK LOST and stops. The window's keys follow
-- the third walker (F three times), so Tab swaps it.
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
v = P
dofile("room-four.lua")   -- (sets THREADS on, if THREADS is set)
v = realv
local t0 = realv:getTime()
local tabs, ground = 0, 1
local function key(N, k) hooks.onKey(N, k, true); hooks.onKey(N, k, false) end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if hooks.preDraw then hooks.preDraw(N) end   -- (the room's marks and steering, as in the window)
  if N == 60 then key(N, "F"); key(N, "F"); key(N, "F") end
  if N % 3600 == 0 then
    local lo, hi, names = math.huge, -math.huge, {}
    for _, w in ipairs(room.walkers) do
      local p = w.cube.body:getCenterOfMassPosition()
      if p.y ~= p.y or p.x ~= p.x or p.z ~= p.z or math.abs(p.y) > 100 then
        print(string.format("SOAK LOST minute %d: %s at %s %s %s", N / 3600, w.spec.name, p.x, p.y, p.z))
        os.exit(1)
      end
      lo, hi = math.min(lo, p.y), math.max(hi, p.y)
      names[#names + 1] = w.spec.name
    end
    print(string.format("SOAK minute %d  wall %.0f s  bodies %.1f-%.1f cm  %s", N / 3600, realv:getTime() - t0, lo, hi,
      table.concat(names, ", ")))
    if N / 3600 >= MIN then print("SOAK DONE"); os.exit(0) end
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
