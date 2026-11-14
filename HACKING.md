# Hacking on bpp

A map of the code for someone about to change it: which class does what, how
a script runs, and how to add a feature together with its test. For the
tests themselves see [tests/README.md](tests/README.md); for threads,
[THREADS.md](THREADS.md).

## Building

```sh
qmake CONFIG+=release          # qmake6 for Qt 6
make -j"$(nproc)" release      # gives release/bpp
make -C tests release          # unit tests + Lua API
```

`bpp.pro` takes every `.cpp` and `.h` under `src/`, so a new file needs no
change there, only a fresh `qmake`. Whenever qmake's settings change, run
`rm -rf release/bpp release/bpp.gch` before `make`: the old precompiled
header no longer fits, and the compiler stops with "stray '\177'" errors.

## Where things are

`Viewer` (`src/viewer.h`, `viewer.cpp`) is the heart of it: the Bullet world,
the script's Lua state, the OpenGL view, and everything a script reaches as
`v`. It is still large, but it hands most self-contained jobs to a helper
it holds as a member:

| File | Member | What it does |
|------|--------|--------------|
| `viewer_lua.cpp` | | `Viewer::luaBind`: the `Viewer` class as scripts see it (`v:add`, `v:preSim`, `v:addParam` ...) |
| `viewermedia.cpp` | | music, `v:ask`, `v:download`, `v:dataDir` |
| `params.cpp` | `_params` | the script's parameters (`v:addParam`), which the GUI shows as sliders, check boxes and cells |
| `scriptkeys.cpp` | `_keys` | the script's `v:onKey` hook and `v:addShortcut` shortcuts |
| `hover.cpp` | `_hover` | the tooltip by the resting mouse (`v:onHover`) |
| `quadview.cpp` | `_quad` | Tab's four-pane CAD view |
| `quickrender.cpp` | | the render button and `v:quickRender`: how POV-Ray is called |
| `wavtrack.cpp` | `_wavTrack` | an export's `.wav` sound track |
| `synth.cpp` | `_synth` | `v:setTone`'s synthesised voices |
| `decorations.cpp` | `_decorations` | look-only objects that follow a body (`v:attach`) |
| `culling.cpp`, `shadowmap.cpp`, `shadowrecord.cpp`, `screenmerge.cpp` | `_shadowRecord`, `_merge` | drawing fast: culling, shadows, recorded shadow lists, merged vertex buffers |
| `constraintdraw.cpp` | | the joint markers of `v.showConstraints` |
| `povexport.cpp` | | the files a POV-Ray export writes (`Viewer::savePOV` calls it) |
| `bppworld.cpp` | | bpp's Bullet world, with threads (`v:setThreads`) |

Each helper's header starts with a comment saying what it is for and how
the Viewer uses it; read that first.

The rest of `src/`:

- `objects/`: what a script can `v:add`. `Object` (`object.h`) is the base:
  a Bullet body and shape, colour and texture, drawing
  (`renderInLocalFrame`) and POV-Ray export (`toPOV`). `Cube`, `Sphere`,
  `Mesh`, `OpenSCAD`, `SoftBody` and the rest each add a shape. `Cam` is
  the camera.
- `lua_bullet*.cpp`: Bullet's own classes for scripts (`btVector3`,
  `btRigidBody`, the joints ...). The registrations are split into four
  files only to shorten the build (`lua_bullet_p.h`).
  `lua_converters.h` passes Qt types (`QString`, `QVariant`, `QList`) to
  and from Lua.
- `gui.cpp`: the main window: editor (`code.cpp`, highlighting in
  `high.cpp`), console and command line (`cmd.cpp`), parameter table,
  menus. It reaches the Viewer by calling it and by Qt signals
  (`scriptHasOutput`, `frameUpdate`, `paramsChanged` ...); `prefs.cpp` is
  the preferences dialog.
- `main.cpp`: the command line. With `-f script.lua -n N` it runs bpp
  without a window (what the tests do); otherwise it opens the `Gui`.
- `geo.cpp`, `demcore.cpp`, `dembed.cpp`: compiled helpers for particular
  demos (Artificial Physics, the Brazil nut).
- `joystick/`, `spacenavigator/`: gamepads (SDL2) and the 3Dconnexion
  SpaceNavigator.

## How a script runs

Opening a script, pressing reload, or `bpp -f` all end in
`Viewer::parse(text)`, which runs it in five steps:

1. the old script's `preStop` hook, if it set one;
2. `closeScript()`: drops the old script's hooks and every Lua reference
   bpp holds, takes its bodies and joints out of the world, and closes its
   Lua state;
3. `clear()`: deletes the old objects and parameters;
4. `openLua()`: a fresh Lua state with the standard libraries, bpp's
   `print`, `package.path`, and every class's `luaBind` (the list is in
   `openLua`); then `luaBindInstance()` sets the global `v`;
5. `runScript(text)`: runs the script. An error goes to the console with
   where the script was, and the script stops there.

The script itself only builds the scene and sets hooks (`v:preSim(fn)` and
the like). After that, each frame runs in `Viewer::animate()`:

```
preDraw hook -> POV-Ray export (if on) -> preSim hook -> Bullet step -> postSim hook
```

The steps from `preSim` on run only while the simulation is running. In the
GUI, `Viewer::draw()` then paints the frame: it places the decorations,
culls, draws shadows and objects, and ends in `postDraw`. (`preDraw` runs
once a frame, in `animate()`, with or without a window.) Without a window, `main.cpp` calls `animate()` N times, and
nothing is drawn.

`Viewer::mutex` keeps the GUI's drawing and the stepping apart while
`parse()` is replacing the scene; `_parsing` tells `animate()` and `draw()`
to stay out.

## Adding a feature, with its test

**Something new on `v`** (a method or property):

1. Declare it in `viewer.h` and write it in `viewer.cpp`. If it is a
   job of its own with state of its own, give it its own file and class,
   held as a Viewer member, as `hover.cpp` and `scriptkeys.cpp` are.
2. Register it in `Viewer::luaBind` (`viewer_lua.cpp`).
3. If it keeps a Lua function or table (a `luabind::object`), drop it in
   `closeScript()` with the other hooks, before the Lua state closes.
   Otherwise reloading a script crashes.
4. Write `tests/NN-name.lua` with the next free number. It checks the
   feature and ends by printing `N passed, 0 failed`; copy the asserts at
   the top of `tests/23-params.lua`. A test that must fail with an error
   says so with a `-- expect-error: PATTERN` line (`tests/25-script-error.lua`).
5. `tests/harness.py --update api`, check with `git diff tests/api/` that
   only your new names appear, and commit the listing with the change. The
   `api` suite is how a renamed property gets noticed, because bpp
   silently accepts a misspelt one.

**A new object type**: `src/objects/foo.{h,cpp}`, a subclass of `Object`
with a static `luaBind` (copy `sphere.cpp`), registered in `openLua()`'s
list. Override `renderInLocalFrame` for the screen and `toPOV` for the
export. Its destructor frees the shape and motion state it made with
`deleteOwnShape(true)`; a shape a script hands in is Lua's (mark it with
`setShapeFromLua(true)`), and motion states always belong to C++, even a
script's. `tests/26-ownership.lua` covers the cases, and the sanitizer
job fails on a leak or a double free. Re-run `qmake` so the new files get
built.

**A Bullet class or method for scripts**: add it to the matching
`lua_bullet_N.cpp`.

**Then pick the suites that see the change:**

| You changed | Run | Update when it is meant |
|-------------|-----|-------------------------|
| anything | `make -C tests release` (unit, api) | `--update api` |
| physics, export, an object's POV-Ray | `tests/harness.py golden` | `--update golden` |
| what the window looks like | `tests/harness.py screens` | `--update screens` (Qt 6: with a Qt 6 build) |
| a demo, or loading scripts | `tests/harness.py smoke` | `--update smoke` |
| the physics Euler's Gallery depends on | `tests/harness.py theory` | the dossier and `theory/checks.txt` |

A change meant to alter nothing at all (moving code out of `Viewer`) is
best checked against a build of master with `--baseline`: see "Refactoring"
in tests/README.md.

CI runs all of this on every push, with Qt 5, Qt 6, the sanitizers, the
threaded build and Windows (`.github/workflows/tests.yml`); a push is done once it's
green.
