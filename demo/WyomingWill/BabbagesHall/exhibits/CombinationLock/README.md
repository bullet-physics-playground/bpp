# The Combination Lock

*Babbage's Hall, east bay 2: a lock that tests a number.*

**`MANUAL.pdf`** is the manual: how the lock works, how to dial a
combination and why the rules are what they are, with pictures, and the
exhibit's keys (`H` opens it, here or in the hall). This README is the
builder's reference.

The fourth machine on the walk, and the last of the simple hand-worked
pieces. A dial turns a drive cam; behind it three wheels turn loose on a
fixed post, each with a notch in its rim, its **gate**. A steel pin in the
cam's back, and one through each wheel, give the **lost motion**: turning
the dial, the cam's pin comes round to wheel 3's pin after nearly a turn
and carries wheel 3 on; wheel 3's pin carries wheel 2, and wheel 2's
wheel 1. So the dialling rules set one wheel at a time:

1. **Left four times** to the first number: within three turns every
   wheel has been picked up, and wheel 1, at the back, is left on it.
2. **Right three times** to the second: wheel 1 stays where it is; wheels
   3 and 2 come round, and wheel 2 is left on it.
3. **Left twice** to the third: wheel 3.
4. **Right until the dial stops**: the cam's notch comes under the fence.

A lever pivoted on the bolt lays a steel rod, the **fence**, across the
rims of all three wheels and the cam. The cam is 0.4 mm bigger than the
wheels, so the fence rests on it, clear of the wheels. When the cam's
notch comes under the fence it can fall, but only as far as the wheels let
it: into their gates if all three are under it, else 0.4 mm onto their
rims. Fallen into the gates, the notch's steep wall hooks it, and turning
on pulls the fence, the lever and the bolt. This is Sargent & Greenleaf's
arrangement, as in a safe's door, made big and open. The lock is set to
**31-72-46**.

A slate behind shows the combination the lock is set to and the one being
tried, each step, the dial's reading, where each gate stands from under the
fence (in the dial's numbers), and whether the bolt is out.

**The safecracker's way** (`LK_WAY=safe`; in the hall, `Tab`) reads the
combination off the lock without being told it, as safecrackers
manipulate real dial locks. The three wheels aren't quite alike (40.0,
39.9 and 39.8 mm in radius: here on purpose, and more than printing would
leave them), and when the cam's notch is under the fence, the fence rests
on the largest wheel whose gate isn't under it. Rocked gently, the dial
stops where the fence meets the notch's two chamfered walls: the **contact
points**. When a gate comes under the wheel holding the fence up, the
fence drops 0.1 mm onto the next, meets the walls further in, and the gap
between the contact points narrows by 0.16 numbers. So the safecracker
parks all three wheels together on each number and graphs the gap: it
narrows at wheel 1's number. With wheel 1 left there, wheels 2 and 3
parked together give wheel 2's. Each graph stops just past the narrowing,
and then the narrowing's two edges are found a half number at a time
(a real safecracker graphs the whole dial; MANUAL section 8 says why). The last wheel is tried, every second
number, until the lock opens. The slate hides the combination until then,
and draws the graph in chalk; a reading narrower than the graph's level
turns blue there and on the dial, a number found turns gold, and the
combination green when the lock opens. It can be heard too: a click as each wall
stops the dial (what a contact microphone on the case would pick up). The
dial is chalked at the two contact points, with the arc between them, the
gap, blue when it reads narrower (MANUAL section 8).

    bpp -f combination-lock.lua            (or walk to it in the hall)
    LK_WAY=safe bpp -f combination-lock.lua

| Key | |
|---|---|
| `0`–`9` | a combination: six figures (31 72 46); `Return` dials it by the rules and tries to open |
| `Backspace` | a figure off |
| `L`, `R` | the dial one number left, right |
| `Space` | right until the dial stops: opens the lock if the fence can fall |
| `C` | close: left two turns (the bolt thrown, the wheels scrambled) |
| `M` | the camera close to the dial (again: back; walking on puts the view back too) |
| `G` | the camera above the gates under the fence (again: back) |
| `T` | the tour: the lock's own combination (it opens), the last number five off (it doesn't), every number one off (it opens). In the safecracker's way, the safecracker's tour (about 11 minutes; the speed slider hurries it) |
| `F` | (the safecracker's way) feel the contact points, the wheels where they are, and show them and their gap |
| `H` | the manual, `MANUAL.pdf`, opened in your PDF viewer |

The slate warns before dialling a combination the rules can't set (the
second number 0 to 11 above the first, the third 0 to 7 below the second)
or one in the forbidden zone (a last number from 90 to 99), and then the
lock does what it does. The sliders: the hand's speed, the wheels' drag
and the simulation's speed. Resting the mouse on a part says what it is,
the dial's reading and where the gates stand.

## What is simulated, and what is the script's

The dial's body (the cam and its pin, with the spindle, the dial and its
knob), the three wheels (each with its pin), the bolt and the lever with
its fence are bodies; the dial and the wheels on hinges, the bolt on a
slider, the lever on a hinge on the bolt. Every push is a contact: pin on
pin, the fence on the cam and the rims, in the gates and in the cam's
notch. Each wheel and the cam are their printed outlines cut into convex
pieces (`lock.lua`; 13 for a wheel, 14 for the cam). Where two pins meet,
in the middle of the gap between their parts, each is a sphere of its
radius: Bullet's cylinder-on-cylinder contacts came out with false normals
that dragged a resting wheel along (`FINDINGS.md`).

The wheels and the bolt are held where they are left by friction (a
hinge's or a slider's motor at no speed: the wheels' wave washer and the
bolt's guides); the lever is pressed down by a torsion spring on its pivot
pin (a steady torque, 0.3 N at the fence). The operator's hand is the
script's: it turns the dial as a person does, at up to 70 numbers a
second, slowing to stop on a number, and turns the first 20 numbers of a
close steadily. Feeling for a contact point, it turns the dial at 3
numbers a second with not much more torque than the dial's own friction
(0.6 N cm against 0.3), so the dial stops where the fence
meets the wall, and the hand reads it there. The safecracker is the
script's too, but it is told nothing: it reads the dial, and its steps are
a coroutine in the order a person takes them. The slate, its numbers, its
graph and its warnings are the script's. Whether the lock opens is the
bolt's own position at the end.

## The parts

`./make-stls.sh` makes the STLs (OpenSCAD), each turned to lie on the
printer's bed; all are under 200 mm. `COMBO=12-34-56 ./make-stls.sh`
cuts the wheels' gates for another combination (the wheels are the only
parts that change; `lua lock.lua gates 12 34 56` gives their angles).

| Part | Print | Notes |
|---|---|---|
| `wheel-1.stl`, `wheel-2.stl`, `wheel-3.stl` | 1 each | the wheels, 80.0, 79.8 and 79.6 mm across (a little different on purpose: the safecracker's way feels which holds the fence up), 5 mm thick, each with its gate cut for its number and its number cut in its face; a hole for its pin |
| `cam.stl` | 1 | the drive cam, 80.8 mm, its notch (a steep wall and a sloping one, both chamfered at the top); a flat-sided hole for the spindle |
| `dial.stl` | 1 | the dial and its knob, in one, knob down |
| `dial-marks.stl` | 1 | the dial's marks and numbers, raised 0.6 mm: print in a second colour on top of the dial, or paint them (119 separate marks: not a part on its own) |
| `washer.stl` | 3 | spacers between the wheels on the post |
| `back-plate.stl` | 1 | the back plate with the wheel post (12 mm) |
| `base.stl` | 1 | the base the back plate, the front standard and the keeper stand on |
| `standard.stl` | 1 | the front standard (the door): the spindle's bearing, and the index at its top |
| `guide.stl` | 2 | the bolt's guides, glued to the back plate |
| `keeper.stl` | 1 | the keeper (the door frame's strike) the bolt goes into |
| `bolt.stl` | 1 | the bolt, 10 × 10 mm, a hole for the lever's pivot pin |
| `lever.stl` | 1 | the lever: a hole for its pivot pin, one for the fence |
| `slate-left.stl`, `slate-right.stl` | 1 each | the slate's board (34 × 15 cm) in halves; paint it with blackboard paint |
| `slate-frame-left.stl`, `slate-frame-right.stl`, `slate-stand.stl` | 1, 1, 2 | its frame, and the posts it stands on |

**To buy:** three 3 × 14 mm steel dowel pins (the wheels) and one 3 ×
10 mm (the cam); a 4 mm steel rod, 48 mm long (the fence), and a 4 ×
18 mm pin (the lever's pivot); an 8 mm steel rod, 40 mm long, with a flat
filed along 8 mm of one end (the spindle); a small torsion spring for
the pivot pin (about 0.3 N at the fence's end, 60 mm out: a pen spring
bent to shape will do); a thin wave washer for the 12 mm post (it presses
the pack together: that is the wheels' drag) and an e-clip or a printed
collar to hold the pack on; glue.

**Assembly.** Press each wheel's pin through its hole, centred (4.5 mm
out each side), and the cam's pin into the cam's back. Slide onto the
post, from the back plate: a spacer, wheel 1 (number forward), a spacer,
wheel 2, a spacer, wheel 3; then the wave washer and the collar. Glue
the back plate, the standard and the keeper to the base, and the guides
to the back plate. Push the spindle through the standard into the cam
(the flat in the cam's hole) and the dial onto its front end. Put the
bolt in its guides, the lever on its pin with the spring behind it, and
press the fence into the lever. Turn the dial to 0: the cam's notch
should be at the top, under the fence; glue the dial there.

Each wheel's drag should be light but steady (the dial turns the pack
with a finger; a wheel left alone doesn't move when the next is turned).
For the safecracker's way, measure the wheels across with calipers: they
should come out 0.2 mm apart, largest wheel 1. A printer that doesn't hold
that can sand the rims to it. The wheels need a firmer drag for it than
for dialling: in the simulation each is 0.8 N cm (dialling works from 0.1
to 1), and at 0.4 or less the fence, dropping onto a wheel as its gate
comes near, turns it into line and the graph's narrowing comes too soon
(`FINDINGS.md`).
The bolt must slide easily: in the simulation the relock fails once the
bolt's friction is more than about three times the spring's press at the
fence (`FINDINGS.md`). Sand and wax the bolt, or use a stronger spring.

## Files

| File | |
|---|---|
| `combination-lock.lua` | the exhibit |
| `lock.lua` | the geometry, the convex pieces, the model of the wheels, the gates for a combination, the dialling rules; `lua lock.lua scad` writes `parts/lock-geometry.scad` |
| `lock-test.lua` | every combination through the model: which the rules set, the forbidden zone, the tolerance, how many combinations open the lock; and the safecracker's method on 40 random locks (`lua lock-test.lua`, 3.5 minutes) |
| `parts/combination-lock.scad`, `parts/lock-geometry.scad` | every part's shape; the sizes (written by `lock.lua`: don't edit) |
| `make-slate.py`, `slate/` | the slate's pictures, and the steps' words |
| `make-sounds.py`, `sounds/` | the safecracker's clicks, one for each notch wall (`python3 make-sounds.py`; numpy). The chalk on the dial is `chalkTick` and `chalkArc` in `parts/combination-lock.scad` |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
| `MANUAL.md`, `manual/` | the manual and its figures (`python3 manual/make-figures.py` redraws them from `lock.lua` and the parts, but for `fig-exhibit.png`, a screenshot) |
