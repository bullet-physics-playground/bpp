--
-- BABBAGE'S HALL -- a Victorian engineering hall for the Bullet Physics
-- Playground: cast-iron columns, a glass roof, brick and brass, holding
-- machines that compute, each in its own folder in exhibits/, every part of
-- them printable. They get more interesting as you walk on, ending with
-- Babbage's Difference Engine. Bays still waiting for their machines stand
-- covered, "in preparation".
--
-- Only the exhibit you are standing at runs. Walk away and it stops where
-- it is; come back and it carries on from there.
--
-- KEYS (click the 3D view first so it has the keyboard):
--   Tab         walk to the next exhibit (and the views from either end); at
--               one with a lectern, first up to it, then a step in
--   Shift+Tab   walk back (stepping back out first)
--   ], [        on to the next exhibit, back to the one before (past the
--               stepping in and an exhibit's other ways)
--   F3          find an exhibit: type part of its name, or its number (the
--               "Hall: stop" slider's); Tab, Shift+Tab pick among the
--               matches, Return goes there, Esc (or F3) leaves it
--   I           at an exhibit with a lectern: its label, close up (again: back)
--   PgDn, PgUp  at an exhibit whose label has more than one page: the next
--               page, the one before
--   An exhibit with ways of its own (the splitter board's walls) has a stop
--   for each: Tab steps on through them, and its label changes with them.
--   everything else goes to the exhibit you're at, with the same keys as
--   when it runs on its own; the Shortcuts pane shows them.
--   Rest the mouse on an exhibit, its table, its lectern, a placard or a
--   covered bay to see what it is.
--
-- MORE EXHIBITS: one line each in EXHIBITS, below. A line whose script
-- isn't there yet becomes a covered bay with its placard; when the script
-- turns up, the bay comes to life. The hall grows to fit.
--
-- HOW IT WORKS: as in Euler's Gallery, whose machinery this is. Each
-- exhibit is the unchanged script, in a Bullet world of its own (bpp's
-- v:newWorld), at its own coordinates, drawn in its bay (v:placeWorld) --
-- so it runs exactly as it does on its own, number for number. It's loaded
-- into a sandbox of its own (its own globals) that finds its files in its
-- own folder (hallPath(name) gives a file's path from bpp's folder),
-- gets its own random numbers, keeps its sliders apart (named "Exhibit:
-- slider" in the Params pane), and collects its per-frame callbacks, keys
-- and help, which this file passes on only while you're at it. Only the
-- world of the exhibit you're at is stepped. NEEDS a bpp with v:newWorld.
--
-- LOADING: the hall itself is shown at once, each exhibit's bay with a sheet
-- over it; then the exhibits are loaded one a frame, the one you're at (or
-- walking to) first, and each sheet comes off as its exhibit arrives. The
-- status bar says which is loading. An exhibit's printed parts are made by
-- OpenSCAD the first time it loads, and again after its files change: that
-- is what takes the time (a minute and a half for all five here, the first
-- time; under two seconds once bpp has them cached).
--
-- UNITS: centimetres; the floor is at y = 0.
--

local realV = v
-- (bpp has already drawn from Lua's random numbers before any script runs:
-- an exhibit on its own starts from there. How far in, counted from seed 1.)
local RANDOM_BASE = 0
do
  local first = math.random()
  math.randomseed(1)
  for k = 0, 1000 do if math.random() == first then RANDOM_BASE = k; break end end
end
local realCube, realSphere, realCylinder, realMesh = Cube, Sphere, Cylinder, Mesh
local realCone, realPlane = Cone, Plane
local unpack = unpack or table.unpack

local function findDir(cands, file)
  for _, d in ipairs(cands) do
    local f = io.open(d .. file, "r")
    if f then f:close(); return d end
  end
  error("Babbage's Hall: can't find " .. file)
end
local HERE = findDir({ "./", "demo/WyomingWill/BabbagesHall/" }, "hall.lua")
local MANUAL = dofile(HERE .. "open-manual.lua")   -- (H: the manual, in the PDF viewer)
local MESH = HERE .. "hall-meshes/"
local LABELS = dofile(MESH .. "labels.lua")

-- ---------------------------------------------------------------------
-- the exhibits, in the order you walk past them (a bay on the west side,
-- then the one facing it on the east, and on): in MACHINES.md's order,
-- from what asks least of a visitor (one idea, little mechanism) to what
-- asks most, the hall's namesake at the end
-- ---------------------------------------------------------------------
--   dir, file  the script (dir from this folder). Not there: a covered bay.
--   name       what the header and Tab call it
--   label      its placard (a key of hall-meshes/labels.lua)
--   prefix     its sliders in the Params pane are named prefix .. name
--   floorY     the height of its own ground plane, in its own units: that
--              is where the hall's floor goes
--   about      what the placard says when the mouse rests on it
--   manual     (if it shares its folder with another exhibit) its manual's
--              file name in that folder; H opens MANUAL.pdf otherwise
--   modes      (if it has ways of its own) a list, each { key, name, env,
--              card, about }: each is loaded as an exhibit of its own, in a
--              world of its own, with the environment variables env (so
--              its script, unchanged, builds that way); all stand in the
--              same bay, the one you're at shown and the others put away
--              out of sight. Each is a stop: Tab steps on through them. Its
--              lectern card is hall-meshes/lectern-<card>.png (and -2, -3
--              ... for more pages); its sliders are named with its key.
EXHIBITS = EXHIBITS or {
  { dir = "exhibits/Suanpan/", file = "suanpan.lua", name = "the suanpan", label = "suanpan",
    prefix = "Suanpan: ", floorY = -100,
    about = "The suanpan, the Chinese abacus: a heaven bead counts 5 and an earth bead 1 when\n" ..
            "pushed to the beam; each rod holds a digit. A finger adds by the rules every pupil\n" ..
            "learned: direct, the five-complement, the ten-complement and its carry; the slate\n" ..
            "shows each. 0-9: a number; Return: add it; C: clear; T: the tour.\n" ..
            "Tab: taking away (the rules backward), then multiplying; PgDn turns its label's pages.",
    modes = {
      { key = "add", name = "the suanpan", card = "suanpan", env = { SU_WAY = "add" } },
      { key = "subtract", name = "the suanpan: subtraction", card = "suanpan-subtract", env = { SU_WAY = "subtract" } },
      { key = "multiply", name = "the suanpan: multiplication", card = "suanpan-multiply", env = { SU_WAY = "multiply" } },
    } },
  { dir = "exhibits/SlideRule/", file = "slide-rule.lua", name = "the slide rule", label = "slide-rule",
    prefix = "Slide rule: ", floorY = -100,
    about = "The slide rule (1620s): on D a number v stands log v along; C on the slide is the same.\n" ..
            "C's 1 over a puts every b on C over a x b on D: the slide adds the lengths. A finger\n" ..
            "sets the slide and the cursor; the slate shows each step, the reading and the estimate\n" ..
            "that places the point. Type 2.5 X 3.2 (or 7.5 / 2.5), Return; M: close to the hairline.\n" ..
            "Tab: squares, roots, cubes, reciprocals and logarithms; PgDn turns its label's pages.",
    modes = {
      { key = "multiply", name = "the slide rule", card = "slide-rule", env = { SR_WAY = "multiply" } },
      { key = "powers", name = "the slide rule: squares and roots", card = "slide-rule-powers", env = { SR_WAY = "powers" } },
    } },
  { dir = "exhibits/NapiersBones/", file = "napiers-bones.lua", name = "Napier's bones", label = "napier",
    prefix = "Napier: ", floorY = -100,
    about = "Napier's bones (1617): rods carrying the multiplication table. A hand lays the rods\n" ..
            "for a number beside the index, each turned to its digit; a row then holds every digit's\n" ..
            "multiple, and adding along the diagonals gives the product. Type 4138 X 567, Return;\n" ..
            "M: close to the board. Tab: Genaille's rods (1891), whose triangles do the carrying.",
    modes = {
      { key = "napier", name = "Napier's bones", card = "napier", env = { NB_WAY = "napier" } },
      { key = "genaille", name = "Napier's bones: Genaille's rods", card = "napier-genaille", env = { NB_WAY = "genaille" } },
    } },
  { dir = "exhibits/CombinationLock/", file = "combination-lock.lua", name = "the combination lock", label = "lock",
    prefix = "Lock: ", floorY = -100,
    about = "The combination lock: three wheels behind the dial, each with a gate in its rim. A pin\n" ..
            "through each wheel carries the next round after nearly a turn, so the rules set one wheel\n" ..
            "at a time: left four times to the first number, right three to the second, left two to\n" ..
            "the third. If every gate is then under the fence, it falls into the cam's notch, and\n" ..
            "turning right draws the bolt. Type 31 72 46, Return; M: the dial close up; G: the gates.\n" ..
            "Tab: the safecracker's way, which reads the combination off the lock, never told it.",
    modes = {
      { key = "dial", name = "the combination lock", card = "lock", env = { LK_WAY = "dial" } },
      { key = "safe", name = "the combination lock: the safecracker's way", card = "lock-safecracker", env = { LK_WAY = "safe" },
        about = "The safecracker's way: no two wheels are quite alike, and the fence rests on the largest.\n" ..
                "Rocked gently, the dial stops where the fence meets the cam's notch: the contact points.\n" ..
                "A gate under the wheel holding the fence up drops it a hair, and they close in. Two graphs\n" ..
                "find two numbers; the last wheel is tried. T: the tour; F: feel the contact points." },
    } },
  { dir = "exhibits/BeadSort/", file = "bead-sort.lua", name = "the bead sort", label = "beadsort",
    prefix = "Bead sort: ", floorY = -100,
    about = "The bead sort: each number, 0 to 9, a row of beads laid from the left on nine rods.\n" ..
            "The hand turns the frame upright; the beads slide down their rods, each until it rests\n" ..
            "on the bead below, and the rows, read from the bottom, are the numbers sorted. The\n" ..
            "beads keep their number's colour: the rows end up mixed, for the beads moved, not the\n" ..
            "numbers. Type up to eight digits, Return; R: eight at random; C: clear; T: the tour." },
  { dir = "exhibits/DominoAdder/", file = "domino-adder.lua", name = "the Domino Half Adder", label = "domino-adder",
    prefix = "Dominoes: ", floorY = -100,
    about = "The Domino Half Adder: 268 dominoes that add two one-bit numbers.\n" ..
            "Waves meeting head-on stop each other; a branch is taken only by a wave\n" ..
            "running toward it; a wave can cut another line. That is enough for XOR and AND." },
  { dir = "exhibits/Differential/", file = "differential.lua", name = "the Differential", label = "differential",
    prefix = "Differential: ", floorY = -100,
    about = "The Differential: gears that add. The carrier turns (A + B) / 2, and its\n" ..
            "ring, with twice as many numbers, reads A + B. Turn one input back and it subtracts." },
  { dir = "exhibits/Pascaline/", file = "pascaline.lua", name = "the Pascaline", label = "pascaline",
    prefix = "Pascaline: ", floorY = -100,
    about = "The Pascaline (1642): Pascal's adding machine. Each wheel, passing 9,\n" ..
            "lifts a weighted lever, the sautoir; passing 9 it drops, and its pawl kicks\n" ..
            "the next wheel on by one. Watch 99 + 1 ripple to 100. To add: rest the mouse\n" ..
            "on a dial's hole and press Space, or U/T/H to choose a wheel and 1-9." },
  { dir = "exhibits/GaltonBoard/", file = "galton.lua", name = "the Galton board", label = "galton",
    prefix = "Galton: ", floorY = -100,
    about = "The Galton board (1873): 150 balls fall through twelve rows of pins, going\n" ..
            "left or right at each, and pile up in the bins in the bell of the normal curve;\n" ..
            "the gold lines are where fair coins would put them. Two mirror-image wheels\n" ..
            "under the hopper let them in one at a time. Space: turn the crank; E: empty the bins and pour\n" ..
            "them back; T: the tour." },
  { dir = "exhibits/GaltonBoard/", file = "splitter-board.lua", name = "the splitter board", label = "splitter",
    prefix = "Splitter: ", floorY = -100, manual = "MANUAL-splitter.pdf",   -- (it shares the Galton board's folder)
    about = "The splitter board: a Galton board whose pins are fair, independent coins.\n" ..
            "Every pin is a splitter, a neck dropping each ball onto it; a wall on the left\n" ..
            "swallows the balls that reach it, into a tube for the row they were caught at.\n" ..
            "The tubes fill as first passage has it, a long thin tail; the survivors pile up\n" ..
            "away from the wall. Space: turn the crank; E: empty and pour back; T: the tour.\n" ..
            "Tab steps on through its five walls; PgDn turns its label's pages.",
    modes = {
      { key = "first", name = "the splitter board", card = "splitter", env = { SB_WALLS = "first" } },
      { key = "ruin", name = "the splitter board: gambler's ruin", card = "splitter-ruin",
        env = { SB_WALLS = "ruin", SB_START = "1" } },
      { key = "reflect", name = "the splitter board: a wall that sends balls back", card = "splitter-reflect",
        env = { SB_WALLS = "reflect" } },
      { key = "flat", name = "the splitter board: the pile goes flat", card = "splitter-flat",
        env = { SB_WALLS = "flat" } },
      { key = "none", name = "the splitter board: no walls", card = "splitter-none", env = { SB_WALLS = "none" } },
    } },
  -- (the planimeter comes before the Galton board in MACHINES.md; it waits
  -- here, after the splitter board, so that the Galton board and the
  -- splitter board still face each other across the nave)
  { dir = "exhibits/Planimeter/", file = "planimeter.lua", name = "Amsler's planimeter", label = "planimeter",
    prefix = "Planimeter: ", floorY = -100,
    about = "Amsler's polar planimeter (1856): trace round a shape and a wheel rolling\n" ..
            "and slipping on the paper reads its area. In preparation." },
  { dir = "exhibits/LehmerSieve/", file = "lehmer-sieve.lua", name = "Lehmer's number sieve", label = "lehmer",
    prefix = "Sieve: ", floorY = -100,
    about = "Lehmer's number sieve (1926): wheels of 9, 8, 7 and 5 places, each moved on one\n" ..
            "place by every turn of the handle. Pegs close the holes of the numbers that fail;\n" ..
            "where every wheel has an open hole, the probe falls right through. It factors\n" ..
            "N by Fermat's way; the board beside it shows the working. N: choose a number;\n" ..
            "T: its tour; G: turn until the probe falls through; Space: one turn." },
  { dir = "exhibits/DigiComp2/", file = "digicomp2.lua", name = "the Digi-Comp II", label = "digicomp",
    prefix = "Digi-Comp: ", floorY = -100,
    about = "The Digi-Comp II (1965): balls rolling down a two-level board of flip-flops\n" ..
            "count, add, subtract, multiply and divide in binary. Thirteen rockers, tipped over\n" ..
            "by the balls alone, make the accumulator, the MQ and the distributor; four switches\n" ..
            "are the memory; six shutters on one bar are COMPLEMENT. In AUTO (U) each ball at\n" ..
            "the bottom lets the next go. Space: START; M, C, N, X: the switches; G: run the\n" ..
            "program the \"program\" slider chooses, line by line, on the board behind it\n" ..
            "(B: close up); T: every program in turn." },
  { dir = "exhibits/TidePredictor/", file = "tide-predictor.lua", name = "Kelvin's tide predictor", label = "tide-predictor",
    prefix = "Tides: ", floorY = -75,
    about = "Kelvin's tide predictor (1872): cranks for the Sun's and the Moon's tides,\n" ..
            "added up by a chain over their pulleys, draw the tide a year ahead. In preparation." },
  { dir = "exhibits/DifferentialAnalyser/", file = "differential-analyser.lua", name = "the Differential Analyser",
    label = "differential-analyser", prefix = "Analyser: ", floorY = -75,
    about = "The Differential Analyser (1931): integrators, wheels on spinning discs,\n" ..
            "wired in a loop, solve differential equations and draw the answer. In preparation." },
  { dir = "exhibits/DifferenceEngine/", file = "difference-engine.lua", name = "the Difference Engine",
    label = "difference-engine", prefix = "Engine: ", floorY = -75,
    about = "Babbage's Difference Engine: columns of figure wheels that tabulate a\n" ..
            "polynomial by adding differences, with no multiplying at all. In preparation." },
}
SPARE_BAYS = SPARE_BAYS or 0
-- (opened from elsewhere, as from the repository's top folder: the
-- exhibits' folders are found from this one)
if HERE ~= "./" then
  for _, e in ipairs(EXHIBITS) do
    if not e.dir:match("^/") then e.dir = HERE .. e.dir end
  end
end

-- ---------------------------------------------------------------------
-- the hall's plan: one long nave, the entrance at its south end (+z),
-- the title wall at the north (-z). Bays down both sides, a pair to each
-- of the iron columns' bays.
-- ---------------------------------------------------------------------
local BAY_W, BAY_D, AISLE = 440, 360, 420      -- a bay's width along the nave, its depth; the aisle
local TABLE_GAP = 60                            -- an exhibit's table: its front edge this far behind the rail
local WW = 2 * BAY_D + AISLE                    -- the hall's width (1140)
local HW = WW / 2
local H = 560                                   -- the eaves
local NBAYS = #EXHIBITS + SPARE_BAYS
local ROWS = math.ceil(NBAYS / 2)
local ENTRY = 320                               -- a vestibule inside the door, so the first bays are in view
local ZS = ROWS * BAY_W + ENTRY                 -- the entrance wall
local ZN = -320                                 -- the title wall (a space before it, for the title)

-- the bays, in walking order: each { x, z, a } with a the way it faces
-- (0: toward +z), and the aisle side of it
local function rot(a, dx, dz) return dx * math.cos(a) + dz * math.sin(a), -dx * math.sin(a) + dz * math.cos(a) end
local BAYS = {}
for k = 0, ROWS - 1 do
  local z = ZS - ENTRY - BAY_W / 2 - k * BAY_W
  BAYS[#BAYS + 1] = { x = -HW + BAY_D / 2, z = z, a = math.pi / 2, side = "W" }    -- west side, facing east
  BAYS[#BAYS + 1] = { x = HW - BAY_D / 2, z = z, a = -math.pi / 2, side = "E" }    -- east side, facing west
end

-- ---------------------------------------------------------------------
-- physics: each exhibit has a Bullet world of its own (v:newWorld, which
-- needs a bpp from October 2026 or later), made exactly as bpp makes the
-- scene's own, holding only what the exhibit builds, at its own
-- coordinates. So it runs exactly as it does on its own, number for
-- number. It's drawn in its bay (v:placeWorld). The hall is in the scene's
-- own world (0), which nothing moves in. Only the world of the exhibit
-- you're at is stepped; the others wait exactly as they are.
-- ---------------------------------------------------------------------
if not realV.newWorld then
  error("Babbage's Hall needs a bpp with separate worlds (v:newWorld): rebuild bpp with the worlds patch")
end
local BPP_TIMING = { timeStep = 1 / 25, fixedTimeStep = 1 / 100, maxSubSteps = 7, animationPeriod = 16 }
local IDLE = { timeStep = 1 / 60, fixedTimeStep = 1 / 60, maxSubSteps = 1, animationPeriod = 16 }
-- (the step sizes are bpp's, not a world's: each exhibit's, while you're at it)
local function applyTiming(p)
  realV.timeStep, realV.fixedTimeStep, realV.maxSubSteps = p.timeStep, p.fixedTimeStep, p.maxSubSteps
  if realV.animationPeriod then realV.animationPeriod = p.animationPeriod or 16 end
end
realV.gravity = btVector3(0, -981, 0)

-- ---------------------------------------------------------------------
-- the cost meter (after the Rec Room's): every METER_PRINT seconds the
-- console shows what each frame spent its time on, in ms -- physics (the
-- exhibit's steps and bpp's own), the exhibit's scripts, garbage, and
-- drawing -- and how often the exhibit you're at was resting (see each
-- exhibit's "at rest"). Off unless asked for: the "Hall: meter" slider
-- (in the Params pane at the two views down the hall) or HALL_METER=1.
-- ---------------------------------------------------------------------
local METER = os.getenv("HALL_METER") == "1"
local METER_PARAM = "Hall: meter"
local METER_PRINT = tonumber(os.getenv("HALL_METER_S") or "") or 10
local METER_FILE = os.getenv("HALL_METER_FILE")       -- (and appended to this file, if set)
-- Two stopwatches, as in the Rec Room: bpp's (v:getTime) for real time, and
-- for short pieces of work the same if it is fine-grained enough, else the
-- processor clock.
local realMs = function() return realV:getTime() * 1000 end
local now
do
  local t0 = realV:getTime()
  local t1 = t0
  repeat t1 = realV:getTime() until t1 ~= t0
  local t2 = t1
  repeat t2 = realV:getTime() until t2 ~= t1
  if t2 - t1 < 0.0001 then now = realMs else now = function() return os.clock() * 1000 end end
end
local meter = { phys = 0, scripts = 0, gc = 0, draw = 0, frames = 0, draws = 0, resting = 0, t0 = nil, longest = 0 }
local lastShown = nil      -- (when the last frame was shown: for the freeze log)
local function resetMeter(t)
  meter.phys, meter.scripts, meter.gc, meter.draw, meter.frames, meter.draws, meter.resting = 0, 0, 0, 0, 0, 0, 0
  meter.t0, meter.longest = t, 0
end
-- Garbage: Lua's own collector, which works a little at a time as garbage
-- is made, unless HALL_GC_MS is set: then, as in the Rec Room, up to that
-- many ms are spent collecting every frame, so garbage never piles up into
-- one long collection. The Rec Room needs that (its games share one large
-- heap, and a collection's last step could hold it up for a tenth of a
-- second); here the heap is small, and it cost 0.4 ms every frame, as much
-- again as a resting exhibit costs. Turn it on if the freeze log shows
-- pauses.
local GC_BUDGET = tonumber(os.getenv("HALL_GC_MS") or "") or 0
local function collectSome()
  if GC_BUDGET <= 0 then return end
  local t = now()
  repeat until collectgarbage("step", 0) or now() - t >= GC_BUDGET
  meter.gc = meter.gc + (now() - t)
end
-- A frame that takes longer than FREEZE_LOG_MS (250; 0: never) is noted in
-- the console with the time of day it ended, while the meter is on.
local FREEZE_LOG_MS = tonumber(os.getenv("HALL_FREEZE_MS") or "") or 250

-- ---------------------------------------------------------------------
-- the sandboxes
-- ---------------------------------------------------------------------
local exhibits = {}        -- the live ones, in walking order
local active = nil         -- the exhibit you're at (nil: one of the views)
local flight = nil         -- the camera on its way to the next stop (see "walking on")
local loading = nil        -- the exhibit being loaded
local loadSome             -- (loads the next exhibit; below)
local hallStatus = ""      -- (the hall's own status line: what is loading)
local finder = nil         -- (F3: finding an exhibit by name; the status line is the finder's meanwhile)
local keysStep = nil       -- (HALL_KEYS: keys pressed at given frames, below)

local function loadIn(file, env)
  if setfenv then
    local f, err = loadfile(file)
    if f then setfenv(f, env) end
    return f, err
  end
  return loadfile(file, "t", env)
end
local function exists(path)
  local fh = io.open(path, "rb")
  if fh then fh:close() return true end
  return false
end
-- roots to look in for files named from bpp's own folder
local ROOTS = {}
for entry in package.path:gmatch("[^;]+") do
  local d = entry:match("^(.*[/\\])module[/\\]%?%.lua$")
  if d then ROOTS[#ROOTS + 1] = d; ROOTS[#ROOTS + 1] = d .. "../"; ROOTS[#ROOTS + 1] = d .. "../../" end
end
local ident = btQuaternion(0, 0, 0, 1)

local CALLBACKS = { preSim = true, postSim = true, preDraw = true, postDraw = true, onKey = true,
                    onParamChanged = true, onCommand = true, onJoystick = true, onSpaceNavigator = true,
                    onHover = true, cycleObject = true,
                    onEnter = true, onLeave = true }      -- (the hall's own: you come into its bay, and leave it)
local TIMING = { timeStep = true, fixedTimeStep = true, maxSubSteps = true, animationPeriod = true }

-- Runs fn with the exhibit's world in use (and its random numbers), then
-- puts back the world that was (see setRandom, below)
local setRandom
local LIGHTS, applyLight         -- (an exhibit's lights: see bayLight, below)
local function inWorld(g, fn, ...)
  local was = realV:currentWorld()
  realV:useWorld(g.world)
  local r = { pcall(fn, ...) }
  realV:useWorld(was)
  return unpack(r)
end

-- makeExhibit(e, bay): a sandbox for one exhibit. Everything it builds is
-- left as it is (its own world keeps it apart); what it has of its own is
-- its globals, its folder, its sliders, its keys and callbacks, and its
-- camera, which is moved to its bay.
-- An exhibit's ways not shown are put away: drawn PARKED cm lower, under
-- the floor, and their objects on a layer that isn't drawn, casting no
-- shadows. (Not far away: bpp sizes its view to everything in the scene,
-- and ways put a kilometre down pushed the view's near limit out past the
-- exhibits and lecterns, which then weren't drawn at all.)
local PARKED = 400
local HIDDEN = Layer and Layer("put away") or nil
if HIDDEN then HIDDEN:setVisible(false) end
local function hideObjects(g, hide)
  if not HIDDEN or (g.hidden or false) == hide then return end
  g.hidden = hide
  g.cast = g.cast or {}
  for _, o in ipairs(g.objects) do
    pcall(function()
      if hide then
        g.cast[o] = o.castShadow
        o.castShadow = false
        o.layer = HIDDEN
      else
        o.layer = nil
        if g.cast[o] ~= nil then o.castShadow = g.cast[o] end
      end
    end)
  end
end
local function makeExhibit(e, bay)
  local g = { e = e, name = e.name, dir = e.dir, callbacks = {}, shortcuts = {}, help = "", down = {}, objects = {},
              timing = {}, N = 0, draws = 0, prefix = e.prefix or (e.name .. ": "), vset = {}, view = {} }
  for k, val in pairs(BPP_TIMING) do g.timing[k] = val end
  g.world = realV:newWorld()
  -- its bay: where its world is drawn, turned to face the aisle (its +z,
  -- the side it's seen from on its own, toward the aisle)
  local ox, oy, oz, a = bay.x, bay.y, bay.z, bay.a
  local cs, sn = math.cos(a), math.sin(a)
  -- (one of an exhibit's ways, not the one shown: drawn far under the
  -- floor, out of every view, so bpp's culling leaves it undrawn)
  local function place()
    realV:placeWorld(g.world, btTransform(btQuaternion(btVector3(0, 1, 0), a),
                                          btVector3(ox, oy - (g.parked and PARKED or 0), oz)))
  end
  g.place = place
  place()
  local function toScene(p) return btVector3(p.x * cs + p.z * sn + ox, p.y + oy, -p.x * sn + p.z * cs + oz) end
  local function toLocal(q)
    local x, z = q.x - ox, q.z - oz
    return btVector3(x * cs - z * sn, q.y - oy, x * sn + z * cs)
  end
  g.toScene, g.toLocal = toScene, toLocal
  -- moved dz toward the aisle (its +z) from the bay's middle: see
  -- TABLE_GAP (its world, its views and what the mouse finds all go with it)
  g.shift = function(dz)
    ox, oz = bay.x + dz * sn, bay.z + dz * cs
    place()
  end
  local dir = e.dir
  local function fix(path)
    if type(path) ~= "string" or path:sub(1, 1) == "/" or path:match("^%a:[/\\]") then return path end
    if exists(dir .. path) then return dir .. path end
    if exists(path) then return path end
    local bare = path:gsub("^[%./\\]*", "")
    for _, r in ipairs(ROOTS) do
      if exists(r .. path) then return r .. path end
      if exists(r .. bare) then return r .. bare end
    end
    return dir .. path
  end

  -- the camera: what it sets as it loads is kept as its view; while you're
  -- at it, it moves the camera, from its bay. (As it loads it touches the
  -- camera no other way: exhibits load while you're at another, and one
  -- standing the camera upright as it loaded turned the view you had level.)
  local camFns = {}
  local cam = setmetatable({}, {
    __index = function(_, k)
      local c = realV.cam
      if k == "pos" or k == "look" then return toLocal(c[k]) end
      local val = c[k]
      if type(val) == "function" then
        local fn = camFns[k]
        if not fn then
          fn = function(self, ...) if active == g and not flight then return val(realV.cam, ...) end end
          camFns[k] = fn
        end
        return fn
      end
      return val
    end,
    __newindex = function(_, k, val)
      if k == "pos" or k == "look" then
        if loading == g then g.view[k] = val
        elseif active == g and not flight then realV.cam[k] = toScene(val) end
        return
      end
      if active == g and not flight then realV.cam[k] = val end
    end,
  })

  -- the viewer, as the exhibit sees it
  local vpFns = {}
  local special = {
    addShortcut = function(_, keys, fn) g.shortcuts[keys] = fn end,
    removeShortcut = function(_, keys) g.shortcuts[keys] = nil end,
    addParam = function(_, n, ...) return realV:addParam(g.prefix .. n, ...) end,
    getParam = function(_, n) return realV:getParam(g.prefix .. n) end,
    setHelpText = function(_, text)
      g.help = text
      if active == g and not finder then realV:setHelpText(g.wrapHelp(text)) end
    end,
    setStatusText = function(_, text)
      g.statusText = text or ""
      if active == g and not finder then realV.statusText = g.statusText end
    end,
    loadSound = function(_, path) return realV:loadSound(fix(path)) end,
    -- (its own steps, timed for the meter)
    stepSimulation = function(_, ...)
      local t = now()
      local r = realV:stepSimulation(...)
      meter.phys = meter.phys + (now() - t)
      return r
    end,
    -- (what it adds, kept, so that one of an exhibit's ways can be put away)
    add = function(_, o, ...)
      local r = realV:add(o, ...)
      g.objects[#g.objects + 1] = o
      if g.hidden and HIDDEN then pcall(function() g.cast[o] = o.castShadow; o.castShadow = false; o.layer = HIDDEN end) end
      return r
    end,
    remove = function(_, o, ...)
      for i = #g.objects, 1, -1 do if g.objects[i] == o then table.remove(g.objects, i); break end end
      return realV:remove(o, ...)
    end,
    -- (the worlds are the hall's to arrange)
    newWorld = function() error("an exhibit can't make worlds of its own in the hall") end,
    useWorld = function() end,
    placeWorld = function() end,
  }
  local vp = setmetatable({}, {
    __index = function(_, k)
      if k == "cam" then return cam end
      if TIMING[k] then return g.timing[k] end
      if CALLBACKS[k] then return function(_, fn) g.callbacks[k] = fn end end
      local s = special[k]
      if s then return s end
      if g.vset[k] ~= nil then return g.vset[k] end
      local val = realV[k]
      if type(val) == "function" then
        local fn = vpFns[k]
        if not fn then fn = function(self, ...) return val(realV, ...) end; vpFns[k] = fn end
        return fn
      end
      return val
    end,
    __newindex = function(_, k, val)
      if TIMING[k] then g.timing[k] = val; return end
      if k == "statusText" then                -- (its status line: shown while you're at it)
        g.statusText = val or ""
        if active == g and not finder then realV.statusText = g.statusText end
        return
      end
      if k == "gravity" then realV.gravity = val; return end      -- (its world's)
      g.vset[k] = val        -- (lights, shadows and the like: the hall's own stay)
      -- (its lights, while you're at it, at once: see LIGHTS)
      if LIGHTS[k] and active == g then applyLight(g, k) end
    end,
  })

  local env = setmetatable({}, { __index = _G })
  env._G = env
  env.v = vp
  env.Mesh = function(path, ...) return realMesh(fix(path), ...) end
  -- (a file of its own, found from the hall: for what bpp opens itself, as
  -- an object's tex)
  env.hallPath = fix
  env.galleryPath = fix        -- (Euler's Gallery's name for it)
  -- its ground plane: in its own world, as on its own, but not drawn (the
  -- hall's floor is drawn there, at the same height: it's drawn a hundredth
  -- of a centimetre across)
  env.Plane = function(nx, ny, nz, c)
    local p = realPlane(nx, ny, nz, c, 0.01)   -- (drawn a hundredth of a cm across)
    -- (and not in a POV-Ray scene, where a plane has no size: it would lie
    -- across the whole floor, at the floor's own height)
    pcall(function() p.pov_export = false end)
    return p
  end
  -- its random numbers: the same sequence it gets on its own (see setRandom)
  env.math = setmetatable({
    random = function(...) g.draws = g.draws + 1; return math.random(...) end,
    randomseed = function(sd) g.seed, g.draws = sd, 0; return math.randomseed(sd) end,
  }, { __index = math })
  -- (one of an exhibit's ways: its environment variables, as if set when
  -- bpp was started)
  if e.env then
    env.os = setmetatable({
      getenv = function(k) local val = e.env[k]; if val ~= nil then return val end; return os.getenv(k) end,
    }, { __index = os })
  end
  env.io = setmetatable({
    open = function(path, mode) return io.open(fix(path), mode) end,
    lines = function(path, ...) if path == nil then return io.lines() end return io.lines(fix(path), ...) end,
  }, { __index = io })
  env.loadfile = function(path) return loadIn(fix(path), env) end
  env.dofile = function(path)
    local f = assert(env.loadfile(path))
    return f()
  end
  local loaded = {}
  env.require = function(mod)
    if loaded[mod] then return loaded[mod] end
    for pattern in package.path:gmatch("[^;]+") do
      local file = pattern:gsub("%?", (mod:gsub("%.", "/")))
      if exists(file) then
        local f = assert(loadIn(file, env))
        loaded[mod] = f(mod) or true
        return loaded[mod]
      end
    end
    return require(mod)
  end
  -- (its parts built in the background while it loads: OpenSCAD asks bpp
  -- to build the part if it isn't in the cache yet, and the load waits, its
  -- coroutine yielding, while the hall goes on; then the part comes from the
  -- cache at once. Outside its load, or with a bpp that can't, as before.)
  if openscadBuild then
    env.OpenSCAD = function(text, ...)
      if loading == g and coroutine.running() then
        while openscadBuild(text) == "building" do
          g.waitingFor = (g.waitingFor or 0) + 1
          coroutine.yield()
        end
      end
      return OpenSCAD(text, ...)       -- (ready: from the cache; failed: it says why)
    end
    -- (Lua 5.1 can't wait inside a pcall: while it loads, its pcall runs the
    -- call as a coroutine of its own, passing any wait on up)
    local function copcall(f, ...)
      local co = coroutine.create(f)
      local r = { coroutine.resume(co, ...) }
      while coroutine.status(co) ~= "dead" do
        r = { coroutine.resume(co, coroutine.yield(unpack(r, 2))) }
      end
      if r[1] then return true, unpack(r, 2) end
      return false, r[2]
    end
    env.pcall = function(f, ...)
      if loading == g and coroutine.running() then return copcall(f, ...) end
      return pcall(f, ...)
    end
    env.xpcall = function(f, h)
      if loading == g and coroutine.running() then
        local r = { copcall(f) }
        if r[1] then return unpack(r) end
        return false, h(r[2])
      end
      return xpcall(f, h)
    end
  end
  g.env = env
  g.load = function() env.dofile(e.file) end
  return g
end

-- Random numbers: Lua has one sequence for everyone. An exhibit on its own
-- starts it from where bpp leaves it and draws from it alone; here the
-- sequence is put back to where that exhibit had got to whenever it's the
-- one drawing (as it loads, and while you're at it).
setRandom = function(g)
  math.randomseed(g.seed or 1)
  for _ = 1, (g.seed and 0 or RANDOM_BASE) + g.draws do math.random() end
end

-- ---------------------------------------------------------------------
-- the hall
-- ---------------------------------------------------------------------
local UP = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local function yq(a) return btQuaternion(btVector3(0, 1, 0), a) end
local HOVER = {}           -- objectKey -> text, for the hall's own things
local function hallAdd(o)
  realV:add(o)
  return o
end
-- Shadows: bpp's shadows come from one light above, so the roof, its ribs
-- and the walls would shade everything. Only what stands on the floor casts:
-- the exhibits, their plinths, the columns' feet, the placards.
local CASTING = false
local function noCast(o)
  if not CASTING then pcall(function() o.castShadow = false end) end
  return o
end
local function vis(o, col, tr)
  noCast(o)
  o.col = col
  pcall(function() o.collides = false end)
  if tr then pcall(function() o.transparency = tr end) end
  return hallAdd(o)
end
local function box(x, y, z, sx, sy, sz, col, q, tr)
  local c = realCube(sx, sy, sz, 0)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(c, col, tr)
end
-- a solid one (the floor; things the mouse can rest on)
local function solid(x, y, z, sx, sy, sz, col, q, hover)
  local c = realCube(sx, sy, sz, 0)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  c.col = col
  c.friction = 0.6
  c.restitution = 0.2
  noCast(c)
  hallAdd(c)
  if hover and objectKey then HOVER[objectKey(c)] = hover end
  return c
end
local function cyl(x, y, z, r, h, col, q)
  local c = realCylinder(r, h, 0)
  c.trans = btTransform(q or UP, btVector3(x, y, z))
  return vis(c, col)
end
local function overhead(o)
  pcall(function() o.castShadow = false end)
  return o
end
local function mesh(file, x, y, z, col, q)
  local m = realMesh(file, 0, false)
  m.trans = btTransform(q or ident, btVector3(x, y, z))
  return vis(m, col)
end

-- the hall's colours: cast iron painted Brunswick green, brass, red brick
-- with buff bands, encaustic tiles
local IRON, IRON2, BRASS, GOLD = "#24382c", "#1a2a21", "#b5893a", "#d4af37"
local BRICK, BUFF, TILE1, TILE2, TILE3 = "#8a3b2a", "#cdb48a", "#9c4a2f", "#ae9d7b", "#2a2422"
-- (the buff tiles were #d9c49a, which the hall's light at full strength,
-- at an exhibit, turned near white)
local GLASS, OAK, CANVAS = "#bcd6dc", "#6b4423", "#b9ae94"
-- The hall's light shines from high above the middle of the nave (a light
-- with w below 1 is at x/w, y/w, z/w). At an exhibit it is at full
-- strength; in the aisle and at the views, dimmed (AISLE_DIM), so an
-- exhibit brightens when you step up to it and dims when you leave (as in
-- Euler's Gallery).
local HALL_LIGHT0 = btVector4(0, 2000, (ZS + ZN) / 2, 0.4)
local AISLE_DIM = 0.6
local HALL_LIGHT1 = btVector4(-200, 100, 200, 0.2)            -- (bpp's own)
realV.glLight0 = HALL_LIGHT0
-- At an exhibit, the hall's light, unless the exhibit sets its own: that
-- comes from where it would on its own, turned with its bay.
local function bayLight(g, L)
  if L:getW() == 1 then
    local a = g.toScene(btVector3(L.x, L.y, L.z))
    return btVector4(a.x, a.y, a.z, 1)
  end
  local a, b = g.toScene(btVector3(L.x, L.y, L.z)), g.toScene(btVector3(0, 0, 0))
  return btVector4(a.x - b.x, a.y - b.y, a.z - b.z, L:getW())
end
-- The rest of an exhibit's lighting -- its ambient light, its lights'
-- colours and its highlights (glSpecular) -- is its own too while you're
-- at it, and the hall's (bpp's, the lights' colours dimmed) again when you
-- leave.
local HALL_LIGHTS = { glAmbient = realV.glAmbient, glModelAmbient = realV.glModelAmbient, glSpecular = realV.glSpecular,
                      glLight0Color = realV.glLight0Color, glLight1Color = realV.glLight1Color }
LIGHTS = { glLight0 = true, glLight1 = true, glAmbient = true, glModelAmbient = true, glSpecular = true,
           glLight0Color = true, glLight1Color = true }
local LIGHT_AS_AISLE = os.getenv("HALL_LIGHT_AS") == "aisle"   -- (for comparing: the aisle's light at an exhibit too)
applyLight = function(g, k)
  if LIGHT_AS_AISLE then g = nil end
  local val = g and g.vset[k]
  if k == "glLight0" then realV.glLight0 = (g and val) and bayLight(g, val) or HALL_LIGHT0
  elseif k == "glLight1" then realV.glLight1 = g and bayLight(g, val or HALL_LIGHT1) or HALL_LIGHT1
  elseif not g and (k == "glLight0Color" or k == "glLight1Color") then
    local c = HALL_LIGHTS[k]                                   -- (the aisle: dimmed)
    realV[k] = btVector4(c.x * AISLE_DIM, c.y * AISLE_DIM, c.z * AISLE_DIM, c:getW())
  else
    if val == nil then val = HALL_LIGHTS[k] end
    realV[k] = val
  end
end

-- the floor: encaustic tiles, buff and terracotta, a dark border down the
-- aisle's edges (solid: anything falling off an exhibit lands on it)
do
  local T = 80
  local AX = WW / 2 - BAY_D          -- the aisle's edges
  for ix = 0, math.ceil(WW / T) - 1 do
    local x0 = -HW + ix * T
    local w = math.min(T, HW - x0)
    for iz = 0, math.ceil((ZS - ZN) / T) - 1 do
      local z0 = ZN + iz * T
      local d = math.min(T, ZS - z0)
      local col = ((ix + iz) % 2 == 0) and TILE1 or TILE2
      solid(x0 + w / 2, -1, z0 + d / 2, w, 2, d, col)
    end
  end
  for _, s in ipairs({ -1, 1 }) do box(s * AX, 0.15, (ZS + ZN) / 2, 14, 0.3, ZS - ZN, TILE3) end
end

-- the walls: brick, a buff band at the dado and another at the springing of
-- the windows; tall windows between the columns
local function wall(x0, z0, x1, z1, windows)
  local L = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
  local a = math.atan2(x1 - x0, z1 - z0) + math.pi / 2     -- (the wall runs along its own x)
  local q = yq(a)
  local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
  overhead(box(cx, H / 2, cz, L, H, 6, BRICK, q))
  box(cx, 110, cz, L, 10, 9, BUFF, q)                                    -- the dado band
  box(cx, 6, cz, L, 12, 9, TILE3, q)                                     -- the plinth course
  overhead(box(cx, 420, cz, L, 8, 9, BUFF, q))                           -- the springing band
  overhead(box(cx, H - 10, cz, L, 20, 12, IRON, q))                      -- the eaves girder
  if windows then
    local nx, nz = (x1 - x0) / L, (z1 - z0) / L
    for s = BAY_W / 2, L - 1, BAY_W do
      local px, pz = x0 + nx * s, z0 + nz * s
      overhead(box(px, 330, pz, 170, 300, 8, IRON2, q))                  -- the iron frame
      overhead(box(px, 330, pz, 156, 286, 9, GLASS, q, 0.5))
      for k = -1, 1 do overhead(box(px + nx * k * 52, 330, pz + nz * k * 52, 4, 286, 10, IRON2, q)) end
      for y = 220, 440, 55 do overhead(box(px, y, pz, 156, 3, 10, IRON2, q)) end
    end
  end
end
wall(-HW, ZS, -HW, ZN, true)            -- the west wall
wall(HW, ZS, HW, ZN, true)              -- the east wall
wall(-HW, ZN, HW, ZN, false)            -- the north wall, with the title
-- the entrance (south) wall, with a door
overhead(box(-HW / 2 - 70, H / 2, ZS, HW - 140, H, 6, BRICK))
overhead(box(HW / 2 + 70, H / 2, ZS, HW - 140, H, 6, BRICK))
overhead(box(0, (H + 320) / 2, ZS, 280, H - 320, 6, BRICK))
box(-146, 160, ZS - 4, 12, 320, 8, IRON); box(146, 160, ZS - 4, 12, 320, 8, IRON); box(0, 322, ZS - 4, 304, 14, 8, IRON)
box(0, 160, ZS + 4, 280, 320, 2, "#14100c")

-- the roof: a glass barrel vault on iron ribs, springing from the eaves
local VR = HW                                    -- the vault's radius
local NSEG = 10
do
  local cz, len = (ZS + ZN) / 2, ZS - ZN
  for k = 0, NSEG - 1 do
    local a0, a1 = math.pi * k / NSEG, math.pi * (k + 1) / NSEG
    local x0, y0 = VR * math.cos(a0), H + 0.45 * VR * math.sin(a0)
    local x1, y1 = VR * math.cos(a1), H + 0.45 * VR * math.sin(a1)
    local mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    local w = math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2)
    local q = btQuaternion(btVector3(0, 0, 1), math.atan2(y1 - y0, x1 - x0))
    overhead(box(mx, my, cz, w, 2, len, GLASS, q, 0.6))                         -- a strip of glass
    overhead(box(mx, my - 1, cz, 6, 4, len, IRON2, q))                           -- an iron purlin at its middle
    -- the ribs, across, every half bay
    for z = ZN, ZS, BAY_W / 2 do overhead(box(mx, my - 4, z, w + 1, 10, 6, IRON, q)) end
  end
  -- the tie rods across the nave at the eaves, at each column
  for z = ZS - ENTRY, ZN + 1, -BAY_W do overhead(box(0, H - 30, z, WW, 3, 3, IRON)) end
end

-- the columns: cast iron, fluted shafts on square bases, gilded capitals,
-- at the aisle's edges between the bays, each with a gas lamp
local AX = WW / 2 - BAY_D
local function column(x, z)
  CASTING = true
  box(x, 20, z, 50, 40, 50, IRON2)                 -- the base
  box(x, 44, z, 40, 8, 40, IRON)
  cyl(x, 48 + (H - 110) / 2, z, 14, H - 110, IRON)
  for k = 0, 7 do
    local dx, dz = rot(k * math.pi / 4, 14, 0)
    cyl(x + dx, 48 + (H - 110) / 2, z + dz, 2.5, H - 120, IRON2)   -- (the fluting)
  end
  CASTING = false
  cyl(x, H - 50, z, 22, 20, GOLD)                  -- the capital
  box(x, H - 34, z, 54, 12, 54, IRON)
  -- the gas lamp: a brass arm toward the aisle, a glass globe
  local s = (x < 0) and 1 or -1
  box(x + s * 30, 300, z, 50, 4, 4, BRASS)
  cyl(x + s * 55, 285, z, 3, 30, BRASS)
  local g = realSphere(11, 0); g.trans = btTransform(ident, btVector3(x + s * 55, 262, z))
  vis(g, "#fff2c0")
  pcall(function() g.emission = "#fff2c0" end)
end
for z = ZS - ENTRY, ZN + BAY_W / 2 - 1, -BAY_W do
  column(-AX, z); column(AX, z)
end

-- the title on the north wall, on an iron arch, facing down the nave
do
  local L = LABELS.title
  box(0, 400, ZN + 6, L.w + 60, 50, 4, IRON)
  box(0, 400, ZN + 8, L.w + 50, 42, 2, "#101a14")
  mesh(MESH .. L.file, 0, 389, ZN + 9, GOLD)
  local S = LABELS.subtitle
  mesh(MESH .. S.file, 0, 350, ZN + 9, BRASS)
  -- and under it, a great wheel of the kind the hall is about
  local q = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
  for k = 0, 23 do
    local a = k * 2 * math.pi / 24
    box(140 * math.cos(a), 190 + 140 * math.sin(a), ZN + 10, 34, 20, 6, IRON, btQuaternion(btVector3(0, 0, 1), a))
  end
  local r = realCylinder(126, 6, 0); r.trans = btTransform(q, btVector3(0, 190, ZN + 10)); vis(r, BRASS)
  local h = realCylinder(116, 8, 0); h.trans = btTransform(q, btVector3(0, 190, ZN + 11)); vis(h, "#2a2018")
  for k = 0, 5 do box(0, 190, ZN + 12, 228, 10, 4, BRASS, btQuaternion(btVector3(0, 0, 1), k * math.pi / 6)) end
  local hub = realCylinder(22, 12, 0); hub.trans = btTransform(q, btVector3(0, 190, ZN + 14)); vis(hub, GOLD)
end

-- a bay: an oak dais, a brass rail along its aisle edge with a gap in the
-- middle for the placard, on a brass stand
local PLACARD_TILT = 12
local function bayFrame(b, labelKey, hoverText)
  local a = b.a
  local q = yq(a)
  -- the dais
  box(b.x, 1.5, b.z, BAY_D - 30, 3, BAY_W - 60, OAK)                     -- (the bays face east or west)
  box(b.x, 3.2, b.z, BAY_D - 40, 0.6, BAY_W - 70, "#4a2f1a")
  -- the rail: posts and a top bar, either side of the placard
  local ux, uz = rot(a, 1, 0)                       -- along the aisle
  local fx, fz = rot(a, 0, BAY_D / 2 - 12)          -- the aisle edge, from the bay's middle
  for _, s in ipairs({ -1, 1 }) do
    for k = 0, 3 do
      local d = s * (60 + k * 40)
      cyl(b.x + fx + ux * d, 45, b.z + fz + uz * d, 1.6, 90, BRASS)
    end
    local d0 = s * (60 + 60)
    box(b.x + fx + ux * d0, 90, b.z + fz + uz * d0, 128, 3, 3, BRASS, q)
  end
  -- the placard: a brass post and an inclined iron board, the name in gilt
  local L = LABELS[labelKey] or LABELS.reserved
  local px, pz = b.x + fx, b.z + fz
  CASTING = true
  box(px, 45, pz, 5, 90, 5, BRASS, q)
  local tiltQ = q * btQuaternion(btVector3(1, 0, 0), -math.rad(PLACARD_TILT))
  local bw = L.w + 12
  solid(px, 95, pz, bw, 14, 2.5, IRON2, tiltQ, hoverText)
  box(px, 95, pz, bw + 2, 16, 2, BRASS, tiltQ)
  local nY, nH = math.cos(math.rad(PLACARD_TILT)), math.sin(math.rad(PLACARD_TILT))
  local vx, vz = rot(a, 0, 1)
  local lx, ly, lz = px + vx * 1.3 * nY, 95 + 1.3 * nH, pz + vz * 1.3 * nY
  local dy = -L.h / 2
  mesh(MESH .. L.file, lx + vx * (-dy * nH), ly + dy * nY, lz + vz * (-dy * nH), GOLD, tiltQ)
  CASTING = false
  return px, pz
end

-- a covered bay: a plinth with a canvas sheet over what's coming
local function coveredBay(b, e)
  bayFrame(b, e.label, e.about)
  local q = yq(b.a)
  CASTING = true
  box(b.x, 45, b.z, 130, 78, 130, OAK, q)
  box(b.x, 85, b.z, 138, 3, 138, BRASS, q)
  solid(b.x, 132, b.z, 112, 90, 112, CANVAS, q, e.about)     -- the sheet, hanging in folds
  box(b.x, 104, b.z, 124, 36, 124, "#a99e84", q)
  box(b.x, 178, b.z, 98, 4, 98, "#c4b99e", q)
  local L = LABELS["in-preparation"]
  local dx, dz = rot(b.a, 0, 56.2)
  mesh(MESH .. L.file, b.x + dx, 160, b.z + dz, "#6a5a3a", q)
  CASTING = false
end
local function emptyBay(b)
  local text = "An empty bay, waiting for the next engine."
  bayFrame(b, "reserved", text)
  local q = yq(b.a)
  CASTING = true
  solid(b.x, 45, b.z, 130, 78, 130, OAK, q, text)
  box(b.x, 85, b.z, 138, 3, 138, BRASS, q)
  CASTING = false
end

-- ---------------------------------------------------------------------
-- the exhibits into their bays
-- ---------------------------------------------------------------------
-- The hall is built first and shown at once; the exhibits are loaded
-- after it, one a frame, the one you're at (or walking to) first. Until
-- its turn, an exhibit's bay holds a sheet over its plinth ("being set
-- up"), and the status bar says which one is loading. (Loading is what
-- takes the time: an exhibit's printed parts are made by OpenSCAD the
-- first time, and again whenever its files change; after that they come
-- from bpp's cache.)
local all = {}             -- every exhibit with a script, in walking order, loaded or not
-- (one of an exhibit's ways, as an exhibit of its own: its name, sliders,
-- environment, lectern card and hover text; the first keeps the exhibit's
-- own slider names)
local function modeOf(e, k)
  local m = e.modes[k]
  local x = {}
  for key, val in pairs(e) do x[key] = val end
  x.modes = nil
  x.name = m.name or e.name
  x.env = m.env
  x.card = m.card or e.label
  x.about = m.about or e.about
  if k > 1 then x.prefix = (e.prefix or (e.name .. ": ")):gsub(":%s*$", "") .. ", " .. m.key .. ": " end
  return x
end
local function sheet(b, about)
  local q = yq(b.a)
  local text = about .. "\n\n(Being set up: it appears here as soon as it has loaded.)"
  CASTING = true
  local objs = {
    box(b.x, 45, b.z, 130, 78, 130, OAK, q),
    box(b.x, 85, b.z, 138, 3, 138, BRASS, q),
    solid(b.x, 132, b.z, 112, 90, 112, CANVAS, q, text),
    box(b.x, 104, b.z, 124, 36, 124, "#a99e84", q),
    box(b.x, 178, b.z, 98, 4, 98, "#c4b99e", q),
  }
  CASTING = false
  return objs
end
local nCovered = 0                 -- (bays in preparation; each of an exhibit's ways is one of all)
for i, b in ipairs(BAYS) do
  local e = EXHIBITS[i]
  if not e then
    emptyBay(b)
  elseif not exists(e.dir .. e.file) then
    coveredBay(b, e)
    nCovered = nCovered + 1
  else
    local off = btVector3(b.x, -(e.floorY or 0), b.z)
    -- (in a world of its own, at its own coordinates, drawn in its bay)
    local g = makeExhibit(e.modes and modeOf(e, 1) or e, { x = b.x, y = -(e.floorY or 0), z = b.z, a = b.a })
    g.bay = b
    bayFrame(b, e.label, e.about)
    if e.stand then
      CASTING = true
      local top, q = off.y - 4, yq(b.a)
      box(b.x, top / 2, b.z, e.stand[1] - 10, top, e.stand[2] - 10, WALNUT, q)
      box(b.x, top - 3, b.z, e.stand[1] - 4, 6, e.stand[2] - 4, DARK, q)
      box(b.x, 5, b.z, e.stand[1], 10, e.stand[2], DARK, q)
      box(b.x, top - 8, b.z, e.stand[1] - 6, 2, e.stand[2] - 6, GILT, q)
      CASTING = false
    end
    g.pending = true
    g.sheet = sheet(b, e.about)
    -- (seen from the aisle, until it has loaded and has a view of its own)
    local vx, vz = rot(b.a, 0, 1)
    g.bayView = { pos = btVector3(b.x + vx * 330, 230, b.z + vz * 330), look = btVector3(b.x, 90, b.z) }
    all[#all + 1] = g
    -- (its other ways: in the same bay, each in a world of its own, put
    -- away until you come to it; no frame, sheet or stand of their own)
    if e.modes then
      local group = { modes = { g } }
      g.group, g.modeIndex = group, 1
      for k = 2, #e.modes do
        local m = makeExhibit(modeOf(e, k), { x = b.x, y = -(e.floorY or 0), z = b.z, a = b.a })
        m.bay, m.group, m.modeIndex = b, group, k
        m.parked = true
        m.place()
        m.pending = true
        m.bayView = g.bayView
        group.modes[k] = m
        all[#all + 1] = m
      end
    end
  end
end

-- an exhibit's lectern: a museum label on a brass post, standing on the dais
-- at its table's right front corner, tilted up; its card (make-lecterns.py:
-- hall-meshes/lectern-<label>.png). Built only if the exhibit has a card.
-- With it the exhibit has an approach: the first Tab brings you to where a
-- visitor walking up would stand, the table and the lectern in view, the
-- card turned to you; the next steps in, to the exhibit's own view. I looks
-- at the card close up, and back.
local LECTERN_TILT = 35                       -- degrees back from upright
local LECTERN = { dx = 12, dz = 14, y = 8 }    -- (cm past the table's right edge, before its front edge;
                                                -- the board's middle over the table top)
local EYE = 62                                -- the approach: eyes this far over the table top (162 cm up)
-- (its card's pages: lectern-<card>.png, then -2, -3 ... while there are more)
local function cardPages(key)
  local pages = {}
  local first = MESH .. "lectern-" .. key .. ".png"
  if not exists(first) then return pages end
  pages[1] = first
  for n = 2, 20 do
    local f = MESH .. "lectern-" .. key .. "-" .. n .. ".png"
    if not exists(f) then break end
    pages[n] = f
  end
  return pages
end
-- (an exhibit's ways share one lectern: built by the first of them to load,
-- its card turned to the way you're at, at its first page)
local function lecternFor(g)
  g.pages = cardPages(g.e.card or g.e.label)
  g.page = 1
  local L = g.group and g.group.lectern
  if L then
    g.lecternCard, g.lecternView = L.card, L.view
    if g.modeIndex == 1 then g.approach = L.approach end
    return true
  end
end
local function lectern(g, t)
  if lecternFor(g) then return end
  local file = g.pages[1]
  if not file then return end
  -- (in the exhibit's own frame: its table top at y = 0, the dais at -96.5)
  local lx, lz, ly = t.x + t.w / 2 + LECTERN.dx, t.z + t.d / 2 + LECTERN.dz, LECTERN.y
  -- the approach: from the aisle, square to the table, back far enough that
  -- the table and the lectern fill the middle of the view (bpp's 45 degrees
  -- up and down; a view a little wider than high)
  local x0, x1 = t.x - t.w / 2, lx + 22
  local cx, cz = (x0 + x1) / 2, t.z + t.d / 4
  local D = 0.85 * (x1 - x0) + t.d / 2
  local apos, alook = btVector3(cx, EYE, cz + D), btVector3(cx, 0, cz)
  -- (the lectern turned to face it)
  local yaw = math.atan2(apos.x - lx, apos.z - lz)
  local q = yq(g.bay.a) * yq(yaw)
  local tq = q * btQuaternion(btVector3(1, 0, 0), -math.rad(LECTERN_TILT))
  local sn, cs = math.sin(math.rad(LECTERN_TILT)), math.cos(math.rad(LECTERN_TILT))
  local function at(x, y, z) return g.toScene(btVector3(x, y, z)) end
  local function put(o, p, rq) o.trans = btTransform(rq, p); return o end
  local base = -96.5
  -- (the hall's, like the placards: in its world, drawn whichever exhibit
  -- is in use; an exhibit loading while you're at another has that one's
  -- world in use, and there its lectern wasn't seen)
  local was = realV:currentWorld()
  realV:useWorld(0)
  CASTING = true
  local parts = {
    put(vis(realCube(22, 1.2, 22, 0), IRON2), at(lx, base + 0.6, lz), q),                       -- (its foot)
    put(vis(realCube(3, ly - 9 - base, 3, 0), BRASS), at(lx, (base + ly - 9) / 2, lz), q),     -- (its post)
    put(vis(realCube(42, 30, 1.6, 0), IRON2), at(lx, ly, lz), tq),                              -- (the board)
    put(vis(realCube(43, 31, 1, 0), BRASS), at(lx, ly - 0.4 * sn, lz - 0.4 * cs), tq),          -- (its brass edge)
  }
  local card = realCube(36, 24, 0.2, 0)                                                         -- (the card, 36 x 24 cm)
  card.tex = file
  local c, W = at(lx, ly + 0.95 * sn, lz + 0.95 * cs), 36
  parts[#parts + 1] = put(vis(card, "#ffffff"), c, tq)
  CASTING = false
  realV:useWorld(was)
  if objectKey then for _, o in ipairs(parts) do HOVER[objectKey(o)] = g.e.about end end
  -- (I: from in front of it, square on, close enough to read)
  local n = btVector3(c.x, c.y, c.z)
  local D = 1.35 * W                           -- (as far off as it is wide, and a bit)
  local d = g.toScene(btVector3(D * cs * math.sin(yaw), D * sn, D * cs * math.cos(yaw))) - g.toScene(btVector3(0, 0, 0))
  g.lecternView = { pos = btVector3(c.x + d.x, c.y + d.y, c.z + d.z), look = n }
  g.lecternCard = card
  local approach = { pos = g.toScene(apos), look = g.toScene(alook) }
  if g.group then
    -- (the approach is the first way's: the others are steps on from it)
    g.group.lectern = { card = card, view = g.lecternView, approach = approach }
    g.group.modes[1].approach = approach
    for _, m in ipairs(g.group.modes) do
      if m ~= g and m.ready then m.lecternCard, m.lecternView = card, g.lecternView end
    end
  else
    g.approach = approach
  end
end
-- (the card turned to one of its pages)
local function showPage(g, n)
  if not (g.lecternCard and g.pages and g.pages[n]) then return end
  g.page = n
  pcall(function() g.lecternCard.tex = g.pages[n] end)
end
-- (one of an exhibit's ways in its bay, the others put away)
local function showMode(g)
  if not g.group then return end
  for _, m in ipairs(g.group.modes) do
    local park = m ~= g
    if m.parked ~= park then m.parked = park; m.place() end
    hideObjects(m, park)
  end
  g.group.shown = g
  showPage(g, 1)
end

-- Loading an exhibit: its script, into its sandbox and world, as on its
-- own. It runs as a coroutine, so that it can wait for its parts while the
-- hall goes on (see OpenSCAD in makeExhibit); resumeLoad takes it on to
-- its next part not built yet, or to its end, and says when it has ended.
local finishLoad
local function startLoad(g)
  g.pending = nil
  g.t0 = realMs()
  g.co = coroutine.create(function() g.load() end)
end
local function resumeLoad(g)
  loading = g
  setRandom(g)
  local was = realV:currentWorld()
  realV:useWorld(g.world)
  local ok, err = coroutine.resume(g.co)
  realV:useWorld(was)
  loading = nil
  if ok and coroutine.status(g.co) ~= "dead" then return false end    -- (waiting for a part)
  g.co = nil
  finishLoad(g, ok, err)
  return true
end
finishLoad = function(g, ok, err)
  local e = g.e
  local t0 = g.t0
  -- the sheet off its bay
  do
    local was = realV:currentWorld()
    realV:useWorld(0)
    for _, o in ipairs(g.sheet or {}) do pcall(function() realV:remove(o) end) end
    realV:useWorld(was)
    g.sheet = nil
  end
  -- its table forward, its front edge TABLE_GAP behind the rail, so the
  -- machine is seen close from the aisle (the exhibit says where its
  -- table is: exhibit-table.lua)
  local t = ok and g.env.EXHIBIT_TABLE
  -- (the mouse on its table: what its placard says, as on the placard,
  -- which is low down and seldom in view)
  if t and t.parts and objectKey then
    for _, o in ipairs(t.parts) do HOVER[objectKey(o)] = g.e.about end
  end
  if t then
    local want = BAY_D / 2 - 12 - TABLE_GAP       -- (the rail is 12 cm in from the bay's edge)
    local front = t.z + t.d / 2
    if want > front then g.shift(want - front) end
    lectern(g, t)
  end
  if ok then
    g.ready = true
    if g.parked then hideObjects(g, true) end      -- (one of an exhibit's ways, not shown)
    exhibits[#exhibits + 1] = g
    print(string.format("HALL: %s is in its bay (%s%s, %.1f s)", g.name, e.dir, e.file, (realMs() - t0) / 1000))
    -- its first frame, now: everything put where it begins, so it shows
    -- from anywhere in the hall, not only once you're at it (and it then
    -- stands still until you arrive, as each exhibit does when it starts)
    inWorld(g, function()
      g.N = g.N + 1
      local f = g.callbacks.preSim
      if f then local ok2, err2 = pcall(f, g.N); if not ok2 then print("HALL: " .. g.name .. " preSim: " .. tostring(err2)) end end
      local tm = g.timing
      realV:stepSimulation(tm.timeStep, tm.maxSubSteps, tm.fixedTimeStep)
      f = g.callbacks.postSim
      if f then local ok2, err2 = pcall(f, g.N); if not ok2 then print("HALL: " .. g.name .. " postSim: " .. tostring(err2)) end end
    end)
  else
    g.failed = tostring(err)
    print("HALL: " .. g.name .. " didn't load: " .. g.failed)
  end
end

-- ---------------------------------------------------------------------
-- walking round: the exhibits, and two views down the hall
-- ---------------------------------------------------------------------
local VIEW_A = { name = "the entrance", isView = true,
                 pos = btVector3(0, 340, ZS - 20), look = btVector3(0, 20, ZN + 200) }
local VIEW_B = { name = "the title wall", isView = true,
                 pos = btVector3(0, 320, ZN + 60), look = btVector3(0, 120, ZS) }
local stops = { VIEW_A }
for _, g in ipairs(all) do stops[#stops + 1] = g end
stops[#stops + 1] = VIEW_B
local function indexOf(s) for i, x in ipairs(stops) do if x == s then return i end end end
local here = VIEW_A
local STOP_PARAM, stopShown = "Hall: stop", nil

local function nextStop(s, d)
  local i = indexOf(s) or 1
  return stops[(i - 1 + d) % #stops + 1]
end
-- (] and [: the next exhibit, or the one before, passing by the step in
-- and an exhibit's other ways; the views at either end count as exhibits)
local function exhibitOf(s) return s.group and s.group.modes[1] or s end
local function nextExhibit(s, d)
  local cur = exhibitOf(s)
  local i = indexOf(cur) or 1
  for k = 1, #stops do
    local t = stops[(i - 1 + d * k) % #stops + 1]
    if exhibitOf(t) == t and t ~= cur then return t end
  end
  return s
end
-- (at an exhibit with an approach: steppedIn is it once you've stepped in)
local steppedIn = nil
-- (an exhibit's pane: one line of the hall's, then its own, its keys at
-- the top, so they show in a small pane; where its sliders are, at the end)
local function header(g)
  return function()
    local out = g.approach and steppedIn ~= g          -- (at its approach)
    local ways = g.group and string.format(" (way %d of %d)", g.modeIndex, #g.group.modes) or ""
    local pages = (g.pages and #g.pages > 1) and string.format(";   PgDn, PgUp: its label's pages (%d of %d)", g.page or 1, #g.pages) or ""
    return "BABBAGE'S HALL -- at " .. g.name .. ways ..
           (out and ".   Tab: step in" or (".   Tab: on to " .. nextStop(g, 1).name)) ..
           ";   Shift+Tab: " .. ((g.approach and not out) and "step back" or ("back to " .. nextStop(g, -1).name)) ..
           (g.lecternView and ";   I: its label, close up (again: back)" or "") .. pages ..
           ";   ], [: on to " .. nextExhibit(g, 1).name .. ", back to " .. nextExhibit(g, -1).name .. ";   F3: find an exhibit" ..
           ((g.shortcuts and g.shortcuts["H"]) and ";   F1: its manual (a PDF)\n" or ";   H: its manual (a PDF)\n")
  end
end
local function wrapHelp(g)
  return function(text)
    return g.header() .. text .. "\n\nIts sliders are the \"" .. g.prefix .. "\" ones in the Params pane."
  end
end
for _, g in ipairs(all) do g.header, g.wrapHelp = header(g), wrapHelp(g) end

local function hallHelp(s)
  local live, coming = {}, {}
  for _, g in ipairs(all) do
    if not g.group or g.modeIndex == 1 then
      live[#live + 1] = "  " .. g.name .. (g.group and string.format(" (%d ways: Tab steps through them)", #g.group.modes) or "") ..
                        (g.ready and "" or (g.failed and "  (didn't load)" or "  (being set up)"))
    end
  end
  for i, e in ipairs(EXHIBITS) do
    if not exists(e.dir .. e.file) then coming[#coming + 1] = "  " .. e.name end
  end
  return "BABBAGE'S HALL -- " .. s.name ..
         "\n(Tab: walk on to " .. nextStop(s, 1).name .. "; Shift+Tab: back to " .. nextStop(s, -1).name ..
         "; ]: on to " .. nextExhibit(s, 1).name .. "; [: back to " .. nextExhibit(s, -1).name .. ")\n\n" ..
         "Only the exhibit you're standing at runs; the others wait where they\n" ..
         "were and carry on when you come back. Rest the mouse on a placard or a\n" ..
         "covered bay to read it.\n\n" ..
         "On show:\n" .. table.concat(live, "\n") .. "\n\n" ..
         (#coming > 0 and ("In preparation:\n" .. table.concat(coming, "\n") .. "\n\n") or "") ..
         "Tab / Shift+Tab   walk on / back, through every stop: up to an exhibit,\n" ..
         "                  a step in, each of its ways\n" ..
         "] / [             on to the next exhibit / back to the one before\n" ..
         "F3                find an exhibit: type part of its name, or its\n" ..
         "                  number (the \"Hall: stop\" slider's), then Return\n" ..
         "H (or F1)          at an exhibit: its manual (a PDF); here: the hall's guide\n" ..
         "the mouse          looks round as usual\n"
end

-- ---------------------------------------------------------------------
-- walking on: the camera flies from where it is to the next stop, out
-- along the aisle and into the next bay, rather than jumping there.
-- HALL_FLY=0: it jumps, as before. (The exhibit you're going to runs at once;
-- its own camera moves wait until you've arrived.)
-- ---------------------------------------------------------------------
local FLY_ON = os.getenv("HALL_FLY") ~= "0"
local FLY_SPEED = 900          -- cm/s along the way; each flight takes 1.2 to 3.5 s
-- the aisle beside a point: the nave's centre line (x = 0)
local function route(p0, p1)
  return { btVector3(0, 0, p0.z), btVector3(0, 0, p1.z) }
end
-- (and every point of the way kept inside the hall's walls, ceiling and
-- floor, so the curve can never swing out through one)
local function inside(p)
  local m = 15
  return btVector3(math.max(-HW + m, math.min(HW - m, p.x)), math.max(m, math.min(H - m, p.y)),
                   math.max(ZN + m, math.min(ZS - m, p.z)))
end
local FLY_LOG = os.getenv("HALL_FLY_LOG")        -- (1: print each flight's extent; a file name: there too)
local function catmull(a, b, c, d, t)
  local t2, t3 = t * t, t * t * t
  local function k(p0, p1, p2, p3)
    return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
  end
  return btVector3(k(a.x, b.x, c.x, d.x), k(a.y, b.y, c.y, d.y), k(a.z, b.z, c.z, d.z))
end
local function yawPitch(d)
  local l = math.max(d:length(), 1e-9)
  return math.atan2(d.x, d.z), math.asin(math.max(-1, math.min(1, d.y / l)))
end
local function dirOf(yaw, pitch)
  return btVector3(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch))
end
local function ease(t) if t < 0.5 then return 4 * t * t * t end local u = -2 * t + 2; return 1 - u * u * u / 2 end
local function startFlight(pos1, look1, direct)
  local c = realV.cam
  local pos0 = c.pos
  -- the way: the camera, the aisle beside it, (round any corner,) the aisle
  -- beside the next stop, the stop; heights in between from one to the other
  -- (direct: stepping in or back at an exhibit, straight there)
  local raw = direct and {} or route(pos0, pos1)
  local pts = { pos0 }
  for i, p in ipairs(raw) do
    local f = i / (#raw + 1)
    pts[#pts + 1] = btVector3(p.x, pos0.y + (pos1.y - pos0.y) * f, p.z)
  end
  pts[#pts + 1] = pos1
  -- (a point too near the last, or an aisle point at the same place on the
  -- floor as the end -- right under a view's camera, say -- left out:
  -- arriving there along the aisle, the curve would overshoot the end)
  local function flat(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) end
  local way = { pts[1] }
  for i = 2, #pts do
    local last = way[#way]
    local keep = (pts[i] - last):length() > 40 and flat(pts[i], last) > 40
    if i < #pts and flat(pts[i], pts[#pts]) < 40 then keep = false end
    if keep or i == #pts then way[#way + 1] = pts[i] end
  end
  -- along it, in small pieces, measured
  local S, L = { way[1] }, { 0 }
  for i = 1, #way - 1 do
    local a, b, cc, d = way[math.max(i - 1, 1)], way[i], way[i + 1], way[math.min(i + 2, #way)]
    for k = 1, 24 do
      local p = inside(catmull(a, b, cc, d, k / 24))
      L[#L + 1] = L[#L] + (p - S[#S]):length()
      S[#S + 1] = p
    end
  end
  local total = L[#L]
  if FLY_LOG then
    local zl, zh, xl, xh = 1e9, -1e9, 1e9, -1e9
    for _, p in ipairs(S) do zl, zh, xl, xh = math.min(zl, p.z), math.max(zh, p.z), math.min(xl, p.x), math.max(xh, p.x) end
    local line = string.format("FLY %d points; x %.0f to %.0f, z %.0f to %.0f (walls: z %.0f to %.0f)", #way, xl, xh, zl, zh, ZN, ZS)
    print(line)
    if FLY_LOG ~= "1" then local fh = io.open(FLY_LOG, "a"); if fh then fh:write(line, "\n"); fh:close() end end
  end
  local yaw0, pitch0 = yawPitch(c.dir)
  local yaw1, pitch1 = yawPitch(look1 - pos1)
  local dy = (yaw1 - yaw0 + math.pi) % (2 * math.pi) - math.pi        -- (the short way round)
  flight = { S = S, L = L, total = total, t0 = realV:getTime(),
             T = math.max(1.2, math.min(3.5, 0.6 + total / FLY_SPEED)),
             yaw0 = yaw0, dyaw = dy, pitch0 = pitch0, dpitch = pitch1 - pitch0, pos1 = pos1, look1 = look1 }
end
local function stepFlight()
  local f = flight
  if not f then return end
  local c = realV.cam
  local t = (realV:getTime() - f.t0) / f.T
  if t >= 1 then
    flight = nil
    c.pos = f.pos1
    c:setUpVector(btVector3(0, 1, 0), true)
    c.look = f.look1                -- (in that order: the look turns the view from where it now is)
    return
  end
  local u = ease(math.max(0, t))
  local s = u * f.total
  local i = 2
  while i < #f.L and f.L[i] < s do i = i + 1 end
  local span = f.L[i] - f.L[i - 1]
  local w = span > 0 and (s - f.L[i - 1]) / span or 1
  local p = f.S[i - 1] + (f.S[i] - f.S[i - 1]) * w
  c.pos = p
  c:setUpVector(btVector3(0, 1, 0), true)     -- (upright first: the look keeps the horizon level)
  c.look = p + dirOf(f.yaw0 + f.dyaw * u, f.pitch0 + f.dpitch * u) * 100
end
-- the camera to a stop: flown there, or put there at once (instant: as the
-- hall starts, and with HALL_FLY=0)
local function moveCam(pos, look, instant, direct)
  -- (flown: from the way it looks now, the flight keeping it upright as it
  -- goes; standing it upright first turned it level, and the flight then
  -- began by looking up)
  if FLY_ON and not instant then startFlight(pos, look, direct); return end
  flight = nil
  local c = realV.cam
  c:setUpVector(btVector3(0, 1, 0), true)
  c.pos = pos
  c.look = look            -- (in that order: the look turns the view from where it now is)
end

local function goTo(s, instant, stepIn)
  -- let go of any keys still held at the exhibit we're leaving (its world
  -- then waits, untouched, until you come back)
  if active then
    active.lecternBack = nil
    local f = active.callbacks.onKey
    for key in pairs(active.down) do if f then pcall(f, active.N, key, false) end end
    active.down = {}
    -- (and tell it you're leaving, if it asked: v:onLeave)
    f = active.callbacks.onLeave
    if f then local ok, err = pcall(f, active.N); if not ok then print("HALL: " .. active.name .. " onLeave: " .. tostring(err)) end end
  end
  local same = here == s or (here.group ~= nil and here.group == s.group)   -- (stepping in or back, or on to another way, at the same exhibit)
  here = s
  steppedIn = (stepIn and not s.isView and s.approach) and s or nil
  pcall(function() realV.statusText = (not s.isView and s.ready and s.statusText ~= nil and s.statusText ~= "" and s.statusText) or hallStatus end)
  resetMeter(realMs())
  lastShown = nil          -- (walking on isn't a freeze)
  -- (and where you are as a slider, "Gallery: stop": bpp's Restart runs the
  -- hall again from the start, then puts every slider back as it was --
  -- this one included, which brings you back here. Drag it to jump.)
  local i = indexOf(s)
  if i and stopShown ~= i then
    stopShown = i
    realV:addParam(STOP_PARAM, i, 1, #stops, 1,
                   "where you are: 1 the entrance, then on round (Tab, Shift+Tab); drag to go there")
  end
  if not s.isView and s.ready then showMode(s) end
  if not s.isView and not s.ready then
    -- (not loaded yet: its bay from the aisle; it comes to life when it has)
    active = nil
    realV:useWorld(0)
    applyTiming(IDLE)
    if realV.showParams then realV:showParams("Hall: ") end
    realV.showConstraints = false
    for k in pairs(LIGHTS) do applyLight(nil, k) end
    moveCam(s.bayView.pos, s.bayView.look, instant)
    realV:setHelpText(s.header() .. (s.failed and ("It didn't load: " .. s.failed) or
                      "Being set up: it appears in a moment (the status bar says what is loading)."))
    return
  end
  if s.isView then
    active = nil
    realV:useWorld(0)
    applyTiming(IDLE)
    -- (the Params pane: none of the exhibits' sliders)
    if realV.showParams then realV:showParams("Hall: ") end
    -- (bpp's markers on joints: not in the hall views)
    realV.showConstraints = false
    for k in pairs(LIGHTS) do applyLight(nil, k) end          -- (the hall's lights)
    moveCam(s.pos, s.look, instant)
    realV:setHelpText(hallHelp(s))
  else
    active = s
    realV:useWorld(s.world)
    setRandom(s)
    applyTiming(s.timing)
    -- (the Params pane: only this exhibit's sliders)
    if realV.showParams then realV:showParams(s.prefix) end
    -- (and bpp's markers on joints as the exhibit has them: on, unless it
    -- turns them off)
    realV.showConstraints = s.vset.showConstraints ~= false
    for k in pairs(LIGHTS) do applyLight(s, k) end            -- (its lights, as on its own)
    if s.approach and steppedIn ~= s then
      moveCam(s.approach.pos, s.approach.look, instant, same)      -- (walking up: the table and its lectern)
    else
      local view = s.view
      local pos = view.pos or btVector3(0, 150, 200)
      local look = view.look or btVector3(0, 0, 0)
      moveCam(s.toScene(pos), s.toScene(look), instant, same)
    end
    realV:setHelpText(s.wrapHelp(s.help))
    -- (and tell it you've come, if it asked: v:onEnter)
    local f = s.callbacks.onEnter
    if f then local ok, err = pcall(f, s.N); if not ok then print("HALL: " .. s.name .. " onEnter: " .. tostring(err)) end end
  end
end

-- ---------------------------------------------------------------------
-- passing things on to the exhibit you're at
-- ---------------------------------------------------------------------
local function report(g, k, err)
  print("HALL: " .. g.name .. " " .. k .. ": " .. tostring(err))
  g.callbacks[k] = nil              -- (said once, not every frame)
end
local function callActive(k)
  local g = active
  if not g then return end
  local f = g.callbacks[k]
  if f then
    local ok, err = pcall(f, g.N)
    if not ok then report(g, k, err) end
  end
end

-- (each frame timed for the meter: the exhibit's preSim, less the steps it
-- takes itself, is its scripts; from there to postSim is bpp's own step)
local tStep = nil
local function meterLine(t)
  local el = (t - meter.t0) / 1000
  local n, d = math.max(meter.frames, 1), math.max(meter.draws, 1)
  local phys, scripts, gc, draw = meter.phys / n, meter.scripts / n, meter.gc / d, meter.draw / d
  local fps = meter.draws / el
  local busy = (meter.frames > 0 and phys + scripts or 0) + gc + draw
  local where
  if not active then where = "at " .. here.name .. ": nothing is stepped"
  else
    where = string.format("at %s: resting (not stepping) in %.0f%% of the frames", active.name,
                          100 * meter.resting / n)
  end
  return string.format("HALL METER -- ms per frame, averaged over the last %.0f s (the \"Hall: meter\" slider: off)\n" ..
                       "  %.0f frames a second; %s\n" ..
                       "  physics %.2f   scripts %.2f   garbage %s   drawing %.2f\n" ..
                       "  busy    %.1f ms of each %.1f ms frame (%.0f%%); longest frame %.0f ms\n" ..
                       "  outside the hall's code %.1f ms a frame (bpp itself, the graphics driver, waiting for the screen)\n",
                       el, fps, where, phys, scripts, GC_BUDGET > 0 and string.format("%.2f", gc) or "(Lua's own)", draw, busy, 1000 / math.max(fps, 1),
                       100 * busy * fps / 1000, meter.longest, math.max(0, 1000 / math.max(fps, 1) - busy))
end
realV:preSim(function(N)
  local t = now()
  if active then
    active.N = active.N + 1
    local p0 = meter.phys
    callActive("preSim")
    if active then applyTiming(active.timing) end
    meter.scripts = meter.scripts + (now() - t) - (meter.phys - p0)
    if active and active.timing.timeStep == 0 then meter.resting = meter.resting + 1 end
  end
  tStep = now()
end)
realV:postSim(function(N)
  loadSome()
  local t = now()
  if tStep and active then meter.phys = meter.phys + (t - tStep) end
  meter.frames = meter.frames + 1
  callActive("postSim")
  meter.scripts = meter.scripts + (now() - t)
  collectSome()
  if keysStep then keysStep(N) end
end)
local tDraw = nil
realV:preDraw(function(N)
  stepFlight()
  callActive("preDraw")
  tDraw = now()
end)
realV:postDraw(function(N)
  local t = now()
  if tDraw then meter.draw = meter.draw + (t - tDraw); meter.draws = meter.draws + 1 end
  callActive("postDraw")
  local w = realMs()
  if lastShown then
    local gap = w - lastShown
    meter.longest = math.max(meter.longest, gap)
    if METER and FREEZE_LOG_MS > 0 and gap > FREEZE_LOG_MS and meter.t0 and w - meter.t0 > 0 then
      print(string.format("HALL: a %.0f ms freeze, ending at %s", gap, os.date("%H:%M:%S")))
    end
  end
  lastShown = w
  if METER then
    if not meter.t0 then resetMeter(w)
    elseif w - meter.t0 >= METER_PRINT * 1000 then
      local line = meterLine(w)
      print(line)
      if METER_FILE then
        local fh = io.open(METER_FILE, "a")
        if fh then fh:write(os.date("%H:%M:%S "), line, "\n"); fh:close() end
      end
      resetMeter(w)
    end
  end
end)

-- ---------------------------------------------------------------------
-- F3: find an exhibit. Type part of its name (any of its ways', a view's)
-- or its number, the "Hall: stop" slider's; the status line shows the
-- match, Tab and Shift+Tab the next and the one before; Return goes there,
-- Esc or F3 again leaves it. Every key is the finder's meanwhile.
-- ---------------------------------------------------------------------
local function plain(t) return (t:lower():gsub("[^%w ]", "")) end
local function finderMatches(q)
  local out = {}
  if q:match("^%d+$") then
    local s = stops[tonumber(q)]
    if s then out[1] = s end
    return out
  end
  q = plain(q)
  for _, s in ipairs(stops) do
    if q == "" or plain(s.name):find(q, 1, true) then out[#out + 1] = s end
  end
  return out
end
local function finderShow()
  local f = finder
  f.matches = finderMatches(f.query)
  f.pick = math.max(1, math.min(f.pick, #f.matches))
  local m = f.matches[f.pick]
  local line = "FIND: " .. f.query .. "_   " ..
    (m and ("-> " .. indexOf(m) .. " " .. m.name ..
            (#f.matches > 1 and string.format("  (%d of %d: Tab, Shift+Tab)", f.pick, #f.matches) or "") ..
            ";   Return: go there")
       or "(no exhibit has that in its name)") .. ";   Esc: never mind"
  pcall(function() realV.statusText = line end)
  local rows = { "FIND AN EXHIBIT: type part of its name, or its number; Return goes there,",
                 "Tab and Shift+Tab pick among the matches, Backspace takes a letter off,",
                 "Esc (or F3) leaves it.", "" }
  local shown = {}
  for _, x in ipairs(f.matches) do shown[x] = true end
  for i, x in ipairs(stops) do
    if shown[x] then
      rows[#rows + 1] = string.format("%s %2d  %s", x == m and "->" or "  ", i, x.name)
    end
  end
  realV:setHelpText(table.concat(rows, "\n"))
end
local function finderClose(go)
  local m = go and finder.matches[finder.pick]
  finder = nil
  if m and m ~= here then
    goTo(m)
  else
    -- (as it was: the status line and the pane of where you are)
    pcall(function() realV.statusText = (active and active.statusText ~= "" and active.statusText) or hallStatus end)
    if here.isView then realV:setHelpText(hallHelp(here))
    elseif here.ready then realV:setHelpText(here.wrapHelp(here.help)) end
  end
end
local function finderKey(key)
  local f = finder
  -- (a new query starts at its first match; none at all, at where you are)
  local function typed(q) f.query = q; f.pick = (q == "" and indexOf(here)) or 1; finderShow() end
  if key == "Esc" or key == "Escape" or key == "F3" then finderClose(false)
  elseif key == "Return" or key == "Enter" then finderClose(true)
  elseif key == "Backspace" then typed(f.query:sub(1, -2))
  elseif key == "Tab" or key == "Backtab" then
    if #f.matches > 0 then f.pick = (f.pick - 1 + (key == "Tab" and 1 or -1)) % #f.matches + 1 end
    finderShow()
  elseif key == "Space" then typed(f.query .. " ")
  elseif #key == 1 and key:match("[%w']") then typed(f.query .. key:lower())
  end
end

local HELD_BACK = { S = true, D = true, R = true, P = true }
local function hallKey(N, key, down)
  -- (the finder has every key while it's open)
  if finder then
    if down then finderKey(key) end
    return true
  end
  if key == "F3" then
    if down then
      finder = { query = "", pick = indexOf(here) or 1 }
      -- (let go of the exhibit's held keys, as when walking on)
      if active then
        local f = active.callbacks.onKey
        for k in pairs(active.down) do if f then pcall(f, active.N, k, false) end end
        active.down = {}
      end
      finderShow()
    end
    return true
  end
  if key == "BracketRight" or key == "]" or key == "BracketLeft" or key == "[" then
    if down then goTo(nextExhibit(here, (key == "]" or key == "BracketRight") and 1 or -1)) end
    return true
  end
  if key == "Tab" or key == "Backtab" then
    -- (an exhibit with an approach is two stops: walking up to it, then
    -- stepping in; Shift+Tab the same, the other way)
    if down then
      local at = not here.isView and here.approach
      if key == "Tab" then
        if at and steppedIn ~= here then goTo(here, false, true)
        else goTo(nextStop(here, 1)) end
      else
        if at and steppedIn == here then goTo(here, false, false)
        else local p = nextStop(here, -1); goTo(p, false, p.approach ~= nil) end
      end
    end
    return true
  end
  local g = active
  -- (PgDn, PgUp: its label's pages; unless the exhibit uses them itself)
  if (key == "PgDown" or key == "PgUp") and g and g.pages and #g.pages > 1 and not g.shortcuts[key] then
    if down then
      local n = (g.page or 1) + (key == "PgDown" and 1 or -1)
      n = math.max(1, math.min(#g.pages, n))
      if n ~= g.page then
        showPage(g, n)
        realV:setHelpText(g.wrapHelp(g.help))
      end
    end
    return true
  end
  -- (I: its lectern close up, and back; unless the exhibit has I itself)
  if key == "I" and g and g.lecternView and not g.shortcuts[key] then
    if down then
      if g.lecternBack then moveCam(g.lecternBack.pos, g.lecternBack.look); g.lecternBack = nil
      else
        local c = realV.cam
        local p, l = c.pos, c.look                 -- (copies: the camera's own would follow it)
        g.lecternBack = { pos = btVector3(p.x, p.y, p.z), look = btVector3(l.x, l.y, l.z) }
        moveCam(g.lecternView.pos, g.lecternView.look)
      end
    end
    return true
  end
  -- (H: the manual of the exhibit you're at, in the PDF viewer, or at the
  -- views the hall's own guide; unless the exhibit has H itself. F1 does
  -- the same everywhere: no exhibit uses it, so the Pascaline's and the
  -- Digi-Comp II's manuals, whose H is their own, open with it)
  if (key == "H" and not (g and g.shortcuts[key])) or key == "F1" then
    if down then
      if here.isView then MANUAL.open(HERE, "the hall's guide")
      else MANUAL.open(here.dir, here.name, here.e.manual) end
    end
    return true
  end
  if not g then
    if key == "P" then
      if down then print("HALL: P (save every frame for POV-Ray) is held back here; use the POV-Ray menu.") end
      return true
    end
    return false
  end
  local sc = g.shortcuts[key]
  if sc then
    if down then
      local ok, err = pcall(sc, g.N)
      if not ok then print("HALL: " .. g.name .. " key " .. key .. ": " .. tostring(err)) end
    end
    return true
  end
  local f = g.callbacks.onKey
  local used = false
  if f then
    if down then g.down[key] = true else g.down[key] = nil end
    local ok, r = pcall(f, g.N, key, down)
    used = ok and r
  end
  -- bpp's own one-letter keys (S stop, D sleeping, R reload, P POV-Ray)
  -- would change the whole hall: at an exhibit they do only what it uses
  -- them for
  if not used and HELD_BACK[key] then return true end
  return used
end
realV:onKey(hallKey)

-- (HALL_KEYS: keys pressed at given frames, for trying the hall's keys
-- headless: "300:F3,l,o,c,k,Return;900:]" presses F3, l, o, c, k and Return
-- at frame 300, ] at 900, and prints where each leaves you)
local KEYS_AT = {}
for at, list in (os.getenv("HALL_KEYS") or ""):gmatch("(%d+):([^;]+)") do
  local keys = {}
  for k in list:gmatch("[^,]+") do keys[#keys + 1] = k end
  KEYS_AT[tonumber(at)] = keys
end
local keyFrame = 0
if next(KEYS_AT) then keysStep = function(N)
  keyFrame = keyFrame + 1
  local keys = KEYS_AT[keyFrame]
  if not keys then return end
  for _, k in ipairs(keys) do
    if #k == 1 then k = k:upper() end                 -- (bpp names a letter's key by its capital)
    hallKey(N, k, true); hallKey(N, k, false)
  end
  local f = finder
  print(string.format("HALL: keys at frame %d (%s): at %s%s", keyFrame, table.concat(keys, " "), here.name,
                      f and string.format("; finding \"%s\": %s (%d of %d)", f.query,
                                          f.matches[f.pick] and f.matches[f.pick].name or "none", f.matches[f.pick] and f.pick or 0, #f.matches) or ""))
end end

realV:onParamChanged(function(N, name, value)
  if name == METER_PARAM then
    local on = value >= 0.5
    if on ~= METER then
      METER = on
      meter.t0 = nil                       -- (it starts counting afresh)
      print("HALL: the meter is " .. (on and "on: a line every " .. METER_PRINT .. " s" or "off"))
    end
    return
  end
  if name == STOP_PARAM then
    local i = math.max(1, math.min(#stops, math.floor(value + 0.5)))
    stopShown = i
    if stops[i] ~= here then goTo(stops[i]) end
    return
  end
  for _, g in ipairs(exhibits) do
    local p = g.prefix
    if name:sub(1, #p) == p then
      local f = g.callbacks.onParamChanged
      if f then
        -- (in its own world; the one you're at gets its random numbers back)
        local ok, err = inWorld(g, f, g.N, name:sub(#p + 1), value)
        if not ok then print("HALL: " .. g.name .. ": " .. tostring(err)) end
        if active and active ~= g then setRandom(active) end
      end
      return
    end
  end
end)

-- hover: the hall's own placards, else whichever exhibit knows the thing
if realV.onHover then
  realV:onHover(function(N, obj, x, y, z)
    if objectKey then
      local t = HOVER[objectKey(obj)]
      if t then return t end
    end
    for _, g in ipairs(exhibits) do
      local f = g.callbacks.onHover
      if f then
        local p = g.toLocal(btVector3(x, y, z))
        local ok, r = pcall(f, g.N, obj, p.x, p.y, p.z)
        if ok and r then return r end
      end
    end
    return nil
  end)
end

if realV.onePerFrame ~= nil then realV.onePerFrame = true end
realV:addParam(METER_PARAM, METER and 1 or 0, 0, 1, 1, "the cost meter in the console every " .. METER_PRINT .. " s: 1 on, 0 off")
-- (START: begin at that exhibit's name, for trying one out)
local START = os.getenv("HALL_START")
if START then
  for _, g in ipairs(all) do if g.name:lower():find(START:lower(), 1, true) then here = g; break end end
  if START == "end" then here = VIEW_B end
end
goTo(here, true)
print(string.format("HALL: %d exhibits to set up, %d in preparation, %d empty bays; the nave %.0f m long",
                    #all, nCovered, #BAYS - #EXHIBITS, (ZS - ZN) / 100))

-- the exhibits loaded, one a frame from the second on (the hall is shown
-- first): next, the one you're at or walking to, else the next one on
-- from where you are
local hallFrames = 0
local function status(t)
  hallStatus = t
  if not finder then pcall(function() realV.statusText = (active and active.statusText ~= "" and active.statusText) or t end) end
end
local function nextToLoad()
  if not here.isView and here.pending then return here end
  local i = indexOf(here) or 1
  for k = 1, #stops do
    local s = stops[(i - 1 + k) % #stops + 1]
    if s.pending then return s end
  end
end
-- (up to MAX_LOADS exhibits loading at once, their parts building side by
-- side; one more started each frame; the one you're at always started)
local MAX_LOADS, underWay, allShown = 3, {}, false
local function loaded(g)
  lastShown = nil                                  -- (loading isn't a freeze)
  if here == g then goTo(g, not FLY_ON, steppedIn == g)   -- (you're there: it comes to life)
  elseif active then setRandom(active) end
end
-- (HALL_TRACE=file: a line a second, the frames drawn and the status, to
-- see how the hall keeps up while it sets up; in a window, as headless
-- runs print)
local TRACE = os.getenv("HALL_TRACE") and io.open(os.getenv("HALL_TRACE"), "w")
local traceT0, traceLast, traceFrames = realMs(), 0, 0
loadSome = function()
  hallFrames = hallFrames + 1
  if TRACE then
    traceFrames = traceFrames + 1
    local t = (realMs() - traceT0) / 1000
    if t - traceLast >= 1 then
      TRACE:write(string.format("%6.1f s  %3d frames  %s\n", t, traceFrames, allShown and "(all set up)" or hallStatus))
      TRACE:flush()
      traceLast, traceFrames = t, 0
    end
  end
  if hallFrames < 2 or allShown then return end
  -- those under way, on as far as they can go
  local still = {}
  for _, g in ipairs(underWay) do
    if resumeLoad(g) then loaded(g) else still[#still + 1] = g end
  end
  underWay = still
  -- one more, if there's room (or if it's the one you're at)
  local g = nextToLoad()
  if g and (#underWay < MAX_LOADS or g == here) then
    startLoad(g)
    if resumeLoad(g) then loaded(g) else underWay[#underWay + 1] = g end
  end
  local n = 0
  for _, x in ipairs(all) do if x.ready or x.failed then n = n + 1 end end
  if #underWay > 0 or nextToLoad() then
    local names = {}
    for _, x in ipairs(underWay) do names[#names + 1] = x.name end
    local building = openscadBuilds and openscadBuilds() or 0
    status(string.format("Setting up %s (%d of %d ready)%s", #names > 0 and table.concat(names, ", ") or "the exhibits",
                         n, #all, building > 0 and string.format("; OpenSCAD building %d part%s", building, building == 1 and "" or "s") or ""))
  else
    allShown = true
    status("")
    if here.isView then realV:setHelpText(hallHelp(here)) end
    print(string.format("HALL: %d exhibits on show, %d in preparation, %d empty bays",
                        #exhibits, nCovered, #BAYS - #EXHIBITS))
  end
end
