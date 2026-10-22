--
-- tools/worldprint.lua -- a full print of a generated world, to show that
-- a change to the generator leaves its worlds exactly as they were
--
--   lua5.1 tools/worldprint.lua harbour-town 1 > a.txt     (any Lua 5.1-5.4)
--   ... change the generator ...
--   lua5.1 tools/worldprint.lua harbour-town 1 > b.txt && cmp a.txt b.txt
--
-- Prints, for one preset (lib/places.lua) and seed, every layer's output
-- -- the terrain's nodes (ground, water level, water kind), rivers, ponds
-- and dredged areas; the zone at every terrain node and the streets; the
-- lots, buildings, features, trees, hedges, pads and World pieces -- and
-- every triangle, colour and object that World:toBPP draws, through a
-- stand-in for BPP's drawing calls (so no BPP is needed). Numbers are
-- printed with 17 significant digits, so equal prints mean equal worlds.
-- Keys starting with "_" (caches) and the build times are left out; each
-- mesh's triangles are printed sorted, and -0 as 0. The
-- last line is the time each part took: generation, then drawing.
--
package.path = "./?.lua;" .. package.path
local name, seed = arg[1] or "harbour-town", tonumber(arg[2] or "1")

-- a stand-in for the BPP calls World:toBPP makes
local function emit(s) io.write(s, "\n") end   -- (written as it goes: a big world's print is GBs in memory)
local function num(x) if x == 0 then x = 0 end return string.format("%.17g", x) end   -- -0 as 0
local function vec(t) return num(t.x) .. "," .. num(t.y) .. "," .. num(t.z) end
local Obj = {}
Obj.__index = Obj
local function obj(kind, ...)
  local o = setmetatable({ kind = kind, args = { ... }, tris = {}, cols = {},
                           body = { setCollisionFlags = function() end } }, Obj)
  return o
end
function Obj:addTriangle(a, b, c) self.tris[#self.tris + 1] = vec(a) .. ";" .. vec(b) .. ";" .. vec(c) end
function Obj:setTriangleColor(i, r, g, b) self.cols[i + 1] = num(r) .. "," .. num(g) .. "," .. num(b) end
function Obj:build() end
_G.btVector3 = function(x, y, z) return { x = x, y = y, z = z } end
_G.btQuaternion = function(a, b, c, d)
  if type(a) == "table" then return { axis = a, angle = b } end
  return { x = a, y = b, z = c, w = d }
end
_G.btTransform = function(q, p) return { q = q, p = p } end
for _, k in ipairs({ "Terrain", "Cylinder", "Cube", "Triangle", "Plane", "Sphere", "Mesh" }) do
  _G[k] = function(...) return obj(k, ...) end
end
local drawn = {}
local viewer = { add = function(self, o) drawn[#drawn + 1] = o end }

-- every value, keys sorted, shared tables by number, functions left out
local seen, nSeen = {}, 0
local function dump(v, path)
  local t = type(v)
  if t == "number" then emit(path .. "=" .. num(v))
  elseif t == "string" or t == "boolean" then emit(path .. "=" .. tostring(v))
  elseif t == "table" then
    if seen[v] then emit(path .. "=@" .. seen[v]); return end
    nSeen = nSeen + 1; seen[v] = nSeen
    local ks = {}
    for k, val in pairs(v) do
      local ok = type(val) ~= "function" and type(val) ~= "userdata"
      if type(k) == "string" and (k:sub(1, 1) == "_" or k:match("^buildTime")) then ok = false end
      if ok then ks[#ks + 1] = k end
    end
    table.sort(ks, function(a, b)
      if type(a) == type(b) then return a < b end
      return type(a) == "number"
    end)
    for _, k in ipairs(ks) do dump(v[k], path .. "." .. tostring(k)) end
  end
end

local World, P = require "lib.world", require "lib.places"
local c0 = os.clock()
local w = P.build(World, name, { seed = seed })
local c1 = os.clock()
w:toBPP(viewer, { scale = 1 })
local c2 = os.clock()

local t = w.terrain
for k = 1, t.stride * (t.ny + 1) do
  emit(table.concat({ "node", k, num(t.h[k]), t.wl[k] and num(t.wl[k]) or "-", tostring(t.kind[k] or "-") }, " "))
end
for _, key in ipairs({ "rivers", "ponds", "dredged" }) do dump(t[key], "terrain." .. key) end
for k = 1, t.stride * (t.ny + 1) do
  local x, y = t:nodeXY(k)
  emit("zone " .. k .. " " .. tostring(w.town:zone(x, y)))
end
for _, key in ipairs({ "streets", "centres", "districts", "bulbs" }) do dump(w.town[key], "town." .. key) end
for _, key in ipairs({ "lots", "buildings", "trees", "hedges", "pads", "leak", "warehouses", "tunnels", "yard", "pieces", "notes" }) do
  dump(w[key], key)
end
for i, o in ipairs(drawn) do
  emit("drawn " .. i .. " " .. o.kind .. " tris " .. #o.tris)
  -- a mesh's triangles in sorted order: the order they were added in does
  -- not change the mesh (the woods' canopy is added in pairs() order)
  local lines = {}
  for j, tr in ipairs(o.tris) do lines[j] = "t " .. tr .. " " .. tostring(o.cols[j]) end
  table.sort(lines)
  for _, l in ipairs(lines) do emit(l) end
  local o2 = {}
  for k, val in pairs(o) do if k ~= "tris" and k ~= "cols" and k ~= "body" then o2[k] = val end end
  dump(o2, "drawn" .. i)
end
io.write(string.format("TIME generate %.2f s  draw %.2f s\n", c1 - c0, c2 - c1))
