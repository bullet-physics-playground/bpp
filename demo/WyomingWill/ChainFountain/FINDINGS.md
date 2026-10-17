# The Chain Fountain: findings

What was found about how faithful this exhibit's physics is, 15-16 Oct
2026, in the order it was found. Sections 1-10 are about the coil the
exhibit had; 11-12 about a poured heap; 13 makes the heap the default.
Every number is from a run of the exhibit (or of the reference programs in
reconstruction/) unless it is marked as read from a paper or as from
memory. Paths are relative to this folder unless they start with demo/.
The runs in sections 1-10 were made when the coil was the default: to
repeat them now, add CF_PILE=coil.

## Where things stand

- **The exhibit now starts from a poured heap of ball chain** (since 16 Oct
  2026; H or CF_PILE=coil gives the old coil). 9.75 m of chain the size
  Biggins and Warner used (4.5 mm balls 6.5 mm apart, 30 degrees a joint)
  lies in the jar as it fell when poured in; a hand draws the end over and
  lets go. Its fountain: h2/h1 = 0.140, against 0.12-0.14 measured on real
  ball chains (Biggins and Warner 2014; Pantaleone 2019).
- **Why the coil was wrong.** Both Bullet with every link simulated and an
  independent bead-and-rod reference (reconstruction/bead-pour.c) give
  h2/h1 = 0.11-0.19 from a poured heap and about 0.06 from the exhibit's
  coil, where the pick-up runs round the wall and the chain rides the rim
  (section 11). The coil's own shortcut (ten links woken, the rest frozen)
  made its fountain 1.2-2x taller than the coil simulated whole (section
  8); the coil, simulated whole, gives 0.04-0.06. The coil's 1.5 cm links
  can't form a heap in this 7 cm jar at all: poured, they lay rings round
  the wall (0.08-0.11).
- **How the heap is simulated.** The heap is fixed bodies except a live
  zone 4 cm across and 0.5 cm deep round the pick-up; this matches every
  link simulated within the spread from pour to pour (0.147 against 0.140
  over five heaps; section 12). Bullet's joints needed an error correction
  of 0.5 a step, not its 0.2, for the result not to change with the step.
- **Cost.** 14 ms a frame during the flow at an eighth of real speed (15
  in the Cabinet), so the exhibit starts there; at a quarter it would take
  28-30 ms. The cost is Bullet's per-body and per-joint work for about 280
  links falling and a few hundred in the zone, not solver iterations.
- **Still open.** The theory's speed reading disagrees with the height
  reading in the heap's short, slowing window (section 13); the zone's pile
  push is about a quarter low; about one run in ten catches the rim; GPU
  drawing cost of about 3000 individually drawn links is not measured; a
  faithful run at a quarter of real speed would need bpp/Bullet changes.

## 1. The theory (Biggins and Warner 2014)

J. S. Biggins and M. Warner, "Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689, arXiv:1310.4056.

A chain lies in a pile in a jar. Its end has been pulled over the rim and down to the floor, and it now siphons out at a steady speed v. Notation:
- h1: drop from the pick-up point (top of the pile) to where the chain comes to rest on the floor.
- h2: height of the top of the chain (the "fountain") above the pick-up point.
- lambda (written m in the paper): mass per unit length.
- alpha (a): the pile pushes up on the link being picked up with a force alpha * lambda * v^2. This is the anomalous reaction. A link is a short rod lifted by one end. It turns about its middle, so its other end is pushed down into the pile, and the pile pushes back.
- beta (b): the floor pulls down on the arriving chain with beta * lambda * v^2.

In steady flow along a fixed path, the quantity T - lambda v^2 (T is the tension) obeys the statics of a hanging chain. This gives:
- v^2 = g h1 / (1 - alpha - beta)   (the speed rule)
- h2 = alpha v^2 / g, for a narrow arch whose two legs are close together (the height rule). More exactly, for a flexible chain h2 = alpha v^2/g - R, where R is the radius of curvature at the top of the arch.
- h2/h1 = alpha / (1 - alpha - beta).
- Energy conservation requires alpha + beta <= 1/2.
- An ideal chain (alpha = beta = 0) goes at v = sqrt(g h1) and does not rise above the pick-up.
- Rod model: alpha = (1/2)(1 - I/(m b^2/4)), with I the link's moment of inertia about its centre, m its mass and b its length. Biggins and Warner model a link as three equal beads on a massless rod (I = m b^2/6), which gives alpha = 1/6.
- Their experiment: ball chain with 4.5 mm balls joined by 2 mm rods. Measured h2 = 0.14 h1 (linear fit). They say beta is small for their chain, from a crude test. With alpha = 1/6 and beta about 0, the model gives h2 about 0.2 h1, which they describe as the same order as observed.

These paper values were read from the arXiv abstract page and summary. From memory, and not checked here: J. S. Biggins, "Growth and shape of a chain fountain", EPL 106 (2014) 44001, treats the arch shape and how the fountain grows. Falling-chain experiments where the floor pulls the chain down (beta > 0), such as Hamm and Geminard, Am. J. Phys. 78 (2010), are the background for beta.

What a freeze at the floor means for beta: in the simulation a link that reaches the floor is frozen and its joint is cut. The chain therefore ends in a free end with zero tension, and nothing pulls down. So beta = 0 exactly, and the theory has no free parameter: v^2 = g (h1 + h2).

## 2. The simulation (the coil, as the exhibit had it until 16 Oct 2026)

- Chain: rigid capsules, 1.5 cm joint to joint, radius 0.3 cm, mass 0.5 g. No damping, no restitution. Friction 0.3 (chain-chain and chain-glass).
- Joints: Bullet cone-twist constraints, swing limit = the "bending" setting (default 30 deg per joint), free twist. This bending limit is the angle setting in the exhibit (20, 30, 60, 90 deg): how far one link may turn relative to the next.
- Rod-model alpha for one of these links: (1/2)(1 - (L^2/12 + r^2/4)/(L^2/4)) = 0.31.
- Jar: 7 cm inside radius, 8 cm wall, 24 static glass slabs. The rim is 158 cm above the floor; the pile top starts 5 cm below the rim.
- Pile: the coil is drawn but not simulated. It rests on a static rigid disc that is lowered 0.65 cm per layer.
- Waking: links are woken (made dynamic) in chain order, so that 10 links ahead of the pick-up still lie where they were laid. At most 1200 links are woken per simulated second. The last woken link is held at its far end by a cone-twist joint to a fixed body; this stands in for the rest of the coil. Without the anchor, the moving chain dragged the woken links off into a heap.
- Floor: a link whose centre goes below 2.5 cm is frozen and becomes a drawn-only, non-colliding mesh. Its joint is removed.
- About 130-200 links are dynamic at a time.
- Step: exactly 1/1800 s whatever the display speed. Each frame takes as many whole steps as its share of simulated time. Wake, freeze and measurement run after every step, so output is identical at 0.25x, 0.5x and 1x speed. 20 solver iterations.
- Default: 10 layers, jar 150 cm up.

## 3. What is measured, and how

Steady window: from t = 1.00 s until the last coil link is woken. In this window:
- h1: the mean of (pile-top chain centre height minus 2.5 cm), about 150 cm.
- h2: the mean height of the highest dynamic link above the pile-top chain centre, sampled every 1/240 s.
- v: number of links frozen in the window x 1.5 cm / window length. This is the "rate the links land". Before this work, the code used the rate links were woken; in default runs the two agree to 2%.
- alpha from height = g h2 / v^2. alpha from speed = 1 - g h1 / v^2.
- New (CF_PUSH=1), the pile's push measured directly. After every step, sum the normal contact impulses between the disc and dynamic links (Bullet manifolds, vertical component), divide by the step, and subtract m g for each link with a positive-impulse contact on the disc (the weight it carries anyway). Divide the mean by lambda v^2. The same is done for the jar slabs, which gives the rim's upward push.
- New: the rms speed of links at the moment they are frozen, and the energy fraction (rms speed)^2 / (2 g h1). A lossless Biggins-Warner chain has fraction 1/(2(1 - alpha)), and an ideal chain (alpha = 0) has 50%.

## 4. What was found

### 4.1 The flow is steady enough in rate, not in shape

With the original code, wake rate and landing rate agreed within 1-3%, and the number of moving links was flat (for example 163 -> 168 at 30 deg). In quarters of the window, though, the rate swung by +-14% (30 deg: 346-458 cm/s), and the fountain height had a standard deviation of 2-4 cm.

Shapes were dumped and plotted (side views every 1/30 s):
- Stiff chains (20, 30 deg): loops and tangles above the pile, with slow links whirling.
- Floppy chains (60, 90 deg): the chain rises 5-10 cm and turns over in an arch 8-15 cm wide, then falls outside the jar on a slant.
- In every case the falling leg is wavy, not straight.

The pick-up point runs round the flat spiral at the chain's own speed: a 3-6 cm radius circle, 10-20 revolutions a second.

### 4.2 A real defect: the coil was laid past the joints' limits

A check of the laid coil (angle between successive links, and link length) gave:
- The spiral went in to 3 cm radius at every bending. At 20 deg, 304 of 1054 joints were laid bent past their limit: about 29 deg against 20 at the 3 cm radius. At 25 deg, 84 joints.
- At every bending, each new layer began with one link only 0.65 cm long between joint points, standing upright (two 90 deg bends). The next layer then wound the opposite way (a hairpin). That makes 21 over-limit joints at 30, 60 and 90 deg.

When such a link is woken, Bullet's joint error correction snaps it into its limit, which kicks energy into the chain at the pick-up.

Fix: the spiral is now no tighter than the chain can turn while also tipping down. The inner radius is max(3 cm, L/(2 sin(theta/2)) + 0.1 cm), where theta = sqrt(bend^2 - tip^2) and tip is the slope of a dropping link. That gives 3.1 cm at 30 deg and 4.8 cm at 20. Every layer winds the same way, and the chain drops to the next layer over 3 links of full length. The bending slider minimum went from 10 to 20 deg, because below about 15 deg the coil does not fit the jar. After the fix the only over-limit joints are the 3 corners of the pre-woken lead at t = 0.

Consequence: a 20 deg layer holds less chain (9.6 m in 10 layers, against 15.8 m at 30 deg and 16.1 m at 60/90).

### 4.3 Before / after, 10 layers, CF_SPEED=1, steady window

Push = the direct measurement (CF_PUSH=1). The rim column is the rim's upward push in units of lambda v^2. E% = landing kinetic energy as a share of g h1.

Before (old coil, measurement method as now):

| bend | v (landing rate) | rms landing speed | h2 cm | alpha height | alpha speed | push | rim | E% |
|---|---|---|---|---|---|---|---|---|
| 20 | 472 | 405 | 16.9 | 0.07 | 0.34 | 0.34 | 0.05 | 56 |
| 30 | 404 | 366 | 13.7 | 0.08 | 0.10 | 0.35 | 0.17 | 45 |
| 60 | 424 | 365 | 8.5 | 0.05 | 0.18 | 0.16 | 0.05 | 45 |
| 90 | 423 | 375 | 9.8 | 0.05 | 0.17 | 0.16 | 0.03 | 48 |

(The exhibit as found printed v as the wake rate, 463/406/422/426 cm/s, and from it alpha speed 0.31/0.11/0.17/0.19; alpha height 0.08/0.08/0.05/0.05.)

After (fixed coil):

| bend | v | rms landing | h2 cm | alpha height | alpha speed | push | rim | E% |
|---|---|---|---|---|---|---|---|---|
| 20 | 450 | 361 | 10.7 | 0.05 | 0.27 | 0.27 | 0.14 | 44 |
| 30 | 397 | 352 | 10.5 | 0.07 | 0.06 | 0.31 | 0.31 | 42 |
| 60 | 425 | 383 | 12.8 | 0.07 | 0.18 | 0.19 | 0.02 | 50 |
| 90 | 432 | 380 | 13.2 | 0.07 | 0.21 | 0.17 | 0.01 | 49 |

sqrt(g h1) = 384 cm/s throughout; h1 = 149.6-150.3 cm.

Fountain above the rim, whole run from 0.5 s (median, interquartile range, highest), with 14 layers in brackets:

| bend | before | after |
|---|---|---|
| 20 | 11.1 (9.0-13.7), 21.2 | 4.7 (3.5-5.8), 11.9 [4.5 (3.0-5.8)] |
| 30 | 8.8 (6.4-11.0), 16.1 | 5.4 (3.4-8.0), 12.4 [4.1 (1.9-6.7)] |
| 60 | 3.4 (2.4-5.0), 7.5 | 7.7 (6.0-8.3), 10.1 [6.3 (3.9-8.0)] |
| 90 | 4.4 (3.6-5.1), 9.7 | 7.8 (6.6-8.6), 12.4 [7.3 (5.1-8.2)] |

The old "stiffer chain, higher fountain" result was produced by the over-bent coil. After the fix, runs with the jar at 146/148/152/154 cm give medians of 6-8 cm (20 deg), 5-7 (30), 4-8 (60) and 5-8 (90). There is no bending trend beyond this run-to-run (chaotic) spread.

### 4.4 Uncertainty of the push measurement

If instead every dynamic link within 7 mm above the pile (inside the jar) counts as lying on it, the push is 0.17 / 0.22 / 0.13 / 0.12 (20/30/60/90). So the push is known to about +-0.05. The anchor's force is not included; Bullet constraint impulses are not exposed to Lua.

An earlier instrumented copy (old coil) estimated the anchor's vertical force from global momentum balance at 0.01-0.05 lambda v^2.

### 4.5 Run-to-run and numerical spread (fixed coil)

- Jar height 146/148/152/154 cm, all bendings: v 414-448 cm/s, push 0.15-0.41, alpha height 0.05-0.07, alpha speed 0.12-0.25, rim 0.03-0.18.
- Step 1/3600 s: 20 deg v 477, push 0.39, h2 19.8 cm (+85%); 30 deg 437 / 0.32 / 14.3; 60 deg 401 / 0.26 / 10.1 (rim 0.17); 90 deg 444 / 0.19 / 15.6. Not converged at 20 deg.
- Look-ahead K (links woken ahead; only a device to simulate less), via a scratch copy:
  - K = 5: v 476 / 452 cm/s at 30 / 60 deg, alpha speed 0.35 / 0.28, push 0.21 / 0.16.
  - K = 20: the woken links are dragged into a heap: 276-446 links moving, and at 60 deg the rim carries 1.3 lambda v^2.
  - So the scheme is not neutral, and v is known to about 20%.
- With the old coil, 1/3600 and 1/4800 s steps at 20 deg ran away: 250-400 links moving, links landing in clumps, wake rate 592 cm/s (above the sqrt(2 g h1) = 542 cm/s energy bound). That is why v is now the landing rate.
- Friction 0.05 instead of 0.3 (old coil): the rim push drops (30 deg: 0.17 -> 0.04) and alpha speed rises (0.10 -> 0.23, push 0.29).

### 4.6 Cause of the alpha mismatch

1. The pile does push, as the theory requires: directly measured alpha = 0.17-0.31 at default settings (0.12-0.41 over all variations). That is the same order as Biggins-Warner's 1/6, and at 20/30 deg close to the rod value 0.31 for these links. The rigid disc and the anchor do not suppress the mechanism; the fountain is not low because the push is weak.

2. The speed rule matches the measured push where the chain keeps clear of the rim: 60 and 90 deg, alpha speed 0.12-0.21 against push 0.12-0.20. Where the chain rubs and strikes the glass rim (20 and especially 30 deg; rim push 0.07-0.31 lambda v^2), alpha speed reads low, because friction and impacts on the rim take momentum.
   - At default 30 deg the two printed readings, 0.07 and 0.06, agree only by coincidence: the push is 0.31 and the rim carries 0.31.
   - The look-ahead test (K = 5: speed 0.28-0.35 against push 0.16-0.21) shows that this agreement also depends on the waking scheme.

3. The height rule fails at every setting: alpha height 0.04-0.09 against push 0.12-0.41. The fountain is about a third of alpha v^2/g (for example 12.8 cm against 35 cm at 60 deg). The arch-top radius measured at 3-4 cm (old coil; circle through links +-3 from the top) accounts for only about 0.02 of alpha. So h2 = alpha v^2/g - R is not satisfied either, and T - lambda v^2 is not conserved between the pile and the top of the arch.
   - The flow is not the theory's steady, lossless flow along a fixed path. The pick-up circles at the chain speed, the arch swings, and stiff chains loop above the pile.
   - The chain loses energy on the way. Links land with 42-50% of the drop's energy, at an rms 352-383 cm/s, 11-20% below the length-rate v. A lossless chain with the measured push would land with 60-72%. So 11-30% of the power is lost between pile and floor, and the falling leg is wavy (it falls partly sideways to its own line).
   - Where the energy goes (joint stops, link-link contacts, rim, the shaken arch) is not established. At 90 deg, where the stops are seldom hit, the loss is still about 11%.

4. Why h2/h1 is lower than Biggins-Warner's 0.14 (here 0.07-0.09): same reason as 3. It is not a weak push.

Ruled out or measured:
- unsteadiness of the rate (rates agree within 2%, active count flat at the default step);
- inconsistent windows (h1, h2 and v now all come from the same window);
- h1 definition (it is measured from the pick-up, not the rim; the rim is 5.1-5.5 cm above the pick-up);
- beta (a freeze is beta = 0 exactly);
- a weak or suppressed pick-up reaction.

Not ruled out:
- the flat-spiral geometry (a pile whose pick-up stays put was not tried);
- link coarseness (1.5 cm links in a 7 cm jar, against Biggins-Warner's 4.5 mm beads);
- the rigid joint stops;
- solver and step effects (not converged at 20 deg);
- the waking and anchor scheme.

## 5. What was changed (files)

In demo/WyomingWill/ChainFountain/:
- chain-fountain.lua:
  - The coil is laid within the bend limit, at full link length, with layer drops over 3 links and the same winding sense. Bending slider minimum 20 deg.
  - v in the theory check is now the landing rate.
  - New console line: the links' rms landing speed and the energy fraction.
  - Optional direct pile and rim push measurement (CF_PUSH=1). It is off by default, because walking all contacts every step makes the Cabinet run 2.6x slower (34.7 s against 13.2 s for 1200 frames).
  - Help text: the fountain is much the same, 3-9 cm, at every bending.
- README.md: all numbers re-measured; theory section rewritten with the findings above.

The dossier demo/WyomingWill/Cabinet/report/dossiers/ChainFountain.md was updated.

Checks after the change:
- Cabinet vs standalone output IDENTICAL: default (22 lines), CF_PUSH=1 (23), CF_BEND=60 (21).
- Output with a 0.5 s (30-frame) start pause is an exact prefix match of the output without it (24 lines).
- 0.25x with pause = 1x (30 deg); 0.5x = 1x (60 deg, CF_PUSH).
- The README console block matches a fresh run.

## 6. Still open

- Where 11-30% of the power is lost along the moving chain, and whether a real bead chain would lose it.
- Whether a pile whose pick-up does not circle (a heap) gives a narrow arch with h2 near alpha v^2/g. (Answered in section 7: no.)
- Step convergence at 20 deg, and the dependence of v (about 20%) on the waking look-ahead and the infinitely strong anchor.
- When the disc drops a layer, the last ~10 woken links of the old layer fall 0.65 cm onto it. This is small, but it is a pile artifact.

## 7. Follow-up experiment: a pile whose pick-up point stays put

Question: is the fountain about 1/3 of alpha v^2/g, with links landing at 42-50% of the drop's energy, because of
- (a) the flat spiral's geometry: the pick-up circling at the chain's speed, a wavy falling leg (real physics of this setup); or
- (b) energy lost in the model: joint stops, contacts, rim, solver or step, the waking scheme?

### 7.1 New measurements and options (all off by default; default output byte-identical to before)

- **Flake pile (CF_LAYOUT=flake).** The chain is laid in straight runs of 4 links, back and forth, 3 runs per layer. Each run is joined to the next by a half-turn no tighter than the joint limit allows. Each layer goes back over the last, dropping 0.65 cm over a half-turn plus a run. The pick-up stays within a few cm of the middle, as in a jumbled heap, instead of circling. Every link is 1.5 cm and no joint is laid past its limit. It needs a chain that turns tightly (bend 45 deg or more). A layer holds only about 0.3 m, so the pile is run on a table: CF_JAR=0 (no glass walls; the pile on the bare disc), 40 layers. The pile is then 26 cm tall, and h1 drifts from about 150 to 125 cm over the run (window mean about 138 cm).
- **One-at-a-time knobs:**
  - CF_ITER: solver iterations.
  - CF_MU: friction everywhere.
  - CF_STOP: the joint limit, independent of the bending the coil is laid for; 179 = effectively no stops.
  - CF_AHEAD: links woken ahead of the pick-up.
  - CF_LINK: links scaled in length, radius and mass, so mass per length is the same.
  - CF_STEPS: physics steps per second.
- **"Carried" alpha (CF_PUSH=1).** In a steady Biggins-Warner chain, T - lambda v^2 - lambda g y = -alpha lambda v^2 everywhere between pile and floor (y measured from the pick-up). The tension is not observable in Bullet from Lua, so it is reconstructed. Start at the lowest moving link: its joint to the floor was cut, so nothing pulls it from below. Going up the chain, the force on link i from link i+1 is the running sum of m(a_j - g) over links j up to i, with accelerations a_j taken from velocity differences across one physics step. T is that force's component along the line to the next link. The invariant -(T - lambda v_i^2 - lambda g y)/(lambda v^2), with v_i each link's own speed and v the landing rate, is averaged over the freely falling part 20-100 cm below the pick-up and over every step of the steady window. This is "alpha carried": the push the moving chain actually has.
- **The previous direct "pile push" is unchanged:** disc contact force minus m g for each link touching the disc, divided by lambda v^2.

### 7.2 Spiral (default jar) vs flake (table), CF_SPEED=1, steady window

| run | h1 cm | v (landing rate) | rms landing speed | h2 cm | pile push | rim | alpha carried | alpha from height | h2 / (push v^2/g) | h2 / (carried v^2/g) | landing energy (lossless with carried) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| spiral, jar, 20 deg | 149.6 | 450 | 361 | 10.7 | 0.27 | 0.14 | -0.07 | 0.05 | 0.19 | - | 44% |
| spiral, jar, 30 (default) | 150.2 | 397 | 352 | 10.5 | 0.31 | 0.31 | -0.13 | 0.07 | 0.21 | - | 42% |
| spiral, jar, 60 | 150.3 | 425 | 383 | 12.8 | 0.19 | 0.02 | 0.04 | 0.07 | 0.37 | 1.74 | 50% (52%) |
| spiral, jar, 90 | 150.3 | 432 | 380 | 13.2 | 0.17 | 0.01 | 0.03 | 0.07 | 0.41 | 2.31 | 49% (52%) |
| spiral, table, 60 | 150.3 | 419 | 382 | 10.6 | 0.20 | 0.00 | 0.04 | 0.06 | 0.30 | 1.48 | 50% (52%) |
| spiral, table, 90 | 150.3 | 425 | 374 | 9.5 | 0.18 | 0.00 | 0.01 | 0.05 | 0.29 | 5.2 | 48% (51%) |
| flake, table, 45 | 138.3 | 420 | 380 | 18.2 | 0.28 | 0.00 | 0.10 | 0.10 | 0.36 | 1.01 | 53% (56%) |
| flake, table, 60 | 138.0 | 428 | 373 | 17.3 | 0.23 | 0.00 | 0.08 | 0.09 | 0.40 | 1.16 | 51% (54%) |
| flake, table, 90 | 137.8 | 435 | 365 | 9.1 | 0.13 | 0.00 | 0.06 | 0.05 | 0.36 | 0.79 | 49% (53%) |

Speed rule with the carried alpha (flake): the rms landing speed is 0.979 / 0.972 / 0.962 of sqrt(g h1/(1 - alpha_carried)) at 45/60/90 deg.

### 7.3 One thing at a time, bend 60 deg (flake on table / spiral in jar)

| change | flake: h2/(push v^2/g), carried, energy | spiral: h2/(push v^2/g), carried, energy |
|---|---|---|
| none | 0.40, 0.08, 51% | 0.37, 0.04, 50% |
| 3600 steps/s | 0.45, 0.10, 53% | 0.24, -0.08, 43% (rim 0.17) |
| 7200 steps/s | 0.43, 0.10, 53% | 0.31, 0.00, 46% |
| 50 solver iterations | 0.43, 0.09, 52% | 0.26, 0.01, 47% |
| 100 iterations | 0.39, 0.07, 51% | 0.30, 0.02, 48% |
| friction 0 | 0.39, 0.09, 52% | 0.32, 0.00, 47% |
| no joint stops (179 deg) | 0.25, 0.04, 47% (push drops to 0.13) | 0.35, 0.02, 47% (push 0.14) |
| 5 links woken ahead | 0.50, 0.08, 51% | 0.34, 0.01, 47% |
| 15 links woken ahead | 0.25, 0.07, 50% | 0.28, -0.02, 47% |
| links half size | 0.31, 0.01, 46% | 0.33, 0.00, 45% |

### 7.4 Where along the chain the push is lost

The reconstructed invariant was also binned by position along the chain (scratch instrument; flake, 60 deg):
- It is about -0.9 to -1 on the links still lying on the pile, which are not yet moving.
- It reaches about -0.2 to -0.27 where the chain first runs at most of its speed, 2-8 cm above the pile. That is close to the measured contact push of 0.23.
- It rises to about -0.08 to -0.12 by the top of the arch, and stays there down the falling leg (-0.08 to -0.10 from 0 to 100 cm below the pick-up).
- It drifts to about -0.2 in the last 20 cm above the freeze, where the chain is most wavy.
- The chain reaches 90% or more of its speed only 4-6 cm above the pile.
- Large perpendicular joint forces (shear between rigid links) appear in the first 10 cm above the pile.

So the deficit sits between the pile and the top of the arch, in the zone where links are being dragged, lifted and brought up to speed over several links.

### 7.5 Conclusion

- **Not (a) as the main cause.** A pick-up that stays put raises the fountain somewhat: at 60 deg on the same table, 17.3 cm against 10.6. But the fountain is still only 0.36-0.40 of push x v^2/g, against 0.29-0.41 for the spiral.
- **Not (b) as an energy channel in the moving chain.** No tested model change brings the ratio above 0.50: step x2 and x4, iterations x2.5 and x5, friction 0, joint stops off, link size x0.5, look-ahead 5 and 15. Landing energy stays at 43-53% throughout.
- **The theory holds for the push the chain actually carries.** In the flake runs at the normal link size, all three Biggins-Warner relations hold with alpha_carried:
  - height within -21% / +16%;
  - landing speed within 2-4%;
  - landing energy 3-4 points below lossless.

  So the earlier "11-30% of the power lost" mostly came from using the pile's contact push as alpha. The moving chain itself loses only a few percent.
- **The real gap is at the pick-up.** The contact push the pile exerts (0.13-0.28 lambda v^2 on the flake) is 2-3 times the push the moving chain carries (0.06-0.10). In this simulation the chain is not picked up one link at a time as in the theory. It is dragged and lifted over several links, and most of the pile's upward force goes somewhere in that zone other than into the chain's tension. Where exactly, and whether that is physical, is not settled.
  - It is not step- or iteration-dependent, so it is not solver convergence.
  - It depends on the joint stops: without stops the contact push itself roughly halves, to 0.13.
- **The spiral pile and half-size links additionally lose the push between pile and falling leg.** Their carried alpha is 0.00-0.04, or below zero where the chain rubs the jar rim, while the fountain still stands at alpha_height 0.04-0.07. So for those, the flow between pile and falling leg is also not the steady one, consistent with the circling pick-up and the arch swinging.
- **Literature comparison** (computed from the paper's stated numbers, not from memory): Biggins and Warner's measured h2 = 0.14 h1 corresponds, with beta = 0, to an effective alpha = 0.14/1.14 = 0.12, below their rod model's 1/6. A real chain therefore also seems to deliver less than the idealized pick-up push. I don't know of a published direct measurement of the pile's contact force for comparison.

### 7.6 Changes in this round (demo/WyomingWill/ChainFountain/)

- **chain-fountain.lua:**
  - New experiment-only options: CF_LAYOUT=flake, CF_JAR=0, CF_ITER, CF_MU, CF_AHEAD, CF_STOP, CF_LINK.
  - The lead to the coil now starts at the coil's first point in z as well. The flake's first point is off the x axis; the spiral's is not, so default output is unchanged.
  - With CF_PUSH=1, two new console lines: the h2 that the measured push predicts, and the carried alpha.
- **README.md:** theory section rewritten with these tables. The dossier was updated.
- **Checks:**
  - Default output (CF_PUSH off) is byte-identical to the previous commit at 30 and 60 deg.
  - Cabinet vs standalone IDENTICAL: default (22 lines), CF_PUSH=1 (25), flake 60 with CF_PUSH=1 (23).
  - The 0.5 s start pause is an exact prefix match (24 lines; 27 with CF_PUSH=1).
  - 0.25x with pause = 1x (CF_PUSH=1); flake 60 at 0.5x = 1x.
  - README console blocks match a fresh run.

### 7.7 Still open

- What in the pick-up zone takes about 2/3 of the pile's contact push, and whether a real chain does the same: a contact/joint artifact of rigid capsules with cone-twist stops, or the real mechanics of a chain lifted over several links.
- Why the spiral and half-size-link runs carry about no push to the falling leg, yet still stand 5-13 cm high.
- The reconstructed tension ignores link-link contacts in the wavy falling leg. Its values are consistent with the fountain height on the flake (within 0.02 in alpha), but are not independently validated.

## 8. Is the exhibit's simulation shortcut what loses the push?

### 8.1 Why ask

To stay affordable, the exhibit uses a shortcut:
- Only about 10 links ahead of the pick-up are simulated. The rest of the coil is drawn but frozen, on a rigid disc.
- The last woken link is held at its far end by a rigid joint to a fixed body standing for the unmoved coil.
- Landed links are frozen at 2.5 cm above the floor.

The push goes missing in exactly the pick-up zone where this shortcut acts. The speed also changed by about 20% with the look-ahead count.

### 8.2 The reference: every link simulated (CF_LIVE=1)

- **Setup:**
  - All links are dynamic from t = 0, with the same capsules, joints, friction, restitution, step (1/1800 s) and 20 solver iterations.
  - No waking and no anchor. The laid coil rests on the disc placed under its lowest layer, inside the same jar.
  - 6 spiral layers, about 750 links including the 1.5 m lead.
  - Landed links are still frozen at 2.5 cm. That is 150 cm below the pick-up; leaving them on the floor (CF_NOFREEZE=1) gave h2 8.5 cm at 30 deg, the same as frozen.
  - "Laid" means released at once. "Settled" (CF_SETTLE=0.3) means the lead's floor end is held for 0.3 s while the pile settles under its own weight, after which the settled positions become the rest positions.
- **New measure (CF_PUSH=2): the unmoved pile's push.** This is the vertical contact force, from the disc and from every link not yet moved, on links already moving, minus m g for each moving link they touch. It is computed the same way in both modes. The old disc-only push is meaningless in the all-live pile, because the disc carries the whole stack.
- **Pick-up height:** the rest height of the first link, counting from the floor end, that is still within 1 cm of where it lay.
- **Runs:** 5 per case, with the jar at 146, 148, 150, 152 and 154 cm. Values are mean ± standard deviation; steady window from 1.0 s until 10 links before the coil's end.

| bend, mode | v cm/s | h2 cm | unmoved-pile push | carried push | rim push | landing energy |
|---|---|---|---|---|---|---|
| 30, all live | 399 ± 15 | 8.6 ± 0.4 | 0.49 ± 0.09 | -0.13 ± 0.08 | 0.26 ± 0.09 | 43 ± 4% |
| 30, shortcut (10 ahead) | 420 ± 17 | 10.6 ± 1.5 | 0.20 ± 0.03 | -0.01 ± 0.11 | 0.13 ± 0.13 | 47 ± 5% |
| 60, all live | 379 ± 20 | 6.3 ± 0.5 | 0.23 ± 0.03 | -0.19 ± 0.11 | 0.32 ± 0.18 | 40 ± 3% |
| 60, shortcut | 418 ± 6 | 10.8 ± 0.6 | 0.17 ± 0.01 | 0.01 ± 0.02 | 0.03 ± 0.03 | 48 ± 2% |
| 90, all live | 397 ± 30 | 5.5 ± 0.4 | 0.20 ± 0.02 | -0.16 ± 0.12 | 0.28 ± 0.18 | 42 ± 3% |
| 90, shortcut | 423 ± 3 | 11.2 ± 0.8 | 0.15 ± 0.01 | 0.01 ± 0.02 | 0.03 ± 0.02 | 47 ± 1% |

All pushes are in units of lambda v^2. h2 is the top of the chain above the pick-up.

**Reference checks:**
- Step 1/3600 s, 2 runs each: h2 8.5 and 9.4 cm (30 deg); 5.7 and 6.0 (90 deg). Carried push -0.03 to -0.06.
- Settled pile, 30 deg: h2 9.6 cm.
- Earlier 5-layer runs at 60 deg: laid 5.9 cm, settled 5.4, 3600 steps 6.4.

All of these fall within the spread.

**Shortcut look-ahead, 5-layer runs at 60 deg:**
- 5 links: v 448, unmoved-pile push only 0.04. The rigid anchor is then close enough to supply the push, and the anchor's force is not counted as a contact.
- 10 links: v 422, push 0.18.
- 20 links: woken links dragged into a heap, v 297, rim 3.7.

**Flake layout all-live (on the bare table):** not feasible. The live 25-layer stack is dragged off as a mass, giving a landing rate of 580-940 cm/s and an apparent landing energy above 100%.

### 8.3 Conclusion

- **The shortcut does not lose the push.** With every link simulated, the pile pushes as hard or harder: 0.20-0.49 against 0.15-0.20. The falling chain carries none of it: -0.13 to -0.19 against about 0 with the shortcut. Losing the pick-up push is therefore a property of rigid capsule links being lifted from a pile in this model, not of the shortcut.
- **The shortcut is not neutral.** It makes the fountain taller and keeps the chain off the rim.
  - With every link free, the moving chain drags the top of the pile and rubs the jar rim: 0.26-0.32 lambda v^2 against 0.03-0.13.
  - It runs 5-10% slower and lands with 40-43% of the drop's energy, against 47-48%.
  - Its fountain is 8.6 / 6.3 / 5.5 cm against the shortcut's 10.6 / 10.8 / 11.2 at 30 / 60 / 90 deg.
  - So the exhibit's fountain is about 1.2x (30 deg) to 2x (60, 90 deg) as tall as the full simulation of the same chain.
- **A cheaper scheme that matches:** simulate whole top layers of the coil, wake the next layer when the pick-up reaches the layer above it, and use no anchor (CF_WAKE=layer, CF_LIVELAYERS=n).
  - With 4 live layers at 30 deg, 5 runs give v 406 ± 17, h2 8.7 ± 0.6, push 0.48 ± 0.09, carried -0.09 ± 0.13, rim 0.20 ± 0.10 and landing energy 45 ± 5%: the same as all-live within the spread.
  - 3 layers match at 60 deg.
  - At 90 deg neither 3 nor 4 layers matches. h2 matches (5.5 cm), but v is 356-359 against 397 and the rim push 0.57-0.62 against 0.28.
  - With only 2 live layers the rim push is 0.5-1.6, too much.
- **Cost per frame** (10 layers, quarter speed, 1200 frames, standalone; a 60 fps frame has 16.7 ms):
  - exhibit as is: 4.4 ms;
  - 4 live layers: 21 ms;
  - all live: 35 ms.

  In the Cabinet the whole 1200-frame run, including loading the hall, takes 12.8 / 30.3 / 46.9 s. The faithful schemes would therefore drop the exhibit below 60 fps at quarter speed, and to about 12 fps at real speed (4 live layers). The exhibit's default was not changed; its README now says plainly that its fountain is up to twice as tall as the same chain simulated whole.

### 8.4 Changes and checks

- **chain-fountain.lua:** new experiment-only options CF_LIVE, CF_SETTLE, CF_NOFREEZE, CF_WAKE=layer, CF_LIVELAYERS and CF_PUSH=2. Defaults are unchanged.
- **README.md:** new "Without the shortcut" section with the table above and the costs. The dossier was updated.
- **Checks:**
  - Default output, and CF_PUSH=1 output, are byte-identical to the previous commit (30 and 60 deg).
  - Cabinet vs standalone IDENTICAL: default (22 lines), CF_PUSH=1 (25), all-live CF_LIVE=1 CF_LAYERS=6 CF_PUSH=2 (21), four live layers CF_WAKE=layer CF_LIVELAYERS=4 CF_PUSH=2 (26).
  - Pause prefix: default (10 lines in 500 frames at quarter speed); all-live with settling (18 lines).
  - All-live at 0.5x = 1x.

### 8.5 Still open

- Why rigid links lifted from a pile, live or not, pass none of the pile's contact push into the falling chain's tension in this model, and whether real bead chains (Biggins and Warner's measured h2 = 0.14 h1, i.e. alpha about 0.12) do better. The simulated full chain gives h2/h1 of only 0.04-0.06.
- Whether the strong rim drag of the all-live pile is realistic for a coiled chain. It comes from the free top layer being dragged toward the rim; a real loosely piled chain might drag less or more.
- A scheme that matches all-live at 90 deg, and one cheap enough for the exhibit.

## 9. Can a faithful mode be made cheap enough?

**Profile (coordinator's callgrind, all-live mode):** Bullet's step takes 96% of the time. Within it, the constraint solver takes 62% and collision detection 20%. Lua takes about 3%.

**Contact count per step** (eachContact, 10 layers, 30 deg):
- all-live: 880-1875 link-link contact points between links more than 10 apart along the chain (links lying on links in the pile), plus about 350-390 link-disc points; about half of all points are not yet touching (distance > 0);
- 4 live layers: 650-1020 link-link points;
- exhibit's shortcut: about 12-30 points in total.
- Links 1 or 2 apart never have contacts. bpp adds every joint with Bullet's disable-collisions-between-linked-bodies flag, so neighbour collision is already off.

**Cost per frame** (10 layers, 30 deg, standalone; 600 frames at quarter speed, 150 at real speed; budget 16.7 ms at 60 fps). Physics is compared with the every-link reference, 5 runs each (jar at 146-154 cm, 6 layers):

| mode | quarter speed | real speed | physics vs every-link reference |
|---|---|---|---|
| exhibit (10 links ahead, anchor) | 5.4 ms (Cabinet 6.9) | 22 ms | fountain 1.2-2x too tall (section 8) |
| every link live | 52 | 209 | reference |
| + resting links allowed to sleep (CF_SLEEP=1) | 53 | 208 | no gain: joints make the chain one Bullet island, and an island sleeps only as a whole |
| + only touching contact points (contact processing threshold 0, CF_CPT=0) | 48 | 187 | - |
| + 1200 steps/s instead of 1800 | 37 | 145 | - |
| + both | 33 | 132 | - |
| 4 live top layers (no anchor) | 32 | 129 | matches at 30 deg, not at 90 (60 not run; 3 live layers match at 60) |
| 4 live layers + CPT=0 | 27 | 109 | 30 deg: v 406 ± 15, h2 8.5, rim 0.20 (matches; CPT=0 is neutral) |
| 4 live layers + 10 solver iterations | 25 | 99 | 30 deg: v 372 ± 25, rim 0.52 (does not match) |
| 4 live layers + 1200 steps/s | 21 | 86 | 30 deg: v 387 ± 20, h2 8.7, rim 0.27 (matches) |
| 4 live layers + CPT=0 + 1200 steps/s | 19 | 77 | 30: v 377, rim 0.35 (edge); 60 and 90: top layers dragged into heaps (rim 1.4-1.7) |
| 3 live layers + CPT=0 + 1200 steps/s | 15.0 (Cabinet 15.1) | 62 | 30: v 396 ± 15, h2 8.0, push 0.49, rim 0.25, carried -0.10 (matches); 60: v 352 vs 379, rim 0.47 vs 0.32 (no); 90: v 354 vs 397, rim 0.61 vs 0.28 (no) |
| 2 live layers resting on a layer of fixed (static) links | - | - | 30 deg, 1 run: rim 1.19, v 347 (no; the number of live layers matters, not the bumpy support) |

Reference values at 30 / 60 / 90 deg: v 399 ± 15 / 379 ± 20 / 397 ± 30; h2 8.6 / 6.3 / 5.5 cm; rim 0.26 / 0.32 / 0.28 lambda v^2.

**Conclusion:**
- No cheaper way tried is faithful at all three bendings within the frame budget.
- The only mode under 16.7 ms at quarter speed (3 live layers, contact threshold 0, 1200 steps/s) is faithful at 30 deg (the exhibit's default bending) but not at 60 or 90.
- Nothing fits real speed. The exhibit's own shortcut already takes 22 ms per frame there.
- The exhibit's default was not changed. The new options are env-only: CF_SLEEP, CF_CPT, CF_STATICLAYERS. With them the default output is byte-identical to before.
- Checks for the 15 ms mode: Cabinet vs standalone IDENTICAL (23 lines), exact pause prefix (25 lines), 0.5x = 1x.

**Possible C++ changes in bpp** (not made):
- Expose btContactSolverInfo (solver mode flags, split impulse) and the global contact breaking threshold to Lua. The gain is probably small; CPT=0 already removes the not-yet-touching points.
- Link against a BT_THREADSAFE Bullet build and use btDiscreteDynamicsWorldMt with btSequentialImpulseConstraintSolverMt. Expect at most about 2x on the 2 cores here, less in practice.
- Neither reaches the 3-4x needed at quarter speed for every-link fidelity at all bendings, or about 13x at real speed. The cost is the hundreds of resting contacts in a live pile.

## 10. A better physical model of the chain? (16 Oct 2026)

### 10.1 What real chains do (literature, read this session)

- **Biggins and Warner, Proc. R. Soc. A 470 (2014) 20130689, arXiv:1310.4056.**
  - Chain: nickel-plated brass ball chain, 4.5 mm balls joined by 2 mm rods (balls about 6.5 mm apart), 50 m, "fed into the beaker in a random configuration".
  - Fit: h2 = 0.14 h1.
  - Rod model: a link of three beads, I = m b^2/6, gives alpha = 1/6 and h2 about h1/5 (with beta about 0).
  - Energy conservation requires alpha + beta <= 1/2. Their crude test suggests beta is small for their chain.
- **Biggins, "Growth and shape of a chain fountain", EPL 106 (2014) 44001, arXiv:1401.5810.**
  - 1 L beaker, h1 = 1.72 m, pot tilted 5.5-31 deg.
  - Fit to the fountain shapes: alpha = 0.12, beta = 0.11, against the rod model's 1/6.
  - Fountain height h2 = alpha h1 (1 - sin theta_p)/(1 - alpha - beta).
  - The paper notes the pick-up estimate ignores the pile's conformation: rods lying at random angles on a rough bed, rods moving before pick-up.
- **Pantaleone, "A quantitative analysis of the chain fountain", arXiv:1910.03125.** The coordinator gives Am. J. Phys. 2017; the arXiv page doesn't state a journal.
  - Three chains: small ball (D 0.30 cm, link 0.44 cm, 16.5 g/m), large ball (D 0.44, 0.63 cm, 34.0 g/m), bar chain.
  - Container: box 9 x 9 x 13 cm. Drops 1.29, 2.35 and 3.57 m. Maximum bending about 20 deg per junction.
  - Measured h_above/h_below: 0.12 +- 0.01 (both ball chains), 0.14 +- 0.01 (bar chain).
  - Measured speed V/sqrt(2 g h_below): 0.70 +- 0.03 and 0.69 +- 0.03 (ball chains), 0.71 (bar chain). His model predicts 0.748.
  - Model: momentum balance plus a link-container contact model with no free parameters. It predicts 0.13 for the ball chains.
  - Energy: lost in inelastic link-link collisions just above the container bottom, where neighbouring links rotate in opposite directions.
- **Virga, "Dissipative shocks in a chain fountain", arXiv:1402.6360.** Treats pick-up and put-down as dissipative shocks. From alpha = 0.12, beta = 0.11 it infers a dissipation factor f of about 0.96.
- **Simulations:** I found no published simulation that reproduces the chain fountain. I did not search exhaustively.

### 10.2 An independent reference: the ideal bead chain (bead-chain.c, outside Bullet)

- **Model:**
  - Beads of diameter 4.5 mm, 6.5 mm apart on rods that cannot stretch.
  - Bending limited to 30 deg per bead, kept geometrically as a minimum distance between next-but-one beads (as the real rods butt against the balls).
  - Beads do not overlap. Contacts with the jar floor, wall and rim are perfectly inelastic with Coulomb friction.
  - Every bead is simulated, with gravity. The method is position-based dynamics with small steps (2e-5 s, 4 Gauss-Seidel sweeps); velocities come from the corrected positions.
- **Geometry and procedure:**
  - The exhibit's jar (radius 7 cm, rim 158 cm up) and its kind of coil (spirals, all turning the same way), 3 layers.
  - The lead runs over the rim on curves within the bending limit, so no joint is laid past its limit.
  - The pile settles for 0.2 s with the lead's end held; then it is released. Beads freeze at 2.5 cm above the floor (beta = 0).
- **Measures:** the same as the exhibit's CF_PUSH=2: pile push, rim push, carried push (rebuilt from rod tensions), v (landing rate), and h2 relative to the pick-up.
- **Left out:** bead rotation and rod play (slack), air drag, restitution, and a jumbled pile.
- **Cost:** about 3 min per 2 s run.

| reference variant (3 layers, h1 152 cm) | v cm/s | v/sqrt(2 g h1) | h2 cm | h2/h1 | pile push | rim push | carried |
|---|---|---|---|---|---|---|---|
| mu 0.3 | 329 | 0.60 | 6.6 | 0.043 | 0.29 | 0.47 | -0.46 |
| mu 0.3, step 1e-5 | 334 | 0.61 | 6.4 | 0.042 | 0.24 | 0.68 | -0.57 |
| mu 0.3, rim frictionless | 412 | 0.76 | 6.6 | 0.043 | 0.21 | 0.19 | -0.12 |
| mu 0.09 (Bullet's effective value, see 10.3) | 404 | 0.74 | 7.5 | 0.049 | 0.21 | 0.09 | -0.07 |
| mu 0.09, jar 2 cm lower | 427 | 0.79 | 9.4 | 0.063 | 0.19 | 0.09 | -0.02 |
| mu 0.3, 8 sweeps | 340 | 0.62 | 5.8 | 0.038 | 0.23 | 0.65 | -0.67 |
| bend 20 deg | 406 | 0.74 | 7.3 | 0.048 | 0.25 | 0.36 | -0.29 |
| pile top 0.3 cm above the rim | 379 | 0.69 | 7.1 | 0.046 | 0.27 | 0.19 | -0.30 |

**Not working in the reference:**
- 5-layer and 8-layer coils (pick-up 3 cm under the rim) jammed: the chain stalled within about 1 s.
- A jumbled heap jammed too. The heap was built as a self-avoiding random walk with bends up to 30 deg, working down the jar.

So the reference cannot say what a heap does.

**What it shows:**
- An ideal chain of the real kind, simulated exactly and lifted from this coil in this jar, also gives h2/h1 = 0.04-0.06, not the experiments' 0.12-0.14.
- Its pile pushes (0.19-0.29), but the falling chain carries none of it (carried push -0.02 to -0.67).
- The lying chain holds the moving chain back about as much as the pile pushes, and the chain rides on the rim.
- The speed (0.60-0.79 of sqrt(2 g h1)) is close to the experiments' 0.70.

### 10.3 The Bullet model against the reference

- **Bullet friction is a product.** For each contact Bullet multiplies the two bodies' friction coefficients. The exhibit sets 0.3 on links, glass and disc alike, so every chain contact actually has mu = 0.09.
  - With mu set so the product is 0.3 (0.548 each), the all-live Bullet chain gives h2 = 8.6-9.8 cm (30 deg) and 5.1-5.7 cm (90 deg), 3 runs each.
  - That is the same as with 0.09: 8.6 +- 0.4 and 5.5 +- 0.4.
- **Bullet matches the reference.** Bullet all-live at 30 deg gives v 399 +- 15, h2 8.6 +- 0.4 cm (h2/h1 0.057), rim 0.26, carried -0.13. The reference with mu 0.09 gives v 404, h2 7.5 cm (0.049), rim 0.09, carried -0.07. The same regime.
- **Earlier one-at-a-time changes to the Bullet chain didn't help either:**
  - joint stops off;
  - finer links (0.5 scale);
  - step 1/3600 and 1/7200 s;
  - 50 and 100 solver iterations;
  - friction off;
  - stationary pick-up (flake pile).

  None of these raised the fountain toward 0.12-0.14 (sections 7-8).

### 10.4 Conclusion and recommendation

- The low fountain is not caused by Bullet's capsule links, cone-twist joints, joint softness, step or solver. An exact bead-chain model gives the same result in the same jar and coil.
- What the experiments have and neither model has is their pile: 30-75 m of chain fed in at random, a jumbled heap.
- Biggins's own EPL paper names the pile's conformation (rods at random angles on a rough bed, rods moving before pick-up) as what the simple pick-up estimate leaves out.
- Testing a heap needs a simulation that can lift chain from a heap without jamming. My reference jammed, so this is open.
- Within what was testable, there is no better model to adopt: keep the exhibit as is. The default is unchanged; the new env-only option is CF_GLASSMU.
- Fixing the friction documentation is a one-line change. I did not change the default friction, because it doesn't change the fountain.

## 11. The heap test: does a poured, jumbled pile give the real fountain? (16 Oct 2026)

Repo: the exhibit folder demo/WyomingWill/ChainFountain/. All numbers are from fresh headless runs in this round unless marked otherwise. The raw run outputs, dumps and plots were working files and are not in the repo; the runs can be repeated with the commands in the README and the dossier.

### 11.1 Question and hypothesis

From the exhibit's ordered flat-spiral coil, the full Bullet chain (CF_LIVE=1) and the earlier exact bead reference (reconstruction/bead-chain.c) both give h2/h1 = 0.04-0.06. Real ball chains give 0.12-0.14 (Biggins and Warner 2014: 0.14; Pantaleone, arXiv:1910.03125: 0.12 +- 0.01 for ball chains, 0.14 for a bar chain; read in the previous round). The experiments feed the chain "into the beaker in a random configuration", and Biggins (EPL 106, 2014, 44001) names the pile's conformation as what the simple pick-up model leaves out. Hypothesis: the coil is the problem; a jumbled heap gives the real fountain.

### 11.2 Method

- **Chain** (both engines): Biggins and Warner's geometry. Links 0.65 cm joint to joint, 4.5 mm thick, 1500 links = 9.75 m, bending limit 30 deg per joint. In Bullet: capsules radius 0.225 cm, length 0.65 cm tip to tip (`CF_LINK=0.4333 CF_RADIUS=0.225`), the link's mass at its two ends as a ball chain's is in its balls (`CF_BEADI=1`: I = m L^2/4 + 0.4 m r^2 about the centre), cone-twist joints at the tips. Friction 0.3 per contact (`CF_MU=0.548`; Bullet multiplies the two bodies' values), no restitution, 1800 steps/s, 20 iterations.
- **Pour** (`CF_POUR=1`): the chain hangs from a scripted hand (a fixed body joined to the top link) 6 cm above the jar's floor; the hand wanders (random walk of its velocity, kept within 2 cm of the axis, seed `CF_SEED`) and lowers the chain at 1 m/s, a new link added above at a time; the end goes in last. Then it settles (until the fastest link is under 1 cm/s, at most 2 s), the end still held. Then the hand draws the end straight up to 4 cm above the rim, out to x = 12 cm at 1.5 m/s, and down to 3.5 cm above the floor at 1.2 g (faster than free fall, so the chain is taut), and lets go (t = 0). Nothing is placed by hand. Heaps: 3.5-4 cm high over the jar floor, spread over it (median radius 4 cm). Settled state: fastest link 0.6-3.8 cm/s, kinetic energy <= 6e-7 of a link's at 4 m/s (Bullet; new console field), reference total KE 9-124 (unit bead masses, cm^2/s^2), i.e. <= 1e-6 per bead of a bead at 4 m/s.
- **Control** (`CF_POUR=2`): the same 1500 links laid as the exhibit's coil (flat spirals within the bending limit) on the jar floor, settled and drawn over the same way.
- **Measurement:** the exhibit's own theory check with `CF_PUSH=2`: v = landing rate, h1 (pick-up above the freeze height, about 148 cm), h2 (top of the moving chain above the pick-up), the unmoved pile's push, the rim's push, the push the falling chain carries (from tensions rebuilt from link accelerations), landing energy; steady window from 1 s after letting go until 10 links before the end (0.6-1.0 s, about 2-4 m of chain). Pick-up: the first link from the floor end still within 1 SCALE (0.43 cm) of where it lay at let-go.
- **Reference:** reconstruction/bead-pour.c (left uncommitted by the previous investigator; kept and extended). Beads D = 0.45 cm, L = 0.65 cm, inextensible rods, bending limit as a minimum next-but-one distance, inelastic contacts, Coulomb friction 0.3 applied on velocities, XPBD with substeps HS = 1e-5 s and ITERS = 4 constraint passes per substep, same jar, same pour/pull/freeze procedure. Added this round: **solid rods** (ROD = 0.05 cm radius; rod-rod segment contacts and rod-glass contacts at three points on the bare part of each rod), because with bare 4.5 mm beads 6.5 mm apart two rods crossing at their middles leave the beads 4.6 mm apart and the chain can pass through itself. Unit test: a rod pushed down onto a crossing rod stays at 2 ROD. ROD = 0 reproduces the old binary's output exactly.
- **Reference friction check fixed:** the groove check (LAYOUT=3: a chain drawn along a groove of two fixed rows of beads) had a groove shorter than the pull, so the chain ran off its end; it read 3.8x Coulomb at every setting (this is why the previous note in the file said "3.6x ... fixed"). With a long enough groove: ITERS=4, HS=1e-5: 1.087 (0.09 of it is the bumps of the rows: MU=0 gives 0.09); ITERS=2 or 8 at 1e-5, or ITERS=1 at HS <= 7e-6: 1.09-1.10; **ITERS=1 at 1e-5: 5.0x** and ITERS=2 at 2e-5: 4.5x (friction limited by an overdone normal push). The floor check is 1.000 throughout. So the previous investigator's D = 0.6, ITERS = 1, HS = 1e-5 heap runs (h2/h1 0.06-0.12) were over-gripping and are void; the same settings with HS = 5e-6 gave 0.095 (heap 1) and 0.061 (heap 2, rim 1.17), with ITERS=4 0.067 (rim 0.60) - D = 0.6 beads, not the experiments' geometry, and not used below.

### 11.3 Results, ball chain in the exhibit's jar (h1 = 148 cm)

Bullet, heap, friction 0.3 per contact:

| run | v cm/s | v/sqrt(2gh1) | h2/h1 | pile push | rim | carried | E% |
|---|---|---|---|---|---|---|---|
| pour 1 | 426 | 0.79 | 0.128 | 0.19 | 0.00 | 0.11 | 52 |
| pour 2 | 430 | 0.80 | 0.147 | 0.16 | 0.00 | 0.12 | 53 |
| pour 3 | 419 | 0.78 | 0.119 | 0.16 | 0.00 | 0.08 | 50 |
| pour 4 | 404 | 0.75 | 0.109 | 0.17 | 0.03 | 0.02 | 47 |
| pour 5 | 369 | 0.69 | 0.116 | 0.21 | 0.43 | -0.21 | 40 |
| mean +- sd | 410 +- 25 | 0.76 +- 0.05 | 0.124 +- 0.015 | 0.18 | | | |
| pours 1-3 at 3600 steps/s | 433, 442, 434 | 0.80-0.82 | 0.132, 0.159, 0.135 (0.142 vs 0.131) | 0.23-0.26 | 0.00 | 0.08-0.15 | 52-56 |

Bullet heap variants: friction 0.09 per contact (the exhibit's effective value; `CF_PILE=heap CF_POUR=1`, pours 1-3): 0.133, 0.103, 0.061 (rim 0.63); earlier same-friction runs at CF_LINK=0.4333 (previous investigator): 0.144, 0.142. Friction 0 (pour 1): 0.126. Uniform-rod inertia instead of balls (`CF_BEADI=0`, pours 1-2): 0.138, 0.059 (rim 0.86).

Bullet, coil: never steady. Jar at 150 cm: v 238 cm/s (0.44) and falling, h2/h1 0.057, rim 2.6 m v^2, carried -1.8, E 22%; 148: v 148, 0.055, rim 7.0; 152: v 141, 0.055, rim 10.9; friction 0.09: v 107. 3600 steps/s: stops within 1 s (500 of 1500 links out, then under 15 cm/s; killed at 6.25 s). Friction 0 everywhere: stops at 6.9 m out; a position dump at 4 s shows the remaining ~200 links pulled into a knot against the inside of the rim, with the hanging chain lying against the jar's outer wall. Coil on a bare table (CF_JAR=0): the whole coil is dragged off; not usable.

Reference:

| run | v/sqrt(2gh1) | h2/h1 | pile push | rim | carried | E% |
|---|---|---|---|---|---|---|
| heap 1 (p1) | 0.84 | 0.183 | 0.28 | 0.26 | -0.04 | 48 |
| heap 2 (p2) | 0.53 | 0.123 | 0.42 | 1.47 | -1.12 | 30 |
| heap 3 (p3) | 0.84 | 0.148 | 0.31 | 0.00 | 0.04 | 48 |
| heap 1, HS 5e-6 (f1h5) | 0.86 | 0.174 | 0.30 | 0.00 | 0.09 | 52 |
| heap 2, HS 5e-6 (f2h5) | 0.85 | 0.157 | 0.26 | 0.11 | 0.04 | 51 |
| heap 1, ITERS 8 (f1i8) | 0.77 | 0.190 | 0.25 | 0.49 | -0.30 | 43 |
| coil (c) | 0.44 | 0.058 | 0.31 | 2.16 | -1.95 | 17 |
| coil, HS 5e-6 (ch5) | 0.79 | 0.060 | 0.10 | 0.67 | -0.50 | 35 |

Reference coil with frictionless glass (cmr0): the whole coil is set moving, no bead stays at rest, no pick-up and no steady part.

### 11.4 Conclusion (case 1 holds, for a ball chain of the experiments' size)

- Poured as the experiments do it, a chain of their size gives their fountain in both engines: h2/h1 = 0.11-0.16 (Bullet, 8 runs, mean 0.13) and 0.12-0.19 (reference, 6 runs, mean 0.16), against 0.12-0.14 measured. In the runs where the chain clears the rim, the falling chain carries a real push (0.02-0.15), unlike every coil run in either engine.
- Laid as the exhibit's coil, the same chain picks up at the wall, is drawn up the glass and over the rim, and rides on it: h2/h1 0.058-0.060 (reference) or stalls (Bullet), the rim holding the chain up with 0.7-11 m v^2, carried push strongly negative. So **the coil was the problem**, through the rim: the coil's pick-up runs round the wall, the heap's sits in the middle.
- Not a numerical artefact: two independent engines agree; halving the step moves the heap result by less than the pour-to-pour spread (Bullet +8% on the mean of 3 pours; reference -5% and +28%); 8 passes instead of 4 give 0.190 against 0.183. Not friction or inertia (friction 0 / 0.09 / 0.3 and rod vs ball inertia all give 0.10-0.15 when the chain clears the rim).
- Caveats: (a) about 1 pour in 4 (Bullet pour 5, reference pour 2, and 2-3 of the 6 reloads at friction 0.09) catches the rim and runs slow at h2/h1 0.06-0.12: the flow seems to have two states, clear of the rim and on it. (b) The chain runs at 0.69-0.80 (Bullet) and 0.84 (reference) of sqrt(2 g h1) against 0.69-0.71 measured; there is no air drag, and the freeze makes b = 0 exactly. (c) Windows are short (0.4-1 s, 2-4 m) because 9.75 m is all a 7 cm jar holds; the experiments used 30-75 m. (d) The pick-up's pull is by a scripted hand, as "dragged over the rim and released" (Biggins 2014, as quoted in bead-pour.c by the previous investigator).

### 11.5 The exhibit's own 1.5 cm links

Poured the same way (`CF_POUR=1 CF_NLINKS=450`; `CF_T0=0.5` because 6.75 m runs out early), the coarse chain cannot loop tighter than L/(2 sin 15 deg) = 2.9 cm and lays itself round the jar wall in rings: a self-made coil, not a heap. h2/h1 = 0.105, 0.082 (rim 0.45), 0.106, 0.078 (4 pours) against the POUR=2 coil 0.057, 0.077, 0.064 (jar at 150/148/152). With ball inertia (pour 2): 0.104. 700 links fill the jar to the rim (heap top 7.3 cm) and partly siphon out during the pour (24 and 13 links outside; 0.069-0.084); two 450-link pours at 3600 steps/s siphoned out entirely (446 links outside) and gave no run. So the exhibit's chain stays low however it lies in this jar; the fix needs the finer chain.

### 11.6 The exhibit from a poured heap: CF_PILE=heap (first version; replaced in section 12)

- What it does: the ball-chain-sized chain (as 11.2, friction from the slider, default 0.3 = 0.09 per contact), drawn with chain-fountain-meshes/bead-link.obj (gen-link.py, r 0.225, L 0.65), starts from chain-fountain-meshes/heap.txt (the joint points from the end on, in cm above the jar floor; pour seed 1 at the exhibit's friction). The heap is 1500 fixed bodies. Ten links ahead of the pick-up are live (no more than 1200/SCALE a simulated second), each live link held by a cone-twist joint to a fixed neighbour; any fixed link whose centre is within L + 2 r + 0.2 cm of a moving link still in the heap (from 20 links before the pick-up on) and more than r higher is woken (so nothing fixed pins the chain down; links it slides over stay fixed). A link is re-searched only after it has moved 1 mm. No settle phase; the hand draws the end over immediately.
- Two earlier versions failed: (1) the previous investigator's chain-order version (10 ahead, rest fixed) jammed in all 3 heaps (chain stuck at 0.7 m out; the next links lie under fixed ones); (2) waking every fixed link near any moving link cascaded to ~1000-1500 live links (no saving; it matched the full runs: 0.146, 0.106, 0.062).
- **A Bullet/bpp determinism trap found:** bpp's remove() takes a body's joints out of the world by iterating a QSet (pointer order), and Bullet's removeConstraint swaps the last joint into the hole, so removing a body with two joints reorders the solver's joint list unpredictably. The heap option was therefore not reproducible run to run (and CF_PUSH or CF_DUMP changed it) until wakeHeap removed the two hold joints one by one before removing the fixed body. Now identical run to run. The default coil never removes a body with more than one joint, which is why it was always deterministic. (Possible bpp fix in src/, not made: remove a body's joints in a fixed order.)
- Check against the full heap (same 3 heaps, every link live, friction 0.09):

| | h2/h1 | v/sqrt(2gh1) | pile push | rim |
|---|---|---|---|---|
| every link: pour runs | 0.133, 0.103, 0.061 | 0.58-0.79 | 0.15-0.47 | 0.03-0.63 |
| every link: heap reloaded (re-settled) | 0.120, 0.073, 0.058 | 0.62-0.79 | 0.16-0.37 | 0.01-0.49 |
| every link: reloaded, 3600 steps | 0.160, 0.069, 0.100 | 0.67-0.84 | 0.19-0.58 | 0.00-0.50 |
| CF_PILE=heap, 1800 (default) | 0.165, 0.150, 0.168 | 0.73-0.81 | 0.09-0.12 | 0.00-0.31 |
| CF_PILE=heap, 3600 | 0.199, 0.184, stuck at the rim | 0.84 | 0.09-0.11 | 0.00 |
| CF_PILE=heap, 1200 | 0.092, 0.096, 0.054 | 0.42-0.75 | -0.08-0.07 | 0.02-2.28 |

  Full: mean 0.097 over 9 runs (chaotic: reloading the same heap changes 0.103 to 0.073). Option: mean 0.161, 1.6x taller, a third of the push, not step-converged (0.09 / 0.16 / 0.19 at 1200 / 1800 / 3600 steps/s), and one run (heap 3, 3600) stuck at the rim right after let-go with a 60 cm spike (a hold joint under load). As with the coil, freezing the pile makes the fountain taller.
- Cost per frame, quarter speed, standalone, idle machine (2 cores): exhibit 5.1 ms (1200 frames, 6.1 s); CF_PILE=heap 18.8 ms (800 frames, 15.1 s; the Lua search is 2.4 s of the 15 s; before it was limited to links near the pick-up and to links that had moved, it was 18 s of 32; CF_CPT=0 gains 3%; CF_STEPS=1200 13.7 ms but changes the physics); every link of the heap (CF_LIVE=1) 58 ms (1300 frames, 75 s). Cabinet incl. hall load: exhibit 11.9 s / 1200 frames, heap option 21.3 s / 850. Budget 16.7 ms. Live links in the option: ~540 at let-go (incl. ~250 in flight), 330-410 in the window.
- Verdict: the exhibit can start from a poured heap, but not faithfully or within budget. Default unchanged.

### 11.7 Files changed this round

- demo/WyomingWill/ChainFountain/chain-fountain.lua: kept the previous investigator's CF_POUR/CF_HEAP/CF_SAVEHEAP/CF_RADIUS/CF_BEADI machinery, with fixes: heaps saved as joint points from each link's pose (was centres; rebuilding joints halfway between centres shortens links where the chain bends, about 7% at two 30-degree bends, which the solver then kicked straight) relative to the jar floor; CF_POUR no longer overridden by a heap file; settle line prints kinetic energy. New: CF_PILE=heap (defaults for the ball chain, mesh, shipped heap), the heap shortcut (wakeHeap, heapFeed, hold joints removed one by one), nMoving() (true live count in heap mode), CF_T0, CF_DUMP=t:file, CF_CPT honoured in heap mode, header comment. Default and earlier experiment outputs unchanged (11.8).
- New: chain-fountain-meshes/bead-link.obj, chain-fountain-meshes/heap.txt.
- reconstruction/bead-pour.c (new file, from the previous investigator): rods (ROD), friction check fixed (groove long enough, rail placed along the pull), RESULT line with iters/d/rod/settleKE, header rewritten with the checks.
- reconstruction/bead-chain.c: the previous investigator's DUMPT option, kept.
- README.md: "The heap test" section, options list, files list. Dossier demo/WyomingWill/Cabinet/report/dossiers/ChainFountain.md: model line, four table rows, run lines, checks, caveats, references.

### 11.8 Checks

- Default output (quarter speed, default 0.5 s pause, 1230 frames), CF_PUSH=1 (300 frames, 1x), CF_LIVE=1 CF_LAYERS=6 CF_PUSH=2 (400 frames): byte-identical to HEAD f7027b4 (24, 27, 23 lines).
- cmp2.sh: default 1200 frames IDENTICAL (22 lines); CF_PILE=heap 850 frames IDENTICAL (16 lines).
- CF_PILE=heap: HOLD_S=0 780 frames is an exact prefix of the default pause for 810 frames (18 lines); 0.5x = 1x with CF_PUSH=2 (22 lines); 0.25x with pause = 1x.
- Determinism: CF_PILE=heap run twice, and with CF_PUSH=2, gives identical lines (after the joint-removal fix).

### 11.9 Still open

- Why a heap's flow is sometimes caught on the rim (two states?), and how often a real chain does that; a jar with the pick-up further from the rim, or a longer chain, would show it.
- Bullet step convergence of the heap fountain (+8% on the mean of three pours at friction 0.3; single reloads at 0.09 went from 0.120 to 0.160 and from 0.058, on the rim, to 0.100, clear of it) and of the option (x2 from 1200 to 3600 steps/s).
- A shortcut for the heap that matches the full heap at lower cost: the woken set must include links the chain drags, not only links lying on it; the cascade version matched but woke ~1000 links.
- The exhibit's own fountain stays at 0.06-0.08 with its 1.5 cm links; a faithful exhibit needs the finer chain and about 58 ms a frame for every link (or a better shortcut).
- From memory, not checked here: Macklin et al. SCA 2019 (small steps), Mueller et al. SCA 2020 (XPBD friction), Ericson 2005 sec. 5.1.9 (segment nearest points); the 1 mm rod thickness of a 4.5 mm ball chain is an assumption.

## 12. A faithful heap shortcut within the frame budget? (16 Oct 2026)

The raw run outputs were working files and are not in the repo.

### 12.1 Setup

- Chain as section 11 (`CF_PILE=heap`: links 0.65 cm, r 0.225, ball inertia), **true friction 0.3** (CF_MU=0.548). Five new heaps poured with `CF_PILE=heap CF_MU=0.548 CF_POUR=1 CF_SEED=1..5 CF_SAVEHEAP`; their own pour runs: h2/h1 0.085, 0.129, 0.139, 0.093 (rim 0.91), 0.125 at ERP 0.2.
- Reference = every link simulated from the same saved heap (CF_LIVE=1), same settings, 5 heaps.

### 12.2 The reference itself was not step-converged (new)

Every link, ERP 0.2 (Bullet's default): h2/h1 mean 0.131 (1800 steps/s, 5 heaps), 0.160 (3600, 5), 0.150 (7200, 3). Raising the joints' error correction: ERP 0.5: 0.148 (1800), 0.145 (3600); ERP 0.8: 0.135 (1800); ERP 0.5 at 1200: 0.118. So at 1800 the joints give too much at ERP 0.2; ERP 0.5 converges 1800 (a numerical setting chosen by step convergence, not to hit a value); 1200 is not converged at any ERP tried. Final reference (ERP 0.5, CPT 0): 0.140 (0.117-0.160) at 1800, 0.137 (0.093-0.167) at 3600; v 398-457; rim 0-0.29; carried -0.09 to 0.14; pile push 0.17-0.29.

### 12.3 Why the first CF_PILE=heap was too tall, and the live zone

The first option (heap fixed; 10 ahead; links lying on the chain woken) gave 1.6x the full fountain: the fixed heap can't be dragged. New scheme (`heapFeed`, CF_ZONE/CF_ZDEPTH): every heap link within R of the pick-up (or R across and at most d below it) is live; a live heap link 1 cm outside that and slower than 1 cm/s is fixed again (checked every 18 steps); live links next to fixed ones are held to them by cone-twist joints. Convergence in the zone (ERP 0.5, CPT 0, 1800; mean h2/h1 of 5 heaps vs reference 0.140): R 3 / d 0.5: 0.161 (3600: 0.168); R 3 / d 1: 0.155; **R 4 / d 0.5: 0.147 (3600: 0.145; 0.164 without one run caught on the rim)**, v 416-445, rim 0-0.17, carried 0-0.13, pile push 0.13-0.20 (slightly below the reference's 0.17-0.29). Earlier ERP-0.2 series (with a bug, see 12.5) showed the same trend: ball R 1.5 / 2.5 / 4 stand 16% / 4% / -7% vs the reference.

### 12.4 Cost: what stands in the way

- Measured during the flow (t 0-1.75 s; the whole-run average hides it because frames after the chain is out are cheap). Quarter speed, standalone (Cabinet): exhibit 4.8 (5.4) ms; R 4 zone 27.5 (30.0); R 3 zone 22.5 (24.4); 10 ahead only, no zone 13.5; every link 36.4. Whole run: R 4 21.8 (24.0), exhibit 4.8 (5.4), every link 48.8.
- The falling 1.5 m of 0.65 cm chain (~280 live links) alone costs ~13.5 ms; the converged zone adds ~14. Callgrind (zone run): physics 82% (solver 52%, of which iterations 38%; collision 18%; body removal 7%), Lua 14%. But solver iterations 5 instead of 20 save only 12% of the frame: the cost is per body and per joint (setup, cone-twist getInfo, AABBs), which needs src/ changes (not touched).
- **At 1/8 real speed the R 4 mode fits: 14.1 ms during the flow, 14.3 in the Cabinet** (whole run 11.4 / 11.7, 1418 frames). Nothing faithful fits at 1/4.
- Rendering: under xvfb (software GL, no GPU) 186 ms a frame for the heap mode vs 77 for the exhibit; bpp batches only fixed boxes and cylinders, so the heap's 1500 links and the landed ones are drawn one by one. Not measured on a GPU.
- Not tried: a lower stand (in-flight links scale with h1; the zone cost stays) - it would also bring the fountain's top near the rim.

### 12.5 Bugs found and fixed on the way

- `.trans` of a moving body (bpp Object transform) is the last frame's drawn transform, not the body's current one: refreezing with it placed fixed links turned wrongly (all zone runs before the fix are void; redone). Now `body:getOrientation()`; the heap saver uses it too.
- Creating new fixed bodies during the run made hall and standalone runs differ: bpp's updateMovedAabbs remembers fixed bodies' boxes by address and clears the whole map when it grows (timing differs in the hall). Fix: each heap link has one fixed body for the whole run, parked at (5000 + 2i, -1000, 0) while the link moves (body:setWorldTransform + .trans), brought back when refrozen. Now IDENTICAL.
- From before: removing a body with two joints reorders Bullet's joint list (QSet order); holds are removed one by one.

### 12.6 What was done

- chain-fountain.lua: CF_ZONE/CF_ZDEPTH live zone with refreezing and parking (fixHeap, freezeHeap, inZone, heapFeed), CF_ERP (set at load and before every frame), CF_PILE=heap defaults now R 4, d 0.5, ERP 0.5, CPT 0, friction slider 0.548, speed 1/8 (slider step 0.025, Z 1/8 <-> 1); heapTop kept current; zone search limited to the heights it can reach and re-run only after the pick-up moves 5 mm. Coil default untouched.
- chain-fountain-meshes/heap.txt replaced by heap 2 of the five (true friction 0.3).
- README: the CF_PILE=heap section rewritten (table, cost, console block from a fresh run); options list. Dossier: model line, table rows, caveats, checks, default-change recipe.

### 12.7 Checks

- Default (1230 frames with pause), CF_PUSH=1, CF_LIVE=1 CF_LAYERS=6 CF_PUSH=2: byte-identical to 4b48858.
- cmp2: default 1200 IDENTICAL (22); CF_PILE=heap 1500 IDENTICAL (15).
- CF_PILE=heap: pause prefix exact (17 lines); 1x = 0.5x = 0.25x = 1/8 (17 lines).

### 12.8 To make it the default (done the same day: section 13)

`local HEAPPILE = os.getenv("CF_PILE") == "heap"` -> `local HEAPPILE = (os.getenv("CF_PILE") or "heap") == "heap"`; CF_PILE=coil keeps the coil. Console then: "--- 9.8 m of chain, 1500 links; ...", "drawn over and let go (0.64 s)", end about t = 2.25 s, h2/h1 about 0.14 (0.140 with the shipped heap). README What it does / bending table / Keys / Simulation / help text to rewrite; the layers slider becomes inert; bendings under 30 deg kick the heap's joints.

### 12.9 Still open

- A faithful mode at quarter speed: needs ~2x less per-body work in bpp/Bullet (src/), or fewer live links than physics allows here.
- The zone's pile push is ~25% low although the fountain matches.
- GPU rendering cost of ~3000 individually drawn meshes.
- About one run in ten catches the rim in both the reference and the mode.

## 13. The heap made the default (16 Oct 2026)

The user ran CF_PILE=heap in the GUI: "very smooth, a nice speed", and
h2/h1 = 0.140, as here. So the heap is now the exhibit's default.

### 13.1 What changed

- chain-fountain.lua: the pile is chosen by setMode(heap): the default is
  the heap (CF_PILE=coil for the coil headless). Everything the pile
  decides (link size, thickness, mass at the ends, mesh, heap file, zone,
  error correction 0.5, touching contacts, starting speed 1/8, friction
  slider 0.548) is set there, so the pile can change while it runs.
- **H** switches heap <-> coil and starts again (shown in the Shortcuts
  pane; H is not one of bpp's keys S, D, R, P, nor the hall's Tab). It
  puts speed and friction to the new pile's own; the other sliders keep
  their values. Headless check: heap -> coil gives the coil's run line for
  line as the coil started on its own, and coil -> heap the heap's.
- Sliders with the heap: **bending stays 30 degrees** (the heap was poured
  with joints that bend 30; any other limit would kick its joints straight
  or let it lie as it never could). Moving it puts it back to 30 and the
  console says why, once. Pouring a heap for each bending would be the
  other honest way; it was not done because each would need its own check
  against every link simulated. **Layers** does nothing with the heap (a
  note, once). **Steps** go no lower than 1800 (at 1200 the heap's fountain
  is lower, 0.118, not converged). **Friction** restarts the heap (a heap's
  fixed links and the glass take it only at a start). Height works as it
  did (the heap is stored from the jar's floor up).
- Console, heap only (the coil's is unchanged, byte for byte):
  - the rod-model figure (-0.10, meaningless for links whose mass is at
    their ends) is replaced by: "the rod model gives none for balls on
    light rods; 1/6 for their three-ball links";
  - a new line says the window is not steady: the chain lands at 447 cm/s
    in the first half of the window and 416 in the second, as the heap runs
    out, so the speed rule (which needs a steady chain) is unreliable
    there. The window itself (1 s after letting go until ten links before
    the end) is kept as it was, so numbers stay comparable with sections
    11-12; moving it to make the two readings agree would be fitting it.
    The falling chain is also wavy (rms landing speed 389 against the
    431 cm/s length rate).
- README: What it does, the theory check (the heap's run first, then the
  coil's), Keys, sliders, Simulation and the help text rewritten for the
  heap; the coil kept as the comparison. This file added.

### 13.2 The default run (an eighth of real speed, 0.5 s pause)

```
--- 9.8 m of chain, 1500 links; the jar 150 cm up; joints bend 30 deg at most ---
drawn over and let go (0.64 s)
t= 0.25s  fountain 12.3 cm above the rim (average 11.3, highest 13.4); chain 529 cm/s; 564 links moving, 1.2 m out
t= 0.50s  fountain 16.4 cm above the rim (average 15.1, highest 16.5); chain 489 cm/s; 691 links moving, 2.4 m out
t= 0.75s  fountain 16.1 cm above the rim (average 16.3, highest 17.2); chain 435 cm/s; 580 links moving, 3.5 m out
t= 1.00s  fountain 17.3 cm above the rim (average 17.5, highest 18.2); chain 451 cm/s; 529 links moving, 4.6 m out
t= 1.25s  fountain 15.0 cm above the rim (average 14.9, highest 18.2); chain 444 cm/s; 482 links moving, 5.7 m out
t= 1.50s  fountain 11.5 cm above the rim (average 12.5, highest 18.2); chain 413 cm/s; 425 links moving, 6.8 m out
t= 1.75s  fountain 11.0 cm above the rim (average 11.1, highest 18.2); chain 379 cm/s; 302 links moving, 7.8 m out
t= 2.00s  fountain -108.1 cm above the rim (average -64.4, highest 18.2); chain 636 cm/s; 172 links moving, 8.6 m out
t= 2.25s  all of it out of the jar; the fountain stood up to 18.2 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-1.64s; h1 = 148.3 cm, the pick-up above where a link lands (the rim is 7.2 cm above the pick-up)
  chain 431 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 381 cm/s and not rise above the pick-up
  top of the chain 20.7 cm above the pick-up on average (h2): h2/h1 = 0.140 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 407 cm/s
  a = g h2/v^2 = 0.11 from the height, 1 - g h1/v^2 = 0.22 from the speed (the rod model gives none for balls on light rods; 1/6 for their three-ball links)
  not steady: links land at 447 cm/s in the first half of that window and 416 in the second (the heap running out); the speed rule needs a steady chain, so its reading here is unreliable
  the links reach the floor at 389 cm/s (rms), with 52% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
```

### 13.3 Checks

- CF_PILE=coil: byte-identical to the previous default (with pause 1230
  frames; 1x 300 frames; CF_PUSH=1).
- Hall identity (cmp2): heap 1500 frames IDENTICAL (16 lines); coil 1200
  frames IDENTICAL (22).
- Pause prefix: heap HOLD_S=0 1400 frames an exact prefix of the default
  1500 (18 lines); coil 1170 of 1230 (24).
- Speed: heap 1x = 1/4 = 1/8 (18 lines); coil 1x = 1/8 = 1/4 (24).
- H: heap -> coil and coil -> heap each give exactly the run of the pile
  started on its own (headless, the key's function called after start);
  in the GUI under xvfb, H switched and restarted both ways.
- The Cabinet loads all 21 exhibits.
- Cost at the default speed, during the flow / whole run: standalone 14.0
  / 11.2 ms a frame, Cabinet 14.8 / 12.1 (coil at its 1/4: 4.6 / 4.7,
  Cabinet 5.3 / 5.4).
