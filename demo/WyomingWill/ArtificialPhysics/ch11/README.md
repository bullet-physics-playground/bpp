# Ch. 11 — Uniform coverage: the mean free path in 2D and 3D

Entry 11.7 of `BOOK.md` (Sec. 11.3, PDF 380–383, Listing 11.4,
Eqs. 11.2–11.4). The mean free path is the mean distance a robot travels to
enter an adjacent cell: the robot uniform in a unit cell, the entry point
uniform on the side it shares with the next cell. A coverage run on cells of
size c uses a mean free path of f × c.

In 3D the cells are cubes with face neighbours: the robot is uniform in a unit
cube and the entry point uniform on a shared face.

## Results

| Case | f (exact) | Closed form | Simulated, 10⁷ samples (entry at 1.001) | Exact at 1.001 | z |
| --- | --- | --- | --- | --- | --- |
| 2D | 0.651757 | (2 + √2 + 5 ln(1+√2)) / 12 | 0.652431 ± 0.000087 | 0.652501 | −0.80 |
| 2D, 5% buffer | 0.607939 | — | 0.608751 ± 0.000081 | 0.608693 | 0.71 |
| **3D** | **0.771992** | **(4 + 17√2 − 6√3 − 7π + 21 ln(1+√2) + 42 ln(2+√3)) / 90** | 0.772657 ± 0.000084 | 0.772620 | 0.44 |
| **3D, 5% buffer** | **0.713804** | — | 0.714453 ± 0.000078 | 0.714445 | 0.09 |

- **2D reproduces the book:** the integral is 0.651757 (Eq. 11.4) and the 5%
  buffer gives 0.6079, as on PDF 383.
- **3D: f = 0.7720 × cube edge, or 0.7138 with the 5% buffer.** In BPP's
  coverage box (80 units, three cells a side, edge 26⅔) that is a mean free
  path of 20.6, or 19.0 with the buffer, against 17⅓ in 2D.
- **The closed forms** come from an integer-relation search (PSLQ) on the
  integrals computed to 60 digits; they agree to 50 digits. The 2D one equals
  the book's Eq. 11.3–11.4 in one line. The 3D one is very strong evidence but
  not a proof; it uses the same constants as Robbins' mean distance between
  two random points in a cube.
- **The book's printed 0.6517.** Listing 11.4 puts the entry at x₂ = 1.001,
  which raises the mean to 0.6525 (exact, and our simulation agrees). The
  printed 0.6517 matches an entry at exactly 1 (0.65176). The same listing
  run with glibc `random()` (the appendix's generator) also gives 0.6525, so
  it is not the generator; most likely the run used x₂ = 1. Cosmetic.

## How it was done

- `mfp_exact.py` (mpmath): with u = 1 − x₁ uniform and the lateral
  differences triangular on [−1, 1], the integral over u has a closed form,
  leaving a 1D integral (2D case) or 2D integral (3D case) of smooth
  functions. About 40 s.
- `mfp_theory.lua`: Listing 11.4 as written, extended to 3D (a third
  coordinate pair z₁, z₂) and to the buffer, on the shared generator
  (`lib/rng.lua`). `lua5.1 ch11/mfp_theory.lua`, about a minute.
- `checks/mfp_theory.lua`: the simulation within 4 standard errors of the
  exact values, 10⁶ samples per case, about 5 s.

## Choices where the book is silent

- **Buffer in 3D:** the same as in 2D, applied to each lateral axis: the
  robot's depth range is [0.05, 1] and both lateral ranges are [0.05, 0.95].
- **Wall rule:** BPP keeps the Android app's wall rule (turn on touching the
  boundary), not NetLogo's patch probes, by decision; see `FIXES.md` item 36.

## Next

A 27-cell 3D version of Uniform Coverage, swept over the mean free path as
Maxim did in 2D, to check that the best value sits near 0.71–0.77 × edge.
