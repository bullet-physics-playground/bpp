# The fixed-wing UAV

`model.lua` is the book's fixed-wing aircraft (Ch. 13 §13.2.3, `BOOK.md`
G12) as a kinematic model: 13 m/s always, turn rate at most
Ω_max = g sin 20° / (2 × 13) = 0.129 rad/s (Eq. 13.14), so loops of at least
101 m; a 10 Hz outer loop commands the turn rate. It cannot stop, slow or
reverse, which is why the book says point-mass physicomimetics cannot
control it and gives it a heading particle with a torque law instead.

The experiments with it, and the measurements, are in `../ch13/README.md`
(`../ch13/UAV-Attractor.lua`, `../ch13/UAV-Targets.lua`); the check is
`../checks/fixedwing.lua`.

Not modelled: bank and speed dynamics (the book treats them as
instantaneous), wind, height (all UAVs fly in one plane), a 6-DOF airframe.
It is not yet behind the vehicle interface (`../lib/swarm.lua`): its
outer loop commands a turn rate, not a point to reach.
