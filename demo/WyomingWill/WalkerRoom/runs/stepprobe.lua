-- What the feet meet on the steps (13 November; handover section 4f, steps 7): runs/speedprobe.lua's run and RUN
-- line, and every second step a trace (to STEP_OUT/<name>_s<seed>.tsv, STEP_OUT a folder set in EXTRA): time, the
-- body's x, height and pitch, and for each foot its front edge's x, its bottom, its pitch, the ground under its
-- middle and the ground 1 cm past its front edge (the room walks toward +x).
local probeDir = STEP_OUT
local realv, speedPost = v, nil
v = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if k == "postSim" then return function(self, fn) speedPost = fn end end   -- (speedprobe's: run from ours)
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
dofile("runs/speedprobe.lua")
v = realv
local w = room.walkers[1]
local feet = {}
for _, o in ipairs(w.bodies) do if w.madeBy and w.madeBy[o] == "buildFoot" then feet[#feet + 1] = o end end
-- FEET_FRICTION (a test): the feet's friction times this (Bullet multiplies the two bodies' frictions)
if FEET_FRICTION then for _, f in ipairs(feet) do f.body:setFriction(f.body:getFriction() * FEET_FRICTION) end end
local fh = io.open(string.format("%s/%s_s%d.tsv", probeDir, w.spec.name:gsub(" ", "_"), SEED), "w")
local function pitch(b)   -- (about z, across the walk: + toe up when walking toward +x)
  local q = b:getCenterOfMassTransform():getRotation()
  local x, y, z, s = q:x(), q:y(), q:z(), q:w()
  return math.deg(math.atan2(2 * (s * z + x * y), 1 - 2 * (y * y + z * z)))
end
local lo, hi = btVector3(0, 0, 0), btVector3(0, 0, 0)
local G = room.groundAt
v:postSim(function(N)
  speedPost(N)
  if N % 2 ~= 0 then return end
  local p = w.cube.body:getCenterOfMassPosition()
  local row = { string.format("%.4f\t%.3f\t%.3f\t%.2f", N / 60, p.x, p.y, pitch(w.cube.body)) }
  for _, f in ipairs(feet) do
    f.body:getAabb(lo, hi)
    local c = f.body:getCenterOfMassPosition()
    row[#row + 1] = string.format("%.3f\t%.3f\t%.3f\t%.2f\t%.3f\t%.3f", hi.x, lo.y, c.z, pitch(f.body), G(c.x, c.z), G(hi.x + 1, c.z))
  end
  fh:write(table.concat(row, "\t"), "\n")
  if N >= (RUN_SECS or 20) * 60 then fh:close() end
end)
