# The original NetLogo models

William's NetLogo models for the book, as on the book website
(sites.google.com/view/artificialphysics, page `/netlogo-simulations`),
converted from NetLogo 5 to NetLogo 6. Added to the repo on 2026-10-18 at
William's request, so every port can be checked against its model without
attaching them. They are the reference where the book's text is silent: step
1 of every task (`WORKFLOW.md`) reads the model before the port is written.

William's conversion note: "Used NetLogo 6 to convert previous NetLogo 5
simulations to NetLogo 6. Could not convert lopf.nlogo." So `lopf.nlogo`
(Ch. 5, local oriented potential fields) is not here; its NetLogo 5 version
is on the website.

| Model | Chapter | Ported / checked |
| --- | --- | --- |
| `spring1D.nlogo` | 2.1 | `ch02/Spring1D.lua`; start and update order checked (FINDINGS F41) |
| `spring2D.nlogo` | 2.2 | `ch02/Spring2D.lua`; random-heading start (F41) |
| `solar_system.nlogo` | 2.3 | `ch02/SolarSystem.lua`; speed cap and force cap checked (F15) |
| `formation_newton.nlogo` | 3 | `ch03/models.lua` (line for line); `Formations-Newtonian.lua`: the same split, cap, views 1.5/1.3/1.7, √2 same-spin divisor and friction first, but a like pair's direction from the true distance, where the model's is √2 longer (F74); the defaults differ (F48). No Ch. 13 damping in the model |
| `formation_hooke.nlogo` | 3 | `ch03/models.lua` (line for line; `checks/ch03.lua`) |
| `formation_lj_goal_obs.nlogo` | 3 | `Formations-Lennard-Jones.lua` (not yet checked) |
| `formation_goal_obs.nlogo` | 3.3 | world frame used by `lib/world.lua`'s Ch. 3 presets (F40); goal, obstacles and Disable One in `ch03/models.lua` |
| `honeycomb.nlogo` | 3 | `ch03/models.lua` (line for line; `checks/ch03.lua`, F77) |
| `flock.nlogo` | 3 | not yet |
| `formation_chain.nlogo` | 4 | not yet |
| `formation_perfect.nlogo` | 4 | not yet |
| `kt.nlogo` | 4 (kinetic theory) | `ch04/couette.lua` (line for line; `checks/ch04_couette.lua`, F85, F86): its walls emit hotter than the Rayleigh they draw |
| `uniform.nlogo` | 4.3 | `ch04/coverage.lua` (line for line; `checks/ch04.lua`, F78); `Uniform_Coverage.lua` (via the Android app; wall rule kept by decision, FIXES 36) |
| `uniform_mfpl.nlogo` | 4.3, 11 | `ch04/coverage.lua` (line for line; `ch04/README.md`, F78); measured against BPP (FINDINGS F16) |
| `dinos.nlogo` | 6 (dinoflagellates) | not yet |
| `apo.nlogo` | 19.1 | not yet |
| `dla.nlogo` | not in the book (May 2012): robot recharging after Mullins, "Autonomous Recharging of Swarm Robots" | — |
| `best_fit_circle.nlogo`, `best_fit_circles.nlogo` | not in the book (May 2012): Heil's best-fit circle | — |

Reading a model: the code comes before the first `@#$#@#$#@` line; the
`GRAPHICS-WINDOW` block after it gives the world (its min/max pxcor and
pycor), and each `SLIDER` block gives name, minimum, maximum, default and
step (lines 6–10 of the block). NetLogo's `random n` is an integer 0 … n−1,
and heading 0 is +y, clockwise.
