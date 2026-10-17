# Digest: Hettiarachchi (2007), *Distributed Evolution for Swarm Robotics*

Page numbers are PDF pages. The printed page number is the PDF page minus 19 (printed page 1 is PDF page 20).

## 1. Bibliographic
- **Title:** *Distributed Evolution for Swarm Robotics* (PDF p.2–3)
- **Author:** Suranga D. Hettiarachchi
- **Degree:** Ph.D., Computer Science, University of Wyoming, Laramie. Dated August 2007; the approval page gives the presentation date as "Spetember 5, 2007" [sic] (p.1, 3).
- **Advisor:** William M. Spears, committee chairman (p.1). Diana Spears is thanked as his first advisor (p.5).

## 2. What it is about
The thesis extends Artificial Physics (AP) to moving a swarm in formation through random obstacle fields to a goal. It uses an evolutionary algorithm (EA) run offline to tune Newtonian and generalized Lennard-Jones (LJ) force laws. It also proposes a four-part metric suite: collisions, connectivity, reachability and time-to-goal. It then introduces DAEDALUS, an online, distributed scheme in which robots carry mutated copies of the force law and pass better rules to their neighbours. DAEDALUS is tested in a much denser obstacle field, with "obstructed perception" (line-of-sight occlusion) and with homogeneous or heterogeneous mutation rates. A short hardware chapter adds infrared (IR) obstacle avoidance to a Maxelbot using AP-lite, a Hooke's-law leader-follower controller (p.2, 32–33).

## 3. Task setup
**AP update** (p.44–45): Δv = FΔt/m and Δp = vΔt. Friction multiplies velocity by a constant each step. F is capped at Fmax and speed at Vmax. Mass is 1. The Figure 3.4 code uses Δt=1, VMAX=20, FR=0.9, R=50, and a robot-robot cutoff of r ≤ 1.5R (p.49).

**Newtonian law** (p.45): F = G·mᵢmⱼ/rᵖ. It repels for r<R, attracts for r>R and is zero beyond about 1.5R. Evolved bounds: G 100–5000, Fmax 1–5, p 0.1–2, friction 0–1 (Table 4.5, p.71).

**LJ law** (p.47, 74): F = 24ε[2dσ¹²/r¹³ − cσ⁶/r⁷], with σ = R = 50 and the result clipped to ±Fmax. Evolved bounds: ε 1–20, Fmax 1–5, c 1–10, d 1–10, friction 0–1 (Table 4.6, p.75).
- Robot-robot, robot-obstacle and robot-goal interactions each have their own ε, c, d and Fmax. That makes 12 parameters plus one shared friction (p.74, 116).
- **No evolved numeric values are reported**, only plots (Fig 4.8–4.13, p.72–77).
  - The evolved goal force is a constant Fmax_g at any distance.
  - The robot-robot Fmax saturates below r≈45 for LJ and r≈35 for Newtonian.
  - The LJ obstacle repulsion fades after about 14 units.
- Naming is inconsistent: Section 4.5.3 calls c "attractive" and d "repulsive", while the Figure 3.4 code labels the d term "attractive".

**Offline world** (p.69, 80–81):
- 900×700 units. Robots start bottom-left; the goal is a random 20×20 square on the right side.
- Obstacles are circles with Ro = 10, kept 50 units from the start area and the goal. 90 obstacles cover about 4.5%; 100 cover about 5%.
- Robot radius is 1. R = 50, Vmax = 20.
- Robots see other robots within 1.5R and obstacles within Ro+20. The goal is sensed globally.
- A collision is robot centre within Ro+1 of the obstacle centre (p.64).
- Time limit is 2000 steps, about 47 s of wall-clock time.

**Training:**
- 40 robots and 90 obstacles; population 100 for 100 generations; about 4 days per run (p.69–70).
- Operators: Gaussian mutation with per-allele probability Pm, one-point crossover, and fitness-proportional stochastic universal sampling (SUS). (μ,λ) selection got stuck in local optima (p.55–57).
- Fitness to minimize = w1·P_collision + w2·P_noCohesion + w3·P_notReachGoal (p.66–67).
  - The cohesion penalty is proportional to the error in neighbour count against 6.
  - The goal penalty applies if fewer than 80% of robots are within 4R of the goal at the end.
  - **The weights w, the mutation σ, the crossover rate and the number of training environments n are not given.**

**Metrics** (p.81–82):
- Collisions: damaged robots keep moving.
- Connectivity: the minimum, over the run, of the largest connected component, with links at ≤1.5R.
- Reachability: % of robots within 4R of the goal at step 2000.
- Time-to-goal: the step when 80% have arrived, otherwise "–".

**Online world** (p.104, 116):
- 1600×950 corridor with 5 sequential goals and 90 obstacles of Ro = 30 between each pair of goals (more than 16% coverage, three times denser). Vmax = 30.
- Robots left behind in cul-de-sacs drop out. Robots that collided but reached the goal are "repaired" and continue.

**Obstructed perception** (p.112–113): robots A and B cannot sense each other if, for any obstacle centre C of radius r, the closest point of segment AB to C is within r. In the thesis's terms: q = ((C−A)·(B−A))/|B−A|², minD = |(1−q)A + qB − C|, and the pair is blocked if r > minD. A line of sight along the obstacle's edge counts as visible. Occlusion applies in both the offline and online worlds.

## 4. DAEDALUS
The concept is on p.101–103.
- Each agent has a "worthiness" (fitness). Agents with direct reward gain fitness, and credit can trickle back to their helpers through bucket-brigade or profit-sharing. Agents without reward lose fitness, and an agent whose fitness falls low enough stops or dies.
- When a low-fitness robot meets a higher-fitness robot of the same species, it copies that robot's rules. Mutation and recombination supply the variation.

The implemented version uses only the LJ law:
- **Initialization** (p.104): every robot gets the offline-optimized LJ rule set with 1% Gaussian mutation. Initial worthiness is 1000 for all robots, an arbitrary value.
- **Exp. 1, collisions** (p.105): a collision lowers fitness; the size of the decrement is not given. On meeting a fitter robot, a robot copies only that robot's obstacle-robot parameters.
- **Exp. 2, survival** (p.107):
  - A robot that is stuck (no progress toward the goal) but senses neighbours mutates its robot-robot parameters at 1%.
  - A robot that is stuck with no neighbours mutates its robot-goal parameters at 5%. The thesis calls this "panic".
- **Chapter 7 variant** (p.117): a stopped robot next to a moving neighbour receives that neighbour's robot-robot parameters.
  - Homogeneous DAEDALUS: every robot uses 5% mutation.
  - Heterogeneous: 5 groups of 12 robots at 1, 3, 5, 7 and 9%.
  - Extended heterogeneous: a robot that copies rules also copies the neighbour's mutation rate.
- Everything is online with no global observer. "Stuck" is never defined numerically.

## 5. Results worth reproducing
**Offline**, averaged over 50 runs, 100 obstacles (Table 5.13, p.97; full tables p.84–88):

| Law | Robots | Collisions | Min. connected | Reach % | Steps to 80% at goal |
|---|---|---|---|---|---|
| Newtonian | 40 / 60 / 80 / 100 | 0 / 3 / 3 / 4 | 23 / 60 / 80 / 100 | 52 / 0 / 0 / 0 | none |
| LJ | 40 / 60 / 80 / 100 | 0 / 0 / 2 / 4 | 23 / 37 / 53 / 68 | 98 for all | 580 / 620 / 660 / 690 |

- Newtonian swarms behave as a rigid solid. LJ swarms behave as a "viscous fluid" and scale from 40-robot training to 100 robots (p.88–89).
- For LJ, robots start arriving at about step 300 (p.92).

**Safety zone** (p.92–95, 183–184): a margin of 5 units, so sensing reaches Ro+25 and the force is pinned at Fmax inside r < 20.
- Collisions drop to zero, but reachability falls.
- LJ: 20 robots reach 63% and 100 robots reach 80% at 100 obstacles (1740 steps).
- Newtonian: 20 robots reach 0% at 100 obstacles (96% at 20 obstacles).

**Online with 60 robots**, averaged over 100 runs:
- Collision ratio falls from about 38% to under 8% after 4 goals; the obstacle repulsion grew (p.106).
- Survival at goal 5: 48% when targeting collisions, 63% when targeting survival, about 78% for the offline EA retrained on the hard world (p.107–108).

**Obstructed perception, survivors at goal 5** (p.118–123):
- Train small / test small: 93.3%. Train large / test large: 35% (21). Train small / test large: 41.6% (25).
- DAEDALUS at 5%: 61.6% (37).
- Homogeneous runs: 5% and 7% each about 35 survivors; 1%, 3% and 9% at most 23. At 9% the run eventually hits a harmful mutation.
- Heterogeneous: 29 (48%). Extended heterogeneous: 34.
- Table 7.1 (p.125) gives 37 survivors by mutation rate, which conflicts with the 34 average.

**Hardware** (p.127–147):
- Platform: MMP-5 base, two MiniDRAGON boards (Freescale 68HCS12) and a PIC16F7x7 obstacle-avoidance module on an I²C bus.
- Sensors: four SHARP GP2D12 IR sensors, effective range 10–80 cm, maximum output 2.8 V, raw readings 0 to about 550. Conversion: inches = (6787/(raw−3) − 4)/2.54.
- AP-lite constants: RANGE 30 in, k_mid = 5, k_side = 4, FR = 0.5, goal force Fx = 100, MAX_SPEED 70% power.
- Tests: 1 leader and 2 followers, 10 runs each, outdoors on grass about 8 cm tall with slopes up to 20°.
- Triangle start offsets: X≈36 in, Y≈±20 in. Line start offsets: X 24.96 in and 57.31 in.
- Only the leader carried obstacle sensors. The obstacle data are qualitative correlations from a 15-minute log.

## 6. 3D and aerial/underwater content
- The simulator has a 2D/3D formation toggle and can switch between triangle and square lattices (p.63). **No 3D experiments are reported.**
- The Predator UAV is cited as an example of an expensive single robot (p.21–22).
- Multi-UAV coverage is cited from Spears et al. 2005 (p.27).
- Schultz's SAMUEL evolved navigation for an autonomous underwater vehicle in mine fields: 96% success against 8% for a human-designed strategy (p.39).
- Future work on UAV/USV teams and a marine physicomimetics with ocean-current force mapping is mentioned only as a proposal (p.154–155).

## 7. What this means for our simulation plan
1. **Reproduce the baseline before adapting it.** Scale the world so R = 50 maps to our drone spacing. Use Ro = R/5, sensing at 1.5R for robots and Ro+20 for obstacles, a constant global goal force, and the 2000-step limit. Report the four metrics, with "connected" at ≤1.5R. Treating a hit as damage that lets the drone keep flying is unrealistic for quadcopters. Report "lost" (crashed) separately from "hit".
2. **The online world is the difficulty knob.** The jump to Ro×3, more than 16% coverage, Vmax×1.5 and 5 chained goals is what broke the offline law. Applied to our field it gives a clean "train easy, test hard" protocol.
3. **Minimal reimplementation of DAEDALUS:**
   - Give each drone a 13-float LJ genome and worthiness 1000.
   - Subtract worthiness on collision or near-miss. We must choose the size of the decrement.
   - On a neighbour contact (within 1.5R and in line of sight), the less-worthy drone copies the obstacle genes of the fitter one.
   - If a drone makes no goal progress over a window we choose (for example N steps):
     - with a moving neighbour, it copies that neighbour's robot-robot genes (and, in the extended version, its mutation rate);
     - alone, it mutates its goal genes at 5% ("panic").
   - Seed the swarm with mutation rates of {1, 3, 5, 7, 9}% and let them spread.
4. **Ambiguities to settle and document.** Decide whether "mutation rate" means per-allele probability or step size σ, since the thesis never gives σ. Fix the sign convention for c and d. Define the "stuck" threshold. These choices will dominate results.
5. **Occlusion in 3D.** Extend the segment-to-circle test to segment-to-obstacle geometry (capsules or cylinders) using Bullet ray tests. Apply it to neighbour sensing and to DAEDALUS rule exchange, since exchange requires contact.
6. **Physical vehicles:**
   - Vmax and Fmax must respect the attitude and thrust limits. Treat the LJ output as a velocity or acceleration setpoint for the attitude controller rather than a raw force.
   - The safety-zone result (zero collisions, lower reachability) is worth repeating, because crashed quadcopters cannot "be repaired at the goal".
   - The hardware's IR-based Hooke repulsion (sensing range of 30, linear spring, front-arc sensors) is a ready template for the realistic-sensing task.
7. **Scouts.** Nothing in the thesis covers scouts; the closest is the explore/exploit discussion on mutation rates. Cul-de-sac traps and the proposed escape by switching to a gas model (p.152) are open problems a scout layer could address.
