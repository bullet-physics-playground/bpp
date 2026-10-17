## The Double Cone

**What it shows** — Two cones are joined base to base and set on a pair of rails that rise and spread apart in a V. Let go at the low, narrow end, the double cone rolls up to the high, wide end, so it seems to roll uphill. It does not really: the spreading rails meet it nearer its points, where it is thinner, so its centre of mass sinks faster than the rails rise. Two control tracks sit beside it. On the same rails a plain cylinder rolls down. On rails rising 5 cm instead of 1.5 cm (too steep), the same cone rolls down.

**Model** — Bullet does the contacts:
- **Double cone:** a `btCompoundShape` of two `btConeShapeZ` (R = 5 cm, H = 12 cm each), collision margin 0.01 cm, 400 g, solid. Inertia is I_axis = 3/10 m R² = 3.0 kg·cm² and I_perp = m(3/20 R² + H²/10).
- **Cylinder:** a `btCylinderShapeZ` with r = 3 cm, length 26 cm, 400 g.
- **Rails:** 8 mm brass rods (radius 0.4 cm), 50 cm long, 2.5 cm from the centre line at the low end and 9.5 cm at the high end, so tan φ = 0.14 per side. They rise 1.5 cm (tan θ = 0.03) at the back and middle tracks and 5 cm (tan θ = 0.10) at the front. For collision, each rail is a compound of 10 cm capsules laid end to end. The README says a single 54 cm cylinder gave an "invisible bump halfway up", and 3 cm pieces lost "a few per cent" of energy at the joins.
- **Settings:** friction 0.9 on rails and rollers, 0.81 at the contact (Bullet multiplies the two; the README and lua said 0.9 until 16 Oct 2026, they now give 0.81), restitution 0, damping 0, 30 solver iterations, 2400 steps per simulated second (DC_STEPS), integrated by Bullet's semi-implicit Euler.

The script itself works out the exact predicted centre height at every x. It finds by bisection the height at which the rail's centre line just clears a cone enlarged by (ρ + margin)/cos(taper), allowing for the off-centre contact point on sloping rails. It also tracks the total energy, kinetic (translational plus rotational) plus potential.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Rolls up or down (back) | rolls up iff tan θ < tan φ·R/H; 0.030 < 0.14·5/12 = 0.0583 | rolls up 36.8 cm to the high end | correct |
| Rolls up or down (front) | 0.100 > 0.0583, so rolls down | rolls down 23.9 cm | correct |
| Back cone: centre drop while rolling up 36.8 cm | exact geometry (script): 1.045 cm; thin-rail estimate (tan φ R/H − tan θ)·Δx = 0.0283·36.8 = 1.04 cm (my arithmetic) | 1.045 cm down | 0.000 cm (exact); 0.2% (estimate) |
| Front cone: centre drop rolling down 23.9 cm | geometry 0.994 cm; estimate (0.100 − 0.0583)·23.9 = 1.00 cm | 0.994 cm | exact; 0.6% (estimate) |
| Cylinder: centre drop rolling down 31.8 cm | geometry 0.955 cm; tan θ·Δx = 0.954 cm | 0.955 cm | exact |
| Largest deviation from predicted centre height along the run | 0 | back 0.0000 cm, front 0.0001 cm, middle 0.0001 cm (4 cycles) | ≤1 µm |
| End-to-end centre change (48 cm), printed prediction | back −1.36 cm, cylinder +1.44 cm, front +2.00 cm | (prediction only) | — |
| Energy conservation (rolling, no slip) | ΔE = 0 | loss as % of centre-fall energy, over 4 cycles: back 0.14–0.17%, front 0.09–0.12%, middle 0.20–0.26% | ≤0.26% lost |
| Step-size check (DC_STEPS=600) | — | deviation ≤0.0004 cm; energy loss back 0.42–0.50%, front 0.48–0.57%, middle 0.62–0.65% | loss about 3× larger at 4× the step |

**Run used**
```
cd demo/WyomingWill/DoubleCone && HOLD_S=0 timeout 1500 bpp -f double-cone.lua -n 1200     # 2400 steps/s, 4 cycles
HOLD_S=0 DC_STEPS=600 timeout 1500 bpp -f double-cone.lua -n 1200                          # step-size check
```
```
  Back   rails rise 1.5 cm over 50 (tan 0.030); the cone's centre would go down by 1.36 cm from end to end:
         tan(theta) 0.030 < tan(phi) R/H = 0.140 5.000 / 12.000 = 0.0583, so it rolls UP the rails (its centre going down)
  Middle a cylinder on the same rails: its centre rises 1.44 cm with them, so it rolls down
  Front  rails rise 5.0 cm over 50 (tan 0.100); the cone's centre would go up by 2.00 cm from end to end:
  Front  nears the low, narrow end at 1.55 s, having rolled 23.9 cm down the rails (the rails falling 2.39 cm): its centre went down 0.994 cm (the geometry: 0.994),
         off the geometry by 0.0001 cm at worst on the way; it lost 0.12% of the energy its centre's fall gave it
  Middle nears the low, narrow end at 1.80 s, having rolled 31.8 cm down the rails (the rails falling 0.95 cm): its centre went down 0.955 cm (the geometry: 0.955),
         off the geometry by 0.0001 cm at worst on the way; it lost 0.20% of the energy its centre's fall gave it
  Back   nears the high, wide end at 2.32 s, having rolled 36.8 cm up the rails (the rails rising 1.10 cm): its centre went down 1.045 cm (the geometry: 1.045),
         off the geometry by 0.0000 cm at worst on the way; it lost 0.14% of the energy its centre's fall gave it
```
The README's back-cone line (2.32 s, 36.8 cm, 1.045 cm, 0.0000 cm, 0.14%) matches this run's first cycle exactly. The README's "0.1 to 0.3%" energy loss matches the 0.09–0.26% range seen here.

**Known departures and honest caveats**
- The "geometry" check is the script's own exact contact geometry, which includes the rail thickness and Bullet's collision margin. It shows that Bullet holds the body on the ideal surface; it is not an independent physical measurement. The simple thin-rail formula agrees to within 0.6%.
- Energy is not exactly conserved. 0.1–0.3% of the energy released by the centre's fall is lost, and the loss roughly triples at 600 steps/s, so it is numerical (contact and solver dissipation), not physical rolling resistance. The losses also vary slightly from cycle to cycle (e.g. back 0.14–0.17%), because each restart begins from Bullet's leftover contact state.
- The rails were segmented into 10 cm capsules specifically to avoid Bullet contact artefacts: a bump with one long cylinder, energy loss at joins with 3 cm pieces (README). This was tuned, not derived.
- Friction 0.81 at the contact is high, chosen so that nothing slips; brass on brass is nearer 0.4. Tried 16 Oct 2026 (not adopted): with 0.4 at the contact (1800 frames) the times are the same, the heights within 0.001 cm, and each roll's energy loss moves by -0.03 to +0.06 points (0.11-0.25% of the centre's fall energy, against 0.09-0.26%), so the friction hardly matters here. Rolling resistance and air drag are absent.
- The checks are reported only between 6.5 cm from each end (away from the stops). Behaviour at the stops is not checked.
- Only the outcome (direction and centre descent) is checked. Times to reach the end (e.g. 2.32 s) are not compared with an analytic prediction.

**References**
- The 18th-century "mechanical paradox" lecture-room instrument (mentioned in code and README; no specific author or paper cited).
