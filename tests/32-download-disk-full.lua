-- v:download onto a full disk must say "failed". A download small enough to
-- sit in QFile's buffer was reported done, with nothing written: the full
-- disk only showed when the buffer was flushed, which nothing checked. Here
-- the download's part file is a link to /dev/full (Linux only), and the
-- source a local file (file://), so no network is needed. A download to a
-- disk with room must still work.

local pass = 0
local fail = 0

local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. (detail and (": " .. detail) or ""))
    fail = fail + 1
  end
end

-- (Not under ThreadSanitizer: Qt 5's QNetworkAccessManager starts its
-- bearer-management thread and a D-Bus thread, which hand events over
-- through Qt's own uninstrumented locking, and their stripped stacks can't
-- be suppressed by name. The sanitizer job runs it.)
local dir = os.getenv("BPP_USER_DIR")
local full = io.open("/dev/full", "w")
if os.getenv("TSAN_OPTIONS") then
  if full then full:close() end
  check("skipped under ThreadSanitizer", true)
  print(string.format("\n%d passed, %d failed", pass, fail))
  return
end
if dir == nil or dir == "" or full == nil then
  check("skipped (needs BPP_USER_DIR and /dev/full)", true)
  print(string.format("\n%d passed, %d failed", pass, fail))
  return
end
full:close()

local src = dir .. "/source.bin"
local f = assert(io.open(src, "wb"))
f:write(string.rep("bpp ", 250))   -- 1000 bytes: well inside the buffer
f:close()

local function fetch(to)
  local id = v:download("file://" .. src, to)
  local s
  for _ = 1, 500 do
    s = v:downloadState(id)
    if s.state ~= "running" then break end
  end
  return s
end

os.execute("ln -s /dev/full '" .. dir .. "/onto-full.bin.part'")
local s = fetch(dir .. "/onto-full.bin")
check("onto a full disk: failed", s.state == "failed", s.state .. " " .. s.bytes .. " " .. s.error)

local s2 = fetch(dir .. "/roomy.bin")
local got = io.open(dir .. "/roomy.bin", "rb")
local text = got and got:read("*a") or ""
if got then got:close() end
check("with room: done, all of it", s2.state == "done" and #text == 1000, s2.state .. " " .. #text)

print(string.format("\n%d passed, %d failed", pass, fail))
