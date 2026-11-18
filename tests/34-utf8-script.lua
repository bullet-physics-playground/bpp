-- A script's own text arrives as written: UTF-8. bpp built with Qt 5 read the
-- script through QTextStream, which decodes with the system code page, so on
-- Windows (Windows-1252) the "°" below -- the bytes C2 B0 -- came in as "Â°"
-- (C3 82 C2 B0), and demo/koppi/gps.lua showed "Â°". (On Linux and macOS the
-- code page is UTF-8, so this passed there all along; the Windows job is the
-- one it's for.)

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

local function hex(s)
  return (s:gsub(".", function(c) return string.format("%02X ", c:byte()) end))
end

local deg = "°"
check("° is C2 B0", deg == "\194\176", hex(deg))
local text = "20.5 °C · 3 × 4 → ü"
check("the line's length in bytes", #text == 25, #text .. ": " .. hex(text))

print(string.format("\n%d passed, %d failed", pass, fail))
