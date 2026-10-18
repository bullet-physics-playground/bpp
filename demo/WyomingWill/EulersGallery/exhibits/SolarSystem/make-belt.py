#!/usr/bin/env python3
"""
The asteroid belt's data: solar-belt.lua, for solar-system.lua.

The thirty largest asteroids of the main belt, with their osculating orbital
elements (heliocentric, the ecliptic and equinox of J2000, epoch
JD 2461000.5 TT = 2025-11-21), their discoverers and discovery dates.

WHICH THIRTY, AND HOW BIG: JPL's Small-Body Database, its Query API, the 40
largest asteroids by diameter, with the diameter's sigma, a, e and i
(fetched 18 Oct 2026, saved in belt/sbdb-largest-40.txt):
  https://ssd-api.jpl.nasa.gov/sbdb_query.api?fields=full_name,diameter,diameter_sigma,a,e,i&sb-kind=a&sort=-diameter&limit=40
The main belt is taken as 2.0 AU < a < 3.6 AU: from inside the Hungarias'
edge out to the 7:4 resonance with Jupiter at 3.58 AU, which bounds the
Cybele group (Sylvia, Camilla, Hermione, Cybele, 3.4-3.5 AU), commonly
counted as the outer main belt. That leaves out the trans-Neptunians and
Centaurs (Varuna, 1993 SC, Chariklo, 2002 GZ32, Typhon, Pholus), the Jupiter
Trojan Hektor (5.28 AU) and the Hilda Chicago (3.94 AU, in the 3:2 resonance).
The thirty are the largest 30 of what's left, by SBDB's diameter; each is
drawn by it. Where SBDB gives no sigma (null: Thisbe, Ursula, Fortuna,
Themis) or -1 (Psyche), solar-belt.lua has none.

WHERE THE ELEMENTS COME FROM: the Minor Planet Center's, as Stellarium
carries them in its data/ssystem_minor.ini (github.com/Stellarium/stellarium,
master, fetched 2026-10-18), since the SBDB query above has no epoch or
angles. The thirty entries used are copied, unchanged, to
belt/ssystem_minor-excerpt.ini. They are checked: the five that are also in
the main integration (Ceres, Pallas, Juno, Vesta, Hygiea) are started from
these elements too and compared with JPL Horizons' positions in horizons/
(fetched by fetch-horizons.sh) by the exhibit's console. SBDB's a, e and i
are checked against them here: the same orbits (a within 0.007 AU, e 0.003,
i 0.03 degrees: osculating elements at SBDB's epoch, not the MPC's).

    cd demo/WyomingWill/EulersGallery/exhibits/SolarSystem && python3 make-belt.py
"""
import os
import re
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
EXCERPT = os.path.join(HERE, "belt", "ssystem_minor-excerpt.ini")
URL = "https://raw.githubusercontent.com/Stellarium/stellarium/master/data/ssystem_minor.ini"

SBDB = os.path.join(HERE, "belt", "sbdb-largest-40.txt")
NUMBER = {"Ceres": 1, "Vesta": 4, "Pallas": 2, "Hygiea": 10}    # (SBDB names these four without their numbers)
A_MIN, A_MAX, N = 2.0, 3.6, 30


def largest():
    """[(number, name, diameter, sigma or None, a, e, i)], the main belt's N largest."""
    out = []
    for line in open(SBDB, encoding="utf-8"):
        if line.startswith("#") or "|" not in line:
            continue
        f = [x.strip() for x in line.split("|")]
        m = re.match(r"(?:(\d+) )?(\S+) \(", f[0])
        no, name = (int(m.group(1)) if m.group(1) else NUMBER.get(m.group(2))), m.group(2)
        a = float(f[3])
        if not (A_MIN < a < A_MAX) or no is None:
            continue
        sig = None if f[2] in ("null", "-1.00", "-1") else float(f[2])
        out.append((no, name, float(f[1]), sig, a, float(f[4]), float(f[5])))
    return out[:N]


IN_ENGINE = {"Ceres", "Pallas", "Juno", "Vesta", "Hygiea"}     # (also integrated with their masses)


def blocks(txt):
    for blk in re.split(r"\n(?=\[)", txt):
        m = re.match(r"\[([^\]]+)\]", blk)
        if not m:
            continue
        d = {"_key": m.group(1), "_text": blk.rstrip() + "\n"}
        for line in blk.splitlines()[1:]:
            if "=" in line and not line.lstrip().startswith("#"):
                k, v = line.split("=", 1)
                d[k.strip()] = v.strip()
        yield d


def main():
    BIG = largest()
    txt = open(EXCERPT, encoding="utf-8").read() if os.path.exists(EXCERPT) else ""
    byno = {}
    for d in blocks(txt):
        if d.get("type") == "asteroid" and d.get("minor_planet_number"):
            byno[int(d["minor_planet_number"])] = d
    if any(no not in byno for no, *_ in BIG):
        print("fetching", URL)
        txt = urllib.request.urlopen(URL, timeout=60).read().decode("utf-8")
        for d in blocks(txt):
            if d.get("type") == "asteroid" and d.get("minor_planet_number"):
                byno[int(d["minor_planet_number"])] = d
    os.makedirs(os.path.dirname(EXCERPT), exist_ok=True)
    with open(EXCERPT, "w", encoding="utf-8") as fo:
        fo.write("# The thirty entries make-belt.py uses, copied unchanged from Stellarium's\n"
                 "# data/ssystem_minor.ini (github.com/Stellarium/stellarium, master, 2026-10-18):\n"
                 "# the Minor Planet Center's osculating elements, epoch JD 2461000.5 TT.\n\n")
        for no, *_ in BIG:
            fo.write(byno[no]["_text"] + "\n")
    L = ["-- The asteroid belt, made by make-belt.py: don't edit.",
         "-- Osculating elements, heliocentric, ecliptic and equinox of J2000 (degrees, AU),",
         "-- the Minor Planet Center's via Stellarium's ssystem_minor.ini; diameters (d, km)",
         "-- and their sigmas JPL SBDB's (belt/sbdb-largest-40.txt, fetched 2026-10-18).",
         "return {",
         "  EPOCH = 2461000.5,  -- JD (TT), 2025-11-21",
         "  list = {"]
    worst = 0
    WORST = []
    for no, name, dia, sig, sa, se, si in BIG:
        d = byno[no]
        # (Stellarium has 532 Herculina cut short, as "Herculin")
        assert name.startswith(d["name"]) or d["name"].startswith(name[:8]), (no, d["name"], name)
        a, e, i = float(d["orbit_SemiMajorAxis"]), float(d["orbit_Eccentricity"]), float(d["orbit_Inclination"])
        assert float(d["orbit_Epoch"]) == 2461000.5, name
        # (SBDB's elements -- osculating at its own epoch, rounded -- against the
        # MPC's: the same orbit, to what the epochs' difference allows)
        assert abs(a - sa) < 0.02 and abs(e - se) < 0.005 and abs(i - si) < 0.05, (name, a, sa, e, se, i, si)
        worst = max(worst, abs(a - sa))
        WORST.append((abs(a - sa), abs(e - se), abs(i - si), name))
        L.append('    { no = %d, name = "%s", d = %g, sigma = %s, H = %s, a = %s, e = %s, i = %s, node = %s, peri = %s, M = %s,'
                 ' found = "%s", by = "%s"%s },'
                 % (no, name, dia, "%g" % sig if sig is not None else "nil", d["absolute_magnitude"],
                    d["orbit_SemiMajorAxis"], d["orbit_Eccentricity"], d["orbit_Inclination"],
                    d["orbit_AscendingNode"], d["orbit_ArgOfPericenter"], d["orbit_MeanAnomaly"],
                    d["discovery"], d["discoverer"], ", engine = true" if name in IN_ENGINE else ""))
    L += ["  },", "}", ""]
    with open(os.path.join(HERE, "solar-belt.lua"), "w", encoding="utf-8") as fo:
        fo.write("\n".join(L))
    print("solar-belt.lua: %d asteroids; SBDB's against the MPC's: a within %.4f AU (%s), e %.4f, i %.3f deg"
          % (len(BIG), worst, max(WORST)[3], max(w[1] for w in WORST), max(w[2] for w in WORST)))


if __name__ == "__main__":
    main()
