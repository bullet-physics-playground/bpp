--
-- lib/status.lua -- the one-line status at the bottom of the BPP window
--
-- Design decision (William, 2026-10-17): every simulation shows its most
-- important information on BPP's status line (v.statusText), one line where
-- only the numbers change. To stay readable as the numbers change:
--   * each value follows its label as label=value, with any padding AFTER
--     the value (units stay with the number), so it reads with its own label;
--   * each field has a fixed width, so nothing shifts (BPP shows the line
--     in a fixed-pitch font, FIXES.md 37);
--   * fields are separated by " | ";
--   * parts that appear and disappear go at the end.
--
--   local status = require "lib.status"
--   status.show({ "Uniform Coverage",
--                 status.int("ticks", ticks, 10),
--                 status.num("deviation", dev, 6),
--                 status.text("goal", "off", 7) })
--
-- Works without BPP too (show() does nothing there).
--

local M = {}

local function pad(s, width) return string.format("%-" .. (width or 0) .. "s", s) end

-- A number with `places` decimals while it fits `width` characters;
-- scientific notation when too small to show (below 10^-places) or too
-- large. signed = true always shows + or -. unit, if given, follows the
-- number inside the field ("0.78 m/s").
function M.num(label, x, places, signed, width, unit)
  places, width = places or 3, width or 10
  local a = math.abs(x)
  local fmt = signed and "%+" or "%"
  local s
  if x == 0 or (a >= 10 ^ -places and a < 10 ^ (width - places - 2)) then
    s = string.format(fmt .. "." .. places .. "f", x)
  else
    s = string.format(fmt .. ".2e", x)
  end
  if unit then s = s .. " " .. unit end
  return label .. "=" .. pad(s, width + (unit and #unit + 1 or 0))
end

-- An integer, padded after.
function M.int(label, n, width, unit)
  local s = string.format("%d", n) .. (unit and (" " .. unit) or "")
  return label .. "=" .. pad(s, width or 6)
end

-- A percentage with `places` decimals.
function M.pct(label, x, places, width)
  return label .. "=" .. pad(string.format("%." .. (places or 1) .. "f%%", x), width or 6)
end

-- A word or phrase, padded after.
function M.text(label, s, width)
  return (label and (label .. "=") or "") .. pad(s, width or #s)
end

-- Join the fields and show them (returns the line).
function M.line(fields) return table.concat(fields, " | ") end

function M.show(fields)
  local line = M.line(fields)
  local v = rawget(_G, "v")
  if v then pcall(function() v.statusText = line end) end
  return line
end

return M
