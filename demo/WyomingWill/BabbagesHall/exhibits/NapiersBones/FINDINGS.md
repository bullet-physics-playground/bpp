# Napier's Bones: findings

*What was tried and measured in building it (2026-11-16).*

## The arithmetic, and the set

`bones-test.lua`, with no physics:

- Glaisher's ten rods carry every digit four times and no digit twice on
  a rod. All 10,000 four-digit strings (0000 to 9999) can be laid with
  four of them, as Wikipedia says of Napier's scheme. Longer numbers
  mostly can: 99.8% of five-digit, 99.2% of six-digit and 97.5% of
  seven-digit numbers (20,000 random each).
- 29,959 random products (numbers of 1 to 6 digits that the set can lay,
  times 1 to 999) come out right both ways, against schoolbook
  multiplication.
- The sources' examples: 6785 × 8 = 54280 (Wikipedia); 4138 × 567 =
  2346246, its rows 20690, 24828 and 28966 (MacTutor); 52749 × 4 =
  210996 on Genaille's rods (Wikipedia); 874 × 7 = 6118 (Giesen); and the
  4 rod's row 7, 8 9 0 1 2 3 4 (Roegel).

## Laying the rods

The rods are bodies; the board, its ledge, the index rod and the tray are
solid. The hand holds a rod by steering its speed and spin toward where it
should be, its weight held. It sets the rod down 2.5 mm clear of its
neighbour, lets go, and presses it left and down with 0.3 N until it
stops. Every rod ends within 0.01 mm of its place when the press ends,
square to 0.03 degrees.

The press first ran to its 5 s timeout most of the time. Under the press a
rod keeps turning at about 0.01 rad/s, solver jitter, which at its ends
read as motion. A rod now counts as still under 0.03 cm/s and 0.02 rad/s.

## The creep, and sleeping

Let go, a rod creeps away from its neighbour. A rod watched for 10 s after
its press moved 0.4 mm in 4 s and stopped (`NB_CREEP=1`). The next rod's
press pushes it back, so only the last rod laid keeps its creep, and that
one creeps on: 2 mm in the 15 s it takes to read 4138 × 567's three rows
(about 0.005 cm/s). Changing the step rate (300 to 2400 a second),
friction or damping didn't stop it. It is the size of Bullet's built-in
contact tolerances, which assume metres: in this hall's centimetres they
come to 0.2 to 0.4 mm. Real friction doesn't creep.

So a rod still for 2 s, under 0.05 cm/s, now sleeps: Bullet's own way with
resting bodies. It stops being stepped until a moving body touches it.
That took finding that bpp adds every body unable to sleep
(`DISABLE_DEACTIVATION`, unless its deactivation switch is on), and that
Bullet's `setActivationState` won't change that state; `forceActivationState`
does. The hand keeps the rod it holds or presses awake. With sleeping, the
largest gap between rods at the reading is 0.21 mm (without, 1.97 mm).
Neither matters to the answer, which allows a rod to be half a cell, 8 mm,
out; but the rods should lie where they were put.

## Sweeps

Each tour, headless (the sweeps ran before the hand was sent out of the
way after laying the last rod, which adds about 100 frames). "Worst" is over every product: the largest gap
between neighbouring rods, how far any rod stood off the ledge, and its
skew (from square to the board) and roll (from face up), in degrees.

| | Napier tour (4 products) | worst |
|---|---|---|
| as it is: friction 0.4, hand 12 cm/s, press 0.3 N, 600 steps/s, tilt 20 | PASS, 11,389 frames | gap 0.21 mm, ledge 0.00, skew 0.03, roll 0.03 |
| friction 0.2 | PASS | gap 0.16 mm |
| friction 0.7 | PASS | gap 0.42 mm, ledge 0.08 mm, skew 0.39 |
| friction 0.85 | PASS | gap 2.49 mm, ledge 0.16 mm, skew 0.38 |
| friction 1.0 | **FAIL**: 2222 × 9 read 19980 | gap 5.68 mm, ledge 0.96 mm, skew 0.67 |
| hand 5 cm/s | PASS, 17,736 frames | gap 0.04 mm |
| hand 25 cm/s | PASS, 9276 frames | gap 0.28 mm |
| press 0.1 N | PASS | gap 0.22 mm |
| press 0.8 N | PASS | gap 0.04 mm |
| 300, 1200, 2400 steps a second | PASS | gap 0.44, 0.03, 0.06 mm |
| tilt 5, 10, 35 degrees | PASS | gap 0.08, 0.04, 0.70 mm |
| no sleeping (`NB_SLEEP=0`) | PASS | gap 1.97 mm |
| 20 random problems (`NB_RANDOM=20`) | PASS, 20 right | gap 0.26 mm |
| Genaille tour (3 products) | PASS, 7889 frames | gap 0.08 mm |
| Genaille, no sleeping | PASS | gap 0.16 mm |
| Genaille, 20 random problems | PASS, 20 right | gap 0.26 mm |

At friction 1.0 the 0.3 N press can't seat the rods: they stop short of
the ledge and of each other. In 2222 × 9 the fourth rod, pressed sideways
against a sticky neighbour, rolled over its edge: it lay 5.7 mm out with
its 0 face up, and the row read 1/8 1/8 1/8 0/0, giving 19980. The
reading, taken from the rods as they lie, caught it. A real set wants rods
that slide easily: sand and wax them.

check-all allows 12,500 frames for the Napier tour (13,100 in the hall)
and 9000 for Genaille's (9600).

## The faces

`make-faces.py` draws each face once, for the textures and for the sheets
to print (SVG, then PDF through Chromium). Rasterised at 600 dpi, both
sheets' check bars measure 99.86 mm and a strip 64.09 mm border to border
(its border line is 0.15 mm wide), 176.11 mm tall. As on the slide rule,
bpp's textures have no mipmaps, so no line is under 2 pixels (8 a mm), and
`M` brings the camera to the board (34 cm off, with a 0.62 rad view: in
the hall bpp clips nearer than about 21 cm), put back on leaving.

## The printed parts

Every STL is one watertight solid under 200 mm. The slate's board first
came out 240 mm tall with its legs; it is now printed apart from its
stand. Put together, six rods on the board beside the index rod and all
ten in the tray, no two parts overlap (the largest common volume is
0.046 mm³: the rods resting on the board).

**Not tested:** a printed set. Whether paper strips wrapped round the rods
(0.1 mm a layer) keep the rows of neighbouring rods level with the
index's (they should: every rod, the index too, is wrapped the same way),
and whether the rods slide as easily as friction 0.4 assumes.
