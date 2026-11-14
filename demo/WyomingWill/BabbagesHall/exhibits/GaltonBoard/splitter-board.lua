--
-- The splitter board -- Babbage's Hall
--
-- A second Galton board, built so its pins are independent coins
-- (SPLITTERS.md). On the Galton board each pin is fair, but a ball leaving
-- one still moves sideways and goes the same way at the next two times in
-- three (FINDINGS.md section 6). Here every pin is a splitter: a steel pin
-- carrying a printed tooth whose sides slope into straight necks, each neck
-- dropping the ball onto the pin below. With the teeth matched to the
-- balls' bounce, the choices are fair and independent, and the board shows
-- the mathematics of fair coins exactly.
--
-- And it has walls that swallow balls (as set by SB_WALLS):
--   first   one wall, 2 places left of the start (the default): a ball
--           reaching it drops into a tube for the row it was caught at.
--           The tubes fill as first passage has it, (a/n) C(n, (n+a)/2) / 2^n
--           for row n: a long thin tail, the average wait infinite. The
--           survivors pile up away from the wall as the reflection
--           principle has it.
--   ruin    walls on both sides, 4 places apart, the start SB_START places
--           from the left one (default 2): gambler's ruin, a ball leaving
--           by the right with chance start/4 (a quarter, a half, three
--           quarters)
--   none    no walls: the binomial, exactly
--   reflect one wall that sends balls back, the outermost place a ball can
--           reach SB_REFL places left of the start (default 3): each bin
--           holds its binomial count plus its mirror image's in the wall
--           (the reflection principle the other way round)
--   flat    two such walls, SB_REFL places either side (default 3): the
--           pile goes flat, a third of the balls in each of three bins
--           (SB_REFL=5: five bins, not yet flat after twelve rows, as the
--           mathematics has it)
--
-- The machine around it (the hopper, the two mirror-image metering wheels,
-- the crank, the slide and drawer, the hand, the sign) is the Galton
-- board's, and galton.lua runs it: this script sets out what is its own
-- (splitter-geometry.lua, parts/splitter.scad) and runs galton.lua.
--
-- SB_WALLS, SB_START, SB_REFL, SB_TEETH (the teeth's neck length: 10, 12, 14 or 20,
-- chosen for the balls' bounce, SPLITTERS.md); and the Galton board's GB_*
-- settings (GB_TOUR, GB_RUNS, GB_BOUNCE, ...).
--
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local walls = os.getenv("SB_WALLS") or "first"
local options = { TOOTH_NECK = envnum("SB_TEETH", 10) }
if walls == "ruin" then
  local start = envnum("SB_START", 2)
  options.WALL_L, options.WALL_R = start, 4 - start
elseif walls == "none" then
  options.WALL_L, options.WALL_R = 0, 0
elseif walls == "reflect" or walls == "flat" then
  options.WALL_L, options.WALL_R = 0, 0
  options.REFL_L = envnum("SB_REFL", 3)
  options.REFL_R = walls == "flat" and options.REFL_L or 0
else
  options.WALL_L, options.WALL_R = envnum("SB_WALL", 2), 0
end

BOARD = {
  noWrite = walls ~= "first" or options.TOOTH_NECK ~= 10 or os.getenv("SB_WALL") ~= nil,   -- (only the default writes the sizes file; the others hand theirs to OpenSCAD in the part's text)
  name = "The splitter board",
  result = "splitter",
  title = "THE SPLITTER BOARD",
  geometry = "splitter-geometry.lua",
  options = options,
  scad = "splitter.scad",
  geoScad = "splitter-geometry.scad",
  alsoScad = { "galton.scad", "geometry.scad" },
  camera = { 0, 44, 112, 0, 38 },
  keyBoard = "the splitter board: twelve rows of splitters, a wall that swallows balls, a tube for each row it can catch one at",
  keyPins = "a splitter's pin: steel, 4 mm, carrying its tooth",
  keyTeeth = "a splitter's tooth: printed, a wedge whose sides slope into straight necks; each neck drops a ball onto the pin below. A set of teeth with longer or shorter necks matches the board to its balls' bounce",
  help = {
    "THE SPLITTER BOARD  (Babbage's Hall)",
    "",
    "KEYS",
    "  Space  turn the crank: run the balls through (again: stop)",
    "  E      empty the tubes and bins into the drawer, pour it back",
    "  T      the tour: a run, empty and pour back, a second run",
    "",
    "Every pin is a splitter: a ball drops straight down a neck onto it,",
    "goes left or right, and rolls down the tooth's slope into the next",
    "neck. The neck takes away what the ball remembered of the pin before,",
    "so each choice is a fair coin, independent of the last.",
    "",
  },
}
local WORDS = {
  first = {
    "A ball that reaches the wall on the left drops into the tube for the",
    "row it was caught at. Fair coins fill the tubes to the gold lines: half",
    "the balls caught in the first two rows, and a long thin tail after.",
    "The balls that survive all twelve rows pile up away from the wall.",
    "",
    "The sign counts the balls caught, those in the first tube, and the",
    "survivors, against fair coins.",
  },
  ruin = {
    "A ball that reaches either wall drops into the tube for its side and",
    "row: gambler's ruin. The share that goes out on the right is the start's",
    "place between the walls: a quarter, a half or three quarters.",
    "",
    "The sign counts the balls out on the left and on the right, and the",
    "survivors, against fair coins.",
  },
  none = {
    "No walls: the binomial, exactly. The gold lines are fair coins' counts.",
  },
  reflect = {
    "A ball that reaches the wall on the left lands on a half tooth and is",
    "sent back. Each bin fills with its fair-coin count plus its mirror",
    "image's in the wall (the gold lines): the reflection principle the",
    "other way round from the swallowing wall's, which takes the mirror away.",
    "",
    "The sign counts the balls in the bin by the wall, in the next, and in",
    "the rest, against fair coins.",
  },
  flat = {
    "Both walls send balls back. However the balls start, the pile goes",
    "flat as the rows go on: with the walls three places from the start,",
    "a third of the balls in each bin by the sixth row.",
    "",
    "The sign counts the balls in the left, middle and right bins, against",
    "fair coins.",
  },
}
for _, line in ipairs(WORDS[walls] or WORDS.first) do BOARD.help[#BOARD.help + 1] = line end
local keyWalls = ({ ruin = ", walls on both sides that swallow balls, a tube for each row and side",
  none = ", no walls", reflect = ", a wall that sends balls back (half teeth on it)",
  flat = ", two walls that send balls back (half teeth on them)" })[walls]
if keyWalls then BOARD.keyBoard = "the splitter board: twelve rows of splitters" .. keyWalls end

local path
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/GaltonBoard/" }) do
  local f = io.open(d .. "galton.lua", "r")
  if f then f:close(); path = d .. "galton.lua"; break end
end
assert(path, "The splitter board: can't find galton.lua")
local f
if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
else f = assert(loadfile(path, "t", _ENV)) end
return f()
