# Machines for Babbage's Hall

`MACHINES.pdf` beside this file is a typeset copy of it.

Every non-electronic computing machine worth considering for the hall, from
the list we began with and its additions (the conversation as exported, in
*Mechanical computation machines*), the three papers (*Early Computing
Machines*, *Computing after Babbage*, *Ball-and-disk integrator*) and the
rest of the field. Clocks are left out (they are a collection of their own), and so are
machines that compute with relays, valves or flowing water (see the end).

Each is scored from 1 to 5 for **interest** (how much there is to see and
understand: surprise, motion, history) and for **complexity** (how hard to
simulate in bpp and to print and build). The list ranks them by interest as
I judge it, the most interesting first; the scores group them, and the
order within a score is the judgement. The hall's bays follow the same
order, walked the other way: the least interesting at the entrance, the
Difference Engine at the far end.

**Changes since the first list:** Lehmer's sieve was scored 5 there (with a
ball that drops when the holes line up), then 3; it is 4 here. The Curta and
the Enigma were left out there (too dense; electromechanical) and are in
here: the Curta as a cutaway, the Enigma for its mechanical stepping.

**Status:** *built*: in the hall, with its STL files; *bay*: has a covered bay
"in preparation"; blank: not yet planned.

## The ranked list

| # | Machine | Year | What it does | In bpp, and printed | Int. | Cx. | Status |
|---|---|---|---|---|---|---|---|
| 1 | Babbage's Difference Engine | 1822 / 1849 | tabulates a polynomial by adding its differences, with no multiplying | two orders of difference, three digits, is a good model: figure wheels and Babbage's carry, after the Pascaline | 5 | 5 | bay |
| 2 | Antikythera mechanism | c. 100 BCE | a gear train for the Sun, Moon and planets, the lunar phase, eclipse dials; a pin-and-slot gear for the Moon's varying speed | gears, as in the Differential (convex-hull teeth), and many of them; printed replicas exist | 5 | 4 | |
| 3 | Enigma (its rotors' stepping) | 1923 | a keypress steps the rotors by pawls and notches; the current's path through them lights the cipher letter | the stepping is mechanical (the middle rotor's double step comes of itself); the wiring is a lookup in Lua; prints, with wire, contacts and LEDs (first left out as electromechanical) | 5 | 3 | |
| 4 | Differential Analyser | 1931 | wheel-and-disc integrators, wired in a loop, solve differential equations and draw the answer | rolling contact that must not slip; Bush's torque amplifiers can be motors; Hartree built one in Meccano | 5 | 4 | bay |
| 5 | Zuse Z1 | 1938 | the first freely programmable computer, binary floating point, all mechanical: sliding steel plates and pins | its plate logic is lovely to simulate gate by gate; the whole machine is far beyond us | 5 | 5 | |
| 6 | Norden bombsight | 1930s | a gyro-steadied sight whose analogue computer (rate discs, cams) solves the bombing problem | the computing (disc integrators and cams) is doable; the gyro too, as in Euler's Gallery; whole, very complex | 5 | 5 | |
| 7 | Ford Rangekeeper Mk I | 1917 | a battleship's fire-control computer: integrators, differentials and cams solve where the target will be | its parts each are doable (the Differential, integrators, cams); together, a big job | 5 | 5 | |
| 8 | Curta | 1948 | a pocket four-function calculator: one stepped drum, nines' complements for subtraction | small and dense: the stepped drum and carry are doable, the whole machine very hard; best as an oversized cutaway (first left out as too dense) | 5 | 4 | |
| 9 | Kelvin's tide predictor | 1872 | adds ten or more sine waves (the Sun's and Moon's tides) and draws a year of tides | cranks and slotted yokes are easy; the cord over the pulleys that adds them: bpp has no rope, but a rope of linked beads works if it isn't much lighter than its weights (tested: see below) | 5 | 3 | bay |
| 10 | Digi-Comp II | 1968 | marbles rolling down a board of flip-flops count, add and multiply in binary | marbles and levers: contact only, like the dominoes; tuning the flip-flops is the work | 5 | 3 | bay |
| 11 | Domino Half Adder | modern | dominoes falling add two bits | built: 268 dominoes on printed tiles | 4 | 2 | built |
| 12 | Pascaline | 1642 | adds, with Pascal's falling-weight carry | built: three digits, sautoirs, detents, stylus and stop | 4 | 3 | built |
| 13 | Galton board | 1873 | balls falling through pins pile up into the normal curve | balls and pins only; easy, and a good opener | 4 | 1 | |
| 14 | Planimeter (Amsler's polar) | 1856 | trace a shape's outline and a rolling wheel reads its area | one wheel rolling and slipping on paper; small and clear | 4 | 2 | |
| 15 | Ball-and-disk integrator | 1876 | James Thomson's: a ball between a turning disc and a cylinder; the cylinder turns as the integral | the ball must roll without slipping; the integrator the tide predictor's brother and the analyser's ancestor | 4 | 2 | |
| 16 | Integraph | 1880s | follows a curve and draws its integral | a wheel steering by its knife edge; a small step on from the planimeter | 4 | 3 | |
| 17 | "Basic Mechanisms" kit | 1953 | the US Navy fire-control course's set: differential, cam function generator, slide multiplier, component solver | each a small exhibit; together, one bay that explains the aiming machines | 4 | 2 | 
| 18 | Kelvin's harmonic analyser | 1878 | integrators find the Fourier coefficients of a measured curve (the tide predictor in reverse) | ball-and-disk integrators in a row | 4 | 3 | |
| 19 | Thomas Arithmometer | 1820 | the first mass-produced calculator: stepped drums, a sliding carriage | a stepped drum per digit and a carry; a fine follow-on to the Pascaline | 4 | 3 | |
| 20 | Leibniz's stepped reckoner | 1694 | the first four-function calculator: the stepped drum | the stepped drum is the heart of the next three machines | 4 | 3 | |
| 21 | Odhner pinwheel calculator (Brunsviga, Facit) | 1873 | pinwheels with retractable pins set the figures; turn the crank | flat pinwheels print well; the carry is the work | 4 | 3 | |
| 22 | Automatic Totalisator | 1913 | racetrack betting: a great shaft adder of differentials counts tickets and sets the odds | differentials (built) chained; the first real-time computer, the Science Museum says | 4 | 3 | |
| 23 | Hagelin M-209 | 1940 | a fully mechanical cipher machine: six pin wheels and a drum of 27 lugged bars | all mechanical, but many small parts: pins, lugs, a print wheel | 4 | 5 | 
| 24 | Torres Quevedo's algebraic machines | 1890s | find the roots of polynomials with his "endless spindle" logarithmic gearing | special gearing; little known and striking | 4 | 4 | |
| 25 | Kelvin's equation solver (and Wilbur's) | 1878 / 1936 | tilting plates on pulleys and cords solve simultaneous linear equations | plates, pulleys, cords: the cords are the hard part | 4 | 3 | |
| 26 | Michelson and Stratton's harmonic analyser | 1898 | 80 springs sum and analyse waves; it showed the Gibbs overshoot | springs and levers: Bullet springs, many of them | 4 | 3 | |
| 27 | Comptometer | 1887 | key-driven adder: press a key and the column moves at once | keys, sectors and carry; no crank | 4 | 3 | |
| 28 | Digi-Comp I | 1963 | plastic sliders and pegs: three flip-flops and programmable logic | slides, pegs and a lever: simple parts, many of them | 4 | 2 | |
| 29 | Dr. Nim | 1965 | a marble machine that plays Nim, and wins | a few flip-flops and marbles: a little cousin of the Digi-Comp II | 4 | 2 | |
| 30 | Marble adders (Turing Tumble, Wandel's) | modern | marbles flip levers to add binary numbers | contact and gravity; very like the Digi-Comp II | 4 | 2 | |
| 31 | Argo clock and Dreyer table | 1912 / 1911 | WWI battleship fire control: plotting the target's course and range by integrators and a plotting table | integrators (as the ball-and-disk) and a plotting pen | 4 | 4 | 
| 32 | Torpedo Data Computer | 1940s | a submarine's analogue fire control | like the rangekeeper, smaller; partly electrical | 4 | 5 | |
| 33 | Lehmer's number sieve | 1926 / 1932 | factors numbers: loops of different lengths (bicycle chains, later toothed wheels) turn until gaps line up, and a ball or pin drops through to stop it | printable wheels with holes in place of chains, and a falling probe; simple shafts | 4 | 3 | bay
| 34 | The Differential | 1827 | gears that add and subtract (Pecqueur's patent; older in clocks) | built: printed bevel gears | 3 | 2 | built |
| 35 | Schickard's calculating clock | 1623 | the first known calculator: adding wheels and Napier's bones | a one-tooth carry gear (it jams on long carries: worth showing beside the Pascaline) | 3 | 3 | |
| 36 | Jacquard's card reader | 1804 | punched cards choose which hooks lift: the first stored program | needles, cards and hooks; a reader for a programmable exhibit | 3 | 3 | |
| 37 | Millionaire | 1893 | the first direct multiplier: a "multiplication body" of tongues gives each product at once | complex, dense | 3 | 5 | |
| 38 | Scheutz difference engine | 1853 | the first working difference engine, with a printer | as Babbage's; one of them is enough | 3 | 5 | |
| 39 | Three-dimensional cams | 1930s | a cam shaped by two inputs gives a function of both (fire control's tables) | one shaped cam and a follower; prints well | 3 | 2 | |
| 40 | Petrol-pump price computer | 1930s | multiplies the litres pumped by the price per litre, continuously, with variable-ratio gearing | a variator and counters; small | 3 | 2 | 
| 41 | Linkage function generators (the Peaucellier–Lipkin inverter and others) | 1864 / 1900s | bar linkages that compute a product, a square, a log; Peaucellier's computes 1/x | a few hinged bars each; a set of them would make one bay | 3 | 2 | 
| 42 | Bead sort and spaghetti sort | modern | physical sorting: beads fall on rods, or rods are stood on end | beads and rods under gravity: easy | 3 | 1 | 
| 43 | Slide adder (troncet, Addiator) | 1889 / 1920 | slides moved with a stylus add and carry by a hook | flat slides; the carry hook is the trick | 3 | 2 | |
| 44 | Mechanical combination lock | | the wheels' notches must line up: a lock that tests a number | wheels and a fence; simple | 2 | 2 | 
| 45 | Napier's bones, Genaille–Lucas rulers | 1617 / 1891 | rods laid side by side give a product to read off | no moving mechanism: printable, nothing to simulate | 2 | 1 | |
| 46 | Slide rule | 1620s | multiplies by adding logarithms | one slide; nothing to simulate | 2 | 1 | |
| 47 | Abacus, suanpan | ancient | beads | nothing to simulate | 1 | 1 | |

## By kind

- **Adding and counting** (digital): Schickard, the Pascaline, Leibniz, the
  Arithmometer, the pinwheels, the Comptometer, the Millionaire, the Curta,
  the slide adder, the Totalisator, the petrol-pump computer.
- **Tabulating and programmed:** the Difference Engines (Babbage's, Scheutz's),
  Jacquard's reader, the Zuse Z1.
- **Logic and play:** the Digi-Comps, Dr. Nim, marble adders, the domino adder,
  the Galton board, the bead and spaghetti sorts.
- **Number theory, ciphers and locks:** Lehmer's sieve, the Enigma, the
  Hagelin M-209, the combination lock.
- **Calculus and waves** (analogue): the planimeter, the integraph, the
  ball-and-disk integrator, Kelvin's tide predictor and harmonic analyser,
  Michelson and Stratton's analyser, the Differential Analyser.
- **Algebra:** Kelvin's and Wilbur's equation solvers, Torres Quevedo's root
  finders, linkage function generators, three-dimensional cams, the
  "Basic Mechanisms" kit.
- **Aiming:** the Argo clock and Dreyer table, the rangekeeper, the Norden
  bombsight, the Torpedo Data Computer.
- **Astronomy:** the Antikythera mechanism.

## Left out, and why

- **Electromechanical and electronic:** Stibitz's Model K (relays), the bombes,
  the Harvard Mark I, Colossus, ENIAC and after, and the Mallock machine
  (electrical). The Enigma is kept because its stepping is mechanical and its
  wiring is a fixed lookup; the bombe is not, being relays and motors.
- **Water:** Lukyanov's water integrator and Phillips's MONIAC compute with
  flowing water, which Bullet does not do (rigid and soft bodies only).
- **Clocks and orreries:** a collection of their own.
- **Program stores that don't compute:** music boxes and Jacquard's looms
  (Jacquard's card reader is kept, as an input for another machine).
- **Hollerith's machines** (electrical counting) and **MEMS and nanomachines**
  (too small to print).

## How the hall uses this list

The hall's bays are walked in rising interest, so a new exhibit goes in its
place by its interest score. With eight bays, the hall holds the three built
and the five with bays (Lehmer's sieve now second, after the Differential); the Enigma would make a ninth (a fifth row of bays,
one spare).

**Rope.** bpp has no rope (its soft bodies are cloth). A rope of small
spheres joined by ball joints works, tested as an Atwood machine over a
5 cm pulley: with 60 beads making a 50 g rope between 200 g and 250 g
weights, it stretched under 0.3% and the weights accelerated at 95 to
103 cm/s^2 against the textbook 98, at 2400 steps a second and 100 solver
passes, about a second of computing per simulated second. A rope 2500 times
lighter per bead than its weights broke at any step size: the rope must not
be too much lighter than what hangs on it. That suits the tide predictor
(its pen weight can be light) and the equation solvers. The other way is to
add Bullet's own rope (`btSoftBodyHelpers::CreateRope`) to bpp, a C++
change. The best candidates for new bays, for interest against effort,
are the Galton board and the planimeter (quick and clear), and the Enigma and
the Antikythera mechanism (striking, and within reach).
