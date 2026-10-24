-- What the outside braces touch: every contact of a buildOutsideCrossbar piece (as vibprobe.lua's CONTACTS, but
-- by which brace and piece, and for a foot, whose foot and how far it is tipped against the body). Prints
-- BRACEHIT lines (at most 40) and a BRACESUM line at frame CONTACT_AT. Base: BH_BASE (default stallprobe.lua).
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile(BH_BASE or "/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local T0 = w.cube.body:getCenterOfMassTransform()
local info = {}
for _, o in ipairs(w.bodies) do
  local k = w.madeBy[o]
  local p = T0:invXform(o.body:getCenterOfMassPosition())
  if k == "buildOutsideCrossbar" then
    info[o] = { kind = "brace", name = (p.y > -2 and "top" or "bottom") .. (math.abs(p.z) < 1 and " diag" or (" run z" .. (p.z > 0 and "+" or "-"))) }
  elseif k == "buildFoot" then
    info[o] = { kind = "foot", name = string.format("foot x%+.0f z%+.0f", p.x, p.z) }
  end
end
for _, o in ipairs(w.bodies) do if not info[o] then info[o] = { kind = w.madeBy[o] or "?", name = w.madeBy[o] or "?" } end end
info[w.cube] = { kind = "body", name = "body" }
for _, d in ipairs(w.decor or {}) do info[d.o] = { kind = "deco (look-only)", name = "deco (look-only)" } end
local function find(o) for q, i in pairs(info) do if rawequal(q, o) then return q, i end end end
local function tilt(f)   -- the foot's turn against the body, degrees
  local r = w.cube.body:getCenterOfMassTransform():inverseTimes(f.body:getCenterOfMassTransform()):getRotation()
  local wq = math.min(1, math.abs(r:w())); return math.deg(2 * math.acos(wq))
end
local count, shown, frames = {}, 0, 0
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  if N < 120 then return end
  frames = frames + 1
  local seen = {}
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d)
    if d > 0.01 then return end
    local qa, ia = find(a); local qb, ib = find(b)
    local br, other, qo
    if ia and ia.kind == "brace" then br, other, qo = ia, ib, qb elseif ib and ib.kind == "brace" then br, other, qo = ib, ia, qa end
    if not br then return end
    local what = other and other.name or "ground"
    local key = br.name .. " - " .. (other and other.kind or "ground")
    if not seen[key] then seen[key] = true; count[key] = (count[key] or 0) + 1 end
    if shown < (BH_SHOW or 40) and (not BH_ONLY or (other and other.kind or "ground") == BH_ONLY) then
      shown = shown + 1
      local p = w.cube.body:getCenterOfMassTransform():invXform(btVector3(x, y, z))
      print(string.format("BRACEHIT %d|%s|%s|at %.1f %.1f %.1f (body frame)%s", N, br.name, what, p.x, p.y, p.z,
        (other and other.kind == "foot") and string.format("|foot tipped %.0f deg", tilt(qo)) or ""))
    end
  end)
  if N == (CONTACT_AT or 3699) then
    local t = {}
    for k, n in pairs(count) do t[#t + 1] = string.format("%s %.1f%%", k, 100 * n / frames) end
    table.sort(t)
    print("BRACESUM " .. w.spec.name .. "|" .. (#t > 0 and table.concat(t, ", ") or "none"))
  end
end)
