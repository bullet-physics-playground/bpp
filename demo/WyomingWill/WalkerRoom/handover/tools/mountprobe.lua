-- Body half-length along the walk, and where each leg is mounted on it (x from the body centre).
package.path = "/home/claude/bpp/demo/module/?.lua;" .. package.path
local cons = {}
for _, n in ipairs({ "btHingeConstraint", "btSliderConstraint", "btGeneric6DofConstraint" }) do
  local f = _G[n]
  _G[n] = function(A, B, pA, pB, ...) local c = f(A, B, pA, pB, ...); cons[#cons + 1] = { A, B, n, pA, pB }; return c end
end
dofile("walker-room.lua")
local w = room.walkers[1]
local cb = w.cube.body
local lo, hi = btVector3(0,0,0), btVector3(0,0,0)
cb:getAabb(lo, hi)
local cp = cb:getCenterOfMassPosition()
local xs = {}
for _, c in ipairs(cons) do
  local A, B = c[1], c[2]
  local other, piv
  if B == cb and type(c[4]) == "userdata" then other, piv = A, c[4]
  elseif A == cb and type(B) == "userdata" and type(c[5]) == "userdata" then other, piv = B, c[5] end
  if other then
    local p = other:getCenterOfMassTransform():inverse():invXform(piv)
    xs[#xs + 1] = p.x - cp.x
  end
end
table.sort(xs)
local fh = io.open(os.getenv("MOUNT_OUT"), "a")
fh:write(string.format("%s|frame %.2f..%.2f|mounts %.2f..%.2f|n %d\n", w.spec.name, lo.x - cp.x + 0.04, hi.x - cp.x - 0.04, xs[1] or 0, xs[#xs] or 0, #xs))
fh:close()
