#!/usr/bin/bpp -f
-- What bpp sets up before a script runs (Viewer::parse): a "#!" first line,
-- for scripts run as programs, is dropped (otherwise the line above is a
-- syntax error); require finds the shipped modules by their bare names
-- (the nearest module/ folder up from the script: demo/module/ for tests/,
-- so require "color" rather than "module/color"); the helpers it
-- adds (printf, math.atan2 and atan2) are there; and the collector, which
-- bpp keeps running, ignores collectgarbage("stop") and says so in
-- BPP_GC_AUTO.

local pass = 0
local fail = 0

local function check(name, ok)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name)
    fail = fail + 1
  end
end

check("the #! line was dropped", true)

local ok, color = pcall(require, "color")
check("require finds a shipped module by its bare name", ok and type(color) == "table" and color.red == "#ff0000")

check("printf", type(printf) == "function")
check("math.atan2", type(math.atan2) == "function" and math.abs(math.atan2(1, 1) - math.pi / 4) < 1e-12)
check("atan2", atan2 == math.atan2)

check("BPP_GC_AUTO", BPP_GC_AUTO == true)
-- after a "stop", garbage is still collected as it's made: 400,000 small
-- tables (some 25 MB) leave memory far below what a stopped collector would
local before = collectgarbage("count")
collectgarbage("stop")
for i = 1, 400000 do local t = { i, i, i } end
local grown = collectgarbage("count") - before
check(string.format("collectgarbage('stop') is ignored (grew %d KB)", grown), grown < 8192)
collectgarbage("collect")
check("collectgarbage('collect') still works", collectgarbage("count") <= before + 64)

print(string.format("\n%d passed, %d failed", pass, fail))
