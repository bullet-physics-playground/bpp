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
the rim to the floor; the chain runs at 3-5 m/s, so it starts at a quarter
of real speed. The fountain stands 5-20 cm above the rim (the console
reports it every second), and the jar is empty in about 4 seconds (16 at
quarter speed). R starts again.

How the bending limit matters, same jar and chain:

| Joints bend at most | Fountain above the rim (typical, highest) |
|---|---|
| 20 degrees | 10-25 cm, 35 |
| 30 degrees (default) | 10-20 cm, 29 |
| 60 degrees | 5-7 cm, 13 |
| 90 degrees | 2-9 cm, 10 |

## Keys

| Key | Action |
|---|---|
| `R` | start again, with the sliders' chain settings |
| `V` | the fountain close up <-> the whole drop |
| `Z` | quarter speed <-> real speed |

Sliders: speed, steps, bending (degrees), height (the jar above the floor),
layers (how much chain, 1.6 m a layer), friction. Bending, height and
layers apply when you press R. Rest the mouse on the chain to see how fast
it's going.

## Simulation

Simulating every link of 16 m of chain at once was too slow, so:

* The coil waits in the jar, drawn but not simulated, on a flat rigid pile
  (a disc lowered a layer at a time). Ten links ahead of the one being
  picked up are simulated, and more are woken as the chain comes for them.
* A link that reaches the floor is frozen where it lands.
* So only the moving chain is simulated: about 150-200 links, capsules
  joined by cone-twist joints, 1800 physics steps a second, 20 solver
  iterations. At quarter speed it needs about two-thirds of one processor
  core.

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
