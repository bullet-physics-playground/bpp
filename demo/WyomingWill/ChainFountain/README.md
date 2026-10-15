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
quarter of real speed. The fountain stands 7-11 cm above the rim most of
the time, at times up to 16 (the console reports it every quarter of a
simulated second, so every second at quarter speed), and the jar is empty
in about 4 seconds (17 at quarter speed). R starts again.

How the bending limit matters, same jar and chain (the whole run, from
half a second in until the last of the coil is lifted; 10 layers, and in
brackets a longer run with 14 layers, 22 m):

| Joints bend at most | Fountain above the rim: middle half of the time, median | Highest |
|---|---|---|
| 20 degrees | 9-14 cm, 11 (8-14, 11) | 21 cm (25) |
| 30 degrees (default) | 7-11 cm, 9 (7-12, 9) | 16 cm (16) |
| 60 degrees | 2-5 cm, 3 (3-5, 4) | 7.5 cm (8) |
| 90 degrees | 4-5 cm, 4 (3-5, 4) | 10 cm (10) |

The stiffer the chain, the higher the fountain, up to 60 degrees; at 60
and 90 it is about the same. The chain does exactly the same at any speed:
the speed slider and Z only change how fast you see it.

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
v = sqrt(g (h1 + h2)). The default run:

```
t= 4.25s  all of it out of the jar; the fountain stood up to 16.1 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.62s; h1 = 150.4 cm, the pick-up above where a link lands (the rim is 5.1 cm above the pick-up)
  chain 406 cm/s off the pile: an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 13.7 cm above the pick-up on average (h2): h2/h1 = 0.091 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 401 cm/s
  a = g h2/v^2 = 0.08 from the height, 1 - g h1/v^2 = 0.11 from the speed (rod model for one of these links: 0.31)
```

What agrees: the chain goes faster than an ideal chain could (406 against
384 cm/s) and stands above the pick-up, as the theory says it must when
the pile pushes up. At 30 degrees the speed is within 1.5% of
sqrt(g (h1 + h2)). What doesn't: the two readings of a should be the same,
and only at 30 degrees are they close (0.08 and 0.11). At 20 degrees the
chain runs at 463 cm/s against 405, and a reads 0.08 from the height but
0.31 from the speed; at 60 and 90 degrees, 0.05 against 0.17-0.20. So the
chain comes off the pile faster than its fountain's height accounts for
(the 14-layer runs say the same). Why is not settled. The flow off a flat
spiral is not the steady flow of the theory: the pick-up runs round the
coil, the arch swings and loops, and at 20 degrees some 60 links more than
the path from pile to floor needs are moving, a loose loop whirling in the
jar. Their own chain gave h2/h1 = 0.14, and their rod model
a = 1/6; a here is 0.05-0.09 from the height, a lower fountain than
theirs. The rod model for these links (rods 1.5 cm long, joints free) would
give 0.31.

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

The coil is laid as flat spirals, outside in and then inside out, no
tighter than 3 cm (the tightest a chain bending 30 degrees a joint can go).
Because the pick-up runs round the spiral, the arch swings and loops more
than a fountain from a jumbled heap would.

Headless testing: `CF_SPEED`, `CF_STEPS`, `CF_BEND`, `CF_HEIGHT`,
`CF_LAYERS`, `CF_LOG=file.csv`.

## Files

* `chain-fountain.lua`: the exhibit. It runs on its own or in the Cabinet.
* `chain-fountain-meshes/link.obj`: a link.
* `reconstruction/gen-link.py`: makes it.
