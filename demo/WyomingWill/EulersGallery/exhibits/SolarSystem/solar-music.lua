--
-- The solar system's music: Holst's The Planets, Holst conducting the
-- London Symphony Orchestra, recorded for Columbia in 1922-23. Public
-- domain in the US (a sound recording published before 1926), as
-- Wikimedia Commons says: File:Holst_-_The_Planets_(Columbia_1922-23).flac.
-- It isn't in the repository (266 MB): the first time you come in, you're
-- asked whether to fetch it, into bpp's data folder (v:dataDir()).
--
-- It starts with Mars as you come in, faded in, and plays on through the
-- suite (and round again). Rest the mouse on a planet -- in the orrery, in
-- its vitrine, one of its moons or its rings -- and it crosses over to
-- that planet's movement; the Earth, the Moon, the Sun, Pluto and the
-- asteroids keep whatever is playing. It pauses with bpp's pause (S),
-- fades out when you walk away from the bay (in the hall), and M turns it
-- off and on. G fetches it, if you said "Not now".
--
-- Sound only: nothing here touches the simulation or prints in a run
-- without a screen (bpp's music, questions and downloads do nothing
-- there, and nothing here is asked or fetched unless you say so).
--
-- Loaded by solar-system.lua: makeMusic(v, say) returns the player.
--

-- where each movement starts in the recording, in seconds: where the sound
-- begins after the silence between movements. Found with ffmpeg's
-- silencedetect (noise=-35dB, d=0.3) on this file, near the times found by
-- ear (in brackets). Each movement's own 78-rpm side breaks are not
-- silences at that level, so they are left as recorded.
local MOVEMENTS = {
  { planet = "Mars", title = "Mars, the Bringer of War", at = 1.5 },             -- 0:01.5   (0:00)
  { planet = "Venus", title = "Venus, the Bringer of Peace", at = 382.5 },       -- 6:22.5   (6:15)
  { planet = "Mercury", title = "Mercury, the Winged Messenger", at = 876.9 },   -- 14:36.9  (14:30)
  { planet = "Jupiter", title = "Jupiter, the Bringer of Jollity", at = 1101.5 },-- 18:21.5  (18:11)
  { planet = "Saturn", title = "Saturn, the Bringer of Old Age", at = 1534.9 },  -- 25:34.9  (25:25)
  { planet = "Uranus", title = "Uranus, the Magician", at = 1965.7 },            -- 32:45.7  (32:35)
  { planet = "Neptune", title = "Neptune, the Mystic", at = 2342.7 },            -- 39:02.7  (38:54)
}
local END = 2673.5                                -- 44:33.5, the last sound (then 7 s of silence)
local FILE = "Holst - The Planets (Columbia 1922-23).flac"
-- the file's own address at Wikimedia: md5("Holst_-_The_Planets_(Columbia_1922-23).flac")
-- = 5f37ff963c99294c7dfa948b3b316dff, so it's in /5/5f/
local URL = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Holst_-_The_Planets_%28Columbia_1922-23%29.flac"
local ASK = "solar-system-holst"          -- (where "Don't ask again" is kept, in bpp's settings)
local VOLUME = 0.85

return function(v, say)
  local M = {}
  local S = { on = true, loaded = false, asked = false, present = false, start = false, paused = false,
              pending = nil, sinceSim = 0, draws = 0, dl = nil, shown = -1 }
  local path
  local function file()
    if not path then path = v:dataDir() .. "/" .. FILE end
    return path
  end
  local function here()
    local f = io.open(file(), "rb")
    if f then f:close(); return true end
    return false
  end
  local BYPLANET = {}
  for k, m in ipairs(MOVEMENTS) do BYPLANET[m.planet] = k end
  local function playing() return v.musicPlaying and v:musicPlaying() end
  -- which movement is playing
  local function now()
    local p = v:musicPosition()
    local k = 1
    for i, m in ipairs(MOVEMENTS) do if p >= m.at then k = i end end
    return k
  end
  -- from s seconds, faded in over fade seconds
  local function startAt(s, fade)
    if not S.loaded then S.loaded = v:loadMusic(file()) end
    if not S.loaded then return end
    S.pending = nil
    v:fadeMusicTo(0, 0)
    if v:playMusic(s) then v:fadeMusicTo(VOLUME, fade) end
  end
  local function fetch()
    if S.dl then
      local st = v:downloadState(S.dl)
      if st.state == "running" then return end
    end
    S.dl, S.shown = v:download(URL, file()), -1
    say("music: fetching Holst's The Planets (266 MB, Wikimedia Commons) into " .. file())
  end
  local function ask()
    local r = v:ask("The solar system",
                    "The solar system can play Holst's <i>The Planets</i>, Holst conducting the London Symphony " ..
                    "Orchestra in 1922\226\128\14723 (public domain; from Wikimedia Commons, 266 MB). Download it?",
                    { "Yes", "Not now", "Don't ask again" }, ASK)
    if r == 1 then fetch() end
  end

  -- you come in (on its own: as it starts)
  function M.enter()
    S.present, S.start = true, true
  end
  -- you walk away (in the hall): it fades out
  function M.leave()
    S.present, S.start = false, false
    if S.pending and S.pending.stop then v:stopMusic() end
    S.pending = nil
    if S.loaded then v:fadeMusicTo(0, 1.5) end
  end
  -- each step of the simulation: it isn't paused
  function M.sim()
    S.sinceSim = 0
    if S.paused then S.paused = false; v:resumeMusic() end
  end
  -- each frame drawn (whether or not it's stepping)
  function M.draw()
    S.draws = S.draws + 1
    S.sinceSim = S.sinceSim + 1
    -- bpp paused (no steps for a few frames): so is the music
    if S.sinceSim >= 3 and not S.paused and playing() then S.paused = true; v:pauseMusic() end
    if S.start then
      S.start = false
      if S.on then
        if here() then startAt(MOVEMENTS[1].at, 4)
        elseif not S.asked then S.asked, S.askAt = true, S.draws + 60 end
      end
    end
    -- (the question a second after you come in, not at once: the window
    -- settled first -- bpp 2026-10 can crash if its window is resized under
    -- the question as it first opens)
    if S.askAt and S.draws >= S.askAt then S.askAt = nil; ask() end
    if S.pending then
      S.pending.n = S.pending.n - 1
      if S.pending.n <= 0 then
        local p = S.pending
        S.pending = nil
        if p.stop then v:stopMusic() else startAt(p.at, 2) end
      end
    end
    -- the download, now and then
    if S.dl and S.draws % 30 == 0 then
      local st = v:downloadState(S.dl)
      if st.state == "running" then
        if st.total and st.total > 0 then
          local pct = math.floor(10 * st.bytes / st.total) * 10      -- (every 10%)
          if pct ~= S.shown then
            S.shown = pct
            say(string.format("music: %d%% (%.0f of %.0f MB)", pct, st.bytes / 1e6, st.total / 1e6))
          end
        end
      else
        S.dl = nil
        if st.state == "done" then
          say("music: here (" .. file() .. ")")
          S.loaded = false
          if S.present and S.on then startAt(MOVEMENTS[1].at, 4) end
        else
          say("music: the download failed: " .. tostring(st.error) .. " (G to try again)")
        end
      end
    end
    -- the end of the suite: round again, from Mars
    if S.present and S.on and S.loaded and not S.paused and not S.pending and S.draws % 60 == 0 then
      if not playing() or v:musicPosition() >= END then startAt(MOVEMENTS[1].at, 4) end
    end
  end
  -- the mouse rests on something of a planet's: its movement
  function M.hover(planet)
    local k = planet and BYPLANET[planet]
    if not k or not S.present or not S.on or not S.loaded or S.paused then return end
    if S.pending and S.pending.k == k then return end
    if playing() and now() == k and not S.pending then return end
    if playing() then
      v:fadeMusicTo(0, 1.2)
      S.pending = { k = k, at = MOVEMENTS[k].at, n = 75 }        -- (75 frames, about 1.2 s)
    else
      startAt(MOVEMENTS[k].at, 2)
    end
  end
  -- M: off (faded out, then stopped) and on (from Mars)
  function M.toggle()
    if S.on then
      S.on = false
      if S.loaded and playing() then
        v:fadeMusicTo(0, 1)
        S.pending = { stop = true, n = 60 }
      end
      say("music: off (M: on again)")
    else
      S.on = true
      if here() then
        startAt(MOVEMENTS[1].at, 3)
        say("music: on")
      else
        say("music: not here yet (G fetches it)")
      end
    end
  end
  -- G: fetch it
  function M.get()
    if here() then say("music: already here (" .. file() .. ")"); return end
    v:forget(ASK)
    fetch()
  end
  M.MOVEMENTS = MOVEMENTS
  return M
end
