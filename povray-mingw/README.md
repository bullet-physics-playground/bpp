# povray-mingw

Build glue for embedding POV-Ray's VFE (Virtual Front End) API directly into
bpp, as an alternative to F6 quick-render shelling out to a separate
`povray`/`pvengine` process. This is what the `USE_VFE` build flag (see the
[main README](../README.md)) links against.

This is a prototype: Windows/MSYS2 MinGW-w64 only. There is no upstream
MinGW build of POV-Ray, so this directory builds POV-Ray's core + VFE from
source as a static library, reusing the same source file lists as the
official `windows/vs2015/*.vcxproj` MSVC projects.

## Prerequisites

* A sibling [POV-Ray source checkout](https://github.com/POV-Ray/povray) —
  i.e. `povray/` next to `bpp/`, not inside it. The build expects
  `$$HOME/povray` where `$$HOME` is `bpp`'s parent directory (see
  `WIN32_DIR_POVRAY` in [`../msys2.pri`](../msys2.pri)).
* MSYS2 MinGW-w64 (`mingw64` toolchain: `g++`, `qmake`, `mingw32-make`).
* The MinGW-w64 packages this links against: `zlib`, `libpng`, `libjpeg`,
  `libtiff`. These are pulled in via `pkg-config`, not vendored — POV-Ray's
  own copies under `povray/libraries/` are not built or used.
* Qt5 (`qmake-qt5`) for anything that touches `BppVfeDisplay`
  (`smoketest`, `tworenders`, and bpp itself) — `povvfe` itself has no Qt
  dependency and builds fine with either Qt5 or Qt6 `qmake`.

## Directory layout

* [`povvfe.pro`](povvfe.pro) — the static library itself (`libpovvfe.a`):
  POV-Ray's core (base/core/backend/frontend/parser/povms/vm) plus VFE,
  minus the MSVC precompiled-header stubs and the AVX/FMA-optimized noise
  code under `platform/x86/` (skipped by not defining
  `TRY_OPTIMIZED_NOISE*` — see `povray/windows/povconfig/syspovconfig_mingw32.h`).
* [`smoketest/`](smoketest) — a minimal console app that renders one scene
  through a `BppVfeSession`/`BppVfeDisplay` pair (the same glue classes bpp
  itself uses, from [`../src/povray/`](../src/povray)) and confirms pixels
  actually arrive via the display callbacks. Build-first checkpoint: if this
  doesn't render, nothing downstream will either.
* [`tworenders/`](tworenders) — a second console harness that reuses one
  session across multiple renders, including cancelling one mid-flight and
  immediately restarting — the same sequence bpp's F6 goes through when
  pressed again during an active render. Useful for reproducing
  session-lifecycle bugs without going through the full GUI.
* [`povray-mingw.pro`](povray-mingw.pro) — a `SUBDIRS` project building
  `povvfe` and `smoketest` together.

## Building

All commands assume the MinGW-w64 toolchain is on `PATH` (e.g.
`export PATH="/c/msys64/mingw64/bin:$PATH"` in an MSYS2 shell) and are run
from this directory unless noted.

### 1. The static library

```bash
qmake povvfe.pro && mingw32-make -j4
```

Produces `release/libpovvfe.a`. This step needs the POV-Ray checkout but
not Qt.

### 2. Smoke test (verify the library actually works)

```bash
cd smoketest
qmake-qt5 smoketest.pro && mingw32-make -j4
```

Render something with it — MinGW-w64's DLLs need to be reachable at
runtime too:

```bash
export PATH="/c/msys64/mingw64/bin:$PATH"
./release/smoketest.exe path/to/scene.pov +W320 +H240 +Oout.png +FN
```

A `POVINC=<path>` environment variable maps to an extra library path (for
`colors.inc` etc — see the "missing standard includes" note below).

### 3. Optional: multi-render / cancel harness

```bash
cd ../tworenders
qmake-qt5 tworenders.pro && mingw32-make -j4
export PATH="/c/msys64/mingw64/bin:$PATH"
./release/tworenders.exe path/to/scene.pov +W320 +H240 +Oout.png +FN
```

### 4. bpp itself, with VFE enabled

From the `bpp/` root:

```bash
qmake-qt5 "USE_VFE=1" bpp.pro && mingw32-make -j4
```

`USE_VFE=1` pulls in `WIN32_LINK_POVVFE` in [`../msys2.pri`](../msys2.pri),
which adds the POV-Ray include paths and links `-lpovvfe` from this
directory's `release/`/`debug/` output. Leave it unset (or `USE_VFE=0`) to
build bpp exactly as before, with no dependency on the POV-Ray checkout at
all — see the main README's build-flag section for details.

## Gotchas

* **Switching `USE_VFE` (or any `DEFINES`) doesn't force a rebuild.**
  `mingw32-make`'s dependency tracking is timestamp-based and has no idea
  compiler flags changed, so flipping `USE_VFE` and re-running `mingw32-make`
  without regenerating first can silently link a stale build. Always
  `qmake-qt5 "USE_VFE=..." bpp.pro` again after changing it, and if bpp still
  looks unchanged, force a clean rebuild:
  ```bash
  rm -rf release/.obj release/.moc release/.u release/pch.h.gch
  mkdir -p release/.obj release/.moc release/.u
  mingw32-make -j4
  ```
* **Missing standard includes (`colors.inc` etc).** A real POV-Ray install
  resolves its own standard library via `povray.conf`/the registry; an
  embedded VFE session has neither. bpp's own VFE path
  ([`../src/viewer.cpp`](../src/viewer.cpp)) adds
  `povray/distribution/include` as a library path explicitly, resolved
  relative to bpp's working directory or install location. When testing
  standalone with `smoketest`/`tworenders`, pass the equivalent yourself via
  `POVINC=/path/to/povray/distribution/include`.
* **Output executables need the MinGW-w64 DLLs on `PATH`** (`libpng16.dll`,
  `zlib1.dll`, etc) — the usual `export PATH="/c/msys64/mingw64/bin:$PATH"`
  covers it.

## Licensing

POV-Ray is licensed under the AGPLv3; bpp is also AGPLv3. Statically linking
`libpovvfe.a` into bpp means the resulting binary is bound by AGPLv3
obligations. Fine for local experimentation, but worth a deliberate decision
before anyone distributes a `USE_VFE=1` build.
