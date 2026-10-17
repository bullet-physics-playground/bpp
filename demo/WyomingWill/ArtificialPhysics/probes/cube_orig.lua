dofile((os.getenv('PROBES') or '.') .. '/cubic.lua')
local SEPNAME = PARAM_INFO.rad and "rad" or "desiredSeparation"
for seed = 1, tonumber(os.getenv("SEEDS") or "2") do
  setDimension(true)
  local wantSq = os.getenv("TRI") ~= "1"
  if isSquareFormation ~= wantSq then toggleFormation() end
  if os.getenv("RANGE") then setParam("range", tonumber(os.getenv("RANGE"))) end
  if os.getenv("LAYER") then setParam("layerGain", tonumber(os.getenv("LAYER"))) end
  if isGoalEnabled then toggleGoal() end
  require("lib.rng").seed(seed)
  setup(50)
  for t = 1, tonumber(os.getenv("TICKS") or "6000") do
    simUpdate()
    if t == 250 or t == 500 or t == 750 or t == 1000 or t == 1500 or t == 3000 then
      local pts = {}
      for _, p in ipairs(particles) do pts[#pts + 1] = { p.x, p.y, p.z, p.color } end
      print(string.format("CUBE seed=%d ticks=%d %s", seed, t, cubicStats(pts, v:getParam(SEPNAME))))
    end
  end
end
