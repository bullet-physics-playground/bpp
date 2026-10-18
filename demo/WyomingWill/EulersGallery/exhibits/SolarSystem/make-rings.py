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

THE RING DATA are NASA's: the NSSDC ring fact sheets (D. R. Williams,
updated 14 Oct 2015), fetched 18 Oct 2026:
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/satringfact.html
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/uranringfact.html
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/jupringfact.html
  https://nssdc.gsfc.nasa.gov/planetary/factsheet/nepringfact.html
Their radii, optical depths (tau), albedos and widths. The sheets list a
ring, ringlet or gap narrower than 1000 km by its INNER EDGE: so a narrow
ring here runs from its listed radius out by its width ("edge" below). The
wide faint ones the sheets give by a radius and a width (Galle, Uranus' nu
and mu) are centred on it. What isn't on the sheets is marked NOT ON THE
SHEETS: the Encke gap's width (325 km), the F ring's width (50 km), Uranus'
zeta ring (37,850-41,350 km; the sheet lists 12 rings, not 13), the arcs'
span (40 degrees, and where round the ring: an example), and the taus or
albedos the sheets leave out (taken as said where used).

HOW tau AND albedo ARE DRAWN, the same rule for every ring:
  opacity = the larger of 1 - exp(-tau) (the light a ring stops, seen face
            on) and 0.012 (log10 tau + 7.5) (a floor for the faint dusty
            rings, whose true opacity, 1e-7 to 1e-4, nobody could see: on
            it, tau 1e-7 is 0.006, 1e-5 0.03, 1e-2 0.066), at most 0.97;
  brightness = the ring's hue times (albedo / 0.6) ** (1/2.2): its
            reflectance against Saturn's brightest (0.6), in the screen's
            gamma (so albedo 0.5 is 92% of the hue, 0.2 61%, 0.015 19%).
The faint rings (tau below 0.05) also become up to three times as opaque as
you come close (solar-system.lua), so that you can find them.

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

# each band: name, radii (km: (inner, outer); ("edge", inner, width); ("centre",
# radius, width); ("arc", inner, width, from, to degrees)), tau, albedo, hue
# (its colour at albedo 0.6), what's not on the NSSDC sheets
SATURN, DUST, GREY, RED = "#f4e8c8", "#c9a88a", "#d8d8dc", "#d6b8a0"
RINGS = {
    "Saturn": [
        ("D", (66900, 74510), 1e-5, 0.12, SATURN, "albedo not on the sheet: taken as C's lowest"),
        ("C", (74658, 91975), 0.2, 0.21, SATURN, ""),            # tau 0.05-0.35, albedo 0.12-0.30
        ("B", (91975, 117507), 1.45, 0.5, SATURN, ""),           # tau 0.4-2.5, albedo 0.4-0.6
        ("Cassini Division", (117507, 122340), 0.05, 0.3, SATURN, ""),   # tau 0-0.1, albedo 0.2-0.4
        ("A", (122340, 133410), 0.7, 0.5, SATURN, ""),           # tau 0.4-1.0, albedo 0.4-0.6
        ("A (outside the Encke gap)", (133735, 136780), 0.7, 0.5, SATURN,
         "the Encke gap's width, 325 km, not on the sheet (it gives its inner edge, 133,410)"),
        ("F", ("edge", 139826, 50), 0.1, 0.6, SATURN, "its width, 50 km, not on the sheet"),
    ],
    "Jupiter": [
        ("halo", (89400, 123000), 3e-6, 0.015, DUST, "albedo not on the sheet: taken as the main ring's"),
        ("main ring", (123000, 128940), 5e-6, 0.015, DUST, ""),
        ("Amalthea gossamer ring", (128940, 181350), 1e-7, 0.015, DUST, "albedo: as the main ring's"),
        ("Thebe gossamer ring", (181350, 221900), 1e-7, 0.015, DUST, "albedo: as the main ring's"),
        ("Thebe ring's extension", (221900, 280000), 1e-7, 0.015, DUST, "albedo: as the main ring's"),
    ],
    "Uranus": [
        ("zeta", (37850, 41350), 1e-5, 0.015, GREY,
         "NOT ON THE SHEETS (radii from memory; tau and albedo assumed)"),
        ("6", ("edge", 41837, 1.5), 0.3, 0.015, GREY, ""),
        ("5", ("edge", 42234, 2), 0.5, 0.015, GREY, ""),
        ("4", ("edge", 42571, 2), 0.3, 0.015, GREY, ""),
        ("alpha", ("edge", 44718, 7), 0.4, 0.015, GREY, ""),          # width 4-10
        ("beta", ("edge", 45661, 8), 0.3, 0.015, GREY, ""),           # width 5-11
        ("eta", ("edge", 47176, 1.6), 0.4, 0.015, GREY, ""),
        ("gamma", ("edge", 47627, 2.5), 0.3, 0.015, GREY, ""),        # width 1-4
        ("delta", ("edge", 48300, 5), 0.5, 0.015, GREY, ""),          # width 3-7
        ("lambda", ("edge", 50024, 2), 0.1, 0.015, GREY, ""),
        ("epsilon", ("edge", 51149, 58), 1.4, 0.018, GREY, ""),       # width 20-96, tau 0.5-2.3
        ("nu (R/2003 U 2)", ("centre", 67300, 3800), 1e-5, 0.015, GREY, "tau '<<0.01' on the sheet: taken as 1e-5; albedo not on it"),
        ("mu (R/2003 U 1)", ("centre", 97700, 17000), 1e-5, 0.015, GREY, "tau '<<0.01' on the sheet: taken as 1e-5; albedo not on it"),
    ],
    "Neptune": [
        ("Galle", ("centre", 41900, 2000), 1e-4, 0.015, RED, ""),
        ("Le Verrier", ("edge", 53200, 100), 0.01, 0.015, RED, ""),   # width <100
        ("Lassell", ("edge", 53200, 4000), 1e-4, 0.015, RED, ""),     # out from Le Verrier
        ("Arago", ("edge", 57200, 100), 1e-4, 0.015, RED, "its tau not on the sheet (its column reads '<100', likely the width): taken as Lassell's"),
        ("Adams", ("edge", 62933, 15), 0.05, 0.015, RED, ""),         # tau 0.01-0.1
        ("Adams arcs", ("arc", 62933, 15, 0.0, 40.0), 0.12, 0.04, RED,
         "their span (40 degrees) and place round the ring not on the sheet: an example"),
    ],
}
# (not drawn: Saturn's G and E rings, tau 1e-6, 166,000-173,000 and
# 180,000-480,000 km, beyond the vitrine's moons' rule and as faint as
# Jupiter's; the Keeler gap (inner edge 136,487 km); Neptune's indistinct
# unnamed ring at 61,953 km)


def opacity(tau):
    return min(0.97, max(1 - math.exp(-tau), 0.012 * (math.log10(tau) + 7.5)))


def shade(hue, albedo):
    f = min(1.0, albedo / 0.6) ** (1 / 2.2)
    return "#%02x%02x%02x" % tuple(int(round(int(hue[i:i + 2], 16) * f)) for i in (1, 3, 5))


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
    for f in os.listdir(MESH):                  # (the old ones: the bands are numbered)
        if f.startswith("rings-") and f.endswith(".obj"):
            os.remove(os.path.join(MESH, f))
    L = ["-- The giant planets' rings, made by make-rings.py: don't edit.",
         "-- Radii in km, tau and albedo from NASA's NSSDC ring fact sheets (fetched 2026-10-18; see make-rings.py);",
         "-- op and col drawn from them by make-rings.py's rule; each band's meshes, orrery and vitrine.",
         "return {"]
    for planet, bands in RINGS.items():
        reach = reach_of(planet) * AU
        R = R_MEAN[planet]
        sphere = 0.33 * math.sqrt(R / 1000)
        L.append('  %s = {' % planet)
        for k, (name, r, tau, albedo, hue, note) in enumerate(bands):
            a0, a1 = 0.0, 360.0
            narrow = False
            if r[0] == "edge":
                r0, r1, narrow = r[1], r[1] + r[2], r[2] < 1000
            elif r[0] == "centre":
                r0, r1 = r[1] - r[2] / 2, r[1] + r[2] / 2
            elif r[0] == "arc":
                r0, r1, narrow, a0, a1 = r[1], r[1] + r[2], True, r[3], r[4]
            else:
                r0, r1 = r
            op, col, faint = opacity(tau), shade(hue, albedo), tau < 0.05
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
            L.append('    { name = "%s", r0 = %g, r1 = %g, tau = %g, albedo = %g, col = "%s", op = %.3f, faint = %s,'
                     ' narrow = %s, orrery = "%s", vitrine = "%s"%s },'
                     % (name, r0, r1, tau, albedo, col, op, "true" if faint else "false", "true" if narrow else "false",
                        files["orrery"], files["vitrine"], (', note = "%s"' % note.replace('"', "'")) if note else ""))
        L.append('  },')
    L += ["}", ""]
    with open(os.path.join(HERE, "solar-rings.lua"), "w") as fo:
        fo.write("\n".join(L))
    print("solar-rings.lua and %d meshes" % (2 * sum(len(b) for b in RINGS.values())))


if __name__ == "__main__":
    main()
