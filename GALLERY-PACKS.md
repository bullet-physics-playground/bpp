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
- **Releases:** `.github/workflows/release.yml` builds, on a version tag,
  `.deb` packages, a Windows installer (`bpp.nsi`) and macOS disk images
  (`scripts/deploy-mac.sh`). All three copy the whole of `demo/` and
  `includes/` in.

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

## Questions for Jakob and Bill

Step 1 of the plan. Each question says what the repository shows today
(`test-harness` at a17aaeda, sizes from `du`), suggests an answer, and
leaves a line for the real one.

### For both

1. **Which download is meant to get small?** The release downloads (the
   `.deb`s, the Windows installer, the macOS disk images) each carry all of
   `demo/` (104 MB) and `includes/` (74 MB). A clone stays the size it is
   whatever we do here, because the galleries stay in the repository;
   people who clone can be shown `git clone --depth 1` and a sparse
   checkout in the README. Suggested: the three release downloads ship the
   base demos only and get galleries from the menu; a clone keeps
   everything, as now.

   Also: 60 MB of `includes/` is the POV-Ray models of a Nissan Micra and a
   Citroën GS (`includes/i_micra_*.inc`, `i_citroen_gs*.inc`), which no demo
   uses; only `includes/citroen_gs_demo.pov` does. For the release
   downloads they weigh more than any gallery but Euler's. Keep them, make
   them a pack, or leave them out of the releases?

   Answer:

2. **When is a gallery published?** On `master` since 0.3.40 (4 November)
   there are 92 commits to `src/` and 109 to `demo/WyomingWill/`, and
   `APP_VERSION` is still 0.3.40. A pack built from `master` will often
   need C++ that no release has yet, and would tell users it needs a bpp
   they can't download. Three ways:
   - (a) Packs are built when a bpp version is tagged, with the release.
     Always consistent, but a gallery update waits for the next bpp release
     (about monthly so far).
   - (b) Packs are built on each merge to `master`, as designed above, and
     `gallery.txt` names the bpp a gallery needs. An update needing only Lua
     reaches users the same day; one needing new C++ shows "needs bpp
     0.3.41" until that is out.
   - (c) As (b), but CI holds back a pack whose `gallery.txt` names a bpp
     newer than the latest release, and publishes it with that release, so
     users never see an update they can't install.

   Suggested: (c). Either (b) or (c) depends on `gallery.txt` being right,
   which only Bill can know; a forgotten line gives users with the last
   release a broken gallery. CI could catch that by running each new pack's
   smoke test with the last released bpp too, at the cost of a second build
   in the job. Worth it?

   (There were 7 merges to `master` in the last month, so with (b) or (c) a
   user would see about one notice a week at most.)

   Answer:

3. **The shared modules.** An installed gallery will still find
   `require "common"` and `require "rolling"`: bpp looks for `demo/module/`
   beside and above its executable and in the system places
   (`getDefaultLuaPath`, `src/prefs.cpp`). But it gets the `module/` of the
   bpp that is installed, not the one the gallery was written with.
   Suggested: `demo/module/` counts as part of bpp, so a gallery that needs
   a changed module says so with the bpp version, as for C++.

   Answer:

### For Bill

4. **Which folders are galleries?** By size, suggested:

   | Folder (in `demo/WyomingWill/`) | Size | |
   |---|---|---|
   | `EulersGallery/` | 41 MB | pack |
   | `BabbagesHall/` | 30 MB | pack |
   | `WalkerRoom/` | 11 MB | pack |
   | `ArtificialPhysics/` | 9.2 MB | pack? |
   | `RecRoom/` | 5.3 MB (4.0 MB of it sound) | pack? |

   Everything else in `demo/` together is about 11 MB and stays in the base
   download: `basic/`, `constraint/`, `mesh/`, `module/`, `sound/`,
   `koppi/`, `claude/`, `jr/`, `jaimevives/`, and in `WyomingWill/` the
   `Clocks/`, `Walkers/`, `Hover/` and `tests/` folders, the loose scripts
   and the two shortcut PDFs. Is the Artificial Physics room a gallery? Is
   the Rec Room big enough to be worth a pack?

   Answer:

5. **What the Rec Room and the Walker Room borrow.** The Rec Room uses
   `../Clocks/`, `../Walkers/Jansen_6LegT.lua` and `../../koppi/marblerun.lua`
   (`rec-room.lua`, lines 740 to 758), and quietly leaves out what it
   doesn't find. The Walker Room loads its walkers from
   `../Walkers_For_Room/`, which nothing else uses. Once installed in the
   data folder, `../` is no longer `demo/WyomingWill/`, so these would just
   be missing. Suggested:
   - move `Walkers_For_Room/` into `WalkerRoom/` (640 KB, it already has a
     `.nomenu`);
   - for the Rec Room, `gallery.txt` lists the borrowed files and the pack
     carries copies at the same relative places (about 1 MB), so the
     scripts need no change.

   The other way is a new `v:` property naming the base `demo/` folder, for
   the rooms to look in as well; that is more code and a new API name.
   (Euler's Gallery, Babbage's Hall and the Artificial Physics room borrow
   nothing outside their folders but `demo/module/`, as far as a search of
   their scripts shows; step 2's check will confirm it.)

   Answer:

6. **What goes in a pack.** The galleries carry more than their exhibits:
   reports, handovers, PDFs and pictures (Babbage's Hall 13.6 MB of PNG and
   10.8 MB of PDF; the Walker Room 7.9 MB of PNG; Euler's Gallery 22 MB of
   `.obj` meshes, which its exhibits load). Suggested: a pack is the whole
   folder, as in the repository; the alternative is a list of what to leave
   out in `gallery.txt`. (A compiled Python file is tracked by mistake:
   `EulersGallery/report/__pycache__/front.cpython-313.pyc`.)

   Answer:

7. **How the galleries are started.** Euler's Gallery finds its own folder
   by trying `./` and then `demo/WyomingWill/EulersGallery/`; others do the
   same. From the Demos menu bpp changes into the script's folder first, so
   an installed gallery will be found at `./`. Do you start any of them
   another way that an installed gallery would need too (a run script, a
   command line), or are those only for working in the checkout?

   Answer:

8. **`gallery.txt`.** Suggested, one per gallery folder:

   ```
   name: The Rec Room
   needs-bpp: 0.3.40
   also: ../Clocks/
   also: ../Walkers/Jansen_6LegT.lua
   also: ../../koppi/marblerun.lua
   ```

   `needs-bpp` is raised by hand when a gallery starts relying on a newer
   bpp (or on a changed `demo/module/`, question 3); `also` lines only where
   question 5 needs them. Happy to keep `needs-bpp` up to date?

   Answer:

### For Jakob

9. **Unpacking: zip with miniz, or `.tar.gz` with the system's `tar`?**
   GNU tar, on Linux, reads `.tar.gz` but not `.zip`; the bsdtar of Windows
   10 (from version 1803) and macOS reads both; older Windows has none.
   With miniz (one `.c` and `.h`, MIT licence) the same code unpacks on
   every platform, the tests for a bad or truncated pack test what users
   run, and bpp needs no outside program. `bpp.pro` takes only `src/*.cpp`,
   so miniz needs one `SOURCES` line. Suggested: miniz.

   Answer:

10. **Where packs live.** Suggested: a GitHub release with the tag
    `galleries`, whose files the CI job replaces, rather than `gh-pages`:
    release files don't go into git history, and `gh-pages`' 161 MB of old
    screenshots shows what happens otherwise. The index is then always at
    `https://github.com/bullet-physics-playground/bpp/releases/download/galleries/galleries.json`
    (`v:download` already follows GitHub's redirect to its file server).
    Two details: the release must be published with `make_latest: false`,
    or the Releases page's "Latest" would point at the galleries instead of
    bpp; and the tag stays clear of `release.yml`'s `[0-9]+.[0-9]+.[0-9]+`,
    so it builds nothing. OK?

    Answer:

11. **Going online at start-up.** The design has bpp fetch the index at
    every start, with a setting to turn it off. Some users and packagers
    expect a program not to go online unasked. Suggested: on the first
    start, bpp asks once ("Check for gallery updates when bpp starts?"),
    and keeps the answer in its settings; the Galleries menu works either
    way.

    Answer:

12. **Where galleries go, and how they show.** Suggested:
    `v:dataDir()/galleries/`, keeping the folder's path from `demo/`
    (`galleries/WyomingWill/EulersGallery/`), so the Demos menu shows it in
    the same place as in a checkout and scripts' own files in
    `v:dataDir()` stay apart. When bpp runs from a checkout, `demo/`
    already holds every gallery: the Galleries menu shows those as "in
    demo/", and the start-up check skips them, so developers never download
    a pack or see a notice.

    Answer:

13. **C++ or Lua for the Galleries menu and the notice?** Suggested: C++
    in `src/gui.cpp`, since the check runs at start-up before any script
    and the menu is part of the window; the download code behind
    `v:download` can be shared rather than called through a script.

    Answer:

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
