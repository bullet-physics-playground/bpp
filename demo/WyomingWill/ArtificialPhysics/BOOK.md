# The book in BPP: chapter-by-chapter map

This file maps every simulation, experiment and checkable result in
*Physicomimetics: Physics-Based Swarm Intelligence* (Spears & Spears, Springer
2011) to a Bullet Physics Playground (BPP) port. It covers all 19 chapters and
the appendix: 182 entries. Section 5 adds the ideas from the earlier chat, the plan and the thesis digests that go beyond the book. The detailed notes for each chapter are in `book/`
(`ch01.md` … `ch19.md`, `ch20-appendix.md`). They give the algorithm,
parameter values, the results a port must reproduce (with page, figure and
table references), and what the porter must decide where the book is silent or
inconsistent.

Page numbers are PDF pages of `apbook1.pdf`. Book page = PDF page − 31.

**Status:** **done** = in BPP now; **partly** = in BPP but not yet checked
against the book's numbers; **plan** = in `AP-3D-vehicles-plan.pdf`;
**new** = not in the plan. A ★ marks an extension that is neither in the book
nor in the app.

**Order inside each task:** port it first as a 2D particle replica and
reproduce the book's numbers. Then fly it on vehicles. Then take it to 3D. A
2D replica is what makes a later vehicle or 3D result interpretable.

---

## 1. What reading the whole book changed

These correct or extend the plan. Each is backed by the chapter notes.

1. **Ch. 13 is four mechanisms, not "friction".** In order of cost:
   - **AR damping η** (Eq. 13.9–13.10): scale the force by
     η = (|D − r|/D)^p_d for r < 2D, then stop the vehicle when |ΣF| falls
     below a threshold. This is a two-line change and the cheapest jitter fix.
   - **Adaptive friction** (Eq. 13.23), with k_more/k_less > 10.
   - **Static friction** (Eq. 13.25). Its printed condition is dimensionally
     odd; use μ·m·g < |ΣF·t̂|.
   - **Adaptive speed cap** near obstacles (Eq. 13.24). Its gain ratio is
     reversed: k_less/k_more > 10.

   The book gives ratios but no absolute gains. Build all four as separate
   switches (old behaviour at 0) and measure them one at a time. With η and
   the stop threshold the Pioneers "settle into fixed lattice formations"
   (PDF 454). Our expectation, not the book's, is that η alone makes the
   Newtonian drones settle like LJ, because both are then smooth through
   zero force at D.
2. **Fixed-wing is not a dumbbell.** §13.5 says a vehicle that can only turn
   needs a *single* heading particle; that is the torque law of §13.3
   (Eq. 13.15–13.18), which the chapter applies to its UAVs. The dumbbell
   (Eq. 13.19–13.22) is for vehicles that drive forwards and backwards.
3. **"APO from altitude" should build on Ch. 19, not Ch. 18.** Ch. 18's APO is
   an abstract 50-D optimiser: it collapses onto the best particle and shares
   fitness all-to-all. Ch. 19's APO is the triangle formation plus a pairwise
   fitness force (apoF, within 1.5D). It is local, deterministic and the same
   under rotation, and Ch. 19 calls it "a very simple modification" of the
   formation code. Sensing from altitude is our own idea (★); neither chapter
   mentions altitude.
4. **Kinetic theory (Ch. 4.4, Ch. 7) is velocity-based, with no forces.**
   Nothing in it oscillates about a switch, so it should not jitter on drones.
   That makes it a good contrast case for Ch. 13. Ch. 7 is entirely 2D, so 3D
   is our extension.
5. **The evolved chain law (Ch. 12) is nearly always repulsive.** This is our
   inference, not the book's statement: the evolved minor axis (95.7) exceeds
   the 60-pixel sensing range, so robots in range almost always repel, and the
   chain holds together through backflow pulses. Expect it to jitter on drones and to need
   the Ch. 13 mechanisms.
6. **Ch. 14 is not self-contained.** It does give the offline world (900×700,
   40 robots, 90 obstacles, D 50, Vmax 20), the operators (fitness-proportional
   selection, one-point crossover, Gaussian mutation) and the fitness rule
   (three equally weighted penalties for collisions, cohesion and reaching
   within 4D of the goal; Eq. 14.5, PDF 477–480). It does not give the penalty
   sizes, population size, generations, mutation σ, the Daedalus reward update
   or a definition of "stuck". The only evolved LJ values in the book are on
   the Fig. 15.1 screenshot (PDF 519). Their robot–robot force cap (1.08) is
   about 3.6× below Fig. 14.3's (~3.9), while the obstacle cap (4.32) matches
   Fig. 14.4. Hettiarachchi's thesis fills some
   of this (see the thesis digest).
7. **BPP's `math.random` is the generator the appendix warns about, and a fix
   already exists.** BPP links Lua 5.1, whose `math.random` calls glibc
   `rand()`, i.e. `random()`. Run inside Lua 5.1 with Listing A.1's sampling
   (S extra calls per accepted point, 10⁶ points, 36 bins), it fails at S = 25
   (χ² 321) and S = 27 (χ² 409) against a 99.9% cut of 66.6. The Marsaglia
   multiply-with-carry generator already in `Uniform_Coverage.lua` passes at
   every S tried (χ² 26–41). It is local to that script, though: the
   formations and `quadcopter/swarm.lua` still call `math.random`, and
   Uniform Coverage seeds from `os.time()`. G2 is therefore a small job: move
   the generator into a shared module and give it a seed setting.
8. **The Maxelbot sensor is planar.** Its parabolic cones confine sound to a
   horizontal plane (Ch. 10.5.4.1). A Maxelbot-faithful 3D swarm must either
   fly in levels or assume a different (4-receiver) sensor. Treat that as a
   design decision, not an automatic upgrade.
9. **Clustering doesn't explain the 2D Newtonian jitter, but 3D needs a
   check.** Eq. 3.4 gives the clustering threshold G_t = Fmax·D^p/(2√3) for the
   triangle, and Eq. 3.5 gives Fmax·D^p/(2+2√2) for the square. The 2D drone
   defaults are below it (G 1500 against G_t 2368 triangle and 1699 square), so
   drones don't share nodes. The 3D square uses G 7500, which is above the 2D
   formula's 5492. A 3D G_t has not been derived, so measure it with a G sweep.
10. **Missing from the plan entirely:**
    - Ch. 2's integrator tests;
    - Ch. 4's Couette flow;
    - Ch. 5's local oriented potential fields (four formations without virtual
      colours, plus a gripper and a V that changes shape);
    - Ch. 10's sensor and vehicle stack;
    - Ch. 16's heterogeneous swarm design (rings, protection, surveillance,
      tracking);
    - Ch. 17's two perfect-hexagon methods;
    - Ch. 1's small demos (magnets chain, cooperative pull).
11. **The book's code listings contain bugs; don't copy them.**
    - Ch. 6: the APO sign in Listing 6.3 is reversed relative to Listing 6.4.
    - Ch. 7: speed `max(…, 6)` should be `min`, and Listing 7.3 draws collision
      angles from a half-circle only.
    - Ch. 3: the Hooke cap applies to the attractive side only.
    - Ch. 13: the signs of Eq. 13.1 contradict the prose.
    - Ch. 18: Theorem 18.1's characteristic equation has a sign typo.
    - Ch. 9: the time units are inconsistent.

    Each chapter note lists its own.

---

## 2. Shared groundwork

Most chapters need the same pieces. Build each once.

| ID | Piece | Needed by |
| --- | --- | --- |
| G1 | **Verification monitors:** COM drift, linear and angular momentum, energy. A Lua integrator with controllable Δt for particle tests | 2, 3, 4, and every particle replica |
| G2 | **RNG module:** move the multiply-with-carry generator from `Uniform_Coverage.lua` into a shared module, use it in the formations and the quadcopter harness, add a seed setting (not `os.time()`), and keep the appendix check as a regression test | 4, 7, 11, 12, 15, 17, 18, 19, A |
| G3 | **Headless batch runner:** seeds × configs, CSV out, 2 jobs in parallel, no drawing | 4, 6, 7, 9, 11, 12, 14, 15, 17, 18, 19 |
| G4 | **Velocity commands** for the quad controller (fly this velocity, not this waypoint) | 4.4, 7, 11, 13, 17 |
| G5 | **Point-mass vehicle with limits:** speed, acceleration and lag as parameters, for large swarms | 7, 11, 15, 17 |
| G6 | **Scalar fields:** analytic functions, grids and diffusion, drawn as a ground texture or 3D slices | 1.5, 6, 8, 9, 10, 19 |
| G7 | **Neighbour sensing model:** range and bearing noise, maximum range, token-ring staleness (120 ms × N), 1-bit/packet payload, a Maxelbot preset calibrated to Fig. 10.14 | 3.4, 6, 10, 11, 12, 15 |
| G8 | **Rays:** line of sight between agents, and IR, sonar-ring and laser rangefinders (Bullet ray tests) | 5, 7, 9, 10, 11, 12, 13, 14 |
| G9 | **Force-law table** keyed by (source type, target type): asymmetric, with wildcards and virtual particles, and one sign convention | 3.4, 3.5, 5, 16, 17 |
| G10 | **Ground vehicles:** skid-steer Maxelbot (MMP-5) and differential-drive Pioneer 3-AT | 9, 10, 11, 12, 13 |
| G11 | **Water vehicles:** a holonomic round ASV (Voith–Schneider), then an AUV | 6, ★9 |
| G12 | **Fixed-wing aircraft** (constant speed, bank limit) with the heading-particle torque law, plus the dumbbell agent | 3.1 ★, 13 |
| G13 | **Worlds:** wall polygons from vertex lists, corridors, mazes, and an obstacle-density generator | 4.3, 7, 11, 12, 14, 15 |
| G14 | **Plume model:** Farrell-style puffs with wind, white-noise mixing and obstacles | 8, 9 |
| G15 | **Neighbour messages:** sensed values as well as positions; flooding broadcast | 4.1, 6, 9, 12, 19 |
| G16 | **Metrics:** lattice quality (angles, Delaunay CV), coverage grids and KL divergence, chain metrics (MST), suggested-versus-actual position gap, energy and path length, Q versus P | all |
| G17 | **Heading-dependent force terms:** elliptical zones, LOPF sectors | 4.2, 5, 12 |

---

## 3. Overview by chapter

| Ch. | Title (author) | Entries | First BPP target | Vehicles | Groundwork | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Nature is lazy (Spears) | 8 | Potential-well height map; Q-vs-P metric | particles, ★ magnets | G6, G3 | new |
| 2 | NetLogo and physics (Spears) | 3 | Springs and solar system as integrator tests | particles, ★ 2 drones | G1 | new |
| 3 | NetLogo and physicomimetics (Spears) | 7 | Check the existing formations against the book; add Hooke, honeycomb, events | particles, quads | G1, G9, G16 | partly |
| 4 | Pushing the envelope (Spears) | 5 | Couette flow (2 closed forms); perfect square | particles, quads | G1, G3, G4, G15, G17 | partly / plan / new |
| 5 | Local oriented potential fields (Bravi et al.) | 9 | Square, line, star, tree by sector forces | holonomic particles, quads | G9, G17 | new |
| 6 | Bioluminescence (Karlsson et al.) | 7 | Slime-mould field + APO swarm, min and max tasks | particles, ASV, ★ AUV | G3, G6, G11, G15 | plan |
| 7 | Gas-mimetic swarms (Kerr) | 6 | Three theory checks, then KT vs Default vs Ant | particles, quads, ground robots | G3, G4, G8, G13 | plan |
| 8 | Fluxotaxis theory (Spears, Thayer, Zarzhitsky) | 6 | 3D closed-form unit tests | — | G6 | plan |
| 9 | Fluxotaxis experiments (Zarzhitsky) | 14 | Puff plume + 7-robot and swarm fluxotaxis | particles, Maxelbots, quads | G3, G8, G14, G15 | plan |
| 10 | What is a Maxelbot? (Maxim) | 13 | Trilateration noise model + token ring | Maxelbot | G7, G8, G10 | new |
| 11 | Uniform coverage (Maxim) | 13 | KL metric, wall-only control, f = 0.6 | particles, Maxelbot, quads | G3, G13, G16 | partly |
| 12 | Chain formations (Maxim) | 18 | Listing 12.4 maze with the evolved law | particles, Maxelbots, quads | G3, G7, G8, G13, G17 | plan |
| 13 | Motion control of constrained agents (Apker, Potter) | 13 | η, adaptive and static friction on the drones | quads, Pioneer, fixed-wing | G4, G10, G12 | plan (next) |
| 14 | Adaptive learning, Daedalus (Hettiarachchi) | 7 | Offline three-law LJ obstacle course | particles, quads | G3, G8, G13 | plan |
| 15 | Statistical scouts (Spears et al.) | 10 | Bernoulli vs Bayes on the Ch. 14 world | particles (drones for show) | G2, G3, G13 | plan |
| 16 | Swarm design considerations (Wiegand, Ellis) | 9 | Type table; rings; protection | particles, quads | G9, G16 | new |
| 17 | Swarm engineering (Kazadi) | 9 | Hexagon Methods 1–2; quark model | particles, quads | G2, G3, G4 | plan / new |
| 18 | APO for global optimisation (Xie, Tan, Zeng) | 8 | Table 18.2 as a headless benchmark | — | G2, G3 | new |
| 19 | AP for noisy nonstationary environments (Spears) | 13 | apo.nlogo demo, N × D table, tracking | particles, quads | G3, G6 | plan |
| A | Anomalous random() (Spears, Green) | 4 | RNG regression test and demo | — | G2 | new |

---

## 4. Every entry, chapter by chapter

Each row lists what the entry becomes in BPP. The chapter note has the full
detail.

### Ch. 1 — Nature is lazy (PDF 34–57) · `book/ch01.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 1.1 | Swarm baseline P = 1 − Π(1 − pᵢ) versus measured Q | 37–38 | Standard summary line in the batch runner (G3) | new |
| 1.2 | Cooperative pull (video) | 38 | Ground robots or ★ quads with tethers moving a payload | new |
| 1.3 | Magnets self-organise into a chain (video; 39 + 1 dropped) | 42 | Rigid discs with dipole force and torque | new ★ |
| 1.4 | Compass construction of a triangular lattice | 44–45 | Ground-truth placement; ★ 3D sphere intersections | new |
| 1.5 | Rubber-sheet potential wells, incremental and batch | 45–48 | Live potential height map under 7 particles (G6) | new |
| 1.6 | MAV hexagonal sensing grid | 40 | Done as the drone triangle; add a grid-quality score | done |
| 1.7 | Least action | 41–44 | Energy and path length as standard metrics (G16) | new |

### Ch. 2 — NetLogo and physics (PDF 58–85) · `book/ch02.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 2.1 | `spring1D`: Hooke oscillation, momentum 0, energy flat, friction drains it | 58–72 | Integrator regression test (G1) | new |
| 2.2 | `spring2D`: angular momentum conserved, centrifugal stretch > 2D | 73–77 | Test; ★ 3D off-plane spin; ★ 2 drones on a virtual spring | new |
| 2.3 | `solar_system`: Δt failures, velocity cap fails, force cap works (precession) | 78–85 | Test; ★ one drone orbiting under a capped 1/r² law (velocity cap = drone speed limit) | new |

### Ch. 3 — NetLogo and physicomimetics (PDF 86–123) · `book/ch03.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 3.1 | Boids (`flock`): turn caps 5/3/1.5°; snapshots at 546, 1,309, 78, 42 steps | 86–95 | Constant-speed particles; ★ 3D boids on quads or fixed-wing | plan |
| 3.2 | Hooke lattice (`formation_hooke`): k 0.5, Fmax 1; fails at Fmax 3 and 5; kill and birth | 96–103 | Particles → drones; reproduce the failures too | plan |
| 3.3 | Split-Newtonian triangle, G_t = Fmax·D^p/(2√3), hysteresis, 50 → 21 nodes | 103–108 | Done; add a G_t monitor, a G sweep and a 3D G_t measurement | partly |
| 3.4 | Square with two types, defect removal by noise, 500 particles | 108–113 | Done; add annealing, type flips, toggling, a quality metric; ★ NaCl in 3D | partly |
| 3.5 | Honeycomb: √3 renormalisation, 120°/60° repair, square↔honeycomb toggle | 113–115 | Particles → one altitude; ★ diamond lattice | plan |
| 3.6 | Goal and obstacles; Disable One; abandon threshold goalF > Fmax | 115–121 | Done; add Disable One, the threshold test and a 12-disc wall | partly |
| 3.7 | Hardware requirements (GPS, IR, trilateration) | 121–123 | Sensing model (G7, G8) | new |

### Ch. 4 — Pushing the envelope (PDF 124–157) · `book/ch04.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 4.1 | Perfect formations (`formation_perfect`): (m, n) slots; the triangle breaks Newton's third law | 124–130 | Square first (momentum-clean), then triangle; ★ (m, n, k) cube; the author's 3 open questions | plan |
| 4.2 | Chains (`formation_chain`): elliptical law; Table 4.1 (561 → 350) | 131–138 | Particles with heading (G17), 50-run batches; ★ prolate spheroid in 3D | plan |
| 4.3a | Coverage baseline (`uniform`): 84×84, 9 cells; Table 4.2 | 139–144 | Existing particle port; check against Table 4.2 | partly |
| 4.3b | Mean free path (`uniform_mfpl`): bound 17⅓; Fig. 4.19 dip at 53–65 | 144–147 | Check against Fig. 4.19; ★ 27 cells in 3D | partly |
| 4.4 | Couette flow (`kt`): slope V/6 with r > 0.999; v̄ = 1.2617√T (theory 1.2533) | 147–156 | Particles (two closed-form tests) → point mass → quads; ★ 3D slab | new |

### Ch. 5 — Local oriented potential fields (PDF 160–175) · `book/ch05.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 5.1 | Square deployment by 8 sector forces (no virtual colours) | 164–165 | Particles → drones; compare defects with Ch. 3's square | new |
| 5.2 | Linear deployment | 165 | Same machinery | new |
| 5.3 | Star with leader, arms and levels | 166 | Same; ★ 3D star with 4 or 6 arms | new |
| 5.4 | Star "gripper" (arms closing by ±γ) | 171 | ★ Drones grasping a rigid payload | new |
| 5.5 | Tree / V with levels | 167 | ★ Flying V of drones | new |
| 5.6 | V that changes shape (α changed at run time) | 171 | Same | new |
| 5.7 | Matarić behaviours in AP (wander, follow, disperse, aggregate, home, angularity) | 162–168 | A behaviour library on the formation code | new |
| 5.8 | Holes and choice of starting formation | 171–173 | Measure holes against the starting lattice | new |
| 5.9 | "Angle of attention" (occluded view) | 174 | Ray-cast occlusion share per formation (G8) | new |

The chapter gives no numbers, so the port defines its own parameters and
metrics.

### Ch. 6 — Bioluminescence (PDF 176–223) · `book/ch06.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 6.1 | Dinoflagellate field generator (slime mould, 290/400/510 dinos) | 183–188, 200 | Grid field + drawing (G6); ★ 3D volume, currents | plan |
| 6.2 | ASV swarm: split-Newtonian + APO + goal (only drones with neighbours feel the goal) | 188–192 | Particles → ASVs | plan |
| 6.3 | Force balance: goalF < 0.2598, apoF < 0.13 | 196–198 | Batch sweeps | new |
| 6.4 | Max/min tasks: rising H1, U-shaped H2 with N = 6 best; time curves; 1295/1313/1292 ticks with no chemical | 198–209 | ~12,000 particle runs (G3); then ASVs | plan |
| 6.5 | Multi-drone simulator (asynchronous clocks, comms, fuel) | 210–218 | Our harness plus G7, G15 and fuel accounting | plan |
| 6.6 | 20-drone plume demo | 216–217 | Demo | plan |
| 6.7 | Holonomic ASV hull (18″, two Voith–Schneider propellers) | 218–222 | New vehicle (G11); ★ AUV next | plan |

### Ch. 7 — Gas-mimetic swarms (PDF 224–253) · `book/ch07.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 7.1 | KT controller: Rayleigh/Gaussian wall rebound, 15″ collision zone, 24-sonar ring | 228–236 | Particles → velocity-commanded quads (G4, G8) | plan |
| 7.2 | Uniform density at rest, error < 10% | 239–240 | Batch | plan |
| 7.3 | Mean speed versus T, error < 2% | 240–241 | Batch; ★ 3D Maxwell √(8kT/πm) | plan |
| 7.4 | Profiles with one moving wall (linear) and two (flat), against obstacle density | 241–243 | Batch; decide one- vs two-sided explicitly | plan |
| 7.5 | Default and Ant baselines | 244–246 | Particles; pheromone grid | new |
| 7.6 | KT vs Default vs Ant: KT covers ~90% in about a third of Ant's time | 246–251 | 1000″×5000″ corridor, 50×250 grid; ★ 3D canyon or tunnel | plan |

### Ch. 8 — Fluxotaxis theory (PDF 254–281) · `book/ch08.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 8.1 | Task split; the swarm as a finite-difference grid | 256–264 | Design note | plan |
| 8.2 | Emitter test: positive outward flux for time τ | 267–268 | Termination rule for Ch. 9 | new |
| 8.3 | GDMF navigation law | 269–271 | Core law | plan |
| 8.4 | Anemotaxis overshoots; fluxotaxis stops at the emitter | 272–273 | Analytic test | new |
| 8.5 | Continuous emitter: GDMF ∝ r⁻³ against gradient ∝ r⁻² | 275–277 | 3D closed-form unit test | new |
| 8.6 | Single puff: gradient → 0 at the emitter, GDMF → ∞ | 277–280 | 3D unit test (the note re-derives the garbled formula) | new |

### Ch. 9 — Fluxotaxis experiments (PDF 282–331) · `book/ch09.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 9.1 | 1 versus 3 Maxelbots on ethanol: 22% vs 60% success | 285–286 | Small hardware replica (G10, G14) | new |
| 9.2–9.3 | Smoke around a robot; 32-sensor flume | 287–288 | ★ downwash stirring the plume | new |
| 9.4 | Finite-difference stencils | 291 | Library | plan |
| 9.5 | Puff plume model | 291–295 | G14, the largest single build. The app's Chemical Plume Tracing is ported from Zarzhitsky's C/GTK tool (MapGen/PlumeGen/TraceGen) and is the best source for the constants the book omits | plan |
| 9.6 | LJ variant F = D/r² − D^1.7/r^2.7 | 296–299 | Add to the force-law table | new |
| 9.7 | Simulator loop, collision avoidance overrides tracing | 297–300 | Harness | plan |
| 9.8 | 7-robot hexagon: casting, chemotaxis, anemotaxis, fluxotaxis | 300–306 | Particles → quads | plan |
| 9.9 | Swarm versions (45° casting, flux toward each neighbour) | 306–312 | Unchanged in 3D: the cheapest route to 3D | plan |
| 9.10 | Exp. 1: success 74.6% fluxotaxis (Table 9.3) | 312–315 | Batch | plan |
| 9.11 | Exp. 2: obstacles, emitter enclosed 49.1% of the time | 315–318 | Batch | plan |
| 9.12 | Exp. 3: 7–70 robots, 40,500 runs (Tables 9.4–9.5) | 318–323 | Batch (subset) | plan |
| 9.13 | Exp. 4: 10–150 robots (Table 9.6) | 323–326 | Batch; ranking reverses against 9.12 (book inconsistency) | plan |
| 9.14 | Urban demo | 328–329 | ★ 3D city with source height | plan |

### Ch. 10 — What is a Maxelbot? (PDF 332–371) · `book/ch10.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 10.1 | Closed-form trilateration (6″ L) | 333–335 | Sensor model core; ★ 4-receiver 3D version | new |
| 10.2 | Multi-hop coordinate sharing | 335 | G15 | new |
| 10.3–10.5 | SRF04 accuracy; wavefront jitter fixes; range 2 → 4 → 9–11 ft | 336–344 | Noise and range parameters | new |
| 10.6 | Parabolic cones: sensing is planar | 345–346 | Elevation limit in 3D (decision) | new |
| 10.7–10.8 | RF Manchester link; module timing | 345–351 | Latency and drop model | new |
| 10.9 | Grid test: mean error 0.6″, max 1.2″; ≤ 11% at 9–11 ft | 351–352 | Calibration target for G7 | new |
| 10.10 | Token ring, 120 ms per slot, recovery | 352–355 | Staleness scheduler; ★ how large N can grow at drone speeds | new |
| 10.11 | One robot moves at a time (centralised design) | 356–357 | ★ Sequential update mode as a jitter test | new |
| 10.12 | Localisation I/O (x, y, heading byte) | 357–361 | Neighbour-table format | new |
| 10.13 | MMP-5 skid-steer base, IR 10–80 cm, compass, temperature; 26″ follower | 361–370 | Ground vehicle (G10); ★ heat-source follower | new |

### Ch. 11 — Uniform coverage (PDF 372–397) · `book/ch11.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 11.1–11.3 | Maxim's simulator, cell tiling, KL metric (natural log) | 373–376 | Metric (G16) | partly |
| 11.4 | Markov-chain existence proof | 376–377 | Analytic test | new |
| 11.5 | Turns at walls only: centre least visited (negative control) | 378–379 | Particles | new |
| 11.6 | Mean-free-path turns at f = 0.6 × cell: KL 0.000060 | 379–381 | Particles (ported, check KL) | partly |
| 11.7 | Mean free path theory 0.6518 (0.6079 with buffer) | 380–383 | Closed-form check; ★ 3D ≈ 0.77 edge | new |
| 11.8 | 12 environments × 5 cell sizes (Table 11.1) | 383–386 | G13 (most layouts must be rebuilt) | new |
| 11.9 | Multi-robot formula 1 − (1 − 1/C)^N | 384 | Check with N drones ★ | new |
| 11.10a–c | Hardware runs: 5×5 ft, 5×15 ft, L-shape | 384–396 | Maxelbot replica (G7, G10) | new |
| — | 3D coverage, altitude bands, per-minute scoring | — | ★ from the plan | plan |

### Ch. 12 — Chain formations (PDF 398–443) · `book/ch12.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 12.1–12.3 | Elliptical law, backflow force, front tangential force | 399–402 | Particles (G17) | plan |
| 12.4 | EA with 11 evolved parameters (Listing 12.2) | 402–404 | Use the published values | plan |
| 12.5–12.7 | Maxelbot simulator, 35-vertex maze (Listing 12.4), metrics, 9 environments | 404–413 | G13, G16 | plan |
| 12.8–12.10 | Exp. I scalability, II noise, III add then kill | 414–418 | Batch, 10 seeds | plan |
| 12.11 | 35-step backflow pulse test | 419 | Check | new |
| 12.12 | Ideal chain length (closed form) | 419–421 | Check (the book's example gives 37; the formula gives 38.5) | new |
| 12.13–12.16 | Chain-list protocol, display, laptop link, token loss | 422–428 | G15; ★ chain as a comms relay | new |
| 12.17 | Static Maxelbots: line, L, U at 2, 4, 6 ft | 429–436 | Replica (G10) | new |
| 12.18 | Dynamic: open floor, 5×14 ft corridor, L corridor | 436–442 | Replica; then ★ 3D shafts on quads | plan |
| ★ | Chain applications: relays in tunnels, mines, caves, garages, urban canyons, stairwells, over buildings, into pits; maze exploration; map carried back to base; branching at junctions; loops that reconnect; wall maps from range hits. Score: does the line-of-sight link hold? | — | Quads after the 2D replica (see §5) | new |

### Ch. 13 — Motion control of constrained agents (PDF 444–471) · `book/ch13.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 13.1–13.2 | Point-mass reachable space; the discontinuity at D | 447–448 | Explains the Newtonian jitter | done (observed) |
| 13.3–13.4 | Differential-drive and Pioneer reachable space | 449–453 | Plots (G10) | new |
| 13.5 | **AR damping η + stop threshold** | 453–454 | **First fix on the drones** | new |
| 13.6 | "Triangle of death" | 454–456 | Ground robots | new |
| 13.7–13.8 | Fixed-wing reachable space (13 m/s, 20° bank); single-attractor behaviours. Eq. 13.14 gives a ~101 m turn radius, which matches Fig. 13.16's loops; a coordinated turn would give ~47 m | 457–459 | G12 | new |
| 13.9 | Heading-particle torque law | 460–462 | Fixed-wing (G12) | plan (corrected) |
| 13.10 | Dumbbell agent | 462–463 | Pioneer | plan (corrected) |
| 13.11 | **Pioneer recipe: adaptive friction (13.23), caps, adaptive cap (13.24), static friction (13.25); 3–5-robot camera ring with three-point turns** | 463–465 | **Next build on the drones**; ring on Pioneers | plan |
| 13.12 | 5 UAVs and 10 targets, gravity vs torque law | 465–467 | Fixed-wing | new |
| 13.13 | Four-step design procedure | 466–468 | Checklist | new |

### Ch. 14 — Adaptive learning, Daedalus (PDF 472–505) · `book/ch14.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 14.1 | Offline EA for three LJ laws (Table 14.2 target) | 475–484 | Particles; values from Fig. 15.1 | plan |
| 14.2 | 50 robots flow round a large obstacle | 483 | Particles → drones | partly |
| 14.3 | Offline law in the 5-goal corridor: 51.66% survive | 485–488 | Batch | plan |
| 14.4 | Line of sight between robots | 489–490 | G8 | plan |
| 14.5 | Mutation-rate groups, Approaches 1 and 2 (48.3 → 68.3%) | 491–497 | Daedalus loop | plan |
| 14.6 | Survival against obstacle density (Tables 14.7–14.10) | 497–500 | Batch, the cleanest numeric target | plan |
| 14.7 | Future: stuck robots switch to the gas model | 503 | ★ LJ → KT hybrid escape | new |

### Ch. 15 — Statistical scouts (PDF 506–535) · `book/ch15.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 15.1–15.2 | Bernoulli and Bayes formulas (7 priors; closed form) | 511–517 | Library | plan |
| 15.3 | Navigation simulator: 800×600, 1,500 steps | 517–519 | The Ch. 14 world | plan |
| 15.4 | Ground truth from 1,000 runs, MSE | 519–524 | Batch (G3); environments with p = 0.1/0.5/0.9 to design | plan |
| 15.5–15.8 | Hypotheses 1–4 (prior, more scouts, scalability, difficulty) | 524–531 | Batch | plan |
| 15.9 | LJ scouts predict better than Newtonian scouts | 532 | Batch, both laws | new |
| 15.10 | Porting to real robots | 533 | ★ cascade crashes on drones | plan |

### Ch. 16 — Swarm design considerations (PDF 536–559) · `book/ch16.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 16.1 | Split-Newtonian law with a mass exponent | 540–541 | Force-law table (G9) | new |
| 16.2 | Two types make rings of any radius | 541–542 | Particles → drones; ★ spherical shells | new |
| 16.3 | Virtual particles | 542 | G9 | new |
| 16.4–16.5 | Asymmetric type-to-type laws; graph-based design | 542–550 | G9 | new |
| 16.6 | Resource protection (3 inner + 6 outer) | 543–552 | Demo; ★ drones guarding a VIP | new |
| 16.7 | Multi-field surveillance | 545–552 | Demo | new |
| 16.8 | Covert blind-spot tracking | 546–553 | Demo | new |
| 16.9 | Model-vs-vehicle metrics: suggested-vs-actual gap, settling time, lattice CV | 554–557 | **Acceptance metrics for the Ch. 13 work** | new |

### Ch. 17 — Swarm engineering (PDF 560–592) · `book/ch17.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 17.1–17.3 | Method; hexagon energy; single hexagon is the minimum | 560–572 | Theory and checks | new |
| 17.4 | Basic run: energy plateaus with defects | 572–574 | Particles | new |
| 17.5 | Method 1: synchronised drift | 575–577 | Particles | new |
| 17.6 | Method 2: edge-agent kicks, hexagon in every one of > 10,000 runs | 578–580 | Particles; ★ 3D; compare with Ch. 4.1 | new |
| 17.7–17.8 | Lossless flocking; the informed-agent bias limit (Eq. 17.24) | 580–585 | Sweep the goal-force share on existing formations | new |
| 17.9 | Quark model: coalescence 81%, informed chase, squeeze through a hole | 586–590 | Particles → velocity-commanded quads (G4) | plan |

### Ch. 18 — APO for global optimisation (PDF 596–620) · `book/ch18.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 18.1–18.2 | APO framework; APO1/2/3 laws | 600–606 | Headless Lua | new |
| 18.3 | 50-D benchmark, six functions (Table 18.2) | 606–609 | Batch, plus a control with the optimum shifted from the origin | new |
| 18.4 | Seven mass functions | 609–612 | Batch | new |
| 18.5–18.6 | Convergence theorem; choosing G | 613–616 | Closed-form checks | new |
| 18.7–18.8 | EAPO, VM-APO, LAPO; applications (no data) | 598, 616–618 | Notes | new |

### Ch. 19 — AP for noisy nonstationary environments (PDF 622–644) · `book/ch19.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| 19.1 | `apo.nlogo`: 7 particles find the Rastrigin minimum | 624–626 | Particles + G6 | plan |
| 19.2 | Noise 600,000 and 5,000,000 | 626–627 | Same | plan |
| 19.3 | N × D table (Tables 19.1–19.2) | 627–628 | **Main numeric target** | plan |
| 19.4 | Zoom: feature size against D | 627–629 | Same | new |
| 19.5 | Click to move the optimum (tracking) | 629–630 | ★ drones tracking a moving hotspot | plan |
| 19.6 | d + 1 minimum particles | 629–630 | 4 drones in 3D | new |
| 19.7–19.9 | APO vs PSO 2D: stationary, moving, rotated ellipse | 631–637 | Batch; PSO in Lua | new |
| 19.10–19.13 | 30-D trajectories; PSO → APO hybrid, hand-set and cyclic D | 637–643 | Headless | new |
| — | ★ Sensing from altitude (blur with height), 3D field | — | Our extension of 19.1–19.5 | plan |

### Appendix — Anomalous random() (PDF 646–652) · `book/ch20-appendix.md`
| # | Entry | Pages | BPP | Status |
| --- | --- | --- | --- | --- |
| A.1 | Angle histogram with S extra calls (S = 25, 27 biased; ≥ 28 clean) | 646–648 | RNG regression test (G2); reproduced in BPP's Lua 5.1, and the existing MWC passes | new |
| A.2 | Spatial histogram in the disk | 649–650 | Visual demo: math.random vs the new RNG | new |
| A.3 | Quarter-circle area (unaffected) | 651–652 | Control | new |
| A.4 | drand48 and others are fine | 651–652 | Choice of generator | new |

---

## 5. Ideas from the earlier chat, the plan and the thesis digests

These come from the conversation that produced `AP-3D-vehicles-plan.pdf`, from
that plan, and from the thesis digests' sections on what they mean for the
plan. Each one is missing from, or only touched on, in the tables above. They
are grouped by the chapter they attach to. Source: **chat** = suggested in the
earlier conversation; **plan** = a ★ item in the plan PDF; **digest** = a
thesis digest (author named).

### Formations (Ch. 3, 4, 17)
| Idea | Source |
| --- | --- |
| ★ **Lag acts like heat:** measure how far drone lag shifts the G phase transition (Eq. 3.4), so the drone port gives a result as well as a demo | plan |
| ★ **Gentle annealing on drones:** random kicks that start large and cool to zero, to shake 3D lattices out of glassy arrangements. On drones the kicks are real accelerations, so keep them small | chat |
| ★ **Choose N to suit the shape:** 13, 55 or 147 for icosahedra, or a count that completes whole hexagonal layers | chat |
| ★ **Three-label spin for FCC:** flight levels give ABAB (HCP) stacking; a three-label version of the spin could force ABC (FCC) | chat |
| ★ **Honeycomb's switching costs energy:** the square↔honeycomb switching that escapes the centre trap keeps drones moving. Measure the trade-off between avoiding the trap, energy and wobble | plan |
| ★ **Diamond caveats:** diamond is floppy under distance-only forces, so it is an open question whether the like-class links hold it rigid; the square-escaping switch needs rethinking, because the competing 3D arrangements differ | chat |
| ★ **Honeycomb at one altitude as ground coverage** for cameras or radio: the most area per drone for a given link distance | chat |
| ★ **Perfect Formation on drones:** the momentum checks show how much tracking lag disturbs the formation; test self-repair when switching formations; "One is Born" mid-flight becomes a launch problem; the shared compass fixes the cube's random rotation about the vertical | chat |
| ★ **Ch. 13 in 3D:** the chapter covers only wheeled robots and fixed-wing aircraft; quadcopters in 3D extend it, and its reachable-space analysis needs a second angle (climb rate) | chat |
| **Launch new drones from the side,** so a one-at-a-time launch doesn't climb up through the levels already formed | chat (open item) |

### Optimization and fluxotaxis (Ch. 8, 9, 19)
| Idea | Source |
| --- | --- |
| ★ **Missions for APO on drones:** finding a radiation hotspot or a gas source | chat |
| ★ **Readings from where the drone actually is,** not from its waypoint; downwash stirring a real plume as a noise source | chat |
| ★ **3D plumes:** buoyant gases rise and heavy ones hug the ground; puffs have height and reflect off the ground | chat |
| ★ **Wind changes with height** (slower near the ground); buildings have heights that make wakes and street canyons. Add a height-dependent mean wind as a 3D boundary condition with spin-up, and keep the obstacle mass-relocation rule against building walls | chat; digest (Zarzhitsky) |
| ★ **Source height:** a swarm spread over several altitudes finds the plume's vertical structure; a rooftop vent and a ground spill look the same in 2D. Report source height as a metric by repeating the main tables with the emitter raised | plan; digest (Zarzhitsky) |
| ★ **Wind from tilt and thrust** as a non-intrusive anemometer (fluxotaxis never ran on hardware for lack of one). Model its lag and noise; it may favour fluxotaxis or chemotaxis over anemotaxis | plan; digest (Zarzhitsky) |
| ★ **Downwash on the sensors:** bias each drone's sensed wind and concentration by its own rotor wash and compare with ideal sensors; test sensors mounted above and below the body (placement mattered on a single robot) | plan; digest (Zarzhitsky) |
| **Pseudo-source test:** buildings that create corner sinks or concentration pockets, where chemotaxis is fooled and fluxotaxis should not be | digest (Zarzhitsky) |
| **Flux stopping rule over a 3D shell** (sustained outflux for τ), which the thesis never enabled; the natural way to estimate source height | digest (Zarzhitsky) |
| **Re-derive G_t for 3D packing** (the thesis notes a 308 vs 231 discrepancy in its Eq. 4.7) | digest (Zarzhitsky) |
| **Compare directly with the app's 2D results:** success rate, time to find the source, distance flown; draw the plume as translucent puffs | chat |
| **Share the field code:** optimization and fluxotaxis both find a source in a field with a sensor term on top of the lattice force, so the 3D field sensing and drawing carry from one to the other | chat |

### Bioluminescence (Ch. 6)
| Idea | Source |
| --- | --- |
| ★ **Wake-triggered glow:** real bioluminescence is triggered mechanically, so the vehicles' own wakes light the water. Speed against stealth becomes a control problem | plan |
| ★ **Dinoflagellates migrate vertically** by day and night, and currents add drift to everything. A 3D field of roughly 60 × 60 × 20 cells | plan; chat |
| ★ **Two underwater vehicles:** a multi-thruster ROV-style vehicle (like a BlueROV2) that behaves like an underwater quad, and a torpedo-shaped AUV that cannot hover or move sideways, the harder and more realistic case | chat |
| **Draw the glow** with translucent slices or point sprites | chat |
| **Underwater sensing:** sound at ~1500 m/s; the RF sync pulse won't propagate, so use an optical or clock-synchronised trigger | digest (Kunkel, Heil) |

### Coverage and kinetic theory (Ch. 4, 7, 11)
| Idea | Source |
| --- | --- |
| ★ **Volume coverage** (air sampling, searching a warehouse): in 3D the collision cross-section becomes an area, not a width | chat |
| ★ **Does the linear profile survive collisions that take time?** A quad needs half a second or more to change velocity, which should act like extra viscosity | plan |
| **Lag against collision time:** log commanded-vs-actual velocity lag (time to ~90%) relative to the mean time between collisions; the profile should hold only while the lag is much shorter. Sweep a controller gain to find the failure point | digest (Kerr) |
| **Track the backward-moving fraction** (v_y < 0), which Kerr blames for profile error, and the collision rate per bin | digest (Kerr) |
| **More 3D checks:** profile uniform in z; ⟨½mv²⟩ = (3/2)kT; the full Maxwell speed histogram with a KS test (never tested); altitude bias from floor and ceiling | digest (Kerr) |
| ★ **Fixed-wing drones as gas molecules** (constant speed). Kerr's digest warns that equal speeds break the Maxwell speed distribution, so test the heading distribution instead | plan; digest (Kerr) |
| **Scale:** full quads manage ~100–200 in BPP against the app's 1,000 particles, so expect noisier histograms or use the point-mass vehicle (G5) | chat |

### Chains (Ch. 4.2, 12)
| Idea | Source |
| --- | --- |
| ★ **Where relays matter:** tunnels, mines, caves, parking garages, urban canyons; up a shaft or stairwell, over a building, down into a pit | chat |
| ★ **Chains for exploring maze-like spaces,** not only for holding a link | chat |
| ★ **"Does the relay hold?" as the score:** a link breaks when walls block the line of sight, not only on distance; the app's Max Distance gauge becomes a radio-range check | chat |
| ★ **Heading for a hovering drone:** the ellipse's axis comes from yaw or from a smoothed travel direction. It may decide whether chains stay straight or fold | plan |
| **3D chain details:** front tangential force in a random direction perpendicular to the heading; up/down IR sensors for shafts; acoustic line of sight blocked by walls while RF is not | digest (Maxim) |
| **Reproduce the 2D Maxelbot runs first:** 12 in/s, 3 IR sensors at 9″ range, 5 ft maximum spacing, the 14 ft and 8 + 12 ft corridors | digest (Maxim) |

### Learning and scouts (Ch. 14, 15)
| Idea | Source |
| --- | --- |
| ★ **Drones tune their own settings mid-mission** to cut losses on the obstacle field | chat |
| **Report "lost" (crashed) separately from "hit":** a crashed quad cannot be repaired at the goal. Repeat the safety-zone result (zero collisions, lower reachability) | digest (Hettiarachchi) |
| **Train easy, test hard:** the online world (obstacles ×3, > 16% coverage, Vmax × 1.5, 5 chained goals) is a ready difficulty knob for our field | digest (Hettiarachchi) |
| **Minimal Daedalus:** 13-float genome, worthiness 1000, rule copying on contact within 1.5R and in line of sight, 5% "panic" mutation when stuck, seed rates {1, 3, 5, 7, 9}%; feed the LJ output to the controller as a velocity or acceleration setpoint | digest (Hettiarachchi) |
| **Hardware Hooke repulsion** (IR, range 30, front-arc sensors) as a template for realistic obstacle sensing | digest (Hettiarachchi) |
| **Scouts in two modes:** independent and in formation (same LJ as the swarm); test whether crash cascades break the thesis's "dependence helps" result | digest (Rebguns) |
| **Cost:** ground truth at ~1,000 runs per field is ~17 h with full drones; use G5 or fewer runs | digest (Rebguns) |

### Sensing (Ch. 10; G7)
| Idea | Source |
| --- | --- |
| **Three presets:** "design spec" (Heil, sub-inch within 6 ft), "Maxelbot" (0.6–0.7 in, 2.4–3.5 m, 8.33/N Hz) and "pessimistic" (Heil: σ 3.5 in, 14.5° bearing, drops past 0.6–0.9 m, cut-off at 6 ft) | digest (Heil, Maxim) |
| **Noise on each range, not on the position,** so geometric dilution at distance emerges by itself | digest (Kunkel) |
| **Couple sensing to attitude:** a tilting quad tilts its sound plane; receivers outside it drop out | digest (Heil) |
| **Speed-of-sound calibration parameter** (matters most underwater) | digest (Heil) |
| **Relaying out-of-range positions** with a hop-count "doubt level" (Heil App. B) | digest (Heil) |
| **Cheap baseline:** sector-only bearing (±30°) against full trilateration | digest (Heil) |
| **The 50-sample running average adds lag** that matters for kinetic theory and Daedalus | digest (Heil) |
| **Drops:** 1% acoustic and 0.2% RF; multiplicative U[0.9, 1.1] noise | digest (Maxim) |
| **3D receiver:** a fourth at (0, 0, d), giving z = (b² − e² + d²)/2d (our extension) | digest (Heil, Maxim) |

### Sound, BPP and the app
| Idea | Source |
| --- | --- |
| **Exaggerated pitch:** stretch pitch deviations ~3× on the `emphasis` slider so a climb or hard turn becomes an audible swoop | chat (not built) |
| **Event sounds:** a knock and motor wind-down on a crash; a short chirp on launch and landing | chat (not built) |
| **Info dock pane** in BPP instead of the status line | chat (open item) |
| **Port the Uniform Coverage fixes to the Android app** (±15° cone; dead-end retry) | plan |
| **FIXES item 27** (precompiled-header build bug): documented, not fixed | chat (open item) |

### The capstone mission (plan)
A swarm launches in thirds, top level first, and forms a perfect 3D lattice by
compass and address. Scouts probe a city of buildings to estimate the risk
before the rest follow, adapting their parameters on the way. The swarm then
finds a 3D plume's source and height by fluxotaxis, sensing at several
altitudes, while a chain of drones holds a relay back to the launch point
around corners and over rooftops. Each piece is a task in this map, so it can
be built step by step, with each step a usable demo and a measurable result.

---

## 6. Build order

This revises the plan's order using what the book says.

| Step | Work | Why now |
| --- | --- | --- |
| 0 | **G2 RNG + G3 batch runner + G1 monitors**, then Ch. 2's three tests | Every measurement after this depends on them; small |
| 1 | **Ch. 13 on the drones:** η → adaptive friction → static friction → adaptive cap, each switchable, measured with the Ch. 16.9 metrics on Newtonian 2D/3D over several seeds | The plan's step 1, now with four parts and acceptance metrics |
| 2 | Ch. 3 fidelity checks (G_t sweep incl. 3D, Disable One, Hooke, honeycomb) and Ch. 4.3/Ch. 11 coverage against Tables 4.2, 11.1 and Fig. 4.19 | Cheap; firms up what is already "done" |
| 3 | Ch. 4.1 perfect square → cube, then the triangle; Ch. 17 Method 2 as the alternative | The plan's step 2 |
| 4 | G4 velocity commands + G5 point mass; Ch. 4.4 Couette and Ch. 7 theory checks | Opens all the kinetic-theory and quark work |
| 5 | Ch. 14 offline world → Ch. 15 scouts (particles), then Daedalus | The plan's step 3, in the order the book's dependencies need |
| 6 | Ch. 19 formation APO with G6 fields → ★ from altitude, moving hotspot | The plan's step 4 |
| 7 | Ch. 5 LOPF and Ch. 16 type table: square, line, star, V, rings, protection | New, cheap on the formation code |
| 8 | G7/G8/G10 sensing and ground vehicles → Ch. 10 checks, Ch. 11 and 12 replicas, Ch. 12 chains, then ★ 3D shafts | Hardware-faithful track |
| 9 | Ch. 8 unit tests → G14 plume → Ch. 9 → ★ fluxotaxis 3D | Flagship |
| 10 | G11 ASV → Ch. 6 → ★ AUV; G12 fixed-wing → Ch. 13.7–13.12; Ch. 1 demos; Ch. 18 benchmark | Remaining |

Before porting a task, fetch its `.nlogo` from the book website, read the
matching thesis digest, and check the Android app's version, if it has one. The book's chapters leave out values that the models
and theses contain.
