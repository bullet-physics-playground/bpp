# Linkages That Compute: findings

What was measured while building the linkages (2026-11-26). All runs
headless, 600 steps a second and the solver at 80 iterations, unless
said. A sweep is the tour and twenty settings at random: x from 5 to 9
(the inverter), a from 2 to 5 and b from −5 to 5 (the multiplier), the
crank across ±30° to ±80° and back (the line).

## 1. What the Walker Room had already found

The Walker Room's Jansen walkers (`demo/WyomingWill/WalkerRoom/README.md`,
`Walkers/Jansen_6Leg_parts.lua`) are linkages of a dozen bars a leg, and
they had settled how to build one in Bullet:

- **Stiff hinges and more solver iterations, not softening.** Softening the
  hinges (CFM) let the joints give, and the legs' geometry with them;
  `v:setSolverIterations(40)` with stiff hinges held them.
- **A hub where more than two parts meet.** One part takes the joint and
  the others hinge to it; three bars hinged pairwise at one point fight.
- **Planes.** Bars 3 mm thick on planes 7 mm apart; bars hinged together
  are in different planes, so they never touch. Bars that never meet may
  share one.
- **Merge rigid triangles into one body**, and pre-centre each mesh (an
  OpenSCAD `centerOfMass` recentres only the collision shape).

All of these carried over. The inverter's six bars use planes 1 to 4
(the arms in 1 and 2, the rhombus's sides in 3 and 4, each side in a
different plane from the two it hinges to), O is a pin on the board that
both arms hinge to, and the carriage or crank is in plane 0.

## 2. A hinge pins both its points, in every direction

The first prototype of the inverter read Q **16% off** 100 / x. The bars
leaned: the rhombus's corners rose and fell out of their planes.

`btHingeConstraint` takes a point on each body and holds the two points
together in all three directions (and the axes parallel). A pin through
two bars in different planes, 7 mm apart, given the same point at each
bar's own centre, pulls the bars 7 mm toward each other: the solver splits
the difference by tilting both. The fix: each hinge's point on the first
bar is raised (or lowered) to the second bar's plane, so the two points
coincide where they are, and the pin, in effect, runs from one plane to
the other:

    pa2 = btVector3(pa.x, pa.y + planeY(B.plane) - planeY(A.plane), pa.z)

With that, the inverter's worst error fell from 16% to **0.04%** (Q
0.006 cm off at x = 5), and the pins open 0.0000 cm at the reading. The
Walker Room's bars meet the same way, but there the error goes into a
leg's gait, where nobody measures it to 0.01 cm.

## 3. Where 100 comes from

OP × OQ = OA² − PA². With the arms at 15.05 and the sides at 11.25 it is
226.50 − 126.56 = 99.94, and every reading was 0.06% low. The arms are
now 15.052: 15.052² − 11.25² = 100.0002. A linkage's constant
is a difference of two squares, so the bars must be cut closer than its
answer is read: 0.02 mm on a 150 mm arm moves the answer 0.06%.

## 4. The solver's iterations, the steps and the hand

| run | inverter: worst off (of 24) | multiplier: worst off (of 24) | the line: worst pen off (of 21) |
|---|---|---|---|
| as it is: 80 iterations, 600 Hz | 0.0007, all right | 0.0000, all right | 0.004 mm, all straight |
| 40 iterations | 0.0015, all right | 0.0002, all right | 0.009 mm, all straight |
| 20 iterations | 0.0031, all right | 0.0013, all right | 0.021 mm, all straight |
| 10 iterations | 0.0068, all right | 15 of the first 17 wrong, off by up to 2.3 | 11 of 21 off by more than 0.05 mm |
| 300 Hz | 0.0027, all right | 0.0002, all right | 0.018 mm, all straight |
| 1200 Hz | 0.0002, all right | 0.0000, all right | 0.0005 mm, all straight |
| a fast hand: 8 cm/s; the crank 120°/s | 0.0007, all right | 0.0001, all right | 0.013 mm, all straight |

The inverter's tolerance is 0.01 cm on Q; the multiplier's, 0.02 on the
product; the line's, 0.05 mm off x = 14.2857 at any time after the first
half second. The inverter is one closed loop of six bars and holds even at
10 iterations. The multiplier's chain is longer (board, slider, bridge,
slider, cross carriage, hinge, block, slider, lever, and back through the
b carriage): at 10 iterations the carriages shake and settle slowly and
wrong. 80 is four times what the sweeps need; each costs little here
(every way runs faster than real time).

## 5. The straight line: the hand must not jerk

At first the line failed 17 of its 21 sweeps: the pen strayed up to 0.07
mm, and the smaller the sweep, the worse. Printing every frame showed the
pen within 0.002 mm of the line all the way, but for one frame at each end
of a sweep. The hand drove the crank at full speed one way until it
arrived and at full speed back the next frame: the cell's bars, swung
round in one step, flexed for a moment. A short sweep turns back where the
crank's motion swings Q fastest.

The hand now speeds up and slows down over a third of a second, as a real
hand does. The worst fell to 0.004 mm, and the line passes at every
setting in the table above.

## 6. The multiplier

The prototype (`mult.lua`, scratch) went through five designs:

- **The b carriage hit the cross carriage.** Its guide moved to 6 from O,
  out of the cross carriage's way.
- **A cross carriage on its own slider, anchored far away, lagged.** A light
  body on a long lever arm settles slowly. It now rides a **bridge** that
  spans the board, set at a, so the cross carriage's slider is short.
- **The two pins crossed in the slot.** The cross carriage stays beyond the
  b carriage: a from 2, so the bridge is at 8 or more, and the b carriage
  at 6.
- **The pins are blocks** on a slider along the lever, hinged to their
  carriages, and they lay in the lever's plane and collided with it: they
  lie in the planes beside it now (the b carriage's below, at plane 1;
  the cross carriage's above, at plane 3; the lever at 2).
- **It oscillated** at 40 iterations in the prototype; 80 settled it (the
  final exhibit is calmer: section 4).

The cross carriage moves toward you for a positive product, so the
product's scale runs from −25 at the back to 25 at the front, as do a and
b's.

## 7. The bars carry nothing but the push

The board lies flat: gravity is across the planes of motion, so the
hinges take the bars' weight along their axes and no torque about them.
A board standing up, like the slide adder's, would hang the cell's weight
on its pins, and the answer would sag with it.

## 8. Kempe's reversor (2026-11-28)

The fourth way: Kempe's reversor (L 8, s 4; its small twin 4 and 2) and a
parallelogram adder (6 on the crank, 3 on the arm), seven bars in planes
0 to 6, so no two that cross share one.

- **The starting shape decides the branch.** The circles that place B
  meet twice: one point makes the crossed parallelogram, the other a plain
  one, which doesn't double. The script takes the point farther from the
  plain parallelogram's corner, X + P − O, and places Q on the circle
  through C nearer 2θ. Built at θ = 90°, far from the flat shapes.
- **It must not go flat.** At θ = 0 and 180° the crossed parallelograms
  lie straight and may unfold. The sweep stays 20° to 160°; typing a
  smaller end clamps to 30–160.
- **Measured** (the tour, 20° to 160° and back, the hand at 40° a
  second): the arm off 2θ by 0.058° at most, the pen 0.028 mm off
  6 e^iθ + 3 e^2iθ, the pins open 0.0000 cm. Twenty sweeps at random
  (`LN_RANDOM=20`): all right, the worst the tour's.
- **The arm lags the hand.** The error grows in step with the hand's
  speed: 0.098° at 60° a second, 0.139° at 80, 0.179° at 100, 0.219° at
  the slider's top, 120 (the pen 0.11 mm). It is the solver's lag in a
  chain of seven bars, not the geometry: the pins never open. The check
  passes at 0.3° and 0.2 mm.
- **The evaluation of a whole Kempe "Bill"** (William's
  `kempe_pure_bill.py`): its reversors are genuine (90 bars, rigid to
  1e-15), but the sums are done in Python, not by bars; its "pantograph"
  lines change length by up to 1.28. Built honestly it would be about
  330–350 bars, plus braces, and it picks the branch by predicting
  velocity, which a linkage can't. Hence this set piece: one reversor and
  one adder, all of them bodies and pins.
