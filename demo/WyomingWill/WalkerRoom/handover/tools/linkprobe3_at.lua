-- Test track: how often the walker's own parts touch each other (not via a
-- joint), and with how much impulse. env AMP BUMP
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("test-track.lua")
v = realv
local w = room.walkers[1]
local mine = {}
for _, o in ipairs(w.bodies) do mine[o] = w.madeBy[o] or "?" end
local deco = {}
for _, d in ipairs(w.decor or {}) do deco[#deco + 1] = d.o end
local function isDeco(o) for _, q in ipairs(deco) do if rawequal(q, o) then return true end end return false end
local frames, touch, imp, pairs_ = 0, 0, 0, {}
local bodyHits = 0
local hx0, hx1 = 1e9, -1e9
local nearEnd = 0
realv:preSim(function(N) hooks.preSim(N) end)
realv:postSim(function(N)
  hooks.postSim(N)
  if N < 120 then return end
  frames = frames + 1
  local any, bg = false, false
  realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d, im)
    local ka, kb
    for o, k in pairs(mine) do if rawequal(o, a) then ka = k end; if rawequal(o, b) then kb = k end end
    if (rawequal(a, w.cube) and not kb and not isDeco(b)) or (rawequal(b, w.cube) and not ka and not isDeco(a)) then if d < 0.01 then bg = true
      local q = w.cube.body:getCenterOfMassTransform():invXform(btVector3(x, y, z)); hx0 = math.min(hx0, q.x); hx1 = math.max(hx1, q.x) end end
    if ka and kb and d < 0.01 then any = true; imp = imp + im; local key = ka < kb and (ka .. "-" .. kb) or (kb .. "-" .. ka); pairs_[key] = (pairs_[key] or 0) + 1 end
  end)
  if any then touch = touch + 1 end
  if bg then bodyHits = bodyHits + 1 end
  if N == (SELF_AT or 3600) then
    local t = {}
    for k, n in pairs(pairs_) do t[#t + 1] = k .. " " .. n end
    print(string.format("SELF %s|amp %s|touching %.1f%% of frames|impulse %.1f|%s|bodyground %.1f%%|hitx %.1f %.1f", w.spec.name, AMP, 100 * touch / frames, imp, table.concat(t, ", "), 100 * bodyHits / frames, hx0, hx1))
  end
end)
