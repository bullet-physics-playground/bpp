-- media-check.lua: the music, question, download, glow and light calls,
-- headless.
--
--   release/bpp -f demo/WyomingWill/tests/media-check.lua -n 1
--
-- Optional, for the download: MEDIA_CHECK_URL (should arrive),
-- MEDIA_CHECK_SIZE (its size in bytes), MEDIA_CHECK_FAIL_URL (should fail),
-- e.g. against a local `python3 -m http.server`.

local pass, fail = 0, 0
local function check(name, ok, info)
  if ok then
    pass = pass + 1
    print("PASS " .. name)
  else
    fail = fail + 1
    print("FAIL " .. name .. (info and (": " .. tostring(info)) or ""))
  end
end
local function near(a, b) return math.abs(a - b) < 1e-4 end

-- 1. music: no-ops without audio (or headless)
check("loadMusic -> false", v:loadMusic("no-such-file.flac") == false)
check("playMusic(12.5) -> false", v:playMusic(12.5) == false)
check("playMusic() -> false", v:playMusic() == false)
v:pauseMusic()
v:resumeMusic()
v:stopMusic()
v:fadeMusicTo(0.3, 2.0)
v:fadeMusicTo(1.0, 0)
check("musicPosition -> 0", v:musicPosition() == 0)
check("musicPlaying -> false", v:musicPlaying() == false)

-- 2. ask: headless answers "not now" by itself, and remembers nothing
v:forget("media-check")
local b = {"Yes", "Not now", "Don't ask again"}
check("ask -> 2 (Not now)", v:ask("Music", "Download The Planets?", b) == 2)
check("ask with key -> 2", v:ask("Music", "Download?", b, "media-check") == 2)
check("remembered -> 0", v:remembered("media-check") == 0)
check("ask {Yes, Later} -> 2", v:ask("t", "x", {"Yes", "Later"}) == 2)
check("ask {OK} -> 1", v:ask("t", "x", {"OK"}) == 1)

-- 3. downloads
local dir = v:dataDir()
check("dataDir exists", type(dir) == "string" and dir ~= "", dir)

local function waitFor(id, seconds)
  local t0, s = os.time(), v:downloadState(id)
  while s.state == "running" and os.time() - t0 < seconds do
    s = v:downloadState(id)
  end
  return s
end

local bad = v:downloadState(9999)
check("unknown id -> failed", bad.state == "failed", bad.error)

local url = os.getenv("MEDIA_CHECK_URL")
if url then
  local path = dir .. "/media-check.bin"
  os.remove(path)
  local id = v:download(url, path)
  check("download twice -> same id", v:download(url, path) == id)
  local s = waitFor(id, 30)
  print(string.format("download %s: %s %d/%d %s", url, s.state, s.bytes,
                      s.total, s.error))
  check("download done", s.state == "done", s.error)
  local want = tonumber(os.getenv("MEDIA_CHECK_SIZE") or "")
  if want then check("download size", s.bytes == want, s.bytes) end
  local f = io.open(path, "rb")
  check("file there", f ~= nil)
  if f then f:close() end
  local p = io.open(path .. ".part", "rb")
  check("no .part left", p == nil)
  if p then p:close() end
else
  print("SKIP download (set MEDIA_CHECK_URL)")
end

local badUrl = os.getenv("MEDIA_CHECK_FAIL_URL")
if badUrl then
  local path = dir .. "/media-check-404.bin"
  local s = waitFor(v:download(badUrl, path), 30)
  print(string.format("download %s: %s %s", badUrl, s.state, s.error))
  check("bad download failed", s.state == "failed" and s.error ~= "")
  check("no file", io.open(path, "rb") == nil)
  check("no .part", io.open(path .. ".part", "rb") == nil)
end

-- 4. glow
local sun = Sphere(1, 0)
v:add(sun)
check("emission off", sun.emission == "#000000", sun.emission)
sun.emission = "#ffcc66"
check("emission string", sun.emission == "#ffcc66", sun.emission)
check("emission in POV", sun.pov:find("emission rgb <1, 0.8, 0.4>") ~= nil,
      sun.pov)
sun:setEmission(1, 0.5, 0)
check("setEmission", sun.emission == "#ff8000", sun.emission)
sun:setEmission(2, -1, 0)
check("setEmission clamps", sun.emission == "#ff0000", sun.emission)
sun.emission = ""
check("emission cleared", sun.emission == "#000000", sun.emission)
check("no emission in POV", sun.pov:find("emission") == nil)

-- 5. lights: dim the room, a point light at the Sun, restore
local saved = {
  ambient = v.glAmbient, modelAmbient = v.glModelAmbient,
  light0 = v.glLight0, light1 = v.glLight1,
  color0 = v.glLight0Color, color1 = v.glLight1Color,
}
check("light colours default white",
      near(saved.color0.x, 1) and near(saved.color1.z, 1))

v.glAmbient = 0.0            -- (a) dim: no ambient from the lights,
v.glModelAmbient = 0.03      --     a trace of room light,
v.glLight1Color = btVector4(0, 0, 0, 1) -- fill light off
check("glAmbient 0", near(v.glAmbient, 0))
check("glModelAmbient 0.03", near(v.glModelAmbient, 0.03))

v.glLight0 = btVector4(0, 1, 0, 1)                -- (b) at the Sun, w = 1
v.glLight0Color = btVector4(1, 0.9, 0.7, 1)       --     warm
local l0 = v.glLight0
check("glLight0 positional", near(l0.y, 1) and near(l0:getW(), 1))
check("glLight0Color", near(v.glLight0Color.z, 0.7))

v.glAmbient = saved.ambient  -- (c) restore what was saved
v.glModelAmbient = saved.modelAmbient
v.glLight0, v.glLight1 = saved.light0, saved.light1
v.glLight0Color, v.glLight1Color = saved.color0, saved.color1
check("restored glLight0", near(v.glLight0.x, 500) and near(v.glLight0:getW(), 0.4))
check("restored colour", near(v.glLight0Color.z, 1) and near(v.glLight1Color.x, 1))
check("restored ambient", near(v.glAmbient, 0.2) and near(v.glModelAmbient, 0.2))

print(string.format("media-check: %d passed, %d failed", pass, fail))
