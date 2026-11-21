# Gallery packs: bpp first, galleries when wanted

A handover for a new chat, and the design for Jakob to decide on. Nothing
here is built yet. Written 2026-11-21 from a conversation with Bill
(WyomingWill), who asked for it; the decisions marked **(Jakob)** are his.

## The goal

A new user downloads bpp alone, small and quick. The big galleries (Euler's
Gallery, Babbage's Hall, the Rec Room and the like) are downloaded only when
the user wants one. When a gallery is updated, the user is told the next
time they start bpp, and can update it then or later.

Today a clone is about 341 MB, and the galleries are most of the files in
it: Euler's Gallery 41 MB, Babbage's Hall 27 MB, the Walker Room 11 MB.
(About 161 MB of a clone is old copies of the website's screenshot gallery
on `gh-pages`; that is a separate one-line fix, `force_orphan` in
`.github/workflows/demo-screenshots.yml`.)

## What was decided, and why

Three ways were weighed:

1. **Download less, change nothing** (`git clone --depth 1`, sparse
   checkout). Free, but only for people who use git.
2. **Each gallery its own repository.** Rejected: the galleries lean on
   new bpp features all the time (in November, the Rec Room's snooker
   textures needed a fix in bpp and in the games together), so a gallery
   and the bpp it needs would drift apart, the tests would be split across
   repositories, and the shared tools would be copied around.
3. **Gallery packs, built by CI.** Chosen. The galleries stay in this
   repository, tested together as now; CI builds a pack of each, and bpp
   downloads a pack on first use.

Jakob prefers to keep the full history, as the Lua scripts must stay in
step with the C++; option 3 keeps it.

## How it works

1. **Bill's workflow stays the same.** He builds galleries on
   `test-harness` and merges to `master` when they're stable. The merge is
   what publishes: a CI job zips each gallery that changed and writes a
   small list (the *index*) of every gallery: its name, version, date,
   size, checksum, the bpp version it needs, and what changed. Both go to
   one fixed place on GitHub, replacing the previous files. Work on
   `test-harness` never reaches users, just as now.
2. **A new user downloads only bpp.** A **Galleries** menu lists what's
   available ("Babbage's Hall, 27 MB, Get"). A gallery is unpacked into
   bpp's per-user data folder, so it survives bpp updates, and from then
   on appears in the Demos menu like any other folder of demos.
3. **Each time bpp starts**, it fetches the index (a few KB) and compares
   it with what's installed. If a gallery is newer, a notice that doesn't
   get in the way says so: "Babbage's Hall has an update (12 MB): Update
   now / Later", with what changed. With no internet, bpp skips the check
   quietly; a setting turns the check off.
4. **A gallery that needs a newer bpp** says so ("this update needs bpp
   0.3.41, you have 0.3.40") and the installed version keeps working.

Developers notice no change: the galleries stay in `demo/`, and the tests
cover them together.

## What bpp already has

- **Downloads:** `v:download(url, path)` (`src/viewermedia.cpp`), with a
  tested part-file and disk-full handling (`tests/32-download-disk-full.lua`).
- **A per-user data folder:** `v:dataDir()`, the system's AppDataLocation
  (`userDataDir()` in `src/appenv.cpp`); `BPP_USER_DIR` moves it, as the
  test harness does (`tests/27-user-dir.lua`).
- **The Demos menu** (`Gui::createDemosMenu`, `src/gui.cpp`): built from
  the first `demo/` folder found beside the executable, above it, in the
  launch directory, or in `/usr/share/bpp/demo`. A folder with a
  `.nomenu` file is left out.
- **The version:** `APP_VERSION` in `src/main.cpp` (0.3.40 now).
- **Releases:** `.github/workflows/release.yml` builds `.deb` packages on a
  version tag.

## What's missing

1. **Unpacking.** Qt has no public zip reader. Either bundle a small zip
   library (miniz: one C file, MIT licence) or ship packs as `.tar.gz` and
   use the system's `tar`, which Linux, macOS and Windows 10 and later all
   have. **(Jakob)**
2. **The index and where packs live.** Suggested: a GitHub release with a
   fixed tag (say `galleries`) whose files the CI job replaces: one zip per
   gallery and `galleries.json`. **(Jakob)**
3. **The CI job.** On a push to `master`: for each gallery whose folder
   changed, build its pack, then rewrite the index. The version can be the
   merge's date and short commit id. "What changed" can be the commit
   subjects that touched the gallery since its last pack.
4. **The Galleries menu and the notice** (C++, in `src/gui.cpp`), or a
   Lua loader using `v:download` with a little C++ for unpacking.
5. **The Demos menu** reading installed galleries from the data folder as
   well as `demo/`.
6. **A way for a gallery to say what bpp it needs.** Suggested: a small
   file in the gallery's folder (`gallery.txt`: name, minimum bpp version),
   read by the CI job into the index.

## Things to settle first

- **Which folders are galleries**, and what stays in the base download
  (`basic/`, `constraint/`, `mesh/`, `module/`, `sound/` and the like are
  small). Ask Bill.
- **What a gallery borrows from outside its folder.** The Rec Room borrows
  `WyomingWill/Clocks/`, `WyomingWill/Walkers/` and `koppi/marblerun.lua`;
  many scripts use `demo/module/` through `package.path`; some textures
  live in the top-level `includes/`. A pack must include what it needs, or
  the index must list what it depends on. Check each gallery by running it
  from an unpacked pack in an empty folder.
- **Paths inside the galleries.** Several exhibits fall back to their path
  from the repository's top (`demo/WyomingWill/...`) when not run from
  their own folder; an installed gallery is elsewhere, so check that they
  still find everything when bpp changes into their folder, as its window
  and Demos menu do.
- **Installed bpp.** The `.deb` puts demos in `/usr/share/bpp/demo`;
  decide what an installed bpp ships, and check that textures in
  `includes/` are still found (bpp looks beside and above its executable).

## A plan, step by step

Each step a patch on `test-harness`, with its check:

1. Agree the questions above with Jakob and Bill. Check: their answers
   written into this file.
2. `gallery.txt` in each gallery folder, and a script
   (`scripts/make-gallery-packs.py`) that builds the packs and the index
   locally. Check: each pack, unpacked into an empty folder with bpp
   pointed at it, runs every demo in it (the harness's smoke run).
3. The CI job publishing them on a push to `master`. Check: a test run
   on a fork or a branch.
4. Unpacking in bpp, and the Demos menu reading the data folder. Check:
   unit tests for unpacking (including a bad or truncated pack) and for
   the menu.
5. The Galleries menu, the start-up check and the notice. Check: tests
   with a local index (`file://`, as the download test does), including
   no network and a gallery needing a newer bpp.
6. The README's install instructions.

## Opening message for the new chat

> Clone github.com/bullet-physics-playground/bpp, check out the branch
> test-harness, and read GALLERY-PACKS.md at the top of the repository,
> then HACKING.md and CLAUDE.md. Build bpp as HACKING.md describes and run
> python3 tests/harness.py. Then start on GALLERY-PACKS.md's plan, step 1:
> the questions for Jakob and Bill. Deliver each step as a patch on
> test-harness, with the git commands.
