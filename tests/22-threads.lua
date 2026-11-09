-- v:setThreads: the same scene, in worlds of its own, run without threads
-- and with four, must come out the same to the last digit -- with the
-- solver "si" and with "si-warm" (whose joint cache the threads share).
-- The scene has many islands for the threads to share out: stacks of boxes
-- that topple (contacts) and hanging chains that swing (joints).
--
-- Only the threaded build (qmake CONFIG+=bundled_bullet; THREADS.md) has
-- threads: in the default one setThreads returns 0, and this only checks
-- that.

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

local function finish()
  print(string.format("\n%d passed, %d failed", pass, fail))
end

local probe = v:newWorld()
v:useWorld(probe)
local n = v:setThreads(4)
v:setThreads(0)
v:useWorld(0)
if n == 0 then
  check("setThreads has no threads to give in this build (0)", n == 0, n)
  finish()
  return
end
check("setThreads gives up to four threads", n >= 2 and n <= 4, n)

-- One copy of the scene in the current world; returns its moving parts.
local function scene()
  local parts = {}
  local plane = Plane(0, 1, 0, 0, 100)
  v:add(plane)
  for s = 0, 5 do                              -- stacks, leaning to topple
    for k = 0, 3 do
      local o = Cube(1, 1, 1, 1)
      o.pos = btVector3(s * 4 - 10 + k * 0.32, 0.5 + k * 1.02, -4)
      v:add(o)
      parts[#parts + 1] = o
    end
  end
  for c = 0, 3 do                              -- chains, let go at an angle
    local anchor = Cube(0.3, 0.3, 0.3, 0)
    anchor.pos = btVector3(c * 4 - 6, 8, 4)
    v:add(anchor)
    local prev = anchor
    for k = 1, 5 do
      local link = Cube(0.2, 1, 0.2, 1)
      link.pos = btVector3(c * 4 - 6 + k * 0.7, 8 - k * 0.7, 4)
      v:add(link)
      v:addConstraint(btHingeConstraint(prev.body, link.body,
        btVector3(0, k == 1 and 0 or -0.5, 0), btVector3(0, 0.5, 0),
        btVector3(0, 0, 1), btVector3(0, 0, 1)))
      parts[#parts + 1] = link
      prev = link
    end
  end
  return parts
end

local function run(solver, threads)
  local w = v:newWorld()
  v:useWorld(w)
  v:setSolver(solver)
  local parts = scene()
  local start = {}
  for i, o in ipairs(parts) do start[i] = o.pos end
  v:setThreads(threads)
  for i = 1, 240 do v:stepSimulation(1 / 60, 1, 1 / 60) end
  v:setThreads(0)
  local got = {}
  for i, o in ipairs(parts) do
    local p, q = o.pos, o.trans:getRotation()
    got[i] = { p.x, p.y, p.z, q:x(), q:y(), q:z(), q:w() }
  end
  v:useWorld(0)
  -- how far the stacks' top boxes and the chains' last links went
  local tops, ends = 0, 0
  for i = 4, 24, 4 do tops = tops + (parts[i].pos - start[i]):length() end
  for i = 29, 44, 5 do ends = ends + (parts[i].pos - start[i]):length() end
  return got, tops, ends
end

local function same(a, b)
  for i = 1, #a do
    for j = 1, 7 do
      if a[i][j] ~= b[i][j] then
        return false, string.format("part %d, value %d: %.17g vs %.17g", i, j, a[i][j], b[i][j])
      end
    end
  end
  return #a == #b, "different numbers of parts"
end

for _, solver in ipairs({ "si", "si-warm" }) do
  local off, tops, ends = run(solver, 0)
  local on = run(solver, 4)
  check(solver .. ": the stacks topple", tops > 6, tops)
  check(solver .. ": the chains swing", ends > 4, ends)
  check(solver .. ": with four threads, the same to the last digit", same(off, on))
end

finish()
