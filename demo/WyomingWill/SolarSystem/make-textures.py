#!/usr/bin/env python3
"""
The surface maps the Sun, the planets, Pluto and the moons wear in the solar
system exhibit: solar-meshes/tex-<name>.jpg, each a map of the whole globe
(longitude -180 to 180 east, left to right; latitude 90 to -90, top to
bottom), as bpp wraps an image round a sphere.

They're drawn here, not photographs: each body's best-known markings, where
they are on it (planetocentric latitude, east longitude, from the maps of the
IAU's and NASA's planetary nomenclature), so that as it turns, the turning
can be seen, and which face it shows. The Earth's coasts are Natural
Earth's (public domain), from ne_110m_land.geojson, fetched from its GitHub
repository if it isn't next to this script.

Some markings move about on the real body, and are put down here as
an example: Jupiter's Great Red Spot (it drifts in longitude), Uranus's and
Neptune's clouds. Venus is shown as radar sees its ground under the clouds
(the clouds go round in 4 days, the ground in 243). Titan is its haze.

Usage: python3 make-textures.py      (Pillow, NumPy)
"""

import json
import math
import os
import urllib.request

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "solar-meshes")


class Map:
    def __init__(self, w, seed):
        self.W, self.H = w, w // 2
        lon = (np.arange(self.W) + 0.5) / self.W * 360 - 180
        lat = 90 - (np.arange(self.H) + 0.5) / self.H * 180
        self.LON, self.LAT = np.meshgrid(lon, lat)
        self.la, self.lo = np.radians(self.LAT), np.radians(self.LON)
        self.x = np.cos(self.la) * np.cos(self.lo)
        self.y = np.cos(self.la) * np.sin(self.lo)
        self.z = np.sin(self.la)
        self.img = np.zeros((self.H, self.W, 3))
        self.rng = np.random.default_rng(seed)

    # smooth noise on the sphere: random values on a 3-D grid, interpolated
    # at each point of the globe, several sizes summed (no seam, no pinch at
    # the poles)
    def noise(self, freq=4, octaves=4, falloff=0.5):
        tot = np.zeros_like(self.x)
        amp, f, norm = 1.0, freq, 0.0
        for _ in range(octaves):
            g = int(f) + 2
            grid = self.rng.random((g, g, g))
            px, py, pz = [(c + 1) / 2 * f for c in (self.x, self.y, self.z)]
            ix, iy, iz = [np.floor(p).astype(int) for p in (px, py, pz)]
            fx, fy, fz = [p - np.floor(p) for p in (px, py, pz)]
            fx, fy, fz = [t * t * (3 - 2 * t) for t in (fx, fy, fz)]
            v = 0
            for dx in (0, 1):
                for dy in (0, 1):
                    for dz in (0, 1):
                        w = (fx if dx else 1 - fx) * (fy if dy else 1 - fy) * (fz if dz else 1 - fz)
                        v = v + w * grid[ix + dx, iy + dy, iz + dz]
            tot += amp * v
            norm += amp
            amp *= falloff
            f *= 2
        return tot / norm                     # about 0..1, mean 0.5

    def angdist(self, lat, lon):
        la0, lo0 = math.radians(lat), math.radians(lon)
        c = np.sin(self.la) * math.sin(la0) + np.cos(self.la) * math.cos(la0) * np.cos(self.lo - lo0)
        return np.degrees(np.arccos(np.clip(c, -1, 1)))

    # an ellipse a degrees east-west, b north-south (half-widths), turned rot
    # degrees: 0 at its middle, 1 at its edge (far side: large)
    def ellipse(self, lat, lon, a, b=None, rot=0):
        b = a if b is None else b
        a, b = min(a, 89), min(b, 89)          # (half-widths up to a quarter of the way round)
        la0, lo0 = math.radians(lat), math.radians(lon)
        dl = self.lo - lo0
        cosc = np.sin(la0) * np.sin(self.la) + math.cos(la0) * np.cos(self.la) * np.cos(dl)
        ex = np.cos(self.la) * np.sin(dl)
        ny = math.cos(la0) * np.sin(self.la) - math.sin(la0) * np.cos(self.la) * np.cos(dl)
        r = math.radians(rot)
        u, v = ex * math.cos(r) + ny * math.sin(r), -ex * math.sin(r) + ny * math.cos(r)
        d = np.sqrt((u / math.sin(math.radians(a))) ** 2 + (v / math.sin(math.radians(b))) ** 2)
        return np.where(cosc > 0, d, 99)

    @staticmethod
    def soft(d, edge=0.25):
        t = np.clip((1 - d) / edge, 0, 1)
        return t * t * (3 - 2 * t)

    def paint(self, w, col, alpha=1.0):
        w = np.clip(w * alpha, 0, 1)[..., None]
        self.img = self.img * (1 - w) + np.array(col, float)[None, None, :] * w

    def fill(self, col):
        self.img[:] = col

    def shade(self, f):                      # multiply by f (array or number)
        self.img = self.img * (f[..., None] if hasattr(f, "shape") else f)

    def spot(self, lat, lon, a, col, b=None, rot=0, edge=0.25, alpha=1.0):
        self.paint(self.soft(self.ellipse(lat, lon, a, b, rot), edge), col, alpha)

    def band(self, lat0, lat1, col, edge=1.5, alpha=1.0, wobble=None):
        L = self.LAT if wobble is None else self.LAT + wobble
        w = np.clip((L - lat0) / edge, 0, 1) * np.clip((lat1 - L) / edge, 0, 1)
        self.paint(w, col, alpha)

    def craters(self, n, rmin, rmax, dark=0.85, rim=1.12, seed_lat=None):
        for _ in range(n):
            lat = math.degrees(math.asin(self.rng.uniform(-1, 1)))
            lon = self.rng.uniform(-180, 180)
            r = rmin * (rmax / rmin) ** self.rng.random() ** 2
            d = self.ellipse(lat, lon, r)
            floor = self.soft(d, 0.3)
            ring = np.clip(1 - np.abs(d - 1.05) / 0.12, 0, 1)
            self.shade(1 - (1 - dark) * floor)
            self.shade(1 + (rim - 1) * ring)

    def ring(self, lat, lon, r, col, width=0.15, alpha=1.0):
        d = self.ellipse(lat, lon, r)
        self.paint(np.clip(1 - np.abs(d - 1) / width, 0, 1), col, alpha)

    def save(self, name):
        img = np.clip(self.img, 0, 255).astype(np.uint8)
        Image.fromarray(img).save(os.path.join(OUT, "tex-" + name + ".jpg"), quality=88)
        print("tex-" + name + ".jpg")


def mix(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


# ---------------------------------------------------------------------------
# the Sun: granulation, a few sunspot groups in the two bands either side of
# its equator where they come (latitudes 10-30)
# ---------------------------------------------------------------------------
def sun():
    m = Map(1024, 1)
    m.fill((255, 205, 95))
    m.shade(0.9 + 0.2 * m.noise(24, 3))
    for lat, lon, n in ((14, -120, 3), (22, -40, 2), (-17, 30, 3), (-11, 140, 2), (26, 95, 1)):
        for k in range(n):
            la, lo = lat + m.rng.normal(0, 1.5), lon + 6 * k + m.rng.normal(0, 1)
            r = m.rng.uniform(1.2, 2.6)
            m.spot(la, lo, r * 2.0, (205, 120, 40), edge=0.4)      # penumbra
            m.spot(la, lo, r, (70, 30, 10), edge=0.3)              # umbra
    m.save("sun")


def mercury():
    m = Map(1024, 2)
    m.fill((150, 140, 128))
    m.shade(0.85 + 0.3 * m.noise(6, 4))
    m.craters(260, 0.8, 7)
    m.spot(30.5, 170.2, 18, (176, 163, 140), edge=0.3)            # Caloris basin's plains
    m.ring(30.5, 170.2, 20, (190, 180, 165), 0.08, 0.7)
    for lat, lon, r in ((-58.4, -21.9, 3), (-19.6, -84.2, 4), (8, -76, 2.5)):   # bright young craters (Kuiper among them)
        m.spot(lat, lon, r, (225, 220, 210), edge=0.6)
    m.save("mercury")


# Venus's ground, as radar sees it under the clouds
def venus():
    m = Map(1024, 3)
    m.fill((150, 95, 45))
    m.shade(0.8 + 0.4 * m.noise(5, 5))
    hi = (215, 165, 95)
    m.spot(70, 10, 38, hi, b=9, edge=0.5)                 # Ishtar Terra
    m.spot(65.2, 3.3, 6, (240, 205, 140), edge=0.5)       # Maxwell Montes
    m.spot(-5, 105, 50, hi, b=9, rot=-5, edge=0.5)        # Aphrodite Terra
    m.spot(25.3, -77.2, 9, hi, b=12, edge=0.5)            # Beta Regio (282.8 E)
    m.spot(-22, 4.5, 7, hi, edge=0.5)                     # Alpha Regio
    m.spot(9, -160, 10, hi, edge=0.5)                     # Atla Regio (200 E)
    m.spot(-60, 20, 25, hi, b=8, edge=0.5, alpha=0.7)     # Lada Terra
    m.craters(40, 0.5, 2, dark=0.9, rim=1.15)
    m.save("venus")


def earth():
    m = Map(2048, 4)
    m.fill((22, 62, 130))
    m.shade(0.85 + 0.25 * m.noise(4, 3))
    path = os.path.join(HERE, "ne_110m_land.geojson")
    if not os.path.exists(path):
        url = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson"
        urllib.request.urlretrieve(url, path)
    land = Image.new("L", (m.W, m.H), 0)
    dr = ImageDraw.Draw(land)
    with open(path) as f:
        gj = json.load(f)
    for feat in gj["features"]:
        g = feat["geometry"]
        polys = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        for poly in polys:
            ring = [((lon + 180) / 360 * m.W, (90 - lat) / 180 * m.H) for lon, lat in poly[0]]
            dr.polygon(ring, fill=255)
            for hole in poly[1:]:
                dr.polygon([((lon + 180) / 360 * m.W, (90 - lat) / 180 * m.H) for lon, lat in hole], fill=0)
    L = np.asarray(land, float) / 255
    # the land's colour: green, browner where it's dry, darker in the north's forests
    n = m.noise(8, 4)
    green = np.stack([60 + 30 * n, 105 + 30 * n, 50 + 15 * n], -1)
    landc = green
    dry = np.zeros_like(n)
    for lat, lon, a, b in ((22, 12, 26, 9), (23, 47, 9, 9), (-24, 133, 15, 8), (43, 103, 14, 5), (-23, 21, 6, 6),
                           (34, -112, 6, 4), (32, 58, 9, 5), (27, 71, 4, 3), (-45, -69, 4, 7), (40, 64, 8, 4),
                           (-22, -69, 3, 8)):
        dry = np.maximum(dry, m.soft(m.ellipse(lat, lon, a, b), 0.6))
    sand = np.stack([196 + 25 * n, 165 + 25 * n, 112 + 20 * n], -1)
    landc = landc * (1 - dry[..., None]) + sand * dry[..., None]
    boreal = np.clip((np.abs(m.LAT) - 50) / 8, 0, 1) * (m.LAT > 0)
    landc = landc * (1 - 0.35 * boreal[..., None])
    tundra = np.clip((m.LAT - 64) / 6, 0, 1)
    landc = landc * (1 - tundra[..., None]) + np.array([120, 120, 100])[None, None, :] * tundra[..., None]
    m.img = m.img * (1 - L[..., None]) + landc * L[..., None]
    # ice: Antarctica, Greenland, the Arctic Ocean's pack
    ice = (m.LAT < -62) * L + m.soft(m.ellipse(73, -41, 13, 11), 0.4) * L + np.clip((m.LAT - 79) / 3, 0, 1)
    m.paint(np.clip(ice, 0, 1), (236, 240, 244))
    m.save("earth")


def moon():
    m = Map(2048, 5)
    m.fill((185, 182, 175))
    m.shade(0.88 + 0.22 * m.noise(8, 4))
    mare = (88, 86, 82)
    # the seas (lat, east lon, half-widths in degrees)
    for lat, lon, a, b, rot in ((18, -57, 22, 28, 15), (32.8, -15.6, 18, 17, 0), (28, 17.5, 10, 10, 0),
                                (8.5, 31.4, 12, 10, 0), (17, 59.1, 8, 7, 0), (-7.8, 51.3, 8, 10, 0),
                                (-15.2, 35.5, 5, 5, 0), (-21.3, -16.6, 11, 9, 0), (-24.4, -38.6, 6, 6, 0),
                                (56, 1.4, 38, 5, 0), (13.3, 3.6, 4, 4, 0), (7.5, -30.9, 7, 6, 0),
                                (-10, -23, 6, 6, 0), (-35, -10, 4, 3, 0), (27.3, 147.9, 4, 4, 0),
                                (-19, 92, 5, 5, 0), (-33, 163, 4, 3, 0), (14, 86, 4, 3, 0)):
        m.spot(lat, lon, a, mare, b=b, rot=rot, edge=0.35)
    m.spot(-53, -169, 40, (150, 148, 142), edge=0.5, alpha=0.5)    # the South Pole-Aitken basin, far side
    m.craters(300, 0.4, 5, dark=0.9, rim=1.1)
    for lat, lon, r in ((-43.3, -11.2, 1.8), (9.6, -20.1, 1.6), (8.1, -38, 1.0), (23.7, -47.4, 1.0)):   # Tycho, Copernicus, Kepler, Aristarchus
        m.spot(lat, lon, r * 4, (230, 228, 222), edge=0.9, alpha=0.6)
        m.spot(lat, lon, r, (245, 243, 238), edge=0.4)
    m.save("moon")


def mars():
    m = Map(1024, 6)
    m.fill((190, 105, 60))
    m.shade(0.85 + 0.3 * m.noise(6, 5))
    dark = (95, 60, 42)
    for lat, lon, a, b, rot, al in ((8.4, 69.5, 9, 14, 10, 0.9), (46.7, -22, 20, 11, 0, 0.8), (-25, -40, 25, 9, 0, 0.8),
                                    (-2, 0, 11, 4, 0, 0.8), (-20, 105, 22, 8, 0, 0.8), (-25, 145, 24, 7, 0, 0.8),
                                    (-30, -155, 24, 7, 0, 0.75), (45, 110, 18, 10, 0, 0.4), (-15, 25, 12, 6, 0, 0.7),
                                    (-5, -170, 8, 5, 0, 0.5)):
        m.spot(lat, lon, a, dark, b=b, rot=rot, edge=0.6, alpha=al)
    m.spot(-42.4, 70.5, 12, (215, 160, 115), edge=0.4)          # Hellas
    m.spot(-49.7, -42.8, 7, (210, 150, 105), edge=0.4)          # Argyre
    m.spot(0, -110, 30, (200, 115, 65), b=20, edge=0.6, alpha=0.6)   # Tharsis
    for lat, lon, r in ((18.65, -134, 4), (14.6, -101, 1.5), (1.5, -112.6, 1.5), (-8.3, -120.2, 1.5)):   # Olympus Mons, the Tharsis volcanoes
        m.ring(lat, lon, r, (120, 70, 45), 0.25, 0.8)
    for k in range(40):                                          # Valles Marineris, a dark scar
        lon = -100 + 60 * k / 39
        m.spot(-8 - 4 * math.sin(math.radians((lon + 100) * 3)), lon, 1.6, (90, 52, 38), edge=0.5, alpha=0.7)
    m.paint(np.clip((m.LAT - 80) / 2, 0, 1), (245, 245, 240))    # the north polar cap
    m.spot(-87, -40, 5, (245, 245, 240), edge=0.4)               # the south one, off the pole
    m.save("mars")


def jupiter():
    m = Map(2048, 7)
    w = 1.2 * (m.noise(12, 4) - 0.5)
    m.fill((222, 205, 175))
    zone, belt, dbelt, polar = (232, 220, 195), (175, 120, 85), (150, 98, 70), (150, 140, 130)
    for lat0, lat1, col in ((60, 90, polar), (-90, -60, polar), (36, 41, belt), (24, 31, dbelt), (7, 18, dbelt),
                            (-7, 7, zone), (-20, -7, dbelt), (-33, -26, belt), (-44, -40, belt), (44, 50, belt)):
        m.band(lat0, lat1, col, edge=2.0, wobble=3 * w)
    m.paint(np.clip((np.abs(m.LAT) - 45) / 15, 0, 1), polar, 0.7)
    m.shade(0.92 + 0.16 * m.noise(30, 3))
    m.spot(-22, -60, 13, (230, 215, 190), b=7.5, edge=0.3)      # the Red Spot's hollow
    m.spot(-22, -60, 10, (195, 95, 60), b=5.5, edge=0.35)       # the Great Red Spot (its longitude drifts: put here)
    m.spot(-33, 20, 3.5, (240, 235, 225), b=2.5, edge=0.4)      # Oval BA
    for k in range(9):
        m.spot(-41, -170 + 40 * k, 1.6, (245, 240, 230), edge=0.5)    # the white ovals of the south
    m.save("jupiter")


def saturn():
    m = Map(2048, 8)
    w = 0.8 * (m.noise(10, 3) - 0.5)
    m.fill((228, 207, 150))
    for lat0, lat1, col, al in ((-12, 12, (240, 225, 180), 1), (12, 22, (205, 170, 110), 0.8), (-22, -12, (205, 170, 110), 0.8),
                                (30, 40, (210, 180, 125), 0.6), (-40, -30, (210, 180, 125), 0.6),
                                (55, 90, (170, 160, 135), 0.8), (-90, -55, (175, 165, 140), 0.7)):
        m.band(lat0, lat1, col, edge=3, alpha=al, wobble=2 * w)
    m.shade(0.94 + 0.12 * m.noise(24, 3))
    # the hexagon round the north pole, at 78 degrees north (it turns with the planet)
    hexlat = 78 + 2.5 * np.cos(np.radians(6 * m.LON)) ** 2 - 1.2
    m.paint(np.clip((m.LAT - hexlat) / 0.8, 0, 1), (120, 135, 140))
    m.save("saturn")


def uranus():
    m = Map(1024, 9)
    m.fill((165, 220, 228))
    for lat0, lat1, al in ((-30, -10, 0.15), (10, 30, 0.12), (40, 60, 0.15)):
        m.band(lat0, lat1, (135, 195, 205), edge=6, alpha=al)
    m.paint(np.clip((np.abs(m.LAT) - 55) / 15, 0, 1), (200, 238, 240), 0.6)    # its brighter polar hoods
    for lat, lon in ((32, -40), (28, 100), (-28, 170)):           # a few bright clouds, as an example
        m.spot(lat, lon, 4, (240, 252, 252), b=2, edge=0.6)
    m.save("uranus")


def neptune():
    m = Map(1024, 10)
    m.fill((70, 105, 215))
    m.shade(0.9 + 0.2 * m.noise(6, 3))
    for lat0, lat1, al in ((-50, -40, 0.4), (20, 30, 0.25), (-75, -65, 0.3)):
        m.band(lat0, lat1, (50, 75, 170), edge=4, alpha=al)
    m.spot(-20, 60, 10, (35, 50, 140), b=6, edge=0.4)            # a dark spot, as an example (Voyager's has gone)
    m.spot(-26, 66, 5, (235, 240, 255), b=1.5, edge=0.6)         # its bright companion clouds
    for lat, lon in ((-42, -100), (27, -20), (-71, 150)):
        m.spot(lat, lon, 4, (225, 235, 255), b=1.2, edge=0.6, alpha=0.9)
    m.save("neptune")


def pluto():
    m = Map(1024, 11)
    m.fill((190, 160, 125))
    m.shade(0.85 + 0.3 * m.noise(6, 4))
    m.spot(25, 176, 17, (240, 236, 225), b=24, rot=10, edge=0.3)          # Sputnik Planitia, the heart's left lobe
    m.spot(10, -150, 20, (225, 215, 200), b=20, edge=0.5)                  # the heart's right lobe (210 E)
    m.spot(-15, 95, 55, (85, 45, 35), b=12, rot=-5, edge=0.4)              # Cthulhu Macula
    m.spot(-18, -110, 25, (110, 65, 50), b=8, edge=0.6, alpha=0.7)         # the dark band's other maculae
    m.paint(np.clip((m.LAT - 60) / 15, 0, 1), (175, 165, 150), 0.7)       # the grey north
    m.save("pluto")


def charon():
    m = Map(512, 12)
    m.fill((165, 160, 155))
    m.shade(0.85 + 0.3 * m.noise(6, 4))
    m.craters(40, 1, 5)
    m.paint(np.clip((m.LAT - 62) / 10, 0, 1), (115, 65, 50))             # Mordor Macula, the red north
    m.save("charon")


def simple(name, base, seed, n=60, rmax=6, w=512, extra=None, var=0.25):
    m = Map(w, seed)
    m.fill(base)
    m.shade(1 - var / 2 + var * m.noise(6, 4))
    if n:
        m.craters(n, 0.8, rmax)
    if extra:
        extra(m)
    m.save(name)


def moons():
    # Mars's
    simple("phobos", (110, 100, 92), 20, 30, 6, extra=lambda m: (m.spot(-1, -49, 23, (80, 72, 66), edge=0.2),
                                                                 m.ring(-1, -49, 23, (140, 130, 120), 0.12)))   # Stickney
    simple("deimos", (140, 130, 120), 21, 15, 4)
    # Jupiter's
    def io(m):
        for _ in range(40):
            lat, lon = math.degrees(math.asin(m.rng.uniform(-0.9, 0.9))), m.rng.uniform(-180, 180)
            m.spot(lat, lon, m.rng.uniform(1, 4), [(60, 40, 25), (230, 120, 50), (250, 250, 230)][m.rng.integers(3)], edge=0.6)
        m.ring(-18.7, 104.7, 9, (205, 95, 45), 0.25)                       # Pele's red ring
        m.spot(13, 51, 3, (40, 30, 20), edge=0.4)                          # Loki
        m.paint(np.clip((np.abs(m.LAT) - 50) / 20, 0, 1), (150, 110, 70), 0.6)
    simple("io", (230, 210, 110), 22, 0, extra=io)
    def europa(m):
        for _ in range(45):                                                # lineae: dark great-circle cracks
            lat, lon = m.rng.uniform(-60, 60), m.rng.uniform(-180, 180)
            m.spot(lat, lon, m.rng.uniform(15, 50), (150, 110, 80), b=0.5, rot=m.rng.uniform(0, 180), edge=0.8, alpha=0.5)
        m.spot(0, 90, 80, (190, 160, 130), edge=0.8, alpha=0.4)           # the darker trailing side (centred on 270 W)
    simple("europa", (232, 225, 210), 23, 5, 2, extra=europa)
    def ganymede(m):
        m.spot(35, -145, 30, (90, 80, 68), b=22, edge=0.4)                 # Galileo Regio (145 W)
        m.spot(-10, 160, 35, (95, 85, 72), b=20, edge=0.4)                 # Marius Regio (200 W)
        m.spot(-30, 60, 25, (105, 95, 82), b=15, edge=0.5)                 # Nicholson Regio
        m.paint(np.clip((np.abs(m.LAT) - 45) / 15, 0, 1), (225, 225, 225), 0.7)   # frosty poles
    simple("ganymede", (165, 155, 140), 24, 50, 3, extra=ganymede)
    def callisto(m):
        for k in range(6):
            m.ring(14.7, -56, 3 + 5 * k, (160, 150, 135), 0.06, 0.6)        # Valhalla's rings (56 W)
        m.spot(14.7, -56, 4, (190, 182, 170), edge=0.5)
        for _ in range(120):
            lat, lon = math.degrees(math.asin(m.rng.uniform(-1, 1))), m.rng.uniform(-180, 180)
            m.spot(lat, lon, m.rng.uniform(0.3, 1.2), (200, 195, 185), edge=0.6)
    simple("callisto", (90, 80, 70), 25, 60, 3, extra=callisto)
    # Saturn's
    simple("mimas", (190, 186, 180), 30, 80, 6, extra=lambda m: (m.spot(-1.7, -111.8, 20, (150, 146, 140), edge=0.25),
                                                                 m.ring(-1.7, -111.8, 20, (215, 212, 205), 0.12),
                                                                 m.spot(-1.7, -111.8, 2.5, (210, 207, 200), edge=0.5)))   # Herschel
    def enceladus(m):
        for k in range(4):                                                 # the tiger stripes, round the south pole
            m.spot(-82, -150 + 25 * k, 1.0, (120, 160, 185), b=18, rot=60, edge=0.7)
    simple("enceladus", (242, 244, 245), 31, 20, 3, extra=enceladus, var=0.1)
    simple("tethys", (225, 222, 216), 32, 50, 4, extra=lambda m: (m.spot(32.8, -128.9, 24, (195, 192, 186), edge=0.25),
                                                                   m.ring(32.8, -128.9, 24, (235, 233, 228), 0.1),
                                                                   m.spot(0, 0, 70, (160, 150, 140), b=2.5, rot=80, edge=0.6, alpha=0.5)))  # Odysseus, Ithaca Chasma
    def wispy(m):
        m.spot(0, 90, 75, (150, 145, 135), edge=0.8, alpha=0.6)            # the darker trailing side
        for _ in range(14):
            m.spot(m.rng.uniform(-50, 50), 90 + m.rng.uniform(-60, 60), m.rng.uniform(8, 25), (235, 235, 232),
                   b=0.6, rot=m.rng.uniform(0, 180), edge=0.8, alpha=0.8)  # its bright wisps
    simple("dione", (205, 200, 192), 33, 50, 4, extra=wispy)
    simple("rhea", (205, 198, 188), 34, 90, 4, extra=wispy)
    def titan(m):
        m.band(-90, 90, (215, 160, 80), edge=5)
        m.paint(np.clip((m.LAT - 55) / 20, 0, 1), (175, 130, 75), 0.6)      # its darker north polar hood
    simple("titan", (220, 165, 85), 35, 0, extra=titan, var=0.06)
    def iapetus(m):
        m.spot(0, -90, 75, (55, 42, 32), b=60, edge=0.35)                    # Cassini Regio, the dark leading side (90 W)
        m.band(-1, 1, (90, 85, 80), edge=1.0, alpha=0.4)                     # the ridge along the equator
    simple("iapetus", (225, 220, 210), 36, 40, 5, extra=iapetus)
    # Uranus's
    def miranda(m):
        for lat, lon, r in ((-66.9, -34.3, 18), (-29, 73, 22), (-24.8, -103, 22)):   # Inverness, Arden, Elsinore coronae
            for k in range(4):
                m.ring(lat, lon, r * (0.4 + 0.2 * k), (95, 92, 88), 0.1, 0.7)
    simple("miranda", (170, 166, 160), 40, 40, 3, extra=miranda)
    simple("ariel", (165, 160, 152), 41, 60, 3)
    simple("umbriel", (90, 87, 83), 42, 60, 4, extra=lambda m: m.ring(-7.9, -86.4, 4, (215, 210, 200), 0.3))   # Wunda's bright ring
    simple("titania", (150, 143, 135), 43, 60, 4, extra=lambda m: m.spot(-28, 20, 60, (100, 95, 90), b=1.0, rot=20, edge=0.7, alpha=0.6))   # Messina Chasmata
    simple("oberon", (128, 120, 112), 44, 80, 4, extra=lambda m: m.spot(-46, 44, 5, (70, 65, 60), edge=0.4))   # Hamlet's dark floor
    # Neptune's
    def triton(m):
        m.paint(np.clip((-m.LAT - 10) / 15, 0, 1), (240, 215, 205), 0.9)     # the pinkish south polar cap
        for _ in range(25):
            m.spot(m.rng.uniform(-60, -20), m.rng.uniform(-180, 180), m.rng.uniform(0.5, 1.5), (90, 70, 65),
                   b=3, rot=m.rng.uniform(40, 60), edge=0.6, alpha=0.8)        # its dark streaks
    simple("triton", (200, 185, 170), 45, 10, 2, extra=triton)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    sun(); mercury(); venus(); earth(); moon(); mars(); jupiter(); saturn(); uranus(); neptune(); pluto(); charon(); moons()
