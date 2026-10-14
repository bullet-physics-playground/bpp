# Galileo's Ramp: the Rolling Race

Five things roll down a ramp side by side, let go together: a wooden ball,
a small steel ball, a wooden disc, a brass hoop and a can of soup. Which
wins?

Not the heaviest, nor the biggest. All that matters is how much of each
one's mass is out at its rim. Rolling, a body has to spin up as well as
speed up, and a hoop, all rim, spends half its energy spinning. The soup
wins: the can turns, but the soup inside hardly does, so nearly all its
energy goes into running down the ramp. The two balls, one big and wooden,
one small and steel, tie.

When all five are across the line, they're lined up again.

## Keys

| Key | Action |
|---|---|
| `R` | line them up and let them go again |
| `Z` | slow motion (1/4) <-> real time |

Rest the mouse on a racer to see its k and its time by theory.

## The theory, and what the console says

Rolling without slipping down a slope theta, a body of mass m, radius r
and moment of inertia I = k m r^2 accelerates at

    a = g sin(theta) / (1 + k)

whatever its mass and size, so it takes sqrt(2 d / a) to roll a distance
d. For a ball, k = 2/5; a disc, 1/2; a hoop, nearly 1. For the can, only
its tin turns (the soup doesn't), so k = 0.094.

    Soup   1st across the line at 1.5992 s (theory 1.5994, -0.013%), at 125.1 cm/s (theory 125.0)
    Ball   2nd across the line at 1.8095 s (theory 1.8097, -0.011%), at 110.5 cm/s (theory 110.5)
    Steel  3rd across the line at 1.8095 s (theory 1.8097, -0.011%), at 110.5 cm/s (theory 110.5)
    Disc   4th across the line at 1.8730 s (theory 1.8732, -0.011%), at 106.8 cm/s (theory 106.8)
    Hoop   5th across the line at 2.1009 s (theory 2.1011, -0.010%), at 95.2 cm/s (theory 95.2)

Each one's time and speed at the line match theory to a hundredth of a per
cent.

## The racers

| Racer | Size | Mass | k |
|---|---|---|---|
| wooden ball | 5 cm across | 46 g | 0.400 |
| steel ball | 2 cm across | 33 g | 0.400 |
| wooden disc | 5 cm across, 2 cm thick | 28 g | 0.500 |
| brass hoop | 5 cm across, 3 mm thick, 1.5 cm wide | 57 g | 0.887 |
| can of soup | 6.6 cm across, 9 cm long: 40 g of tin, 330 g of soup | 370 g | 0.094 |

The ramp is 1.2 m long at 5 degrees, with the finish line 1 m down from
the start.

## Physics

* Bullet, with its own contacts. The balls are spheres.
* The disc, hoop and can roll in their lanes, turning about their axes
  only. Held like that, touching the ramp along a line across it is the
  same as touching it at the line's middle, so to Bullet each is a sphere
  of its radius. Each has its own moment of inertia: the hoop's all at its
  rim, the can's its tin's.
* Bullet's own cylinders, touching along a line, jitter and lose 2% of
  their speed, which is why they aren't used.
* Friction 0.8, so none slips. 2400 physics steps a second.
* The moment each crosses the line is caught to the physics step.

## Files

* `galileo-ramp.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `galileo-ramp-meshes/`: the disc, the hoop, the can and their painted
  marks.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `GR_SPEED`, `GR_STEPS`, `GR_SLOPE` (degrees),
`GR_LOG=file.csv`.
