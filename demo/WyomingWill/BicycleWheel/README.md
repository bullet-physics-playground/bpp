# The Bicycle Wheel

A wooden lay figure sits on a swivel stool, feet off the floor, holding a
spinning wheel by the handles on its axle, axle upright; the stool is still.
Then the figure turns the wheel over, and the stool starts to turn the
other way. When it turns the wheel back, the stool stops.

Nothing has pushed against the floor. The spin's angular momentum pointed
up and now points down, so the figure and the stool together have to take
up the difference: twice the wheel's.

While the stool turns, the figure can hold the wheel close or push it out
at arm's length. Pushed out, the stool slows down; pulled back in, it
speeds up again. The angular momentum is the same, shared over more or less
moment of inertia: a figure skater's arms.

Unlike the gyroscopes, gravity plays no part here and nothing precesses. It
is angular momentum being shared out between two bodies.

## Keys

| Key | Action |
|---|---|
| `F` | turn the wheel over (up <-> down) |
| `L` | hold it level: the stool turns half as fast (then `F` to go on) |
| `O` | push the wheel out, arm's length (50 cm in front) |
| `I` | pull it in close (34 cm) |
| `A` | going round it all by itself: on/off (on to start with) |
| `R` | start again: stool still, wheel spun up, axle up, held close |
| `Z` | slow motion (1/4) <-> real time |

By itself it turns the wheel over, pushes it out, pulls it in and turns it
back, a few seconds apart, and over again. `F`, `L`, `O` and `I` stop that
and do just what they say; `A` starts it again.

Sliders: spin (turns a second; moving it starts again with the new spin,
half a second after you let go), turn over and push out (the seconds each
takes), stool friction, wheel friction, speed, steps. Rest the mouse on the
wheel or the stool. After each move the console prints how fast the stool
is turning and how fast it should be by its angular momentum.

## The numbers

The wheel is small, 44 cm across, so the figure can bring it in close. It
weighs 3 kg, most of it in a heavy rim, so its moment of inertia about the
axle is 0.115 kg m^2. Spun at 4 turns a second, its angular momentum is
2.89 kg m^2/s.

The figure and stool have a moment of inertia of 1.5 kg m^2 about the
stool's axis. With the wheel and the hands holding it (1 kg), that becomes
2.09 held close (34 cm out) and 2.63 pushed out (50 cm).

| | should turn at | does |
|---|---|---|
| turned over, held close | 2 x 2.89 / 2.09 = 2.77 rad/s | 2.769 |
| pushed out | 2 x 2.89 / 2.63 = 2.20 rad/s | 2.202 |
| pulled back in | 2.77 rad/s | 2.769 |
| turned back up | 0 | 0.000 |

Those are with the friction sliders at 0. The angular momentum about the
stool's axis stays within 0.1% of where it started, through every move.

With the friction on (the defaults), the stool slows a little between
moves, and the wheel slows too, so each round moves the stool a little less
(2.72, then 2.46, then 2.19 rad/s turned over and close). The console's
"should" is worked out from the angular momentum at the start of each move,
so it allows for the friction before the move but not during it, about
0.02 rad/s.

## Physics

* The stool's turning part and the figure are one rigid body, on a hinge
  (a vertical axis) to the floor, with a little friction in its bearing
  (0.02 N m).
* The wheel is one rigid body (axle, handles and wheel), on a hinge to the
  figure's hands: a body of their own, 1 kg, on a slide straight out in
  front of the figure. The hinge's axis points along the slide, through the
  wheel's centre: it stands for the figure's arms, which turn the wheel over
  about that axis and hold it every other way. A motor on the hinge turns
  the wheel over, smoothly, in 1.2 s; a motor on the slide moves the hands
  in or out in 1.5 s. The arms are drawn from the shoulders to the handles.
* The wheel's spin is carried as a number, an angular momentum inside its
  body (a "gyrostat", as in the gyroscopes). The wheel is drawn turning at
  the angle it's at. Bullet's gyroscopic term is off; the body's
  gyroscopic torque, -w x (I w + h), is handed to Bullet as a torque before
  every step (Adams-Bashforth, from the last two steps), so the hinges
  answer it as they would any other force. That is what turns the stool:
  the hinge in the figure's arms pushing back.
* The wheel slows a little: 0.02 turns a second, each second.
* 1200 physics steps a second, 30 solver iterations.

## Files

* `bicycle-wheel.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `bicycle-wheel-meshes/`: the stool (its base and seat), the figure and its
  arms, the wheel (the part that turns, the tyre, a red mark) and its axle
  with the handles.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `BW_SPIN` (turns a second), `BW_FLIP` (seconds to turn
over), `BW_PUSH` (seconds to push out or pull in), `BW_STOOLF`, `BW_WHEELF`, `BW_LOG=file.csv` (time, turn angle, axle,
stool rate, what it should be, spin, angular momentum about the axis).
