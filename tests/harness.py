#!/usr/bin/env python3
"""
bpp regression test harness.

Runs bpp headless and checks its behaviour against what it did before.
Suites (run all of them with no arguments, or name the ones you want):

  unit     tests/NN-*.lua: each must print "N passed, 0 failed" and exit 0
           (a test with an "-- expect-error:" line must fail as it says).
  api      The Lua API (every bound class, its methods with their overload
           signatures, and its properties) against tests/api/lua-api.txt.
  render   A quick render (v:quickRender), with a stand-in povray first on
           PATH: how bpp calls POV-Ray (options, size, output file, frame,
           scene file, folder) is checked, without rendering.
  smoke    Every demo the Demos menu lists (all of demo/ but folders
           holding .nomenu) runs a few frames without a Lua error,
           crash or hang. Demos already broken are listed, with the reason,
           in tests/smoke/known-failures.txt.
  golden   The demos listed in tests/golden/demos.txt simulate N frames and
           export them to POV-Ray; object transforms, camera and scene text
           are compared, with a numeric tolerance, against
           tests/golden/expected/.
  screens  The still scenes in tests/screens/*.lua are opened in the GUI on
           a virtual X screen (Xvfb, Mesa) and the window is compared with
           tests/screens/expected/*.png (expected-qt6/ for a Qt 6 build).
  theory   (only when named) Euler's Gallery's exhibits run as their
           physics report ran them, and what each prints is checked
           against the theory it stands for: tests/theory/checks.txt.
           --slow adds the exhibits that take many minutes.

  --update rewrites the expected files of the suites run, from this build:
  do that only for a change in behaviour that is meant, and commit the
  result with the change that caused it.

Each bpp run gets its own empty HOME, XDG folders and BPP_USER_DIR (bpp's
settings, mesh cache, data and renders, see src/appenv.h), so the
developer's preferences, mesh cache and export directory never leak into a
result, nor a run's into the developer's: on Windows too, where bpp would
otherwise use the registry and AppData.

Usage:
  tests/harness.py [--bpp release/bpp] [--update] [--jobs N] [-k PATTERN]
                   [suite ...]
"""

import argparse
import concurrent.futures
import difflib
import glob
import hashlib
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTS = os.path.join(ROOT, "tests")
ALL_SUITES = ["unit", "api", "render", "smoke", "golden", "screens"]
# Run only when named: they take a while.
EXTRA_SUITES = ["theory"]
# The expected files of these hold what one platform produces (C++ type
# names as GCC's library spells them, Linux settings files, Mesa pixels).
LINUX_ONLY = ["api", "render", "golden", "screens"]

# Lines bpp writes that are not program behaviour: the device it ran on, Qt's
# notes about the headless platform. Dropped from logs before looking for
# errors.
NOISE = re.compile(
    r"^(ALSA lib |QStandardPaths: |qt\.qpa\.|libEGL warning|MESA-LOADER|"
    r"Fontconfig|QSocketNotifier|pci id for fd)"
)


# --------------------------------------------------------------------------
# running bpp
# --------------------------------------------------------------------------


class Run:
    def __init__(self, rc, out, seconds, workdir, timed_out):
        self.rc = rc
        self.out = out
        self.seconds = seconds
        self.workdir = workdir
        self.timed_out = timed_out

    def lines(self):
        return [l for l in self.out.splitlines() if not NOISE.match(l)]


def user_dir(workdir):
    """A run's BPP_USER_DIR: bpp.ini, cache/, data/, renders/."""
    return os.path.join(workdir, "user")


# Where bpp would write in HOME without BPP_USER_DIR (Linux names). A run that leaves any of these has a path that skips
# src/appenv.h, which on Windows writes into the developer's own profile.
# (Qt's own OpenGL shader cache, qtshadercache-*, also goes in the cache
# folder; bpp can't move it, and it holds nothing of bpp's.)
STRAY = [os.path.join(".config", "bullet-physics-playground.github.io"),
         os.path.join(".config", "Unknown Organization"),
         os.path.join(".cache", "bpp"),
         os.path.join(".local", "share", "bpp"),
         "Desktop"]


def stray_files(workdir):
    home = os.path.join(workdir, "home")
    out = []
    for rel in STRAY:
        path = os.path.join(home, rel)
        if os.path.isdir(path):
            out += [os.path.join(rel, f) for f in sorted(os.listdir(path))
                    if not f.startswith("qtshadercache")]
        elif os.path.exists(path):
            out.append(rel)
    return out


def profile_state():
    """On Windows, where a run's HOME moves nothing: bpp's registry keys
    (when each was last written) and every file in its AppData folders
    (when each was last changed), to compare before and after a whole
    harness run. None elsewhere, where stray_files sees the same in each
    run's own HOME."""
    if not sys.platform.startswith("win"):
        return None
    import winreg
    state = {}

    def walk(key):     # (a key's time changes with its own values only)
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key) as k:
                n, _, when = winreg.QueryInfoKey(k)
                subs = [winreg.EnumKey(k, i) for i in range(n)]
        except OSError:
            return
        state["HKEY_CURRENT_USER\\" + key] = when
        for sub in subs:
            walk(key + "\\" + sub)

    walk(r"Software\bullet-physics-playground.github.io\bpp")
    walk(r"Software\Unknown Organization\bpp")
    for var in ("LOCALAPPDATA", "APPDATA"):
        base = os.environ.get(var)
        for d, ds, fs in os.walk(os.path.join(base, "bpp")) if base else ():
            ds[:] = [x for x in ds if not x.startswith("qtshadercache")]
            for f in fs:
                try:
                    state[os.path.join(d, f)] = os.stat(os.path.join(d, f)).st_mtime_ns
                except OSError:
                    pass
    return state


def isolated_env(workdir, display=None):
    """Environment for one bpp run: its own HOME and BPP_USER_DIR under
    workdir, with POV-Ray exports going to workdir/export."""
    home = os.path.join(workdir, "home")
    user = user_dir(workdir)
    ini = os.path.join(user, "bpp.ini")
    if not os.path.exists(ini):
        # (Qt reads a backslash in an INI value as an escape: forward
        # slashes, which Windows takes too.)
        write(ini, "[povray]\nexport=%s\n" % os.path.join(workdir, "export").replace("\\", "/"))
    os.makedirs(home, exist_ok=True)
    env = dict(os.environ)
    env.update(
        BPP_USER_DIR=user,
        HOME=home,
        XDG_CONFIG_HOME=os.path.join(home, ".config"),
        XDG_CACHE_HOME=os.path.join(home, ".cache"),
        XDG_DATA_HOME=os.path.join(home, ".local", "share"),
        XDG_RUNTIME_DIR=os.path.join(home, ".runtime"),
        LC_ALL="C",
        SDL_AUDIODRIVER="dummy",
    )
    os.makedirs(env["XDG_RUNTIME_DIR"], mode=0o700, exist_ok=True)
    if display:
        env["DISPLAY"] = display
        env.pop("QT_QPA_PLATFORM", None)
        # The GUI takes its toolbar icons from the system icon theme when
        # there is one, from its own bundled set otherwise. Show it no
        # system data folders (and no desktop), so it always uses its own.
        env["XDG_DATA_DIRS"] = os.path.join(workdir, "share")
        for var in ("XDG_CURRENT_DESKTOP", "DESKTOP_SESSION", "QT_QPA_PLATFORMTHEME",
                    "QT_STYLE_OVERRIDE", "KDE_FULL_SESSION", "GNOME_DESKTOP_SESSION_ID"):
            env.pop(var, None)
    else:
        # Windows always has a window server, and a Windows build ships only
        # the native platform plugin; forcing offscreen there fails (see the
        # comment in src/main.cpp). A macOS app bundle has no offscreen
        # plugin either, so it runs with its own window server plugin.
        if sys.platform.startswith("win"):
            pass
        elif sys.platform == "darwin":
            env["QT_QPA_PLATFORM"] = "cocoa"
        else:
            env["QT_QPA_PLATFORM"] = "offscreen"
    return env


def run_bpp(bpp, args, workdir, timeout, cwd, env=None):
    """Runs bpp with args from directory cwd, its settings, cache and exports
    kept in workdir. (The GUI runs a script from the script's own directory,
    and demos find their data files from there.) env: more environment
    variables for the script."""
    extra = env or {}
    env = isolated_env(workdir)
    env.update(extra)
    start = time.time()
    try:
        p = subprocess.run(
            [bpp] + args,
            cwd=cwd,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
        out = p.stdout.decode("utf-8", "replace")
        # (worded so lua_errors, which every suite asks, sees it)
        for f in stray_files(workdir):
            out += "\nerror: bpp wrote %s outside BPP_USER_DIR\n" % f
        return Run(p.returncode, out, time.time() - start, workdir, False)
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"").decode("utf-8", "replace")
        return Run(None, out, time.time() - start, workdir, True)


def lua_errors(lines):
    """Lines that say a script failed (bpp prints these, it does not exit),
    or that a sanitizer build found a memory error or undefined behaviour."""
    pat = re.compile(
        r"(^error: |\[string \"|^-- \[string |lua runtime error in |"
        r"std::runtime_error|No matching overload|unable to make cast|"
        r"attempt to (call|index|perform|compare|concatenate)|bad argument #|"
        r"stack traceback|Segmentation fault|Aborted|terminate called|"
        r"pure virtual method called|ERROR: \w+Sanitizer|WARNING: ThreadSanitizer|"
        r": runtime error: )"
    )
    return [l for l in lines if pat.search(l)]


def read(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def show_diff(expected, got, name, limit=40):
    d = list(difflib.unified_diff(expected.splitlines(), got.splitlines(),
                                  "expected/" + name, "got/" + name,
                                  lineterm="", n=1))
    for l in d[:limit]:
        print("    " + l)
    if len(d) > limit:
        print("    ... %d more diff lines" % (len(d) - limit))


# --------------------------------------------------------------------------
# POV-Ray export: canonical form and tolerant comparison
# --------------------------------------------------------------------------
#
# A frame's .inc lists every object with its transform. Two things in it vary
# from run to run without the program behaving differently, so the canonical
# form takes them out:
#   - the order of the objects: bpp keeps them in a QSet, which iterates in
#     pointer-hash order. Blocks are sorted, and compared as a multiset.
#   - mesh include names, a hash of the mesh's vertices in the order they
#     come. OpenSCAD writes the same solid differently each run (triangles
#     in another order, some faces split along the other diagonal, the last
#     printed digit of a vertex), so the names become mesh_#, and each
#     mesh's geometry is compared on its own, in a "meshes" section: its
#     triangle and vertex counts, bounds and area (see mesh_summary), with
#     MESH_TOL.
# Also dropped: the date/user header line and the run's own cache path.

NUM = re.compile(r"(?<![\w.#])[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?(?![\w.])")
MESH = re.compile(r"mesh_[0-9a-f]{40}")
HEADER = re.compile(r"^(//|;) \d{4}-\d\d-\d\d \d\d:\d\d:\d\d by .*$", re.M)
UNBALANCED = "(braces do not balance in this file: an object was written without one)"
MESH_TOL = 1e-3  # absolute and relative, for the "meshes" section

# What a top-level POV-Ray statement starts with: used only to split a file
# whose braces do not balance.
POV_START = re.compile(
    r"\s*(object|camera|light_source|sphere|box|cylinder|cone|plane|torus|disc|"
    r"mesh2?|blob|union|difference|intersection|merge|text|sphere_sweep|lathe|"
    r"prism|superellipsoid|bicubic_patch|height_field|polygon|sor|isosurface|"
    r"parametric|quadric|poly|global_settings|background|fog|sky_sphere|"
    r"#\w+)\b")


def _split(text, at_new_object):
    blocks, cur, depth, blank = [], [], 0, False
    for line in text.splitlines():
        line = line.rstrip()
        if not line:
            blank = True
            continue
        if blank and cur:
            if depth <= 0 or (at_new_object and POV_START.match(line)):
                blocks.append("\n".join(cur))
                cur, depth = [], 0
            else:
                cur.append("")
        cur.append(line)
        depth += line.count("{") - line.count("}")
        blank = False
    if cur:
        blocks.append("\n".join(cur))
    return blocks


def _blocks(text):
    """Top-level blocks of a POV file: bpp ends each with a blank line where
    the braces balance (it also puts blank lines inside some objects).
    Returns (blocks, balanced). In a file whose braces do not balance, a
    block also ends at a blank line followed by a new object, so one bad
    object does not swallow the (randomly ordered) objects after it."""
    depth, low = 0, 0
    for line in text.splitlines():
        depth += line.count("{") - line.count("}")
        low = min(low, depth)
    if depth == 0 and low == 0:
        return _split(text, False), True
    return _split(text, True), False


def _parse_mesh2(text):
    """Triangles of a mesh2 include as tuples of vertex texts, or None."""
    vv = re.search(r"vertex_vectors\s*\{\s*\d+\s*,(.*?)\}", text, re.S)
    fi = re.search(r"face_indices\s*\{\s*\d+\s*,(.*?)\}", text, re.S)
    if not vv or not fi:
        return None
    verts = [tuple(c.strip() for c in v.split(",")) for v in re.findall(r"<([^>]*)>", vv.group(1))]
    tris = []
    for f in re.findall(r"<([^>]*)>", fi.group(1)):
        a, b, c = (int(i) for i in f.split(","))
        tris.append((verts[a], verts[b], verts[c]))
    return tris


def mesh_summary(path):
    """A mesh include's geometry as one block of text: triangle and distinct
    vertex counts, bounding box and surface area. These do not change with
    the order of triangles or how a face is split into them."""
    if not os.path.exists(path):
        return "mesh (missing %s)" % os.path.basename(path)
    tris = _parse_mesh2(read(path))
    if tris is None:
        return "mesh (not a mesh2)\n" + MESH.sub("mesh_#", read(path))
    verts = {tuple(float(c) for c in v) for t in tris for v in t}
    lo = [min(v[i] for v in verts) for i in range(3)]
    hi = [max(v[i] for v in verts) for i in range(3)]
    area = 0.0
    for t in tris:
        a, b, c = (tuple(float(x) for x in v) for v in t)
        u = [b[i] - a[i] for i in range(3)]
        w = [c[i] - a[i] for i in range(3)]
        n = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
        area += 0.5 * math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    return ("mesh2 { triangles %d vertices %d\n  bounds <%.6g, %.6g, %.6g>, <%.6g, %.6g, %.6g>\n"
            "  area %.6g\n}" % ((len(tris), len(verts)) + tuple(lo) + tuple(hi) + (area,)))


def _key_nums(block):
    nums = [float(m.group(0)) for m in NUM.finditer(block)]
    key = NUM.sub("#", block)
    return key, nums


def canon_export(scene_dir, cache, frames):
    """Canonical text of an export directory: the scene, the .ini, the
    given frames and any sound track, with meshes named by their geometry.
    Blocks within a file are sorted by their text with the numbers taken
    out, then by the numbers. Raises ValueError if a file is missing."""
    name = os.path.basename(scene_dir)
    files = [name + ".pov", name + ".ini"] + ["%05d.inc" % f for f in frames]
    meshes = set()

    def mesh_name(m):
        meshes.add(m.group(0))
        return "mesh_#"

    out = []
    for fn in files:
        path = os.path.join(scene_dir, fn)
        if not os.path.exists(path):
            raise ValueError("the export has no %s" % fn)
        text = read(path)
        text = HEADER.sub("", text)
        # (named as it was when the cache was ~/.cache/bpp, as the
        # expected files have it)
        text = text.replace(cache, "$CACHE/bpp")
        text = MESH.sub(mesh_name, text)
        blocks, balanced = _blocks(text)
        blocks = sorted(blocks, key=lambda b: (_key_nums(b)[0], _key_nums(b)[1]))
        out.append("== " + fn)
        if not balanced:
            out.append(UNBALANCED)
            out.append("")
        out.append("\n\n".join(blocks))
        out.append("")
    # the scene's sound track, if it played anything (Viewer::saveWAV); with
    # SDL's dummy audio driver (isolated_env) it is the same on every machine
    for fn in sorted(f for f in os.listdir(scene_dir) if f.endswith(".wav")):
        with open(os.path.join(scene_dir, fn), "rb") as f:
            data = f.read()
        out.append("== " + fn)
        out.append("sound track: %d bytes, md5 %s" % (len(data), hashlib.md5(data).hexdigest()))
        out.append("")
    out.append("== meshes")
    out.append("\n\n".join(sorted(mesh_summary(os.path.join(scene_dir, m + ".inc"))
                                   for m in meshes)))
    return "\n".join(out).rstrip("\n") + "\n"


def _parse_canon(text):
    """{file: [(key, nums), ...]} from canonical text."""
    files, cur = {}, None
    for chunk in re.split(r"^== (.*)$", text, flags=re.M)[1:]:
        if cur is None:
            cur = chunk.strip()
            continue
        text = chunk.replace(UNBALANCED, "")
        files[cur] = [_key_nums(b) for b in _blocks(text)[0]]
        if UNBALANCED in chunk:
            files[cur].append((UNBALANCED, []))
        cur = None
    return files


def _label(key):
    """A block's first line that says what it is (not a lone brace)."""
    for line in key.strip().splitlines():
        if re.search(r"[A-Za-z]", line):
            return line.strip()[:60]
    return key.strip()[:60]


def _close(expected, got, atol, rtol):
    if not (math.isfinite(expected) and math.isfinite(got)):
        return expected == got
    return abs(expected - got) <= atol + rtol * abs(expected)


def compare_canon(expected, got, atol, rtol):
    """Problems found comparing two canonical exports (empty: same within
    tolerance). Blocks of the same shape are paired by nearest numbers."""
    problems = []
    e_files, g_files = _parse_canon(expected), _parse_canon(got)
    for fn in sorted(set(e_files) | set(g_files)):
        if fn not in e_files or fn not in g_files:
            problems.append("%s: only in %s" % (fn, "got" if fn in g_files else "expected"))
            continue
        groups = {}
        for side, blocks in (("e", e_files[fn]), ("g", g_files[fn])):
            for key, nums in blocks:
                groups.setdefault(key, {"e": [], "g": []})[side].append(nums)
        a, r = (max(atol, MESH_TOL), max(rtol, MESH_TOL)) if fn == "meshes" else (atol, rtol)
        worst, off = (0.0, None), 0
        for key, sides in groups.items():
            es, gs = sides["e"], sides["g"]
            if len(es) != len(gs):
                problems.append("%s: %d objects like '%s', expected %d"
                                % (fn, len(gs), _label(key), len(es)))
                continue
            # Pair exact matches, then each remaining one with its nearest.
            remaining = list(gs)
            unmatched = []
            for en in es:
                if en in remaining:
                    remaining.remove(en)
                else:
                    unmatched.append(en)
            for en in unmatched:
                best = min(remaining, key=lambda gn: max(
                    (abs(x - y) for x, y in zip(en, gn)), default=0.0))
                remaining.remove(best)
                for i, (x, y) in enumerate(zip(en, best)):
                    if not _close(x, y, a, r):
                        off += 1
                        d = abs(x - y)
                        if d > worst[0]:
                            worst = (d, "'%s' value #%d is %g, expected %g"
                                     % (_label(key), i, y, x))
        if worst[1]:
            problems.append("%s: %d value%s off; worst: %s"
                            % (fn, off, "" if off == 1 else "s", worst[1]))
    return problems


# --------------------------------------------------------------------------
# suites
# --------------------------------------------------------------------------


class Ctx:
    def __init__(self, a):
        self.bpp = os.path.abspath(a.bpp)
        self.update = a.update
        self.jobs = a.jobs
        self.pattern = re.compile(a.k) if a.k else None
        self.keep = a.keep
        self.tmp = tempfile.mkdtemp(prefix="bpp-tests-")
        self.atol = a.atol
        self.rtol = a.rtol
        self.slow = a.slow

    def workdir(self, name):
        d = os.path.join(self.tmp, re.sub(r"[^\w.-]", "_", name))
        shutil.rmtree(d, ignore_errors=True)
        os.makedirs(d)
        return d

    def selected(self, names):
        return [n for n in names if not self.pattern or self.pattern.search(n)]


def pmap(ctx, fn, items):
    """fn over items on ctx.jobs threads (each runs one bpp), in order."""
    with concurrent.futures.ThreadPoolExecutor(ctx.jobs) as ex:
        yield from ex.map(fn, items)


def list_file(path):
    """Entries of a list file, skipping blank and # comment lines:
    (first word, rest of the line)."""
    out = []
    for line in read(path).splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            parts = line.split(None, 1)
            out.append((parts[0], parts[1] if len(parts) > 1 else ""))
    return out


# -- unit ------------------------------------------------------------------

SUMMARY = re.compile(r"^(\d+) passed, (\d+) failed$")


def unit_expectations(test):
    """A unit test's "-- expect-error: PATTERN" line (it passes if bpp reports
    an error matching PATTERN and exits 1, and needs no "N passed" line), its
    "-- not-printed: TEXT" lines (output lines that must not appear) and its
    "-- expect-line: PATTERN" lines (each must match an output line)."""
    expect_error, not_printed, expect_lines = None, [], []
    with open(test) as f:
        for line in f:
            m = re.match(r"--\s*expect-error:\s*(.+?)\s*$", line)
            if m:
                expect_error = m.group(1)
            m = re.match(r"--\s*expect-line:\s*(.+?)\s*$", line)
            if m:
                expect_lines.append(m.group(1))
            m = re.match(r"--\s*not-printed:\s*(.+?)\s*$", line)
            if m:
                not_printed.append(m.group(1))
    return expect_error, not_printed, expect_lines


def suite_unit(ctx):
    tests = ctx.selected(sorted(f for f in os.listdir(TESTS)
                                if re.match(r"\d\d-.*\.lua$", f)))

    def one(t):
        r = run_bpp(ctx.bpp, ["-f", os.path.join(TESTS, t)], ctx.workdir("unit-" + t), 300, ROOT)
        lines = r.lines()
        expect_error, not_printed, expect_lines = unit_expectations(os.path.join(TESTS, t))
        if expect_error:
            # a test of how a failing script is reported: the error is the point
            why = []
            if r.timed_out:
                why.append("timed out")
            elif r.rc != 1:   # (a script that fails fails the run: parse() is false)
                why.append("exit code %s, not 1" % r.rc)
            if not any(re.search(expect_error, l) for l in lines):
                why.append("no error matching %s" % expect_error)
                why += lua_errors(lines)[:5]
            why += ["printed %r: the script went on" % l for l in lines if l in not_printed]
            why += ["no line matching %s" % p for p in expect_lines
                    if not any(re.search(p, l) for l in lines)]
            return t, why, "the error as expected" if not why else "", r.seconds
        sums = [SUMMARY.match(l.strip()) for l in lines]
        sums = [m for m in sums if m]
        why = []
        if r.timed_out:
            why.append("timed out")
        elif r.rc != 0:
            why.append("exit code %s" % r.rc)
        if not sums:
            why.append("no 'N passed, M failed' line (script stopped early?)")
        elif int(sums[-1].group(2)) > 0:
            why.append("%s failed" % sums[-1].group(2))
        why += [l for l in lines if l.startswith("FAIL")][:10]
        why += lua_errors(lines)[:5]
        return t, why, (sums[-1].group(0) if sums else ""), r.seconds

    failed = 0
    for t, why, summary, secs in pmap(ctx, one, tests):
        print("  %-4s %-28s %5.1fs  %s" % ("ok" if not why else "FAIL", t, secs, summary))
        for w in why:
            print("         " + w)
        failed += bool(why)
    return failed


# -- api -------------------------------------------------------------------

API_LUA = os.path.join(TESTS, "api", "dump-api.lua")
API_EXPECTED = os.path.join(TESTS, "api", "lua-api.txt")


def suite_api(ctx):
    r = run_bpp(ctx.bpp, ["-f", API_LUA], ctx.workdir("api"), 120, ROOT)
    lines = r.lines()
    got = [l[4:] for l in lines if l.startswith("API ")]
    if r.rc != 0 or not got or lua_errors(lines):
        print("  FAIL dump-api.lua did not run:")
        for l in lines[-10:]:
            print("    " + l)
        return 1
    # A QVector and a QList reach Lua as the same table, and in Qt 6 they
    # are one type, which luabind names QList: the Qt 5 and Qt 6 builds
    # share one expected file.
    got = "\n".join(got).replace("QVector<", "QList<") + "\n"
    if ctx.update:
        write(API_EXPECTED, got)
        print("  updated %s (%d lines)" % (os.path.relpath(API_EXPECTED, ROOT), got.count("\n")))
        return 0
    expected = read(API_EXPECTED)
    if got == expected:
        print("  ok   %d classes, %d lines" % (len(re.findall(r"^class ", got, re.M)), got.count("\n")))
        return 0
    print("  FAIL the Lua API changed (scripts may break). If that is meant, run")
    print("       tests/harness.py --update api  and commit tests/api/lua-api.txt:")
    show_diff(expected, got, "lua-api.txt")
    return 1


# -- render ----------------------------------------------------------------

RENDER = os.path.join(TESTS, "render")


def suite_render(ctx):
    """tests/render/quick.lua quick-renders frame 2 with extra options; the
    stand-in tests/render/standin/povray, first on PATH, writes how it was
    called. bpp's own side of a quick render is checked against that:
    which program, the options (the default preview's), the size (the
    view's: 640x480 headless), the PNG in renders/ (the desktop, without
    BPP_USER_DIR; made if missing) named after the scene and frame, POV-Ray's clock, the scene file, the
    extra options (one argument each), and the folder (the scene's
    export, holding the .pov). The
    Ubuntu POV-Ray is 3.7, which won't read bpp's 3.8 scenes, so nothing
    is rendered."""
    wd = ctx.workdir("render")      # (it has no renders/ yet: bpp makes it)
    env = {"PATH": os.path.join(RENDER, "standin") + os.pathsep + os.environ.get("PATH", "")}
    r = run_bpp(ctx.bpp, ["-f", "quick.lua", "-n", "4"], wd, 120, RENDER, env)
    home = os.path.join(wd, "home")
    call = os.path.join(home, "povray-call.txt")
    for _ in range(100):                  # (POV-Ray is started, not waited for)
        if os.path.exists(call):
            break
        time.sleep(0.1)
    why = lua_errors(r.lines())[:5]
    if r.rc != 0:
        why.append("exit code %s" % r.rc)
    if not os.path.exists(call):
        why.append("povray was not run")
    else:
        time.sleep(0.2)                   # (let it finish writing)
        with open(call) as f:
            got = f.read().split("\n")[:-1]
        folder, args = got[0], got[1:]
        export = os.path.join(wd, "export", "quick")
        cache = os.path.join(user_dir(wd), "cache")
        renders = os.path.join(user_dir(wd), "renders")
        png = re.compile(re.escape("+O" + renders) +
                         r"/bpp-\d{8}-\d{6}-quick-00002\.png$")
        want = ["+L" + cache, "+L" + os.path.join(RENDER, "includes"),
                "-c", "+d", "-A", "+p", "+Q11", "+GA", "+FN10",
                "+W640", "+H480", "+F", png, "+K2", "quick.pov", "+W160", "+H120"]
        if folder != export:
            why.append("ran in %s, not %s" % (folder, export))
        if not os.path.exists(os.path.join(export, "quick.pov")):
            why.append("no quick.pov exported in %s" % export)
        if len(args) != len(want):
            why.append("%d arguments, not %d: %s" % (len(args), len(want), args))
        for i, (g, w) in enumerate(zip(args, want)):
            ok = w.match(g) if hasattr(w, "match") else g == w
            if not ok:
                why.append("argument %d: %r, not %r" % (i + 1, g, getattr(w, "pattern", w)))
        if not why and not glob.glob(os.path.join(renders, "bpp-*-quick-00002.png")):
            why.append("the PNG asked for was not written")
    print("  %-4s %-28s %5.1fs" % ("ok" if not why else "FAIL", "quick.lua", r.seconds))
    for w in why:
        print("         " + w)
    return int(bool(why))


# -- smoke -----------------------------------------------------------------

SMOKE_KNOWN = os.path.join(TESTS, "smoke", "known-failures.txt")
SMOKE_FRAMES = 3


def all_demos():
    """Every .lua under demo/ that the Demos menu lists: a folder holding a
    file named .nomenu is left out, with everything under it, as there
    (src/gui.cpp, populateDemoMenu) -- scripts other scripts load, probes,
    tools."""
    demos = []
    for d, ds, fs in os.walk(os.path.join(ROOT, "demo")):
        ds[:] = [x for x in ds if not os.path.exists(os.path.join(d, x, ".nomenu"))]
        for f in fs:
            if f.endswith(".lua"):
                demos.append(os.path.relpath(os.path.join(d, f), ROOT))
    return sorted(demos)


def smoke_check(ctx, demo):
    path = os.path.join(ROOT, demo)
    r = run_bpp(ctx.bpp, ["-f", path, "-n", str(SMOKE_FRAMES)],
                ctx.workdir("smoke-" + demo), 300, os.path.dirname(path))
    if r.timed_out:
        return "timed out", r
    errs = lua_errors(r.lines())
    if errs:
        why = errs[0].replace(ctx.tmp, "$TMP").replace(ROOT, "$ROOT")
        return why[:150], r
    if r.rc != 0:
        return "exit code %s" % r.rc, r
    return None, r


def untracked_demo_files():
    """Files under demo/ git does not know about (None outside a checkout)."""
    try:
        files = set()
        for extra in ([], ["--ignored"]):  # (.gitignore hides *.scad, anim/, ...)
            r = subprocess.run(["git", "ls-files", "--others", "--exclude-standard"] + extra + ["demo"],
                               cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=True)
            files |= set(r.stdout.decode().splitlines())
    except (OSError, subprocess.CalledProcessError):
        return None
    return files


def report_new_files(before):
    """Fails when demos wrote files into the source tree during the suite: a
    demo that writes next to itself must be skipped (smoke) or left out."""
    after = untracked_demo_files()
    if before is None or after is None or not after - before:
        return 0
    print("  FAIL demos wrote files into the source tree (delete them, and mark")
    print("       the demo 'skip' in tests/smoke/known-failures.txt):")
    for f in sorted(after - before):
        print("         " + f)
    return 1


def _gist(reason):
    """A failure reason without its numbers, for comparing with the known one."""
    return re.sub(r"\d+", "#", reason.strip())[:120]


def suite_smoke(ctx):
    known = dict(list_file(SMOKE_KNOWN)) if os.path.exists(SMOKE_KNOWN) else {}
    skipped = {d for d, why in known.items() if why.startswith("skip")}
    selected = ctx.selected(all_demos())
    demos = [d for d in selected if d not in skipped]
    before = untracked_demo_files()
    failed, fixed, results = 0, [], {}
    for demo, (why, r) in zip(demos, pmap(ctx, lambda d: smoke_check(ctx, d), demos)):
        results[demo] = why
        if why and demo not in known:
            print("  FAIL %-60s %s" % (demo, why))
            failed += 1
        elif why and _gist(why) != _gist(known[demo]) and not ctx.update:
            print("  FAIL %-60s fails differently now: %s" % (demo, why))
            print("       %-60s (known: %s)" % ("", known[demo]))
            failed += 1
        elif not why and demo in known:
            fixed.append(demo)
    if ctx.update:
        entries = ["# Demos that fail the smoke test (tests/harness.py smoke) on the",
                   "# current code: a Lua error, a crash, a hang, or a missing tool.",
                   "# Listed so a new failure stands out; remove a line when the demo",
                   "# is fixed. Written by tests/harness.py --update smoke, which keeps",
                   "# the 'skip' lines: scripts that are not run at all.", ""]
        merged = dict(known) if ctx.pattern else {d: known[d] for d in skipped}
        for d, why in results.items():
            merged.pop(d, None)
            if why:
                merged[d] = why
        entries += ["%s  %s" % (d, merged[d]) for d in sorted(merged)]
        write(SMOKE_KNOWN, "\n".join(entries) + "\n")
        print("  updated %s (%d known failures, %d skipped)"
              % (os.path.relpath(SMOKE_KNOWN, ROOT), len(merged) - len(skipped), len(skipped)))
        return report_new_files(before)
    failed += report_new_files(before)
    for d in fixed:
        print("  note %-60s now passes: remove it from known-failures.txt" % d)
    print("  %d demos, %d new failures, %d known failures, %d skipped"
          % (len(demos), failed, sum(1 for d in demos if d in known),
             len(selected) - len(demos)))
    return failed


# -- golden ----------------------------------------------------------------

GOLDEN_LIST = os.path.join(TESTS, "golden", "demos.txt")
GOLDEN_DIR = os.path.join(TESTS, "golden", "expected")
GOLDEN_FRAMES = 40


def golden_canon(ctx, bpp, demo, tag):
    wd = ctx.workdir("golden-%s-%s" % (tag, demo))
    path = os.path.join(ROOT, demo)
    r = run_bpp(bpp, ["-f", path, "-n", str(GOLDEN_FRAMES), "-e"], wd, 600, os.path.dirname(path))
    errs = lua_errors(r.lines())
    if r.timed_out or r.rc != 0 or errs:
        return None, (errs[:1] or ["exit code %s%s" % (r.rc, " (timed out)" if r.timed_out else "")])[0]
    name = os.path.splitext(os.path.basename(demo))[0]
    scene = os.path.join(wd, "export", name)
    try:
        text = canon_export(scene, os.path.join(user_dir(wd), "cache"),
                            [1, GOLDEN_FRAMES // 2, GOLDEN_FRAMES])
    except ValueError as e:
        return None, str(e)
    if not ctx.keep:
        shutil.rmtree(wd, ignore_errors=True)
    return text, None


def golden_path(demo):
    return os.path.join(GOLDEN_DIR, re.sub(r"\.lua$", ".txt", demo[len("demo/"):]))


def suite_golden(ctx, baseline=None):
    demos = ctx.selected([d for d, _ in list_file(GOLDEN_LIST)])

    def one(demo):
        got, err = golden_canon(ctx, ctx.bpp, demo, "got")
        if err:
            return demo, ["did not run: " + err]
        if baseline:
            expected, err = golden_canon(ctx, baseline, demo, "base")
            if err:
                return demo, ["baseline did not run: " + err]
        elif ctx.update:
            write(golden_path(demo), got)
            return demo, None
        else:
            if not os.path.exists(golden_path(demo)):
                return demo, ["no expected file; run --update golden"]
            expected = read(golden_path(demo))
        if got == expected:
            return demo, []
        problems = compare_canon(expected, got, ctx.atol, ctx.rtol)
        if problems and ctx.keep:
            saved = os.path.join(ctx.tmp, "golden-got", os.path.relpath(golden_path(demo), GOLDEN_DIR))
            write(saved, got)
            problems.append("this run's export, to diff against the expected file: " + saved)
        return demo, problems

    before = untracked_demo_files()
    failed = 0
    for demo, problems in pmap(ctx, one, demos):
        if problems is None:
            print("  upd  %s" % demo)
        elif problems:
            print("  FAIL %s" % demo)
            for p in problems[:6]:
                print("         " + p)
            failed += 1
        else:
            print("  ok   %s" % demo)
    return failed + report_new_files(before)


# -- screens ---------------------------------------------------------------
#
# The GUI simulates in real time, so a moving scene is in a different state
# each time the screen is grabbed. The scenes here hold still (every body has
# mass 0); what they test is drawing. Needs Xvfb, xdotool and ImageMagick.

SCREENS = os.path.join(TESTS, "screens")
SCREEN_SIZE = (1280, 800)
SCREEN_SETTLE = 3          # seconds after the window appears, at least
SCREEN_WAIT = 90           # seconds for the picture to stop changing, at most
FONTS = "/usr/share/fonts/truetype/dejavu"  # the only fonts the GUI is given
SCREEN_FUZZ = "8%"         # per-pixel colour tolerance
SCREEN_MAX_PIXELS = 0.0002  # fraction of pixels allowed to differ (about 200)
STATUS_BAR = 30            # bottom rows masked: the frame counter ticks


def have(*tools):
    return [t for t in tools if not shutil.which(t)]


def start_xvfb():
    for n in range(90, 110):
        if os.path.exists("/tmp/.X11-unix/X%d" % n) or os.path.exists("/tmp/.X%d-lock" % n):
            continue
        p = subprocess.Popen(["Xvfb", ":%d" % n, "-screen", "0", "1600x1000x24", "-nolisten", "tcp"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if os.path.exists("/tmp/.X11-unix/X%d" % n):
                return p, ":%d" % n
            time.sleep(0.1)
        p.kill()
    raise RuntimeError("could not start Xvfb")


def pinned_fonts(wd):
    """A fontconfig file offering only DejaVu, so the window's text looks
    the same whatever fonts the machine has (None if DejaVu is missing)."""
    if not os.path.isdir(FONTS):
        return None
    conf = os.path.join(wd, "fonts.conf")
    aliases = {"DejaVu Sans": ["sans-serif", "Sans Serif", "Sans", "Helvetica", "Arial"],
               "DejaVu Sans Mono": ["monospace", "Monospace", "Courier", "Courier New"],
               "DejaVu Serif": ["serif", "Serif", "Times"]}
    rules = "".join("<alias><family>%s</family><prefer><family>%s</family></prefer></alias>"
                    % (name, font) for font, names in aliases.items() for name in names)
    write(conf, '<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n'
                "<fontconfig><dir>%s</dir><cachedir>%s</cachedir>%s</fontconfig>\n"
                % (FONTS, os.path.join(wd, "fontcache"), rules))
    return conf


def scene_input(scene):
    """A screen scene's input lines: its "-- xdotool: ..." lines, xdotool
    commands run in order once the window is up (WIN stands for the
    window), and its "-- mouse: X Y" line, where in the window the pointer
    then rests (None: it stays off the window)."""
    commands, mouse = [], None
    with open(scene) as f:
        for line in f:
            m = re.match(r"--\s*mouse:\s*(\d+)\s+(\d+)\s*$", line)
            if m:
                mouse = m.group(1), m.group(2)
            m = re.match(r"--\s*xdotool:\s*(.+?)\s*$", line)
            if m:
                commands.append(m.group(1).split())
    return commands, mouse


def grab(ctx, display, scene, out_png):
    """Opens scene in the GUI, sizes the window, and grabs it to out_png
    once two grabs a second apart are the same (the scene has loaded).
    A scene's "-- xdotool:" lines are run first (keys, drags, wheel turns);
    with a "-- mouse:" line the pointer then rests there. For a scene with
    either, the screen under the window is grabbed, so a tooltip shows
    too."""
    wd = ctx.workdir("screens-" + os.path.basename(scene))
    why = _grab(ctx, display, scene, out_png, wd)
    strays = stray_files(wd)
    if why is None and strays:
        why = "bpp wrote %s outside BPP_USER_DIR" % ", ".join(strays)
    return why


def _grab(ctx, display, scene, out_png, wd):
    env = isolated_env(wd, display)
    fonts = pinned_fonts(wd)
    if fonts:
        env["FONTCONFIG_FILE"] = fonts
    log = open(os.path.join(wd, "bpp.log"), "w")
    p = subprocess.Popen([ctx.bpp, scene], cwd=wd, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        win = None
        for _ in range(100):
            r = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "^bpp "],
                               env=env, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            ids = r.stdout.split()
            if ids:
                win = ids[0].decode()
                break
            time.sleep(0.2)
        if not win:
            return "bpp window did not appear (see %s)" % log.name
        subprocess.run(["xdotool", "windowmove", win, "0", "0",
                        "windowsize", win, str(SCREEN_SIZE[0]), str(SCREEN_SIZE[1])], env=env)
        time.sleep(SCREEN_SETTLE)
        commands, mouse = scene_input(scene)
        for c in commands:
            subprocess.run(["xdotool"] + [win if a == "WIN" else a for a in c], env=env)
            time.sleep(0.3)   # (Qt sees each before the next)
        if mouse:
            subprocess.run(["xdotool", "mousemove", "--window", win] + list(mouse), env=env)
        if p.poll() is not None:
            how = ("crashed (signal %d)" % -p.returncode if p.returncode < 0
                   else "exited (code %d)" % p.returncode)
            return "bpp %s while the scene's input ran (see %s)" % (how, log.name)
        if commands or mouse:
            # the window at the screen's corner (windowmove above)
            r = subprocess.run(["xdotool", "getwindowgeometry", "--shell", win], env=env,
                               stdout=subprocess.PIPE, check=True)
            g = dict(l.split("=", 1) for l in r.stdout.decode().split())
            what = ["-window", "root", "-crop", "%sx%s+%s+%s" % (g["WIDTH"], g["HEIGHT"], g["X"], g["Y"]),
                    "+repage"]  # (not the screen's size and place, as a window grab)
        else:
            what = ["-window", win]
        prev = os.path.join(wd, "prev.png")
        deadline = time.time() + SCREEN_WAIT
        subprocess.run(["import"] + what + [prev], env=env, check=True)
        while True:
            time.sleep(1)
            if p.poll() is not None:
                return "bpp exited early (see %s)" % log.name
            subprocess.run(["import"] + what + [out_png], env=env, check=True)
            if image_diff(prev, out_png, None, fuzz="0%") == 0:
                return None
            if time.time() > deadline:
                return "the picture kept changing for %ds" % SCREEN_WAIT
            shutil.copy(out_png, prev)
    finally:
        p.terminate()
        try:
            p.wait(10)
        except subprocess.TimeoutExpired:
            p.kill()
        log.close()


def image_diff(expected, got, diff_png, fuzz=SCREEN_FUZZ):
    """Fraction of pixels that differ by more than SCREEN_FUZZ, outside the
    status bar; None if the sizes differ."""
    def size(png):
        r = subprocess.run(["identify", "-format", "%w %h", png], stdout=subprocess.PIPE, check=True)
        return tuple(int(x) for x in r.stdout.split())
    if size(expected) != size(got):
        return None
    w, h = size(expected)
    crop = "%dx%d+0+0" % (w, h - STATUS_BAR)
    r = subprocess.run(["compare", "-metric", "AE", "-fuzz", fuzz,
                        expected + "[%s]" % crop, got + "[%s]" % crop, diff_png or "null:"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return float(r.stderr.split()[0]) / (w * (h - STATUS_BAR))


def diff_region(expected, got):
    """Bounding box (WxH+X+Y) of the pixels that differ, outside the
    status bar: says in the log where the window changed."""
    r = subprocess.run(["identify", "-format", "%w %h", expected], stdout=subprocess.PIPE, check=True)
    w, h = (int(x) for x in r.stdout.split())
    crop = "[%dx%d+0+0]" % (w, h - STATUS_BAR)
    r = subprocess.run(["convert", expected + crop, got + crop, "-compose", "difference",
                        "-composite", "-colorspace", "gray", "-threshold", SCREEN_FUZZ,
                        "-format", "%@", "info:"], stdout=subprocess.PIPE)
    return r.stdout.decode().strip()


def qt_major(bpp):
    """The Qt version bpp is built with, 5 or 6, from the library it links."""
    r = subprocess.run(["ldd", bpp], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    return 6 if b"libQt6Core" in r.stdout else 5


def suite_screens(ctx):
    missing = have("Xvfb", "xdotool", "import", "compare", "identify")
    if missing:
        print("  FAIL missing tools: %s (apt install xvfb xdotool imagemagick)" % " ".join(missing))
        return 1
    # Qt 6 draws the menus, toolbar and docks in other sizes, so the 3D view
    # sits elsewhere: its build has its own expected images.
    expected_dir = os.path.join(SCREENS, "expected" if qt_major(ctx.bpp) == 5 else "expected-qt6")
    scenes = ctx.selected(sorted(f for f in os.listdir(SCREENS) if f.endswith(".lua")))
    xvfb, display = start_xvfb()
    failed = 0
    try:
        for s in scenes:  # one at a time: they share the screen
            name = s[:-4]
            expected = os.path.join(expected_dir, name + ".png")
            got = os.path.join(ctx.tmp, "screens-" + name + ".png")
            err = grab(ctx, display, os.path.join(SCREENS, s), got)
            if err:
                print("  FAIL %-24s %s" % (s, err))
                failed += 1
                continue
            if ctx.update:
                os.makedirs(os.path.dirname(expected), exist_ok=True)
                shutil.copy(got, expected)
                print("  upd  %s" % s)
                continue
            if not os.path.exists(expected):
                print("  FAIL %-24s no expected image; run --update screens" % s)
                failed += 1
                continue
            diff_png = os.path.join(ctx.tmp, "screens-" + name + "-diff.png")
            frac = image_diff(expected, got, diff_png)
            if frac is None or frac > SCREEN_MAX_PIXELS:
                print("  FAIL %-24s %s; got %s, diff %s" % (
                    s, "size differs" if frac is None else "%.2f%% of pixels differ, within %s"
                    % (100 * frac, diff_region(expected, got)), got, diff_png))
                failed += 1
            else:
                print("  ok   %-24s %.3f%% of pixels differ" % (s, 100 * frac))
    finally:
        # Not kill(): a killed Xvfb leaves its lock file, and the displays
        # start_xvfb() tries run out after twenty runs.
        xvfb.terminate()
        try:
            xvfb.wait(10)
        except subprocess.TimeoutExpired:
            xvfb.kill()
    return failed


# --------------------------------------------------------------------------


# -- theory ----------------------------------------------------------------

THEORY_CHECKS = os.path.join(TESTS, "theory", "checks.txt")
GALLERY = os.path.join(ROOT, "demo", "WyomingWill", "EulersGallery", "exhibits")
NUMBER = r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
EXPECT = re.compile(r"^(?P<pat>.*?)(?:\s+=\s*(?P<val>%s))?(?:\s+~\s*(?P<tol>%s%%?))?"
                    r"(?:\s+x(?P<n>\d+))?\s*$" % (NUMBER, NUMBER))


class TheoryCheck:
    """One expect: line. Its pattern is the text of a line the exhibit
    prints, with {sim} for the simulation's number, {theory} for theory's
    when the line gives it (or "= VALUE" after the pattern), {} for any
    other number and {*} for any text; runs of spaces match any spacing.
    "~ TOL" is how far sim may be from theory: "0.05%" of theory, or "0.2"
    as it is. "xN": at least N lines must match (default 1). With no
    {sim}, the line need only be there."""

    def __init__(self, text, where):
        m = EXPECT.match(text)
        self.text, self.where = text, where
        pat = m.group("pat").strip()
        self.value = float(m.group("val")) if m.group("val") else None
        tol = m.group("tol")
        self.rel = tol.endswith("%") if tol else False
        self.tol = float(tol.rstrip("%")) if tol else None
        self.count = int(m.group("n") or 1)
        parts = re.split(r"(\{sim\}|\{theory\}|\{\}|\{\*\}|\s+)", pat)
        rx = ""
        for p in parts:
            if p == "{sim}":
                rx += "(?P<sim>%s)" % NUMBER
            elif p == "{theory}":
                rx += "(?P<theory>%s)" % NUMBER
            elif p == "{}":
                rx += NUMBER
            elif p == "{*}":
                rx += ".*?"
            elif p and p.isspace():
                rx += r"\s+"
            else:
                rx += re.escape(p)
        self.rx = re.compile(rx)
        self.has_sim = "{sim}" in pat
        if self.has_sim and ("{theory}" not in pat) == (self.value is None):
            raise ValueError("%s: give theory as {theory} or = VALUE, one of them" % where)
        if self.has_sim and self.tol is None:
            raise ValueError("%s: a check with {sim} needs ~ TOL" % where)

    def check(self, lines):
        """Problems found in an exhibit's output (empty: passed)."""
        found = [m for m in (self.rx.search(l) for l in lines) if m]
        why = []
        if len(found) < self.count:
            why.append("%s: %d line(s) like '%s', wanted %d" %
                       (self.where, len(found), self.text, self.count))
        if self.has_sim:
            for m in found:
                sim = float(m.group("sim"))
                theory = float(m.group("theory")) if self.value is None else self.value
                off = abs(sim - theory)
                allowed = self.tol * abs(theory) / 100 if self.rel else self.tol
                if off > allowed:
                    why.append("%s: %s is %g, theory %g: off by %.3g%s (allowed %s%s)" %
                               (self.where, m.group(0).strip()[:60], sim, theory,
                                100 * off / abs(theory) if self.rel and theory else off,
                                "%" if self.rel else "", self.tol, "%" if self.rel else ""))
        return why


def theory_exhibits(path=THEORY_CHECKS):
    """The [Exhibit] blocks of the checks file: name, script, frames, env,
    slow, and their TheoryChecks."""
    out, cur = [], None
    for n, raw in enumerate(read(path).splitlines(), 1):
        line = raw.strip()
        where = "checks.txt:%d" % n
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            cur = dict(name=line[1:-1], script=None, frames=None, env={}, slow=False, checks=[])
            out.append(cur)
        elif cur is None:
            raise ValueError("%s: before the first [Exhibit]" % where)
        elif line.startswith("run:"):
            m = re.match(r"run:\s*(\S+)\s+-n\s+(\d+)$", line)
            if not m:
                raise ValueError("%s: run: SCRIPT -n FRAMES" % where)
            cur["script"], cur["frames"] = m.group(1), m.group(2)
        elif line.startswith("env:"):
            for kv in line[4:].split():
                k, v = kv.split("=", 1)
                cur["env"][k] = v
        elif line == "slow":
            cur["slow"] = True
        elif line.startswith("expect:"):
            cur["checks"].append(TheoryCheck(line[7:].strip(), where))
        else:
            raise ValueError("%s: not run:, env:, slow or expect:" % where)
    return out


def suite_theory(ctx):
    exhibits = [e for e in theory_exhibits() if ctx.selected([e["name"]])]
    skipped = [e["name"] for e in exhibits if e["slow"] and not ctx.slow]
    exhibits = [e for e in exhibits if not (e["slow"] and not ctx.slow)]

    def one(e):
        r = run_bpp(ctx.bpp, ["-f", e["script"], "-n", e["frames"]],
                    ctx.workdir("theory-" + e["name"]), 3600,
                    os.path.join(GALLERY, e["name"]), env=e["env"])
        lines = r.lines()
        why = []
        if r.timed_out:
            why.append("timed out")
        elif r.rc != 0:
            why.append("exit code %s" % r.rc)
        why += lua_errors(lines)[:5]
        for c in e["checks"]:
            why += c.check(lines)
        return e, why, r.seconds

    failed = 0
    for e, why, secs in pmap(ctx, one, exhibits):
        print("  %-4s %-16s %6.0fs  %d checks" % ("ok" if not why else "FAIL", e["name"], secs,
                                                 len(e["checks"])), flush=True)
        for w in why[:12]:
            print("         " + w)
        failed += bool(why)
    if skipped:
        print("  (slow, left out without --slow: %s)" % ", ".join(skipped))
    return failed


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__.split("\n\n", 1)[1])
    ap.add_argument("suites", nargs="*", metavar="suite",
                    help="any of: " + " ".join(ALL_SUITES + EXTRA_SUITES) +
                         " (default: all but " + " ".join(EXTRA_SUITES) + ")")
    ap.add_argument("--bpp", default=os.path.join(ROOT, "release", "bpp"),
                    help="bpp binary to test (default: release/bpp)")
    ap.add_argument("--baseline", metavar="BPP",
                    help="golden: compare against this other bpp binary (say, a "
                         "build of master) instead of the stored expected files")
    ap.add_argument("--update", action="store_true",
                    help="rewrite the expected files of the suites run")
    ap.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 2)
    ap.add_argument("-k", metavar="PATTERN", help="only tests whose name matches")
    ap.add_argument("--atol", type=float, default=1e-5, help="golden: absolute tolerance")
    ap.add_argument("--rtol", type=float, default=1e-5,
                    help="golden: relative tolerance (bpp prints 6 digits; on the "
                         "same platform runs match exactly, so this only absorbs "
                         "a last digit)")
    ap.add_argument("--keep", action="store_true", help="keep the temporary directories")
    ap.add_argument("--slow", action="store_true",
                    help="theory: also the exhibits marked slow")
    a = ap.parse_args()
    unknown = [s for s in a.suites if s not in ALL_SUITES + EXTRA_SUITES]
    if unknown:
        ap.error("unknown suite %s (choose from %s)" % (", ".join(unknown),
                 ", ".join(ALL_SUITES + EXTRA_SUITES)))
    if a.update and a.baseline:
        ap.error("--update and --baseline do not go together")
    if not os.access(a.bpp, os.X_OK):
        ap.error("no bpp binary at %s (build it, or pass --bpp)" % a.bpp)
    if a.baseline and not os.access(a.baseline, os.X_OK):
        ap.error("no bpp binary at %s (--baseline)" % a.baseline)

    ctx = Ctx(a)
    suites = a.suites or ALL_SUITES
    total, start = 0, time.time()
    profile = profile_state()
    for s in ALL_SUITES + EXTRA_SUITES:
        if s not in suites:
            continue
        print("== %s" % s, flush=True)
        if s in LINUX_ONLY and not sys.platform.startswith("linux"):
            print("   (skipped: its expected files are made on Linux)")
            continue
        t = time.time()
        if s == "golden":
            n = suite_golden(ctx, os.path.abspath(a.baseline) if a.baseline else None)
        else:
            n = globals()["suite_" + s](ctx)
        print("   (%s: %d failed, %.0fs)" % (s, n, time.time() - t), flush=True)
        total += n
    after = profile_state()
    if after != profile:
        print("== profile\n   FAIL: bpp wrote to your own profile, not to BPP_USER_DIR:")
        for k in sorted(set(profile) | set(after)):
            if profile.get(k) != after.get(k):
                print("     " + k)
        total += 1
    if a.keep:
        print("temporary files kept in %s" % ctx.tmp)
    else:
        shutil.rmtree(ctx.tmp, ignore_errors=True)
    print("%s (%.0fs)" % ("PASSED" if total == 0 else "FAILED: %d" % total, time.time() - start))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
