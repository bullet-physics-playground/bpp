# The torpedo-shaped AUV

`model.lua` is a torpedo-shaped autonomous underwater vehicle as a
kinematic model at one depth (`BOOK.md` G11; Ch. 13's design procedure,
§13.5). It cannot hover, reverse or move sideways: the case the book's
design procedure is for, and the harder of the plan's two underwater
vehicles (the other, an ROV that hovers, is to come).

| Quantity | Value | Source |
| --- | --- | --- |
| Size | 1.33 m long, 0.191 m across, 30.5 kg | REMUS, Prestero's thesis (2001), Tables 2.1 and 2.3 |
| Cruise speed | 1.54 m/s (3 knots) | Prestero, Table 8.1 |
| Top speed | 2.3 m/s (4.5 knots) | REMUS 100, maker's figures ([geo-matching.com](https://geo-matching.com/products/remus-100)) |
| Maximum fin angle | 13.6° | Prestero, Table 2.2 |
| Smallest turn radius | 6.03 m (4.5 body lengths), the same at every speed | the steady turn of Prestero's model at 13.6° (`M.steadyTurn`) |
| Turn-rate limit | u / 6.03 m: 0.083 rad/s at 0.5 m/s, 0.38 at 2.3 m/s | from the radius |
| Slowest speed the fins still steer | 0.5 m/s | **assumed**, swept 0.25–1.0 |
| Outer loop | 10 Hz | as the book's UAV |

- **The turn radius comes from Prestero's model.** His horizontal-plane
  equations (sway and yaw, with the coefficients of his Appendix B, which
  he adjusted to fit his sea trials) are solved for the steady turn at his
  maximum fin angle, 13.6°: a radius of 6.03 m, with 3.4° of sideslip.
  The same equations give 10.0°/s at 4° of fin and 1.54 m/s, his sea
  trials' "roughly ten degrees per second" (his §8.3, Fig. 7-7), which
  `../checks/auv.lua` holds them to.
- **Why the turn radius does not depend on speed.** Every term of his
  model grows with speed squared, the fins' force as much as the force a
  turn of radius R needs (m u²/R). So the smallest radius is fixed and the
  turn-rate limit grows with speed: u / R. The book's UAV is the other way
  round (Eq. 13.14: Ω_max ∝ 1/v, a bank-angle limit). For the AUV,
  slowing down makes a turn take longer, not tighter.
- **Reachable space** in one 0.1 s tick: speed 0.5–2.3 m/s, heading change
  within ±u × 0.1 s / 6.03 m (±0.0083 rad at the slowest, ±0.038 at top
  speed). A wedge that never reaches zero speed (`M.reachable()`).
- **One number is assumed:** the slowest speed at which the fins still
  steer. Prestero's model has no lower limit (it is quadratic in speed
  throughout); a real vehicle's fins lose authority against currents and
  waves when slow. The results in `../ch13/README.md` were swept over it,
  and over half and twice the turn radius, and do not depend on them.
- **Size:** Prestero's vehicle (2001) is 1.33 m long; today's REMUS 100
  is 1.6 m and 37 kg (maker's figures). Only the drawing and the mass
  in his equations use the size; a longer hull would turn somewhat
  wider.
- **Not modelled:** depth (one level), speed and turn-rate dynamics (the
  book treats a UAV's as instantaneous; in Prestero's model the turn rate
  settles in about a second), currents (G19), underwater
  sensing and comms (G20). It is not yet behind the vehicle interface
  (`../lib/swarm.lua`).

Source: T. Prestero, *Verification of a Six-Degree of Freedom Simulation
Model for the REMUS Autonomous Underwater Vehicle*, MS thesis, MIT and
WHOI, 2001 ([DSpace](https://dspace.mit.edu/handle/1721.1/65068)).

The experiments with it are in `../ch13/README.md`
(`../ch13/AUV-Attractor.lua`); the check is `../checks/auv.lua`.
