--
-- open-manual.lua -- an exhibit's manual, opened in the computer's PDF
-- viewer (Babbage's Hall). The hall's H key uses it, and each exhibit run
-- on its own:
--
--   local MANUAL = dofile(<the hall's folder> .. "open-manual.lua")
--   MANUAL.open(<the exhibit's folder>)       -- its MANUAL.pdf, or README.pdf
--   MANUAL.open(<folder>, what, "MANUAL-splitter.pdf")   -- an exhibit that
--          shares its folder with another names its own manual file
--
-- bpp can't open a file itself from a script, so this asks the system's
-- own opener: xdg-open (Linux), open (macOS), start (Windows), in the
-- background, so the hall goes on. MANUAL_OPENER, if set, is used instead
-- (to test: a command that only records the path it is given).
--

local M = {}

local function exists(p) local f = io.open(p, "rb"); if f then f:close(); return true end return false end
local WINDOWS = package.config:sub(1, 1) == "\\"

-- (a path from the folder bpp runs in, made whole: the viewer runs elsewhere)
local function whole(path)
  if path:sub(1, 1) == "/" or path:match("^%a:[/\\]") then return path end
  local cwd
  local p = io.popen and io.popen(WINDOWS and "cd" or "pwd")
  if p then cwd = p:read("*l"); p:close() end
  cwd = cwd or os.getenv("PWD") or "."
  return cwd .. "/" .. path:gsub("^%./", "")
end

-- the file to open in a folder: its MANUAL.pdf (or the file named) if it
-- has one, else README.pdf
function M.find(dir, file)
  if dir ~= "" and not dir:match("[/\\]$") then dir = dir .. "/" end
  for _, name in ipairs({ file or "MANUAL.pdf", "README.pdf" }) do
    if exists(dir .. name) then return dir .. name, name end
  end
end

local function quote(s)
  if WINDOWS then return '"' .. s .. '"' end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end
local function opener()
  local o = os.getenv("MANUAL_OPENER")
  if o and o ~= "" then return o end
  if WINDOWS then return 'start ""' end
  local p = io.popen and io.popen("uname -s 2>/dev/null")
  local sys = p and p:read("*l"); if p then p:close() end
  return sys == "Darwin" and "open" or "xdg-open"
end

-- open it; says on the console what it opened (or why it couldn't)
function M.open(dir, what, file)
  local path, name = M.find(dir, file)
  if not path then
    print("  (" .. (what or "this") .. " has no manual yet)")
    return nil
  end
  path = whole(path)
  local cmd
  if WINDOWS then cmd = opener() .. " " .. quote(path)
  else cmd = opener() .. " " .. quote(path) .. " >/dev/null 2>&1 &" end
  local ok = os.execute(cmd)
  print(string.format("  %s: %s%s", what or "the manual", path,
        name == "README.pdf" and "  (its README: no manual yet)" or ""))
  return path, ok
end

return M
