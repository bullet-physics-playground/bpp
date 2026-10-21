#!/bin/bash
# check-lua52.sh -- William's bpp runs Lua 5.2; a cloud workspace's often
# 5.1, where 5.2-only mistakes don't show. This loads exhibit-table.lua the
# way an exhibit in the hall does (in a sandbox, with stand-ins for bpp's
# objects) under the standalone lua5.2 and checks it builds in the exhibit's
# own environment. Needs lua5.2 (apt-get install lua5.2).
H=$(cd "$(dirname "$0")/.." && pwd)
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT
mkdir -p "$D/exhibits/X"; cp "$H/exhibit-table.lua" "$D/"
# an exhibit's loader, copied from the Pascaline
awk '/^local TABLE$/,/^end$/' "$H/exhibits/Pascaline/pascaline.lua" > "$D/exhibits/X/exhibit.lua"
cat >> "$D/exhibits/X/exhibit.lua" <<'LUA'
local top, TW, TD = TABLE.build(46, 11, { x = -1, z = 0.7 })
RESULT = string.format("table %d x %d, its plane made by %s", TW, TD, PLANE_MAKER)
LUA
sed -i '1i local DIR = DIR_FROM_HALL' "$D/exhibits/X/exhibit.lua"
cat > "$D/hall-sim.lua" <<'LUA'
local function obj() return {} end
btVector3 = function(x, y, z) return { x = x, y = y, z = z } end
Cube = obj
Plane = function() PLANE_MAKER = "the GLOBAL Plane"; return obj() end
v = { add = function() end }
local env = setmetatable({ DIR_FROM_HALL = arg[1] .. "/exhibits/X/" }, { __index = _G })
env.Plane = function() env.PLANE_MAKER = "the exhibit's own Plane"; return obj() end
local f
if setfenv then f = assert(loadfile(arg[1] .. "/exhibits/X/exhibit.lua")); setfenv(f, env)
else f = assert(loadfile(arg[1] .. "/exhibits/X/exhibit.lua", "t", env)) end
f()
local ok = env.PLANE_MAKER == "the exhibit's own Plane" and rawget(env, "EXHIBIT_TABLE") ~= nil and rawget(_G, "EXHIBIT_TABLE") == nil
print(_VERSION .. ": " .. tostring(env.RESULT) .. (ok and " -- right" or " -- WRONG: it ran in the global environment"))
os.exit(ok and 0 or 1)
LUA
lua5.2 "$D/hall-sim.lua" "$D"
