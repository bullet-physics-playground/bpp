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

local near = {}

-- Call once a frame (from postSim) with the drone list and volume 0..1.
function M.update(drones, volume)
  if not M.available then return end
  if not timbreSet then setTimbres() end
  if volume <= 0 then M.silence(); return end

  local okCam, cam, dir, up = pcall(function() return v.cam.pos, v.cam.dir, v.cam.up end)
  if not okCam then return end
  -- right = dir x up
  local right = { x = dir.y * up.z - dir.z * up.y, y = dir.z * up.x - dir.x * up.z, z = dir.x * up.y - dir.y * up.x }
  local rl = sqrt(right.x ^ 2 + right.y ^ 2 + right.z ^ 2)
  if rl < 1e-6 then right = { x = 1, y = 0, z = 0 } else right.x, right.y, right.z = right.x / rl, right.y / rl, right.z / rl end

  -- the drones that make a sound, nearest first
  local heard = {}
  for _, d in ipairs(drones) do
    if (d.w1 + d.w2 + d.w3 + d.w4) > 1 then
      local r, att, pan, dop, bright = hear(d, cam, right)
      heard[#heard + 1] = { d = d, r = r, att = att, pan = pan, dop = dop, bright = bright }
    end
  end
  table.sort(heard, function(a, b) return a.r < b.r end)

  local g = GAIN * volume
  for k = 1, NEAR do
    local h = heard[k]
    local base = (k - 1) * 4
    if h then
      local d = h.d
      local ws = { d.w1, d.w2, d.w3, d.w4 }
      local wMean = 0
      for m = 1, 4 do
        local w = ws[m]
        wMean = wMean + w / 4
        v:setToneTimbre(base + m, h.bright, 0.2)
        v:setTone(base + m, bpf(w) * h.dop, g * loud(w) * h.att, h.pan)
      end
      local x = wMean / W_MAX
      v:setTone(V_WHINE + k, POLE_PAIRS * wMean / (2 * pi) * h.dop,
                WHINE_GAIN * volume * x * sqrt(x) * h.att, h.pan)
    else
      for m = 1, 4 do v:setTone(base + m, 0, 0) end
      v:setTone(V_WHINE + k, 0, 0)
    end
  end

  -- the rest of the swarm, blended: powers add
  local power, fSum, panSum, bSum = 0, 0, 0, 0
  for k = NEAR + 1, #heard do
    local h = heard[k]
    local d = h.d
    for _, w in ipairs({ d.w1, d.w2, d.w3, d.w4 }) do
      local a = g * loud(w) * h.att
      local pw = a * a
      power = power + pw
      fSum = fSum + pw * bpf(w) * h.dop
      panSum = panSum + pw * h.pan
      bSum = bSum + pw * h.bright
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
