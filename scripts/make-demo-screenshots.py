#!/usr/bin/env python3
"""
Generate a screenshot gallery of the BPP demos.

Runs every demo Lua script with bpp in GUI mode on a virtual X server (Xvfb),
grabs a screenshot of the window once the scene has loaded, and writes an
index.html that shows every screenshot, each one hyperlinked to its Lua script
on github.com/bullet-physics-playground/bpp/demo/<path>.

Intended to be run by GitHub CI, which then publishes index.html + the
screenshots to the gh-pages branch.

This mirrors tests/harness.py's "screens" suite (Xvfb + xdotool + imagemagick),
because QGLViewer (a QOpenGLWidget) cannot render on the headless offscreen
platform, so a real (virtual) display is required to grab a screenshot.

Usage:
    scripts/make-demo-screenshots.py [--bpp release/bpp] [--out out] \
        [--settle 3] [--timeout 120] [demo ...]

Without demo arguments, all discoverable demo entry points under demo/ are
used (module/, mesh/ and helper sub-directories are skipped).

Screenshot capture is sequential: all demos share one virtual X display.
Each demo is launched as `bpp <demo>` (GUI mode) and a snapshot is grabbed
once the scene loads.
"""

import argparse
import html
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEMO_DIR = os.path.join(ROOT, "demo")
GITHUB = "https://github.com/bullet-physics-playground/bpp/blob/master"

# Sub-directories that hold shared libraries, mesh data or helper scripts
# rather than runnable demos.
SKIP_DIRS = {
    "module", "mesh", "meshes", "parts", "tools", "tests", "reconstruction",
    "media-check", "geometry", "data", "checks", "probes", "lib", "runs",
    "handover", "exhibits",
}
# File-name fragments that mark a helper/data file rather than a demo.
SKIP_FRAGMENTS = (
    "-meshes", "-geometry", "-data", "-parts", "-brain", "-rules", "-train",
    "-ai", "-labels", "labels", "model", "vehicle", "scene", "models",
)

SCREEN_SIZE = (1280, 800)          # window size the screenshot is taken at
SETTLE = 3.0                       # seconds to let the window paint at least once
GRAB_TIMEOUT = 60                  # seconds to wait for the bpp window
SCREEN_WAIT = 120                  # seconds to wait for the scene to finish loading
STATUS_BAR = 30                    # bottom rows masked when comparing frames


def discover_demos():
    """Return the demo Lua scripts that are runnable entry points."""
    demos = []
    for d, ds, fs in os.walk(DEMO_DIR):
        # A folder holding .nomenu (and everything under it) is not listed.
        if os.path.exists(os.path.join(d, ".nomenu")):
            ds[:] = []
            continue
        base = os.path.basename(d)
        if base in SKIP_DIRS:
            ds[:] = []
            continue
        for f in sorted(fs):
            if not f.endswith(".lua"):
                continue
            low = f.lower()
            if any(frag in low for frag in SKIP_FRAGMENTS):
                continue
            demos.append(os.path.relpath(os.path.join(d, f), ROOT))
    return sorted(demos)


def isolated_env(workdir, display):
    """Environment for one bpp GUI run on the virtual X display."""
    home = os.path.join(workdir, "home")
    conf = os.path.join(
        home, ".config", "bullet-physics-playground.github.io", "bpp.conf")
    if not os.path.exists(conf):
        os.makedirs(os.path.dirname(conf), exist_ok=True)
        with open(conf, "w") as f:
            f.write("[povray]\nexport=%s\n" % os.path.join(workdir, "export"))
    env = dict(os.environ)
    env.update(
        HOME=home,
        XDG_CONFIG_HOME=os.path.join(home, ".config"),
        XDG_CACHE_HOME=os.path.join(home, ".cache"),
        XDG_DATA_HOME=os.path.join(home, ".local", "share"),
        XDG_RUNTIME_DIR=os.path.join(home, ".runtime"),
        LC_ALL="C",
        SDL_AUDIODRIVER="dummy",
        DISPLAY=display,
        # Force the xcb platform so bpp renders on the virtual X server
        # (otherwise Qt may try Wayland and fail).
        QT_QPA_PLATFORM="xcb",
        # Give the GUI only its own icons, no system desktop/theme.
        XDG_DATA_DIRS=os.path.join(workdir, "share"),
    )
    for var in ("XDG_CURRENT_DESKTOP", "DESKTOP_SESSION", "QT_QPA_PLATFORMTHEME",
                "QT_STYLE_OVERRIDE", "KDE_FULL_SESSION", "GNOME_DESKTOP_SESSION_ID"):
        env.pop(var, None)
    if not display:
        # Headless: no display at all, let bpp pick offscreen.
        env.pop("QT_QPA_PLATFORM", None)
    os.makedirs(env["XDG_RUNTIME_DIR"], mode=0o700, exist_ok=True)
    return env


def start_xvfb():
    """Start a virtual X server and return (process, display string)."""
    for n in range(90, 110):
        if (os.path.exists("/tmp/.X11-unix/X%d" % n)
                or os.path.exists("/tmp/.X%d-lock" % n)):
            continue
        p = subprocess.Popen(
            ["Xvfb", ":%d" % n, "-screen", "0",
             "%dx%dx24" % (SCREEN_SIZE[0], SCREEN_SIZE[1]), "-nolisten", "tcp"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            if os.path.exists("/tmp/.X11-unix/X%d" % n):
                return p, ":%d" % n
            time.sleep(0.1)
        p.kill()
    raise RuntimeError("could not start Xvfb")


def wait_for_window(env, timeout=GRAB_TIMEOUT):
    """Return the bpp window id, or None."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        r = subprocess.run(["xdotool", "search", "--onlyvisible", "--name", "^bpp "],
                           env=env, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        ids = r.stdout.split()
        if ids:
            return ids[0].decode()
        time.sleep(0.2)
    return None


def png_mean(path):
    """Mean grayscale value of a PNG (0 = black, 255 = white)."""
    r = subprocess.run(["convert", path, "-colorspace", "Gray",
                        "-format", "%[mean]", "info:"],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                       check=True)
    return float(r.stdout.decode().strip())


def frame_diff(a, b):
    """Number of pixels that differ between two frames (status bar masked).

    Returns None if the images cannot be compared."""
    def size(png):
        r = subprocess.run(["identify", "-format", "%w %h", png],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                           check=True)
        return tuple(int(x) for x in r.stdout.split())
    sa, sb = size(a), size(b)
    if sa != sb:
        return None
    w, h = sa
    crop = "%dx%d+0+0" % (w, h - STATUS_BAR)
    r = subprocess.run(["compare", "-metric", "AE", "-fuzz", "0%",
                        a + "[%s]" % crop, b + "[%s]" % crop, "null:"],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        return float(r.stderr.split()[0])
    except (IndexError, ValueError):
        return None


def grab_screenshot(env, win, out_png):
    """Resize the bpp window, wait for the scene to be drawn, grab it to PNG.

    In GUI mode bpp shows its window *before* running the demo script, and an
    OpenSCAD object builds its geometry synchronously on the GUI thread while
    the script runs (@c openscad is launched and waited on in the
    OpenSCAD constructor). Right after the window appears the view may
    therefore still be blank: the window has been resized while the GUI thread
    was blocked, so nothing was painted yet.

    Wait until a grabbed frame is non-blank and has stopped changing before
    snapshotting. An animated scene never settles, so its last frame is
    accepted once the geometry has shown up. SCREEN_WAIT caps how long we wait
    for slow OpenSCAD builds to finish.
    """
    subprocess.run(["xdotool", "windowmove", win, "0", "0",
                    "windowsize", win, str(SCREEN_SIZE[0]), str(SCREEN_SIZE[1])],
                   env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(SETTLE)
    prev = out_png + ".prev"
    deadline = time.time() + SCREEN_WAIT
    saw_content = False
    ok = False
    while time.time() < deadline:
        r = subprocess.run(["import", "-window", win, out_png], env=env,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode != 0 or not os.path.exists(out_png):
            time.sleep(1.0)
            continue
        # Still blank: OpenSCAD is running and blocking the GUI thread,
        # or the window has not been painted yet. Keep waiting.
        try:
            mean = png_mean(out_png)
        except (subprocess.CalledProcessError, ValueError):
            mean = 0.0
        if mean < 0.5:
            saw_content = False
            time.sleep(1.0)
            continue
        # Content is visible: if the previous frame is identical, the scene
        # has settled (static demo). If it keeps changing, the demo animates
        # -- accept the current frame once we have seen it change once.
        if saw_content and os.path.exists(prev) and frame_diff(prev, out_png) is not None:
            ok = True          # static scene settled, or animating: fine
            break
        shutil.copy(out_png, prev)
        saw_content = True
        time.sleep(1.0)
    if not ok and os.path.exists(out_png):
        # Timed out or the scene kept changing: grab what we have.
        ok = True
    try:
        os.remove(prev)
    except OSError:
        pass
    return ok


def run_demo(bpp, demo, out_png, timeout):
    """Run one demo in GUI mode on Xvfb and grab a screenshot.

    Returns (ok, error_message)."""
    path = os.path.join(ROOT, demo)
    workdir = os.path.join(tempfile.gettempdir(), "bpp-screenshots",
                           re.sub(r"[^A-Za-z0-9._-]", "_", demo))
    os.makedirs(workdir, exist_ok=True)
    display = os.environ.get("BPP_SCREENSHOT_DISPLAY")
    if not display:
        return False, "no Xvfb display set"
    env = isolated_env(workdir, display)
    log = open(os.path.join(workdir, "bpp.log"), "w")
    p = subprocess.Popen([bpp, path], cwd=os.path.dirname(path),
                         env=env, stdout=log, stderr=subprocess.STDOUT)
    ok = False
    err = ""
    try:
        win = wait_for_window(env)
        if not win:
            err = "bpp window did not appear (see %s)" % log.name
        else:
            ok = grab_screenshot(env, win, out_png)
            if not ok:
                err = "screenshot grab failed (see %s)" % log.name
    finally:
        try:
            p.send_signal(signal.SIGTERM)
            p.wait(timeout=10)
        except subprocess.TimeoutExpired:
            p.kill()
            try:
                p.wait(timeout=10)
            except subprocess.TimeoutExpired:
                pass
        log.close()
    if not ok and not err:
        err = "unknown failure"
    return ok, err


def group_key(demo):
    """Top-level demo folder, e.g. 'basic' (the leading 'demo/' is stripped)."""
    rel = demo[len("demo/"):] if demo.startswith("demo" + os.sep) else demo
    return rel.split(os.sep)[0] if os.sep in rel else "root"


def title_of(demo):
    """Human readable title from the file name."""
    name = os.path.splitext(os.path.basename(demo))[0]
    return re.sub(r"[_\-]+", " ", name).title()


def generate_index(demos, results, out_dir):
    """Write index.html (and copy screenshots) into out_dir."""
    shots_dir = os.path.join(out_dir, "shots")
    os.makedirs(shots_dir, exist_ok=True)

    by_group = {}
    for demo in demos:
        by_group.setdefault(group_key(demo), []).append(demo)

    lines = []
    lines.append("<!doctype html>")
    lines.append("<html lang=\"en\">")
    lines.append("<head>")
    lines.append("  <meta charset=\"utf-8\">")
    lines.append("  <title>BPP Demo Gallery</title>")
    lines.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
    lines.append("  <style>")
    lines.append("    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; margin: 2rem; background: #f4f6f8; color: #222; }")
    lines.append("    h1 { margin-top: 0; }")
    lines.append("    .intro { max-width: 700px; color: #444; margin-bottom: 2rem; }")
    lines.append("    .bar { display: flex; gap: 0.5rem; margin-bottom: 1.5rem; flex-wrap: wrap; }")
    lines.append("    .bar a { padding: 0.25rem 0.6rem; background: #fff; border: 1px solid #c9d2dc; border-radius: 0.4rem; text-decoration: none; color: #0766ad; font-size: 0.9rem; }")
    lines.append("    .bar a:hover { border-color: #0766ad; }")
    lines.append("    .group { margin-bottom: 2.5rem; }")
    lines.append("    .group h2 { font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.06em; color: #0766ad; border-bottom: 2px solid #0766ad; padding-bottom: 0.3rem; margin-bottom: 1rem; }")
    lines.append("    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1rem; }")
    lines.append("    .card { background: #fff; border: 1px solid #d7dde4; border-radius: 0.6rem; padding: 0.75rem; display: flex; flex-direction: column; align-items: center; text-decoration: none; color: inherit; box-shadow: 0 1px 3px rgba(0,0,0,0.06); transition: transform 0.1s, box-shadow 0.1s; }")
    lines.append("    .card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }")
    lines.append("    .card img { width: 100%; height: 160px; object-fit: cover; border-radius: 0.4rem; background: #eef2f5; display: block; }")
    lines.append("    .card .title { margin: 0.55rem 0 0.2rem 0; font-size: 0.92rem; font-weight: 600; text-align: center; }")
    lines.append("    .card .path { font-size: 0.72rem; color: #6b7a8c; text-align: center; word-break: break-all; margin-bottom: 0.45rem; }")
    lines.append("    .card .broken { color: #b00020; font-size: 0.8rem; text-align: center; }")
    lines.append("    .summary { margin-top: 2rem; color: #444; }")
    lines.append("  </style>")
    lines.append("</head>")
    lines.append("<body>")
    lines.append("  <h1>BPP Demo Gallery</h1>")
    lines.append("  <div class=\"intro\">Screenshots of the Bullet Physics Playground demo scripts, ")
    lines.append("  generated by running each Lua demo in bpp's GUI on a virtual X server ")
    lines.append("  (<code>bpp &lt;demo&gt;</code>) and grabbing a snapshot once the scene loads.</div>")
    rendered = sum(1 for v in results.values() if v[0])
    failed = sum(1 for v in results.values() if not v[0])
    lines.append("  <p><em>%d demo%s, %d rendered, %d failed.</em></p>" % (
        len(demos), "" if len(demos) == 1 else "s", rendered, failed))
    lines.append("  <div class=\"bar\">")
    for group in sorted(by_group):
        lines.append("    <a href=\"#%s\">%s</a>" % (group, group))
    lines.append("  </div>")

    for group in sorted(by_group):
        lines.append("  <div class=\"group\" id=\"%s\">" % group)
        lines.append("    <h2>%s</h2>" % html.escape(group))
        lines.append("    <div class=\"grid\">")
        for demo in by_group[group]:
            ok, err = results[demo]
            rel = demo.replace(os.sep, "/")
            url = "%s/%s" % (GITHUB, rel)
            shot = os.path.join("shots", os.path.basename(demo) + ".png")
            shot_exists = ok and os.path.exists(os.path.join(out_dir, shot))
            lines.append("      <a href=\"%s\" class=\"card\" title=\"%s\">" % (url, html.escape(demo)))
            if shot_exists:
                lines.append("        <img src=\"%s\" alt=\"%s\">" % (shot, html.escape(title_of(demo))))
            else:
                lines.append("        <div style=\"width:100%;height:160px;background:#eef2f5;border-radius:0.4rem;display:flex;align-items:center;justify-content:center;color:#9aa5b1;font-size:0.75rem;\">no screenshot</div>")
            lines.append("        <div class=\"title\">%s</div>" % html.escape(title_of(demo)))
            lines.append("        <div class=\"path\">%s</div>" % html.escape(rel))
            if not ok:
                lines.append("        <div class=\"broken\">failed: %s</div>" % html.escape(err[:120]))
            lines.append("      </a>")
        lines.append("    </div>")
        lines.append("  </div>")

    lines.append("  <div class=\"summary\">")
    lines.append("    Generated by <a href=\"https://github.com/bullet-physics-playground/bpp/actions\">GitHub CI</a>: ")
    lines.append("    each demo is run in bpp's GUI on a virtual X server and a snapshot is taken ")
    lines.append("    once the scene loads. Click a screenshot to open its Lua script on GitHub.</div>")
    lines.append("</body>")
    lines.append("</html>")

    with open(os.path.join(out_dir, "index.html"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("demos", nargs="*", metavar="DEMO",
                    help="demo paths (default: all discoverable under demo/)")
    ap.add_argument("--bpp", default=os.path.join(ROOT, "release", "bpp"),
                    help="bpp binary (default: release/bpp)")
    ap.add_argument("--out", default=os.path.join(ROOT, "demo-screenshots"),
                    help="output directory for index.html + shots (default: demo-screenshots/)")
    ap.add_argument("--settle", type=float, default=SETTLE,
                    help="seconds to wait for the scene to load before grabbing (default: %s)" % SETTLE)
    ap.add_argument("--timeout", type=int, default=120,
                    help="seconds to wait for the bpp window per demo (default: 120)")
    ap.add_argument("--timeout-per-demo", type=int, default=None,
                    help=argparse.SUPPRESS)
    args = ap.parse_args()
    if args.timeout_per_demo is not None:
        args.timeout = args.timeout_per_demo

    args.bpp = os.path.abspath(args.bpp)
    if not os.path.isfile(args.bpp):
        sys.exit("bpp binary not found: %s (build it first, e.g. qmake && make release)" % args.bpp)

    demos = args.demos if args.demos else discover_demos()
    if not demos:
        sys.exit("no demos found")

    # imagemagick 'import' and xdotool are required for grabbing.
    for tool in ("Xvfb", "xdotool", "import"):
        if not shutil.which(tool):
            sys.exit("missing tool: %s (apt install xvfb xdotool imagemagick)" % tool)

    os.makedirs(args.out, exist_ok=True)
    shots_dir = os.path.join(args.out, "shots")
    os.makedirs(shots_dir, exist_ok=True)

    xvfb, display = start_xvfb()
    os.environ["BPP_SCREENSHOT_DISPLAY"] = display
    results = {}

    try:
        # The virtual display is shared, so grab one demo at a time.
        for demo in demos:
            out_png = os.path.join(shots_dir, os.path.basename(demo) + ".png")
            ok, err = run_demo(args.bpp, demo, out_png, args.timeout)
            results[demo] = (ok, err)
            status = "ok " if ok else "FAIL"
            print("  %-4s %-55s %s" % (status, demo, err if not ok else ""),
                  flush=True)
    finally:
        xvfb.terminate()
        try:
            xvfb.wait(10)
        except subprocess.TimeoutExpired:
            xvfb.kill()

    generate_index(demos, results, args.out)
    failed = sum(1 for v in results.values() if not v[0])
    print("wrote %s (%d demos, %d rendered, %d failed)" % (
        os.path.join(args.out, "index.html"),
        len(demos), len(demos) - failed, failed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
