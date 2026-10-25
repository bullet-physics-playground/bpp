--
-- probes/stuck_robots.lua -- a lib/batch.py probe for the obstacle task:
-- settle_drones.lua's rows, plus, at the end, every agent left in the
-- field and the columns around it
--
-- DEFINITIONS (metres; x is the field's long axis, the goal travels to -x):
--   left behind  an agent (AP or holding) not past the field's far edge at
--                the end (x > xFar, -38 m)
--   stuck        left behind and moved less than STUCK_MOVE (default 1 m)
--                net over the last STUCK_SECS (default 120 s)
--   solid gap    between two columns: centre distance minus both solid
--                radii, the free width a robot (0.50 m wide) must fit
--                through
--   AP gap       centre distance minus both repulsion radii (solid + 1.6
--                m): below 0 the two columns' repulsion zones overlap, so
--                AP pushes an agent in the gap back from both sides
--   blocked      the agent's escape is through a gap narrower than the
--                robot (solid gap < 0.5 m): checked for every pair of
--                columns whose repulsion zones the agent is in or within
--                1 m of
--
-- Prints, at the end, one STUCK or BEHIND line per agent left behind (the
-- position, net move over the window, speed, the nearest three columns,
-- and the narrowest solid and AP gap among the column pairs around it),
-- and adds to the final row: behind, stuck, stuckBlocked (stuck agents
-- next to a gap narrower than the robot), stuckOpen (the rest).
--
--   python3 lib/batch.py Formations-Lennard-Jones-Ground.lua \
--     --probe probes/stuck_robots.lua --env DIM=2 --seeds 1-3 \
--     --frames 30000 --env EVERY=3000 --out stuck.csv
--
local here = debug.getinfo(1, "S").source:match("^@(.*[/\\])") or "probes/"
dofile(here .. "settle_drones.lua")
local batch = require "lib.batch"
local Swarm = require "quadcopter.swarm"

local STUCK_MOVE = tonumber(os.getenv("STUCK_MOVE") or "") or 1
local STUCK_SECS = tonumber(os.getenv("STUCK_SECS") or "") or 120
local ROBOT_WIDTH = 0.5
local OBS_MARGIN = 1.6     -- lib/swarm.lua's repulsion reach past a column

-- each agent's position once a second (enough history for the window)
local hist, lastT = {}, -1
batch.every(1, function()
  local st = Swarm.state()
  if not st.apEngaged or st.simTime - lastT < 0.999 then return end
  lastT = st.simTime
  for _, d in ipairs(st.drones) do
    local h = hist[d.id] or {}
    hist[d.id] = h
    h[#h + 1] = { t = st.simTime, x = d.px, z = d.pz }
    while #h > 1 and h[1].t < st.simTime - STUCK_SECS - 1 do table.remove(h, 1) end
  end
end)

local function netMove(d, now)
  local h = hist[d.id]
  if not h or #h == 0 then return 0 end
  local a = h[1]
  for _, p in ipairs(h) do if p.t >= now - STUCK_SECS then a = p; break end end
  return math.sqrt((d.px - a.x) ^ 2 + (d.pz - a.z) ^ 2), now - a.t
end

batch.atEnd(function()
  local st = Swarm.state()
  if not st.field then return end
  local behind, stuck, blocked = 0, 0, 0
  for _, d in ipairs(st.drones) do
    if (d.state == "ap" or d.state == "hold") and d.px > st.field.xFar then
      behind = behind + 1
      local moved, span = netMove(d, st.simTime)
      local isStuck = span >= STUCK_SECS - 1 and moved < STUCK_MOVE
      -- the columns around it, nearest first
      local near = {}
      for _, o in ipairs(st.obstacles) do
        local c = math.sqrt((d.px - o.wx) ^ 2 + (d.pz - o.wz) ^ 2)
        near[#near + 1] = { o = o, c = c, surf = c - o.solidR }
      end
      table.sort(near, function(a, b) return a.surf < b.surf end)
      local close = {}
      for _, n in ipairs(near) do
        if n.c < n.o.solidR + OBS_MARGIN + 1 then close[#close + 1] = n end
      end
      local minSolid, minAP = math.huge, math.huge
      for i = 1, #close do
        for j = i + 1, #close do
          local a, b = close[i].o, close[j].o
          local c = math.sqrt((a.wx - b.wx) ^ 2 + (a.wz - b.wz) ^ 2)
          minSolid = math.min(minSolid, c - a.solidR - b.solidR)
          minAP = math.min(minAP, c - a.repR - b.repR)
        end
      end
      local isBlocked = minSolid < ROBOT_WIDTH
      if isStuck then
        stuck = stuck + 1
        if isBlocked then blocked = blocked + 1 end
      end
      local cols = {}
      for i = 1, math.min(3, #near) do
        local n = near[i]
        cols[#cols + 1] = string.format("(%.1f,%.1f r%.2f surf%.2f)", n.o.wx, n.o.wz, n.o.solidR, n.surf)
      end
      print(string.format("%s id=%d x=%.2f z=%.2f moved=%.2f speed=%.3f columnsInReach=%d minSolidGap=%s minAPGap=%s nearest=%s",
        isStuck and "STUCK" or "BEHIND", d.id, d.px, d.pz, moved, math.sqrt(d.vx * d.vx + d.vz * d.vz), #close,
        minSolid < math.huge and string.format("%.2f", minSolid) or "-",
        minAP < math.huge and string.format("%.2f", minAP) or "-", table.concat(cols, " ")))
    end
  end
  batch.row({ final = 2, behind = behind, stuck = stuck, stuckBlocked = blocked, stuckOpen = stuck - blocked })
end)
