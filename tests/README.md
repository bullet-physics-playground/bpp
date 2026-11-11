# Tests

`tests/harness.py` runs bpp headless and checks it against what it did
before. It needs only Python 3 and a built bpp; the screenshot suite also
needs `xvfb`, `xdotool`, ImageMagick and `libqt5svg5` (without it the
toolbar icons are blank), and some demos need `openscad`.

```sh
make -C tests release            # unit tests + Lua API (quick)
make -C tests check              # every suite
tests/harness.py golden -k constraint   # one suite, only matching tests
```

| Suite     | What it checks | Expected files |
|-----------|----------------|----------------|
| `unit`    | `tests/NN-*.lua` each print `N passed, 0 failed` and exit 0 | in the tests |
| `api`     | Every Lua class, property and method overload scripts can use | `api/lua-api.txt` |
| `smoke`   | Every demo the Demos menu lists loads and runs 3 frames: no Lua error, crash or hang | `smoke/known-failures.txt` |
| `golden`  | The demos in `golden/demos.txt` simulate 40 frames; in the POV-Ray export (frames 1, 20, 40), every object's transform, the camera, the scene text and each mesh's geometry match | `golden/expected/` |
| `screens` | Still scenes in `screens/*.lua`, opened in the GUI on a virtual screen, match pixel for pixel (outside the frame counter) | `screens/expected/*.png`, `screens/expected-qt6/` for a Qt 6 build |
| `theory`  | Only when named. Euler's Gallery's exhibits, run as their physics report ran them; what each prints agrees with the theory it stands for, within a tolerance (`--slow` adds the two that take many minutes) | `theory/checks.txt` |

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

A folder holding an empty file named `.nomenu` is not run at all, as the
Demos menu leaves it out: the place for scripts other scripts load,
probes and tools, which can't run on their own. Put such a script in one
rather than listing it here.

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
  tests/harness.py -k '^(?!08-remove)' unit api golden
```

`sanitizers/ubsan.supp` silences one known luabind alignment report (the
reason bpp.pro builds debug with `-fno-sanitize=alignment`).
`08-remove.lua` is left out because it measures memory, which the
sanitizer holds on to.

## The threaded build

The CI builds the threaded version too (Bullet 3.24 with threads, see
THREADS.md) and runs the unit, api and golden suites on it;
`22-threads.lua` checks that a scene run with four threads comes out the
same, to the last digit, as without (on the default build it only checks
that `setThreads` has no threads to give). And it builds that version with
ThreadSanitizer, Bullet included, and runs the unit suite:

```sh
CFLAGS=-fsanitize=thread CXXFLAGS=-fsanitize=thread scripts/bullet-threads.sh
qmake CONFIG+=release CONFIG+=bundled_bullet "QMAKE_CXXFLAGS+=-fsanitize=thread -g" "QMAKE_LFLAGS+=-fsanitize=thread"
rm -rf release/bpp release/bpp.gch && make -j release
TSAN_OPTIONS="suppressions=$PWD/tests/sanitizers/tsan.supp history_size=4" tests/harness.py unit
```

`sanitizers/tsan.supp` leaves out Bullet's own thread pool (it hands out
work with plain flags), its statistics counter, and PulseAudio's thread;
each entry says why. They match only where the pool's own code makes the
access, so a race in bpp's code that the pool runs is still reported
(checked with one planted in `bppworld.cpp`).

## Screen scenes

A scene in `screens/` can work the GUI before it is grabbed. Lines
`-- xdotool: ...` are xdotool commands, run in order once the window is up,
with `WIN` for the window: keys, clicks, drags, wheel turns
(`quadview.lua`). A line `-- mouse: X Y` (window coordinates) then rests
the pointer there (`hover.lua`). For such a scene the screen under the
window is grabbed, so a tooltip shows in the picture.

## Qt 5 and Qt 6

bpp builds with either (`qmake` for Qt 5, `qmake6` for Qt 6). The CI's
jobs build with Qt 5, as Ubuntu 22.04 and 24.04 do; `test-qt6` builds
with Qt 6, against libQGLViewer built from source, and runs the unit, api,
golden and screens suites. The first three use the same expected files as
Qt 5 (the API listing names a `QVector` `QList`, as Qt 6 does). Qt 6 lays
the window out otherwise, so its screenshots are in `screens/expected-qt6/`,
which the harness picks when the bpp it tests links Qt 6; `--update
screens` with a Qt 6 build writes there.

## Euler's Gallery against theory

`theory/checks.txt` turns the checks of the gallery's physics-fidelity
report (`demo/WyomingWill/EulersGallery/report/dossiers/`) into tests. Each
exhibit runs as its dossier's "Run used" did, and the numbers it prints are
compared with theory: the value it prints beside them, or the dossier's.
A tolerance is a few times the agreement the report found, so a change in
the physics fails while another machine's rounding does not; comments give
each one's reason, and the rows that can't be checked from the console
(CSV logs, other settings, sums by hand) are listed as "not checked here".

```sh
tests/harness.py theory                  # 19 exhibits, about 6 minutes on 4 cores
tests/harness.py --slow theory           # all 21 (the Brazil nut takes 17 minutes)
tests/harness.py theory -k GalileoRamp   # one exhibit
```

The CI runs the 19 on every push, and all 21 once a week. When an exhibit
changes on purpose, re-run its dossier's checks and update both the dossier
and its block.

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
