# Digest: Kerr (2005), *Physics based Multiagent Swarms and Their Application to Coverage Problems*

*Caveat on the source:* `pdftotext` returned garbage because the PDF uses Type-3 fonts. I OCR'd every page and checked the equations and figures against the page images. Page numbers below are PDF page numbers; the printed page number is PDF minus 11. This document is an **unfinished draft**:
- Section 3.5 "Robot Port" is empty (p32).
- Section 6.4 "Experiment Results" is empty (p75–76).
- The List of Tables is empty (p9).
- Editorial notes are still in the text, e.g. "(Should I put a picture in here…?)" on p21 and "Talk about how 6 circles…" on p30.

## 1. Bibliographic
- **Title:** Physics based Multiagent Swarms and Their Application to Coverage Problems
- **Author:** Wesley N. Kerr
- **Degree:** M.S., Computer Science, University of Wyoming, Fall 2005
- **Advisor:** Diana F. Spears (p1, p10)

## 2. What it is about
The task is to sweep a swarm of robots through a long bounded corridor that contains obstacles. The goals are to maximize coverage, both longitudinal and lateral, and to minimize sweep time (p12–14). The thesis offers two "gas" controllers:
- **AP gas:** Artificial Physics with only repulsive forces plus a constant goal force (Ch. 3).
- **KT:** a kinetic-theory controller based on Garcia's (2000) DSMC Couette-flow simulation, plus a "robot-faithful" local version (Ch. 4).

Chapter 5 compares theoretical predictions with simulation for three quantities: velocity profile, spatial distribution and average speed. All of it is in 2D. Chapter 6 sets up a comparison against Random, a GA-trained FSM, and Koenig's Ant controller, but reports no results.

## 3. The KT model as specified
- **Flow type (p37):**
  - The controller uses a modified, **two-sided Couette flow** in which both walls move in the same direction at the same speed, to propel the swarm toward the goal.
  - The theory and the KT-results experiment use a **one-sided** Couette flow (one wall still, one moving) (p53–55).
  - The thesis does not reconcile the two.
- **Free flight (p37):** velocities start random and stay constant between collisions. The update is x ← x + vΔt, with Δt "on the order of the mean collision time."
- **Wall rule (p38, p43):** when a step would cross a wall:
  - the x velocity (normal to the wall) is resampled from a **biased Maxwellian**, and the y velocity (parallel to the wall) from a **Gaussian** (Garcia 2000);
  - at a moving Couette wall, v_wall is added to the y component;
  - the new position accounts for the remaining distance the particle would have travelled.
  - No temperature or variance values are given for the wall distributions.
- **Particle–particle collisions:**
  - In the simulation, the number of collisions per cell is "a stochastic function of the number of agents in that region," using bucket sorting into cells (p38).
  - The robot version uses Garcia's rule (p47):
    - s_r = |v_B − v_A|, and v_c is the mean of the two velocities;
    - a random collision angle φ is drawn uniformly, giving a new relative velocity v_r of magnitude s_r;
    - **v₁ = v_c + ½v_r, v₂ = v_c − ½v_r**.
  - A pair cannot collide again until a set number of steps has passed (p44).
  - When several collisions happen at once, the new velocities are vector-summed.
  - Robots always move at a **fixed predefined speed**, and only the heading comes from the resultant (p47–48).
- **Robot-faithful details (p40–47):**
  - A wall is "Couette" if its angle to the goal line is within ε of 0° or 180°. The wall line is estimated from two sonar endpoints in the ±45° arc, and the angle comes from the law of cosines.
  - A global velocity is converted to a local one by β = θ_g − 90 + ζ₁.
  - B's velocity in A's frame uses ξ = 180 + θ_AB − θ_BA (Eq. 4.1). This needs trilateration (Heil 2004) and messages between robots.
- **Parameters, geometry and counts:**
  - Velocity-profile runs: 3,000 particles for 50,000 steps, binned into **7 cells** across the corridor. The obstacle set uses 500 particles for 5,000 steps, binned into **8 columns** (p55).
  - Wall speeds: Fig. 5.2 axes run 0.5–4 ("m") and 1–8 ("mach") (p57).
  - Corridor dimensions, Δt, T and the cell size for the KT runs are **not stated**.
  - Obstacles are random squares at 10–50% coverage, with 5 densities × 8 parameter values × 20 runs (p50–51).

## 4. Theory and predictions
- **Couette profile (p53–55):**
  - From the y-momentum equation, ∂/∂x(μ ∂v_y/∂x) = 0, so ∂²v_y/∂x² = 0 (5.1), giving v_y = c₁x + c₂ (5.2).
  - Boundary conditions v_y(0) = 0 and v_y(D) = v_wall give **v_y = (x/D)·v_wall**, a linear profile (D is the Couette width).
- **Spatial distribution (p57–58):** the steady state is uniform, with **n/c particles per cell** (n particles, c cells).
- **Average speed:**
  - 3D (p36): ⟨v⟩ = (2√2/√π)√(kT/m), and ⟨K⟩ = (3/2)kT.
  - 2D (p63–64):
    - f(v)dv = 2πv(m/2πkT)e^(−mv²/2kT)dv;
    - **⟨v⟩ = ¼√(8πkT/m)**, which equals √(πkT/2m).
    - The intermediate normalization uses ∫₀^∞ where it should be over (−∞, ∞), but the final result is the standard 2D formula.
- **Velocity distribution:** this is used only as "the Couette profile" (the AP version is v_y = gt, p52–53). No full Maxwellian shape test is made.
- **AP average speed, for contrast (p60–61):**
  - ⟨v²⟩ = (N−1)[2√(GF_max) − G/1.5R];
  - ⟨v⟩ ≈ √⟨v²⟩, which is an upper bound.

## 5. Measured results worth reproducing
The error metric is relative error, |theory − actual|/theory (p50).

**KT Couette profile, Fig. 5.2 (p55–57):**
- With no obstacles, error is about 22% at v_wall = 0.5, falling to about 11% at 4, and stays below 20% overall. Garcia's original code also shows error "slightly below 20%."
- With obstacles, error grows sharply with density, to roughly 100–120% at 50%.
- Error falls as wall speed rises.

**Cause of the profile error (p55–56):** the author attributes it to particles moving *backwards* and to too few particle collisions at low wall speed. Two observations support this:
- At v_wall = 1.0, 10% obstacles predicted the profile *better* than 0%.
- Ignoring y when choosing collision partners, which raises the collision count, brought the open-corridor error to about **16%**.

**KT spatial uniformity, Fig. 5.4 (p58–59):**
- About 18% error, flat across 500–1200 particles, starting from a tight Gaussian in a square container.
- The obstacle runs (100–800 particles) show roughly 5–10%.
- AP: under about 6%, decreasing with n.

**KT average speed, Fig. 5.6 (p64–65):**
- Under 10% error for T from 50 to 400, with 500 particles over 50,000 steps.
- Also under 10% with 100 particles over 10,000 steps at up to 50% obstacles.
- AP: ⟨v⟩ under 6% error and ⟨v²⟩ under 0.07% (p62).

**Conclusions (p66):**
- AP is more predictable than KT.
- KT is unpredictable at the level of individual agents, which may be preferable against an adversary.

**Coverage task, Ch. 6 (p67–76):**
- Setup: a 2D corridor of 50×250 cells, 25 robots, 0–40% random obstacles, 5 corridors per density × 10 runs, robot speeds roughly equal.
- Metrics:
  - **w**, sweep time until all agents reach the goal;
  - **c_c**, the fraction of cells ever visited;
  - **c_s**, shadow coverage, i.e. cells just downstream of obstacles (Fig. 6.6).
- Comparison controllers:
  - **Random:** 8 moves at 45° steps; keeps the same heading 80% of the time, the rest is split among shadow, goal and open moves.
  - **GA-trained FSM:** 8 states × 255 inputs; trained 1,200 generations on checkerboard, "L" and random courses, with fitness c₁p_c + c₂p_s + c₃p_f.
  - **Koenig's Node-Counting Ant:** uses stigmergy.
- **No results are reported.** Chapter 7 only says, without data, that AP is faster but explores less than KT (p77).

## 6. 3D, aerial vehicles and hardware
- p28: AP "can be run in either 2D or 3D (to model swarms of micro-air vehicles)." This is the only mention of aerial vehicles.
- p36: the 3D ⟨v⟩ and ⟨K⟩ formulas, which are derived down to 2D for the experiments.
- p50: "The theory and experiments… assume a 2D environment."
- p47–48: robots turn then move at a fixed speed, and low-level routines prevent real collisions. Vehicle dynamics are not modelled.
- p78:
  - AP solid already runs on the UW Distributed Robotics Lab robots (IR sensing, light sensor for the goal).
  - Porting KT needs trilateration and explicit communication, so the port was not done.
  - The author wishes for a single framework that handles both point-particle and robot simulation.
- **There are no fixed-wing, quadcopter or finite-acceleration results.**

## 7. What this means for the 3D kinetic-theory plan
1. **Primary test: the linear profile v_y(x) = (x/D)v_wall.**
   - Decide one-sided versus two-sided walls explicitly. The thesis mixes them. With two moving walls the theoretical profile is flat at v_wall, not linear.
   - In 3D with walls at x = 0 and x = D, the profile should still be linear in x and uniform in z. Add a z-uniformity check.
   - Report the relative error per bin, using Kerr's 7 bins so the numbers are comparable, as v_wall goes from about 0.5 to 8.
   - Baselines: Kerr has about 11–22% error in the open corridor, and Garcia about 20%.
2. **Separate dynamics effects from sampling effects.**
   - First run a 3D point-particle version of the same code to get a baseline.
   - Then run the quadcopter version with the same collision rule, where the collision gives a *commanded* velocity.
   - Record the commanded-versus-actual velocity lag (time to reach about 90% of a commanded change) relative to the mean time between collisions.
   - The profile should hold only while the lag is much shorter than the collision time. Sweeping a damping or controller gain would show the failure point. Kerr's explanation (p56) predicts that too few momentum-exchanging collisions break linearity, and a slow vehicle effectively spreads each collision out over time.
3. **Average speed in 3D:** test ⟨v⟩ = √(8kT/πm), i.e. (2√2/√π)√(kT/m), against T, with a target error under 10%. Also check ⟨½mv²⟩ = (3/2)kT, and the full 3D Maxwell speed histogram with a KS test. Kerr never tested the distribution shape.
4. **Spatial uniformity:** count n/c per 3D voxel after diffusing from a tight Gaussian, and compare with Kerr's roughly 18% error. Watch for altitude bias from the ground and ceiling.
5. **Track the backward-moving fraction** (v_y < 0), which Kerr names as the main cause of profile error. Also log the collision rate per bin.
6. **Fixed-wing UAVs:** Kerr's robots move at constant speed and only turn. That is close to fixed-wing kinematics, but it breaks the Maxwell speed distribution because every speed is equal. Expect the ⟨v⟩ and profile predictions to fail unless something stands in for speed, such as dwell or loiter time or a speed band. Test the heading distribution instead.
7. **If you run the coverage task,** reuse w, c_c and c_s (shadow cells downstream of obstacles), measured in voxels.
