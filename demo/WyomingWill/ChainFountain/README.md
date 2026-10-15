# The Chain Fountain

Pull the end of a long bead chain out of a jar and let it fall to the
floor, and the chain pours out of the jar on its own -- and it doesn't just
slide over the rim: it leaps up in an arch above the jar on its way down.
Steve Mould filmed it in 2013 (the "Mould effect"); John Biggins and Mark
Warner explained it in 2014.

**Why:** a chain's links are short stiff rods, and a chain can only bend so
far between links. A link being picked up off the pile is lifted by one
end, so it turns about its middle and pushes its other end down into the
pile. The pile pushes back, and that push, on top of the pull of the
falling chain, throws the chain up above the jar.

## What it does

About 16 m of chain (1.5 cm links, joints that bend at most 30 degrees) is
coiled in a glass jar on a stand 1.5 m above the floor. The lead hangs over
the rim to the floor; the chain runs at about 4 m/s, so it starts at a
quarter of real speed. The fountain stands 3-8 cm above the rim most of
the time, at times up to 12 (the console reports it every quarter of a
simulated second, so every second at quarter speed), and the jar is empty
in about 4 seconds (17 at quarter speed). R starts again.

How the bending limit matters, same jar (the whole run, from half a
second in until the last of the coil is lifted; 10 layers, and in brackets
14 layers):

| Joints bend at most | Chain | Fountain above the rim: middle half of the time, median | Highest |
|---|---|---|---|
| 20 degrees | 9.6 m (12.9) | 3.5-5.8 cm, 4.7 (3.0-5.8, 4.5) | 11.9 cm (11.9) |
| 30 degrees (default) | 15.8 m (21.5) | 3.4-8.0 cm, 5.4 (1.9-6.7, 4.1) | 12.4 cm (12.4) |
| 60 degrees | 16.1 m (21.9) | 6.0-8.3 cm, 7.7 (3.9-8.0, 6.3) | 10.1 cm (10.1) |
| 90 degrees | 16.1 m (21.9) | 6.6-8.6 cm, 7.8 (5.1-8.2, 7.3) | 12.4 cm (12.4) |

How stiff the chain is makes little difference. The differences in the
table are no bigger than a small change of start makes: with the jar 2 or
4 cm higher or lower, the median is 6-8 cm at 20 degrees, 5-7 at 30, 4-8
at 60 and 5-8 at 90. A stiffer chain can't coil as tightly, so at 20
degrees a layer holds less chain. (Until 15 Oct 2026 this table said the
stiffer chain stood higher, 11 cm at 20 degrees. That came from the coil:
it was laid tighter than a 20-degree chain can bend; see Simulation.) The
chain does exactly the same at any speed: the speed slider and Z only
change how fast you see it.

## The theory check

At the end the console sets the steady part of the run (from 1 s in until
the last of the coil is woken) against John Biggins and Mark Warner,
"Understanding the chain fountain", Proc. R. Soc. A 470 (2014) 20130689
(arXiv:1310.4056). In their notation h1 is the drop from the pick-up to the
floor and h2 the top of the chain above the pick-up; the pile pushes up on
the link being picked up with a m v^2 and the floor pulls down on the link
landing with b m v^2 (m the mass per length, v the chain's speed). A steady
fountain then has v^2 = g h1/(1 - a - b) and h2 = a v^2/g. A chain with
a = b = 0 would go at sqrt(g h1) and not rise at all. Here the floor never
pulls (a landed link is frozen, its joint goes, and the frozen links don't
collide), so b = 0 and the theory leaves nothing to choose:
v = sqrt(g (h1 + h2)). v here is the rate the links land (links a second
times 1.5 cm). The default run:

```
t= 4.25s  all of it out of the jar; the fountain stood up to 12.4 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.68s; h1 = 150.2 cm, the pick-up above where a link lands (the rim is 5.3 cm above the pick-up)
  chain 397 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 10.5 cm above the pick-up on average (h2): h2/h1 = 0.070 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 397 cm/s
  a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.06 from the speed (rod model for one of these links: 0.31)
  the links reach the floor at 352 cm/s (rms), with 42% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
```

With `CF_PUSH=1` it also measures the pile's push itself. After every
physics step it takes the upward contact force of the pile on the chain,
less the weight of the links lying on it, and the upward force of the rim.
It adds:

```
  the pile's push, measured (its contact forces less the weight lying on it): a = 0.31; the rim holds the chain up with 0.31 m v^2
```

(This walks all of Bullet's contacts every step, which makes the run two or
three times slower in the Cabinet, so it is off unless asked for.)

All four bendings, 10 layers, `CF_PUSH=1`:

| Joints bend at most | v (rate links land) | rms speed landing | h2 | a from the height | a from the speed | a, the pile's push | the rim's push |
|---|---|---|---|---|---|---|---|
| 20 | 450 cm/s | 361 cm/s | 10.7 cm | 0.05 | 0.27 | 0.27 | 0.14 m v^2 |
| 30 | 397 | 352 | 10.5 | 0.07 | 0.06 | 0.31 | 0.31 |
| 60 | 425 | 383 | 12.8 | 0.07 | 0.18 | 0.19 | 0.02 |
| 90 | 432 | 380 | 13.2 | 0.07 | 0.21 | 0.17 | 0.01 |

What it says:

* The pile does push up, as Biggins and Warner say it must: a = 0.27-0.31
  at 20 and 30 degrees and 0.17-0.19 at 60 and 90 (their rod model for
  their chain gives 1/6, the same model for one of these links 0.31). How
  well that is known: counting as lying on the pile every link within
  7 mm of it, not only the ones touching it, gives 0.05-0.10 less (0.17,
  0.22, 0.13, 0.12).
* Where the chain keeps clear of the rim (60 and 90 degrees), the speed
  agrees with the push about as well as the push is known (0.18 and 0.21
  against 0.13-0.19 and 0.12-0.17). Where it rubs and strikes the rim
  (at 30 degrees the rim holds it up with 0.31 m v^2), it runs slower than
  the push alone would make it go, and a reads low from the speed. At 30
  degrees the two readings, 0.07 and 0.06, agree only by chance: the push
  is 0.31.
* The height doesn't follow the push: a reads 0.05-0.07 from it at every
  bending, and the fountain stands a third as high as h2 = a v^2/g with
  the measured push (about 35 cm at 60 degrees, against 12.8).
* Biggins and Warner's chain loses no energy between the pile and the
  floor, so it lands with 1/(2 (1 - a)) of the energy of its drop: 60-72%
  for these pushes. This one lands with 42-50%, at 352-383 cm/s, 11-20%
  slower than the rate the links land: the chain coming down is wavy, not
  taut and straight, and a tenth to nearly a third of the power is lost on
  the way.

So the chain fountain here is not the steady flow of the theory. The
pick-up runs round the flat spiral at the chain's own speed (round a
circle of 3-6 cm some 10-20 times a second), the arch swings, a stiff
chain loops above the pile, and the chain loses energy on its way down. Of
the theory's two rules, the one for the speed holds where the rim is out
of the way; the one for the height (which needs as well that the chain go
straight up and turn over in a narrow arch with nothing on it) does not.
Where the energy goes is not settled. Their own chain gave h2/h1 = 0.14;
this one 0.07-0.09.

The run is chaotic, so these numbers move from run to run: with the jar
2 or 4 cm higher or lower, v is 414-448 cm/s, the push 0.15-0.41, and a
from the height 0.05-0.07. With 3600 steps a second instead of 1800 they
move by as much again (at 20 degrees v = 477 cm/s, push 0.39, h2 19.8 cm).
How many links are woken ahead of the pick-up matters too, though it is
only a way of simulating less: with 5 instead of 10 the chain runs 7-20%
faster (476 and 452 cm/s at 30 and 60 degrees) while the measured push is
less (0.21, 0.16); with 20 the woken links are dragged into a heap. So the
speed here is known to about a fifth.

## Keys

| Key | Action |
|---|---|
| `R` | start again |
| `V` | the fountain close up <-> the whole drop |
| `Z` | quarter speed <-> real speed |

Sliders: speed, steps, bending (degrees), height (the jar above the floor),
layers (how much chain, 1.6 m a layer), friction. Moving the bending,
height or layers slider starts it again with the new setting, half a second
after you let go. Rest the mouse on the chain to see how fast it's going.

## Simulation

Simulating every link of 16 m of chain at once was too slow, so:

* The coil waits in the jar, drawn but not simulated, on a flat rigid pile
  (a disc lowered a layer at a time). Ten links ahead of the one being
  picked up are simulated, and more are woken as the chain comes for them
  (no faster than 1200 links a simulated second). The last link woken is
  held by its far end where it lies, as the rest of the coil would hold it;
  without that the moving chain dragged the woken links off in a heap.
* A link that reaches the floor (2.5 cm up) is frozen where it lands, and
  from then on is only drawn: the chain coming down meets nothing there.
* So only the moving chain is simulated: about 130-200 links, capsules
  joined by cone-twist joints, 1800 physics steps a second, 20 solver
  iterations. Waking, freezing and measuring are done after every physics
  step, and a frame takes as many whole steps as its share of simulated
  time, so the run is the same, line for line, at any speed.

The coil is laid as flat spirals, outside in and then inside out, all
turning the same way, every link 1.5 cm and no joint bent further than it
can bend: no tighter than the chain can turn (3.1 cm at 30 degrees, 4.8 cm
at 20), and at the end of a layer the chain tips down to the next over
three links, going on round. (Until 15 Oct 2026 the spiral went in to 3 cm
at every bending, so at 20 degrees a third of the joints were laid bent
past their stop; and at every bending each layer began with a link
0.65 cm long standing upright, the next layer turning back the other way.
When woken, those joints were kicked straight by the solver.) The bending
slider goes down to 20 degrees: a stiffer chain hardly coils in this jar.
Because the pick-up runs round the spiral, the arch swings and loops more
than a fountain from a jumbled heap would.

Headless testing: `CF_SPEED`, `CF_STEPS`, `CF_BEND`, `CF_HEIGHT`,
`CF_LAYERS`, `CF_LOG=file.csv`, `CF_PUSH=1` (measure the pile's push).

## Files

* `chain-fountain.lua`: the exhibit. It runs on its own or in the Cabinet.
* `chain-fountain-meshes/link.obj`: a link.
* `reconstruction/gen-link.py`: makes it.
