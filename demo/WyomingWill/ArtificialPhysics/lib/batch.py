#!/usr/bin/env python3
"""lib/batch.py -- headless batch runner for the Artificial Physics ports (BOOK.md G3).

Runs one headless BPP per (setting combination x seed), two at a time by
default, and writes every result row to one CSV file.

    python3 lib/batch.py SCRIPT [options]

    --seeds 1-5           seeds: a range "1-5", a list "1,2,7", or both "1-3,9"
    --set name=a,b,c      a parameter and the values to try (repeatable; the
                          runs cover every combination)
    --frames N            frames per run (bpp -n), default 3000
    --probe FILE          Lua file appended after the script (uses lib/batch.lua)
    --match PREFIX        also turn the script's own output lines starting with
                          PREFIX (e.g. "ticks=") into rows
    --resetup             re-run setup() after applying the settings
    --env K=V             extra environment for every run (repeatable)
    --jobs N              runs in parallel, default 2
    --timeout S           seconds per run, default 1800
    --out FILE            CSV file, default batch-<script>-<time>.csv
    --summary KEY         print mean, sd, min and max of KEY over seeds, from the
                          last row of each run (repeatable)

Every run gets SEED (read by lib/rng.lua), BATCH_SET and BATCH_JOB. Rows are
lines "ROW k=v ..." from lib/batch.lua, plus --match lines. Each CSV row
starts with job, seed, the settings, status (ok / failed / timeout / norows)
and wall_s; then the row's fields in the order first seen (a field named
like a lead column becomes out.<name>). A run that fails
or reports nothing still gets one row, so nothing goes missing silently.
Output of each run is kept in <out>.logs/.

Runs are independent processes and the seed fixes every random draw, so the
CSV does not depend on --jobs or on the order runs finish (checked by
checks/batch_repeat.sh).

The BPP binary is $BPP if set, else the newest of debug/bpp and release/bpp
in the repository that holds SCRIPT.
"""

import argparse
import concurrent.futures as cf
import csv
import itertools
import math
import os
import re
import subprocess
import sys
import time


def parse_seeds(text):
    seeds = []
    for part in text.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            seeds.extend(range(int(a), int(b) + 1))
        else:
            seeds.append(int(part))
    if 0 in seeds:
        sys.exit("batch: seed 0 means 'from the clock' in lib/rng.lua; use seeds >= 1")
    return seeds


def parse_set(items):
    params = []
    for item in items:
        if "=" not in item:
            sys.exit(f"batch: --set needs name=v1,v2,...: {item!r}")
        name, vals = item.split("=", 1)
        params.append((name.strip(), [x.strip() for x in vals.split(",") if x.strip()]))
    return params


def find_bpp(script_dir):
    if os.environ.get("BPP"):
        return os.environ["BPP"]
    d = os.path.abspath(script_dir)
    while True:
        found = [os.path.join(d, b, "bpp") for b in ("debug", "release")]
        found = [f for f in found if os.access(f, os.X_OK)]
        if found:
            return max(found, key=os.path.getmtime)
        up = os.path.dirname(d)
        if up == d:
            break
        d = up
    sys.exit("batch: no bpp binary found; set BPP=/path/to/bpp")


TOKEN = re.compile(r"([A-Za-z_][\w.]*)=(\S+)")


def parse_rows(text, match):
    rows = []
    for line in text.splitlines():
        if line.startswith("ROW "):
            body = line[4:]
        elif match and line.startswith(match):
            body = line
        else:
            continue
        row = {}
        for k, val in TOKEN.findall(body):
            row[k] = val[:-1] if val.endswith("%") else val
        if row:
            rows.append(row)
    return rows


def run_job(job, a, bpp, script, settings, seed, logdir):
    env = dict(os.environ)
    env.update(a.env_dict)
    env.update({
        "SEED": str(seed),
        "BATCH_SET": ";".join(f"{k}={v}" for k, v in settings),
        "BATCH_JOB": str(job),
        "SDL_AUDIODRIVER": env.get("SDL_AUDIODRIVER", "dummy"),
        "QT_QPA_PLATFORM": env.get("QT_QPA_PLATFORM", "offscreen"),
    })
    rt = env.get("XDG_RUNTIME_DIR") or "/tmp/rt-batch"
    os.makedirs(rt, mode=0o700, exist_ok=True)
    env["XDG_RUNTIME_DIR"] = rt
    if a.resetup:
        env["BATCH_RESETUP"] = "1"
    lua = "require('lib.batch').start()"
    if a.probe:
        lua += "; dofile(%r)" % os.path.abspath(a.probe)
    cmd = [bpp, "-f", os.path.basename(script), "-l", lua, "-n", str(a.frames)]
    t0 = time.time()
    status = "ok"
    try:
        p = subprocess.run(cmd, cwd=os.path.dirname(os.path.abspath(script)), env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=a.timeout, text=True, errors="replace")
        out = p.stdout
        if p.returncode != 0 or re.search(r"^error: ", out, re.M):
            status = "failed"
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
        status = "timeout"
    wall = time.time() - t0
    tag = "_".join([f"j{job:04d}", f"s{seed}"] + [f"{k}{v}" for k, v in settings])
    with open(os.path.join(logdir, re.sub(r"[^\w.=-]", "_", tag) + ".log"), "w") as f:
        f.write(" ".join(cmd) + "\n" + out)
    rows = parse_rows(out, a.match)
    if not rows and status == "ok":
        status = "norows"
    return job, seed, settings, status, wall, rows, out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("script")
    ap.add_argument("--seeds", default="1-3")
    ap.add_argument("--set", action="append", default=[])
    ap.add_argument("--frames", type=int, default=3000)
    ap.add_argument("--probe")
    ap.add_argument("--match")
    ap.add_argument("--resetup", action="store_true")
    ap.add_argument("--env", action="append", default=[])
    ap.add_argument("--jobs", type=int, default=2)
    ap.add_argument("--timeout", type=float, default=1800)
    ap.add_argument("--out")
    ap.add_argument("--summary", action="append", default=[])
    a = ap.parse_args()

    a.env_dict = dict(e.split("=", 1) for e in a.env)
    seeds = parse_seeds(a.seeds)
    params = parse_set(a.set)
    bpp = find_bpp(os.path.dirname(os.path.abspath(a.script)))
    if not a.out:
        base = os.path.splitext(os.path.basename(a.script))[0]
        a.out = f"batch-{base}-{time.strftime('%Y%m%d-%H%M%S')}.csv"
    logdir = a.out + ".logs"
    os.makedirs(logdir, exist_ok=True)

    names = [n for n, _ in params]
    combos = list(itertools.product(*[vals for _, vals in params])) or [()]
    jobs = [(list(zip(names, c)), s) for c in combos for s in seeds]
    print(f"batch: {len(jobs)} runs ({len(combos)} settings x {len(seeds)} seeds), "
          f"{a.jobs} at a time, {a.frames} frames each, bpp {bpp}", flush=True)

    t0 = time.time()
    results = {}
    with cf.ThreadPoolExecutor(max_workers=max(1, a.jobs)) as pool:
        futs = [pool.submit(run_job, i + 1, a, bpp, a.script, st, sd, logdir)
                for i, (st, sd) in enumerate(jobs)]
        for fut in cf.as_completed(futs):
            job, seed, st, status, wall, rows, out = fut.result()
            results[job] = (seed, st, status, wall, rows)
            label = " ".join(f"{k}={v}" for k, v in st) or "-"
            print(f"  [{len(results)}/{len(jobs)}] job {job} seed {seed} {label}: "
                  f"{status}, {len(rows)} rows, {wall:.1f} s", flush=True)
            if status in ("failed", "timeout"):
                errs = [l for l in out.splitlines() if l.startswith("error")]
                if errs:
                    print("      " + errs[0], flush=True)

    # CSV in job order, so it is the same whatever order the runs finished.
    # A row field named like a lead column (e.g. the script also prints the
    # setting) is kept, as out.<name>.
    lead_names = set(["job", "seed", "status", "wall_s"] + names)
    def col(k):
        return "out." + k if k in lead_names else k
    fields = []
    for job in sorted(results):
        for r in results[job][4]:
            for k in r:
                if k not in fields:
                    fields.append(k)
    header = ["job", "seed"] + names + ["status", "wall_s"] + [col(k) for k in fields]
    with open(a.out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        for job in sorted(results):
            seed, st, status, wall, rows = results[job]
            lead = [job, seed] + [v for _, v in st] + [status, f"{wall:.1f}"]
            for r in rows or [{}]:
                w.writerow(lead + [r.get(k, "") for k in fields])
    bad = sum(1 for r in results.values() if r[2] != "ok")
    print(f"batch: wrote {a.out} ({sum(len(r[4]) for r in results.values())} rows) "
          f"in {time.time() - t0:.1f} s; {bad} run(s) not ok; logs in {logdir}/")

    for key in a.summary:
        print(f"\nsummary of {key} (last row of each run, over seeds):")
        print("  " + "  ".join(f"{n:>12}" for n in names) + f"  {'n':>3}  {'mean':>10}  {'sd':>10}  {'min':>10}  {'max':>10}")
        for c in combos:
            vals = []
            for job in sorted(results):
                seed, st, status, wall, rows = results[job]
                if tuple(v for _, v in st) == tuple(c) and rows and key in rows[-1]:
                    try:
                        vals.append(float(rows[-1][key]))
                    except ValueError:
                        pass
            if not vals:
                continue
            m = sum(vals) / len(vals)
            sd = math.sqrt(sum((x - m) ** 2 for x in vals) / (len(vals) - 1)) if len(vals) > 1 else 0.0
            print("  " + "  ".join(f"{v:>12}" for v in c) +
                  f"  {len(vals):>3}  {m:>10.5g}  {sd:>10.3g}  {min(vals):>10.5g}  {max(vals):>10.5g}")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
