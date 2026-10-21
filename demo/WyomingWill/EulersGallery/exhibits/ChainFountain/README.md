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

Everything found about how faithful this simulation is, from the first
fixes to the poured heap, is in [FINDINGS.md](FINDINGS.md).

## What it does

A ball chain of the kind Biggins and Warner used (4.5 mm balls 6.5 mm
apart, joints that bend at most 30 degrees), 9.75 m of it, lies in a
jumbled heap in a glass jar on a stand 1.5 m above the floor, as it fell
when it was poured in. An unseen hand draws the end up over the rim and
down to the floor and lets go; the chain then runs out at about 4.3 m/s,
so it starts at an eighth of real speed (Z: real speed). The fountain
stands 10-16 cm above the rim (h2/h1 = 0.143 on this heap; their chain:
0.14), and the jar is empty 2.25 s after letting go (about 23 s on screen,
with the pause and the hand). R starts again; H changes to the coil the
exhibit had before (below) and back.

Every link of the heap within 4 cm across of where the chain is being
picked up, and down to 1.5 cm below it, moves; the rest lies still until
the pick-up comes near (see Simulation). That is the fully simulated
heap's fountain, within the spread from pour to pour, at about half its
cost; it still needs an eighth of real speed to keep up with the screen
(17-18 ms a frame during the flow here; see the theory check). The links
keep their angular momentum as Euler's equations say: bpp solves their
gyroscopic term with the joints (since 20 Oct 2026; FINDINGS.md section 15).

### The coil (H, or `CF_PILE=coil`)

Until 16 Oct 2026 the exhibit had a coil of coarser chain, and H still
shows it: about 16 m of chain (1.5 cm links, joints that bend at most 30
degrees) coiled flat in the same jar, the lead over the rim to the floor,
at a quarter of real speed. Its fountain stands only 3-8 cm above the rim
most of the time (h2/h1 0.06-0.07), half the real one: a coil, and links
this coarse in this jar, don't give the measured fountain (see the theory
check). The jar is empty in about 4 seconds (17 at quarter speed).

About 16 m of chain (1.5 cm links, joints that bend at most 30 degrees) is
coiled in a glass jar on a stand 1.5 m above the floor. The lead hangs over
the rim to the floor; the chain runs at about 4 m/s, so it starts at a
quarter of real speed. The fountain stands 3-8 cm above the rim most of
the time, at times up to 12 (the console reports it every quarter of a
simulated second, so every second at quarter speed), and the jar is empty
in about 4 seconds (17 at quarter speed). R starts again.

For the coil, how the bending limit matters, same jar (the whole run, from half a
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

At the end the console sets the steady part of the run (from 1 s after
the chain is let go until ten links before the end of the heap, or the
last of the coil is woken) against John Biggins and Mark Warner,
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
times their length). The default run, the heap at an eighth of real speed:

```
--- 9.8 m of chain, 1500 links; the jar 150 cm up; joints bend 30 deg at most ---
drawn over and let go (0.64 s)
t= 0.25s  fountain  6.5 cm above the rim (average  7.5, highest 10.2); chain 504 cm/s; 544 links moving, 1.2 m out
t= 0.50s  fountain  9.5 cm above the rim (average  7.4, highest 10.2); chain 505 cm/s; 851 links moving, 2.4 m out
t= 0.75s  fountain 12.6 cm above the rim (average 11.8, highest 12.9); chain 437 cm/s; 749 links moving, 3.5 m out
t= 1.00s  fountain 13.9 cm above the rim (average 13.7, highest 14.8); chain 428 cm/s; 695 links moving, 4.6 m out
t= 1.25s  fountain 14.3 cm above the rim (average 14.5, highest 15.2); chain 441 cm/s; 552 links moving, 5.7 m out
t= 1.50s  fountain 13.1 cm above the rim (average 14.2, highest 15.6); chain 422 cm/s; 448 links moving, 6.8 m out
t= 1.75s  fountain 10.4 cm above the rim (average 11.1, highest 15.6); chain 413 cm/s; 292 links moving, 7.9 m out
t= 2.00s  fountain -133.4 cm above the rim (average -85.1, highest 15.6); chain 686 cm/s; 130 links moving, 8.9 m out
t= 2.25s  all of it out of the jar; the fountain stood up to 15.6 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-1.65s; h1 = 148.3 cm, the pick-up above where a link lands (the rim is 7.2 cm above the pick-up)
  chain 436 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 381 cm/s and not rise above the pick-up
  top of the chain 21.2 cm above the pick-up on average (h2): h2/h1 = 0.143 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 408 cm/s
  a = g h2/v^2 = 0.11 from the height, 1 - g h1/v^2 = 0.23 from the speed (the rod model gives none for balls on light rods; 1/6 for their three-ball links)
  steady: links land at 433 cm/s in the first half of that window and 438 in the second
  the links reach the floor at 389 cm/s (rms), with 52% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
```

The fountain stands as high as theirs: h2/h1 = 0.143, against 0.14. The
two readings of a disagree, 0.11 from the height and 0.23 from the speed.
The heap is short (9.75 m is what the jar holds), so the steady part is
short too (0.65 s), and on other heaps (and on this one before 20 Oct
2026) the chain slows in it as the heap runs out, which the speed rule
can't allow for; the console then says "not steady". Here it ran steadily
(433 then 438 cm/s), and the readings still disagree: the chain runs
faster than its height says, as it does with every link simulated (0.79-0.84
of sqrt(2 g h1), against the experiments' 0.70; that speed is not
settled with the step either: FINDINGS.md section 15). The falling chain is
also wavy: its links land at 389 cm/s (rms), slower than the 436 cm/s the
chain runs at. So read a from the height here. (The
rod model, a = (1 - I/(m b^2/4))/2, gives no push at all for a link whose
mass sits in the balls at its ends, as these; Biggins and Warner's
three-ball link gives 1/6. The push here comes from the pile itself, as
the heap test below shows.)

The coil (`CF_PILE=coil`, or H), at a quarter of real speed:

```
t= 4.25s  all of it out of the jar; the fountain stood up to 12.4 cm above the rim
  theory (Biggins and Warner 2014), steady part t=1.00-3.68s; h1 = 150.2 cm, the pick-up above where a link lands (the rim is 5.3 cm above the pick-up)
  chain 397 cm/s (the rate links land): an ideal chain (a = b = 0) would go sqrt(g h1) = 384 cm/s and not rise above the pick-up
  top of the chain 10.5 cm above the pick-up on average (h2): h2/h1 = 0.070 (their chain: 0.14); b = 0 here, so v = sqrt(g (h1 + h2)) = 397 cm/s
  a = g h2/v^2 = 0.07 from the height, 1 - g h1/v^2 = 0.06 from the speed (rod model for one of these links: 0.31)
  the links reach the floor at 352 cm/s (rms), with 42% of the energy of their drop (an ideal chain: 50%; one the pile pushes, more)
```

With `CF_PUSH=1` it also measures two pushes. The pile's: after every
physics step, the upward contact force of the pile on the chain, less the
weight of the links touching it, and the upward force of the rim. And what
the falling chain carries of it: from the lowest link up, each link's
acceleration less g gives the force on it from the next one, so the
chain's tension T. A steady chain keeps T - m v^2 - m g y = -a m v^2 (y
above the pick-up) all the way from the pile to the floor, and that is read
where the chain falls freely, 20-100 cm below the pick-up. It adds:

```
  the pile's push, measured (its contact forces less the weight lying on it): a = 0.31; the rim holds the chain up with 0.31 m v^2
  with that push a steady narrow arch would stand h2 = a v^2/g = 50.4 cm above the pick-up (it stood 10.5)
  what the falling chain carries of it (its tension, from the links' accelerations, 20-100 cm below the pick-up): a = -0.13
```

(This walks all of Bullet's contacts every step, which makes the run two or
three times slower in the Gallery, so it is off unless asked for.)

All four bendings, 10 layers, `CF_PUSH=1`:

| Joints bend at most | v (rate links land) | rms speed landing | h2 | a from the height | a from the speed | a, the pile's push | the rim's push | a the falling chain carries |
|---|---|---|---|---|---|---|---|---|
| 20 | 450 cm/s | 361 cm/s | 10.7 cm | 0.05 | 0.27 | 0.27 | 0.14 m v^2 | -0.07 |
| 30 | 397 | 352 | 10.5 | 0.07 | 0.06 | 0.31 | 0.31 | -0.13 |
| 60 | 425 | 383 | 12.8 | 0.07 | 0.18 | 0.19 | 0.02 | 0.04 |
| 90 | 432 | 380 | 13.2 | 0.07 | 0.21 | 0.17 | 0.01 | 0.03 |

The pile does push up, as Biggins and Warner say it must: a = 0.17-0.31
(their rod model gives 1/6 for their chain, 0.31 for one of these links).
But the fountain stands only a fifth to two fifths as high as
h2 = a v^2/g with that push, and the links land with 42-50% of the energy
of their drop, where a chain that loses nothing on the way would bring
down 1/(2 (1 - a)) = 60-72%. The speed rule seems to agree with the push
at 60 and 90 degrees, but v is the rate links land, and they land 11-20%
slower than that (the chain coming down is wavy). At 30 degrees the
height and speed readings, 0.07 and 0.06, agree only by chance.

**A pile whose pick-up stays put.** On the flat spiral the pick-up runs
round the jar at the chain's own speed. To see whether that is what keeps
the fountain low, `CF_LAYOUT=flake` lays the chain instead in runs of four
links, back and forth, three runs a layer, each layer over the last. The
pick-up then stays within a few centimetres of the middle, as in a jumbled
heap. It needs a chain that turns tightly (45 degrees and more), and a
layer holds only about 30 cm of chain, so it is run on a table: `CF_JAR=0`
(no glass, the pile on the bare disc), 40 layers (the pile 26 cm tall, so
h1 falls from 150 to 125 cm during the run). The same table with the
spiral, for comparison:

| Pile, joints bend at most | v | rms speed landing | h2 | a, the pile's push | a carried | a from the height | h2 / (push v^2/g) | h2 / (carried v^2/g) | energy landing (lossless with a carried) |
|---|---|---|---|---|---|---|---|---|---|
| flake, 45 | 420 cm/s | 380 cm/s | 18.2 cm | 0.28 | 0.10 | 0.10 | 0.36 | 1.01 | 53% (56%) |
| flake, 60 | 428 | 373 | 17.3 | 0.23 | 0.08 | 0.09 | 0.40 | 1.16 | 51% (54%) |
| flake, 90 | 435 | 365 | 9.1 | 0.13 | 0.06 | 0.05 | 0.36 | 0.79 | 49% (53%) |
| spiral, 60 | 419 | 382 | 10.6 | 0.20 | 0.04 | 0.06 | 0.30 | 1.48 | 50% (52%) |
| spiral, 90 | 425 | 374 | 9.5 | 0.18 | 0.01 | 0.05 | 0.29 | 5.2 | 48% (51%) |

Then one thing at a time, on the flake and on the spiral (60 degrees):
3600 and 7200 steps a second, 50 and 100 solver iterations, no friction,
no joint stops (`CF_STOP=179`), 5 and 15 links woken ahead, links half as
big (`CF_LINK=0.5`). None of them brings the fountain near h2 = a v^2/g
with the pile's push: the ratio stays 0.25-0.50 on the flake and
0.24-0.35 on the spiral, and the links land with 43-53% of the energy of
their drop.

What this says:

* The pick-up staying put is not what keeps the fountain low. It helps a
  little (at 60 degrees on the table 17.3 cm against 10.6), but the
  fountain still stands only 0.36-0.40 of the height the pile's push
  should throw it.
* Nor is it energy lost in the model on the way down. In the three flake
  runs, with the push the falling chain carries, the theory holds: the
  height within -21% to +16%, the links land at 96-98% of
  sqrt(g h1/(1 - a)), and with 3-4 points of the drop's energy less than a
  chain that loses nothing.
  The step, solver iterations, friction and joint stops change none of
  this much.
* What keeps it low is at the pick-up. The pile pushes up with 0.13-0.28
  m v^2, but the moving chain carries only a third to a half of that,
  0.06-0.10. The chain here is not picked up a link at a time, as in the
  theory. It is dragged and lifted over several links: 4-6 cm above the
  pile it is still going only about 90% of the chain's speed. Most of the pile's push goes somewhere in that stretch
  other than into the chain's tension. Where exactly is not settled. It
  does not change with the step or the solver iterations. Without joint
  stops the push itself is smaller (0.13 against 0.23).
* On the spiral the falling chain carries even less (0.00-0.04, below zero
  where it rubs the rim), and with half-size links on the flake too
  (0.01). There the fountain stands higher than the carried push alone
  would throw it, so on the way from the pile to the falling leg the flow
  isn't the theory's steady one either.

Their own chain gave h2/h1 = 0.14, and this one 0.07-0.13. With b = 0, 0.14
means a = 0.12 by their formula, less than their rod model's 1/6.

**Without the shortcut.** Only ten links ahead of the pick-up are
simulated, the last held to the unmoved coil (see Simulation), and that is
just where the push goes missing. So the same jar was run with every link
simulated from the start (`CF_LIVE=1`: no waking, no anchor, the pile on
the disc under its lowest layer), 6 layers (about 750 links), and set
against the exhibit's way with the same chain. Each is the mean and spread
of five runs, with the jar at 146, 148, 150, 152 and 154 cm (`CF_PUSH=2`
also measures the push of the unmoved pile, the disc and every link not yet
moved, on the moving chain):

| Joints bend at most, way | v | h2 | a, unmoved pile's push | a carried | rim's push | landing energy |
|---|---|---|---|---|---|---|
| 30, every link | 399 ± 15 cm/s | 8.6 ± 0.4 cm | 0.49 ± 0.09 | -0.13 ± 0.08 | 0.26 ± 0.09 m v^2 | 43 ± 4% |
| 30, ten ahead (the exhibit) | 420 ± 17 | 10.6 ± 1.5 | 0.20 ± 0.03 | -0.01 ± 0.11 | 0.13 ± 0.13 | 47 ± 5% |
| 60, every link | 379 ± 20 | 6.3 ± 0.5 | 0.23 ± 0.03 | -0.19 ± 0.11 | 0.32 ± 0.18 | 40 ± 3% |
| 60, ten ahead | 418 ± 6 | 10.8 ± 0.6 | 0.17 ± 0.01 | 0.01 ± 0.02 | 0.03 ± 0.03 | 48 ± 2% |
| 90, every link | 397 ± 30 | 5.5 ± 0.4 | 0.20 ± 0.02 | -0.16 ± 0.12 | 0.28 ± 0.18 | 42 ± 3% |
| 90, ten ahead | 423 ± 3 | 11.2 ± 0.8 | 0.15 ± 0.01 | 0.01 ± 0.02 | 0.03 ± 0.02 | 47 ± 1% |

The chain with every link simulated is no different in step: with 3600
steps a second, two runs each give h2 = 8.5 and 9.4 cm at 30 degrees, 5.7
and 6.0 at 90. Nor if the pile first settles for 0.3 s with the lead held
(30 degrees: 9.6 cm), nor if landed links stay on the floor instead of
being frozen (8.5 cm).

So the shortcut is not what loses the push. The chain with every link
simulated loses it just the same: the pile pushes as hard or harder, and
the falling chain carries none of it. Losing the push is how these rigid
links come off a pile, in this model. But the shortcut is not neutral
either. With every link free, the moving chain drags the top of the pile
with it and rubs the rim (0.26-0.32 m v^2, against 0.03-0.13), and goes
5-10% slower. Its fountain is lower: 8.6 cm at 30 degrees against 10.6,
and about half as high at 60 and 90. The exhibit's fountain is that much
taller than the full simulation of the same chain.

A cheaper way that matches: the top layers of the coil simulated whole,
the next one woken when the pick-up reaches the layer above it, and no
anchor (`CF_WAKE=layer`, `CF_LIVELAYERS`). With four live layers, five runs
at 30 degrees give v 406 ± 17, h2 8.7 ± 0.6, push 0.48 ± 0.09, carried
-0.09 ± 0.13, rim 0.20 ± 0.10, energy 45 ± 5%: the same as every link,
within the spread. At 60 degrees three layers match. At 90 neither three
nor four does: v is 356-359, against 397, and the rim's push 0.57-0.62
against 0.28, though h2 matches. It costs too much to be the exhibit's
way. A full run (10 layers, quarter speed, 1200 frames) takes on its own
5.3 s the exhibit's way, 25.1 s with four live layers and 41.9 s with every
link: per frame 4.4, 21 and 35 ms, where a frame at 60 a second has 16.7
(in the Gallery 12.8, 30.3 and 46.9 s). So the exhibit keeps ten links
ahead, and its fountain is to be read as up to twice as tall as the same
chain simulated whole.

**What a faithful run costs.** Per frame, 10 layers, 30 degrees, on its
own (600 frames at quarter speed, 150 at real speed; a frame at 60 a second
has 16.7 ms). "Matches" means within the spread of the every-link runs
above, five runs each:

| Way | quarter speed | real speed | against every link |
|---|---|---|---|
| the exhibit (ten ahead) | 5.4 ms (Gallery 6.9) | 22 ms | fountain 1.2-2 times too tall |
| every link | 52 | 209 | (the reference) |
| every link, resting links let sleep (`CF_SLEEP=1`) | 53 | 208 | no faster: the joints make the whole chain one piece, and Bullet only lets a whole piece sleep |
| every link, only touching contacts (`CF_CPT=0`) | 48 | 187 | |
| every link, 1200 steps a second | 37 | 145 | |
| four live layers | 32 | 129 | matches at 30, not at 90 (60 not run; three layers match there) |
| four live layers, only touching contacts | 27 | 109 | matches at 30 (v 406, h2 8.5 cm, rim 0.20) |
| four live layers, 10 solver iterations | 25 | 99 | doesn't (v 372, rim 0.52) |
| four live layers, 1200 steps a second | 21 | 86 | matches at 30 (v 387, h2 8.7, rim 0.27) |
| four live layers, both | 19 | 77 | 30: v 377, rim 0.35, at the edge; 60 and 90: no, the top layers are dragged into a heap |
| three live layers, only touching contacts, 1200 steps | 15.0 (Gallery 15.1) | 62 | 30: yes (v 396, h2 8.0, push 0.49, rim 0.25); 60: no (v 352 against 379, rim 0.47 against 0.32); 90: no (354 against 397, rim 0.61 against 0.28) |
| two live layers on a third of fixed links (`CF_STATICLAYERS=1`) | | | no (one run at 30: rim 1.19, v 347) |

Links next to each other along the chain never touch already: joined
bodies don't collide in bpp, and the runs show no contacts between links
one or two apart. Nearly all the cost of a live pile is its 900-1900
contact points of links lying on links, against about 20 in the exhibit's
way. So nothing tried makes a faithful run cheap enough at all three
bendings. Only one, three live layers with only touching contacts and 1200
steps a second, fits quarter speed (15 ms a frame), and it is faithful only
at 30 degrees. None fits real speed: the exhibit's own way takes 22 ms
there.

**A better chain?** Real ball chains make taller fountains than this one.
Biggins and Warner's chain (4.5 mm balls on 2 mm rods, 6.5 mm apart, six
balls to turn it round) gave h2 = 0.14 h1. Pantaleone's three chains gave
0.12-0.14, with the speed 0.69-0.71 of sqrt(2 g h1). Biggins's fit to the
fountains' shapes gives a = 0.12, b = 0.11. This chain, simulated whole,
gives 0.04-0.06. To see whether that is Bullet's links and joints,
`reconstruction/bead-chain.c` simulates the real kind of chain outside
Bullet, every bead, in the same jar with the same coil and drop. It has
beads on rods that can't stretch, the bending limit kept as the beads' own
geometry, and contacts with no bounce and with friction, stepped finely
(position-based, 2 x 10^-5 s). It does the same as the exhibit's chain
simulated whole:

| Bead chain (3 layers, the drop 152 cm) | v | h2 | h2/h1 | the pile's push | the rim's | carried |
|---|---|---|---|---|---|---|
| friction 0.3 | 329 cm/s | 6.6 cm | 0.043 | 0.29 | 0.47 m v^2 | -0.46 |
| the same, half the step | 334 | 6.4 | 0.042 | 0.24 | 0.68 | -0.57 |
| the same, twice the sweeps | 340 | 5.8 | 0.038 | 0.23 | 0.65 | -0.67 |
| no friction on the glass | 412 | 6.6 | 0.043 | 0.21 | 0.19 | -0.12 |
| friction 0.09 (as Bullet has it here: see below) | 404 | 7.5 | 0.049 | 0.21 | 0.09 | -0.07 |
| the same, the jar 2 cm lower | 427 | 9.4 | 0.063 | 0.19 | 0.09 | -0.02 |
| bending 20 degrees | 406 | 7.3 | 0.048 | 0.25 | 0.36 | -0.29 |
| the pile 0.3 cm above the rim | 379 | 7.1 | 0.046 | 0.27 | 0.19 | -0.30 |

So the fountain's height is not Bullet's doing. A chain of the real kind,
simulated exactly, lifted from this coil in this jar, stands as low: its
pile pushes, but the falling chain carries none of it. The lying chain
holds back as much as the pile pushes, and the chain rides on the rim.
What the experiments have that neither has is their pile: chain "fed into
the beaker in a random configuration" (Biggins and Warner), 30-75 m of it.
A jumbled heap (`HEAP=`) and longer coils (5-8 layers) were tried in
`bead-chain.c`, and the chain jammed in the jar each time. The heap test
below answers it.

**The heap test (16 Oct 2026).** A ball chain of Biggins and Warner's
size (links 0.65 cm joint to joint, 4.5 mm thick, the mass in the balls at
the joints; 1500 links, 9.75 m) was poured into the jar from above, as
they fed theirs in, and left to settle: a hand 6 cm over the jar's floor,
wandering at random within 2 cm of the middle, lets it down a link at a
time at 1 m/s (`CF_POUR=1`; nothing is placed by hand). It settles into a
jumbled heap 3.5-4 cm high over the jar's floor, the end still in the hand
6 cm up (fastest link under 4 cm/s when it is pulled, kinetic energy 10^-6
of a link's at 4 m/s or less). Then the hand draws the end up over the rim
and down to the floor, and lets go. The
control is the same chain laid as the exhibit's coil on the jar's floor
(`CF_POUR=2`), settled and drawn over the same way. Every link is
simulated, the drop is the same (h1 = 148 cm), friction is 0.3 at every
contact (`CF_MU=0.548` in Bullet), and the theory check runs from 1 s
after letting go to the end of the heap (0.4-1 s, 2-4 m of chain). Two
engines: Bullet, and `reconstruction/bead-pour.c`, the chain as 4.5 mm
balls 6.5 mm apart on solid rods 1 mm thick, simulated outside Bullet
(position-based, four passes in each 10^-5 s; its friction checked against
Coulomb, see the file).

| Engine, pile | Runs | v / sqrt(2 g h1) | h2/h1 | the pile's push | the rim's push | carried |
|---|---|---|---|---|---|---|
| Bullet, heap | 5 pours | 0.69-0.80 | 0.109-0.147 (mean 0.124) | 0.16-0.21 | 0.00-0.43 m v^2 | -0.21 to 0.12 |
| the same, 3600 steps a second | pours 1-3 | 0.80-0.82 | 0.132-0.159 (0.142; 0.131 at 1800) | 0.23-0.26 | 0.00 | 0.08-0.15 |
| Bullet, coil | jar at 148, 150, 152 cm | 0.26-0.44, slowing | 0.055-0.057 | 0.4-1.4 | 2.6-10.9 | -1.8 to -5.6 |
| reference, heap | 3 pours | 0.53-0.84 | 0.123-0.183 (0.151) | 0.28-0.42 | 0.00-1.47 | -1.12 to 0.04 |
| the same, half the step | pours 1, 2 | 0.85-0.86 | 0.174, 0.157 (0.183, 0.123) | 0.26-0.30 | 0.00-0.11 | 0.04-0.09 |
| the same, eight passes | pour 1 | 0.77 | 0.190 | 0.25 | 0.49 | -0.30 |
| reference, coil | 1; half the step | 0.44; 0.79 | 0.058; 0.060 | 0.31; 0.10 | 2.16; 0.67 | -1.95; -0.50 |
| experiments | | 0.69-0.71 | 0.12-0.14 | | | |

The coil in Bullet does not run steadily: the chain slides over the rim
and stalls. At 3600 steps a second it stops within a second (500 of the
1500 links out, then under 15 cm/s); with no friction at all it stops too,
6.9 m out, the rest pulled into a knot against the inside of the rim.

So the pile is what was missing. Poured as the experiments pour it, a ball
chain of their size makes their fountain, h2/h1 = 0.11-0.18 in both
engines, with the pile's push carried down the falling chain (0.02-0.15)
and the chain clear of the rim. Laid as this exhibit's coil, the same
chain picks up at the wall, is drawn up the glass and over the rim, and
rides on it: 0.06, the push not carried, the rim holding the chain up with
0.7-11 m v^2. It is not the step, the solver or Bullet: the two engines
agree, and halving the step changes the heap's fountain by less than the
spread from pour to pour (Bullet +8% on average, the reference -5% and
+28%). Not every pour clears the rim: in 1 of 5 Bullet pours and 1 of 3
reference pours, and in some reloads of a heap, the chain caught on the rim
and ran slow, with h2/h1 0.06-0.12. The chain here runs at 0.69-0.80 of
sqrt(2 g h1) in Bullet and 0.84 in the reference, the real ones at
0.69-0.71: nothing here loses energy to the air.

Neither the links' mass nor friction makes the difference. With uniform
rods instead of balls at the joints (`CF_BEADI=0`) one pour gives 0.138
(the other caught on the rim, 0.059); with no friction, 0.126; with the
exhibit's friction (0.09), 0.133, 0.103 and, on the rim, 0.061.

**The exhibit's own links don't make a heap.** Poured the same way, 1.5 cm
links that bend 30 degrees can't loop tighter than about 3 cm, and in a
7 cm jar they lay themselves round the wall in rings, a coil of their own
making, not a heap. 450 links (6.75 m; 700 fill the jar to the rim and
siphon out while pouring) give h2/h1 = 0.078-0.106 from four pours,
against 0.057-0.077 laid as the coil at three heights (`CF_T0=0.5`: the
chain is short, so the check starts at 0.5 s; two pours at 3600 steps
spilled over the rim while pouring). So the exhibit's coarse chain stays
low however it lies in this jar.

**The poured heap: the exhibit's default since 16 Oct 2026.** The
ball-chain-sized chain starts from a heap poured once
beforehand (`chain-fountain-meshes/heap.txt`). Five heaps were poured for
this (`CF_PILE=heap CF_POUR=1 CF_SEED=1..5 CF_SAVEHEAP=...`, true friction
0.3); the one shipped is the second. The heap lies fixed, every link a fixed body, except in a
live zone round the pick-up: every link within 4 cm across of it and no
more than 1.5 cm below it moves (`CF_ZONE`, `CF_ZDEPTH`; 0.5 cm until 20 Oct
2026, see below), and a moving link of the heap that is left 1 cm outside
the zone, at rest (moved under 0.1 mm in the last 1/100 s), lies fixed
again.
Where a moving link's neighbour lies fixed, a joint holds it to that fixed
link. The hand draws the end over the rim as above, and lets go. Friction
is a true 0.3 (0.548 a body), only touching contact points count
(`CF_CPT=0`), and the joints' error correction is 0.5 a step (`CF_ERP`;
Bullet's own is 0.2). It starts at an eighth of real speed.

Two things had to be found first. With Bullet's 0.2 the full heap does not
settle with the step: h2/h1 = 0.131 at 1800 steps a second, 0.160 at 3600,
0.150 at 7200 (5, 5 and 3 pours): the joints give, and at 1800 they give
too much. With 0.5 it is the same at 1800 and at 3600 (0.148, 0.145), and
0.8 gives 0.135, so 0.5 is converged, not tuned; 1200 steps is not (0.118).
And the zone must be big enough. Against every link simulated (the same
five heaps, all settings the same):

| | step a second | h2/h1, five heaps: mean (range) | v cm/s | rim's push | carried | the pile's push | a frame at 1/4 speed, the flow: alone (Gallery) | at 1/8 |
|---|---|---|---|---|---|---|---|---|
| every link | 1800 | 0.140 (0.117-0.160) | 398-442 | 0.00-0.29 | -0.09 to 0.13 | 0.17-0.22 | 36.4 ms | |
| every link | 3600 | 0.137 (0.093-0.167) | 429-457 | 0.00-0.11 | 0.02-0.14 | 0.21-0.29 | | |
| zone 3 cm, 0.5 deep | 1800 | 0.161 (0.139-0.204) | 423-456 | 0.00-0.06 | 0.08-0.16 | 0.12-0.16 | 22.5 (24.4) | 11.7 |
| the same | 3600 | 0.168 (0.146-0.198) | 407-464 | 0.00-0.49 | -0.16 to 0.16 | 0.13-0.21 | | |
| zone 3 cm, 1 deep | 1800 | 0.155 (0.132-0.167) | 408-450 | 0.00-0.19 | -0.02 to 0.15 | 0.12-0.21 | | |
| **zone 4 cm, 0.5 deep (`CF_PILE=heap`)** | 1800 | 0.147 (0.110-0.176) | 416-445 | 0.00-0.17 | 0.00-0.13 | 0.13-0.20 | 27.5 (30.0) | 14.1 (14.3) |
| the same | 3600 | 0.145 (0.069-0.177; 0.164 without one run caught on the rim) | 334-465 | 0.00-0.50 | -0.38 to 0.15 | 0.13-0.31 | | |
| ten ahead only (no zone; cost only) | 1800 | | | | | | 13.5 | |

So the 4 cm zone is the full heap within the spread from pour to pour,
in the fountain's height, the speed, the rim's push and the push the
falling chain carries, at both steps; the pile's push it gives is a little
lower (0.13-0.20 against 0.17-0.29). The 3 cm zone stands 15% too tall.
What it costs is the live links: the falling 1.5 m of fine chain alone
(about 280 links) takes 13.5 ms a frame at quarter speed, the solver's
iterations hardly count (5 instead of 20 saves 12%), and the zone adds
14 ms. So it does not fit a frame at quarter speed: 27.5 ms during the
flow (30.0 in the Gallery; over the whole run 21.8 and 24.0). At an eighth
of real speed, where it starts, it does: 14.1 ms during the flow, 14.3 in
the Gallery (11.4 and 11.7 over the whole run, 1418 frames); the exhibit
itself takes 4.8 (5.4) at quarter speed. Drawing: under a software
renderer (xvfb, no GPU) a frame with drawing takes 186 ms for the heap,
77 for the exhibit; the heap's 1500 links and the landed ones are drawn
one by one (bpp batches only fixed boxes and cylinders). On a real screen
this is not measured.

Its run is the default run at the top of this section. Two traps met on the
way, both fixed: reading a moving link's turn from bpp's `.trans` gave the
turn drawn at the last frame, not the body's (`getOrientation()` now); and
making new fixed bodies during the run made it differ in the Gallery, so
each link keeps one fixed body and parks it far below the floor while it
moves.

(Until 16 Oct 2026 this was an option, `CF_PILE=heap`, and the coil the
default. Now the heap is the default and `CF_PILE=coil`, or H, gives the
coil.)

**20 Oct 2026: the zone made deeper, and the links' gyroscopic term.**
Checked at 7200 steps a second too, the 0.5 cm zone was not settled with
the step: 0.147 / 0.164 / 0.170 at 1800 / 3600 / 7200, every link
0.137-0.140. 0.5 cm is about one ball: the chain lay on links that could
not move, and with every link simulated the layer 0.5-1.5 cm under the
pick-up gives way more at finer steps (38% of the heap's first moves
lie below 0.5 cm at 1800, 53% at 7200; 10-11% below 1.5 cm at both).
Refreezing (every 18 steps, by the speed at that instant) also depended on
the step, but making it depend on time instead changed nothing. So the
zone is now 1.5 cm deep, and refreezing goes by time. Over ten runs a
cell (five heaps, the jar at 150 and 152 cm), clear of the rim:

| steps a second | every link, no term | every link, term solved | zone, no term | zone, term solved (the exhibit) |
|---|---|---|---|---|
| 1800 | 0.140 +- 0.007 | 0.138 +- 0.006 | 0.139 +- 0.009 | 0.135 +- 0.007 |
| 3600 | 0.138 +- 0.007 | 0.120 +- 0.008 | 0.149 +- 0.008 | 0.149 +- 0.009 |
| 7200 | 0.144 +- 0.010 | 0.138 +- 0.007 | 0.151 +- 0.009 | 0.157 +- 0.006 |

(+- the standard error; speeds 0.78-0.85 sqrt(2 g h1); 0-3 runs in ten
caught on the rim, with or without the term.) At the exhibit's 1800
steps the zone is every link simulated; at 3600-7200 it stands about 0.01
higher (two standard errors at most in a cell), a residue whose cause was
not found (a zone 6 cm across gives the same). The deeper zone costs
about 15% more: 17-18 ms a frame during the flow at an eighth of real
speed here, against 15 for the old one (budget 16.7).

Friction in Bullet: Bullet takes the product of the two bodies' friction
for a contact. So the coil's friction slider at 0.3, set on the links, the glass
and the disc alike, is 0.09 for every contact the chain makes. With
friction set so that the product is 0.3 (0.548 each, `CF_MU=0.548`), the
whole chain gives h2 = 8.6-9.8 cm at 30 degrees and 5.1-5.7 at 90 (three
runs each), the same as with 0.09.

For the coil, the run is chaotic, so these numbers move from run to run: with the jar
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
| `H` | the poured heap <-> the coil (starts again) |
| `V` | the fountain close up <-> the whole drop |
| `Z` | an eighth of real speed (the coil: a quarter) <-> real speed |

Sliders: speed, steps, bending (degrees), height (the jar above the floor),
layers (how much chain, 1.6 m a layer), friction. With the heap:

* bending stays at 30 degrees: the heap was poured with joints that bend
  30 degrees, and any other limit would kick them straight or let the heap
  lie as it never could. The slider goes back to 30 (the console says so
  once); H for the coil, where it can change.
* layers does nothing (the heap is the 9.75 m it was poured with); it is
  the coil's.
* steps go no lower than 1800 a second: at 1200 the heap's fountain is
  lower (0.118 against 0.14), not yet what finer steps give.
* friction is each body's, and a contact has the two multiplied: 0.548 is
  a true 0.3. Moving it starts again, as height does.

H puts speed and friction to the other pile's own; the other sliders keep
what they are. Moving the height, friction (heap) or bending and layers
(coil) slider starts it again with the new setting, half a second after
you let go. Rest the mouse on the chain to see how fast it's going.

## Simulation

The heap (the default):

* It was poured once, offline: a hand 6 cm over the jar's floor, wandering
  at random within 2 cm of the middle, let the 1500 links down one at a
  time at 1 m/s, every link simulated, and the heap settled
  (`CF_POUR=1 CF_SEED=2 CF_SAVEHEAP=...`). `chain-fountain-meshes/heap.txt`
  holds where its joints lie.
* In the exhibit the heap's links are fixed bodies, except a live zone:
  every link within 4 cm across of the pick-up and no more than 1.5 cm
  below it is simulated, and so are the ten links after the pick-up along
  the chain. A link left 1 cm outside the zone, at rest (it moved under
  0.1 mm in the last 1/100 s), is fixed again where it is; a moving link
  next to a fixed one is held to it by a joint, as the heap would hold it.
  4 cm across and 1.5 cm deep is where the fountain stops changing as the
  zone grows, at 1800 to 7200 steps a second; with it the run matches every
  link simulated, within the spread from pour to pour (see the theory
  check).
* The links are capsules 0.65 cm long and 4.5 mm thick, with their mass
  at their ends, joined by cone-twist joints that bend 30 degrees, true
  friction 0.3, no bounce; 1800 physics steps a second, 20 solver
  iterations, the joints' error correction 0.5 a step (Bullet's 0.2 lets
  them give, and the run then changes with the step), only touching
  contact points.
* The links keep their angular momentum: bpp solves their gyroscopic
  term (the w x Iw of Euler's equations) together with the joints and
  contacts (`body.gyroSolved`, since 20 Oct 2026). Bullet's own term is
  skipped for bodies this light in kg and cm (its 3x3 solve needs a
  determinant over 1.2e-7; a link's is 3e-15), so before then the links had
  none: a link spinning about its axis (they spin at about 200 rad/s) was
  turned as if its spin had the inertia across it, an error of 13-32% of
  the links' angular accelerations. Added from the script, before each
  step, the term makes a jointed chain gain energy without end; solved
  with the joints it does not. Its effect on the fountain is within the
  spread (every link simulated: -0.009 +- 0.006 in h2/h1; FINDINGS.md
  sections 14-15). A bpp from before then has no `gyroSolved`; the exhibit
  then says so and runs without the term. The balls' own moment of inertia
  is a solid ball's, 0.4 m r^2; the real balls are hollow (up to 2/3 m r^2;
  their wall is not measured), and 2/3 changes nothing beyond the spread
  (`CF_BALLI`).
* About 300-850 links move at a time, about 280 of them in the falling
  chain. A frame takes about 17-18 ms during the flow at an eighth of real
  speed (here, a 2-core machine; 14 with the shallower zone before 20 Oct
  2026); at a quarter it would take about twice that.

Both piles:

* A link that reaches the floor (2.5 cm up) is frozen where it lands, and
  from then on is only drawn: the chain coming down meets nothing there.
* Waking, freezing and measuring are done after every physics step, and a
  frame takes as many whole steps as its share of simulated time, so the
  run is the same, line for line, at any speed.

The coil (H, `CF_PILE=coil`): simulating every link of 16 m of chain at
once was too slow, so:

* The coil waits in the jar, drawn but not simulated, on a flat rigid pile
  (a disc lowered a layer at a time). Ten links ahead of the one being
  picked up are simulated, and more are woken as the chain comes for them
  (no faster than 1200 links a simulated second). The last link woken is
  held by its far end where it lies, as the rest of the coil would hold it;
  without that the moving chain dragged the woken links off in a heap.
  This makes its fountain 1.2-2 times as tall as the coil simulated whole.
* Only the moving chain is simulated: about 130-200 links, capsules 1.5 cm
  long and 6 mm thick joined by cone-twist joints, 1800 physics steps a
  second, 20 solver iterations.

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

Headless testing: `CF_PILE=heap|coil` (the heap by default), `CF_SPEED`,
`CF_STEPS`, `CF_BEND`, `CF_HEIGHT`, `CF_LAYERS`, `CF_LOG=file.csv`,
`CF_PUSH=1` (measure the pile's push and what the chain carries). The
coil's experiments below need `CF_PILE=coil` now. For experiments only
(the defaults are the exhibit): `CF_LAYOUT=flake`, `CF_JAR=0`, `CF_ITER` (solver iterations, 20),
`CF_MU` (each body's friction: the heap 0.548, a true 0.3; the coil 0.3,
a true 0.09), `CF_AHEAD` (links woken ahead, 10), `CF_STOP` (the
joints' limit, if not the bending the chain is laid for), `CF_LINK` (links
this many times as big; still drawn the usual size), `CF_LIVE=1` (every
link simulated, no waking, no anchor), `CF_SETTLE` (with `CF_LIVE`: seconds
the pile settles, the lead held), `CF_NOFREEZE=1` (landed links stay
simulated), `CF_WAKE=layer` and `CF_LIVELAYERS` (whole top layers
simulated), `CF_PUSH=2` (also the unmoved pile's push on the moving chain),
`CF_SLEEP=1` (resting links may sleep), `CF_CPT=d` (only contact points
closer than d cm), `CF_STATICLAYERS` (with `CF_WAKE=layer`: layers of
fixed links under the live ones), `CF_GLASSMU` (friction of the glass; a
contact's friction is the product of the two bodies'). For the heap test:
`CF_POUR=1` (`CF_NLINKS` links poured in by a hand `CF_POURH` cm over the
jar's floor, `CF_SEED` its wandering, `CF_FEED` cm/s; settled; the end
drawn over at `CF_PULL` cm/s and let go), `CF_POUR=2` (the same chain
coiled on the jar's floor instead), `CF_SAVEHEAP=file` and `CF_HEAP=file`
(save a settled heap, start from one; with `CF_LIVE=1` every link
simulated), `CF_RADIUS` (the links' radius), `CF_BEADI=1` (a link's mass
in balls at its ends), `CF_T0` (the theory check from this time on, 1 s),
`CF_DUMP=t:file` (where every moving link is at time t), `CF_GYRO`
(the links' gyroscopic term: `solver`, solved with the joints, the heap's
default (needs a bpp of 20 Oct 2026 or later); `bullet`, Bullet's own,
never applied to these links, the coil's default; `0`; `exact`,
`midpoint`, `implicit`: added before each step, unstable, for comparison),
`CF_BALLI` (a ball's own moment of inertia in m r^2, 0.4). The heap test's
chain: `CF_LINK=0.4333 CF_RADIUS=0.225 CF_BEADI=1 CF_NLINKS=1500`, or
`CF_PILE=heap`, which also starts from the poured heap (see the theory
check), with `CF_ZONE` and `CF_ZDEPTH` (the live zone, 4 and 1.5 cm; 0:
none, or a ball), `CF_ERP` (the joints' error correction a step: 0.5 there,
Bullet's 0.2 otherwise) and `CF_CPT` (0 there); `CF_PILE=heap CF_LIVE=1`
simulates every link of the heap.

## Files

* `chain-fountain.lua`: the exhibit. It runs on its own or in the Gallery.
* `FINDINGS.md`: everything found about this exhibit's physics, in order,
  from the first fixes to the poured heap.
* `chain-fountain-meshes/link.obj`: a link.
* `chain-fountain-meshes/bead-link.obj`: a link of the ball chain (the
  heap); `heap.txt`: its poured heap, the joint points
  from the end on, in cm over the jar's floor (`CF_PILE=heap CF_POUR=1
  CF_SEED=2 CF_SAVEHEAP=...`).
* `reconstruction/gyro-freebody.lua`, `gyro-hang.lua`, `gyro-mimic.py`:
  the tests of the links' gyroscopic term (a free link, a hanging chain of
  spinning links, a Python copy of Bullet's step); bpp's own test of
  `body.gyroSolved` is tests/09-gyro.lua at the top of the repository.
* `reconstruction/gen-link.py`: makes the link meshes
  (`python3 gen-link.py ../chain-fountain-meshes/bead-link.obj 0.225 0.65`).
* `reconstruction/bead-chain.c`: the bead chain outside Bullet (see the
  theory check); `cc -O2 -o bead-chain bead-chain.c -lm`, a few minutes a
  run.
* `reconstruction/bead-pour.c`: the heap test outside Bullet, the chain
  poured or coiled, with solid rods; `cc -O2 -o bead-pour bead-pour.c -lm`,
  `./bead-pour NB=1500 D=0.45 ROD=0.05 SEED=1` (`LAYOUT=1`: the coil);
  about 25 minutes a pour, 10 a run from a saved heap.
