#!/usr/bin/env python3

# Submit a Bullet Physics Playground POV-Ray export to povomatic
# (https://github.com/koppi/povomatic -- distributed POV-Ray rendering on
# Kubernetes) by driving its povomatic.py CLI client.
#
# bpp exports a scene to export/<scene>/ as
#
#   <scene>.pov   -- #include "settings.inc" + #include concat(str(clock,-5,0),".inc")
#   <scene>.ini   -- Initial_Clock / Final_Clock / Final_Frame (bpp sets clock == frame number)
#   NNNNN.inc     -- one per frame, 5-digit zero-padded frame number
#   settings.inc  -- copied from bpp's includes/settings.inc
#   mesh_*.inc    -- mesh geometry
#
# povomatic renders a frame with
#
#   povray +I<scene> +KFI1 +KFF<frames> +KI<clock_initial> +KF<clock_final> +SF<k> +EF<k> +L/app/input +L/app/assets ...
#
# so povomatic's per-frame clock is  clock_initial + (clock_final-clock_initial)*(k-1)/(frames-1).
# Submitting with  frames = Final_Clock-Initial_Clock+1,  clock-initial = Initial_Clock,
# clock-final = Final_Clock  makes that clock land exactly on the integer frame
# numbers, so #include concat(str(clock,-5,0),".inc") picks the matching NNNNN.inc.
#
# POV-Ray only searches the working directory and its +L library paths, never the
# scene file's own directory, so the per-scene export dir is added to povray-args
# as +L<remote-input>/<scene>.
#
# The scene dir, bpp's includes/ and POV-Ray's own stock includes (colors.inc
# etc., which bpp's settings.inc pulls in and the povomatic render image does not
# ship) are all rsynced to the shared volumes, which povomatic passes to povray
# as +L/app/input and +L/app/assets.
#
# Environment (each overridable by the matching option):
#   POVOMATIC_API           passed straight through to povomatic.py (--api-url)
#   POVOMATIC_PY            path to povomatic.py                     (default: search)
#   POVOMATIC_INPUT         NFS input volume, host path              (default: /nfs/povray/input)
#   POVOMATIC_ASSETS        NFS assets volume, host path             (default: /nfs/povray/assets)
#   POVOMATIC_REMOTE_INPUT  input volume path the render workers see (default: /app/input)

import argparse
import glob
import os
import re
import shutil
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DEFAULT_INPUT = os.environ.get("POVOMATIC_INPUT", "/nfs/povray/input")
DEFAULT_ASSETS = os.environ.get("POVOMATIC_ASSETS", "/nfs/povray/assets")
DEFAULT_REMOTE_INPUT = os.environ.get("POVOMATIC_REMOTE_INPUT", "/app/input")

# Rendered output and local-only files that must not be pushed to the shared
# input volume alongside the scene.
RSYNC_EXCLUDES = [
    "*.png", "*.jpg", "*.jpeg", "*.mkv", "*.mp4", "*.mov", "*.avi", "*.gif",
    "*.pov-state", "*.tar.xz", "*.log", "*.out", "*.err", "loop.txt",
    "GNUmakefile", "Makefile",
]


def die(msg):
    print(f"povomatic-job: {msg}", file=sys.stderr)
    sys.exit(1)


def find_povomatic_py(explicit):
    for cand in (explicit, os.environ.get("POVOMATIC_PY"),
                 "/nfs/povomatic/povomatic.py", shutil.which("povomatic.py")):
        if cand and os.path.isfile(cand):
            return cand
    die("povomatic.py not found; pass --povomatic-py or set POVOMATIC_PY "
        "(looked in $POVOMATIC_PY, /nfs/povomatic/povomatic.py, $PATH)")


def find_povray_includes(explicit):
    """Directory holding POV-Ray's standard includes (colors.inc, metals.inc...).

    bpp's settings.inc pulls these in and the povomatic render image does not
    ship them, so they have to travel to the assets volume with everything else.
    """
    pats = [explicit, os.environ.get("POVRAY_INCLUDE_DIR")]
    pats += ["/usr/share/povray*/include", "/usr/local/share/povray*/include",
             "/opt/povray*/include", "/usr/share/povray/*/include"]
    for pat in pats:
        for d in sorted(glob.glob(pat) if pat else [], reverse=True):
            if os.path.isfile(os.path.join(d, "colors.inc")):
                return d
    return None


def resolve_scene(arg):
    """(scene_dir, scene_name) from a directory, a .pov, a .ini, or '.'."""
    arg = os.path.abspath(arg)
    if os.path.isdir(arg):
        scene_dir = arg
        name = os.path.basename(arg.rstrip("/"))
        if not os.path.isfile(os.path.join(scene_dir, name + ".pov")):
            povs = [f for f in os.listdir(scene_dir) if f.endswith(".pov")]
            if len(povs) != 1:
                die(f"{scene_dir}: expected one <scene>.pov, found {len(povs)}")
            name = povs[0][:-4]
        return scene_dir, name
    if arg.endswith((".pov", ".ini")):
        return os.path.dirname(arg), os.path.basename(arg)[:-4]
    die(f"{arg}: not a directory, .pov or .ini")


def parse_ini(path):
    """Top-level key/value pairs and [section] blocks of a POV-Ray ini file."""
    top, sections, cur = {}, {}, None
    if not os.path.isfile(path):
        return top, sections
    with open(path) as f:
        for line in f:
            line = line.split(";", 1)[0].strip()
            if not line:
                continue
            m = re.match(r"\[(.+)\]$", line)
            if m:
                cur = m.group(1)
                sections[cur] = {}
                continue
            if "=" not in line:
                continue
            k, v = (s.strip() for s in line.split("=", 1))
            (sections[cur] if cur else top)[k.lower()] = v
    return top, sections


def as_int(v, what):
    try:
        return int(round(float(v)))
    except (TypeError, ValueError):
        die(f"cannot read {what} ('{v}') as a number")


def rsync(src, dst, extra=()):
    os.makedirs(dst, exist_ok=True)
    cmd = ["rsync", "-a", "--no-owner", "--no-group"]
    cmd += [f"--exclude={p}" for p in extra]
    cmd += [src.rstrip("/") + "/", dst.rstrip("/") + "/"]
    return cmd


def main():
    ap = argparse.ArgumentParser(
        description="Submit a bpp POV-Ray export to povomatic via povomatic.py.")
    ap.add_argument("scene", nargs="?", default=".",
                    help="export/<scene>/ directory, its .pov/.ini, or '.' (default)")
    ap.add_argument("--still", action="store_true",
                    help="submit a single still instead of the animation")
    ap.add_argument("--frame", type=int,
                    help="frame to render for --still (default: Final_Frame)")
    ap.add_argument("--frames", type=int,
                    help="override the animation frame count from the .ini")
    ap.add_argument("--clock-initial", type=float,
                    help="override Initial_Clock from the .ini")
    ap.add_argument("--clock-final", type=float,
                    help="override Final_Clock from the .ini")
    ap.add_argument("--res", metavar="SECTION",
                    help="take Width/Height from a named [section] of the .ini "
                         "(e.g. 720p, 1080p, 4K)")
    ap.add_argument("--width", type=int, help="render width (overrides .ini)")
    ap.add_argument("--height", type=int, help="render height (overrides .ini)")
    ap.add_argument("--priority", type=int, default=0, help="povomatic job priority")
    ap.add_argument("--povray-args", default="", help="extra args appended to povray")
    ap.add_argument("--ffmpeg-args", default="", help="args for the ffmpeg encode pass")
    ap.add_argument("--api-url", default=os.environ.get("POVOMATIC_API"),
                    help="povomatic API URL (default: $POVOMATIC_API)")
    ap.add_argument("--input-dir", default=DEFAULT_INPUT,
                    help=f"NFS input volume, host path (default: {DEFAULT_INPUT})")
    ap.add_argument("--assets-dir", default=DEFAULT_ASSETS,
                    help=f"NFS assets volume, host path (default: {DEFAULT_ASSETS})")
    ap.add_argument("--remote-input", default=DEFAULT_REMOTE_INPUT,
                    help=f"input volume path as the workers mount it "
                         f"(default: {DEFAULT_REMOTE_INPUT})")
    ap.add_argument("--povomatic-py", help="path to povomatic.py")
    ap.add_argument("--povray-include-dir",
                    help="POV-Ray standard include dir to sync to the assets "
                         "volume (default: search; $POVRAY_INCLUDE_DIR)")
    ap.add_argument("--force", action="store_true",
                    help="submit even if the .inc files do not match the frame range")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the rsync and povomatic.py commands, run nothing")
    args = ap.parse_args()

    scene_dir, scene = resolve_scene(args.scene)
    pov = os.path.join(scene_dir, scene + ".pov")
    if not os.path.isfile(pov):
        die(f"{pov}: not found (run bpp with -e to export first)")

    top, sections = parse_ini(os.path.join(scene_dir, scene + ".ini"))

    # Resolution: explicit flags win, then --res section, then the ini's top level.
    res = dict(top)
    if args.res:
        if args.res not in sections:
            die(f"--res {args.res}: no [{args.res}] section in {scene}.ini "
                f"(have: {', '.join(sections) or 'none'})")
        res.update(sections[args.res])
    width = args.width or as_int(res.get("width", 1280), "width")
    height = args.height or as_int(res.get("height", 720), "height")

    inc_frames = sorted(int(f[:-4]) for f in os.listdir(scene_dir)
                        if re.fullmatch(r"\d{5}\.inc", f))
    if not inc_frames:
        die(f"{scene_dir}: no NNNNN.inc frame files")

    # bpp writes Initial_Clock / Final_Clock / Final_Frame with clock == frame
    # number; trust them over the .inc listing, which can carry stale frames
    # from an earlier, longer run. Fall back to the listing when there is no ini.
    def ini_num(*keys, default):
        for k in keys:
            if k in top:
                return as_int(top[k], k)
        return default

    ini_first = ini_num("initial_clock", default=inc_frames[0])
    ini_last = ini_num("final_clock", "final_frame", default=inc_frames[-1])

    povomatic_py = find_povomatic_py(args.povomatic_py)

    # --- assets: bpp's bundled includes/ + POV-Ray's stock includes ----------
    steps = [rsync(os.path.join(REPO_ROOT, "includes"), args.assets_dir)]
    pov_inc = find_povray_includes(args.povray_include_dir)
    if pov_inc:
        steps.append(rsync(pov_inc, args.assets_dir))
    else:
        print("povomatic-job: warning: POV-Ray's standard include dir not found; "
              "colors.inc etc. will only resolve if the render image ships them "
              "(set POVRAY_INCLUDE_DIR to sync them)", file=sys.stderr)

    # --- scene: export/<scene>/ -> <input>/<scene>/ --------------------------
    dest = os.path.join(args.input_dir, scene)
    steps.append(rsync(scene_dir, dest, RSYNC_EXCLUDES))

    # --- build the povomatic.py invocation ---------------------------------
    pov_lib = f"+L{args.remote_input.rstrip('/')}/{scene}"
    povray_args = f"{pov_lib} +W{width} +H{height}"
    if args.povray_args:
        povray_args += " " + args.povray_args

    submit = [sys.executable, povomatic_py, "--scene", f"{scene}/{scene}.pov"]
    if args.api_url:
        submit += ["--api-url", args.api_url]
    if args.priority:
        submit += ["--priority", str(args.priority)]

    if args.still:
        frame = args.frame if args.frame is not None else ini_last
        if not os.path.isfile(os.path.join(scene_dir, f"{frame:05d}.inc")):
            die(f"still frame {frame}: {frame:05d}.inc not found")
        submit += ["--type", "still"]
        submit += ["--povray-args", f"{povray_args} +K{frame}"]
    else:
        ci = ini_first if args.clock_initial is None else args.clock_initial
        cf = ini_last if args.clock_final is None else args.clock_final
        frames = args.frames or (int(round(cf)) - int(round(ci)) + 1)

        expected = set(range(int(round(ci)), int(round(cf)) + 1))
        have = set(inc_frames)
        missing = sorted(expected - have)
        extra = sorted(have - expected)
        if missing:
            msg = (f"{len(missing)} frame(s) in {int(round(ci))}..{int(round(cf))} "
                   f"have no .inc file (first: {missing[0]:05d}.inc)")
            if not args.force:
                die(msg + " -- re-export, or pass --force")
            print("povomatic-job: warning: " + msg, file=sys.stderr)
        if extra:
            print(f"povomatic-job: note: rendering frames {int(round(ci))}..{int(round(cf))} "
                  f"per {scene}.ini; {len(extra)} further .inc file(s) up to "
                  f"{extra[-1]:05d}.inc are left out (pass --clock-final / --frames, "
                  f"or 'make distclean' and re-export, if that is wrong)",
                  file=sys.stderr)

        submit += ["--type", "animation", "--frames", str(frames),
                   "--clock-initial", str(ci), "--clock-final", str(cf),
                   "--povray-args", povray_args]
    if args.ffmpeg_args:
        submit += ["--ffmpeg-args", args.ffmpeg_args]

    def show(cmd):
        print("  " + " ".join(
            (f"'{c}'" if (" " in c or not c) else c) for c in cmd))

    if args.dry_run:
        print("rsync:")
        for s in steps:
            show(s)
        print("submit:")
        show(submit)
        return

    for s in steps:
        subprocess.run(s, check=True)
    os.execv(sys.executable, submit)


if __name__ == "__main__":
    main()
