# The Solar System

The Sun, the eight planets, Pluto, five asteroids (Ceres, Pallas, Juno,
Vesta, Hygiea) and twenty-one moons, from 2026 January 1 on. They move as
gravity moves them, worked out here from where JPL had them that day.

| Part | What's there |
|---|---|
| the orrery | The Sun on its column, with the planets, Pluto and the asteroids on their orbits. Distances from the Sun are square-rooted (Mercury 11 cm, the Earth 18 cm, Neptune 99 cm, Pluto out to 126 cm) so that all of them fit. Their directions, and their heights above and below the ecliptic, are true. The bodies are drawn far bigger than they are. |
| the vitrines | Along the back, each planet with its moons: the Earth and the Moon, Mars (Phobos, Deimos), Jupiter (Io, Europa, Ganymede, Callisto), Saturn (Mimas to Iapetus, and the rings), Uranus (its moons going round it on its side), Neptune (Triton going round backwards), and Pluto and Charon going round each other. Distances from the planet are square-rooted too; directions are true. North, the ecliptic's, is up everywhere. |
| the date | above the vitrines |

Time goes 5 days a second to start with. After 25 years (2051) it starts
again: JPL's DE421, which it's checked against, ends in 2053.

## Keys

| Key | Action |
|---|---|
| `1` `2` `3` `4` `5` | a quarter of a day, 1, 5, 25 or 100 days a second |
| `R` | back to 2026 January 1 |

Slider: days (a second). Resting the mouse on a body gives its name and
distances, and on the Sun the date.

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
* the planet's flattening, J2 and J4, about its pole;
* the Sun's tide, with the Sun's position taken from the main integration.

Then each moon follows its Kepler orbit again. There are sixteen steps to
the innermost moon's orbit: Phobos's is 0.020 days, Mimas's 0.059. Each
system's own barycentre goes round in the main integration. (Prototyped
against a Bulirsch–Stoer reference: on Saturn's system, 3 km out on Mimas
after 20 days, less on the others.)

**The cost** is about one second of computing per simulated year. At the
usual 5 days a second that's under 2% of the time.

## What the console checks

Every January 1 the console prints these:

* **The planets against JPL's DE421 ephemeris**, from the Sun, and the
  Moon from the Earth, in km. DE421 is JPL's own integration fitted to
  radar, spacecraft and laser ranging; it is where everything starts, so
  any difference is this model's. Over ten years the planets stay within
  about 10 km and the Moon within 40 km (0.05″). The Moon's remaining
  error is the physics left out: the Moon's own figure, the tides, and the
  Earth's pole's precession.
* **A Mercury without Einstein**: a massless twin pulled only by Newton.
  It falls behind, 49 km in the first year and 1800 km in ten, which is
  8″ seen from the Sun. Without the correction, the planets wouldn't match
  JPL's.
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
  within 25–210 km. Some go further, for reasons that are physics left
  out:
  * **Phobos**: 3,200 km a year (a few parts in 1e5 of its pace). Mars
    isn't round about its axis either (its C22 term), and Phobos goes
    round three times a Martian day. That isn't modelled.
  * **Titania and Miranda**: 900 and 400 km a year. Neither Uranus's
    J2 nor the moons' older masses fix it (2014's masses are used).
  * **Mimas**: 500–2,400 km, rising and falling. Its 2:1 resonance with
    Tethys swings it back and forth over 70 years.
  * **The asteroids**: Ceres 2,000 km in five years, about 1″ seen from
    the Sun. Horizons' asteroid orbits include another eleven big asteroids'
    pulls, and the Sun's barycentric motion of DE441 rather than DE421.

From a run at 100 days a second:

    2027-01-01  against JPL's DE421, km off, from the Sun: Mercury 0, Venus 0, Earth 0, Mars 0, Jupiter 0, Saturn 0, Uranus 0, Neptune 0, Pluto 0;
                the Moon, from the Earth: 4 km
                a Mercury without Einstein's correction: 49 km off
                energy steady to 4.4e-10, angular momentum to 9.5e-11 (Newton's; Einstein's correction is a few parts in 1e8)
                Mercury's perihelion turned by Einstein: 42.981" a century, over 3 orbits (theory, 6 pi G M / (c^2 a (1 - e^2)) an orbit: 42.981")
                Io, Europa, Ganymede: L_I - 3 L_E + 2 L_G (their mean longitudes) averaged 179.47 degrees over the year,
                  spread 0.32 (Laplace's resonance holds it at 180)
                Neptune and Pluto: closest so far 32.04 AU; Pluto's year now 1.498 of Neptune's (their orbits cross,
                  but the 3:2 resonance keeps them over 17 AU apart)
    ...
    2036-01-01  ... Mercury 0, Venus 0, Earth 0, Mars 5, Jupiter 11, Saturn 8, Uranus 4, Neptune 4, Pluto 4;
                the Moon, from the Earth: 39 km
                a Mercury without Einstein's correction: 1813 km off

and against Horizons, a month, a year and five years in:

    2026-02-01  against Horizons, km off: Phobos 310, Deimos 23, Io 78, Europa 38, Ganymede 26, Callisto 13, Mimas 518, Enceladus 172, Tethys 69, Dione 26, Rhea 7, Titan 0, Iapetus 2, Miranda 41, Ariel 7, Umbriel 9, Titania 102, Oberon 10, Triton 3, Charon 4, Ceres 1, Pallas 1, Juno 1, Vesta 2, Hygiea 0
    2027-01-01  against Horizons, km off: Phobos 3176, Deimos 328, Io 52, Europa 199, Ganymede 213, Callisto 182, Mimas 575, Enceladus 77, Tethys 90, Dione 10, Rhea 4, Titan 31, Iapetus 11, Miranda 404, Ariel 71, Umbriel 14, Titania 858, Oberon 149, Triton 22, Charon 42, Ceres 218, Pallas 135, Juno 74, Vesta 177, Hygiea 52
    2031-01-01  against Horizons, km off: Phobos 13996, Deimos 1671, Io 60, Europa 364, Ganymede 1160, Callisto 896, Mimas 2364, Enceladus 236, Tethys 412, Dione 53, Rhea 25, Titan 90, Iapetus 34, Miranda 2063, Ariel 392, Umbriel 83, Titania 4502, Oberon 937, Triton 108, Charon 209, Ceres 2010, Pallas 840, Juno 660, Vesta 538, Hygiea 604

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
* `solar-data.lua`, `solar-meshes/`: made by `make-data.py`.
* `fetch-horizons.sh`: the Horizons data.

Headless testing: `SS_RATE` (days a second), `SS_YEARS` (years before it
starts again; at most 25).
