-- How a room's walkers steered (handover/STEERING.md, stage C; for runs/room-steer.sh): load a room (LOAD, default
-- walker-room.lua), and after END_S simulated seconds (default 240) print
--   ROOM turns <n> (walls <n>, walkers <n>)|rescues <n> [walker:why ...]|righted <n>|turn sizes <deg ...>
--   WALKER <name>|turning <% of the time a wheel was braked>|backing <%>|gone <cm>|turns <n>
-- Run from the WalkerRoom folder, after the room's settings.
local realv = v
dofile(LOAD or "walker-room.lua")
local END = (END_S or 240) * 60
local braked, backing, frames = {}, {}, 0
realv:postSim(function(N)
  frames = frames + 1
  for _, w in ipairs(room.walkers) do
    if w.shoeDown then braked[w] = (braked[w] or 0) + 1 end
    if w.backing then backing[w] = (backing[w] or 0) + 1 end
  end
  if frames == END then
    local walls, walk, sz, why = 0, 0, {}, {}
    for _, t in ipairs(room.turns) do
      if t[3] == "wall" then walls = walls + 1 else walk = walk + 1 end
      sz[#sz + 1] = string.format("%.0f", math.abs(t[4]))
    end
    for _, r in ipairs(room.rescues or {}) do why[#why + 1] = r[2] .. ":" .. r[3] end
    io.stdout:write(string.format("ROOM turns %d (walls %d, walkers %d)|rescues %d [%s]|righted %d|turn sizes %s\n", #room.turns, walls, walk,
      #(room.rescues or {}), table.concat(why, ", "), #room.righted, table.concat(sz, " ")))
    for _, w in ipairs(room.walkers) do
      io.stdout:write(string.format("WALKER %s|turning %.1f%%|backing %.1f%%|gone %.0f cm|turns %d\n", w.spec.name,
        100 * (braked[w] or 0) / frames, 100 * (backing[w] or 0) / frames, w.travelled or 0, w.turns or 0))
    end
    io.stdout:flush()
  end
end)
