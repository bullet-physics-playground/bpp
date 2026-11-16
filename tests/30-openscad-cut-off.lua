-- An OpenSCAD run cut off part way leaves nothing in the mesh cache. Before,
-- OpenSCAD wrote straight to <hash>.stl, so half a mesh stayed there and
-- every later run of the same source found it and failed to load it, even
-- with OpenSCAD working again. Here a stand-in OpenSCAD (set as the
-- preferences' openscad/executable, in this run's own user folder) first
-- writes half an STL and is killed, then a second one writes a whole one:
-- the second must be run and its mesh loaded. (A shell script: Linux and
-- macOS only.)

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. (detail and (": " .. detail) or ""))
    fail = fail + 1
  end
end

local dir = os.getenv("BPP_USER_DIR")
if dir == nil or dir == "" or package.config:sub(1, 1) ~= "/" then
  check("skipped (needs BPP_USER_DIR and a shell)", true)
  print(string.format("\n%d passed, %d failed", pass, fail))
  return
end

local function write(path, text)
  local f = assert(io.open(path, "w"))
  f:write(text)
  f:close()
end

-- a stand-in OpenSCAD: finds its -o, writes `body` there, then `last`
local function standIn(name, body, last)
  local path = dir .. "/" .. name
  write(path, "#!/bin/sh\nwhile [ $# -gt 0 ]; do [ \"$1\" = -o ] && out=$2; shift; done\n" ..
              "cat > \"$out\" <<'STL'\n" .. body .. "STL\n" .. last .. "\n")
  os.execute("chmod +x '" .. path .. "'")
  write(dir .. "/bpp.ini", "[openscad]\nexecutable=" .. path .. "\n")
end

local SRC = "cube(7); // tests/30-openscad-cut-off.lua"

standIn("cut-off.sh", "solid cut\n facet normal 0 0 1\n  outer loop\n   vertex 0 0 0\n", "kill -9 $$")
local ok = pcall(function() return OpenSCAD(SRC, 1) end)
check("cut off: no mesh", not ok)

standIn("whole.sh", [[solid whole
 facet normal 0 0 1
  outer loop
   vertex 0 0 0
   vertex 1 0 0
   vertex 0 1 0
  endloop
 endfacet
endsolid whole
]], "exit 0")
local ok2, m = pcall(function() return OpenSCAD(SRC, 0) end)
check("run again: the mesh loads", ok2, tostring(m))

-- and from the cache now: an OpenSCAD that only fails isn't needed
write(dir .. "/fails.sh", "#!/bin/sh\nexit 1\n")
os.execute("chmod +x '" .. dir .. "/fails.sh'")
write(dir .. "/bpp.ini", "[openscad]\nexecutable=" .. dir .. "/fails.sh\n")
local ok3, m3 = pcall(function() return OpenSCAD(SRC, 0) end)
check("then from the cache", ok3, tostring(m3))

print(string.format("\n%d passed, %d failed", pass, fail))
