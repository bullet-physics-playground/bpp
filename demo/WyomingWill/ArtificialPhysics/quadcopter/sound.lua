--
-- Rotor sound for the quadcopter swarm, from BPP's synthesised voices
-- (v:setTone / v:setToneTimbre).
--
-- What a quad sounds like, and how it is made here:
--
--   * Each rotor buzzes at its blade-passing frequency, blades x rev/s:
--     2 * w / (2 pi) for these 2-blade props -- ~38 Hz at idle, ~181 Hz in
--     hover, ~283 Hz flat out. Overtones make it a buzz rather than a hum.
--   * Loudness climbs steeply with speed: rotor noise power goes roughly as
--     rpm^5, so amplitude as (w / wMax)^2.5 -- a climb or a hard turn is
--     much louder than hover, idle is nearly silent.
--   * The four rotors run at slightly different speeds whenever the drone
--     tilts, turns or fights a gust (that is how a quad steers), so their
--     tones beat against each other: the warble you hear when one
--     manoeuvres. Each of the nearest drones gets four voices, one a rotor.
--   * Behind the buzz, the motors whine at pole-pairs x rev/s (7 here,
--     ~630 Hz in hover) -- a quiet, pure tone, for the nearest drones.
--   * A broadband whoosh of the blades cutting the air rides on top
--     (each voice's noise band, chopped at its pitch).
--   * Distance: amplitude falls as 1/r, and far drones lose their overtones
--     (air soaks up high frequencies), so they sound duller as well as
--     quieter. Doppler shifts a drone coming at you up in pitch.
--   * Everyone else -- the rest of the swarm -- is one blended voice set:
--     their sound powers add, at their power-weighted mean pitch, spread
--     over three slightly detuned voices so it chorus-es like a crowd.
--
-- Pan is from the camera: left of the view is left in the speakers.
--
-- Voices used: 1..12 rotors of the 3 nearest drones, 13..15 their motor
-- whine, 16..18 the rest of the swarm. A bpp without v:setTone() just
-- gets no sound.
--

local Quad = require "quadcopter.flight"

local M = {}

local sqrt, max, min, pi = math.sqrt, math.max, math.min, math.pi

local BLADES = 2
local POLE_PAIRS = 7
local NEAR = 3                 -- drones voiced rotor by rotor
local V_WHINE = NEAR * 4       -- whine voices follow the rotor voices
local V_SWARM = V_WHINE + NEAR -- then the swarm's three
local SWARM_VOICES = 3
local SWARM_DETUNE = { 0.985, 1.0, 1.016 }
local SWARM_SPREAD = { -0.3, 0, 0.3 }
local VOICES = V_SWARM + SWARM_VOICES

local R0 = 1.5                 -- m: closer than this is no louder
local GAIN = 1.5               -- amplitude of one rotor flat out at R0, at volume 1
local WHINE_GAIN = 0.05
local SOUND_SPEED = 343        -- m/s

local W_MAX = Quad.P.omegaMax

M.available = pcall(function() v:setTone(1, 0, 0) end)

local timbreSet = false
local function setTimbres()
  for i = 1, V_WHINE do v:setToneTimbre(i, 0.7, 0.2) end
  for i = V_WHINE + 1, V_SWARM do v:setToneTimbre(i, 0.05, 0) end
  for i = V_SWARM + 1, VOICES do v:setToneTimbre(i, 0.4, 0.5) end
  timbreSet = true
end

function M.silence()
  if not M.available then return end
  for i = 1, VOICES do v:setTone(i, 0, 0) end
end

-- per-drone geometry relative to the listener (the camera)
local function hear(d, cam, right)
  local dx, dy, dz = d.px - cam.x, d.py - cam.y, d.pz - cam.z
  local r = sqrt(dx * dx + dy * dy + dz * dz)
  local ux, uy, uz = dx / max(r, 1e-6), dy / max(r, 1e-6), dz / max(r, 1e-6)
  local att = R0 / max(r, R0)
  local pan = ux * right.x + uy * right.y + uz * right.z
  -- velocity toward the listener (> 0 approaching)
  local vr = -((d.vx or 0) * ux + (d.vy or 0) * uy + (d.vz or 0) * uz)
  local doppler = SOUND_SPEED / (SOUND_SPEED - min(vr, 100))
  -- far drones lose their overtones: 0.75 close up, ~0.3 at 40 m
  local bright = 0.75 - 0.45 * min(1, max(0, (r - R0) / 40))
  return r, att, pan, doppler, bright
end

local function bpf(w) return BLADES * w / (2 * pi) end
local function loud(w) local x = w / W_MAX; return x * x * sqrt(x) end   -- (w/wMax)^2.5

-- How busy a drone is, 0 (steady hover) .. 1 (hard manoeuvre), from
-- three things you can hear on a real quad:
--   * rotor spread: the four motors' speeds pulling apart, which is how a
--     quad tilts (pitches/rolls) and turns -- the airframe's pitch;
--   * rotor speed change: all four speeding up or slowing down, which is
--     the sound's pitch rising or falling (climbs, sinks, braking);
--   * speed relative to the swarm (the whole swarm drifting after the
--     goal is not news).
-- Rises quickly, falls back over ~0.7 s, so a manoeuvre stays audible a
-- little after it ends.
local SPREAD_REF = 0.06        -- rotor spread (fraction of mean) that counts as 1
local DW_REF = 150             -- rad/s per s of mean motor speed change
local SPEED_REF = 1.0          -- m/s relative to the swarm
local ATTACK, RELEASE = 0.08, 0.7   -- s

-- Emphasis. A drone's loudness factor, at emphasis 1, is
--   swarm level + (BUSY - swarm level) x how much it stands out,
-- where the swarm level runs from QUIET (everyone settled) to 1 (everyone
-- busy, e.g. a launch), and "stands out" is how far its activity is above
-- the swarm's median, beyond jitter (0..1). At emphasis 0 every factor is 1: the physical
-- sound. In between, a blend in decibels (factor ^ emphasis).
local STANDOUT_MIN = 0.1      -- activity above the swarm's median that is just jitter
local STANDOUT_REF = 0.4      -- and above that, what counts as fully standing out
local QUIET = 0.15             -- a settled swarm: -16 dB
local BUSY = 4.0               -- a drone far busier than the rest: +12 dB
local HOLD = 1.0               -- s a drone keeps its own voices at least
local STICKY = 1.5             -- score bonus for keeping them

local track = setmetatable({}, { __mode = "k" })   -- drone -> {w, act}
local slots = {}               -- k -> {d = drone, since = time}
local lastT = nil

local function activity(d, dt, mvx, mvy, mvz)
  local t = track[d]
  local w1, w2, w3, w4 = d.w1, d.w2, d.w3, d.w4
  local wMean = (w1 + w2 + w3 + w4) / 4
  if not t then t = { w = wMean, act = 0 }; track[d] = t end
  if dt and dt > 0 then
    local spread = (max(w1, w2, w3, w4) - min(w1, w2, w3, w4)) / max(wMean, 1)
    local dw = math.abs(wMean - t.w) / dt
    local speed = sqrt(((d.vx or 0) - mvx) ^ 2 + ((d.vy or 0) - mvy) ^ 2 + ((d.vz or 0) - mvz) ^ 2)
    local raw = spread / SPREAD_REF + dw / DW_REF + speed / SPEED_REF
    local target = 1 - math.exp(-raw)
    local tau = target > t.act and ATTACK or RELEASE
    t.act = t.act + (target - t.act) * (1 - math.exp(-dt / tau))
  end
  t.w = wMean
  return t.act
end
M.activity = function(d) return track[d] and track[d].act or 0 end
M.standout = function(d) return track[d] and track[d].standout or 0 end

-- Call once a frame (from postSim) with the drone list, volume 0..1,
-- emphasis 0 (physical) .. 1 (busy drones stand out), and the flight time.
function M.update(drones, volume, emphasis, now)
  if not M.available then return end
  if not timbreSet then setTimbres() end
  emphasis = max(0, min(1, emphasis or 0))
  local dt = (lastT and now and now > lastT and now - lastT < 1) and (now - lastT) or nil
  lastT = now
  if volume <= 0 then M.silence(); return end

  local okCam, cam, dir, up = pcall(function() return v.cam.pos, v.cam.dir, v.cam.up end)
  if not okCam then return end
  -- right = dir x up
  local right = { x = dir.y * up.z - dir.z * up.y, y = dir.z * up.x - dir.x * up.z, z = dir.x * up.y - dir.y * up.x }
  local rl = sqrt(right.x ^ 2 + right.y ^ 2 + right.z ^ 2)
  if rl < 1e-6 then right = { x = 1, y = 0, z = 0 } else right.x, right.y, right.z = right.x / rl, right.y / rl, right.z / rl end

  -- the swarm's mean velocity (drones with their motors running)
  local mvx, mvy, mvz, nOn = 0, 0, 0, 0
  for _, d in ipairs(drones) do
    if (d.w1 + d.w2 + d.w3 + d.w4) > 1 then
      mvx, mvy, mvz, nOn = mvx + (d.vx or 0), mvy + (d.vy or 0), mvz + (d.vz or 0), nOn + 1
    end
  end
  if nOn > 0 then mvx, mvy, mvz = mvx / nOn, mvy / nOn, mvz / nOn end

  -- the drones that make a sound, and how busy each is
  local heard, byDrone, acts = {}, {}, {}
  for _, d in ipairs(drones) do
    local act = activity(d, dt, mvx, mvy, mvz)
    if (d.w1 + d.w2 + d.w3 + d.w4) > 1 then
      local r, att, pan, dop, bright = hear(d, cam, right)
      local h = { d = d, r = r, att = att, pan = pan, dop = dop, bright = bright, act = act }
      heard[#heard + 1] = h
      byDrone[d] = h
      acts[#acts + 1] = act
    end
  end
  table.sort(acts)
  local median = #acts > 0 and acts[math.floor((#acts + 1) / 2)] or 0
  local level = QUIET + (1 - QUIET) * median          -- the swarm's own loudness
  -- Many calm drones add up (50 are ~13 dB louder than 3) and would bury
  -- the few busy ones; under emphasis the calm part is scaled back toward
  -- the loudness of a handful.
  level = level * (min(1, 3 / max(#heard, 1))) ^ (0.5 * emphasis)
  -- (and distance counts for less: 1/r^(1 - 0.5 x emphasis), so a busy
  -- drone across the swarm can still be heard over calm ones nearby)
  local distExp = 1 - 0.5 * emphasis
  for _, h in ipairs(heard) do
    h.att = h.att ^ distExp
    h.standout = min(1, max(0, h.act - median - STANDOUT_MIN) / STANDOUT_REF)
    track[h.d].standout = h.standout
    h.emph = (level + (BUSY - level) * h.standout) ^ emphasis   -- (blended in dB)
    -- who gets voices of their own: the nearest at emphasis 0, the ones
    -- that stand out (and are near) as emphasis rises
    h.score = h.att * (1 + 20 * emphasis * h.standout)
  end
  M.median = median

  -- keep the slots' drones while they're still the best (or just got in)
  for k = 1, NEAR do
    local s = slots[k]
    local h = s and byDrone[s.d]
    if h then
      h.score = (now and s.since and now - s.since < HOLD) and math.huge or h.score * STICKY
    else
      slots[k] = nil
    end
  end
  table.sort(heard, function(a, b) return a.score > b.score end)
  local chosen = {}
  for k = 1, math.min(NEAR, #heard) do chosen[heard[k].d] = heard[k] end
  for k = 1, NEAR do                       -- (slots keep their drone if chosen)
    if slots[k] and not chosen[slots[k].d] then slots[k] = nil end
  end
  for k = 1, math.min(NEAR, #heard) do
    local d = heard[k].d
    local has = false
    for j = 1, NEAR do if slots[j] and slots[j].d == d then has = true end end
    if not has then
      for j = 1, NEAR do
        if not slots[j] then slots[j] = { d = d, since = now }; break end
      end
    end
  end

  local g = GAIN * volume
  for k = 1, NEAR do
    local h = slots[k] and byDrone[slots[k].d]
    local base = (k - 1) * 4
    if h then
      local d = h.d
      local ws = { d.w1, d.w2, d.w3, d.w4 }
      local wMean = 0
      local gk = g * h.att * h.emph
      for m = 1, 4 do
        local w = ws[m]
        wMean = wMean + w / 4
        v:setToneTimbre(base + m, h.bright, 0.2)
        v:setTone(base + m, bpf(w) * h.dop, gk * loud(w), h.pan)
      end
      local x = wMean / W_MAX
      v:setTone(V_WHINE + k, POLE_PAIRS * wMean / (2 * pi) * h.dop,
                WHINE_GAIN * volume * x * sqrt(x) * h.att * h.emph, h.pan)
    else
      for m = 1, 4 do v:setTone(base + m, 0, 0) end
      v:setTone(V_WHINE + k, 0, 0)
    end
  end

  -- the rest of the swarm, blended: powers add (each drone emphasized by
  -- its own activity, so a settled crowd fades to a hum)
  local power, fSum, panSum, bSum = 0, 0, 0, 0
  for _, h in ipairs(heard) do
    if not chosen[h.d] then
      local d = h.d
      for _, w in ipairs({ d.w1, d.w2, d.w3, d.w4 }) do
        local a = g * loud(w) * h.att * h.emph
        local pw = a * a
        power = power + pw
        fSum = fSum + pw * bpf(w) * h.dop
        panSum = panSum + pw * h.pan
        bSum = bSum + pw * h.bright
      end
    end
  end
  for j = 1, SWARM_VOICES do
    local vi = V_SWARM + j
    if power > 0 then
      local f, pan = fSum / power, panSum / power
      v:setToneTimbre(vi, bSum / power * 0.8, 0.5)
      v:setTone(vi, f * SWARM_DETUNE[j], sqrt(power / SWARM_VOICES),
                max(-1, min(1, 0.6 * pan + SWARM_SPREAD[j])))
    else
      v:setTone(vi, 0, 0)
    end
  end
end

return M
