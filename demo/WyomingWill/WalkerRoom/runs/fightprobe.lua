-- Do a diag build's two motors on one braced pair fight while it walks? (13 November 2026; handover 4y)
-- One test-track run, as speedprobe.lua (the same RUN line), plus a FIGHT line. Every frame from 2 s on, for each
-- braced pair (motors 1 with 4, 2 with 3: DIAG_PAIRS in walker-room.lua), each crank's motor torque in the
-- driving sense (+ drives the walker its way; weight x stride units, about its pivot, the last physics step of the
-- frame) and its power (torque x the crank's turning against the body):
--   FIGHT <name>|opposed <share of frames the pair's two torques have opposite signs, the smaller over 1% of the
--     cap>|fight mean <..> p95 <..>
--     (the smaller of the two torques when opposed, 0 otherwise)|pair mean <..> (their sum)|work + <..> - <..>
--     (all four motors' positive and negative work over the run, weight x stride)|capped <share of motor-frames
--     at 98% of the cap or more>|fight when capped <mean fight as a share of the cap, in the pair-frames where one
--     motor is at its cap> (<how many>)|nudge gap <mean |difference| of the crank lock's nudges within a pair, rad/s>
--     |angle gap <..>..<..> (the pair's turned angles' difference, degrees)
-- With PAIR_MOTOR (walker-room.lua) the free crank's torque reads 0, so opposed and fight read 0.
local realv, hooks = v, {}
local P = setmetatable({}, { __index = function(_, k) local x = realv[k]
    if type(x) == "function" then return function(self, ...) return x(realv, ...) end end
    return x end, __newindex = function(_, k, val) realv[k] = val end })
for _, h in ipairs({ "preSim", "postSim", "preDraw", "onKey", "onHover", "onParamChanged" }) do rawset(P, h, function(self, fn) hooks[h] = fn end) end
rawset(P, "setHelpText", function() end)
v = P
dofile("lib/test-track.lua")
v = realv
local w = room.walkers[1]
local END = (RUN_SECS or 20) * 60
for _, m in ipairs(w.motors) do m.hinge:enableForces() end
local unit = w.totalMass * (GRAVITY or 981) * (STRIDE or 15)
local x0 = w.cube.body:getCenterOfMassPosition().x
local pairs4 = { { 1, 4 }, { 2, 3 } }
local x5, lo, hi, last, T = nil, 9, -9, {}, {}
local frames, opposed, F, S, wpos, wneg, capped, mf, ngap, alo, ahi = 0, 0, {}, 0, 0, 0, 0, 0, 0, 1e9, -1e9
local nudge, FC, FCn = {}, 0, 0
realv:preSim(function(N)
  if hooks.preSim then hooks.preSim(N) end
  -- the lock's nudge for each crank this frame (lockCranks' own rule, read after it ran)
  local sum, n = 0, 0
  for _, m in ipairs(w.motors) do if not m.free then sum = sum + (m.turned or 0) - (m.offset or 0); n = n + 1 end end
  for i, m in ipairs(w.motors) do
    nudge[i] = math.max(-1.5, math.min(1.5, 4 * (sum / math.max(n, 1) + (m.offset or 0) - (m.turned or 0))))
  end
end)
realv:postSim(function(N)
  if hooks.postSim then hooks.postSim(N) end
  local tq, om = {}, {}
  for i, m in ipairs(w.motors) do
    local a = m.hinge:getHingeAngle()
    if last[i] then
      local d = a - last[i]; d = d - 2 * math.pi * math.floor(d / (2 * math.pi) + 0.5)
      om[i] = d * 60
      if N >= 120 then
        local r = d * 60 * m.sign / math.abs(m.speed); lo = math.min(lo, r); hi = math.max(hi, r)
        T[#T + 1] = math.abs(m.hinge:motorTorque()) / unit
      end
    end
    last[i] = a
    tq[i] = m.hinge:motorTorque() / unit
  end
  if N >= 120 and #w.motors == 4 then
    frames = frames + 1
    for i, m in ipairs(w.motors) do
      -- power: torque on body B x the hinge angle's rate (B against A); its sign is fixed below from the run's total
      local p = tq[i] * (om[i] or 0) / 60
      if p > 0 then wpos = wpos + p else wneg = wneg - p end
      if not m.free then
        mf = mf + 1
        if math.abs(tq[i]) >= 0.98 * m.impulse / FIXED / unit then capped = capped + 1 end
      end
    end
    for _, pr in ipairs(pairs4) do
      local a, b = w.motors[pr[1]], w.motors[pr[2]]
      -- driving sense: the sign that makes the pair's mean power positive is applied at the end; here, raw
      local ta, tb = tq[pr[1]] * a.sign, tq[pr[2]] * b.sign
      local f = (ta * tb < 0) and math.min(math.abs(ta), math.abs(tb)) or 0
      local cap = math.max(a.impulse, b.impulse) / FIXED / unit
      if f > 0.01 * cap then opposed = opposed + 1 end
      F[#F + 1] = f
      if math.max(math.abs(ta), math.abs(tb)) >= 0.98 * cap then FC = FC + f / cap; FCn = FCn + 1 end
      S = S + math.abs(ta + tb)
      ngap = ngap + math.abs((nudge[pr[1]] or 0) - (nudge[pr[2]] or 0))
      local g = math.deg(((a.turned or 0) - (a.offset or 0)) - ((b.turned or 0) - (b.offset or 0)))
      alo, ahi = math.min(alo, g), math.max(ahi, g)
    end
  end
  if N == 300 then x5 = w.cube.body:getCenterOfMassPosition().x - x0 end
  if N == END then
    local xe = w.cube.body:getCenterOfMassPosition().x - x0
    table.sort(T)
    print(string.format("RUN %s|speed %.3f|x5 %.2f|xend %.2f|cranks %.2f..%.2f|torque p95 %.4f max %.4f", w.spec.name,
      (xe - x5) / (END / 60 - 5), x5, xe, lo, hi, T[math.max(1, math.floor(0.95 * #T))], T[#T]))
    if frames > 0 then
      local fm = 0; for _, f in ipairs(F) do fm = fm + f end; fm = fm / #F
      table.sort(F)
      -- the motors' net work must be positive (they drive the walker): if the raw sum is negative, the sign
      -- convention was the other way, so swap the two
      if wpos < wneg then wpos, wneg = wneg, wpos end
      print(string.format("FIGHT %s|opposed %.3f|fight mean %.4f p95 %.4f|pair mean %.4f|work + %.2f - %.2f|capped %.3f|fight when capped %.4f of the cap (%d)|nudge gap %.4f|angle gap %.2f..%.2f",
        w.spec.name, opposed / (2 * frames), fm, F[math.max(1, math.floor(0.95 * #F))], S / (2 * frames),
        wpos, wneg, capped / math.max(mf, 1), FC / math.max(FCn, 1), FCn, ngap / (2 * frames), alo, ahi))
    end
  end
end)
