# The Bicycle Wheel

A wooden lay figure sits on a swivel stool, feet off the floor, holding a
bicycle wheel by the handles on its axle. The wheel spins at 3 turns a
second, axle upright; the stool is still. Then the figure turns the wheel
over, and the stool starts to turn the other way. When it turns the wheel
back, the stool stops.

Nothing has pushed against the floor. The spin's angular momentum pointed
up and now points down, so the figure and the stool together have to take
up the difference: twice the wheel's.

Unlike the gyroscopes, gravity plays no part here and nothing precesses. It
is angular momentum being shared out between two bodies.

## Keys

| Key | Action |
|---|---|
| `F` | turn the wheel over (up <-> down) |
| `L` | hold it level: the stool turns half as fast (then `F` to go on) |
| `A` | turning it over by itself every 6 s: on/off (on to start with) |
| `R` | start again: stool still, wheel spun up, axle up |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (turns a second, on `R`), turn over (the seconds it takes),
stool friction, wheel friction, speed, steps. Rest the mouse on the wheel or
the stool. After each turn the console prints how fast the stool is turning
and how fast it should be by its angular momentum.

## The numbers

The wheel is 66 cm across and weighs 2.2 kg, mostly in the rim and tyre.
Its moment of inertia about the axle is 0.15 kg m^2, so at 3 turns a second
its angular momentum is 2.83 kg m^2/s.

The figure and stool have a moment of inertia of 2.5 kg m^2 about the
stool's axis. With the wheel held 47 cm out in front, that becomes 3.14.
Turned over, the stool should turn at 2 x 2.83 / 3.14 = 1.80 rad/s, a turn
in 3.5 s.

It does. With the friction sliders at 0, what it does and what it should do
agree to four figures. The angular momentum about the stool's axis stays
within 0.03% of where it started, through every turn.

With the friction on (the defaults), the stool slows a little between
turns, so it ends a hair off zero when the wheel comes back up. The wheel
slows too, so each turn moves the stool a little less (1.77, then 1.59,
then 1.42 rad/s). The console's "should" is worked out from the angular
momentum at the start of each turn, so it allows for the friction before
the turn but not during it, about 0.01 rad/s.

## Physics

* The stool's turning part and the figure are one rigid body, on a hinge
  (a vertical axis) to the floor, with a little friction in its bearing
  (0.02 N m).
* The wheel is one rigid body (axle, handles and wheel), on a hinge to the
  figure's body. The hinge's axis points straight out in front of the
  figure, through the wheel's centre: it stands for the figure's arms,
  which turn the wheel over about that axis and hold it every other way. A
  motor on the hinge turns the wheel over, smoothly, in 1.2 s. The arms are
  drawn from the shoulders to the handles.
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
over), `BW_STOOLF`, `BW_WHEELF`, `BW_LOG=file.csv` (time, turn angle, axle,
stool rate, what it should be, spin, angular momentum about the axis).
