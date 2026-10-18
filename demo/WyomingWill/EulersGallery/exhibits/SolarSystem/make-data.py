"""The solar system's starting data: solar-data.lua, from JPL.

Run from this folder: python3 make-data.py
Needs NumPy and jplephem (pip install jplephem), and JPL's DE421 ephemeris,
de421.bsp (pip install skyfield-data: it's in its data folder; or from
https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/). The moons and asteroids
come from JPL Horizons: fetch-horizons.sh puts them in horizons/. Any that
aren't there yet get stand-in orbits (marked so), from mean elements.

Everything is in JPL's frame, the ICRF (Earth's equator and equinox of
J2000), in AU and AU per day, at 2026 January 1, 0h TDB. The planets, the
Moon and Pluto start where DE421 has them, and DE421's positions at later
dates (every year to 2050) go in too, for the exhibit to check itself
against; Horizons' later positions of the moons and asteroids likewise.

It also makes the exhibit's meshes, in solar-meshes/: the orrery's orbits
(each body's two-body orbit as it is at the start, its distance from the
Sun square-rooted, as the orrery draws it), Saturn's rings, the date's
digits and the vitrines' names. (Needs Pillow and the DejaVu fonts, too.)
"""
import glob, math, os, re, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
JD0 = 2461041.5                     # 2026-01-01 0h TDB
AU = 149597870.6996262              # DE421's
KM3S2 = 86400.0 ** 2 / AU ** 3      # km^3/s^2 -> AU^3/d^2

# ---------------------------------------------------------------------------
# DE421
# ---------------------------------------------------------------------------
def find_bsp():
    for p in [os.path.join(HERE, "de421.bsp"), "de421.bsp"]:
        if os.path.exists(p):
            return p
    try:
        import skyfield_data
        p = os.path.join(os.path.dirname(skyfield_data.__file__), "data", "de421.bsp")
        if os.path.exists(p):
            return p
    except ImportError:
        pass
    sys.exit("de421.bsp not found: pip install skyfield-data, or put de421.bsp here")

from jplephem.spk import SPK
K = SPK.open(sys.argv[1] if len(sys.argv) > 1 else find_bsp())

def de(i, jd):
    """Barycentric position (AU) and velocity (AU/d) of NAIF body i."""
    if i in (399, 301):
        p, v = K[0, 3].compute_and_differentiate(jd)
        q, w = K[3, i].compute_and_differentiate(jd)
        return (p + q) / AU, (v + w) / AU
    p, v = K[0, i].compute_and_differentiate(jd)
    return p / AU, v / AU

# DE421's masses (AU^3/d^2)
GMS = 0.0002959122082855911
EMRAT = 81.3005690699153
GMB = 8.997011408268049e-10
GM_DE = {10: GMS, 1: 4.91254957186794e-11, 2: 7.243452332698441e-10, 399: GMB * EMRAT / (1 + EMRAT),
         301: GMB / (1 + EMRAT), 4: 9.54954869562239e-11, 5: 2.82534584085505e-07, 6: 8.459706073308477e-08,
         7: 1.29202482579265e-08, 8: 1.52435910924974e-08, 9: 2.17844105199052e-12,
         2000001: 1.386390447855846e-13, 2000002: 2.988216510330216e-14, 2000003: 3.424278300941669e-15,
         2000004: 3.931009658107358e-14, 2000010: 1.195934778958387e-14}

# ---------------------------------------------------------------------------
# the bodies
# ---------------------------------------------------------------------------
# the main integration: name, NAIF id, radius km, colour
MAIN = [("Sun", 10, 695700, "#ffd35a"), ("Mercury", 1, 2439.7, "#a8a29a"), ("Venus", 2, 6051.8, "#e8cf8a"),
        ("Earth", 399, 6371.0, "#3f7fd8"), ("Moon", 301, 1737.4, "#c9c9c9"), ("Mars", 4, 3389.5, "#c8582e"),
        ("Jupiter", 5, 69911, "#d9b38c"), ("Saturn", 6, 58232, "#e3cf94"), ("Uranus", 7, 25362, "#9fd9e0"),
        ("Neptune", 8, 24622, "#4f6fe0"), ("Pluto", 9, 1188.3, "#c9a989")]
ASTEROIDS = [("Ceres", 2000001, 469.7, "#8f8a82", (2.7675, 0.0785, 10.59, 80.25, 73.6)),
             ("Pallas", 2000002, 256.0, "#8a8f96", (2.7700, 0.2302, 34.93, 172.9, 310.9)),
             ("Juno", 2000003, 127.0, "#9a8f80", (2.6683, 0.2562, 12.99, 169.8, 248.1)),
             ("Vesta", 2000004, 262.7, "#a49a8a", (2.3615, 0.0894, 7.14, 103.7, 151.5)),
             ("Hygiea", 2000010, 216.5, "#7f7a74", (3.1415, 0.1125, 3.83, 283.2, 312.3))]
# the moon systems: planet, its NAIF body id, GM of the system's moons km^3/s^2, J2, J4, reference radius km,
# pole RA, Dec (deg, IAU, ~2026), and its moons: name, id, GM km^3/s^2, radius km, stand-in a km, e, i (to the
# equator) deg
SYSTEMS = [
    ("Mars", 499, 4, 1.96045e-3, 0.0, 3396.0, 317.653, 52.871,
     [("Phobos", 401, 7.087e-4, 11.1, 9376, 0.0151, 1.08), ("Deimos", 402, 9.62e-5, 6.2, 23458, 0.0003, 1.79)]),
    ("Jupiter", 599, 5, 14696.43e-6, -587.14e-6, 71492, 268.0549, 64.4959,
     [("Io", 501, 5959.916, 1821.6, 421800, 0.0041, 0.036), ("Europa", 502, 3202.739, 1560.8, 671100, 0.0094, 0.466),
      ("Ganymede", 503, 9887.834, 2631.2, 1070400, 0.0013, 0.177), ("Callisto", 504, 7179.289, 2410.3, 1882700, 0.0074, 0.192)]),
    ("Saturn", 699, 6, 16290.71e-6, -935.83e-6, 60330, 40.580, 83.536,
     [("Mimas", 601, 2.5026, 198.2, 185539, 0.0196, 1.574), ("Enceladus", 602, 7.2027, 252.1, 238042, 0.0047, 0.009),
      ("Tethys", 603, 41.2067, 531.1, 294672, 0.0001, 1.091), ("Dione", 604, 73.1146, 561.4, 377415, 0.0022, 0.028),
      ("Rhea", 605, 153.9426, 763.8, 527068, 0.0010, 0.333), ("Titan", 606, 8978.1382, 2574.7, 1221865, 0.0288, 0.306),
      ("Iapetus", 608, 120.5038, 734.5, 3560854, 0.0283, 15.5)]),
    ("Uranus", 799, 7, 3510.68e-6, -34.17e-6, 25559, 257.311, -15.175,
     [("Miranda", 705, 4.32, 235.8, 129872, 0.0013, 4.338), ("Ariel", 701, 83.43, 578.9, 190945, 0.0012, 0.041),
      ("Umbriel", 702, 85.09, 584.7, 265998, 0.0039, 0.128), ("Titania", 703, 226.94, 788.9, 436298, 0.0011, 0.079),
      ("Oberon", 704, 205.32, 761.4, 583519, 0.0014, 0.068)]),
    ("Neptune", 899, 8, 3408.4e-6, -33.4e-6, 25225, 299.50, 42.96,
     [("Triton", 801, 1428.495, 1353.4, 354759, 0.000016, 157.0)]),
    ("Pluto", 999, 9, 0.0, 0.0, 1188.3, 132.993, -6.163,
     [("Charon", 901, 105.88, 606.0, 19596, 0.00005, 0.0)]),
]
# each moon system's mass (planet and moons), km^3/s^2: DE440's, which
# JPL's moon solutions (and so Horizons) go with, not DE421's (the main
# integration keeps DE421's, as its planets start from DE421). Pluto's:
# the mass Horizons' Charon orbit (plu060) implies -- a two-body fit to its
# five years, 975.43 (DE440: 975.5; DE421: 977.0, which takes Charon 20,000
# km off in a year)
SYSTEM_GM = {"Mars": 42828.375816, "Jupiter": 126712764.1, "Saturn": 37940584.8418, "Uranus": 5794556.4,
             "Neptune": 6836527.10058, "Pluto": 975.43}
# a planet that isn't round about its axis: Mars's C22 and S22
# (unnormalised, from the normalised -8.46e-5 and 4.89e-5 of its gravity
# field, at the 3396 km radius) and its rotation, the IAU's prime meridian
# W = w0 + wdot d (degrees; d days from J2000). Phobos goes round three
# times a Martian day, and this takes its drift from Horizons from 3,200
# km a year to 1,000
N22 = math.sqrt(2 * 5 / 24)
TESSERAL = {"Mars": (-8.46e-5 * N22, 4.89e-5 * N22, 176.630, 350.89198226)}
# the Earth's J2 (for the Moon) and radius, DE421's
J2E, RE = 0.001082625305, 6378.1363

# ---------------------------------------------------------------------------
# Horizons files (fetch-horizons.sh): rows of JD, X, Y, Z, VX, VY, VZ
# ---------------------------------------------------------------------------
def horizons(i):
    p = os.path.join(HERE, "horizons", "%d.txt" % i)
    if not os.path.exists(p):
        return None
    txt = open(p).read()
    m = re.search(r"\$\$SOE(.*?)\$\$EOE", txt, re.S)
    if not m:
        print("  horizons/%d.txt: no $$SOE ... $$EOE block, ignored" % i)
        return None
    rows = []
    for line in m.group(1).strip().splitlines():
        f = [x.strip() for x in line.split(",")]
        nums = [float(x) for x in f if re.fullmatch(r"[-+]?\d+\.\d*(E[-+]?\d+)?", x)]
        # JDTDB, X, Y, Z, VX, VY, VZ (the calendar date is skipped)
        if len(nums) >= 7:
            rows.append(nums[:7])
    return {round(r[0], 4): (np.array(r[1:4]), np.array(r[4:7])) for r in rows}

# ---------------------------------------------------------------------------
# stand-ins: an orbit from mean elements, in a given plane
# ---------------------------------------------------------------------------
def ra_dec_vec(ra, dec):
    ra, dec = math.radians(ra), math.radians(dec)
    return np.array([math.cos(dec) * math.cos(ra), math.cos(dec) * math.sin(ra), math.sin(dec)])

def kepler_state(mu, a, e, i, node, peri, M, pole):
    """State from elements referred to the plane with the given pole (ICRF unit vector)."""
    E = M
    for _ in range(50):
        E = E - (E - e * math.sin(E) - M) / (1 - e * math.cos(E))
    x, y = a * (math.cos(E) - e), a * math.sqrt(1 - e * e) * math.sin(E)
    n = math.sqrt(mu / a ** 3)
    r = a * (1 - e * math.cos(E))
    vx, vy = -a * n * math.sin(E) / (1 - e * math.cos(E)), a * n * math.sqrt(1 - e * e) * math.cos(E) / (1 - e * math.cos(E))
    def rot(v, ax, ang):
        ax = ax / np.linalg.norm(ax)
        return v * math.cos(ang) + np.cross(ax, v) * math.sin(ang) + ax * np.dot(ax, v) * (1 - math.cos(ang))
    zp = pole / np.linalg.norm(pole)
    xp = np.cross([0, 0, 1.0], zp)
    if np.linalg.norm(xp) < 1e-9:
        xp = np.array([1.0, 0, 0])
    xp /= np.linalg.norm(xp)
    yp = np.cross(zp, xp)
    P, Q = np.array([1.0, 0, 0]), np.array([0, 1.0, 0])
    # in the plane's own axes: perifocal, turned by peri, tilted by i about the node line, turned by node
    def place(u):
        v = np.array([u[0], u[1], 0.0])
        v = rot(v, np.array([0, 0, 1.0]), peri)
        v = rot(v, np.array([1.0, 0, 0]), i)
        v = rot(v, np.array([0, 0, 1.0]), node)
        return v[0] * xp + v[1] * yp + v[2] * zp
    return place((x, y)), place((vx, vy))

ECL = math.radians(84381.448 / 3600)
ECL_POLE = np.array([0, -math.sin(ECL), math.cos(ECL)])

# ---------------------------------------------------------------------------
# build
# ---------------------------------------------------------------------------
rng = np.random.default_rng(2026)
out = []
def L(s=""):
    out.append(s)

def vec(v):
    return "{ %.17g, %.17g, %.17g }" % tuple(v)

L("-- The solar system's starting data, made by make-data.py: don't edit.")
L("-- ICRF (equator and equinox of J2000), AU, AU/day, TDB; GM in AU^3/day^2.")
L("return {")
L("  JD0 = %.1f,  -- 2026-01-01 0h TDB" % JD0)
L("  AU_KM = %.10f," % AU)
L("  C = %.17g,  -- the speed of light, AU/day" % (299792.458 * 86400 / AU))
L("  J2E = %.12g, RE = %.17g,  -- the Earth's oblateness, for the Moon (RE in AU)" % (J2E, RE / AU))
L("  OBLIQUITY = %.17g,  -- radians" % ECL)


# ---------------------------------------------------------------------------
# the starting states
# ---------------------------------------------------------------------------
sources = {}
STATE = {}            # name -> (p, v): barycentric for the main bodies, from the planet for moons
L("  main = {")
for name, i, rad, col in MAIN:
    p, v = de(i, JD0)
    STATE[name] = (p, v)
    L('    { name = "%s", id = %d, gm = %.17g, r = %.6g, col = "%s", x = %s, v = %s },' % (name, i, GM_DE[i], rad / AU, col, vec(p), vec(v)))
sources["planets, the Moon, Pluto"] = "JPL DE421"
for name, i, rad, col, el in ASTEROIDS:
    h = horizons(i)
    if h and round(JD0, 4) in h:
        p, v = h[round(JD0, 4)]
        src = "Horizons"
    else:
        a, e, inc, node, peri = el
        M = rng.uniform(0, 2 * math.pi)
        p, v = kepler_state(GMS, a, e, math.radians(inc), math.radians(node), math.radians(peri), M, ECL_POLE)
        sp, sv = de(10, JD0)
        p, v = p + sp, v + sv
        src = "stand-in"
    STATE[name] = (p, v)
    sources.setdefault("asteroids: " + src, []).append(name)
    L('    { name = "%s", id = %d, gm = %.17g, r = %.6g, col = "%s", asteroid = true, source = "%s", x = %s, v = %s },'
      % (name, i, GM_DE[i], rad / AU, col, src, vec(p), vec(v)))
L("  },")

def apo(p, v, mu):
    r = np.linalg.norm(p)
    a = 1 / (2 / r - np.dot(v, v) / mu)
    h = np.cross(p, v)
    e = np.linalg.norm(np.cross(v, h) / mu - p / r)
    return a * (1 + e)

# each vitrine's reach (AU): a little beyond its outermost moon's farthest
REACH = {}
ep, ev = STATE["Earth"]
mp, mv = STATE["Moon"]
REACH["Earth"] = 1.06 * apo(mp - ep, mv - ev, GM_DE[399] + GM_DE[301])
POLES = {"Earth": np.array([0, 0, 1.0])}
L("  systems = {")
for (pname, pid, bary, j2, j4, rref, pra, pdec, moons) in SYSTEMS:
    gm_moons = sum(m[2] for m in moons) * KM3S2
    gm_sys = SYSTEM_GM[pname] * KM3S2
    gm_p = gm_sys - gm_moons
    pole = ra_dec_vec(pra, pdec)
    POLES[pname] = pole
    rows = []
    far = 0
    for (mname, mid, mgm, mrad, a, e, inc) in moons:
        h = horizons(mid)
        if h and round(JD0, 4) in h:
            p, v = h[round(JD0, 4)]
            src = "Horizons"
        elif pname == "Jupiter":
            import astronomy
            t = astronomy.Time.Make(2026, 1, 1, 0, 0, 0)          # UT; TDB - UT, 69 s, ignored
            jm = astronomy.JupiterMoons(t)
            st = [jm.io, jm.europa, jm.ganymede, jm.callisto][mid - 501]
            # EQJ, AU, AU/day: the J2000 equator, the ICRF to 0.02 arcseconds
            p, v = np.array([st.x, st.y, st.z]), np.array([st.vx, st.vy, st.vz])
            src = "L1.2"
        else:
            mu = gm_p + mgm * KM3S2
            p, v = kepler_state(mu, a / AU, e, math.radians(inc), rng.uniform(0, 2 * math.pi), rng.uniform(0, 2 * math.pi),
                                rng.uniform(0, 2 * math.pi), pole)
            src = "stand-in"
        STATE[mname] = (p, v)
        sources.setdefault("%s's moons: %s" % (pname, src), []).append(mname)
        rows.append('      { name = "%s", id = %d, gm = %.17g, r = %.6g, source = "%s", x = %s, v = %s },'
                    % (mname, mid, mgm * KM3S2, mrad / AU, src, vec(p), vec(v)))
        far = max(far, apo(p, v, gm_p + mgm * KM3S2))
    if pname == "Pluto":
        # Pluto and Charon about their barycentre: Charon's share of the distance
        mc = moons[0][2] * KM3S2
        far = far * gm_p / (gm_p + mc)
    REACH[pname] = 1.06 * far
    tess = ""
    if pname in TESSERAL:
        tess = " c22 = %.10g, s22 = %.10g, w0 = %.6f, wdot = %.10f," % TESSERAL[pname]
    L('    { planet = "%s", id = %d, bary = %d, gm = %.17g, j2 = %.10g, j4 = %.10g, rref = %.10g, pole = %s, reach = %.10g,%s moons = {'
      % (pname, pid, bary, gm_p, j2, j4, rref / AU, vec(pole), REACH[pname], tess))
    for r in rows:
        L(r)
    L("    } },")
L("  },")
L("  EARTH_REACH = %.10g," % REACH["Earth"])

# ---------------------------------------------------------------------------
# checkpoints: DE421 every year (planets from the Sun, the Moon from the
# Earth); Horizons rows for the moons and asteroids
# ---------------------------------------------------------------------------
L("  checks = {")
for yr in range(2027, 2051):
    jd = JD0 + sum(366 if (y % 4 == 0 and (y % 100 or y % 400 == 0)) else 365 for y in range(2026, yr))
    sp, _ = de(10, jd)
    ep, _ = de(399, jd)
    rows = []
    for n, i, *_ in MAIN[1:]:
        p, _ = de(i, jd)
        rel = p - (ep if i == 301 else sp)
        rows.append('%s = %s' % (n, vec(rel)))
    L('    { jd = %.1f, date = "%d-01-01", %s },' % (jd, yr, ", ".join(rows)))
L("  },")
hchecks = {}
for (pname, pid, *_r, moons) in SYSTEMS:
    for m in moons:
        h = horizons(m[1])
        if h:
            for jd, (p, v) in h.items():
                if jd > JD0:
                    hchecks.setdefault(jd, []).append('%s = %s' % (m[0], vec(p)))
for n, i, *_ in ASTEROIDS:
    h = horizons(i)
    if h:
        for jd, (p, v) in h.items():
            if jd > JD0:
                hchecks.setdefault(jd, []).append('%s = %s' % (n, vec(p)))
L("  hchecks = {  -- Horizons: moons from their planet, asteroids from the solar system's barycentre")
for jd in sorted(hchecks):
    L('    { jd = %.1f, %s },' % (jd, ", ".join(hchecks[jd])))
L("  },")

# ---------------------------------------------------------------------------
# the display
# ---------------------------------------------------------------------------
ORRERY_S = 18.0         # the orrery: cm per square-root AU
VITRINE_R = 24.0        # a vitrine's reach, cm
L("  ORRERY_S = %.6g,  -- the orrery: cm per square-root AU from the Sun" % ORRERY_S)
L("  VITRINE_R = %.6g,  -- a vitrine's reach, cm" % VITRINE_R)
L("  sources = {")
for k, v in sources.items():
    L('    "%s: %s",' % (k, v if isinstance(v, str) else ", ".join(v)))
L("  },")
L("}")
open(os.path.join(HERE, "solar-data.lua"), "w").write("\n".join(out) + "\n")
for k, v in sources.items():
    print(k, v if isinstance(v, str) else ", ".join(v))
print("solar-data.lua: %d lines" % len(out))

# ---------------------------------------------------------------------------
# meshes
# ---------------------------------------------------------------------------
MESH = os.path.join(HERE, "solar-meshes")
os.makedirs(MESH, exist_ok=True)
CE, SE = math.cos(ECL), math.sin(ECL)
def disp(p):
    """ICRF -> the display's axes: x the ecliptic's x, y its north, z toward the viewer (minus the ecliptic's y)."""
    X, Y, Z = p[0], CE * p[1] + SE * p[2], -SE * p[1] + CE * p[2]
    return np.array([X, Z, -Y])

def write_obj(path, V, F, note):
    with open(path, "w") as fo:
        fo.write("# %s\n" % note)
        for v in V:
            fo.write("v %.4f %.4f %.4f\n" % tuple(v))
        for f in F:
            fo.write("f %d %d %d\n" % (f[0] + 1, f[1] + 1, f[2] + 1))

def tube(points, w, closed=True):
    """A thin square-section tube along a polyline (a loop if closed)."""
    V, F = [], []
    n = len(points)
    for k in range(n):
        p = points[k]
        q = points[(k + 1) % n] if (closed or k < n - 1) else points[k]
        o = points[k - 1] if (closed or k > 0) else points[k]
        t = q - o
        t = t / (np.linalg.norm(t) + 1e-12)
        u = np.cross(t, [0, 1.0, 0])
        if np.linalg.norm(u) < 1e-6:
            u = np.cross(t, [1.0, 0, 0])
        u /= np.linalg.norm(u)
        b = np.cross(t, u)
        for c in [(u + b), (u - b), (-u - b), (-u + b)]:
            V.append(p + c * w / 2)
    segs = n if closed else n - 1
    for k in range(segs):
        a, b2 = 4 * k, 4 * ((k + 1) % n)
        for j in range(4):
            j2 = (j + 1) % 4
            F.append((a + j, b2 + j, b2 + j2))
            F.append((a + j, b2 + j2, a + j2))
    return V, F

def orbit_points(p, v, mu, n=360):
    """Points round the two-body orbit through (p, v)."""
    r = np.linalg.norm(p)
    a = 1 / (2 / r - np.dot(v, v) / mu)
    h = np.cross(p, v)
    evec = np.cross(v, h) / mu - p / r
    e = np.linalg.norm(evec)
    P = evec / e
    Q = np.cross(h / np.linalg.norm(h), P)
    pts = []
    for k in range(n):
        E = 2 * math.pi * k / n
        pts.append(a * (math.cos(E) - e) * P + a * math.sqrt(1 - e * e) * math.sin(E) * Q)
    return pts

# the orrery's orbits, from the Sun, square-rooted
sp, sv = STATE["Sun"]
for name, i, *_ in MAIN[1:] + [(a[0], a[1]) for a in ASTEROIDS]:
    if name == "Moon":
        continue
    p, v = STATE[name]
    pts = orbit_points(p - sp, v - sv, GMS + GM_DE[i])
    dp = []
    for q in pts:
        d = disp(q)
        r = np.linalg.norm(d)
        dp.append(d / r * ORRERY_S * math.sqrt(r))
    V, F = tube(dp, 0.12 if name in [a[0] for a in ASTEROIDS] else 0.2)
    write_obj(os.path.join(MESH, "orbit-%s.obj" % name.lower()), V, F, "%s's orbit at 2026-01-01, square-rooted" % name)

# Saturn's rings in its vitrine (its equator; distances square-rooted like the moons')
def annulus(r0, r1, pole, reach, n=180):
    zp = disp(pole)
    xp = np.cross(zp, [0, 1.0, 0])
    xp /= np.linalg.norm(xp)
    yp = np.cross(zp, xp)
    V, F = [], []
    s0, s1 = VITRINE_R * math.sqrt(r0 / reach), VITRINE_R * math.sqrt(r1 / reach)
    for k in range(n):
        th = 2 * math.pi * k / n
        d = math.cos(th) * xp + math.sin(th) * yp
        V.append(d * s0)
        V.append(d * s1)
    for k in range(n):
        a, b = 2 * k, 2 * ((k + 1) % n)
        for f in [(a, b, b + 1), (a, b + 1, a + 1)]:
            F.append(f)
            F.append((f[0], f[2], f[1]))       # both faces
    return V, F
KMAU = 1 / AU
for nm, r0, r1 in [("ring-c", 74658, 92000), ("ring-b", 92000, 117580), ("ring-a", 122170, 136775)]:
    V, F = annulus(r0 * KMAU, r1 * KMAU, POLES["Saturn"], REACH["Saturn"])
    write_obj(os.path.join(MESH, "saturn-%s.obj" % nm), V, F, "Saturn's %s ring, in its vitrine" % nm[-1].upper())

# a vitrine's hoop: a brass circle round it, level (in the ecliptic)
pts = [np.array([math.cos(2 * math.pi * k / 120), 0, math.sin(2 * math.pi * k / 120)]) * (VITRINE_R + 1.5) for k in range(120)]
V, F = tube(pts, 0.35)
write_obj(os.path.join(MESH, "hoop.obj"), V, F, "a vitrine's hoop")

# lettering: the date's digits, the vitrines' names
from PIL import Image, ImageDraw, ImageFont
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
def text_obj(text, path, height_cm, depth_cm, font, px=48, fixed_w=None, box=None):
    f = ImageFont.truetype(font, px)
    l, t, r, b = f.getbbox(text)
    if box:                 # a shared vertical box (the date's glyphs line up)
        t, b = box
    W, H = (fixed_w or (r - l)) + 4, b - t + 4
    if fixed_w:
        l = l - (fixed_w - (r - l)) // 2
    im = Image.new("L", (W, H), 0)
    ImageDraw.Draw(im).text((2 - l, 2 - t), text, font=f, fill=255)
    a = np.asarray(im) > 127
    s = height_cm / H
    open_, rects = {}, []
    for y in range(H + 1):
        runs = set()
        if y < H:
            row, x = a[y], 0
            while x < W:
                if row[x]:
                    x0 = x
                    while x < W and row[x]:
                        x += 1
                    runs.add((x0, x))
                else:
                    x += 1
        for k in list(open_):
            if k not in runs:
                rects.append((k[0], k[1], open_.pop(k), y))
        for k in runs:
            if k not in open_:
                open_[k] = y
    V, F = [], []
    for x0, x1, y0, y1 in rects:
        X0, X1 = x0 * s - W * s / 2, x1 * s - W * s / 2
        Y0, Y1 = (H - y1) * s, (H - y0) * s
        o = len(V)
        for z in (0, depth_cm):
            V.extend([(X0, Y0, z), (X1, Y0, z), (X1, Y1, z), (X0, Y1, z)])
        for q in [(4, 5, 6, 7), (0, 4, 7, 3), (1, 2, 6, 5), (3, 7, 6, 2), (0, 1, 5, 4)]:
            F.append((o + q[0], o + q[1], o + q[2]))
            F.append((o + q[0], o + q[2], o + q[3]))
    write_obj(path, V, F, "lettering: " + text)
    return W * s, H * s
# fixed-width digits, all the same box (the widest)
fm = ImageFont.truetype(MONO, 48)
dw = max(fm.getbbox(c)[2] - fm.getbbox(c)[0] for c in "0123456789-")
box = (min(fm.getbbox(c)[1] for c in "0123456789"), max(fm.getbbox(c)[3] for c in "0123456789"))
for c in "0123456789-":
    text_obj(c, os.path.join(MESH, "digit-%s.obj" % ("dash" if c == "-" else c)), 4.0, 0.4, MONO, fixed_w=dw, box=box)
for nm in ["THE EARTH & THE MOON", "MARS", "JUPITER", "SATURN", "URANUS", "NEPTUNE", "PLUTO & CHARON"]:
    key = nm.split()[1].lower() if nm.startswith("THE") else nm.split()[0].lower()
    text_obj(nm, os.path.join(MESH, "name-%s.obj" % key), 2.2, 0.3, SERIF)
print("meshes:", len(os.listdir(MESH)))
