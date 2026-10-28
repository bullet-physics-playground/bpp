-- One step on flat ground (a test): the test track flat (set TERRAIN="waves", AMP=0), and a static box STEP_H cm tall,
-- 60 cm long, 300 wide (across), its face STEP_GAP cm ahead of the walker's front-most foot as built. Friction 0.8 as
-- the ground. Under it: stallprobe (TRACK, STALL). Each frame: the front-most foot's height, the feet on top, the body x.
-- At the end:
--   STEP <name>|gap <cm>|h <cm>|first touch <s>|a front foot on top <s>|all four on top <s>|pushed back <cm>|body x end <cm>
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("/home/claude/work/stallprobe.lua")
v = realv
local w = room.walkers[1]
local H, GAP = STEP_H or 7, STEP_GAP or 10
local feet, mine = {}, {}
for _, o in ipairs(w.bodies) do mine[#mine + 1] = o; if w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
mine[#mine + 1] = w.cube
local front = -1e9
for _, f in ipairs(feet) do local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0); f.body:getAabb(lo, hi); front = math.max(front, hi.x) end
local face = front + GAP
STEP_FACE_X = face
local box = Cube(60, H, 300, 0)
box.pos = btVector3(face + 30, H / 2, getPosXYZ and select(3, getPosXYZ(w.cube)) or 0)
box.col = "#8a8378"; box.friction = 0.8
realv:add(box)
local x0 = w.cube.body:getCenterOfMassPosition().x
local touch, frontTop, allTop, maxx, push = nil, nil, nil, -1e9, 0
local function isMine(o) for _, q in ipairs(mine) do if rawequal(q, o) then return true end end end
realv:preSim(function(N) if hooks.preSim then hooks.preSim(N) end end)
realv:preDraw(function(N) if hooks.preDraw then hooks.preDraw(N) end end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local t = N / 60
  local bx = w.cube.body:getCenterOfMassPosition().x
  if not touch then
    realv:eachContact(function(a, b, x, y, z, nx, ny, nz, d)
      if (rawequal(a, box) or rawequal(b, box)) and (isMine(a) or isMine(b)) then touch = touch or t end
    end)
  end
  if touch then
    if bx > maxx then maxx = bx end
    if maxx - bx > push then push = maxx - bx end
  end
  local on = 0
  for _, f in ipairs(feet) do
    local p = f.body:getCenterOfMassPosition()
    if p.x > face + 1 and p.y > H - 0.5 then on = on + 1 end
  end
  if on >= 1 and not frontTop then frontTop = t end
  if on >= 4 and not allTop then allTop = t end
  if N == 3699 or N == (STEP_END or 61.6) * 60 then
    print(string.format("STEP %s|gap %.1f|h %.1f|first touch %s|a front foot on top %s|all four on top %s|pushed back %.1f|body x end %.1f",
      w.spec.name, GAP, H, touch and string.format("%.2f", touch) or "-", frontTop and string.format("%.2f", frontTop) or "-",
      allTop and string.format("%.2f", allTop) or "-", push, bx - x0))
  end
end)
