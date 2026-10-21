-- exhibit-table.lua -- Babbage's Hall: the standard exhibit table.
--
-- THE STANDARD (README.md, "Exhibit standard"):
--   * The table top is the exhibit's y = 0, 100 cm above the floor (so the
--     exhibit's floor plane is at y = -100, and its floorY in hall.lua -100):
--     the machine stands just above its placard, whose board is at 95 cm.
--   * The top is the machine's footprint plus 30 cm on every side, rounded
--     up to the next 10 cm, and never smaller than 80 x 60 cm.
--   * An oak top, 4 cm, with a brass edge; an apron; four cast-iron legs.
--   * The machine itself keeps its real, printable size.
--
-- An exhibit loads this into its own environment (so in the hall it builds
-- in the exhibit's world, with the exhibit's Cube and Plane):
--
--   local f = assert(loadfile(DIR .. "../../exhibit-table.lua"))
--   if setfenv then setfenv(f, getfenv(1)) end
--   local TABLE = f()
--   local top = TABLE.build(machineWidth, machineDepth, { x = cx, z = cz })
--
-- build() returns the top (a fixed body, its upper face at y = 0: things may
-- stand on it), the table's size, and the floor plane. It also leaves
-- EXHIBIT_TABLE (its size and centre) in the exhibit's globals: in the hall,
-- the exhibit is moved forward so that the table's front edge is 60 cm
-- behind the rail.

local T = {}
T.HEIGHT = 100                  -- cm, floor to the table's top
T.MARGIN = 30                   -- cm of table round the machine, every side
T.MIN_W, T.MIN_D = 80, 60       -- the smallest table
T.TOP = 4                       -- the top's thickness

local OAK, BRASS, IRON = "#6b4423", "#c9a14a", "#2b2b2b"

-- the table for a machine w (along x) by d (along z)
function T.size(w, d)
  local function up(x) return math.ceil(x / 10 - 1e-9) * 10 end
  return math.max(T.MIN_W, up(w + 2 * T.MARGIN)), math.max(T.MIN_D, up(d + 2 * T.MARGIN))
end

local function deco(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.collides = false
  c.col = col
  v:add(c)
  c.pos = btVector3(x, y, z)
  return c
end

-- opts: x, z (the machine's centre on the table; default 0, 0); floor (the
-- floor plane's size, default 400)
function T.build(w, d, opts)
  opts = opts or {}
  local cx, cz = opts.x or 0, opts.z or 0
  local TW, TD = T.size(w, d)
  local top = Cube(TW, T.TOP, TD, 0)
  top.col = OAK
  v:add(top)
  top.pos = btVector3(cx, -T.TOP / 2, cz)
  -- the brass edge round the top, and the apron under it
  deco(TW + 1, 1.2, 1, cx, -0.6, cz + TD / 2, BRASS)
  deco(TW + 1, 1.2, 1, cx, -0.6, cz - TD / 2, BRASS)
  deco(1, 1.2, TD + 1, cx + TW / 2, -0.6, cz, BRASS)
  deco(1, 1.2, TD + 1, cx - TW / 2, -0.6, cz, BRASS)
  local AP = 9
  deco(TW - 12, AP, 2, cx, -T.TOP - AP / 2, cz + TD / 2 - 5, OAK)
  deco(TW - 12, AP, 2, cx, -T.TOP - AP / 2, cz - TD / 2 + 5, OAK)
  deco(2, AP, TD - 12, cx + TW / 2 - 5, -T.TOP - AP / 2, cz, OAK)
  deco(2, AP, TD - 12, cx - TW / 2 + 5, -T.TOP - AP / 2, cz, OAK)
  -- the legs, cast iron, with a stretcher low down between each pair
  local LH = T.HEIGHT - T.TOP
  for _, sx in ipairs({ -1, 1 }) do
    for _, sz in ipairs({ -1, 1 }) do
      deco(5, LH, 5, cx + sx * (TW / 2 - 6), -T.TOP - LH / 2, cz + sz * (TD / 2 - 6), IRON)
    end
    deco(2.5, 2.5, TD - 12, cx + sx * (TW / 2 - 6), -T.HEIGHT + 18, cz, IRON)
  end
  deco(TW - 12, 2.5, 2.5, cx, -T.HEIGHT + 18, cz, IRON)
  local floor = Plane(0, 1, 0, -T.HEIGHT, opts.floor or 400)
  floor.col = "#3b3f45"
  v:add(floor)
  -- (for the hall: where the table is, so it can bring it forward to the rail)
  EXHIBIT_TABLE = { w = TW, d = TD, x = cx, z = cz }
  return top, TW, TD, floor
end

return T
