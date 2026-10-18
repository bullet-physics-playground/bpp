# The Solar System

The Sun, the eight planets, Pluto, twenty-one moons, the giant planets'
rings and the asteroid belt's thirty largest, from 2026 January 1 on. They
move as gravity moves them, worked out here from where JPL had them that day.

It opens in the dark. The Sun ignites, and the bodies light up one by one in
the order its light reaches them, each after the time light really takes to
get there; with Holst's *The Planets*, Holst conducting the London Symphony
Orchestra in 1922–23, if you let it fetch the recording.

| Part | What's there |
|---|---|
| the orrery | The Sun on its column, with the planets, Pluto and the asteroid belt on their orbits (the orbits drawn for the planets, Pluto and the five biggest asteroids). Distances from the Sun are square-rooted (Mercury 11 cm, the Earth 18 cm, Neptune 99 cm, Pluto out to 126 cm) so that all of them fit. Their directions, and their heights above and below the ecliptic, are true. The bodies are drawn far bigger than they are. |
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
| `L` | the opening again: the room dark, the Sun igniting, its light going out |
| `M` | the music off, or on again (from Mars) |
| `G` | get the music (266 MB, once), if you said "Not now" |

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

## The opening

You come in to a dark room: not black, but hard to make anything out. After
a second and a half the Sun ignites. It glows (its own light, an emission),
and it is the only lamp: a point light at its centre, the fill light off. So
in the orrery every body's day side faces the Sun and its night side faces
away. Then its light goes out, and each body lights up as the light reaches
it, nearest first: Mercury, Venus, the Earth and the Moon, Mars and its
moons, the asteroid belt, Jupiter and its moons and rings, and on out to
Neptune and Pluto. Each brightens over a second, from 5% of its colour to
its full look.

**When**: after the time light takes from the Sun's centre to the body's, at
its distance in the simulation at that moment (a planet's own place, not its
system's barycentre; each moon's, each asteroid's), **shown 1 second for
every 10 minutes of the light's travel**: Mercury 0.4 s, the Earth 0.8 s,
the belt 1.8 to 3.2 s, Jupiter 4.3 s, Saturn 7.9 s, Uranus 16 s, Neptune 25
s and Pluto 29.5 s after the Sun ignites. The console says each time once, as
it lights up, from the distances on 2026-01-01:

      the Sun ignites (2026-01-01): its light reaches each body after its distance from the Sun over c (shown here 1 s for each 10 min)
      sunlight reaches Mercury: 3 min 51 s after leaving the Sun (0.4625 AU)
      sunlight reaches Venus: 6 min 03 s after leaving the Sun (0.7274 AU)
      sunlight reaches the Earth: 8 min 11 s after leaving the Sun (0.9833 AU); the Moon: 8 min 12 s
      sunlight reaches Mars: 11 min 53 s after leaving the Sun (1.4287 AU); its moons Phobos 11 min 53 s, Deimos 11 min 53 s
      sunlight reaches (4) Vesta: 18 min 19 s after leaving the Sun (2.2017 AU)
      ... (the rest of the belt, out to (31) Euphrosyne: 31 min 37 s, 3.8006 AU)
      sunlight reaches Jupiter: 43 min 21 s after leaving the Sun (5.2119 AU); its moons Io 43 min 20 s, Europa 43 min 19 s, Ganymede 43 min 19 s, Callisto 43 min 27 s; and its rings
      sunlight reaches Saturn: 1 h 19 min 10 s after leaving the Sun (9.5185 AU); its moons Mimas 1 h 19 min 09 s, ... Titan 1 h 19 min 13 s, Iapetus 1 h 19 min 05 s; and its rings
      sunlight reaches Uranus: 2 h 42 min 06 s after leaving the Sun (19.4901 AU); its moons Miranda 2 h 42 min 06 s, ...; and its rings
      sunlight reaches Neptune: 4 h 08 min 33 s after leaving the Sun (29.8848 AU); its moon Triton 4 h 08 min 32 s; and its rings
      sunlight reaches Pluto: 4 h 54 min 35 s after leaving the Sun (35.4214 AU); its moon Charon 4 h 54 min 35 s

**Its clock is the exhibit's own frames** (60 a second), counted only while
the simulation steps, never the wall clock. So the console says the same,
line for line, in the hall as on its own, and the start's half-second pause
only delays it; and since the times come from the start's distances, the
lines are the same at any speed (where they fall among the check lines
depends on the speed: at 5 days a second the Sun ignites on January 8 of the
simulation, at 100 in late May).

**Each time you come in** (in the hall: each time you arrive at the bay; on
its own: at the start; and with `L`) the opening plays again, from the
distances then. The console gives the times only once a run, at the frames
the first opening on its own has them, so that the hall and the exhibit on
its own print the same. (In the hall, the first frame is run as the hall
loads, so the console's opening is one frame ahead of the one you see.)

**No shadows.** Nothing here casts one. bpp's shadows (the View menu's
Shadows: yours to turn on, not the exhibit's) come from light 0 as from a
single fixed direction, a far sun overhead; from a lamp at the Sun, in the
middle of everything, every shadow would fall the wrong way, so the rings
don't shade their planets nor the planets their rings. With shadows on, the
lighting is worked out per pixel, still from the Sun.

**The vitrines are lit by the same lamp**, the orrery's Sun, in front of
them: each planet's day side there faces the orrery's Sun, not the real
Sun's direction from it (bpp has two lights; there's no lamp per vitrine).
The Earth's comes out within about 45 degrees; Saturn's about 90.

**How a body is darkened**: a body without a map by its colour. A body
wearing a map is drawn white under it whatever its colour, so it is
darkened instead by letting the dark room show through it (transparency 95%
before its light arrives).

The lights: `v.glLight0` at the Sun (w = 1); `v.glLight0Color` and the
Sun's emission go from 0 to full over the Sun's second; `v.glAmbient` and
`v.glModelAmbient` from 0.02 (the dark room) to 0.05 (night sides you can just
see); `v.glLight1Color` 0 (no fill light); `v.glSpecular` 0.2 (a lamp this
close put a glare on the table's top).

## The asteroid belt

**The thirty largest asteroids of the main belt**: everything over about
190 km across, Ceres (939 km) down to Hermione (194). Ceres, Pallas, Juno,
Vesta and Hygiea were in the integration already, with their masses; the
other twenty-five are new: Interamnia, Europa, Davida, Sylvia, Eunomia,
Euphrosyne, Cybele, Camilla, Bamberga, Patientia, Psyche, Thisbe, Doris,
Ursula, Iris, Fortuna, Diotima, Herculina, Amphitrite, Aurora, Egeria,
Eugenia, Elektra, Themis and Hermione.

**Their orbits**: osculating elements (heliocentric, ecliptic and equinox
of J2000) at epoch 2025-11-21 (JD 2461000.5 TT), the Minor Planet Center's,
as Stellarium carries them in its `data/ssystem_minor.ini` (github.com,
Stellarium/stellarium, master, fetched 2026-10-18), with each one's
discoverer and date of discovery. JPL's Small-Body Database
(ssd-api.jpl.nasa.gov) and Horizons (ssd.jpl.nasa.gov) were the sources
asked for, but the network refused both where this was made, so the
elements are not JPL's. The thirty entries are copied, unchanged, to
`belt/ssystem_minor-excerpt.ini`; `make-belt.py` makes `solar-belt.lua` from
them. (Stellarium has 532 Herculina cut short, as "Herculin".)

**Their sizes are from memory**: published mean diameters (Dawn's for Ceres
and Vesta, the VLT/SPHERE shape models of Vernazza and others, 2021, and
Marsset and others, 2020, for most of the rest), each good to about 10%, not
checked here against a source. They decide which thirty are the largest (a
different source could swap the last few) and how big each is drawn: by the
orrery's own rule, 0.33 cm times the square root of the radius in thousands
of km, Ceres 0.23 cm down to 0.10 cm (without the planets' 0.35 cm floor;
the five already there had been drawn 0.35 cm and are now drawn by the rule
too).

**How they move**: massless, pulled (Newton) by the Sun, the planets, the
Moon, Pluto and the five asteroids with masses, at their places in the main
integration, and stepped by RK4 a day at a time, after each of its days
(`solar-engine.lua`). Being massless, they change nothing in the rest:
every existing check line is the same, character for character. They start
from the elements' epoch, 41 days before 2026-01-01, carried on to it with
the planets pulling (RK4, quarter-day steps, the planets on Kepler orbits
back from DE421's places), plus the Sun's place then.

**Planetary perturbations matter** over the exhibit's 25 years: two-body
Kepler about the Sun alone would be off by 60,000–800,000 km after one year
and up to 3 million km (Juno) or 5 million (Hygiea) within five, which is a
millimetre or more in the orrery, as big as the asteroids are drawn. Even
the 41 days from the epoch to the start matter: Kepler for them puts Hygiea
5,900 km off on 2026-01-01, which grew to a million km in five years before
the bridge with the planets pulling was put in.

**Checked against JPL Horizons**: Horizons' positions for Ceres, Pallas,
Juno, Vesta and Hygiea (from `horizons/`, fetched earlier by
`fetch-horizons.sh`), against massless twins of those five started from
these elements and moved the same way (a twin isn't pulled by its massive
self, which starts a few hundred km from it; the twins aren't drawn). At the
start, and every January 1 to 2031 (Horizons' files end there), in km:

| | Ceres | Vesta | Pallas | Hygiea | Juno |
|---|---|---|---|---|---|
| 2026-01-01 (the start) | 111 | 109 | 151 | 146 | 103 |
| 2027-01-01 | 90 | 109 | 115 | 150 | 110 |
| 2028-01-01 | 105 | 78 | 106 | 101 | 166 |
| 2029-01-01 | 97 | 159 | 189 | 20 | 119 |
| 2030-01-01 | 105 | 137 | 200 | 123 | 79 |
| 2031-01-01 | 107 | 73 | 158 | 180 | 70 |
| two-body Kepler alone, 2027 | 92,780 | 56,643 | 62,584 | 795,611 | 93,997 |
| two-body Kepler alone, 2031 | 1,177,214 | 308,622 | 848,383 | 1,593,904 | 3,109,530 |

So the integrated belt stays within about 200 km of Horizons over five
years, about what the elements' last digit (0.00001 degree, 70 km at 2.8 AU)
and the start allow; Horizons' orbits also have the other big asteroids
pulling, which these don't. The console prints these lines (new lines: the
check lines that were there are unchanged):

      2026-01-01  the asteroid belt (the MPC's elements of 41 days before, carried here) against Horizons, km off: Ceres 111, Vesta 109, Pallas 151, Hygiea 146, Juno 103
      2027-01-01  the asteroid belt (from the MPC's elements, integrated) against Horizons, km off: Ceres 90, Vesta 109, Pallas 115, Hygiea 150, Juno 110
                  (two-body Kepler about the Sun alone: Ceres 92780, Vesta 56643, Pallas 62584, Hygiea 795611, Juno 93997)

Resting the mouse on an asteroid gives its number and name, its size (and
that it's from memory), who found it and when, its orbit's a, e and i (the
MPC's), its distances and its year.

## The rings

**Saturn**: the D, C, B and A rings, the Cassini Division between B and A,
the Encke gap in A, and the narrow F ring (66,900 to 140,200 km from its
centre). B the densest (opaque), C half see-through, the Cassini Division
nearly empty (dark, mostly see-through). **Jupiter**: the halo
(92,000–122,500 km), the main ring (to 129,000) and the gossamer rings out
to 226,000 km: faint, reddish dust. **Uranus**: thirteen rings, 37,850 to
103,000 km: the nine narrow ones of 1977 (6, 5, 4, α, β, η, γ, δ, ε), λ,
the dusty ζ, ν and μ; as dark as charcoal. **Neptune**: Galle, Le Verrier,
Lassell, Arago and Adams (41,900 to 62,930 km), with the arcs in the Adams
ring.

**The ring data are from memory** (NASA's planetary fact sheets and the PDS
Ring-Moon Systems Node's tables, which the network here refused):
`make-rings.py` has them, with the colour and opacity of each band, and
makes the meshes (`solar-meshes/rings-*.obj`) and `solar-rings.lua`.

Each ring is a flat band in its planet's equator, turned to its pole (the
IAU's, from `solar-rotation.lua`) and not turning. In the orrery they're
scaled exactly as the planet is drawn: the planet's sphere stands for its
mean radius, and a ring at r km is drawn at r over that radius times the
sphere's, so ring against planet is true (Saturn's A ring reaches 2.35
times its radius). In the vitrines, distances from the planet are
square-rooted, as its moons' are, so the rings sit among the moons as they
do (Mimas just outside the A ring), and they look narrower against the
planet than they are. Uranus's rings stand nearly upright to its orbit:
its equator is tipped 98 degrees.

Saturn's rings look dim in 2026, and rightly: Saturn's equinox was in May
2025, when the Sun crossed the ring plane, and on 2026-01-01 the Sun is
only 3.6 degrees below it (the IAU pole against the integration's Saturn):
lit almost edge-on, on their south face. They brighten over the years
as the Sun climbs (faster at 25 or 100 days a second).

The narrow rings are tens of km wide or less, far below a pixel: they're
drawn 0.035 cm wide in the orrery and 0.05 cm in the vitrines, and say so.
Where the Adams ring's arcs are round it is an example (they go round in
0.44 days).

**Faint rings, honestly**: Jupiter's, Uranus's, Neptune's and Saturn's D ring
are drawn nearly see-through (Jupiter's main ring 10% opaque, its halo 4%,
the gossamer rings 2–3%; Uranus's narrow rings dark grey, its dusty ones
2–5%; Neptune's 4–45%): from where you stand they're barely there, as they
are. As you come closer they show more, up to three times as opaque from
150 cm in to 30 cm (and at most 90%), so that you can find them.

They light up with their planets, and the mouse on them says what they are,
their radii and who found them: Saturn's by Galileo (1610, as "ears") and
recognised as a ring by Huygens (1655, published 1659), Cassini's division
(1675); Uranus's by stellar occultation in 1977 (Elliot, Dunham and Mink,
from the Kuiper Airborne Observatory), λ and ζ by Voyager 2 (1986), ν and μ
by the Hubble Space Telescope (2003); Jupiter's by Voyager 1 (March 1979);
Neptune's arcs by stellar occultations in 1984, confirmed, and the whole
rings seen, by Voyager 2 in 1989 (from memory too).

## The music

**Holst's *The Planets*, Holst conducting the London Symphony Orchestra,
recorded for Columbia in 1922–23**: public domain in the US (a sound
recording published before 1926), from Wikimedia Commons,
`File:Holst_-_The_Planets_(Columbia_1922-23).flac` (266 MB). It isn't in
the repository. The file's own address is the standard one, from the md5 of
its name (5f37ff963c99294c7dfa948b3b316dff):
`https://upload.wikimedia.org/wikipedia/commons/5/5f/Holst_-_The_Planets_%28Columbia_1922-23%29.flac`.

* **The first time you come in**, with no recording here, it asks: "The
  solar system can play Holst's *The Planets*, Holst conducting the London
  Symphony Orchestra in 1922–23 (public domain; from Wikimedia Commons, 266
  MB). Download it?" *Yes* fetches it in the background into bpp's data
  folder (`v:dataDir()`), saying how far it's got every 10% in the console,
  and starts the music when it's done; *Not now* asks again the next run;
  *Don't ask again* doesn't (bpp keeps the answer). `G` fetches it any time.
* **When it's here**, it starts as you come in, in the dark, with Mars,
  faded in over 4 seconds, and plays on through the suite (and round again).
  **Rest the mouse on a planet** (in the orrery, in its vitrine, one of its
  moons or its rings) and it crosses over (a 1.2 s fade, then 2 s in) to
  that planet's movement. The Earth, the Moon, the Sun, Pluto and the
  asteroids keep whatever is playing.
* It **pauses with bpp's pause** (S, or the toolbar: when the simulation
  hasn't stepped for three frames) and carries on with it; `M` fades it out
  and stops it, and starts it again from Mars. In the hall it belongs to
  this bay: it fades out over 1.5 s as you walk away, and starts again from
  Mars when you come back.
* In a run without a screen there's no question, no download and no
  music, and nothing about it in the console.

Where each movement starts (`solar-music.lua`, **found by ear**, to be
fine-tuned): Mars 0:00, Venus 6:15, Mercury 14:30, Jupiter 18:11, Saturn
25:25, Uranus 32:35, Neptune 38:54; the end 44:41.

## In the hall

The hall (`../../gallery.lua`) tells the exhibit when you arrive at its bay
and when you leave (`v:onEnter`, `v:onLeave`, which bpp on its own doesn't
have: the exhibit then starts as if you'd just come in), and gives it its
own lights while you're there: where they are (a lamp, w = 1, goes with the
bay), the ambient light, the lights' colours and the highlights, at once as
it changes them, and the hall's again when you leave. Its dark room darkens
the hall around it too, while you're at it.

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
usual 5 days a second that's under 2% of the time. Measured without a
screen (3,000 frames), the exhibit's own work per frame is 1.1 ms at 5 days
a second and 7.1 ms at 100 (before the belt, the rings and the opening:
0.7 and 6.1 ms), within the 16.7 ms of a frame. The belt's daily RK4 is
about a tenth of the main integration's cost. Drawing, under a software
renderer (Xvfb, llvmpipe) with shadows on: 36–38 ms a frame against 34–37
before (the screen pass up by about 12 ms, mostly the see-through rings and
bodies; the shadow pass down by 10, nothing here casting); a graphics card
does both in a small fraction of that.

**The asteroid belt** (see above) is integrated alongside: massless, so
nothing here changes; each asteroid pulled by the bodies above at their
places in this integration, RK4, one-day steps.

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

      cd demo/WyomingWill/EulersGallery/exhibits/SolarSystem
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

* `solar-system.lua`: the exhibit. It also stands in Euler's Gallery (`../../`).
* `solar-engine.lua`: the integrations.
* `solar-rotation.lua`: how each body turns (the IAU's models).
* `solar-data.lua`, `solar-meshes/`: made by `make-data.py`, except the
  maps, `solar-meshes/tex-*.jpg`, made by `make-textures.py` (NumPy,
  Pillow; it fetches Natural Earth's `ne_110m_land.geojson` from GitHub
  if it isn't beside it).
* `fetch-horizons.sh`: the Horizons data.
* `solar-belt.lua`: the asteroid belt's elements, sizes and discoveries,
  made by `make-belt.py` from `belt/ssystem_minor-excerpt.ini` (Stellarium's
  copy of the Minor Planet Center's elements; it fetches Stellarium's file
  if the excerpt isn't there).
* `solar-rings.lua`, `solar-meshes/rings-*.obj`: the rings, made by
  `make-rings.py`. (`solar-meshes/saturn-ring-*.obj`, Saturn's old rings
  made by `make-data.py`, aren't used any more.)
* `solar-music.lua`: the music (Holst's *The Planets*): asking, fetching,
  playing, following the mouse.

Headless testing: `SS_RATE` (days a second), `SS_YEARS` (years before it
starts again; at most 25).
