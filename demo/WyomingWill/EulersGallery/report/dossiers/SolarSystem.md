## The Solar System

**What it shows** — The Sun, the eight planets, Pluto, five asteroids (Ceres, Pallas, Juno, Vesta, Hygiea) and 21 moons, moving under gravity from 2026-01-01 0h TDB, starting from JPL's states for that day. An orrery shows heliocentric distances square-rooted (directions and ecliptic heights true), and vitrines show each planet with its moons. Every body wears a drawn map and turns by the IAU rotation model, so the Moon's librations and Mercury's 3:2 spin-orbit resonance can be seen. The console compares the integration with JPL every year (planets, Moon) and every month (moons, asteroids).

**Model** — All gravity is computed in Lua (`solar-engine.lua`). Bullet only places meshes: world gravity is set to 0 and every body's transform is written each frame, so Bullet runs no dynamics. Everything is in ICRF coordinates, AU and days.
- *Main integration*: 16 bodies, all pulling each other (Newton). They are the Sun, Mercury, Venus, Earth, the Moon, Pluto, five asteroids, and the system barycentres of Mars, Jupiter, Saturn, Uranus and Neptune. Two terms are added: the first-order Schwarzschild correction to the Sun's pull, GM/(c²r³)[(4GM/r − v²)r + 4(r·v)v], and the Earth's J2 acting on the Moon (code comment: the Earth's pole is taken as ICRF z, "near enough"). The step is a fixed 1-day Bulirsch–Stoer step: Gragg modified midpoint with 2, 4, 6, 8 and 10 substeps, Richardson-extrapolated to 10th order, with no error control. Positions between steps come from cubic Hermite interpolation (for display; the checks are taken at whole days, the ends of steps). Alongside runs a massless "Mercury without Einstein" twin, pulled by Newton only.
- *Moon systems* (Mars, Jupiter, Saturn, Uranus, Neptune, Pluto): a Wisdom–Holman drift–kick–drift step. Each moon drifts on its Kepler orbit for half a step. The kick holds the other moons (with the planet's reflex wobble), the planet's J2 and J4, Mars's C22/S22 rotating with Mars, and the Sun's tide (the Sun taken from the main integration). Each system has 16 steps per orbit of its innermost moon (console, in days): Mars 0.020, Jupiter 0.111, Saturn 0.059, Uranus 0.088, Neptune 0.367, Pluto 0.399. Between steps a moon is carried on its Kepler orbit from the last step (less than one step).
- *Checks*: each frame first runs every check whose date falls before the frame's time, with the integration stopped exactly at that date (the yearly and monthly dates are whole days from the start, so the main integrator's 1-day steps land on them), then advances to the frame. The check figures are therefore the same at any SS_RATE (fixed 15 Oct 2026; before, checks ran on the first frame after the date and interpolated back).
- *Perihelion check*: a separate two-body run of Mercury plus the Schwarzschild term, stepped by RK4 at h = 0.01 d. The Laplace–Runge–Lenz vector is averaged over each perihelion-to-perihelion orbit and a straight line is fitted through its direction.
- *Data*: DE421 states and masses for the Sun, planets, Moon and Pluto. Moons and asteroids start from JPL Horizons. Moon-system masses are DE440's. Pluto's GM is 975.43 km³/s², the value Horizons' Charon orbit implies (README: DE421's 977.0 puts Charon 20,000 km off in a year).
- *Rotation*: IAU WGCCRE 2015 pole and prime-meridian models, keeping only the main periodic terms. Mars, its moons and the Moon's terms come from the 2009 report.

**Theory checks**

Values are from the fixed code (15 Oct 2026); the check lines are identical at SS_RATE=5, 60 and 100. The Phobos, Titania, Miranda and Ceres rates are differences between yearly Horizons lines (2026-01-01 → 2027-01-01 → 2031-01-01).

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Planets vs DE421 (heliocentric), 2027 / 2031 / 2036 | JPL DE421 | 2027: all 0 km. 2031: Mars 1, Jupiter 2, others 0. 2036: Mercury 1, Earth 1, Mars 1, Jupiter 5, Saturn 1, others 0 | ≤ 5 km in 10 yr (README "within 5 km") ✓ |
| Moon vs DE421 (geocentric) | DE421 | 4 / 20 / 39 km (2027 / 2031 / 2036) | 39 km ≈ 0.05″ (README) |
| Mercury without GR, lag behind DE421 | needs the Schwarzschild term | 49 km (2027), 624 (2031), 1813 (2036); not monotonic (733, 624, 404, 286, 531, 1107, 1813 for 2030–36) | shows that GR is needed; README "49 / 1800 km", and now says the yearly figure is not monotonic ✓ |
| Mercury perihelion advance | Δϖ = 6πGM/(c²a(1−e²)) per orbit = 42.981″/century | 42.981″/century (over 3, 20 and 40 orbits) | 0.000″ to 3 decimals |
| Energy (Newtonian) | conserved | max \|ΔE/E\| 1.4e-9 (2035) | README "about 1e-9" ✓ |
| Angular momentum | conserved | max \|ΔL/L\| 3.0e-10 (2035) | README "3e-10" ✓ |
| Laplace resonance L_I − 3L_E + 2L_G | 180° (free libration 0.07°, README) | yearly means 179.87–180.12°, spread 0.15–0.23°; 20-day means 179.65–180.32° | ±0.35° (README "179.7–180.3") ✓; these are frame-sampled and move by ~0.01° with SS_RATE |
| Neptune–Pluto 3:2 | P_Pluto/P_Neptune ≈ 1.5; min separation > 17 AU | ratio 1.489–1.515 (osculating); closest 32.04 AU | consistent; 25 yr cannot test the 17 AU bound (README) |
| Moons, asteroids vs Horizons, 2026-02-01 | JPL Horizons | Phobos 83, Io 5, Mimas 41, Titania 102, Titan 0, Ceres 1 km | start-up; README same line identical ✓ (was Io 78, Mimas 518 from a high-rate run) |
| Same, 2027-01-01 | Horizons | Phobos 986, Mimas 575, Titania 858, Miranda 404, Ceres 218, Titan 31 km | README same line identical ✓ |
| Same, 2031-01-01 | Horizons | Phobos 4771, Titania 4502, Miranda 2060, Mimas 2794, Ceres 2010, Titan 90, Triton 108, Charon 209 km | README same line identical ✓ |
| Phobos drift | Horizons | ≈ 950 km/yr | README "950 km a year" ✓ |
| Titania / Miranda drift | Horizons | ≈ 900 / 400 km/yr | README ✓ |
| Earth subsolar point, 2026-01-01 0h TDB | IERS Earth via Skyfield: 23.02 S, 178.87 W | 23.01 S, 178.79 W | 0.01° lat, 0.08° lon |
| Moon libration (sub-Earth point) | longitude up to 7.9°; latitude 1.5° + 5.0–5.3° = 6.7–6.8° | each year 7.5–8.0 W to 7.4–8.1 E; 6.8–6.9 S to 6.8 N | ✓ |
| Mercury 3:2 hot poles at perihelion | subsolar longitude 0° or 180° | 0.0 to 0.2 from 0°/180° (e.g. 2036: −180.0, 0.0, −180.0, 0.0) | ≤ 0.2° |
| WH vs Bulirsch–Stoer prototype (README) | BS reference | Mimas 3 km off after 20 d (README, not rerun) | — |

**Run used**
```
cd demo/WyomingWill/EulersGallery/exhibits/SolarSystem
HOLD_S=0 SS_RATE=60  SS_YEARS=10 timeout 3000 ../../../../../release/bpp -f solar-system.lua -n 3660
HOLD_S=0 SS_RATE=100 SS_YEARS=10 timeout 3000 ../../../../../release/bpp -f solar-system.lua -n 2200
HOLD_S=0 SS_RATE=5|60|100 SS_YEARS=4 ... -n 13180|1100|662          # three years, rate comparison
```
All 120 check lines (DE421 blocks and Horizons lines, including the yearly Laplace means) are identical, character for character, at rates 60 and 100 over ten years, and at 5, 60 and 100 over three; the rate-60 lines are also identical to the pre-fix rate-60 run (at 1 d/frame the old sampling already landed on the dates). Only the frame-sampled lines (20-day Laplace means, the Moon's face extremes, Mercury's perihelion longitudes) differ, by 0.01–0.2. Verbatim:
```
the Earth: on 2026-01-01 at 0h (TDB) the Sun is overhead at 23.01 S, 178.79 W (... through Skyfield: 23.02 S, 178.87 W ...)
the moons: Wisdom-Holman, steps (days): Mars 0.020, Jupiter 0.111, Saturn 0.059, Uranus 0.088, Neptune 0.367, Pluto 0.399
2026-02-01  against Horizons, km off: Phobos 83, Deimos 4, Io 5, Europa 11, Ganymede 19, Callisto 17, Mimas 41, Enceladus 6, ...
2027-01-01  against JPL's DE421, km off, from the Sun: Mercury 0, Venus 0, Earth 0, Mars 0, Jupiter 0, Saturn 0, Uranus 0, Neptune 0, Pluto 0;
            Mercury's perihelion turned by Einstein: 42.981" a century, over 3 orbits (theory, ... an orbit: 42.981")
2031-01-01  against Horizons, km off: Phobos 4771, ..., Mimas 2794, ..., Titania 4502, Oberon 937, Triton 108, Charon 209, Ceres 2010, ...
2036-01-01  against JPL's DE421, km off, from the Sun: Mercury 1, Venus 0, Earth 1, Mars 1, Jupiter 5, Saturn 1, Uranus 0, Neptune 0, Pluto 0;
            the Moon, from the Earth: 39 km
            a Mercury without Einstein's correction: 1813 km off
            energy steady to -1.3e-09, angular momentum to -2.5e-10
```
Before the fix, the rate-100 run gave (2026-02-01) Io 945, Mimas 4688, Enceladus 2014 and (2036) Mercury 1220, Venus 11, Moon 122 km; now Io 5, Mimas 41, Enceladus 6 and Mercury 1, Venus 0, Moon 39, as at rate 60.

Checks: hall vs standalone (`SS_RATE=100 SS_YEARS=3 bash ../../report/cmp2.sh solar SolarSystem solar-system.lua 700 ss`): IDENTICAL (101 lines). Start pause: HOLD_S=0 for 600 frames is a prefix of the default pause for 630 frames (SS_RATE=100, SS_YEARS=3).

**Known departures and honest caveats**
- **Fixed 15 Oct 2026: check sampling at high SS_RATE.** The checks used to fire on the first frame after their date. At 100 d/s (1.67 d a frame) the main bodies were then read off the Hermite cubic outside its step (extrapolated up to a day: Mercury 1220 km, the Moon 122 km in 2036) and the moons carried back from their last Wisdom–Holman step by a bare Kepler orbit (Mimas 4,688 km, Io 945 km on 2026-02-01). Now each frame first stops the integration at every check date it passes and runs the check there (`checks(tn)` in solar-system.lua), then goes on to the frame's time; the displayed positions are unchanged. A second rate dependence was removed in `E.advance` (solar-engine.lua): the moons' steps inside the current day are finished before the next day is stepped, so each kick takes the Sun from the same day's interpolant whatever the frame pattern. With both, the check lines agree to the km at rates 5, 60 and 100.
- **Fixed 15 Oct 2026: README sample output.** The 2027 block (Laplace 180.08, spread 0.18, with its 20-day-means line), the 2036 planets (Mercury 1, Earth 1, Mars 1, Jupiter 5, Saturn 1), the Horizons 2026-02-01 / 2027 / 2031 lines, "within 5 km", Phobos 950 km/yr, "20–210 km" and the Mimas wording now come from the fresh run. The README now says the no-Einstein distance is not monotonic year to year (49, 190, 494, 733, 624, 404, 286, 531, 1107, 1813 km for 2027–36): the orbit differs, and the distance depends on where Mercury is in it each Jan 1.
- Still frame-sampled (by design, not checks against theory values): the Laplace 20-day means and yearly means, the Moon's face extremes, Mercury's perihelion longitudes and Neptune–Pluto closest approach are taken once per frame, so they change slightly with SS_RATE (20-day means by ~0.01°, the yearly means agreed to 0.01° in these runs, perihelion longitudes by up to 0.2°; at 1.67 d/frame the perihelion is located to within a frame).
- Between Wisdom–Holman steps a moon's position is its Kepler drift from the last step (no kick); at the check dates this covers under one step (≤ 0.4 d for Pluto, 0.059 d for Saturn) and is the same at every rate.
- Physics left out (README):
  - The Moon's 39 km is the Moon's figure, tides and Earth-pole precession; the J2 pole is fixed at ICRF z.
  - Phobos (~950 km/yr) is Mars's higher-order gravity field. Adding C22/S22 cut it from 3,200 km/yr, and Deimos from 330 to 50.
  - Titania and Miranda (900 and 400 km/yr) are not explained by J2 or older masses.
  - Mimas: 575 km after a year, 2,794 after five, growing with a month-to-month wobble of 100–200 km (the README's old "500–2,400, rising and falling" is not what the monthly series shows; README updated). The README attributes it to its 2:1 resonance with Tethys (70-year swing); that cause is not tested here.
  - Asteroids (Ceres 2,000 km in 5 yr, ~1″) lack Horizons' 11 extra perturbing asteroids and DE441's barycentre.
- DE421 masses drive the main integration, but DE440 masses drive the moon systems. This mix is deliberate.
- The 1-day Bulirsch–Stoer step has no error control. Pluto–Neptune "> 17 AU" is a known fact, not shown in the 10 years run.
- Rotation models keep only the main periodic terms. Several moons' meridians (Titan, Mimas, Enceladus, Tethys, Dione, Iapetus) and Pluto/Charon are not cross-checked against a second source (README).
- Surface maps are drawn, not photographs. Variable features such as the Red Spot and sunspots are illustrative.
- The README's Lainey L1.2 alternative start (1.5° swing, period 2039 d vs 2070 d theory) was not rerun, since it needs the Horizons files removed.

**References** (as cited in the code and README)
- JPL DE421 ephemeris (via skyfield-data/jplephem); DE440/DE441 (masses, Horizons' asteroid barycentre); JPL Horizons; JPL satellite solutions.
- Archinal et al. 2018, "Report of the IAU WGCCRE: 2015", Celest. Mech. Dyn. Astr. 130:22; the 2009 WGCCRE report, CMDA 109:101; NAIF pck00008; the hapsira library.
- Wisdom & Holman mapping; Bulirsch–Stoer / Gragg modified midpoint; Lainey's L1.2 theory of the Galilean moons (via astronomy-engine).
- IERS Earth orientation via Skyfield; Natural Earth coastlines.
