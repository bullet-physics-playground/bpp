# povray-linux

Build glue for embedding POV-Ray's VFE (Virtual Front End) API directly into
bpp on Linux, as an alternative to F6 quick-render shelling out to a
separate `povray` process. This is what the `USE_VFE` build flag (see the
[main README](../README.md)) links against on Linux; [`povray-mingw/`](../povray-mingw)
is the Windows/MSYS2 twin of this directory.

## Prerequisites

* A sibling [POV-Ray source checkout](https://github.com/POV-Ray/povray) —
  i.e. `povray/` next to `bpp/`, not inside it — already configured for this
  machine (`./configure` run once from the `povray/` checkout so that
  `povray/unix/config.h` exists; no `make`/install needed, this project only
  needs the generated headers and sources).
* `pkg-config` packages `zlib`, `libpng`, `libjpeg`, `libtiff-4` and the
  Boost headers (`libboost-dev` or similar) — these are the same
  dependencies a normal Debian/Ubuntu `povray` package build needs.
* Qt5 (`qmake`) for anything that touches `BppVfeDisplay` (bpp itself);
  `povvfe` itself has no Qt dependency.

## Building

From this directory:

```bash
qmake povvfe.pro && make
```

Produces `release/libpovvfe.a`.

Then, from the `bpp/` root:

```bash
qmake "USE_VFE=1" bpp.pro && make
```

`USE_VFE=1` adds the POV-Ray include paths and links `-lpovvfe` from this
directory's `release/`/`debug/` output (wired in `bpp.pro`'s `linux { }`
block). Leave it unset (or `USE_VFE=0`) to build bpp exactly as before, with
no dependency on the POV-Ray checkout at all.

## Notes

* **Switching `USE_VFE` doesn't force a rebuild** — qmake/make's dependency
  tracking is timestamp-based and won't notice the `#define` changed. Always
  re-run `qmake "USE_VFE=..." bpp.pro` after changing it, and if bpp still
  looks unchanged, force a clean rebuild of `release/.obj`.
* **Missing standard includes (`colors.inc` etc).** An embedded VFE session
  has no `povray.conf` to resolve POV-Ray's standard library from. bpp's own
  VFE path ([`../src/viewer.cpp`](../src/viewer.cpp)) adds
  `povray/distribution/include` as a library path explicitly, resolved
  relative to the sibling `povray/` checkout.
* This reuses the same source file lists as [`povray-mingw/povvfe.pro`](../povray-mingw/povvfe.pro),
  swapping POV-Ray's Windows platform/VFE glue for its Unix equivalents
  (`platform/unix/*`, `vfe/unix/*`) — see the comment at the top of
  [`povvfe.pro`](povvfe.pro) for the exact mapping.
* **Two source files are `#include`d through tiny shims** (`povms_c_shim.cpp`,
  `portablenoise_shim.cpp`) instead of being listed directly in `SOURCES`.
  qmake derives object file names from source basenames and silently *drops*
  a `SOURCES` entry instead of erroring when it thinks two entries collide —
  both on an exact basename match (`source/povms/povms.c` vs `povms.cpp`)
  and, apparently, a basename-*suffix* match
  (`source/core/material/portablenoise.cpp` vs
  `platform/x86/avx/avxportablenoise.cpp`). Either collision means the
  dropped file's symbols are silently missing from the archive — a link
  failure, not a build failure, so it's easy to miss. If you add more POV-Ray
  source files here and hit `undefined reference` at bpp's link step despite
  the file being in `povvfe.pro`, check the object list in the generated
  Makefile (`grep <name> povray-linux/Makefile.Release`) for a basename
  clash before assuming the symbol is missing elsewhere.
* **The AVX/AVX2/FMA3/FMA4 noise code needs per-file ISA flags, not a global
  `QMAKE_CXXFLAGS` bump.** `unix/povconfig/syspovconfig.h` unconditionally
  enables `TRY_OPTIMIZED_NOISE_AVX`/`AVXFMA4`/`AVX2FMA3` for any GCC new
  enough (a compiler-version check, independent of what ISA flags are
  actually passed), which pulls in `extern` references to
  `platform/x86/{avx,avxfma4,avx2fma3}/*.cpp`. Giving the *whole* static-lib
  target `-mfma4`, for example, lets GCC's optimizer emit FMA4 instructions
  in any translation unit it likes — not just the one
  `CPUInfo`-feature-gated call site — and FMA4 is AMD-only (Bulldozer-era),
  so that SIGILLs immediately on any non-FMA4 CPU (most Intel machines,
  including the one this was built and tested on) regardless of the runtime
  dispatch these noise implementations are supposed to be gated behind.
  `povvfe.pro` uses `QMAKE_EXTRA_COMPILERS` to give only those four files
  their specific `-mavx`/`-mavx2 -mfma`/`-mavx -mfma4` flags, matching how
  the real `unix/Makefile.am` builds them as separate `libx86avx.a`/
  `libx86avxfma4.a`/`libx86avx2fma3.a` archives.
* **POV-Ray's block-drawing calls can pass pixel coordinates past the image
  edge** (e.g. `DrawFilledRectangle` with `y2` a few pixels beyond
  `GetHeight()-1`, whenever the render size isn't a clean multiple of the
  block size) — POV-Ray's own reference display
  (`unix/disp_sdl.cpp` in the sibling checkout) clamps every coordinate to
  `[0, GetWidth()-1] × [0, GetHeight()-1]` before writing for exactly this
  reason. `BppVfeDisplay` (in [`../src/povray/bppvfedisplay.cpp`](../src/povray/bppvfedisplay.cpp),
  not this directory, but easy to miss since it's platform-agnostic code)
  now does the same clamping; without it, F6 with `USE_VFE=1` reliably
  segfaults partway through the first render.

## Licensing

POV-Ray is licensed under the AGPLv3; bpp is also AGPLv3. Statically linking
`libpovvfe.a` into bpp means the resulting binary is bound by AGPLv3
obligations. Fine for local experimentation, but worth a deliberate decision
before anyone distributes a `USE_VFE=1` build.
