# Handoff: Babbage's Hall

`HANDOFF.pdf` beside this file is a typeset copy of it.

Read this first in a new chat. It says how William likes to work, where
everything is, how to build and test, what has been learned, and what to do
next. The list of machines is `MACHINES.md`; the hall itself is described in
`README.md`. This file is updated whenever a chat ends.

## 1. What this is

- **Babbage's Hall** (`demo/WyomingWill/BabbagesHall/`), a Victorian
  engineering hall in the Bullet Physics Playground (bpp,
  **github.com/bullet-physics-playground/bpp**; William pushes to the branch
  **`test-harness`** (since 2026-11-11), which Jakob merges into `master`): cast iron,
  brass, a glass roof, holding **machines that compute**. A separate museum
  from William's Euler's Gallery (`../EulersGallery/`), built on its
  machinery (separate worlds, sandboxes, walking with Tab).
- **Every machine can be 3D printed and built.** Each exhibit's parts are
  OpenSCAD sources (the single source for the simulation and the prints), a
  `make-stls.sh` makes the STL files, and its README lists what to buy and
  how to assemble it. What is printed is what is simulated: no shortcuts in
  the parts that compute, and anything idealised is said on the placard and
  in FINDINGS.
- **The walk asks more of you as you go:** from what asks least (one idea,
  little mechanism) to what asks most, Babbage's Difference Engine at the
  far end. `MACHINES.md` has the order and why (re-ordered 2026-11-14:
  it was by interest alone).
- Built so far, in walking order: **the suanpan** (west 1, since
  2026-11-15), **the slide rule** (east 1, since 2026-11-16), **Napier's bones** (west 2, since 2026-11-16), **the combination lock** (east 2, since 2026-11-19), **the bead sort** (west 3, since 2026-11-22; its second way, the spaghetti sort, since 2026-11-24),
  **the Domino Half Adder** (east 3), **the slide adder** (west 4, since
  2026-11-25), **the linkages** (east 4, facing it, since 2026-11-26:
  Peaucellier's inverter; Tab: his straight line, a multiplier),
  **the Differential** (west 5), **the
  Pascaline** (east 5), **the Galton
  board** (west 6, since 2026-11-12), **the splitter board** (east 6,
  facing it, since 2026-11-14), **Lehmer's number sieve** (east 7), and
  the **Digi-Comp II** (west 8: it counts, adds, multiplies,
  subtracts and divides, runs programs, and in AUTO runs a multiply by
  itself, or a division to OVERFLOW's halt; its weight and fly are parts:
  a cup of balls and a bought rotary damper; each program has only its
  parts on the board, and the operator's hand is shown).
  Covered bays wait for Amsler's planimeter (west 7:
  after the splitter board, so that it and the Galton board still face
  each other), Kelvin's tide predictor (east 8), the Differential Analyser
  (west 9) and the Difference Engine (east 9): eighteen bays, nine pairs.
- William M. Spears (`williammspears@gmail.com`) owns the WyomingWill demos;
  Jakob (koppi) wrote bpp. Clocks are William's own separate collection.

## 2. How William likes to work

- **Deliver every change as a patch plus the git commands.** He applies
  patches in a checkout called `bpp-push`, pushes, then pulls in his
  installation checkout (which has `pull.ff only`; never apply patches
  there). Give the commands as below, and say if bpp must be rebuilt (only
  when C++ changed).

```
git pull
git am ~/Downloads/<name>.patch
git push
```

- **Every patch includes all its documents, PDFs too.** Every `.md` has a
  typeset `.pdf` beside it (`./make-pdfs.sh`, or `tools/md2pdf.py` for
  one); rebuild the PDF whenever its `.md` changes. Euler's Gallery and the
  Rec Room have README.pdfs made with `../ArtificialPhysics/tools/md2pdf.py`.
- **Build patches on `origin/test-harness`**, where he pushes (a clone
  fetches only `master`: `git fetch origin
  test-harness:refs/remotes/origin/test-harness`). To check something
  landed, look there, not on `master`.
- **Before sending a patch:** check it applies to the current
  `origin/test-harness` (fetch first; a patch built on one he hasn't
  applied fails, as the first `MACHINES.md` patch did); no trailing spaces (`git diff --check`);
  `tools/check-all.sh` passes; the visuals looked at (`tools/shots.sh`). A
  re-sent patch gets a new file name, so a stale download can't be applied.
- Commits are authored `William M. Spears <williammspears@gmail.com>`, with
  the Co-Authored-By trailer for Claude. Stage only the files you changed.
- He looks at the exhibits in the GUI and reports what he sees with
  screenshots: take his reports seriously and reproduce them before
  answering, and measure when the pictures don't settle it.
- Plain explanations; measure before claiming; say what was and wasn't
  tested.
- **His bpp is built with Lua 5.2;** a cloud workspace's is usually 5.1.
  Write Lua that runs on both: no bare `setfenv`/`getfenv` (give
  `loadfile` its environment with `"t", _ENV` on 5.2, as the exhibits'
  table loaders do), no `goto`. `tools/check-lua52.sh` checks the one place
  this has bitten (the table loader) under a standalone `lua5.2`.

## 3. Where everything is

| Path | What |
|---|---|
| `hall.lua` | The hall: architecture, the EXHIBITS list (walking order, placards, `floorY`), sandboxes, walking and camera flights, resting, the cost meter |
| `exhibit-table.lua` | The standard exhibit table (README "Exhibit standard") |
| `MACHINES.md` | All 50 machines considered, in walking order (five tiers), scored for interest and complexity, with how each would go in bpp and be printed; the rope test |
| `README.md` | The hall: bays, keys, how it works, the cost meter, the exhibit standard, notes for exhibit authors |
| `HANDOFF.md` | This file |
| `make-pdfs.sh`, `tools/md2pdf.py` | The PDFs |
| `make-labels.py`, `make-lecterns.py`, `hall-meshes/` | The placards' lettering (Pillow, NumPy, DejaVu fonts); the lecterns' cards (PNG) |
| `tools/check-all.sh` | Every exhibit's tour, on its own and in the hall |
| `tools/shots.sh`, `tools/keys.sh` | Screenshots on a virtual screen; with keys, hover, camera flights |
| `tools/check-lua52.sh` | The Lua 5.2 sandbox check |
| `tools/rope-test.lua` | The rope experiment (for the tide predictor) |
| `exhibits/NapiersBones/bones-test.lua` | Napier's set (every four-digit number laid), and both ways (Napier's, Genaille's) against plain arithmetic (`lua bones-test.lua`, from its folder) |
| `exhibits/SlideRule/rule-test.lua` | The slide rule's plans against arithmetic, with the parts placed exactly and off by up to 0.2 mm (`lua rule-test.lua`, from its folder) |
| `exhibits/CombinationLock/lock-test.lua` | The lock's model against all 1,000,000 combinations: which the dialling rules set, the forbidden zone, the tolerance, the 27 that open a lock; the safecracker's method on 40 random locks (`lua lock-test.lua`, from its folder, 3.5 minutes) |
| `exhibits/DigiComp2/tests/toggle.lua`, `tests/switch.lua`, `tests/junction.lua` | One Digi-Comp flip-flop alone (with its foot, done hole and clear lane); one switch; the piece of board where the memory meets the accumulator |
| `exhibits/DigiComp2/MANUAL.md`, `manual/` | The Digi-Comp's illustrated manual; `manual/make-figures.sh` redraws its figures from the geometry (lua, python3, matplotlib). `tools/md2pdf.py` puts a `.md` file's images into its PDF |
| `exhibits/SlideAdder/manual/make-figures.py` | The slide adder's manual figures, from its sizes |
| `exhibits/Linkages/manual/make-figures.py` | The linkages' manual figures (the cell, the line, the multiplier's triangles), from their sizes |
| `exhibits/BeadSort/spaghetti-sort.lua` | The bead sort's second way (`BS_WAY=spaghetti`: `bead-sort.lua` hands over to it); `BS_TILT` tilts its palm, a test |
| `exhibits/<Name>/` | One folder per exhibit: its script, `parts/` (OpenSCAD), `make-stls.sh`, `README.md`/`.pdf`, `FINDINGS.md`/`.pdf` |

Related: `../EulersGallery/` (the gallery the hall's machinery came from;
its tables still follow its own sizes, see §7), `../RecRoom/` (games room:
the cost meter and suspending came from there), `demo/claude/digicomp.lua`
(an incomplete Digi-Comp II, a starting point), `module/scad/gearsv50.lua`
and the Differential's `parts/gearsv50.scad` (bevel gears).

## 4. Building, running, testing

```
git clone https://github.com/bullet-physics-playground/bpp ~/bpp && cd ~/bpp
apt-get update
apt-get install -y libbullet-dev libluabind-dev liblua5.1-0-dev liblua5.2-dev \
  libqglviewer-dev-qt5 libsdl2-mixer-dev libassimp-dev qtbase5-dev libglew-dev \
  xvfb xdotool imagemagick openscad lua5.2 povray
pip install --break-system-packages trimesh manifold3d markdown playwright
mkdir -p build && cd build && qmake ../bpp.pro CONFIG+=release && make -j2 release
```

That gives `build/release/bpp` (a few minutes to ten). The tools find it
there, in `release/`, or on the path; or set `BPP`.

- **Headless:** from the top folder,
  `build/release/bpp -f demo/WyomingWill/BabbagesHall/hall.lua -n 600`.
  `HALL_START=pascaline` starts at an exhibit. The exhibits run on their own
  the same way, each with a tour that prints `RESULT <name> tour: PASS`.
- **GUI on a virtual screen:** `tools/shots.sh` (see its header);
  `LIBGL_ALWAYS_SOFTWARE=1`, so drawing is slow and the simulation runs
  slower than real time there. In the GUI, `print` goes to bpp's console
  pane, not the terminal: write to a file (the meter's `HALL_METER_FILE`,
  the flights' `HALL_FLY_LOG=file`) to read it.
- **Printed parts:** each exhibit's `make-stls.sh` (OpenSCAD 2021.01 here;
  William's is newer: avoid `assign()` and `polyhedron(triangles=)`). Check
  every STL is one watertight solid (trimesh), and that parts don't overlap
  at rest (manifold3d); OpenSCAD renders pictures under `xvfb-run`.
- **POV-Ray:** `build/release/bpp -f ... -n 2 -e` writes `export/<script>/`
  (untracked; delete it after); render with
  `povray +I<script>.pov +K2 +W800 +H450 +L<bpp folder>`.

## 5. What has been learned (bpp and Bullet)

- **OpenSCAD parts** are cached by the text asked for, not by the files'
  contents: put a checksum of every file the part includes into the text
  (each exhibit's `checksum()`). Set `collides` before `v:add`, the
  transform after. A body's origin must be its centre of mass.
- **`polyhedron()` faces go clockwise seen from outside.** OpenSCAD 2021's
  CGAL forgave the other way when it joined pieces; William's newer
  OpenSCAD (Manifold) doesn't, and such a part comes out inside out: drawn
  with dark slivers when bpp's shadows are off (the shader hides it), and
  a bad STL. Check a new polyhedron's signed volume (trimesh, or
  manifold3d on its points). Fixed 2026-11-04 in the Differential's
  gears and the sieve's cam ring.
- **Two bpp processes building the same new part at once** can collide in
  the mesh cache: run tests one at a time after a part changes.
- **Gears:** mesh-on-mesh (GImpact) bevel teeth jam; a compound of convex
  hulls (one per tooth plus the body, from the same SCAD source) meshes
  well (`exhibits/Differential/FINDINGS.md`).
- **Hinge angles** (`getHingeAngle`) are clockwise-positive as seen down the
  hinge's axis, the opposite of a right-handed turn. A hinge's motor speed
  counts the same way as its angle (measured on the Digi-Comp's wheel).
- **A pin's friction** can be had from a hinge's motor held at no speed with
  a small impulse a step (`enableAngularMotor(true, 0, torque * step)`); the
  Digi-Comp's rockers use it, from PLA on PLA at the boss.
- **Over-centre parts** (a rocker whose centre of mass is above its pin) rest
  in a very shallow dip: with no friction they bounced back out of it, with
  pin friction they stop wherever they're left. Give them weight high up (the
  Digi-Comp's rockers have a steel ball pressed in) and test both extremes.
- **Walls as boxes** run past their ends by half their thickness if made
  `length + thickness` long, so the joints are solid: check where such an
  end meets a moving part (the Digi-Comp's feeder wheel rubbed two), or
  narrows a channel (two jammed the Digi-Comp's clear lane). Mitre a lane's
  walls at its bends (`laneWalls` in the Digi-Comp's geometry).
- **A ball pushing a part out of its way** pushes it only until it can
  squeeze past, which may be nowhere near where the part should end up: to
  push it all the way, guide the ball (the Digi-Comp's clear lane narrows
  beside each foot).
- **Two ways into one place:** trace the ball that comes in first (its
  position every frame) before giving the other one a way in; a ball
  rolling down a wall must pass under the ends of the walls above it with
  room for the ball (the Digi-Comp's joining funnels, `FINDINGS.md`).
  Lanes on one level can't cross: their order is fixed by where they start
  and end, so plan a board in a drawing of every wall first.
- **A part with holes** (the Digi-Comp's upper plate) is a static body of
  boxes round the holes, drawn not by them (`transparency = 1`) but by the
  OpenSCAD part. `transparency` near 0.35 draws a see-through plate well.
- **Luabind objects** from `v:eachContact` can't be compared with `==`; look
  them up as table keys (`names[obj]`).
- **Small steps:** the exhibits take 2400 steps a simulated second, stepped
  by hand in `preSim` (`common.setTiming(STEP, 0, STEP)`); the teeth and the
  dominoes need it. Sleeping is off for moving parts (state 4), so each
  exhibit **rests** (stops stepping) once nothing moves; it changes nothing
  computed.
- **Springs** that matter are simulated as the printed part: the Pascaline's
  detent is a body on a hinge turned back by the leaf's stiffness from PLA
  (3EI/L), and its working range of thickness was found by sweeping it.
- **A part driven by a weight through a damper** moves slowly wherever only
  a small force drives it: the Digi-Comp's escapement, whose pin must creep
  off the anchor's second finger, took up to 1.8 s to let go with the damper
  where the torque-and-cap had taken half a second. Measure such waits
  with the real drag, at both ends of its tolerance.
- **An object's `pos` (and `trans`) is its drawing's**, which follows its
  body only after a step: read a body that has just been placed from the
  body (`getCenterOfMassPosition()`).
- **`getCenterOfMassTransform()` is the body's own transform**, not a copy
  (and `getCenterOfMassPosition()` its own vector): keep a pose by copying
  it (`btTransform(tr:getRotation(), btVector3(p.x, p.y, p.z))`). Kept as
  is, it moves with the body (the Digi-Comp's parts were "put back" where
  they had been sent). An object's `.trans` is a copy.
- **Taking parts away finds hidden jobs.** A wall drawn as one part's may
  do another's work (the Digi-Comp's clear lane steered done balls; a
  done lane's wall was its hole's backstop). Test each reduced machine,
  in AUTO too: in MANUAL a ball stopped in the wrong place often still
  counts as done.
- **Impulses applied in `preSim` before a step** (a cord's pull, a drag)
  change a held body's velocity for an instant, until the step's contacts
  take it back: read speeds for "is it moving?" before applying them (the
  Digi-Comp's hand thought the held wheel was turning, and never began).
- **Rope:** none built in; a rope of beads on ball joints works if the rope
  isn't far lighter than what hangs on it (`MACHINES.md`, "Rope").
- **Mouse:** scripts get `onHover` (after half a second still, no button
  down) but no clicks; keys override bpp's own one-letter keys.
- `btTransform` has no `getOrigin` in bpp's Lua; `.trans`, `:mult` and
  `getCenterOfMassTransform` are what there is.
- **Compounds:** a `btCompoundShape` in bpp's Lua takes only a few dozen
  children (each costs one of luabind's few dependency slots; past them bpp
  stops with an assertion in `object_rep.cpp`). Build big bodies as trees
  of small compounds, neighbours together (Lehmer's sieve's `tree()`), and
  don't add and remove children over and over: move them
  (`updateChildTransform`), as the sieve's pegs do.
- **Cylinders:** bpp's Lua has `btCylinderShapeX` and `btCylinderShapeZ`
  but no constructor for the upright `btCylinderShape`: stand a Z one up.
- **Convex pieces** from a 2D outline: `exhibits/LehmerSieve/parts/make-geometry.py`
  (shapely's constrained triangulation, merged while convex); check that the
  pieces' areas add up to the outline's. Corners inside an outline cost
  pieces; draw holes and inner arcs coarser for the contacts than for the
  print.
- **An OpenSCAD part made a body** must be set to collide before `v:add`
  (the exhibits' `part()` turns collisions off).
- `v:eachContact(fn)` calls `fn(a, b, x, y, z, nx, ny, nz, distance,
  impulse)` for every contact: the quickest way to find what jams.
- **Geneva drives** index well but their locking disc only bounds a star's
  turn (about a degree either way): a sprung detent per star puts it on its
  place, and the disc's relief must clear the star's lead and lag
  (`exhibits/LehmerSieve/FINDINGS.md`).
- `.gitignore` at the top ignores `*.scad`: the hall's own `.gitignore` has
  `!*.scad`, and STL files are not kept (each `make-stls.sh` makes them).

- **Balls in two dimensions jam** (the Galton board, `FINDINGS.md`): a
  hopper of balls between two plates, emptying through a neck, clogged at
  three balls wide and at five; a ball perched on a pin under the neck held
  up an arch or a zigzag column; taps (rocking the board) did not clear it.
  A neck wide enough flooded the pins, and the crowded balls spread far too
  wide. A slotted wheel metering one ball at a time is what worked.
- **A mechanism hands every ball on the same way,** and the result leans
  its way: the Galton board's one metering wheel made the first pin a switch
  (moving a chute 1.5 mm flipped the lean); a funnel and neck hid it, until
  the bounce was changed and the lean changed sides. William asked whether
  the setup was asymmetric: turning the wheel the other way swapped every
  lean. Two mirror-image wheels, geared, fixed it (the mean within about 0.3
  of 6 from a bounce of 0.3 to 0.55). If a result depends on a parameter
  that should only change its spread, look for an asymmetry; test by
  mirroring (`GB_LOG=3` shows how the balls leave the neck).
- **An invisible change is a different run.** Rewriting the Galton
  board's OpenSCAD sizes file (three empty lists added, nothing drawn
  differently) changed its tour's numbers (5.88/2.12 to 5.73/2.18); so
  does running it with an empty parts cache. The parts don't collide, but
  something about building them changes the order the solver meets the
  balls, and the board is chaotic. Neither run is wrong. Compare a change
  against the same cache, and keep a file's text unchanged when its
  meaning is. (bpp's commit 02f18d43, "Objects and constraints in the order
  added, not a QSet's", came in the same night and is probably the cause:
  a QSet's order follows memory addresses, which any new part moves. Not
  yet checked: rebuild and see whether the Galton tour's numbers change,
  and whether a cold cache still makes a difference.)
- **Check a document's length after a scripted edit.** A replace anchored
  on the wrong text cut this file from 616 lines to 330 in the
  mirror-wheels patch (2026-11-13): most of section 5's later lessons,
  all of section 6 and most of section 7 went, and nobody noticed for a
  day. Restored 2026-11-14 from the version before, the later edits merged
  back in (a three-way merge with the cut file as the base). `wc -l` and
  the list of headings before and after.
- **Fair is not independent** (the Galton board, `FINDINGS.md` section 6):
  each pin split the balls 50/50, yet the bins came out wider than the
  binomial. William guessed why: a ball leaving a pin carries a bias to the
  next. Recording each ball's path (`GB_PATHS`, `paths.py`) measured it: the
  same way again two times in three, the first pair 98%. A deader ball
  remembered more (damping would have been the wrong fix), and taller rows
  forgot but let balls jump pins; no setting tried beat the equilateral
  lattice. When a count is wrong but every single step looks fair, measure
  the correlations between steps.
- **A full container looks like a jam:** balls left at the slide's level
  were sitting on a heaped, full drawer, and knocking did nothing. Size a
  container for a heap, not for flat packing.
- **A smooth 60-degree wall is a ramp:** a ball at the edge of a pin
  lattice slid down it, squeezing past pins through gaps 0.5 mm too small
  (Bullet's soft contacts let it). Half pins standing out of the wall stop
  it. And a pin a little more than a ball's radius from a wall cradles a
  ball against it: leave it out and put a half pin on the wall.
- **Tall stacks of balls jitter** at 20 solver passes (5 to 6 cm/s at the
  bottom of 36 balls, the solver's, not a movement; 60 passes bring it to
  1): call such balls still below 8 cm/s rather than pay for more passes.
- **OpenSCAD outlines** that only touch a circle that is cut too (an outline
  run along a circle 1 mm inside it) leave slivers, and the extrusion "is not
  closed" (the walls of a whole tile went missing, silently, in an STL that
  was still watertight). Run such an outline well inside the circle, and
  check each tile's thickness, not only that it is watertight. Check the
  outlines for self-intersection when a size changes (a wider funnel's
  mouth went outside the walls it should meet).
- **`HALL_START`** lands on an exhibit's own view, not its first stop (the
  lectern); Shift+Tab from there goes to the previous exhibit. To see a first
  stop, start at the exhibit before and Tab (seen 2026-11-12 with the
  Pascaline and the Galton board alike).
- **A part that stands in for another must meet the ball as it does**
  (the splitter board's reflecting walls, `SPLITTERS.md`). A half tooth
  that was only a slope sent balls back to the wall three times in four:
  a ball dropping onto a 60-degree slope keeps its fall as speed, where
  one landing on a pin's round top loses it. Kept on its pin, with the
  neck's wall carried down so the ball lands on the pin's inner shoulder,
  it is fair. When a special part sits among ordinary ones, measure what
  balls do at the ordinary part *after* it.
- **A wall's piece can be a neck's wall too.** Leaving out the tooth at a
  reflecting wall's place in the rows no ball can reach yet took away the
  outer wall of the neck beside it, and every ball there went on to the
  wall. Build the special part only where it is needed; elsewhere keep
  the ordinary one.
- **A sizes file written from a table takes every number in it:** new
  options added as numbers to the splitter board's `G` went into
  `parts/splitter-geometry.scad`, which would have changed the default
  board's checksum, its parts and so its (chaotic) runs. Keep options that
  the default doesn't use in a sub-table (`G.refl`), and check with `git
  status` that a generated file is unchanged when its meaning is.
- **A board's other modes were drawn as the default** (found 2026-11-14):
  only the splitter board's default writes its sizes file, so `ruin` and
  `none` collided with their own walls but were drawn with the default's.
  `galton.lua` now hands such a board's sizes to OpenSCAD in the part's
  text, after the include (OpenSCAD's last assignment wins).
- **Don't edit files a background check is running.** check-all's
  splitter run, started before the reflecting walls, read the geometry
  half-edited (it passed, and rewrote the sizes file). Run check-all again
  on the finished code before sending.

- **A value C++ keeps remembers the Lua thread it was made on** (luabind):
  made in a coroutine, it was let go through a thread gone by then, and
  bpp crashed closing the script (`Object::preDestructor`). `luaHome()`
  (`src/luahome.h`) gives the value held from the main thread; every place
  that keeps a script's value uses it (an object's body and render
  function, sliders' callbacks, hover, keys).
- **Lua 5.1 can't yield across a C call**, `pcall` included (bpp runs 5.1,
  not LuaJIT). The hall's loads are coroutines, so while an exhibit loads
  its sandbox's `pcall` and `xpcall` run the call as a coroutine of their
  own and pass any wait on up; the sandbox's `dofile` and `require` were
  already plain Lua.
- **`bpp -n` never returns to Qt's event loop** (`main.cpp` calls
  `animate()` in a loop), so nothing there hears that a process has
  finished; and its frames cost nothing, so a fixed number of them would
  run out while parts built. There `openscadBuild` builds at once.
- **Waiting for a background command: look for what is on its command
  line.** A wait for `pgrep -f cold3`, a word that was only in the
  environment, returned at once, and a trace read mid-run looked like a
  crash; a second bpp then started on the same cache raced the first to
  rename the same parts (now harmless: a part another bpp finished counts).
- **bpp sizes its view to everything in the scene** (`computeBoundingBox`,
  every object, wherever it is drawn). The hall's first try at an
  exhibit's ways put the ways not shown a kilometre under the floor: the
  near limit of the view moved out past the exhibits and lecterns, which
  then weren't drawn at all (and the shadows went). Now they go 4 m down,
  and their objects onto a layer that isn't drawn (`Layer`,
  `setVisible(false)`, `o.layer`; nil puts one back), casting no shadows.
  Out of sight is not out of the scene.
- **OpenSCAD from a snap can't read `~/.cache`** (a snap may not open
  hidden folders in your home): "Can't open input file". Since
  74830071 bpp uses the OpenSCAD path set in its preferences, which it had
  been ignoring, so a snap set there weeks before failed the first time a
  new part was needed (2026-11-14, William's machine). Point the preference
  at a packaged OpenSCAD.
- **Set each part against the other as it stands** (the slide rule,
  2026-11-16). Its first plans put the cursor at the place a mark on the
  slide *would* be, from the plan's numbers: a slide left 10 mm short still
  read right. A person sets C's 1 under the hairline wherever it is, and the
  cursor to the mark wherever the slide is; done that way (`R.target`), an
  error in one part is carried into the reading. Wherever the script places
  a part relative to another, take the other's place from its body, not
  from the plan. A sweep that slows the operator down finds such things.
- **bpp's textures have no mipmaps** (linear filtering only): a texture far
  finer than the screen shimmers and drops lines. The slide rule's scales
  are 10 px a mm with no line under 1.5 px, and a close-up key (`M`) for
  reading.
- **Close up, in the hall, is 21 cm or more** (the slide rule's `M`,
  2026-11-16). bpp's near clipping plane follows the whole scene's size
  (QGLViewer: 0.005 × √3 × its radius): a camera 11 cm from a part, fine on
  its own, showed the table's underside in the 42 m hall. Stand farther
  off and narrow the view (`cam:setFieldOfView`; bpp leaves it at π/4, so
  put it back, on the key and in `v:onLeave`, which the hall calls as you
  walk on). And the hall's camera proxy turns `pos` and `look` into the
  bay but passes `setUpVector` through as it is: keep it (0, 1, 0).
- **bpp adds every body unable to sleep**, and Bullet's
  `setActivationState` won't undo that; `forceActivationState(1)` does
  (Napier's bones, 2026-11-16). Resting bodies there crept: Bullet's
  contact tolerances assume metres, and in centimetres a rod let go crept
  0.4 mm, the last one laid 2 mm in 15 s. A rod still for 2 s now sleeps
  (`setSleepingThresholds`), and the hand keeps the one it holds awake
  (`forceActivationState(4)`). Anything in the hall that should stay where
  it was put, at rest, can do the same.
- **A job that queues jobs must put them first**, not at the end of the
  queue (Napier's bones' `soon`): appended, they ran after the clearing
  the problem had already queued.
- **Scripts get hover, not clicks** (bpp gives `v:onHover`, no click
  hook; the Shortcuts pane is plain text, so no links). The manual opens on
  a key, `H` (and `F1`, which no exhibit uses: the Pascaline's `H` is its
  hundreds, the Digi-Comp II's its memory), through the system's opener (`open-manual.lua`: `xdg-open`,
  `open`, `start`; `MANUAL_OPENER` replaces it for testing). A click hook
  on objects would let the lectern itself be clicked: that is bpp's C++,
  for Jakob.
- **Size a container for its count's spread, not its expected count**: a
  tube holding 82 for an expected 75 overflows in about one run in six.
  And a test for "everything is still" must leave out what can't move on
  anyway (a tall stack in a tube jitters without moving).
- **A Lua tool under `demo/` needs a `.nomenu` beside it.** GitHub's CI
  runs every `.lua` under `demo/` in bpp ("smoke run of every demo"), and
  a plain-Lua helper (a manual's `manual/states.lua`, say) fails there. A
  folder holding an empty `.nomenu` is left out of the run and the Demos
  menu. check-all doesn't do this run; before pushing, run
  `python3 tests/harness.py --bpp build/release/bpp -k BabbagesHall smoke`
  from the top of the repository.
- **Don't edit `tools/check-all.sh` while it runs:** bash reads a script
  as it goes, so lines added above the one running shift what it reads
  next (it would re-run or garble a line). Stop it, or edit a copy.
- **Two touching cylinders give false normals** (the combination lock,
  2026-11-19). The wheels' pins rest touching after a push; Bullet's
  contacts between two parallel `btCylinderShapeZ` came out with normals
  such as (0.99, 0.15) where the pins' centre line was (−0.6, 0.8), and
  their friction dragged a resting wheel 9 numbers when the next one
  moved off. Where two such parts only meet in one plane, give each a
  sphere of its radius there: sphere on sphere is exact.
- **A flat face sliding over a compound of convex pieces** (the same lock)
  sometimes takes a piece's inner face for the contact's normal: a square
  fence over the cam's pieces was shoved sideways (normal −0.98, −0.19,
  far from any edge of the outline) at every pass, and the bolt crept back.
  Bullet's internal-edge problem; its fix (`btAdjustInternalEdgeContacts`)
  is for triangle meshes. A round part over the pieces didn't meet it.
- **A round part pressed on an edge turns what it rests on.** The lock's
  round fence, resting on the corner of a gate nearly under it, pushes
  along the line to its centre, and the sideways part of its spring's force
  turned the wheel the last bit, even at four times the wheel's drag: it
  opened 1.5 numbers below and 1.8 above, where the geometry says 1.14.
  When a follower must not move what it touches, measure the band, and
  say what the test expects in it.
- **Rest a follower on what drives it, not on what it reads** (the lock's
  first fence rested on the wheels: a passing gate let it drop into the
  set wheels' gates, and the moving gate's wall dragged them along). And a
  part that drops onto an edge strikes it: chamfer what lets it down, so it
  comes down at the driver's pace.
- **To check sound headless,** run with `SDL_AUDIODRIVER=dummy` (else
  there's no audio device, `loadSound` returns -1 and nothing plays) and
  `-e`: what plays, and bpp's synth tones, go into the export's `.wav`, on
  its timeline of 25 frames a second (frame 847 at 33.88 s). Export writes
  about 100 KB a frame, so keep the run short; for a longer listen, log
  the sounds and mix them.
- **Gentle forces find seams.** A seam between two convex pieces of a
  compound that a part slides over can catch it, even a round part: the
  lock's dial way (the hand's 30 N cm) never noticed, but the
  safecracker's feeling touch (then 0.8 N cm) stopped at every seam between the
  cam's pieces. Keep seams away from where a part slides with small forces:
  the cam's notch piece now takes in 25 degrees of rim.
- **"Starting on it" needs a grace, not an edge.** The dialling rules'
  "starting on the number doesn't count" was "less than 1 away": a hand
  stopping 0.02 short of 31 then counted 30 as 0.98 away and turned a whole
  extra turn, carrying a wheel off. Half a number either way is "on it".
- **A procedure of many steps is clearest as a coroutine** (the
  safecracker): it yields each thing for the hand to do and is resumed with
  what was found, so its code reads in the order a person does it. Keep
  its locals in a `do` block: Lua 5.1 allows 200 locals to a function, and
  a long exhibit's top level reaches that.
- **To edit `tools/check-all.sh` while it runs,** write the new version to
  another file and `mv` it over: bash goes on reading the old file (its
  inode), and the next run reads the new.
- **`v:eachContact` gives wrong handles in the hall for objects added
  while the exhibit loads** (the spaghetti sort, 2026-11-24).
  `Viewer::addObject` keeps a reference to index 2 of the Lua stack, but
  reads bpp's main Lua state, not the coroutine the hall loads an exhibit
  in, so it keeps whatever sits there (a slider's name, here) for every
  object added during the load; objects added later are right. On its
  own an exhibit never sees it. **Fixed the same day** in `src/viewer.cpp`
  (`addObjectLua` keeps the handle it was given; bpp must be rebuilt).
  The spaghetti sort still knows the palm by where it meets a rod (above
  the comb, where nothing else is), so it works on an older bpp too. Test
  anything that reads contacts in the hall too, not only on its own.
- **A rod on a flat foot rights itself** unless it leans past
  atan(radius / half its length): a "leaning rack" left short rods
  upright and off the comb, and a tall rod, free at the foot, leant 7
  degrees sideways. Hold a standing part at both ends, with clearances
  too small to let it pass that angle (the spaghetti sort's notches and
  comb), and it comes to rest upright.
- **A force that drives a part into a stop must be stopped by it** (the
  slide adder, 2026-11-25). The operator feels a 9 that won't take a carry
  because the stylus, pushed down on a band at its bottom, stops. At 300
  steps a second it squeezed past the peg instead (Bullet's contacts are
  soft, and a coarse step lets a ball sink further in), the operator felt
  nothing, and carries through nines went wrong. At 600 it held at five
  times the hand's force. Where a reading depends on something *not*
  moving, push harder than the machine ever will and check it holds.
- **Upright, a slider must hold its own weight**: the adder's bands are held
  by friction (a slider motor at no speed), and below a band's weight
  (11.8 kg cm/s^2) every band slid to the bottom. And a part that moves
  several at once needs their sum: the zeroing bar's 4 N couldn't lift six
  bands at friction 60, and the next sum began from leftovers.
- **Count the solids in every STL, and sweep every moving part's travel
  against the fixed ones.** The slide adder's channels along the top and
  the bottom cut the cover between two slots off on every side: one cover
  half came out as six solids (now five islands, each on studs from the
  rib behind it). And its ribs, run the full height, crossed the zeroing
  bar's path; an overlap check of the parts at rest missed it, one at each
  end of the bar's travel found it.
- **A hinge pins its two points together in all three directions**
  (`btHingeConstraint`), not just across its axis. Between bars in
  different planes, give the pin's point on one bar at the other bar's
  height (`pa.y + planeY(B) - planeY(A)`), or the pin pulls the bars
  toward one plane and they lean: Peaucellier's inverter read 16% off,
  then 0.04% (the linkages' `FINDINGS.md`).
- **A linkage wants stiff hinges and solver iterations** (the Walker
  Room's rule): one closed loop of six bars held at 10; the multiplier's
  long chain of sliders and hinges went wrong at 10 and was right at 20.
  The linkages run at 80. And a hand that reverses at once jerks a
  linkage: ramp a driving motor's speed (a third of a second took the
  straight line's pen from 0.07 mm off to 0.004).
- **A linkage's constant is a difference of squares** (OA² − PA² = 100):
  0.02 mm on a 150 mm bar moved Peaucellier's answer 0.06%. Work out the
  lengths to the answer's precision, not the bar's.
- **Rebuilding in a build folder that has a `release/bpp`** can go wrong:
  the precompiled header has the program's name (`PRECOMPILED_HEADER` in
  `bpp.pro`), and when it must be remade gcc can take the binary for the
  header. Remove `release/bpp` and `release/bpp.gch` before `make` after
  header changes.
## 6. How to make an exhibit

1. Pick it from `MACHINES.md`; it goes in its place in the list's walking
   order, which moves the bays after it along one (`hall.lua` EXHIBITS;
   README table; the READMEs' bay numbers and the PDF subtitles in
   `make-pdfs.sh`).
2. Prototype the mechanism in a scratch script first and measure it.
3. `exhibits/<Name>/`: the script runs on its own and in the hall
   (find its folder with the `DIR` loop the others use; `hallPath` for
   OpenSCAD's full path), uses `exhibit-table.lua` (the machine's footprint),
   the start hold, resting, a tour that prints `RESULT ... PASS/FAIL`,
   sliders, keys, help text and hover text.
4. `parts/*.scad` as the single source of geometry (or, as the Pascaline,
   a Lua geometry file that writes the SCAD); `make-stls.sh` with each part
   turned to print; check the STLs and overlaps.
5. Sweep friction and speed, record it in `FINDINGS.md`; `README.md` with
   the parts table, what to buy, assembly; both PDFs; a `make-pdfs.sh` line.
   **A manual**, `MANUAL.md` and its PDF (William, 2026-11-17: one per
   machine): how to work the machine, step by step, with worked examples
   and pictures drawn from the same code as the simulation and the printed
   parts (`manual/make-figures.py`), common mistakes, the exhibit's keys, a
   short "making one" pointing to the README. The slide rule's is the
   model for a simple machine, the Digi-Comp II's for a big one. Register
   `H` and `F1` to open it when the exhibit runs on its own (`if not
   hallPath`, `open-manual.lua`; only `F1` where the exhibit uses `H`
   itself, as the Pascaline and the Digi-Comp II do); in the hall the
   hall's `H` and `F1` do it.
6. In the hall: its EXHIBITS entry (`floorY = -100`), placard lettering
   (`make-labels.py`; a new key needs its line in `labels.lua` first), the
   lectern card (`make-lecterns.py`; more than a card's worth of text goes
   on pages, a list of cards, turned by PgDn), `tools/check-all.sh` (add it
   there), screenshots. An exhibit that can be built more than one way
   (by environment variables, as the splitter board's `SB_WALLS`) can show
   them all: its EXHIBITS entry's `modes`, each a stop Tab steps through
   (`]` and `[` pass them by), each with a label of its own.
7. **Make it show its working in the 3D view from the start**, not only in
   the console and tooltips: William watches in the GUI. Lehmer's sieve
   first showed nothing of N, x or the answer, and its probe's depth was
   hidden; it got a board of number drums (the exhibit's, said so) and a
   printed depth scale. When a machine runs on by itself, pause between
   steps so each reading can be seen (the sieve's "through" drum was
   cleared in the frame it was set). Say what the machine computes and
   what the script does for the operator (the sieve only says "maybe";
   the square test is Lua's).

## 7. Where things stand and what's next

- **Done (2026-10-21): Lehmer's number sieve** (then east 1, now west 6): four Geneva stars
  of 9, 8, 7 and 5 places on one axle, driven from one shaft, detents to
  centre them, pegged holes, a cam-lifted probe; it factors 1241 (and 1679,
  1157, 2813: `N`) by Fermat's way. **2026-10-25:** William found it hard
  to see what it computed: now a board beside it (the exhibit's) shows N,
  x, each wheel's hole under the probe (green open, red pegged), the depth,
  and at a stop x*x - N, the verdict and the factors; a printed depth
  scale on the probe's guide reads how far the probe went; `T` runs the
  tour for the number `N` chose. The wheels' colours and the see-through
  cam are still first guesses. **2026-10-26:** the depth now stays on the
  board between turns, and the camera is further back; William's window
  is narrower than the virtual screen (about 1450 px of 3D view, not
  1658), so frame views with room to spare. He asked whether the cam is
  one print: it is (one watertight solid); only the simulation's contact
  shape is 72 convex wedges. Offered, not done: finer cam steps (5 degree
  flats now). It is the dearest exhibit to step (a 25 s tour took about
  three minutes here, headless): if it is slow on his computer,
  `LS_HZ=1200` halves that and still passes.
- **Done (2026-10-26): the Digi-Comp II, step 1, the counter** (then west 3, later west 4 and east 4, now east 6):
  three printed rockers, tipped over by the balls alone, and a feeder
  wheel. **The same day, step 2a, the accumulator,** which replaces it.
  William asked for the rest of the real machine; its manual (Evil Mad
  Scientist's copy, cdn.evilmadscientist.com/KitInstrux/DCII-manual.pdf)
  gives the registers: accumulator 7 flip-flops, memory 4 bits, MQ 3,
  distributor 3 (a ring counter), mode flip-flops T1 to T6 and complement
  CF1, CF2; switches MULTIPLY, CLEAR, COUNT, COMPLEMENT, OVERFLOW
  (run/halt) and AUTO/MANUAL; the ball's path INPUT, MULTIPLY, CLEAR, COUNT,
  then down the accumulator. Built now: a **two-level** board (balls that
  are done drop through holes to the lower level and roll to the
  collector), the 7-bit accumulator (each rocker has a foot on the lower
  level for CLEAR: a wedge a clear ball pushes back to 0), hand-set
  **switches** (flaps) for CLEAR and COUNT, and START (the feeder wheel,
  turned by hand). Keys: Space START, C and N the switches, 1 to 7 set a
  bit by hand. Board 322 x 878 mm, 10 upper and 10 lower tiles; table
  100 x 150.
- **Done (2026-10-26, while William slept): step 2b, add and multiply.**
  The memory (four hand-set switches beside A1 to A4: 1 sends the ball
  into that flip-flop's funnel, by a long left wall the carry doesn't
  cross; 0 drops it), the MQ (three flip-flops read the other way, so a
  ball takes one away; a borrow out of it drops through STOP and the hand
  stops), the distributor (a tree of three flip-flops: the MQ and M4, M1,
  M3, M2 by turns; the manual's is a ring) and MULTIPLY, all thirteen
  flip-flops the same part. CLEAR's "on" outlet is on its right now (the
  memory's lane needs A1's left). Tour: count, clear, 37 + 11 = 48,
  13 x 3 = 39, every ball checked; the hand puts balls back from the
  collector. Keys: M, C, N; 1 to 7; H J K L the memory; 8 9 0 the MQ; D the
  distributor. Board 424 x 1216 mm, 14 + 14 tiles; table 110 x 180. Not
  yet seen by William.
- **2026-10-27:** William asked for an illustrated manual of every
  operation, now and to come, and which parts each needs (for building
  part of the machine): `exhibits/DigiComp2/MANUAL.md`. Its figures are
  drawn from the geometry. Keep it up to date as steps are added; its
  section 6 (complement, subtract, divide, AUTO) gives E.S.R.'s ways and
  this board's.
- **Done the same night: the narrated tour.** Before each ball a yellow
  dashed line on the board shows the way it will go, and the sign's THIS
  BALL says what it will do and what A was and will be (`route()`,
  `preview()` in `digicomp2.lua`; also on `Space`). `DC_STEP` starts the
  tour at a later step, for testing.
- **Done (2026-10-27): step 2c, the complement: subtract and divide.**
  William chose the longer board (more visible) over a lower-level
  inverting lane. Not E.S.R.'s T1 to T6, CF1, CF2: under each of A1 to
  A6's done holes a **done lane** runs on into the next flip-flop's funnel,
  and six **shutters** (one bar, high over the walls: the COMPLEMENT
  switch, `X`) cover the holes, so a ball goes on through every flip-flop
  to A7 and turns each over. Complement = two balls, the hand moving
  COMPLEMENT between them (CF1 and CF2's job). Dividing: MQ 7, the hand
  watches OVERFLOW and stops at the end of that cycle; quotient and
  remainder from the cycles and A (MANUAL section 6; FINDINGS says why the
  end of the cycle). A's steps are 14.75 cm apart now (`G.ADZ`), all its
  funnels have both walls long. Tour adds the complement of 25, 12 - 4 and
  13 / 5 (about 27 600 frames; check-all allows 29 000). Board 424 x 1573
  mm, 18 + 18 tiles; table 110 x 220. `tests/complement.lua`. The camera
  stands farther back for the longer board.
- **Done (2026-10-28): the hall loads a bit at a time.** William found the
  hall slow to start. It is shown at once now, a sheet over each exhibit's
  bay, and the exhibits load one a frame (the one you're at first); the
  status bar says which. The time is OpenSCAD making parts on a cold cache
  (94 s for all five here; 1.8 s cached). The Digi-Comp's sign letters are
  in `parts/sign.scad` now, so changing its geometry no longer remakes them.
- **Done the same night: programs.** William saw that the procedures are
  the operator's part (the machine has no stored program: its switches are
  control lines, each ball a clock tick, the operator its control unit)
  and asked for them as scripts the exhibit reads and runs line by line,
  with a library. `programs/*.dc2` (listed in `programs/LIBRARY`): the
  keys, plus `SET`, `UNTIL STOP|OVERFLOW|CYCLE`, `CHECK`; the "program"
  slider and `G` run one, the listing on the program board behind (`B`),
  the line in the status bar; `DC_PROGRAM=all` runs the library (53 000 frames, 12
  minutes here).
  MANUAL section 9. (The hall's and the exhibits' status lines were never
  shown: bpp's `statusText` is a property, not a `setStatusText` method;
  the hall passes it on now.)
- **Then: the program board.** A board on a stand behind the machine
  shows the program, its line lit, scrolling with it; `B` flies the camera
  to it and back (set the camera's up vector, then its place, then its
  look, as separate statements: Lua's multiple assignment has no order).
- **Then: the tour is the library, the meter is off.** William asked for
  the tour to run the programs (so what starts by itself is a program, line
  by line), and for the hall's cost meter to be off unless asked for (the
  "Hall: meter" slider at the views, or `HALL_METER=1`; the freeze log goes
  with it). The Digi-Comp's tour is now ~53 000 frames; check-all allows
  56 000 (and no longer runs the library separately).
- **Then: AUTO (step 2d).** The escapement is on the board (the knob is
  gone: the weight, a torque, turns the wheel, the fly caps its speed, the
  anchor holds it; Space pushes the START lever). Every ball goes down a
  trip channel at the bottom right, under a trip lever (an arm trailing
  down the slope from an axle: a ball can only lift it; its underside
  stays high near the axle, so a ball meets it far out), to the store.
  The axle comes out through the rim; an arm hangs from it beside the
  board, and a thread from its foot runs up beside the board to an eye and
  across to the START lever, which it pulls as the hand does. AUTO (`U`):
  the thread hooked in; MANUAL: off. STOP's ball drops into a pocket and
  trips nothing. Programs have `AUTO`, `MANUAL` and `RUN` (each ball
  checked at the lever, the next in flight); `multiply-auto.dc2` does 13 x
  5 in 21 balls from one START. The library (the tour) is ~81 000 frames;
  check-all allows 86 000. FINDINGS, step 2d, has the tries: a lever
  reaching up the slope jammed; a push rod up the board worked but was too
  heavy to push unless balanced, and William pointed out a thin rod 1.5 m
  long can pull but hardly push, hence the thread. In the simulation the
  thread is inextensible and pull-only (impulses each step, `trip.pull`).
  The weight and fly as parts are not done.
- **Then: OVERFLOW's halt (step 2e).** OVERFLOW is a shutter over the
  overflow hole (key `O`, program step `OVERFLOW HALT|RUN`): RUN, the
  carry out of A7 rolls over it to the collector; HALT, it drops into a
  pocket and trips nothing, so AUTO stops. `count-out-auto.dc2` and
  `divide-auto.dc2` run E.S.R.'s way. A halt mid-cycle can leave A = 0
  when a division isn't exact (11 / 5): the manual says to finish the
  cycle by hand. **Checked whole (2026-10-31):** check-all's eight
  runs of the other exhibits and `check-lua52.sh` passed, but both
  Digi-Comp runs gave no RESULT: the tour had not ended. Run with its log,
  every program was right and the tour ended at frame 98 292, past the
  96 000 check-all allowed (it had been put at ~88 000). check-all now
  allows 110 000 (110 600 in the hall), still two hours a run; each took
  about an hour here, two at a time on two cores.
- **Done (2026-10-31): the weight and the fly as parts (step 2f).** The
  wheel is glued on a 3 mm steel axle down through the plate and the board.
  Under the board (not in the lower level as planned: there it could not be
  wound, and the damper and ratchet had no room): a ratchet on the axle,
  the drum on the axle with two pawls in it, a coupler, and the **FRT-G2-200**
  damper screwed to a bracket. The cord runs up under the board to a pulley
  just out past the top edge and down to a printed cup of **eight** balls (74 g
  with the cup: torque 2.9 mN m, the old 30 kg cm^2/s^2); 57 balls from wound
  up to the table. `G.DRIVE` in the geometry; `drive` in the script (the cup
  a body, the cord pull-only as the thread, the damper a drag c w,
  `DC_DAMP` scaling it, `DC_CUP` the balls). The hand winds the weight when
  fewer than 25 balls are left and nothing moves; `R` leaves it as it is.
  The library passed at the damper's rating (on its own and in the hall)
  and at 0.65 and 1.35 of it (its tolerance), the hand winding three times
  a tour. Found: the anchor's second finger comes off its pin slowly
  against the damper (up to 1.8 s at its rating, 3.6 s at 1.35, where the hand's
  3 s wait for the anchor was too short and readings came a ball early: it
  waits 8 s now); at 0.65 the wheel runs past the damper's 50 rpm. The
  damper's mount is drawn from our reading of an unlabelled datasheet
  drawing: measure its shaft before printing the coupler. FINDINGS, step
  2f. **Not seen by William yet.**
- A possible tighter rule for dividing in AUTO (A = 0 at a halt is exact
  only if M's bits still to come in that cycle are all 0) was offered to
  William, not yet taken.
- **Done (2026-10-31, evening): each program with only its parts.**
  William asked for it on the full board, the parts "really absent" (out
  of the simulation, not only hidden). Every wall and peg has a `part` in
  the geometry (A, CLEAR, COUNT, MULTIPLY with D, MQ and STOP, MEMORY,
  COMPLEMENT, OVERFLOW, AUTO; BOARD and FEEDER always), the script tags
  the moving parts, and each program has a `PARTS` line; a step needing a
  part it doesn't name is an error when it is read. A program's start
  takes the rest off (`parts` in the script: fixed things moved far below
  the floor, moving ones frozen, untouchable and moved there too); they
  stay off after it, keys for them refuse, `R` by hand puts all back.
  `manual/fig-parts.png` is drawn from the same tags. Found by it: the
  clear lane's walls also steer A's done balls into the trip channel
  (without them AUTO stopped), and the done lanes' first stretch is the
  done holes' backstop (without it a fast carry skipped A2's hole and
  rolled off the plate): both are A's now. Watching OVERFLOW needs only
  A's hole and pocket; its shutter is for halting AUTO. **Not seen by
  William yet.** He pointed to a replica:
  www.instructables.com/Digi-Comp-II-Replica/ (only its summary could be
  fetched here).
- **Done (2026-11-01): the hand, shown.** William asked to see it: a
  drawn pointing hand (`parts/hand.scad`, its own file so the machine's parts
  aren't remade) that goes to everything the operator does (switches,
  flip-flops, knobs, START, the thread's hook, carrying balls from the
  store and pockets to the top, winding under the board) and does it on
  arrival; `hand` in the script, a queue of jobs, the machine busy while
  it has any. The tour takes 23% longer (it ends near frame 121 000);
  check-all allows 135 000. FINDINGS, "The hand, shown". Seen by William
  (2026-11-03): he asked to lose the forearm and keep the palm off the
  fingertip (done), and for `Q`, the hand off (done: at once and unseen,
  as before; `DC_HAND=0`).
- **Slow? Check POV-Ray export first (2026-11-03).** The machine crawled
  in William's hall, 2 s a frame of "physics" on the hall's meter: bpp's
  POV-Ray export was on (toolbar button or `P`; a cyan dot top right).
  It runs every frame before the steps, so the meter counts it as
  physics. A fix to bpp's export (format a mesh only when its `.inc` is
  missing) went to Jakob separately. FINDINGS, "How fast it runs".
- **The Shortcuts pane (2026-11-04):** William found he had to scroll to
  the keys. Every exhibit's pane now has its KEYS first, under one line of
  the hall's (Tab, Shift+Tab; where its sliders are moved to the end); the
  Digi-Comp's no longer lists its library or the program (one line names
  it; the listing is on the program board, which the "program" slider now
  shows too). Resting the mouse on a table says what its placard says
  (`EXHIBIT_TABLE.parts`): the placards are low down and seldom in view.
  A new bpp pane was considered and set aside (screen room; bpp's C++).
- **Lecterns (2026-11-05):** a museum label on a brass post just right of
  an exhibit's table and beyond it, its card tilted up: the name, a line, a
  few sentences (`make-lecterns.py` writes the card as a PNG; the hall
  puts it on a thin box as a texture and builds the lectern when the card
  is there). `I` looks at it close up and back; the mouse on it says what
  the placard says. The Differential has one, which William chose (A) over
  a smaller card on the table beside the machine (B: in the exhibit's own
  view, but the view is tight round the machine, so it was cut off and
  crowded it). Where it stands went round three times: in front of the
  table (out of the exhibit's view); beyond the table's back right corner
  (turned 35 degrees to the aisle: away from the viewer; then turned to
  the camera, but far back, and it would be farther still at the
  Digi-Comp). William's idea settled it, **two stops at an exhibit with a
  lectern**: the first Tab walks up to it, a view the hall works out from
  the table and the lectern (eyes 162 cm up, square to the table, back far
  enough for both: `g.approach`), the lectern at the table's right front
  corner (`LECTERN`: 12 cm past its right edge, 14 cm before its front)
  turned to face that view; the next Tab steps in, to the exhibit's own
  view; then on. Shift+Tab the same, back (`steppedIn` in `hall.lua`).
  Stepping in or back flies straight (at first it went by the aisle, the
  way between bays, and William saw it back out and come in again).
  The exhibit is awake from the first stop (its tour, keys, pane). Only
  exhibits with a card have the two stops. Two camera faults found on
  the way, both old: the hall stood the camera upright before every
  flight, which turned it level, so a flight began by looking up (William
  saw stepping in pan up and back down); and an exhibit loading in the
  background still reached the real camera (standing it upright as it
  loaded), which now and then left you looking level where you were.
  Flights now start from the way the camera looks, and a loading exhibit
  touches the camera only to set its own view (the camera's pitch logged
  every frame: steady). All five exhibits then on show have a card
  (2026-11-06; wording William read first; the Domino Half Adder's names
  Matt Parker's 10,000-domino computer, Manchester Science Festival,
  October 2012, which adds two four-bit numbers: Think Maths' own page).
  `make-lecterns.py` shrinks a title or line too wide for the card and
  says if the text runs off its foot. Each exhibit's first stop seen in
  the window: the table, the lectern and the placard in view; the
  Domino Half Adder's big table puts its card farther off (zoom, or `I`).
  An exhibit added later gets the two stops by getting a card.
  **2026-11-11:** walked to with Tab, the sieve had no lectern: an exhibit
  loading while you're at another has that one's world in use, and its
  lectern went there (the Differential's showed only because it loads
  first; starting at the sieve hid it). The lecterns are the hall's now,
  in world 0 like the placards.
- **Checked against bpp's new Params and ScriptKeys (2026-11-11):**
  `tools/check-all.sh` all passed on Jakob's rewrite, and in the window
  Tab, the panes and the sliders work.
- **Done (2026-11-12, revised 2026-11-13): the Galton board** (now west 5),
  in a new row of bays: the hall has ten now, the planimeter's covered bay
  (west 2) before it (by rank, 14 and 13), and everything after it one row
  on, on the same side (Pascaline west 3, Domino Half Adder east 3,
  Digi-Comp II west 4, tide predictor east 4, Differential Analyser west 5,
  Difference Engine east 5; the READMEs' bay numbers and the PDF subtitles
  with them). 150 steel balls (6 mm), 4 mm pins 12 mm apart, twelve rows
  from the first pin, thirteen bins with the binomial's heights for 150
  engraved in gold; a hopper, **two mirror-image metering wheels** geared
  together behind the board and turned by one crank (the hand, a motor; the
  gears, a lock holding both to the crank's turn), a funnel under both and a
  straight neck onto the first pin; a slide under the bins, a drawer, the
  hand tipping the drawer back into the hopper (the pouring moves the
  balls, as the Digi-Comp's hand does), and knocking the board if balls
  stay wedged (idealised; not needed since the drawer was made deeper). A
  sign (the exhibit's) shows the run, the balls in the bins, the mean bin
  and the spread against 6.00 and 1.73. The tour: a run, empty and pour, a
  run (about 4 min headless; check-all allows 6000 frames, 6600 in the
  hall). The first patch (2026-11-12) had one wheel, and the board leant
  whichever way the bounce tipped it: William spotted the asymmetry; the
  second patch replaces the wheel with the pair. Over six runs at the usual
  settings the mean bin was 5.97 and the spread 1.94 (fair coins: 6.00,
  1.73); fair from a bounce of 0.3 to 0.55 and at friction 0.15 and 0.45. At
  a bounce of 0.7 the spread passes the tour's 2.6. The bounce (0.4, ball on
  board) is a guess (no figure for steel on printed PLA was found); FINDINGS
  says how to measure it. Keep the crank to 0.75 turns a second: faster, two
  balls meet over the neck and jam. Why wider than fair coins (2026-11-13,
  a third patch): each pin is fair but remembers the last (the same way again
  two times in three; FINDINGS section 6, with the bounce, friction and
  row-spacing sweeps); the board was left as it is, the instrument kept
  (`GB_PATHS`, `paths.py`, and `GB_GEO="V=..."` for the rows). Left to
  try: feeding the first pin a little off-centre, since the first pair
  goes together 98% of the time. Splitters (2026-11-13, a fourth patch):
  a neck above every pin, tested on its own (`splitter-test.lua`,
  `SPLITTERS.md`), for a second board that would show independent coins
  exactly and, with other walls, gambler's ruin and first passage. At a
  30 mm pitch with 10 mm necks the decisions cannot be told from fair
  coins; but the bounce moves it (0.3: 69% the same way). A fifth patch
  tried to take the bounce out (mixing chambers, leaning necks): neither
  did, and the memory turned out to hang on how a ball meets the neck's
  mouth (a seam there moved it by 0.13), so no simulation can promise a
  printed splitter's memory. The plan (a sixth patch): the whole printed
  tooth is what swaps, in variants of one height so the rows stay put;
  four sets (necks 10, 12, 14, 20 mm) cover bounces 0.3 to 0.6 within
  0.07, tuned on the built board by the pile's spread. A swallowing wall
  in the test bed (walls.py) gives first passage and the reflection
  principle as the formulas do with tuned teeth (chi-square 11.6 on 11 df,
  3,000 balls), and fails plainly mistuned; two walls give gambler's ruin
  (three starts, all passing). A gambler's-ruin board wants its walls 4
  places apart (2% survive 12 rows; a quarter, a half, three quarters go
  right). The exhibit (an eighth patch): splitter-board.lua, run by
  galton.lua through a small BOARD interface (its geometry, its OpenSCAD
  files, its sign and verdict); every wall mode passes its tour by
  chi-square. Still to come: its bay in the hall, its placard and lectern
  card, check-all, its printed parts. Next was: the splitter
  board in bpp, with swappable wall panels (plain; swallowing, for first
  passage and the reflection principle; both, for gambler's ruin). Both
  boards are to be kept. Printed in three tiles under 200 mm,
  two gears, a stand, an acrylic front sheet; every STL checked watertight,
  and no two parts overlap at rest. `tools/check-all.sh` (twelve runs, the
  Galton board's two included) all passed on the revised board.
  **Not seen by William in the GUI yet.**
- **Done (2026-11-14): the hall re-ordered, the splitter board in it.**
  William found the old order (by interest alone) off: the Domino Half
  Adder, which does one thing once, stood sixth; Lehmer's sieve second.
  MACHINES.md now orders all 48 by what each asks of a visitor (the idea
  it computes, the mechanism, how much it shows), in five tiers, and the
  hall walks it: dominoes first, the Galton and splitter boards facing
  each other in the third pair. The splitter board has its placard,
  lectern card and check-all lines (fourteen runs).
- **The splitter board's other distributions (not yet done).** With fair
  splitters the board has shown the binomial, first passage, the
  reflection principle and gambler's ruin (SPLITTERS.md). Still to do, in
  the order suggested (each in `splitter-test.lua` first, against the
  exact counts, then as a wall mode or a board of its own):
  1. **Reflecting walls: done (2026-11-14), below.**
  2. **Galton's two-stage board: conditional distributions** (moderate,
     about a session). His own 1877 design: one tall board, a row of
     compartments halfway down with a slide under them. Open all and the
     bell is the whole one; open one and a narrower bell stands under it
     (the root of regression). The parts exist; new are the compartments
     and their gate.
  3. **First return: the Catalan numbers** (moderate to hard, one or two
     sessions). Balls caught at the starting column, mid-board, must leave
     without crossing live splitters: through a hole into a second layer
     behind (the Digi-Comp II's two-level board is the precedent), ramps
     to the tubes there. For 150 balls about 75, 19, 9, 6, 4, 3.
  4. **Splitters in two directions: the Rayleigh ring** (hard; an exhibit
     of its own). A 3D forest of splitters, ring bins; simulable, hard to
     print and build.
  The biased-pin distributions (Poisson, geometric, two humps, the
  Ehrenfest urn) were set aside at William's word (fair splitters only,
  so that the mathematics shows, not a construct). The arcsine law has no
  mechanism yet. **The splitter board is not seen by William in the GUI
  yet.**
- **Done (2026-11-14, later): reflecting walls on the splitter board.**
  Tested first in `splitter-test.lua` (`SP_REFL_L`, `SP_REFL_R`; `walls.py`
  takes a wall as `3r`), then two wall modes on the board: `SB_WALLS=reflect`
  (one wall, `SB_REFL` places left, 3 by default: each bin holds its
  binomial count plus its mirror image's, 47, 42, 31, 19, 8, 2 for 150)
  and `SB_WALLS=flat` (two: 50, 50, 50 at ±3; `SB_REFL=5` gives five bins,
  not flat yet in twelve rows, as the mathematics has it: the rows needed
  grow as the width squared, so the board stays at twelve rows and the
  walls narrow). The wall zigzags: a half tooth where a ball can stand at
  the wall's place, the ordinary outer tooth (the neck's wall) between.
  The half tooth keeps its steel pin, 2.5 mm outward, with the neck's wall
  carried down to it (without the pin: 0.28 of the balls went on inward
  after the wall, the walls hoarded balls; with it 0.47 to 0.50 at a
  bounce of 0.4, within 0.06 of fair at 0.3 to 0.6). Every board run
  passed by chi-square (SPLITTERS.md, "Reflecting walls" and "The
  exhibit"); the sign counts bins (by the wall, next, the rest; or left,
  middle, right). Found on the way: the 20 mm teeth (for a bounce of 0.3)
  fail over twelve rows with no walls at all (memory growing to +0.13 by
  rows 9 to 11; the earlier table had 8 rows): to be tuned again, not
  done. And the other wall modes are now drawn as they are (section 5).
  Not done: the half teeth's STLs (the splitter board's printed parts are
  all still to come), the hall's tour of the splitter board is still the
  default (first passage); the reflecting modes are run with `SB_WALLS`.
  **Then, at William's word: the wall made solid.** The outer teeth
  between the half teeth (whole at first, their outer halves doing
  nothing, so the wall looked like part of the path) are now only their
  inner halves, printed with the set, and the board's wall fills the rest
  out to their outer edge. Nothing a ball meets changed: the test bed
  (`SP_REFL_FILL`) gave one wall's run identical to the ball, and two
  walls the same counts; every board tour passed again. **Not seen by
  William in the GUI.**
- **Done (2026-11-15): an exhibit's ways, lectern pages, and the splitter
  board's walls in light wood.** At William's word: the hall's splitter
  board shows all five ways (EXHIBITS `modes`: first passage, gambler's
  ruin, a wall that sends balls back, the pile goes flat, no walls), Tab
  stepping on through them; each way its own world, the others put away
  (section 5: not far away). Lectern labels can have pages (PgDn, PgUp; a
  list of cards in `make-lecterns.py`); the splitter board has a label of
  two to four pages for each way, what you see, the mathematics, and
  further reading (Feller, Grinstead and Snell, van der Hofstad and
  Keane). Its exit blocks, ramps, tubes and walls are drawn again over the
  board in light wood (`wallsDrawn()`, drawn only): in the board's brown
  they couldn't be seen. Its help no longer says "half the balls caught
  in the first two rows" (a quarter in the first, 37 in 100 by the
  second). William's idea, for other exhibits too: an exhibit with ways,
  a label with pages.
- **Done (2026-11-15): the suanpan** (west 1), the first of the four
  hand-worked pieces at the start of the walk (William chose bays for all
  four: the abacus, the slide rule, Napier's bones, the combination lock).
  All four bays were added at once, the other three covered, so every
  exhibit moved along two bays on its side and the facing pairs (the
  Galton and splitter boards) still face. Seven rods, 49 printed beads on
  steel rods: each bead a body on a slider along its rod, a motor at no
  speed and little force its friction; a finger (the script's) moves one
  bead and it pushes the others by contact. Adding by the suanpan's rules
  (`plan.lua`: direct, the five- and ten-complements, both together, the
  carry), from the left; a slate (pictures swapped as textures,
  `make-slate.py`) shows the number, the number added, the rod and the
  rule. Its tour (3, 4, 8, 6, 79, 1234 to 1334) passes at every friction,
  finger speed and step rate tried, and 40 random additions pass
  (`FINDINGS.md`); the rules alone, 120,000 random additions. Its lectern
  has three pages, one of history (the 1946 Tokyo contest, checked). No
  dots on its beam: a dot every third rod is the soroban's. Not done:
  subtraction, multiplication, division.
- **Done (2026-11-15, evening): parts built in the background, the hall
  going on.** William found getting into the hall slow; the exhibits never
  ran until visited, but OpenSCAD held the window still while it built
  parts (`waitForFinished`). bpp gains `openscadBuild(sdl)` ("ready",
  "building" or "failed: ..."; several OpenSCADs at once, one per spare
  core; each writes `<hash>.part.stl`, renamed once done) and
  `openscadBuilds()`. The hall loads each exhibit as a coroutine (up to
  three at once): its `OpenSCAD` asks for the part and yields until it is
  built, then takes it from the cache. From an empty cache, in a window:
  all 297 parts in 7 minutes, the hall drawing every second (3 to 9
  frames a second in software, no gap over 1.6 s); before, it stood still
  for each part. Headless runs unchanged (built at once). Two more of
  William's three ideas wait: an exhibit's other ways loaded only once you
  get there, and exhibits loaded only as you walk up.
- **Done (2026-11-16): the suanpan takes away and multiplies.** William
  has an abacus and wanted to learn on it. The suanpan has three ways
  (`SU_WAY`; Tab in the hall, each with its own lectern pages):
  adding; taking away, the rules backward (the borrow first, as the
  soroban handbooks teach it: the slate says the rule, the borrow is done,
  then the rod's own beads; 2000 − 1 borrows through three rods); and
  multiplying, the modern Japanese method as in Kojima (1954): the
  multiplier on the left rods, the multiplicand to its right, each
  two-digit product from the times table added k rods right of the
  multiplicand's digit, that digit then cleared. Seven rods hold 99 × 99
  or 9999 × 9; the rods are named A to G for it. `plan-test.lua` checks
  all three against arithmetic (100,000 sums, 100,000 differences,
  29,801 products: none wrong, all 26 rules each way). Both new tours
  pass at every friction, finger speed and step rate tried, and on 40
  random differences and 20 random products read from the beads.
  check-all has four more lines (each way alone and in the hall). The 145
  new slate pictures are saved with an 8-colour palette (a third the
  size; the old ones untouched). Not done: division.
- **Done (2026-11-16): the slide rule** (east 1), facing the suanpan. A
  25 cm Mannheim rule: A; B, CI, C on the slide; D, K, L; a cursor. The
  slide and the cursor are bodies on sliders (the grooves; the parts don't
  touch), held by friction as the suanpan's beads are; a finger (the
  script's) sets one at a time, each **against the other as it stands**
  (section 5: the first version didn't, and a slide left 10 mm short still
  read right). Two ways (`SR_WAY`; Tab in the hall, each with three lectern
  pages): multiplying and dividing (C's 10 when C's 1 would run off; a
  table at one setting: 1.609 x 2, 3, 5), and squares, roots (which half
  of A), cubes, reciprocals and logarithms. A wide, low slate (34 x 12 cm)
  shows the problem, each step, what the rule reads, the estimate that
  places the point, and the answer; `M` takes the camera to the hairline
  and follows it (the figures are too small to read from the exhibit's
  view; in the hall it must stand 30 cm off with a narrow view, section 5). Readings are rounded to what a person reads (three figures, four
  from 1 to 2 on C and D) and checked against the true answer within one
  in the last figure. Both tours pass at every friction, finger speed and
  step rate tried, and 40 random problems each way; they fail once the
  finger leaves parts 0.05 mm off (3 x 4, read to four figures at D's left
  end, goes first). `rule-test.lua`: 20,000 problems of each kind, none
  wrong with the parts exactly placed. Printed: the stock and slide each in
  halves joined by splice bars, the cursor (and a 2 mm acrylic window),
  two feet tilting it 25 degrees, the slate; the scales on paper,
  `scales.pdf` (A4, measured true to 0.01 mm at 600 dpi), drawn by
  `make-scales.py`, which also makes the textures. All STLs watertight,
  none overlapping. check-all has four more lines. The hall's summary line
  counted each of an exhibit's ways as a bay (it said "-1 in
  preparation"): it counts covered bays now. **Not seen by William in the
  GUI yet.** Not done: S and T (trigonometry) scales, a printed rule.
- **Done (2026-11-16): Napier's bones** (west 2). Napier's own set,
  as Glaisher describes it: ten four-sided rods, four tables each (every
  four-digit number can be laid; bones-test.lua tries all 10,000). The
  rods are bodies; a hand (the script's) steers one at a time out of the
  tray, turns it to the face it needs, sets it on the tilted board's
  ledge beside the last and presses it home with 0.3 N. Every reading is
  taken from where the rods lie: the face up from each rod's orientation,
  the cell level with the index's row from its place (on Genaille's rods
  the triangles are followed by height). Two ways (`NB_WAY`; Tab, three
  lectern pages each): Napier's (the row, the diagonals, a row for each
  of the multiplier's digits, added) and Genaille's rods (rows 2 to 9, the
  carries drawn as triangles, the path dotted in red). Resting rods crept
  (section 5); they sleep now. Both tours pass at every friction up to
  0.85, hand speed, press, step rate and tilt tried, and 20 random
  problems each way; at friction 1.0 a rod rolled over its edge and the
  reading caught it (FINDINGS.md). Printed: eleven rods, the board, two
  feet, the tray, the slate on its stand; the faces on paper,
  `napier-faces.pdf` and `genaille-faces.pdf` (strips to wrap round the
  rods, measured true to 0.1 mm). All STLs watertight and under 200 mm,
  none overlapping. check-all has four more lines. **Not seen by William
  in the GUI yet.** Not done: division and square roots on the bones
  (Napier did both).
- **Done (2026-11-17): manuals, and `H` to open them.** William asked for
  a manual per machine, as a PDF, and a way to open it from the hall. `H`
  opens the exhibit's `MANUAL.pdf` (else its README) in the PDF viewer, at
  any exhibit in the hall, and at the entrance or title wall the hall's
  guide (`open-manual.lua`, through `xdg-open` on William's Ubuntu; quoting
  tested with a folder named with a space and an apostrophe). The slide
  rule has the first: `MANUAL.md`, 8 pages, its rule pictures drawn by
  `manual/make-figures.py` from `make-scales.py`'s own marks, the parts set
  as the text says. **Waiting on William's verdict on the format.**
- **Done (2026-11-17): every machine has its manual.** William liked the
  slide rule's ("This is super. Keep going."), so the others followed in
  its format, one commit each: the suanpan (each rule's moves drawn from
  `plan.lua`'s own steps), Napier's bones and Genaille's rods (the
  simulation's own faces; sums and paths from `bones.lua`), the Domino
  Half Adder (the layout from `domino-layout.lua`; which dominoes fell in
  each sum as the simulation reported, `DA_DEBUG=2`), the Differential,
  the Pascaline and Lehmer's sieve (OpenSCAD's drawings of the printed
  parts, set to the states the simulation reported, through each
  exhibit's `manual/views.scad`), the Galton board and the splitter board
  (`MANUAL-splitter.md`: the two share a folder, so an EXHIBITS entry can
  now name its manual file, `manual = ...`). `F1` opens a manual too,
  everywhere: the Pascaline's `H` is its hundreds and the Digi-Comp II's
  its memory, so theirs open on `F1`. Found and fixed on the way: the
  suanpan's slate tiles were thick enough that their top edges showed each
  picture squashed into a strip.
- **Fixed (2026-11-18): the splitter board's gambler's ruin.** Starting 1
  place from a wall, it stopped its run with four balls on the ramp to the
  first tube: that tube takes half the balls (75 of 150, give or take 6)
  and, single file, held 82. A tube is now two staggered columns wide
  (10.4 mm) wherever, for fair coins, the chance of more balls than single
  file holds is over one in a thousand; only that tube is (starts 1 and
  3), and the width is kept out of the default board's sizes file. A tall two-column stack
  jitters without moving, so a run's end no longer waits on balls already
  in a tube (`maxvFree`). All three starts and the default pass their
  tours; the default board's geometry is unchanged. check-all has a line
  for gambler's ruin now (SPLITTERS.md, "A tube too short").
- **Done (2026-11-19): the combination lock** (east 2), the last of the
  four simple hand-worked pieces. Sargent & Greenleaf's arrangement, made
  big and open: a dial and drive cam, three printed wheels loose on a post,
  a steel pin through each (lost motion: each picks up the next after 96.2
  numbers), a lever on the bolt laying a steel fence across the rims, the
  cam 0.4 mm bigger so the fence rests on it, clear of the wheels. Every
  push is a contact (pin on pin, the fence on the rims, in the gates and the
  cam's notch); the wheels and the dial on hinges, the bolt on a slider,
  each held by friction; the lever's torsion spring a steady torque. The
  hand dials by the rules (left four, right three, left two, right until it
  stops) and the slate shows each gate's distance from the fence, live. Set
  to 31-72-46; the tour opens it, fails with the last number five off, and
  opens with every number one off. `lock.lua` is the single source: the
  geometry, the convex pieces (the bodies and OpenSCAD's outlines alike),
  a model of the wheels, the gates for a combination. `lock-test.lua`: of
  the million combinations, the rules can't set those with the second
  number 0 to 11 above the first or the third 0 to 7 below the second; a
  last number 90 to 99 is the forbidden zone; none opens early; 27 open a
  given lock (about 37,000 really different, in Matt Blaze's range for
  real safe locks). The physics sets every gate to 0.03 numbers of the
  model. FINDINGS has the way there: the fence on the wheels dragged set
  wheels; the notch's steep wall shoved a fence that had only dropped onto
  the rims (chamfered now, both walls); the pins as cylinders (now spheres
  where they meet, section 5); a round fence turns a wheel nearly there
  (the lock opens 1.5 below to 1.8 above; the exhibit expects "either" in
  that band); a square fence hit Bullet's internal edges; closing fast
  lifted the fence before the bolt was thrown (the hand closes the first
  20 numbers at 40 a second). The relock needs the bolt's friction and the
  wheels' drag under about four times the spring's press. Four lectern
  pages (one of history and reading: Yale's Monitor Bank Lock, Sargent's
  time lock, Blaze, Feynman). Printed: three wheels (cut for the
  combination: `COMBO=12-34-56 ./make-stls.sh`), cam, dial and its marks
  (a second colour), back plate with the post, base, standard, guides,
  keeper, bolt, lever, the slate; steel pins, fence, spindle, a spring and
  a wave washer bought. All STLs watertight, under 200 mm, none
  overlapping but the press fits. check-all has two more lines; the smoke
  run (`-k BabbagesHall`) passes, 43 demos (`lock-test.lua`, a tool,
  returns at once when bpp opens it). **Not seen by William in the GUI
  yet.** Offered, not done: wheels with a change key instead of
  reprinting.
- **Done (2026-11-20): the lock's second way, the safecracker's**
  (`LK_WAY=safe`; `Tab` in the hall; its own lectern card, three pages).
  The wheels now differ on purpose (40.0, 39.9, 39.8 mm), and with the
  cam's notch under it the fence rests on the largest wheel whose gate
  isn't under it. A "feel" job turns the dial at 3 numbers a second with
  only 0.6 N cm (the dial's own friction is 0.3), so it stops at the
  contact points; a gate under the wheel
  holding the fence up drops it 0.1 mm, and the gap between the contact
  points narrows 0.16 numbers. The safecracker, a coroutine told nothing,
  graphs the gap with all three wheels parked together (narrow at wheel
  1's number), then with wheel 1 left there and wheels 2 and 3 parked
  together (wheel 2's), each every 2.5 numbers and then every half number
  round the narrowing, and tries every second number for wheel 3. The tour
  (43,000 frames, about 12 simulated minutes; check-all allows 52,000)
  finds 31 and 72 and opens on 46; the gaps felt differ from the model's
  (`L.contacts`) by 0.013 numbers (the median), repeating to 0.006. Swept:
  hand speed, wheel drag, surface friction, step rate, three other locks,
  all pass. `lock-test.lua` runs the method in the model on 40
  random locks: all found and opened. The slate hides the combination and draws the
  graphs in chalk. FINDINGS has the way there: seams between the cam's
  pieces stopped the gentle hand (section 5); 0.15 mm steps let the fence
  onto the smallest wheel only 0.1 mm above the chamfer's foot, where it
  half-caught; two "starting on it" roundings went a whole turn too far
  (`goTo`, `toOpen`: now half a number of grace); the last wheel's tries
  went through the second number and carried wheel 2 off (now from just
  above it, on round). The wheels' drag is now 0.8 N cm (was 0.4; the
  dial way passes at both): at 0.4 or less the fence turns a wheel whose
  gate nears it into line, and with surface friction 0.6 that put wheel 2
  at 78. The feel is 0.6 N cm (0.8 rode up the chamfer at friction 0.3).
- **Done (2026-11-20): the safecracker's way, heard.** A click as each
  notch wall stops the gentle dial (`sounds/`, made by `make-sounds.py`:
  a contact microphone's click, steep wall bright, sloping wall dull) and,
  after each pair, a tone from bpp's synth (`v:setTone`, voice 20) pitched
  by the gap: E, then a fourth up (A, D) for each wheel the fence drops
  onto. The tone is the exhibit's, and the lectern says so (a fourth page,
  LISTEN); `F` plays the clicks alone; in the hall, heard only while
  you're at the lock. Checked through bpp's own export (FINDINGS: the
  safecracker's way, heard).
- **Done (2026-11-21): pick-up clicks, and cream cards.** The
  safecracker's way also clicks, more lightly, each time a pin picks up a
  wheel on the turns (a wheel going from still to faster than 3 numbers a
  second; one click when several start together), so the parking turns
  sound like a real dial being worked. The lecterns' cards are printed
  darker, paper (181, 173, 154) for (239, 230, 207): in the hall's light at
  full strength they show cream again, (244, 233, 207) at the lock, and a
  deeper cream in the aisle. (A tint on the card did nothing: bpp ignores
  an object's colour once it has a texture.)
- **Done (2026-11-21): colour on the slate for what matters** (the
  safecracker's way). Blue: a reading narrower than the graph's level
  (its LOW, HIGH and GAP numbers, its dot, and the dial's arc); gold: a
  number found (the FOUND row); green: the lock opened (the whole
  combination). The graph's dots are all chalk but for blue (they had
  been white, green, orange by graph, which William found confusing next
  to the arc's white and blue). Coloured glyph sets `gb-`, `gy-`, `gg-` from
  `make-slate.py`; `showGlyphs(row, text, col)` takes a colour code for the
  row or one a character; `markNarrow` judges and colours. William's
  report: the clicks don't change at a narrowing, and nothing said why it
  mattered.
- **Done (2026-11-21): chalk on the dial instead of the tone.** The tone
  is gone (a real lock makes none, it repeated the graph, and it hid that
  a click says *when* and the dial says *where*); the clicks stay. At each
  click the dial is chalked at that reading (a tick), settled where the
  feel stops, with the arc between the two, the gap, riding round with the
  dial until the next reading's first click; blue when the gap reads
  narrower than the graph's level (`CHALK` in the exhibit, `chalkTick` and
  `chalkArc` in the scad). The lectern's second page is now LISTEN, AND
  READ THE DIAL.
- **Done (2026-11-20): walking the hall, and a quicker safecracker.**
  Tab still walks every stop (up to an exhibit, a step in, each of its
  ways); `]` and `[` go exhibit to exhibit, and `F3` finds one by typing
  part of its name or its number, which keeps working as the hall grows
  past 40 exhibits. `HALL_KEYS` presses keys at given frames, so the hall's
  keys can be tried headless (README). The safecracker now stops each graph
  at the first point back up after the narrowing and then finds its two
  edges a half number at a time, on the way the dial turns (an edge it
  can't feel: the other and the first graph's width): 43 readings and
  25,400 frames for 31-72-46, against 86 and 42,950. The lectern and the
  manual say a real safecracker graphs the whole dial, and why.
- **Done (2026-11-21): ticks on the lock's wheels.** Dark ticks across
  each wheel's rim every 30 degrees, a pale one opposite the gate
  (`rimTicks` in `parts/combination-lock.scad`, riders like the pin and the
  gate's red mark; drawn, not printed), so the safecracker's 2.5-number
  steps show before a gate comes round. William's report: you couldn't tell
  the wheels were turning until the notch showed.
- **Done (2026-11-21): exhibits brighten as you step up to them,** as in
  Euler's Gallery (98c41481). The hall's light, high above the middle of
  the nave (`HALL_LIGHT0`), stays on at an exhibit unless the exhibit sets
  its own `glLight0` (none here does); in the aisle and at the views its
  colours are dimmed to 60% (`AISLE_DIM`, in `applyLight`). Before, an
  exhibit switched to a light from the front, which lit upright faces and
  darkened table tops: four of ten measured dimmed on arrival (the slide
  rule -8%, the Differential -9%, the Digi-Comp and the lock -5%). Now all
  ten brighten, by 8-11% for the four seen mostly from above and 42-59%
  for the rest (mean brightness of the 3D view, the same camera in the
  aisle's light and in the exhibit's: `HALL_LIGHT_AS=aisle`). The buff
  floor tiles went near white at full strength (as Galileo's ramp did in
  the gallery): now #ae9d7b, buff at an exhibit (245, 221, 173 on screen),
  a deeper buff in the aisle. They had been near white in the old aisle
  too. The lectern cards (since printed darker) and Napier's bones were
  near white at full strength, but their text and figures stay sharp, and
  they were close to white before.
- **Done (2026-11-22): the bead sort** (MACHINES.md 5), west 3, the
  first exhibit whose answer comes from physics: nine rods, eight rows,
  72 beads, each bead a hull body on a `btSliderConstraint` along its rod
  (the motor at zero speed is its friction, the `friction` slider); the
  frame a body on a `btHingeConstraint` turned by its motor, the hand's
  speed the motor's limit. Type up to eight digits and Return: the hand
  threads each row with the frame flat, turns it upright, waits for the
  beads to stop and reads the rows from where they lie (the slate: the
  numbers laid, the rows, what it is doing; green when sorted). The tour
  (3 7 1 9 4 2 6 5; 5 0 5 2 8 2; 1 to 8) passes; a sweep of 23 lists each
  (friction 0 to 4, the hand at 10 and 90°/s, 300 and 1200 steps a second,
  two seeds) had none wrong, and friction 4.6, above a bead's weight,
  fails as it should (FINDINGS.md). The first bead starts where
  sin θ = F/mg says, logged about 5° later at 30°/s (the time it takes to
  move 3 mm). Printed parts in `parts/bead-sort.scad`, ten STLs; the
  manual has why it sorts, with figures. The bays after it moved along:
  Domino E3, Differential W4, Pascaline E4, Galton W5, splitter E5. The
  planimeter, which comes before the Galton board in MACHINES.md, now
  waits at W6, after the splitter board, so the Galton board and the
  splitter board still face each other (easily undone in `hall.lua`).
  Learned: bpp's `setTiming(STEP,0,STEP)` gives one step a frame, so a
  fast world steps itself the rest in `v:preSim`
  (`v:stepSimulation(STEP,0,STEP)`); `btHingeConstraint:setLimit` needs
  all five arguments; `btCylinderShape` isn't bound (use a hull);
  `v.showConstraints=false` or sliders draw as orange tubes; judge
  "settled" by each bead's movement along its rod, since the frame
  chatters at its stop; and count a rod once in a row, since two falling
  beads can share a row's band for a moment.
- **Done (2026-11-24): an exhibit starts when you step in**, here and in
  Euler's Gallery. Walking up, you see it standing still with its
  lectern: its world isn't stepped and its scripts aren't called. It
  starts the first time you step in, or press one of its keys at the
  approach (which steps you in), and from then on carries on whenever
  you're at it, the approach included. A way after the first has no
  approach and starts on arrival. `HALL_START` (`GALLERY_START`) now
  lands stepped in, so the in-hall checks and the gallery's `cmp2.sh` run
  as before; the gallery gained `GALLERY_KEYS`, as `HALL_KEYS`. Also: `I`
  flies straight to the lectern and back (it had gone out to the aisle
  and in again), as the gallery's always did.
- **Done (2026-11-24): the spaghetti sort,** the bead sort's second way
  (`Tab`, `BS_WAY=spaghetti`; `bead-sort.lua` hands over to
  `spaghetti-sort.lua`, which runs on its own too). A. K. Dewdney's
  (*Scientific American*, June 1984): a number n is a printed rod 8 mm
  across and 30 + 12 n mm long (so 0 has one); the hand drops each into a
  rack (a base that levels the feet, a notch for each foot, a comb with
  slots open toward you) where it stands upright; a palm, a board on a
  slider up a post, is lowered by the slider's motor, and the rod it
  touches first, read from the contacts after every step, is drawn out
  toward you and laid in a row in front (drawn: it leaves the simulation),
  and the palm goes on down. The rods keep their colours, so the row comes
  out sorted colours and all (the lectern's second page sets this against
  the bead sort's mixed beads). Slate: the numbers as cut, as taken, what
  the hands do; digits under the slots and at the laid rods' ends. The
  tour (the bead sort's three lists) passes at frame 4322; sweeps of 23
  lists (palm 0.5 to 10 cm/s, friction 0 to 1.2, 300 and 1200 steps a
  second, two seeds) none wrong; the palm stops 0.08 to 0.18 mm above each
  top. `BS_TILT` (the palm out of level) fails from 3 degrees, as the
  geometry says (2.8: its low end grounds on the comb before a short rod
  at the far end). Found on the way (FINDINGS section 7): rods meant to
  lean on the comb stood up on their own or leant sideways (now held
  upright at both ends); in the hall `eachContact` named the palm wrongly
  (section 5: a bpp fault, fixed in a second patch, C++: rebuild bpp). The placard is now THE BEAD AND
  SPAGHETTI SORTS (100 cm, the widest); a lectern card of three pages;
  MANUAL section 8 with figures (`manual/make-figures-spaghetti.py`) and
  a screenshot; ten printed parts and ten rods (`make-stls.sh`), all
  watertight, under 200 mm, none overlapping but glued faces. check-all
  has two more lines. **Not seen by William in the GUI yet.**
- **Done (2026-11-25): the slide adder** (MACHINES.md 7, west 4), with its
  second way, subtracting (`Tab`, `SA_WAY=subtract`). Troncet's
  arithmographe and the Addiator, upright and at 8 mm a step: six printed
  bands of 21 pegs on sliders behind a cover whose slots are joined by a
  channel along the top (the carry hook) and one along the bottom (the
  borrow); a zeroing bar under the bands' feet. The stylus is a body (a
  ball among the pegs, a ball in the slot) moved by a hand's limited force
  toward its target; the operator, a coroutine, reads the windows (red or
  not), makes a person's moves, and feels a band that won't move (a 9 that
  won't take a carry, a 0 that won't lend, the channel's end). Tours: 47295
  + 85358, 99999 + 1, 1889 + 2026 (frame 5527); 132653 − 85358, 100000 −
  1, 853 − 4729, which shows the complement, 996124 (frame 5033). Sweeps of
  23 sums each way (hand 2 to 15 cm/s, friction 13 to 60, the hand's force
  1.2 N, 600 and 1200 steps a second) none wrong; 300 steps a second, a
  band's friction under its weight, and a hand too weak to lift a band
  fail, each for a reason found (FINDINGS). Placard THE SLIDE ADDER; two
  lectern cards of three pages; MANUAL with figures
  (`manual/make-figures.py`) and a screenshot; nine kinds of printed part,
  all one watertight solid, under 200 mm, none overlapping at either end of
  their travel. A covered bay for the linkages (MACHINES.md 8, east 4)
  faces it, so that everything after moved one row on, each on its own
  side (bay numbers changed in the READMEs, manuals and PDF subtitles).
  **Not seen by William in the GUI yet.**
- **Done (2026-11-26): the linkages** (MACHINES.md 8, east 4, facing the
  slide adder), three ways (`Tab`, `LN_WAY`): Peaucellier's inverter
  (arms 15.052, rhombus 11.25: OP × OQ = 100; P set at x from 5 to 9, Q
  read at 100 / x), his straight line (P on a crank whose circle passes
  through O; Q's pen dots x = 100 / 7), and a slotted-lever multiplier (the
  b carriage at 6 tilts the lever, the bridge at 4a carries the cross
  carriage: a b / 2, its scale marked double). Every bar, carriage, block,
  the lever and the bridge a body, every pin a hinge, every slot a slider;
  the board lies flat. Built on the Walker Room's rules (William's
  suggestion: planes 7 mm apart, hubs, stiff hinges and solver iterations)
  and one found here: a hinge's two points must be at their own planes
  (16% off became 0.04%). Tours: x = 5, 6.25, 8, 9 (frame 826); the crank
  ±80° and back, the pen 0.003 mm off at most (frame 658); 3 × 4, 2.5 ×
  2.5, 4.5 × −2, 5 × 5 (frame 1147). Sweeps of 24 settings (21 for the
  line) at 20, 40 and 80 iterations, 300 and 1200 steps a second, and a
  fast hand: none wrong; 10 iterations fail the multiplier and the line.
  The line first failed at its turns, the hand reversing at once: the
  crank's motor now ramps. Placard LINKAGES THAT COMPUTE; three lectern
  cards of three pages; MANUAL with figures (`manual/make-figures.py`)
  and a screenshot; twelve kinds of printed part (the lever and bridge in
  halves), each one watertight solid under 200 mm. check-all has six more
  lines. **Not seen by William in the GUI yet.**
- **Added (2026-11-27):** two machines to MACHINES.md, at William's word:
  the linkages that write (9) and Jaquet-Droz's Draughtsman and Writer
  (29); rows after each moved on one (the list has 50).
- **Next (2026-11-27): the linkages that write** (MACHINES.md 9), William's
  idea: type a letter, and a one-crank linkage computed for it draws it.
  His synthesizer (`linkage_synthesis.py`, and `linkage_native.c` /
  `linkage_core.h`, the same in C with OpenMP: a four-bar core and up to
  six RR dyads, differential evolution, a Grashof gate and assembly
  margins, shape mode) searched in advance for every letter at three
  accuracies, a slider choosing (sloppy, ok, very good: about 5%, 2%, 1%
  RMS of the letter's diagonal), so the visitor sees how many bars more a
  better letter takes; the slate can replay the search. A first try (3
  seeds, up to 3 dyads, 5 s a seed on 2 cores): O 4 bars 0.03%, C 8 bars
  0.9%, D 10 bars 1.5%, L 10 bars 1.7%, A 10 bars 4.0% (A and L want more
  dyads, seeds and the corners weighted). In bpp: every link a body (the
  offset pen points rigid plates), every pin a hinge at its own planes, one
  ramped motor on the crank; first the 8-bar C, the simulated pen against
  the computed curve. William's synthesizer files are not in the
  repository yet. After it, the three-dimensional cams (10) and the
  petrol-pump price computer (11); new bays would be needed. The covered bays (the planimeter, the tide predictor, the Differential
  Analyser, the Difference Engine) wait for their turn in the list.
  Still offered, not asked for: printing only a Digi-Comp program's parts
  (the tiles carry every wall; `make-stls.sh` could take a `PARTS` list,
  with tiles cut anew). Skipped, at William's word: fixing bpp's own
  `demo/koppi/gears.lua` (its `assign()`, which newer OpenSCAD dropped).
- **Settled (2026-10-21):** William has tried the Pascaline (the mouse and
  the keys) and it works well; the stylus collision he thought he saw
  wasn't one. Euler's Gallery keeps its own tables as they are; the exhibit
  standard is the hall's. The Rec Room's camera flights look good, the
  top-down table view included.
- **Open, for later:** POV-Ray finds textures only with `+L` the bpp folder
  (their paths are relative to it): Jakob has it. A printed detent
  (`detent.stl`, 1.2 mm leaf) would test the stiffness worked out from PLA;
  William will print one some other time.

## 8. Opening message for the next chat

> Clone github.com/bullet-physics-playground/bpp, check out the branch
> test-harness, and read demo/WyomingWill/BabbagesHall/HANDOFF.md, then
> MACHINES.md and README.md there. Build bpp as described, run
> tools/check-all.sh, and continue with HANDOFF.md section 7: [the next
> step]. Deliver
> each step as a patch on test-harness, with its documents and PDFs, and
> the git commands.
