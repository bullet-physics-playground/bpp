# Ch. 3 — NetLogo and physicomimetics: the formation models checked

`BOOK.md` entries 3.2–3.6 (PDF 96–121, `book/ch03.md`). The book's
formation models, `formation_newton`, `formation_hooke`,
`formation_goal_obs` and `honeycomb` (`../netlogo/`), as plain Lua that does what each
`.nlogo` does, operation for operation, and the book's results checked on
it. The BPP scene `../Formations-Newtonian.lua` is checked at the book's
settings against the same results.

| File | What |
| --- | --- |
| `models.lua` | The four models: split Newtonian (triangle, square and honeycomb lattices, the honeycomb's switching; our 3D version), Hooke's law, the goal, obstacles and the buttons (Kill One, One is Born, Disable One); the lattice measures |
| `../checks/ch03.lua` | The book's results as 28 checks, about two minutes (`lua5.1 checks/ch03.lua`; any Lua 5.1–5.4, the same numbers on each) |
| `../probes/ch03_scene.lua` | The BPP scene at the book's sliders, for `lib/batch.py` |

**Where the book's text is silent, the `.nlogo` decides:** each particle
starts at a normal deviate (sd 20 patches) from the centre, velocity 0;
friction first, then all forces from the positions at the start of the
tick, then every body moves; the goal and obstacles are bodies of mass
100,000 that the particles pull and push (they barely move); a disabled
particle gets the same mass. Two defaults differ between the book and the
model: `formation_newton.nlogo` has G 310 and friction 0.15, the book's
Fig. 3.13 G 400 and friction 0.50 (F48); we use the book's.

**Measures** (`models.lua`): *nodes*, lattice nodes occupied, where
particles closer than D/3 count as one node; *shared*, the share of
particles that share a node (clustered); *nn*, the mean distance from each
particle to the nearest particle at another node, over D; *rg*, the radius
of gyration; *v*, the mean speed (patches per tick).

## The split Newtonian law (Sec. 3.2.2–3.2.3)

| Book | Ours (seeds 1–4) |
| --- | --- |
| G 400 > G_t = 259.81 at Fmax 1: clusters; Fmax 5 (G_t 1299.04): none (Fig. 3.14) | 21–24 nodes for 50 particles; Fmax 5: 50 nodes |
| 50 agents on 21 nodes; 25 removed, 19 nodes remain (Fig. 3.16) | 21 → 16 and 22 → 21 nodes |
| Eq. 3.4: clusters when G > G_t | From the starting cloud: none at 0.9 G_t, 68–80% of the particles clustered at 1.2 G_t |
| Lowering G: clusters loosen, then a sudden break-up near G_t | Lowering G by 0.02 G_t every 200 ticks: all but two pairs gone at 0.94–1.00 G_t (6 seeds); the last pairs, held in lattice defects with more than six neighbours, at 0.80–0.96 G_t |
| Raising G after a stable formation makes no clusters; raising it and adding particles does | Raised to 400: 12% (3 pairs); then 10 particles added: 33–43% |
| Square, Eq. 3.5: G_t2 = Fmax D^p / (2 + 2√2) = 186.4; Fmax 1 clusters, Fmax 5 does not (Fig. 3.18) | Fmax 1: 36–60% shared, Fmax 5: none. **The break-up is at 1.12–1.52 G_t2 (median 1.18), not at G_t2** (below) |
| Momenta conserved despite the discontinuity at D (Fig. 3.10) | \|P\| ~ 10⁻¹⁵, L ~ 10⁻¹³ |

**Why the square lattice breaks up above Eq. 3.5 (FINDINGS F74).** The
book's derivation (after Fig. 3.15): two particles share a node; they
repel each other with Fmax; the ring around them pushes a displaced one
back with G/D^p from every neighbour (the force does not vanish at D), the
neighbours' directions projected on the displacement. The cluster holds
while that restoring force beats Fmax in every direction: G > Fmax D^p /
S, S the smallest sum of |cos| over the neighbours. For the triangle S =
2√3 (displacement at 30° to a bond), Eq. 3.4. For the square the book
takes the four unlike neighbours at D and the four like ones at √2 D as
equal, S = 2 + 2√2. But the model renormalises like pairs' distance (r /
√2) and also divides their direction by that shorter r, so a like pair's
force is √2 longer: the cluster (a like pair) repels with √2 Fmax and the
like neighbours push with √2 G/D^p, S = 4√2, and G_t = √2 Fmax D^p / 4√2 =
Fmax D^p / 4 = 225 = 1.21 G_t2. With the direction taken from the true
distance (`rawDirection`, which is what `Formations-Newtonian.lua` and the
Java app do), the break-up is at 1.02–1.12 G_t2: Eq. 3.5 is right for
that code, and our formula for the `.nlogo`'s.

**3D (ours, F73).** The same argument for close packing (12 neighbours,
FCC or HCP) gives S = 2√6 ≈ 4.90, so **G_t3 = Fmax D^p / (2√6) =
G_t / √2** (183.7 at the book's settings). Measured with the view at 1.3 D:
all but two pairs gone at 0.92–1.12 G_t3, the last at 0.84–0.96 G_t3. The
book's view of 1.5 D reaches the second shell of close packing (√2 D) and
pulls it in: nn 0.64 D against 0.90 D at 1.3 D. Fewer clusters form from a
3D cloud than in 2D: 37–43 nodes at 2 G_t3, against 18–19 in 2D at 2 G_t.

**The BPP scene.** `Formations-Newtonian.lua` switched to 2D with the
book's sliders (G, power 2, forceMax, rad 30, range 1.5, friction 0.5,
timeStep 1), 50 particles, 1010 ticks, seeds 1–3: none clustered at
0.9 G_t; 62–74% shared at 1.2 G_t; at G 400, 19–22 nodes; at forceMax 5,
none, as in the replica (`probes/ch03_scene.lua`). Its own defaults (G
1500, power 2.2, forceMax 1.5, rad 50; 3D G 7500, power 2.5, forceMax 5)
are below their G_t (2366, and 18,042 by the 3D formula), so it does not
cluster.

## Hooke's law (Sec. 3.2.1)

| Book | Ours (seed 1) |
| --- | --- |
| A good lattice by 200 time steps (Fig. 3.9) | nn 0.95 D at 200, 0.99 D at 500, then still (v 0) |
| Fmax 3: the cloud cannot expand (Fig. 3.12) | rg 32 against 80, frozen |
| Fmax 5: unstable, in flux | rg 26, v 11.6 patches per tick |
| k 0.25: works poorly | nn 0.46 D |
| Range 2.5 D: cannot expand ("less is more", Fig. 3.8) | rg 29 |
| Kill One, One is Born: holes, a stable formation; the newborn absorbed | still again after each; the newborn's nearest neighbour at 1.00 D |

## Goal, Disable One and obstacles (Sec. 3.3)

The model's world: 701 × 401 patches, the goal at (−175.25, 0), the
particles starting round (175.25, 0); the goal switched on after 300
ticks. Fig. 3.25's twelve discs and Fig. 3.26's wall are the ones measured
from the figures (`lib/world.lua`, F40).

| Book | Ours |
| --- | --- |
| Goal force 0.25: slow, the lattice settles round the goal; 2.00: fast and compressed (Fig. 3.24) | Centre at the goal after 844 against 102 ticks; rg 48 against 34 |
| A disabled particle's neighbours may stay; goalF must exceed Fmax (the Abandon Goal Force monitor, 1) to pull them away | A lone neighbour: stays at goalF 0.99, leaves at 1.01. **In the formation, 0–2 stay at goalF 0.2–0.5 and none at 0.7 or more (8 seeds): the departing lattice pulls the others off** (F75) |
| 12 discs of size 10: the formation twists through; all reached the goal in that run (Fig. 3.25) | All 50 within 120 patches of the goal after 674–787 ticks (606–637 without obstacles; 4 seeds) |
| Size 50: a wall; the whole formation rotates round its northern end (Fig. 3.26) | All 50 pass north of the wall (4 seeds; at the measured radius 45 too) |

## The honeycomb (Sec. 3.2.4)

`honeycomb.nlogo`: 201 particles, D 20, G = G_t (the model computes it),
Fmax 1, friction 0.5, Δt 1; like pairs (same parity) renormalised by √3
instead of √2, views 1.3 and 1.7 as for the square. *Defects* below are
the particles with two neighbours (0.85–1.15 D) less than 90° apart: none
in a perfect honeycomb (120°), and a particle trapped at a cell's centre
makes 60° (McLurkin's test).

| Book | Ours (seeds 1–2) |
| --- | --- |
| A particle at a cell's centre is caught in a potential well | Honeycomb rule alone: 29–39% defects at 500 ticks, 21–38% still at 3000 |
| Periodically switching between square and honeycomb lets them escape; `honeycomb.nlogo` "provides the details" | The model's switching: 6% at 500 ticks, 4–5% at 3000; 56–64% of the particles with exactly 3 neighbours (the edge has fewer) |
| — | Our periodic switch (100 ticks square, 100 honeycomb, measured after a honeycomb phase): slower, 42–53% at 500 ticks, then 0–10% at 1800–3000, 68–75% with 3 neighbours |

**What the model's switching is (F77).** It is not a switch between two
lattices over time. Each particle counts the neighbours it looks at, in
a new random order every tick, and uses the square rule for 100 of them
and the honeycomb rule for the next 100; with 200 neighbours, every tick
half its pairs (at random) feel the square rule and half the honeycomb.
The force is a random mix, and the lattice it settles in is a hybrid:
unlike neighbours at 0.92 D, like ones at 1.55 D, between the square's
√2 D and the honeycomb's √3 D (pure honeycomb: 0.96 D and 1.65 D). It
works, faster than a true periodic switch. McLurkin's own repair
(perturbing a particle that sees neighbours 60° apart, Fig. 3.22) has no
parameters in the text and is not ported.

## Not yet

The square lattice's annealing
tricks and 500 particles (Fig. 3.19–3.20); boids (Sec. 3.1); Hooke's law
and the events in the BPP scenes and on vehicles.
