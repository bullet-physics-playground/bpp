# Tests

`tests/harness.py` runs bpp headless and checks it against what it did
before. It needs only Python 3 and a built bpp; the screenshot suite also
needs `xvfb`, `xdotool` and ImageMagick, and some demos need `openscad`.

```sh
make -C tests release            # unit tests + Lua API (quick)
make -C tests check              # every suite
tests/harness.py golden -k constraint   # one suite, only matching tests
```

| Suite     | What it checks | Expected files |
|-----------|----------------|----------------|
| `unit`    | `tests/NN-*.lua` each print `N passed, 0 failed` and exit 0 | in the tests |
| `api`     | Every Lua class, property and method overload scripts can use | `api/lua-api.txt` |
| `smoke`   | Every demo under `demo/` loads and runs 3 frames: no Lua error, crash or hang | `smoke/known-failures.txt` |
| `golden`  | The demos in `golden/demos.txt` simulate 40 frames; in the POV-Ray export (frames 1, 20, 40), every object's transform, the camera, the scene text and each mesh's geometry match | `golden/expected/` |
| `screens` | Still scenes in `screens/*.lua`, opened in the GUI on a virtual screen, match pixel for pixel (outside the frame counter) | `screens/expected/*.png` |

Every bpp run gets its own empty HOME, settings, mesh cache and export
directory, so your preferences never affect a result. Demos run from their
own directory, as the GUI runs them; the unit tests from the top of the
checkout, as before. Numbers are compared with a tolerance of 1e-5 (bpp
prints six digits): on the same platform runs match exactly.

`api`, `golden` and `screens` hold what Linux produces (Ubuntu 24.04, as
the CI runs), so on other systems the harness skips them.

## When a test fails

A failure means bpp now does something different. If the change is a bug,
fix it. If it is meant (a new property, a changed default, a better
renderer), regenerate the expected files and commit them with the change:

```sh
tests/harness.py --update api            # or golden, screens, smoke
git diff tests/                          # check the change is the one meant
```

`smoke/known-failures.txt` lists demos that already fail, mostly
standalone Lua tools that are not bpp scenes. A new failure fails the
suite; a listed demo that starts working is reported, so the list can
shrink. A line whose reason starts with `skip` is not run at all: for
scripts that write files next to themselves or run for minutes. (The smoke
and golden suites fail if a run leaves new files under `demo/`.)

The `api` suite matters more than it looks: bpp accepts any property name
a script sets (`cube.colr = "red"` is not an error, it does nothing), so a
renamed or removed property breaks scripts silently. This suite is what
notices.

## Refactoring: compare against master

For a change that should not alter behaviour at all (moving code out of
`Viewer`, say), compare the branch directly against a build of master on
the same machine, instead of against the stored files:

```sh
git worktree add ../bpp-master master && (cd ../bpp-master && qmake && make -j release)
tests/harness.py golden --baseline ../bpp-master/release/bpp
```

## Sanitizers

The CI also builds with AddressSanitizer and UndefinedBehaviorSanitizer
and runs the unit, api and golden suites on that build:

```sh
qmake CONFIG+=release CONFIG+=sanitizer CONFIG+=sanitize_address CONFIG+=sanitize_undefined
make -j release
ASAN_OPTIONS=detect_leaks=0 \
UBSAN_OPTIONS=print_stacktrace=1:suppressions=$PWD/tests/sanitizers/ubsan.supp \
  tests/harness.py -k '^(?!08-remove|demo/basic/25-phase4)' unit api golden
```

`sanitizers/ubsan.supp` silences one known luabind alignment report (the
reason bpp.pro builds debug with `-fno-sanitize=alignment`).
`08-remove.lua` is left out because it measures memory, which the
sanitizer holds on to; `basic/25-phase4.lua` because of a known bug
(`Sweep::addProfilePoint` frees the shape its body still uses), until it is
fixed.

## What makes a golden demo

Only demos that give the same numbers on every run belong in
`golden/demos.txt`: each one there was checked over several runs. OpenSCAD
writes a solid with its triangles in a different order each run; for some
demos (gears, pulley, spirals) that changes collisions, so they are left
out, while for others it does not matter and they stay. Demos that seed
`math.random` from the clock are left out too. The harness removes the
run-to-run noise bpp itself adds: object order in the export (bpp keeps
objects in a `QSet`), mesh file names, the date line and cache paths.
Each mesh is compared by its triangle and vertex counts, bounds and area,
within 1e-3: OpenSCAD splits some faces differently from run to run and
varies a vertex's last printed digit.

The expected files were made on Ubuntu 24.04 with its packages, as the CI
job runs. Another compiler, Bullet or Mesa version can move results
slightly; on such a machine use `--baseline` rather than the stored files.
