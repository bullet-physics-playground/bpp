--
-- lib/batch.lua -- the BPP side of the batch runner (BOOK.md G3)
--
-- lib/batch.py starts one headless BPP per (seed, setting) and appends
--   require("lib.batch").start()
-- plus an optional probe file to the script (-l). This module then:
--   * sets delayMs to 0 if the script has it, since that throttle compares
--     wall-clock time and would make a headless result depend on machine
--     speed (FIXES.md item 1);
--   * applies the settings in BATCH_SET ("name=value;name=value"), and
--     re-runs setup if BATCH_RESETUP=1, so the start is drawn with them;
--   * gives probes M.row() to report results and M.every()/M.atEnd() to
--     measure during and at the end of a run.
-- The seed comes from SEED through lib/rng.lua as usual.
--
-- Probe example (a file passed to lib/batch.py with --probe):
--   local batch = require "lib.batch"
--   batch.every(300, function(frame) batch.row({ n = countSomething() }) end)
--   batch.atEnd(function(frame) batch.row({ final = 1, score = score() }) end)
--
-- A row is printed as one line:  ROW frame=900 n=50 score=0.0123
-- lib/batch.py turns every ROW line (and, with --match, the script's own
-- key=value lines) into CSV rows.
--

local M = {}

local function viewer() return rawget(_G, "v") end

local function hasParam(name)
  local vv = viewer()
  if not vv then return false end
  local ok, val = pcall(function() return vv:getParam(name) end)
  return ok and val ~= nil
end

-- "a=1;b=true;c=text" -> { {"a", 1}, {"b", true}, {"c", "text"} }, in order.
function M.settings(str)
  str = str or os.getenv("BATCH_SET") or ""
  local list = {}
  for item in str:gmatch("[^;]+") do
    local k, val = item:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k then
      if val == "true" then val = true
      elseif val == "false" then val = false
      elseif tonumber(val) then val = tonumber(val) end
      list[#list + 1] = { k, val }
    end
  end
  return list
end

-- Set one parameter, keeping it a number, boolean or string.
function M.set(name, val)
  local vv = viewer()
  if type(val) == "number" then
    vv:addParam(name, val, -1e12, 1e12, 0, "set by lib/batch")
  else
    vv:addParam(name, val, "set by lib/batch")
  end
end

-- Re-run the scene's setup, if it exposes one, with its current count.
function M.resetup()
  local setup = rawget(_G, "setup")
  if type(setup) ~= "function" then
    print("batch: no global setup(); BATCH_RESETUP ignored")
    return false
  end
  for _, n in ipairs({ "numParticles", "numDrones" }) do
    if hasParam(n) then setup(math.floor(viewer():getParam(n))); return true end
  end
  setup()
  return true
end

-- Called by lib/batch.py's -l line before any probe.
function M.start()
  if hasParam("delayMs") then M.set("delayMs", 0) end
  local applied = {}
  for _, kv in ipairs(M.settings()) do
    if not hasParam(kv[1]) then
      print(string.format("batch: warning: the script has no parameter '%s'", kv[1]))
    end
    M.set(kv[1], kv[2])
    applied[#applied + 1] = kv[1] .. "=" .. tostring(kv[2])
  end
  if os.getenv("BATCH_RESETUP") == "1" then M.resetup() end
  print(string.format("batch: job=%s seed=%s settings=%s",
                      os.getenv("BATCH_JOB") or "-", os.getenv("SEED") or "-",
                      #applied > 0 and table.concat(applied, ";") or "-"))
end

-- Print one result row. fields: a table of name -> number/string/boolean.
-- order (optional): a list of names to print first, in that order; the
-- rest follow alphabetically so rows are stable from run to run.
local frameNow = 0
function M.row(fields, order)
  local parts, seen = { "frame=" .. frameNow }, { frame = true }
  local function add(k)
    local val = fields[k]
    if val == nil or seen[k] then return end
    seen[k] = true
    if type(val) == "number" and val ~= math.floor(val) then val = string.format("%.6g", val) end
    parts[#parts + 1] = k .. "=" .. tostring(val):gsub("%s", "_")
  end
  for _, k in ipairs(order or {}) do add(k) end
  local rest = {}
  for k in pairs(fields) do if not seen[k] then rest[#rest + 1] = k end end
  table.sort(rest)
  for _, k in ipairs(rest) do add(k) end
  print("ROW " .. table.concat(parts, " "))
end

-- Run fn(frame) every `frames` drawn frames (BPP's preDraw, which also
-- runs headless). Several M.every calls share the one preDraw callback.
local periodic, hooked = {}, false
function M.every(frames, fn)
  periodic[#periodic + 1] = { every = math.max(1, math.floor(frames)), fn = fn }
  if hooked then return end
  hooked = true
  viewer():preDraw(function(N)
    frameNow = N
    for _, p in ipairs(periodic) do
      if N > 0 and N % p.every == 0 then p.fn(N) end
    end
  end)
end

-- Run fn(frame) once when the run stops (BPP's preStop).
local finals = {}
function M.atEnd(fn)
  finals[#finals + 1] = fn
  if #finals > 1 then return end
  viewer():preStop(function(N)
    frameNow = N
    for _, f in ipairs(finals) do f(N) end
  end)
end

return M
