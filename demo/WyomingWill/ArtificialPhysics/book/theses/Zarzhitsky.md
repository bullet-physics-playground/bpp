# Digest: Zarzhitsky (2008), *A Physics-based Approach to Chemical Source Localization Using Mobile Robotic Swarms*

Page numbers are PDF page numbers. The printed page number is the PDF page minus 17; for example, PDF p.105 is printed p.88.

## 1. Bibliographic
- **Title:** *A Physics-based Approach to Chemical Source Localization Using Mobile Robotic Swarms*
- **Author:** Dimitri V. Zarzhitsky
- **Degree:** Ph.D., Computer Science
- **University:** University of Wyoming (Laramie). Defended June 20, 2008; degree dated August 2008.
- **Advisor:** Diana F. Spears (Chair). David R. Thayer was Co-Chair and first suggested fluxotaxis. William M. Spears sat on the committee. (pp.1–4, 6)

## 2. What it is about
The thesis introduces fluxotaxis, which follows the gradient of the divergence of chemical mass flux (GDMF, ∇[∇·(ρV)]). It argues that fluxotaxis combines the strengths of chemotaxis and anemotaxis and switches between them automatically. Fluxotaxis is analysed in 1D and 3D. It is then compared with chemotaxis and anemotaxis in a 2D filament-puff simulator (a re-implementation of Farrell et al. 2002, extended with obstacles), using physicomimetics lattices of 7 robots and swarms of 7–150 robots. The thesis also builds a ethanol flume (a small wind tunnel) and measures real plumes with 32 sensors. On hardware, only chemotaxis was implemented, on three Maxelbots, because no small anemometer was available. Fluxotaxis was never run on hardware (p.253).

## 3. Plume model
- **Structure:** three separate C programs: a plume generator, a trace generator and a viewer. The emitter is assumed passive and the robots are assumed not to disturb the plume (p.104).
- **World:** a square world of 1×1-unit cells, with rectangular obstacles that contain no chemical (p.81).
- **Wind:**
  - Four random corner vectors are linearly interpolated along the edges, giving a Dirichlet boundary (p.105).
  - The interior is integrated forward-Euler in time with central differences in space (p.106):
    u_{i,j}^{t+1} = u − (uΔt/2h)(u_{i+1,j}−u_{i−1,j}) − (vΔt/2h)(u_{i,j+1}−u_{i,j−1}) + (kΔt/2h²)(u_{i+1,j}+u_{i−1,j}+u_{i,j+1}+u_{i,j−1}−4u), with the same form for v.
  - Rule for k: usually below 0.5 when Δt = 1, and "always greater than" the mean u and v.
  - Farrell used a wind grid 10× coarser; this thesis uses a uniform grid with no interpolation.
  - The interior starts at the mean velocity and is spun up for "a few hundred steps" before emission.
  - Puffs that leave the world are advected at the mean velocity and may re-enter (pp.106–107).
- **Mixing:** a random σ is added to the advective velocity, with time correlation, bandwidth and gain "exactly" as in Farrell et al. (p.107). p.105 calls this a "uniformly random σ".
- **Puff growth:** r(t) = (r₀^{2/3} + γt)^{3/2}. γ < 0.01 gives coherent plumes (p.107).
- **Concentration:** ρ_i = Q/(√(8π³) r_i³) · exp(−D_i²/r_i²), summed over puffs, where D_i is the distance from the puff centre (p.108).
- **Obstacles:** puff mass that falls inside an obstacle is moved along a line to the nearest boundary cell, which conserves mass. Large, diffuse puffs can "envelop" small obstacles, so the thesis used large obstacles and a small γ (pp.108–109).
- **Flume:**
  - Box 8×4×1 ft; exhaust fan 55–165 L/s; double-layer mesh flow straightener (p.111).
  - Sensor grid 10×10 at 4-in spacing; 32 sensors read by two 16-channel 10-bit ADCs; 20 Hz sampling (pp.113, 117, 119).
  - 85 experiments; more than 100 GB of interpolated data (p.124).
  - A 15-minute time average along the flow fits a linear density gradient, with residual SD under 10% of the maximum (p.118).

## 4. Fluxotaxis and comparison algorithms
- **Theory:**
  - DMF: ∇·(ρV) = uρ_x + ρu_x + vρ_y + ρv_y + wρ_z + ρw_z (p.48).
  - GDMF = ∇[ρ∇·V + V·∇ρ]. The first term behaves like anemotaxis and the second like chemotaxis (p.128).
  - Emitter signature: DMF > 0 sustained for τ (determined experimentally). In practice, the surface flux ∮ρV·n̂ dA, by the divergence theorem, exceeds a threshold over time (pp.50–52).
  - The 1D source, sink and constant-flow-speed theorems hold only inside the Gaussian's inflection points (pp.136–143).
  - GDMF fails in steady state with a uniform field: DMF is zero away from the point source (p.134).
- **7-robot version (Listing 7.4, p.184):**
  - Hexagon held by the split-Newtonian law F = ±G r^−p (p.67); waypoints every 3 ft (p.188).
  - If the centre robot senses more than 50% of total ρ, the lattice contracts.
  - Otherwise the robots sample ρ at 3 lattice radii and compute concentration-weighted centroids. If ρ rises with radius, they move to the centroid of the centroids. If the outer reading is higher than the inner, they move to the outer centroid. If ρ falls with radius, they run `flux_ring`. Otherwise they cast.
  - `flux_ring`: move to the edge with the largest influx above a threshold. If there is none, move to the largest outflux above the threshold. Otherwise cast. Each edge flux uses the averaged ρ and V of the two robots, with the edge length as the area (pp.185–186).
  - No threshold values are given. The DMF stopping test was disabled in all simulations (p.186).
- **Swarm version (Listings 7.9–7.10, pp.208–210):**
  - Formation law: Lennard-Jones F = R/r² − R^1.7/r^2.7 (pp.196, 199).
  - Each robot computes, for each neighbour n, the flux ρ_n·|V_n|·cos(θ_wind − θ_line)·dist. Readings below the chemical or wind threshold give zero.
  - The robot moves toward the neighbour with the most negative value (largest influx). If there is none, it moves toward the largest outflux. If neither exists, it falls back to chemotaxis; with fewer than 2 neighbours it falls back to anemotaxis.
  - The ·dist factor is a deliberate exploration bias (p.207).
- **Chemotaxis (p.204):** move toward the neighbour with the highest above-threshold ρ; cast if there is no gradient.
- **Anemotaxis (p.205):** goal force along −V when ρ and |V| are above threshold; otherwise cast.
- **Casting (pp.199–201):** move diagonally at 45°, reverse at walls and obstacles, and synchronise direction by recursive local broadcast.
- **Theory for formation parameters:** G_t = F_max R^p/(2√3) and F*_goal = √3G/R^p (pp.71–72). The phototaxis demo used R = 20 in, p = 2, F_max = 2, quoted "G < 308", F_goal = 1.0 < 1.33 (p.78). Note that eq. 4.7 gives about 231 with these values, not 308.

## 5. Experiments and results worth reproducing
- **7-robot lattice, no obstacles (pp.188–190):**
  - Setup: 100×100 ft world, 5000 steps (about 80 min); robots 1 ft² at 2 ft/s; initial lattice radius 1.5 ft; maximum expansion factor 5–15; 35 plumes × 10 expansion factors × 200 starts.
  - Results (Table 7.1):

| Algorithm | Proximity | Success |
|---|---|---|
| Fluxotaxis | 0.9235 | 0.746 |
| Chemotaxis | 0.6745 | 0.318 |
| Anemotaxis | 0.6843 | 0.067 |

- **7-robot lattice, with obstacles (pp.191–194):**
  - Setup: 150 plume/obstacle configurations, with either 10×10 ft or 5×5 ft obstacles at 1–2% coverage. The emitter runs 3000 steps before the robots start, then 7000 steps of tracing. Maximum radius 10 ft; 500 starts at 0–80 ft.
  - Fraction of time the emitter was enclosed: fluxotaxis 49.1%, chemotaxis 7.2%, anemotaxis 8.4%.
- **Large swarm (pp.212–219):**
  - Common setup: 90,000 ft² world; 3 in/s; communication radius Rs = 40 in; emitter runs 3600 steps first, then 7200 steps.
  - Obstacle study: 81 plumes, 7–70 agents, starts 0–200 ft, 40,500 runs. Fluxotaxis arrival time was about 1508–1615 steps; anemotaxis about 1700–1885; chemotaxis 2437–2887; casting 4490–5292 (Table 7.2). Fluxotaxis localization count was about 70k, against about 60k for chemotaxis (Table 7.3).
  - Swarm-size study: 10–150 robots, 10 plumes, ten 5×5 ft obstacles (Table 7.4):

| Algorithm | Arrival time (steps) | Localization frequency |
|---|---|---|
| Fluxotaxis | 3249.9 | 2384.8 |
| Anemotaxis | 3780.5 | 1983.6 |
| Casting | 4224.4 | 224.1 |
| Chemotaxis | 5208.5 | 1496.5 |

- **Maxelbot hardware (pp.223–233, 248–250):**
  - Controller: HCS12 at 25 MHz with 12 KB RAM.
  - Localization: RF/acoustic trilateration (AM radio plus SRF04 40 kHz with parabolic acoustic cones). Error is a few inches out to 7 ft.
  - Communication: Manchester-encoded data at 4800 bps; 3 neighbour updates per second.
  - Chemical sensor: Figaro TGS 2620 metal-oxide sensor, 50–5000 ppm, logarithmic response, affected by temperature and humidity. Calibrated with the SRT procedure.
  - Single robot: four sensors at about 6 in height, ~2 in/s, 60-sample averaging. In a 6×11 ft room it succeeded in 17/23 runs (74%) with a mean of 18 min.
  - In a 25×25 ft lab:

| Metric | Single robot | 3-Maxelbot triangle (1 sensor each) |
|---|---|---|
| Success | 22.2% | 60% |
| Search time | 630 s | 415 s |
| Mean proximity | 7.0 ft | 5.3 ft |

  - The planned anemometer was a Shibaura F6201 hot-wire unit (p.277).
  - Rotating-paddle anemometers were rejected because they disturb the plume, and the TGS 2620 degrades in high airflow (pp.221–222).

## 6. 3D-related content
- 3D DMF including the w terms (p.48), and 3D GDMF (p.128).
- Section 6.3 (pp.144–152) and Appendix A (pp.290–294) analyse diffusion only, with radial V = V₀r̂:
  - Continuous emitter: n = S₀/(4πDr), GDMF = −mV₀S₀/(2πDr³) r̂, DG ∝ r⁻². Both point to the source.
  - Single puff: n = N(4πDt)^{−3/2} e^{−r²/4Dt}. |GDMF| grows without bound as r → 0, while |DG| → 0. The predictive radius is r₀ = 1/√(2B) = √(2Dt).
  - Transient solution: n = S₀/(4πDr)·(1 − erf(r/√(4Dt))).
- The thesis states that real plumes are 3D but CPT is done in 2D slices, and that robot-induced flow disturbance was deliberately left out as future work (p.29).
- Ethanol is 1.6× denser than air; heated, buoyant plumes form complex 3D layers. The flume measured at several heights and used a 3D Voronoi-linear hybrid interpolation (pp.113–115, 119–123).
- A heuristic from the literature compares concentration at different heights; one cited robot declares the source when its bottom sensor detects chemical 90% of the time (p.49).
- Robot clustering is useful for 3D aerial and underwater formations (p.70). Micro-air vehicles are mentioned only in passing (pp.20, 59).
- The Multi-DRONE Simulator is for surface boats (HBOI), not aerial vehicles:
  - It separates real physics from AP physics; the environment updates 25× per control step and localization 2×.
  - It models an azimuth thruster and GPS error of ±3 m; AP friction is set to 0 when the environment supplies damping.
  - Pages 83, 255–275.

## 7. Implications for our 3D fluxotaxis plan
1. **Extend the swarm flux rule to 3D.** Use ρ_n(V_n·d̂)|d| over 3D neighbour vectors, with full (u, v, w) wind. Start with the thesis's ordering (influx, then outflux, then chemotaxis, then anemotaxis) and expose the chemical threshold, wind threshold and distance bias as parameters.
2. **Check the 3D puff code against the closed forms.** The thesis's 3D GDMF results (p.148–152) work as unit tests: a static puff plus radial V should make the GDMF arrow point inward and grow as r shrinks, while the chemotaxis vector fades near the source.
3. **Keep Farrell's three scales in 3D.** That means advection of puffs, colored-noise mixing, and r(t) growth. The 3D density form ρ_i = Q/((8π³)^{1/2}r³)exp(−D²/r²) already fits. Add a height-dependent mean wind as a 3D Dirichlet boundary with spin-up, and reuse the obstacle mass-relocation rule against building walls.
4. **Model downwash on purpose.** The thesis assumed it away (pp.29, 104). Bias each drone's sensed V and ρ by its own rotor wash, and compare against "ideal sensors". Also test sensor offsets (above or below the body), since the thesis found sensor placement on a single robot mattered (p.243).
5. **Reproduce the thesis's main tables first, then repeat them in 3D.** Reproduce Table 7.1 (7-member hexagon) and Table 7.4 (10–150 members; arrival time and localization-count metrics) in the 2D Android or 3D port. Then repeat with a vertical emitter offset so source height becomes a reported metric, alongside the thesis's "enclosed fraction" metric.
6. **Use DMF to stop the search.** Add a sustained-outflux stopping rule over a 3D lattice shell (∮ρV·n̂ > threshold for τ), which the thesis never enabled (p.186). It is the natural way to estimate source height, unlike the height-comparison heuristic (p.49).
7. **Pick formation laws for 3D.** Lennard-Jones for fluid-like swarms in a city; split-Newtonian with G < G_t for rigid lattices. Re-derive G_t for 3D packing, since eq. 4.7 assumes a 2D hexagon, and note the 308 versus 231 discrepancy.
8. **Wind from tilt.** It is a non-intrusive airflow sensor, which the thesis lacked. Model its lag and noise, because the thesis notes anemotaxis is misled by instantaneous wind (p.219).
9. **Add a pseudo-source test.** Include buildings that create corner sinks or high-concentration pockets, where the thesis showed chemotaxis gets fooled (pp.216–217) and fluxotaxis should not.
