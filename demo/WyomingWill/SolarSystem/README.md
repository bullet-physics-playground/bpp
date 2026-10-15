# The Solar System

The Sun, the eight planets, Pluto, five asteroids (Ceres, Pallas, Juno,
Vesta, Hygiea) and twenty-one moons, from 2026 January 1 on. They move as
gravity moves them, worked out here from where JPL had them that day.

| Part | What's there |
|---|---|
| the orrery | The Sun on its column, with the planets, Pluto and the asteroids on their orbits. Distances from the Sun are square-rooted (Mercury 11 cm, the Earth 18 cm, Neptune 99 cm, Pluto out to 126 cm) so that all of them fit. Their directions, and their heights above and below the ecliptic, are true. The bodies are drawn far bigger than they are. |
| the vitrines | Along the back, each planet with its moons: the Earth and the Moon, Mars (Phobos, Deimos), Jupiter (Io, Europa, Ganymede, Callisto), Saturn (Mimas to Iapetus, and the rings), Uranus (its moons going round it on its side), Neptune (Triton going round backwards), and Pluto and Charon going round each other. Distances from the planet are square-rooted too; directions are true. North, the ecliptic's, is up everywhere. |
| the date | above the vitrines |

Every body wears a map of its surface and turns as it really does: the Earth
once a day about its tilted axis, Venus slowly backwards, Uranus on its
side, Mercury three times in two of its years, and the Moon and nearly all
the moons once each time round, so that each keeps one face to its planet.
Rest the mouse on any of them to find out about it.

Time goes 5 days a second to start with. After 25 years (2051) it starts
again: JPL's DE421, which it's checked against, ends in 2053.

## Keys

| Key | Action |
|---|---|
| `1` `2` `3` `4` `5` | a quarter of a day, 1, 5, 25 or 100 days a second |
| `R` | back to 2026 January 1 |

Slider: days (a second). To watch them turn, slow down: at 5 days a second
the Earth turns five times a second, and Jupiter twelve, faster than the
60 frames a second can show (they seem to turn slowly, or backwards, as a
wagon wheel does in a film); at a quarter of a day a second (key `1`) the
Earth turns once every 4 seconds.

Resting the mouse on a body gives its name, its size, how long it takes to
turn and its day (noon to noon), its axis's tilt to its orbit, its
distances (and how long light takes from it to the Earth), and its year;
for a moon, its distance from its planet, how long it takes to go round,
and whether it keeps one face toward it. On the Sun, the date.

## The surfaces, and the turning

**Each body is turned by the IAU's model of its rotation** (the Working
Group on Cartographic Coordinates and Rotational Elements, 2015 report;
Mars and its moons from the 2009 one, as the engine has them): where its
north pole points, and how far round its prime meridian has turned, as
functions of the date, with their main periodic terms (the Moon's
librations, Neptune's and Triton's precession). They're in
`solar-rotation.lua`. The Sun's, the planets' and the Moon's are checked
against the hapsira library's transcription of the reports, the moons'
against NAIF's older planetary constants kernel (pck00008) where they
haven't changed since. Not checked against a second source: the values
revised since 2000 for Titan, Mimas, Enceladus, Tethys, Dione and Iapetus
(their prime meridians shifted by a few degrees), and Pluto's and
Charon's, turned the right-hand way up in 2015 (Pluto's pole agrees with
the one in `solar-data.lua`, from JPL).

**The maps** (`solar-meshes/tex-*.jpg`, made by `make-textures.py`) are
drawn, not photographs: each body's best-known markings put where they are
on it, in latitude and longitude, so the turning shows. The Earth's coasts
are Natural Earth's. The Moon has its seas on the side toward the Earth;
Mercury its Caloris basin; Mars its dark Syrtis Major, its polar caps and
Valles Marineris; Jupiter its belts and Great Red Spot; Saturn the
hexagon round its north pole; Pluto its heart and Charon its red north
pole; Iapetus its dark leading side. Some markings come and go, or drift,
and are an example: Jupiter's Red Spot (it drifts in longitude), the
clouds of Uranus and Neptune, the Sun's spots. Venus is shown as radar
sees its ground (the clouds go round in 4 days, the ground in 243). Titan
is shown as its haze. The asteroids are too small to show.

The console checks the turning against what's known:

* **The Earth**: at the start (2026-01-01 0h TDB) the Sun is overhead at
  23.01 S, 178.79 W, against 23.02 S, 178.87 W from the IERS's measured
  Earth (through Skyfield). The IAU's model is the simple one, within a
  tenth of a degree.
* **The Moon's face**: where on the Moon the Earth is overhead, over each
  year. It wanders 7.9° east and west and 6.8° north and south: the
  librations, which let us see 59% of the Moon over time. Theory: up to
  7.9° in longitude (from its orbit's eccentricity) and the tilt of its
  equator to its orbit, 1.5° + 5.0° to 5.3°, in latitude. This takes both
  the Moon's orbit (from the integration) and its turning (the IAU).
* **Mercury's 3:2**: it turns three times in two of its years, so at each
  perihelion the same two longitudes, 0° and 180° (its "hot poles"), face
  the Sun by turns. The console gives where the Sun is overhead at each
  perihelion: 0.0 to 0.2 from 0° or 180°.

## Physics

**The main integration** covers the Sun, the planets, the Moon, Pluto and
the asteroids. Mars, Jupiter, Saturn, Uranus, Neptune and Pluto enter as
their systems' barycentres; the Earth and the Moon are separate. Every one
pulls every other (Newton). On top of that:

* **Einstein's correction to the Sun's pull**, to first order (the
  Schwarzschild term): `GM / (c² r³) [(4GM/r − v²) r + 4 (r·v) v]`.
* **The Earth's flattening (J2) pulling on the Moon.**

It's stepped by Bulirsch–Stoer: Gragg's modified midpoint with 2, 4, 6, 8
and 10 substeps, extrapolated to none, which is tenth order. The step is
one day, in JPL's frame (the ICRF), in AU and days.

**The moon systems**: each moon's position from its planet is stepped by
Wisdom and Holman's mapping. Each moon follows its exact Kepler orbit about
its planet for half a step. Then everything else is given as one kick:
* the other moons, with the planet's own wobble;
* the planet's flattening, J2 and J4, about its pole (and for Mars,
  its out-of-roundness about its axis, C22 and S22, turning with it);
* the Sun's tide, with the Sun's position taken from the main integration.

Then each moon follows its Kepler orbit again. There are sixteen steps to
the innermost moon's orbit: Phobos's is 0.020 days, Mimas's 0.059. Each
system's own barycentre goes round in the main integration. (Prototyped
against a Bulirsch–Stoer reference: on Saturn's system, 3 km out on Mimas
after 20 days, less on the others.)

**The cost** is about one second of computing per simulated year. At the
usual 5 days a second that's under 2% of the time.

## What the console checks

Every January 1 the console prints these (each check is made with the
integration stopped exactly at its date, whatever the speed):

* **The planets against JPL's DE421 ephemeris**, from the Sun, and the
  Moon from the Earth, in km. DE421 is JPL's own integration fitted to
  radar, spacecraft and laser ranging; it is where everything starts, so
  any difference is this model's. Over ten years the planets stay within
  5 km and the Moon within 40 km (0.05″). The Moon's remaining
  error is the physics left out: the Moon's own figure, the tides, and the
  Earth's pole's precession.
* **A Mercury without Einstein**: a massless twin pulled only by Newton.
  It falls behind, 49 km in the first year and 1800 km in ten, which is
  8″ seen from the Sun. Not steadily, year by year (190, 494, 733, 624,
  404, 286, 531 and 1107 km in between): its orbit is what differs, and
  how far apart that puts the two Mercurys depends on where in its orbit
  Mercury is that January 1. Without the correction, the planets wouldn't
  match JPL's.
* **Mercury's perihelion turned by Einstein**, from a separate run of
  Mercury alone about the Sun. The orbit's Laplace–Runge–Lenz vector is
  averaged over each whole orbit, perihelion to perihelion, to remove the
  wobble within an orbit. Against 6πGM/(c²a(1−e²)) per orbit: **42.981″
  a century, against 42.981″**.
* **The energy and angular momentum** (Newton's) are steady to about 1e-9
  and 3e-10.
* **Laplace's resonance.** Io, Europa and Ganymede's mean longitudes keep
  L_I − 3 L_E + 2 L_G at 180°. Over the years its 20-day means stay
  between 179.7° and 180.3°. The real free libration about 180° is only
  0.07°, and the rest is the moons' other slow wobbles. (Started instead
  from Lainey's L1.2 theory, the angle swings 1.5° about 180°, with a
  period measured at 2039 days, against the theory's 2070.)
* **Neptune and Pluto**: how close they've come, and Pluto's year in
  Neptune's (1.50: the 3:2 resonance). Their orbits cross, but the
  resonance keeps them more than 17 AU apart. That is a fact of the
  millennia, not something the 25 years here can show.
* **The moons and asteroids against JPL Horizons**, monthly for five
  years, in km. They start within 1 or 2 km and stay close: after five
  years, Titan, Rhea, Dione, Iapetus, Io, Triton, Umbriel and Charon are
  within 20–210 km. Some go further, for reasons that are physics left
  out:
  * **Phobos**: 950 km a year (a part in 1e5 of its pace). Mars isn't
    round about its axis either: its C22 and S22 terms, turning with
    Mars, are in, and they took Phobos's drift down from 3,200 km a year
    (Deimos's from 330 to 50). The rest is Mars's finer lumps, which
    aren't modelled.
  * **Titania and Miranda**: 900 and 400 km a year. Neither Uranus's
    J2 nor the moons' older masses fix it (2014's masses are used).
  * **Mimas**: 575 km in a year and 2,800 in five, wavering by a hundred
    or two from month to month. Its 2:1 resonance with Tethys swings it
    back and forth over 70 years, and a small difference in that swing
    grows slowly over five.
  * **The asteroids**: Ceres 2,000 km in five years, about 1″ seen from
    the Sun. Horizons' asteroid orbits include another eleven big asteroids'
    pulls, and the Sun's barycentric motion of DE441 rather than DE421.

From a run at 100 days a second (the checks' figures are the same at any
speed: each check stops the integration at its date; the Laplace, Moon's
face and perihelion lines are taken frame by frame and change a little):

    2027-01-01  against JPL's DE421, km off, from the Sun: Mercury 0, Venus 0, Earth 0, Mars 0, Jupiter 0, Saturn 0, Uranus 0, Neptune 0, Pluto 0;
                the Moon, from the Earth: 4 km
                a Mercury without Einstein's correction: 49 km off
                energy steady to 4.4e-10, angular momentum to 9.4e-11 (Newton's; Einstein's correction is a few parts in 1e8)
                Mercury's perihelion turned by Einstein: 42.981" a century, over 3 orbits (theory, 6 pi G M / (c^2 a (1 - e^2)) an orbit: 42.981")
                Io, Europa, Ganymede: L_I - 3 L_E + 2 L_G (their mean longitudes) averaged 180.08 degrees over the year,
                  spread 0.18 (Laplace's resonance holds it at 180)
                  its 20-day means so far: 179.77 to 180.30 (Io's free libration about 180 is 0.07 degrees; the rest is
                  the moons' other slow wobbles)
                Neptune and Pluto: closest so far 32.04 AU; Pluto's year now 1.498 of Neptune's (their orbits cross,
                  but the 3:2 resonance keeps them over 17 AU apart)
                the Moon's face: the Earth overhead at 7.9 W to 7.6 E, 6.8 S to 6.9 N on it
                  (the librations, which let us see 59% of it: up to 7.9 degrees east and west, and 6.7 to 6.8
                  north and south, the tilt of its equator to its orbit)
                Mercury at perihelion, the Sun overhead at longitude 0.2, 179.9, 0.0, -179.9
                  (it turns 3 times in 2 of its years: at each perihelion one of its two hot poles, at 0 or 180, faces the Sun)
    ...
    2036-01-01  ... Mercury 1, Venus 0, Earth 1, Mars 1, Jupiter 5, Saturn 1, Uranus 0, Neptune 0, Pluto 0;
                the Moon, from the Earth: 39 km
                a Mercury without Einstein's correction: 1813 km off

and against Horizons, a month, a year and five years in:

    2026-02-01  against Horizons, km off: Phobos 83, Deimos 4, Io 5, Europa 11, Ganymede 19, Callisto 17, Mimas 41, Enceladus 6, Tethys 8, Dione 1, Rhea 1, Titan 0, Iapetus 1, Miranda 34, Ariel 6, Umbriel 9, Titania 102, Oberon 10, Triton 3, Charon 4, Ceres 1, Pallas 1, Juno 1, Vesta 2, Hygiea 0
    2027-01-01  against Horizons, km off: Phobos 986, Deimos 50, Io 52, Europa 199, Ganymede 213, Callisto 182, Mimas 575, Enceladus 77, Tethys 90, Dione 10, Rhea 4, Titan 31, Iapetus 11, Miranda 404, Ariel 71, Umbriel 14, Titania 858, Oberon 149, Triton 22, Charon 42, Ceres 218, Pallas 135, Juno 74, Vesta 177, Hygiea 52
    2031-01-01  against Horizons, km off: Phobos 4771, Deimos 247, Io 63, Europa 361, Ganymede 1160, Callisto 897, Mimas 2794, Enceladus 276, Tethys 442, Dione 36, Rhea 22, Titan 90, Iapetus 33, Miranda 2060, Ariel 392, Umbriel 83, Titania 4502, Oberon 937, Triton 108, Charon 209, Ceres 2010, Pallas 840, Juno 660, Vesta 538, Hygiea 604

## Where it starts: the data

`solar-data.lua` is made by `make-data.py` (Python, with NumPy, jplephem
and Pillow) and holds the starting positions and velocities, the masses,
the flattenings and poles, and the checkpoints:

* **The Sun, the planets, the Moon and Pluto: JPL's DE421**, and its
  masses. DE421 comes in the skyfield-data package
  (`pip install jplephem skyfield-data`).
* **The moons and asteroids: JPL Horizons**, fetched by
  `fetch-horizons.sh` into `horizons/` (in the repository). If those files
  are missing, Jupiter's four moons start from Lainey's L1.2 theory (from
  the astronomy-engine package), and the others on stand-in orbits of the
  right size and shape but at made-up places round them; the console says
  so. To fetch them again:

      cd demo/WyomingWill/SolarSystem
      sh fetch-horizons.sh
      python3 make-data.py

  `make-data.py` also makes the meshes in `solar-meshes/`: the orbits, as
  they are at the start, square-rooted as the orrery draws them; Saturn's
  rings; the vitrines' hoops; the date's digits; and the names.

The moons' masses are from JPL's satellite solutions; the planets' J2, J4,
radii and poles from the IAU and the same. Each moon system's total mass
is DE440's, which JPL's moon solutions (and so Horizons) go with, rather
than DE421's. The main integration keeps DE421's, since its planets start
from DE421. Pluto's is the mass Horizons' Charon orbit implies, 975.43
km³/s² (DE440: 975.5). DE421's 977.0 takes Charon 20,000 km off in a year.

## Files

* `solar-system.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `solar-engine.lua`: the integrations.
* `solar-rotation.lua`: how each body turns (the IAU's models).
* `solar-data.lua`, `solar-meshes/`: made by `make-data.py`, except the
  maps, `solar-meshes/tex-*.jpg`, made by `make-textures.py` (NumPy,
  Pillow; it fetches Natural Earth's `ne_110m_land.geojson` from GitHub
  if it isn't beside it).
* `fetch-horizons.sh`: the Horizons data.

Headless testing: `SS_RATE` (days a second), `SS_YEARS` (years before it
starts again; at most 25).
