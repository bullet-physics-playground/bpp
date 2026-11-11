-- Errors from bpp's own functions (v:setSolver, v:setSolverInfo, v:attach;
-- v:setThreads has one only in the threaded build): each is a Lua error a
-- script can catch, with its message, and bpp carries on.
--
-- They used to be raised with luaL_error, which (Lua being built as C)
-- jumps straight out past luabind's C++ frames: the strings it had made
-- for the arguments were never freed (valgrind: "definitely lost"), and
-- skipping C++ destructors that way is undefined behaviour. The names
-- below are long on purpose, so that std::string keeps them on the heap.

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

-- The message is as luaL_error made it: where in the script, then what
-- (not wrapped by luabind as "std::runtime_error: '...'").
local function fails(name, f, expected)
  local ok, err = pcall(f)
  check(name .. " is an error", not ok, "no error")
  check(name .. " says why, and where", type(err) == "string" and
        err:find(":%d+: " .. expected:gsub("%p", "%%%0")) ~= nil and
        not err:find("std::", 1, true), err)
end

fails("setSolver with an unknown kind",
      function() v:setSolver("a-solver-kind-that-does-not-exist") end,
      "setSolver: unknown kind 'a-solver-kind-that-does-not-exist'")
fails("setSolverInfo with an unknown name",
      function() v:setSolverInfo("a-setting-that-does-not-exist", 1) end,
      "setSolverInfo: unknown 'a-setting-that-does-not-exist'")

local box = Cube(1, 1, 1, 1)
v:add(box)
fails("attach of an object that is no decoration",
      function() v:attach(box, box) end,
      "attach: only a decoration can follow another object")
local mark = Cube(0.2, 0.2, 0.2, 0)
mark.decoration = true
v:add(mark)
fails("attach of a decoration to itself",
      function() v:attach(mark, mark) end,
      "attach: an object can't follow itself")

-- And bpp carries on: the same functions work, and the scene runs.
v:setSolver("si")
check("setSolver works afterwards", v.solver == "si", v.solver)
v:setSolverInfo("iterations", 20)
v:attach(mark, box)
check("attach works afterwards", true)
for i = 1, 30 do v:stepSimulation(1 / 60, 1, 1 / 60) end
check("the scene runs afterwards", box.pos.y < 0, box.pos.y)

print(string.format("\n%d passed, %d failed", pass, fail))
