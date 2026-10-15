#!/usr/bin/env python3
"""Bundle the transitive, non-system macOS dependencies of a bpp .app.

macdeployqt copies Qt's dependencies but can leave out second-level (or
@rpath-resolved) libraries such as brotlicommon and libsharpyuv.  This
helper scans every Mach-O in the bundle, copies any missing runtime
dependency from the usual Homebrew locations into Contents/Frameworks,
fixes its install id, and repeats until the closure is complete.
"""
import os
import re
import shutil
import subprocess
import sys

APP = os.path.abspath(sys.argv[1])
FW = os.path.join(APP, "Contents", "Frameworks")
BIN = os.path.join(APP, "Contents", "MacOS", "bpp")
LIB_DIRS = ["/opt/homebrew/lib", "/usr/local/lib"]
# also include opt/*/lib
for base in ("/opt/homebrew/opt", "/usr/local/opt"):
    if os.path.isdir(base):
        for name in os.listdir(base):
            p = os.path.join(base, name, "lib")
            if os.path.isdir(p) and p not in LIB_DIRS:
                LIB_DIRS.append(p)

SYSTEM_PREFIXES = ("/System/", "/usr/lib/")


def run(*args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def is_macho(path):
    try:
        out = run("file", "-b", path).stdout
    except Exception:
        return False
    return "Mach-O" in out


def otool_libs(path):
    out = run("otool", "-L", path).stdout
    libs = []
    for line in out.splitlines()[1:]:
        line = line.strip()
        m = re.match(r"^(.*) \(compatibility version", line)
        if m:
            libs.append(m.group(1).strip())
    return libs


def otool_rpaths(path):
    out = run("otool", "-l", path).stdout
    rpaths = []
    i = 0
    lines = out.splitlines()
    while i < len(lines):
        if "cmd LC_RPATH" in lines[i]:
            # next lines contain path
            for j in range(i + 1, min(i + 4, len(lines))):
                m = re.search(r"path\s+(.*)\s+\(offset", lines[j])
                if m:
                    rpaths.append(m.group(1).strip())
                    break
        i += 1
    return rpaths


def resolve(dep, ref, app=APP, fw=FW):
    refdir = os.path.dirname(ref)
    if dep.startswith("@executable_path"):
        return os.path.normpath(dep.replace("@executable_path", os.path.join(app, "Contents", "MacOS")))
    if dep.startswith("@loader_path"):
        return os.path.normpath(dep.replace("@loader_path", refdir))
    if dep.startswith("@rpath"):
        rest = dep[len("@rpath"):]  # keep leading /
        # Search rpaths of ref first
        for rp in otool_rpaths(ref):
            if rp.startswith("@"):
                # resolve rpath itself
                base = resolve(rp, ref)
                cand = os.path.normpath(os.path.join(base, rest.lstrip("/")))
            else:
                cand = os.path.normpath(os.path.join(rp.replace("@executable_path", os.path.join(app, "Contents", "MacOS")), rest.lstrip("/")))
            if os.path.exists(cand):
                return cand
        # Then defaults
        for base in (fw, os.path.join(fw, "..", "lib")):
            cand = os.path.normpath(os.path.join(base, rest.lstrip("/")))
            if os.path.exists(cand):
                return cand
        return os.path.normpath(os.path.join(fw, rest.lstrip("/")))
    return dep


def find_source(dep):
    base = os.path.basename(dep)
    # @rpath or relative -> search Homebrew lib dirs
    if dep.startswith("@rpath") or not dep.startswith("/"):
        for d in LIB_DIRS:
            src = os.path.join(d, base)
            if os.path.exists(src):
                return src
        return None
    # absolute
    if os.path.exists(dep):
        return dep
    # maybe under another prefix
    for d in LIB_DIRS:
        src = os.path.join(d, base)
        if os.path.exists(src):
            return src
    return None


def macho_files():
    out = []
    for root, _, files in os.walk(os.path.join(APP, "Contents")):
        for f in files:
            p = os.path.join(root, f)
            if is_macho(p):
                out.append(p)
    return out


def bundle_one_round():
    changed = False
    for ref in macho_files():
        for dep in otool_libs(ref):
            if dep.startswith(SYSTEM_PREFIXES) or dep == "/usr/lib/libSystem.B.dylib":
                continue
            target = resolve(dep, ref)
            if os.path.exists(target) and os.path.abspath(target).startswith(os.path.abspath(APP)):
                # already in bundle (or resolves inside)
                continue
            # If target exists inside app? above covers; if exists outside absolute and not copied? find handled below.
            # Determine if dependency is missing from bundle (target not within app)
            if os.path.exists(target) and os.path.abspath(target).startswith(os.path.abspath(APP)):
                continue
            base = os.path.basename(dep)
            # Never bundle Qt itself or Qt plugins - macdeployqt owns those.
            low = base.lower()
            if low.startswith("qt") or low.startswith("libq") or "qt" in low and low.startswith("libqt"):
                continue
            if ".framework" in dep.lower():
                continue
            if os.path.exists(os.path.join(FW, base)):
                continue
            src = find_source(dep)
            if src and "/qt" in src.lower():
                continue
            if not src:
                continue
            dst = os.path.join(FW, base)
            # copy (follow symlinks)
            if os.path.islink(src):
                src = os.path.realpath(src)
            shutil.copy2(src, dst, follow_symlinks=True)
            # fix install id
            run("install_name_tool", "-id", "@executable_path/../Frameworks/" + base, dst)
            print("bundled %s -> %s" % (src, dst))
            changed = True
    return changed


def main():
    os.makedirs(FW, exist_ok=True)
    round_no = 0
    while True:
        changed = bundle_one_round()
        round_no += 1
        if not changed:
            break
        if round_no > 20:
            print("aborting: too many rounds", file=sys.stderr)
            break
    print("dependency bundling complete")


if __name__ == "__main__":
    main()
