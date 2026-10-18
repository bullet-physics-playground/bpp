#!/usr/bin/env python3
"""
The asteroid belt's data: solar-belt.lua, for solar-system.lua.

The thirty largest asteroids of the main belt, with their osculating orbital
elements (heliocentric, the ecliptic and equinox of J2000, epoch
JD 2461000.5 TT = 2025-11-21), their discoverers and discovery dates.

WHERE THE ELEMENTS COME FROM. JPL's Small-Body Database (ssd-api.jpl.nasa.gov)
and Horizons could not be reached from where this was made (the network
refused them), so the elements are the Minor Planet Center's, as Stellarium
carries them in its data/ssystem_minor.ini (github.com/Stellarium/stellarium,
master, fetched 2026-10-18; sha256 542cb048...5846). The thirty entries used
are copied to belt/ssystem_minor-excerpt.ini. They are checked: the five that
are also in the main integration (Ceres, Pallas, Juno, Vesta, Hygiea) are
started from these elements too and compared with JPL Horizons'
positions in horizons/ (fetched by fetch-horizons.sh) by the exhibit's
console: 2026-01-01, 41 days after the elements' epoch, they agree within
1,000 km (Hygiea 6,000), which is what a two-body orbit followed for six weeks gives.

THE DIAMETERS ARE FROM MEMORY (published mean diameters: Dawn's for Ceres
and Vesta; ESO VLT/SPHERE shape models, Vernazza et al. 2021, Marsset et al.
2020, Hanus et al. 2017-2020, for most of the rest; NEOWISE/IRAS for a
few), not checked here against a source: each within about 10%. They decide
which thirty are "the largest" (everything over about 190 km across), and
how big each is drawn. A different source could swap the last few.

    cd demo/WyomingWill/EulersGallery/exhibits/SolarSystem && python3 make-belt.py
"""
import os
import re
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
EXCERPT = os.path.join(HERE, "belt", "ssystem_minor-excerpt.ini")
URL = "https://raw.githubusercontent.com/Stellarium/stellarium/master/data/ssystem_minor.ini"

# number, name, mean diameter (km, FROM MEMORY, see above)
BIG = [
    (1, "Ceres", 939.4), (4, "Vesta", 525.4), (2, "Pallas", 513), (10, "Hygiea", 434),
    (704, "Interamnia", 332), (52, "Europa", 315), (511, "Davida", 298), (87, "Sylvia", 271),
    (15, "Eunomia", 268), (31, "Euphrosyne", 268), (65, "Cybele", 263), (3, "Juno", 254),
    (107, "Camilla", 254), (324, "Bamberga", 228), (451, "Patientia", 225), (16, "Psyche", 222),
    (88, "Thisbe", 218), (48, "Doris", 216), (375, "Ursula", 216), (7, "Iris", 214),
    (19, "Fortuna", 211), (423, "Diotima", 208), (532, "Herculina", 207), (29, "Amphitrite", 204),
    (94, "Aurora", 204), (13, "Egeria", 203), (45, "Eugenia", 202), (130, "Elektra", 199),
    (24, "Themis", 198), (121, "Hermione", 194),
]
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
    if os.path.exists(EXCERPT):
        txt = open(EXCERPT, encoding="utf-8").read()
    else:
        print("fetching", URL)
        txt = urllib.request.urlopen(URL, timeout=60).read().decode("utf-8")
    byno = {}
    for d in blocks(txt):
        if d.get("type") == "asteroid" and d.get("minor_planet_number"):
            byno[int(d["minor_planet_number"])] = d
    os.makedirs(os.path.dirname(EXCERPT), exist_ok=True)
    with open(EXCERPT, "w", encoding="utf-8") as fo:
        fo.write("# The thirty entries make-belt.py uses, copied unchanged from Stellarium's\n"
                 "# data/ssystem_minor.ini (github.com/Stellarium/stellarium, master, 2026-10-18):\n"
                 "# the Minor Planet Center's osculating elements, epoch JD 2461000.5 TT.\n\n")
        for no, name, _ in BIG:
            fo.write(byno[no]["_text"] + "\n")
    L = ["-- The asteroid belt, made by make-belt.py: don't edit.",
         "-- Osculating elements, heliocentric, ecliptic and equinox of J2000 (degrees, AU),",
         "-- from the Minor Planet Center via Stellarium's ssystem_minor.ini; diameters (km)",
         "-- from memory (see make-belt.py).",
         "return {",
         "  EPOCH = 2461000.5,  -- JD (TT), 2025-11-21",
         "  list = {"]
    for no, name, dia in BIG:
        d = byno[no]
        # (Stellarium has 532 Herculina cut short, as "Herculin")
        assert name.startswith(d["name"]), (no, d["name"], name)
        a, e = float(d["orbit_SemiMajorAxis"]), float(d["orbit_Eccentricity"])
        assert 2.0 < a < 3.7 and a * (1 - e) > 1.66, name          # the main belt
        assert float(d["orbit_Epoch"]) == 2461000.5, name
        L.append('    { no = %d, name = "%s", d = %g, H = %s, a = %s, e = %s, i = %s, node = %s, peri = %s, M = %s,'
                 ' found = "%s", by = "%s"%s },'
                 % (no, name, dia, d["absolute_magnitude"], d["orbit_SemiMajorAxis"], d["orbit_Eccentricity"],
                    d["orbit_Inclination"], d["orbit_AscendingNode"], d["orbit_ArgOfPericenter"],
                    d["orbit_MeanAnomaly"], d["discovery"], d["discoverer"],
                    ", engine = true" if name in IN_ENGINE else ""))
    L += ["  },", "}", ""]
    with open(os.path.join(HERE, "solar-belt.lua"), "w", encoding="utf-8") as fo:
        fo.write("\n".join(L))
    print("solar-belt.lua: %d asteroids" % len(BIG))


if __name__ == "__main__":
    main()
