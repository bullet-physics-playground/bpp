-- monitor.lua: the exhibit's two boxes, headless, logged to CSV: every 0.1 s
-- the red bead's and the big bead's positions (in the box) and the big
-- bead's turn; every 1 s, for five layers by height at the end of the
-- settling, their mean heights in the middle (|x| < 3 cm), by the walls
-- (|x| > 5 cm) and overall. With the exhibit's settings (keep in step).
--   MON_SEED=7 MON_T=180 MON_OUT=/some/dir bpp -f monitor.lua -n 1
-- then analyse.py in MON_OUT (it reads rough-s*.csv, smooth-s*.csv).
local SEED = tonumber(os.getenv("MON_SEED") or "7")
local TEND = tonumber(os.getenv("MON_T") or "180")
local OUT = os.getenv("MON_OUT") or "."
local N_S = 280
local function settings(rough)
  return { MODEL = 1, YM = 6.3e8, NS = 40, E = 0.95, MUB = 0.1, MUW = 0.1, MUG = 0.1, N = N_S, W = 15, BOX = 1, RB = 1.5,
           LID = 44, H = 42, ROUGH = rough and 1 or 0, RG = 0.5, SG = 1.0, F = 5, GAMMA = 3, GAMMA0 = 0.8, TG = 2, TR = 1,
           SEED = SEED, GW1 = 3, GW2 = 10, WATCH1 = 25, WATCH2 = 75, CONVSTART = 8, CONVEND = 45, LATE0 = 25, LATE1 = 45,
           LATEB0 = 45, LATEB1 = 120, RISE1 = 10, RISE2 = 12, RISEW = 2 }
end
local boxes = {}
for k, rough in ipairs({ true, false }) do
  local b = DemBed()
  for key, val in pairs(settings(rough)) do b:set(key, val) end
  b:init()
  local top = 0
  for i = 0, N_S - 1 do top = math.max(top, b:y(i)) end
  local best, bi = 1e9, 0
  for i = 0, N_S - 1 do
    local d = (b:x(i) + 6) ^ 2 + (b:y(i) - top) ^ 2
    if d < best then best, bi = d, i end
  end
  b:set("TRACER", bi)
  local name = rough and "rough" or "smooth"
  local f = io.open(string.format("%s/%s-s%d-path.csv", OUT, name, SEED), "w")
  f:write("t,tx,ty,bx,by,angle,boxy\n")
  local g = io.open(string.format("%s/%s-s%d-layers.csv", OUT, name, SEED), "w")
  g:write("t,layer,mid_y,mid_n,wall_y,wall_n,all_y\n")
  boxes[k] = { b = b, tr = bi, f = f, g = g, name = name }
end
-- the layers: 5 bands by height at the end of settling (t = 0)
local function assignLayers(bx)
  local ys = {}
  for i = 0, N_S - 1 do ys[#ys + 1] = { bx.b:y(i), i } end
  table.sort(ys, function(a, b) return a[1] < b[1] end)
  bx.layer = {}
  for r, p in ipairs(ys) do bx.layer[p[2]] = math.min(5, math.floor((r - 1) * 5 / N_S) + 1) end
end
local t = -0.5
local nextP, nextL = 0, 0
local dt = 1 / 60
while t < TEND do
  t = t + dt
  for _, bx in ipairs(boxes) do bx.b:start(t) end
  for _, bx in ipairs(boxes) do bx.b:finish() end
  if not boxes[1].layer and t >= 0 then for _, bx in ipairs(boxes) do assignLayers(bx) end end
  if t >= nextP - 1e-9 then
    for _, bx in ipairs(boxes) do
      local b, by = bx.b, bx.b:boxY()
      bx.f:write(string.format("%.3f,%.3f,%.3f,%.3f,%.3f,%.4f,%.3f\n", t, b:x(bx.tr), b:y(bx.tr) - by, b:x(N_S), b:y(N_S) - by, b:angle(N_S), by))
    end
    nextP = nextP + 0.1
  end
  if boxes[1].layer and t >= nextL - 1e-9 then
    for _, bx in ipairs(boxes) do
      local b, by = bx.b, bx.b:boxY()
      local s = {}
      for L = 1, 5 do s[L] = { 0, 0, 0, 0, 0, 0 } end
      for i = 0, N_S - 1 do
        local L, x, y = bx.layer[i], b:x(i), b:y(i) - by
        local q = s[L]
        q[5], q[6] = q[5] + y, q[6] + 1
        if math.abs(x) < 3 then q[1], q[2] = q[1] + y, q[2] + 1 elseif math.abs(x) > 5 then q[3], q[4] = q[3] + y, q[4] + 1 end
      end
      for L = 1, 5 do
        local q = s[L]
        bx.g:write(string.format("%.2f,%d,%.3f,%d,%.3f,%d,%.3f\n", t, L, q[2] > 0 and q[1] / q[2] or -1, q[2], q[4] > 0 and q[3] / q[4] or -1, q[4], q[5] / q[6]))
      end
    end
    nextL = nextL + 1
  end
end
for _, bx in ipairs(boxes) do bx.f:close(); bx.g:close() end
print("monitor done", SEED)
