#!/usr/bin/env python3
"""
The giant planets' rings, as flat meshes: solar-meshes/rings-*.obj and
solar-rings.lua (what solar-system.lua needs to draw them and say what they
are).

Each ring is drawn as one or more flat annuli ("bands") in its planet's
equator: in the mesh, the x-z plane, its north up (+y); solar-system.lua
turns it each frame so that +y is the planet's north pole (the IAU's, from
solar-rotation.lua). The rings don't turn.

Two sets: the orrery's, scaled exactly as the planet there is drawn (its
sphere is 0.33 sqrt(R/1000 km) cm across for its mean radius R, and a ring
at r km is drawn at r/R times that, so ring against planet is true); and
the vitrines', whose distances from the planet are square-rooted as its
moons' are (VITRINE_R sqrt(r / reach)), so that the rings sit among the
moons as they do.

THE RING DATA ARE FROM MEMORY, not checked here against a source (NASA's
planetary fact sheets and the PDS Ring-Moon Systems Node's ring tables, which
could not be reached from where this was made; JPL's and the Rings Node's
sites were refused by the network). Radii to a few hundred km at worst;
the optical character (how dense, how bright) as those sources describe it.

Narrow rings (Uranus' nine main ones and its epsilon ring, Neptune's Le
Verrier, Arago and Adams, Saturn's F) are tens of km wide or less: far below
a pixel at any scale here. They're drawn MIN_W cm wide (and say so).

    cd demo/WyomingWill/EulersGallery/exhibits/SolarSystem && python3 make-rings.py
"""
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
MESH = os.path.join(HERE, "solar-meshes")
AU = 149597870.6996262074
VITRINE_R = 24.0
MIN_W = {"orrery": 0.035, "vitrine": 0.05}   # cm: the narrowest a ring is drawn

# mean radius (km) the planets are drawn with (solar-data.lua's main r, and
# solar-system.lua's RADIUS table for the vitrines)
R_MEAN = {"Jupiter": 69911, "Saturn": 58232, "Uranus": 25362, "Neptune": 24622}

# each band: name, (inner, outer) radius (km; for a narrow ring, ("narrow",
# centre, width)), colour, opacity (0 to 1: how much it hides what's behind), faint
# (opacity rises as you come close, see solar-system.lua)
# FROM MEMORY: see above.
RINGS = {
    "Saturn": [
        ("D", (66900, 74510), "#6f6658", 0.06, True),
        ("C", (74658, 92000), "#8f8470", 0.35, False),
        ("B (inner)", (92000, 99000), "#cdbd98", 0.75, False),
        ("B", (99000, 117580), "#e6d9b6", 0.97, False),
        ("Cassini Division", (117580, 122170), "#5e5547", 0.18, False),
        ("A", (122170, 133423), "#cfc19c", 0.8, False),       # (the Encke gap, 133,423 to 133,745, between)
        ("A (outer)", (133745, 136775), "#c4b691", 0.7, False),
        ("F", ("narrow", 140180, 50), "#c9bfa6", 0.5, False),
    ],
    "Jupiter": [
        ("halo", (92000, 122500), "#6e5644", 0.04, True),
        ("main ring", (122500, 129000), "#7d6150", 0.10, True),
        ("Amalthea gossamer ring", (129000, 182000), "#6e5644", 0.03, True),
        ("Thebe gossamer ring", (182000, 226000), "#6e5644", 0.02, True),
    ],
    "Uranus": [
        ("zeta", (37850, 41350), "#3a3c40", 0.05, True),
        ("6", ("narrow", 41837, 1.5), "#4a4b4e", 0.6, True),
        ("5", ("narrow", 42234, 2), "#4a4b4e", 0.6, True),
        ("4", ("narrow", 42571, 2.5), "#4a4b4e", 0.6, True),
        ("alpha", ("narrow", 44718, 7), "#4a4b4e", 0.6, True),
        ("beta", ("narrow", 45661, 8), "#4a4b4e", 0.6, True),
        ("eta", ("narrow", 47176, 1.6), "#4a4b4e", 0.6, True),
        ("gamma", ("narrow", 47627, 3), "#4a4b4e", 0.6, True),
        ("delta", ("narrow", 48300, 6), "#4a4b4e", 0.6, True),
        ("lambda", ("narrow", 50023, 2), "#4a4b4e", 0.5, True),
        ("epsilon", ("narrow", 51149, 58), "#56575a", 0.75, True),
        ("nu", (66100, 69900), "#5a4a40", 0.03, True),
        ("mu", (86000, 103000), "#4a5a78", 0.02, True),
    ],
    "Neptune": [
        ("Galle", (40900, 42900), "#5c4a42", 0.05, True),
        ("Le Verrier", ("narrow", 53200, 113), "#6a5a50", 0.45, True),
        ("Lassell", (53300, 57200), "#5c4a42", 0.04, True),
        ("Arago", ("narrow", 57200, 100), "#6a5a50", 0.3, True),
        ("Adams", ("narrow", 62932, 50), "#6a5a50", 0.4, True),
        # the arcs in the Adams ring (Courage, Liberte, Egalite 1 and 2,
        # Fraternite), about 40 degrees of it: where they are round the ring
        # is an example (they go round in 0.44 days)
        ("Adams arcs", ("arc", 62932, 50, 0.0, 40.0), "#8a7868", 0.85, True),
    ],
}


def reach_of(planet):
    txt = open(os.path.join(HERE, "solar-data.lua")).read()
    m = re.search(r'planet = "%s".*?reach = ([0-9.e+-]+)' % planet, txt)
    return float(m.group(1))


def write_obj(path, V, F, note):
    with open(path, "w") as fo:
        fo.write("# %s\n" % note)
        for v in V:
            fo.write("v %.5f %.5f %.5f\n" % v)
        for f in F:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))


def annulus(s0, s1, a0=0.0, a1=360.0, n=None):
    """A flat ring in the x-z plane, s0 to s1 cm, from angle a0 to a1 (degrees)."""
    span = a1 - a0
    if n is None:
        n = max(12, int(round(96 * span / 360)))   # (96 round: a chord at 7 cm misses the circle by 0.004 cm)
    full = span >= 360
    V, F = [], []
    m = n if full else n + 1
    for k in range(m):
        th = math.radians(a0 + span * k / n)
        c, s = math.cos(th), -math.sin(th)
        V.append((s0 * c, 0.0, s0 * s))
        V.append((s1 * c, 0.0, s1 * s))
    for k in range(n):
        a, b = 2 * k, 2 * ((k + 1) % m)
        F.append((a, a + 1, b + 1))       # (bpp draws each triangle both ways)
        F.append((a, b + 1, b))
    return V, F


def main():
    L = ["-- The giant planets' rings, made by make-rings.py: don't edit.",
         "-- Radii in km (from memory: see make-rings.py); each band's meshes, orrery and vitrine.",
         "return {"]
    for planet, bands in RINGS.items():
        reach = reach_of(planet) * AU
        R = R_MEAN[planet]
        sphere = 0.33 * math.sqrt(R / 1000)
        L.append('  %s = {' % planet)
        for k, (name, r, col, op, faint) in enumerate(bands):
            a0, a1 = 0.0, 360.0
            if isinstance(r[0], str):           # ("narrow", centre, width) or ("arc", centre, width, from, to)
                rc, w = r[1], r[2]
                if r[0] == "arc":
                    a0, a1 = r[3], r[4]
                r0, r1, narrow = rc - w / 2, rc + w / 2, True
            else:
                r0, r1, narrow = r[0], r[1], False
            files = {}
            for which in ("orrery", "vitrine"):
                if which == "orrery":
                    s0, s1 = sphere * r0 / R, sphere * r1 / R
                else:
                    s0, s1 = VITRINE_R * math.sqrt(r0 / reach), VITRINE_R * math.sqrt(r1 / reach)
                if s1 - s0 < MIN_W[which]:
                    c = (s0 + s1) / 2
                    s0, s1 = c - MIN_W[which] / 2, c + MIN_W[which] / 2
                V, F = annulus(s0, s1, a0, a1)
                fn = "rings-%s-%s-%d.obj" % (which, planet.lower(), k + 1)
                write_obj(os.path.join(MESH, fn), V, F, "%s's %s ring, %s: %.4f to %.4f cm" % (planet, name, which, s0, s1))
                files[which] = fn
            L.append('    { name = "%s", r0 = %g, r1 = %g, col = "%s", op = %g, faint = %s, narrow = %s,'
                     ' orrery = "%s", vitrine = "%s" },'
                     % (name, r0, r1, col, op, "true" if faint else "false", "true" if narrow else "false",
                        files["orrery"], files["vitrine"]))
        L.append('  },')
    L += ["}", ""]
    with open(os.path.join(HERE, "solar-rings.lua"), "w") as fo:
        fo.write("\n".join(L))
    print("solar-rings.lua and %d meshes" % (2 * sum(len(b) for b in RINGS.values())))


if __name__ == "__main__":
    main()
