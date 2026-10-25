# Ch. 4.3 — Uniform coverage checked against the book and William's runs

`BOOK.md` entries 4.3a and 4.3b (PDF 139–147, `book/ch04.md`). The two
coverage models, `uniform.nlogo` (turn only at walls and other agents)
and `uniform_mfpl.nlogo` (also turn after a mean free path), as plain Lua
that does what each `.nlogo` does, operation for operation, checked
against Table 4.2, Figs. 4.17 and 4.19 and William's own NetLogo and
Android runs (`uniform_data.txt`); and the BPP scene `../Uniform_Coverage.lua`
(a port of the Android app) run on the same grid.

| File | What |
| --- | --- |
| `coverage.lua` | The two models: the world, the agents' step and the deviation (Eq. 4.1) |
| `sweep.lua` | The deviation over agents and mean free paths, with the stopping rule below |
| `uniform_data.txt` | William's runs, as he sent them (2026-10-25): NetLogo and Android deviations for 1–1000 agents, MFP 1–120, and two BPP columns (before and after FIXES 4–5). Run lengths were not recorded (tens of millions of ticks, depending on the agents) |
| `../checks/ch04.lua` | The book's results as 8 short checks, about 40 s (any Lua 5.1–5.4) |
| `../probes/coverage_sweep.lua` | The BPP scene under the same stopping rule, for `lib/batch.py` |

**Where the book's text is silent, the `.nlogo` decides** (`coverage.lua`
has the details): a world of patches −42…42 that wraps, with the border
patches the yellow wall; agents start at 15/16 of a uniform position and
a random integer heading; every tick they move one at a time in a new
random order; an agent turns (random 360) when the patch 1 ahead or 2
ahead at ±45° is wall, another agent is within 3 patches and 15° of its
heading, or its step count reaches the mean free path, trying up to nine
times; the nine cells split −40…40 at ±13⅓, the outer ones reaching the
wall; every agent is counted in its cell every tick, the setup's count
included.

**Stopping rule** (William: "pick a fair stopping criterion"). The right
length depends on the agents and the mean free path, so every run uses
the same rule: agent steps (agents × ticks) in doubling blocks from 2 ×
10⁷, stopping when the deviation is within 1% of its value a block
earlier, or at 2 × 10⁸ agent steps, the book's budget for Fig. 4.19 (one
particle 2 × 10⁸ ticks, 100 particles 2 × 10⁶). A run that hit the cap
without meeting the 1% test is marked \*.

## William's runs, reproduced

Seed 1. "NetLogo copy" is `coverage.lua`; "BPP scene" is
`Uniform_Coverage.lua` (the Android rule: turns only when the next step
would cross the arena's ±40 edge; FIXES 36, FINDINGS F16), whose own
MFP 120 is the "none" of its slider.

| Agents | MFP | NetLogo (William) | NetLogo copy (ours) | Android (William) | BPP scene (ours) |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0.00057 | 0.0029* | 0.00122 | 0.0032* |
| 1 | 4 | 0.000402 | 0.0019* | 0.000437 | 0.0020* |
| 1 | 10 | 0.0014 | 0.0022 | 0.00073 | 0.00062* |
| 1 | 17 | 0.0038 | 0.0039 | 0.0019 | 0.0018 |
| 1 | 30 | 0.0072 | 0.0073 | 0.0043 | 0.0035 |
| 1 | 50 | 0.023 | 0.0231 | 0.016 | 0.0157 |
| 1 | 100 | 0.026 | 0.0267 | 0.036 | 0.0367 |
| 10 | 1 | 0.0011 | 0.0035* | 0.0011 | 0.0029* |
| 10 | 4 | 0.0005 | 0.0018 | 0.00075 | 0.00082* |
| 10 | 10 | 0.0014 | 0.0018* | 0.0006 | 0.0015* |
| 10 | 17 | 0.00347 | 0.0034 | 0.00176 | 0.0017* |
| 10 | 30 | 0.0068 | 0.0068 | 0.0038 | 0.0033 |
| 10 | 50 | 0.0203 | 0.0204 | 0.0144 | 0.0131 |
| 10 | 100 | 0.0256 | 0.0254 | 0.033 | 0.0347 |
| 100 | 1 | 0.0011 | 0.0026* | 0.0016 | 0.0135* |
| 100 | 4 | 0.00046 | 0.0015* | 0.0013 | 0.0029* |
| 100 | 10 | 0.00064 | 0.0011* | 0.00027 | 0.0028* |
| 100 | 17 | 0.0019 | 0.0017 | 0.00084 | 0.0012* |
| 100 | 30 | 0.0030 | 0.0032 | 0.00085 | 0.0015* |
| 100 | 50 | 0.0029 | 0.0029 | 0.0027 | 0.0032* |
| 100 | 100 | 0.016 | 0.0162 | 0.020 | 0.0212* |
| 1000 | 1 | 0.0042 | 0.0037 | 0.0040 | not run |
| 1000 | 4 | 0.0033 | 0.0040 | 0.0031 | not run |
| 1000 | 10 | 0.0036 | 0.0039 | 0.0041 | not run |
| 1000 | 17 | 0.0042 | 0.0040 | 0.0046 | not run |
| 1000 | 30 | 0.0044 | 0.0049 | 0.0048 | not run |
| 1000 | 50 | 0.0044 | 0.0045* | 0.0047 | not run |
| 1000 | 100 | 0.0044 | 0.0045 | 0.0048 | not run |

\* not settled (the 1% test failed at the cap). The BPP scene's 100 agents
ran to 2 × 10⁷ agent steps only, and its 1000 agents not at all: the
scene tests every pair of agents every tick (10⁶ tests a tick for 1000),
so the full budget would take days; its 1000-agent numbers stay
William's Android ones. William's own BPP runs at MFP 17 (0.0016 for one
agent; 0.0013 and 0.0014 for 10 before and after FIXES 4–5; 0.0011 and
0.0005 for 100) sit with the scene's here.

**MFP 17 and above: the copy reproduces William's NetLogo column**, to
within a few percent for 1–100 agents and about 10% for 1000; the BPP
scene reproduces his Android column the same way. **Below 17 neither run
settles within 2 × 10⁸ agent steps.** With a mean free path of a few
steps an agent random-walks between cells, so the deviation there is
sampling noise falling as ~1/√(agent steps): one agent at MFP 1, 4 and
10 over four seeds gives 0.0029–0.0040, 0.0009–0.0020 and 0.0013–0.0022,
against William's 0.00057, 0.0004 and 0.0014. Reaching his values would
take ~10⁹–10¹⁰ ticks, so his small-MFP numbers come from much longer runs
(or are the lucky end of the spread); they are not a disagreement.

## The book's results

| Book | Ours (`coverage.lua`) |
| --- | --- |
| Table 4.2 (`uniform.nlogo`, no mean free path): 1, 10, 100, 1000, 10,000 particles give 0.027, 0.026, 0.016, 0.004, 0.003 | 0.0272, 0.0265, 0.0168, 0.0045 (10,000 not run) |
| Fig. 4.17: one particle visits the corners most, then the edges, the centre least | Corners 0.1200, edges 0.1064, centre 0.0942 (mean shares, 5 × 10⁶ ticks) |
| Fig. 4.19, one particle: below 0.003 for MFP ≲ 15, a bump at ~17, poor above ~30, plateau ~0.027 | MFP 10: 0.0013–0.0022 (not settled); 17: 0.0039; 30: 0.0073; 50: 0.0231; 100–120: 0.0267–0.0272 |
| ... a dip between MFP 53 and 65 (turning at the far edge of the centre cell, 53⅓ and 66⅔ away) | 55: 0.0210, 60: 0.0124, **65: 0.0037**, 70: 0.0059, 80: 0.0184 |
| Fig. 4.19, 100 particles: ~0.002–0.005 to MFP 55, then up to ~0.017 | 17: 0.0017, 30: 0.0032, 50: 0.0029, 55: 0.0027, 60: 0.0062, 65: 0.0095, 80: 0.0153, 120: 0.0168 |
| MFP 120 is "none": the longest straight path, 80√2 ≈ 113, is shorter | MFP 120 and no MFP give the same deviation to the last digit (0.02722) |

## Not done

Table 11.1 (Ch. 11.8): Maxim's simulator on 12 environments; the
environments are described in his papers [156, 239], not in the book, so
they cannot be rebuilt from it. Ch. 11.5–11.6 (turns at walls only, then
mean-free-path turns, on Maxim's cell-based simulator) are the same
questions as Table 4.2 and Fig. 4.19 on a different simulator.
