--
-- hook-check.lua: bpp's DemBed against bead-bed.c, through Lua. Runs
-- bead-bed.c's validation tests (TEST=drop, pair, incline, gdrop, ghollow)
-- and a short bed run through the hook, printing what bead-bed.c prints,
-- so the two can be compared line for line (see HOOK.md):
--
--   ../../../../release/bpp -f hook-check.lua -n 2 > hook.txt
--   (and the same with bead-bed: HOOK.md has the commands)
--
-- CHECK selects one: "tests" (default) or "bed" (KEY=value pairs from
-- CHECK_ARGS, run to TEND).
--
if not DemBed then
  print("hook-check: this bpp has no DemBed")
  return
end
local function parse(s)
  local t = {}
  for k, val in (s or ""):gmatch("(%w+)=(%S+)") do t[k] = val end
  return t
end
local function bed(args)
  local b = DemBed()
  for k, val in pairs(args) do
    if k == "BOX" then b:set("BOX", val == "right" and 2 or ((val == "gentle" or val == "left") and 0 or 1))
    elseif k ~= "TEST" then assert(b:set(k, tonumber(val)), "unknown key " .. k) end
  end
  return b
end

local CHECK = os.getenv("CHECK") or "tests"
if CHECK == "tests" then
  local TESTS = {
    "TEST=drop MODEL=1 YM=6.3e10 E=0.95 NS=40",
    "TEST=pair MODEL=1 YM=6.3e10 E=0.95 NS=40",
    "TEST=drop MODEL=0 TC=1e-4 E=0.1 NS=40",
    "TEST=pair MODEL=0 TC=1e-4 E=0.1 NS=40",
    "TEST=incline MODEL=1 YM=6.3e10 MUW=0.64 NS=40",
    "TEST=incline MODEL=0 TC=1e-4 MUW=0.1 NS=40",
    "TEST=gdrop ROUGH=1 ROUGHF=1 MODEL=1 YM=6.3e9 E=0.95 NS=80 RG=0.5 SG=1.0",
    "TEST=ghollow ROUGH=1 ROUGHF=1 MODEL=1 YM=6.3e9 E=0.95 NS=80 RG=0.5 SG=1.0 MUW=0.1 TW=0",
  }
  for _, line in ipairs(TESTS) do
    local a = parse(line)
    print("== " .. line)
    print((bed(a):test(a.TEST):gsub("\n$", "")))
  end
else
  local a = parse(os.getenv("CHECK_ARGS"))
  local b = bed(a)
  b:init()
  local TEND = tonumber(a.TEND or 60.05)
  local t, settled, conv = -tonumber(a.SETTLE or 0.5), false, false
  while t < TEND do
    t = t + 1 / 60
    b:step(t)
    if not settled and b:get("settled") == 1 then
      settled = true
      print(string.format("RESULT_SETTLE ovmax=%.3e ovmean=%.3e ke_per_bead_over_mgd=%.3e", b:get("settleOvMax"), b:get("settleOvMean"), b:get("settleKe")))
    end
    if not conv and b:get("conv") == 1 then
      conv = true
      print(string.format("  beads in the middle rising %.2f mm/s, beside the walls %.2f mm/s", b:get("mid"), b:get("wall")))
    end
  end
  print(string.format("RESULT reached=%.3f mid=%.3f wall=%.3f trips=%d ovmean=%.2e ovmax=%.2e hc20=%.3f", b:get("reached"), b:get("mid"), b:get("wall"),
                      b:get("trips"), b:get("ovmean"), b:get("ovmax"), b:get("hc20")))
end
