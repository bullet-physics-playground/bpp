-- dump-geometry.lua <digicomp2-geometry.lua> <out.json>: the board's shapes, for figures.py
local G = dofile(arg[1])
local out = {}
local function num(x) return string.format("%.4f", x) end
local function enc(v)
  local t = type(v)
  if t == "number" then return num(v)
  elseif t == "string" then return string.format("%q", v)
  elseif t == "boolean" then return tostring(v)
  elseif t == "table" then
    if #v > 0 or next(v) == nil then
      local o = {}
      for _, x in ipairs(v) do o[#o + 1] = enc(x) end
      return "[" .. table.concat(o, ",") .. "]"
    end
    local o = {}
    for k, x in pairs(v) do
      if type(x) ~= "function" and type(k) == "string" then o[#o + 1] = string.format("%q", k) .. ":" .. enc(x) end
    end
    return "{" .. table.concat(o, ",") .. "}"
  end
  return "null"
end
local function seg(w) return { w[1], w[2], w[3], w[4], w.role or "" } end
local d = {}
d.walls, d.lwalls, d.holes = {}, {}, {}
for _, w in ipairs(G.walls) do d.walls[#d.walls + 1] = seg(w) end
for _, w in ipairs(G.lwalls) do d.lwalls[#d.lwalls + 1] = seg(w) end
for _, h in ipairs(G.holes) do d.holes[#d.holes + 1] = seg(h) end
d.pegs = G.pegs
d.rockers = {}
for _, t in ipairs(G.rockers) do d.rockers[#d.rockers + 1] = { x = t.x, z = t.z, name = t.name, kind = t.kind, done = t.done } end
d.shutters = {}
for _, sh in ipairs(G.shutters) do d.shutters[#d.shutters + 1] = { piece = sh.pieces[1], pin = sh.pin, hole = sh.hole } end
local SH = G.SHUTTER
d.shutter = { bar = SH.bar, knob = SH.knob, knobR = SH.KNOB_R, pinR = SH.PIN[2], travel = SH.TRAVEL }
d.switches = {}
for _, s in ipairs(G.switchList) do
  d.switches[#d.switches + 1] = { x = s.x, z = s.z, name = s.name, on = s.on, top = s.top }
end
d.lanes = G.lanes
d.clearLane = G.clearLane
d.returns = G.returns
d.marks = G.marks
d.stop, d.overflow, d.clearDrop, d.countOffDrop = G.stop, G.overflow, G.clearDrop, G.countOffDrop
d.board = { G.board.x0, G.board.x1, G.board.z0, G.board.z1 }
d.lower = { G.lower.x0, G.lower.x1, G.lower.z0, G.lower.z1 }
d.wheel = { G.WHEEL.x, G.WHEEL.z, G.WHEEL.R, G.WHEEL.ballR, G.WHEEL.queueTop, G.WHEEL.queueBot }
d.wheelPieces = G.WHEEL.pieces
local F, S = G.FLIP, G.SWITCH
d.flip = { pieces = F.pieces, foot = { F.lower[2][1], F.lower[3][1] }, alpha = F.ALPHA, A = F.A, run = F.RUN,
           pegX = F.pegX, pegZ = F.pegZ, pegR = F.PEG_R, weightZ = F.WEIGHT_Z, weightR = F.WEIGHT_R, LF = F.LF }
d.sw = { FL = S.FL, FT = S.FT, IW = S.IW, OX = S.OX, OUT = S.OUT, DROP = S.DROP, ANG = S.ANG }
d.R, d.CHAN, d.HOLE, d.DX, d.DZ, d.ADZ = G.R, G.CHAN, G.HOLE, G.DX, G.DZ, G.ADZ
d.FUNNEL, d.JOIN, d.DONE, d.XC, d.XRET, d.ZCOL = G.FUNNEL, G.JOIN, G.DONE, G.XC, G.XRET, G.ZCOL
d.runtop = F.A + 1.4 + G.R + F.RUN
local f = assert(io.open(arg[2], "w"))
f:write(enc(d))
f:close()
