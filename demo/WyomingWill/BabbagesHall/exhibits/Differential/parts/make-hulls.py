#!/usr/bin/env python3
"""make-hulls.py -- the gears' convex pieces and masses, for the simulation.

Bullet's contacts between convex shapes are good; between two meshes
(GImpact) bevel teeth jam and slip (see ../FINDINGS.md). So each gear is
simulated as a compound of convex hulls: its body inside the root cone, and
its N teeth outside it. The pieces come from differential.scad (PART="tooth":
one tooth, PART="body"), so they are the printed gear's; the masses and
moments of inertia come from the whole printed parts (PART="side",
"spider", "carrier").

Writes gear-hulls.lua (centimetres, kilograms) beside this file. Needs
openscad and the Python packages numpy and trimesh.

    python3 make-hulls.py [--density 0.8]     (g/cm3: PLA is 1.24 solid;
                                               0.8 is about 50% infill)
"""
import argparse, os, subprocess, tempfile
import numpy as np
import trimesh

HERE = os.path.dirname(os.path.abspath(__file__))
SCAD = os.path.join(HERE, "differential.scad")


def part(name):
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, name + ".stl")
        subprocess.run(["openscad", "-o", out, "-D", f'PART="{name}"', SCAD],
                       check=True, capture_output=True)
        return trimesh.load(out)


def lua_points(pts):
    # millimetres -> centimetres, flattened
    return "{ " + ", ".join(f"{v / 10:.4f}" for p in pts for v in p) + " }"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--density", type=float, default=0.8)
    args = ap.parse_args()

    tooth = part("tooth").convex_hull
    body = part("body").convex_hull
    out = ["-- made by make-hulls.py from differential.scad: do not edit",
           "-- every gear's convex pieces (cm, in the gear's own frame: its axis z,",
           "-- its back at z = 0) and the printed parts' masses (kg) and moments of",
           f"-- inertia about their own origins (kg cm^2), at {args.density} g/cm^3",
           "return {",
           f"  tooth = {lua_points(tooth.vertices)},",
           f"  body = {lua_points(body.vertices)},"]
    for name in ("side", "spider", "carrier"):
        m = part(name)
        m.density = args.density / 1000.0           # g/cm3 -> g/mm3: mass in g, inertia in g mm2
        c = m.center_mass
        mass_kg = m.mass / 1000.0
        # inertia about the part's own origin: the tensor about its centre of
        # mass, moved there (parallel axes)
        I_o = m.moment_inertia + m.mass * (np.dot(c, c) * np.eye(3) - np.outer(c, c))
        I_kgcm2 = I_o / 1000.0 / 100.0              # g mm2 -> kg cm2
        out.append(f"  {name} = {{ mass = {mass_kg:.5f}, com = {{ {c[0]/10:.4f}, {c[1]/10:.4f}, {c[2]/10:.4f} }},"
                   f" inertia = {{ {I_kgcm2[0,0]:.5f}, {I_kgcm2[1,1]:.5f}, {I_kgcm2[2,2]:.5f} }} }},")
    out.append("}")
    with open(os.path.join(HERE, "gear-hulls.lua"), "w") as f:
        f.write("\n".join(out) + "\n")
    print(f"gear-hulls.lua: tooth {len(tooth.vertices)} points, body {len(body.vertices)}")


if __name__ == "__main__":
    main()
