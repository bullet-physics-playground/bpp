# Machines for Babbage's Hall

`MACHINES.pdf` beside this file is a typeset copy of it.

Every non-electronic computing machine worth considering for the hall, from
the list we began with, the three papers (*Early Computing Machines*,
*Computing after Babbage*, *Ball-and-disk integrator*) and the rest of the
field. Clocks are left out (they are a collection of their own), and so are
machines that compute with relays, valves or flowing water (see the end).

Each is scored from 1 to 5 for **interest** (how much there is to see and
understand: surprise, motion, history) and for **complexity** (how hard to
simulate in bpp and to print and build). The list ranks them by interest as
I judge it, the most interesting first; the scores group them, and the
order within a score is the judgement. The hall's bays follow the same
order, walked the other way: the least interesting at the entrance, the
Difference Engine at the far end.

**Status:** *built*: in the hall, with its STL files; *bay*: has a covered bay
"in preparation"; blank: not yet planned.

## The ranked list

| # | Machine | Year | What it does | In bpp, and printed | Int. | Cx. | Status |
|---|---|---|---|---|---|---|---|
| 1 | Babbage's Difference Engine | 1822 / 1849 | tabulates a polynomial by adding its differences, with no multiplying | two orders of difference, three digits, is a good model: figure wheels and Babbage's carry, after the Pascaline | 5 | 5 | bay |
| 2 | Antikythera mechanism | c. 100 BCE | a gear train for the Sun, Moon and planets, the lunar phase, eclipse dials; a pin-and-slot gear for the Moon's varying speed | gears, as in the Differential (convex-hull teeth), and many of them; printed replicas exist | 5 | 4 | |
| 3 | Enigma (its rotors' stepping) | 1923 | a keypress steps the rotors by pawls and notches; the current's path through them lights the cipher letter | the stepping is mechanical (the middle rotor's double step comes of itself); the wiring is a lookup in Lua; prints, with wire, contacts and LEDs | 5 | 3 | |
| 4 | Differential Analyser | 1931 | wheel-and-disc integrators, wired in a loop, solve differential equations and draw the answer | rolling contact that must not slip; Bush's torque amplifiers can be motors; Hartree built one in Meccano | 5 | 4 | bay |
| 5 | Zuse Z1 | 1938 | the first freely programmable computer, binary floating point, all mechanical: sliding steel plates and pins | its plate logic is lovely to simulate gate by gate; the whole machine is far beyond us | 5 | 5 | |
| 6 | Norden bombsight | 1930s | a gyro-steadied sight whose analogue computer (rate discs, cams) solves the bombing problem | the computing (disc integrators and cams) is doable; the gyro too, as in Euler's Gallery; whole, very complex | 5 | 5 | |
| 7 | Ford Rangekeeper Mk I | 1917 | a battleship's fire-control computer: integrators, differentials and cams solve where the target will be | its parts each are doable (the Differential, integrators, cams); together, a big job | 5 | 5 | |
| 8 | Curta | 1948 | a pocket four-function calculator: one stepped drum, nines' complements for subtraction | small and dense: the stepped drum and carry are doable, the whole machine very hard; best as an oversized cutaway | 5 | 4 | |
| 9 | Kelvin's tide predictor | 1872 | adds ten or more sine waves (the Sun's and Moon's tides) and draws a year of tides | cranks and slotted yokes are easy; the cord over the pulleys that adds them is the hard part (a chain of links, or a computed cord) | 5 | 3 | bay |
| 10 | Digi-Comp II | 1968 | marbles rolling down a board of flip-flops count, add and multiply in binary | marbles and levers: contact only, like the dominoes; tuning the flip-flops is the work | 5 | 3 | bay |
| 11 | Domino Half Adder | modern | dominoes falling add two bits | built: 268 dominoes on printed tiles | 4 | 2 | built |
| 12 | Pascaline | 1642 | adds, with Pascal's falling-weight carry | built: three digits, sautoirs, detents, stylus and stop | 4 | 3 | built |
| 13 | Galton board | 1873 | balls falling through pins pile up into the normal curve | balls and pins only; easy, and a good opener | 4 | 1 | |
| 14 | Planimeter (Amsler's polar) | 1856 | trace a shape's outline and a rolling wheel reads its area | one wheel rolling and slipping on paper; small and clear | 4 | 2 | |
| 15 | Ball-and-disk integrator | 1876 | James Thomson's: a ball between a turning disc and a cylinder; the cylinder turns as the integral | the ball must roll without slipping; the integrator the tide predictor's brother and the analyser's ancestor | 4 | 2 | |
| 16 | Integraph | 1880s | follows a curve and draws its integral | a wheel steering by its knife edge; a small step on from the planimeter | 4 | 3 | |
| 17 | Kelvin's harmonic analyser | 1878 | integrators find the Fourier coefficients of a measured curve (the tide predictor in reverse) | ball-and-disk integrators in a row | 4 | 3 | |
| 18 | Thomas Arithmometer | 1820 | the first mass-produced calculator: stepped drums, a sliding carriage | a stepped drum per digit and a carry; a fine follow-on to the Pascaline | 4 | 3 | |
| 19 | Leibniz's stepped reckoner | 1694 | the first four-function calculator: the stepped drum | the stepped drum is the heart of the next three machines | 4 | 3 | |
| 20 | Odhner pinwheel calculator (Brunsviga, Facit) | 1873 | pinwheels with retractable pins set the figures; turn the crank | flat pinwheels print well; the carry is the work | 4 | 3 | |
| 21 | Automatic Totalisator | 1913 | racetrack betting: a great shaft adder of differentials counts tickets and sets the odds | differentials (built) chained; the first real-time computer, the Science Museum says | 4 | 3 | |
| 22 | Torres Quevedo's algebraic machines | 1890s | find the roots of polynomials with his "endless spindle" logarithmic gearing | special gearing; little known and striking | 4 | 4 | |
| 23 | Kelvin's equation solver (and Wilbur's) | 1878 / 1936 | tilting plates on pulleys and cords solve simultaneous linear equations | plates, pulleys, cords: the cords are the hard part | 4 | 3 | |
| 24 | Michelson and Stratton's harmonic analyser | 1898 | 80 springs sum and analyse waves; it showed the Gibbs overshoot | springs and levers: Bullet springs, many of them | 4 | 3 | |
| 25 | Comptometer | 1887 | key-driven adder: press a key and the column moves at once | keys, sectors and carry; no crank | 4 | 3 | |
| 26 | Digi-Comp I | 1963 | plastic sliders and pegs: three flip-flops and programmable logic | slides, pegs and a lever: simple parts, many of them | 4 | 2 | |
| 27 | Dr. Nim | 1965 | a marble machine that plays Nim, and wins | a few flip-flops and marbles: a little cousin of the Digi-Comp II | 4 | 2 | |
| 28 | Marble adders (Turing Tumble, Wandel's) | modern | marbles flip levers to add binary numbers | contact and gravity; very like the Digi-Comp II | 4 | 2 | |
| 29 | Torpedo Data Computer | 1940s | a submarine's analogue fire control | like the rangekeeper, smaller; partly electrical | 4 | 5 | |
| 30 | The Differential | 1827 | gears that add and subtract (Pecqueur's patent; older in clocks) | built: printed bevel gears | 3 | 2 | built |
| 31 | Lehmer's number sieve | 1926 / 1932 | factors numbers: loops of different lengths (bicycle chains, later toothed wheels) turn until gaps line up | simple shafts and wheels; the 1932 wheel version is easier than chains | 3 | 2 | bay |
| 32 | Schickard's calculating clock | 1623 | the first known calculator: adding wheels and Napier's bones | a one-tooth carry gear (it jams on long carries: worth showing beside the Pascaline) | 3 | 3 | |
| 33 | Jacquard's card reader | 1804 | punched cards choose which hooks lift: the first stored program | needles, cards and hooks; a reader for a programmable exhibit | 3 | 3 | |
| 34 | Millionaire | 1893 | the first direct multiplier: a "multiplication body" of tongues gives each product at once | complex, dense | 3 | 5 | |
| 35 | Scheutz difference engine | 1853 | the first working difference engine, with a printer | as Babbage's; one of them is enough | 3 | 5 | |
| 36 | Three-dimensional cams | 1930s | a cam shaped by two inputs gives a function of both (fire control's tables) | one shaped cam and a follower; prints well | 3 | 2 | |
| 37 | Linkage function generators | 1900s | bar linkages that compute a product, a square, a log | a few hinged bars each; a set of them would make one bay | 3 | 2 | |
| 38 | Slide adder (troncet, Addiator) | 1889 / 1920 | slides moved with a stylus add and carry by a hook | flat slides; the carry hook is the trick | 3 | 2 | |
| 39 | Napier's bones, Genaille–Lucas rulers | 1617 / 1891 | rods laid side by side give a product to read off | no moving mechanism: printable, nothing to simulate | 2 | 1 | |
| 40 | Slide rule | 1620s | multiplies by adding logarithms | one slide; nothing to simulate | 2 | 1 | |
| 41 | Abacus, suanpan | ancient | beads | nothing to simulate | 1 | 1 | |

## By kind

- **Adding and counting** (digital): Schickard, the Pascaline, Leibniz, the
  Arithmometer, the pinwheels, the Comptometer, the Millionaire, the Curta,
  the slide adder, the Totalisator.
- **Tabulating and programmed:** the Difference Engines (Babbage's, Scheutz's),
  Jacquard's reader, the Zuse Z1.
- **Logic and play:** the Digi-Comps, Dr. Nim, marble adders, the domino adder,
  the Galton board.
- **Number theory and ciphers:** Lehmer's sieve, the Enigma.
- **Calculus and waves** (analogue): the planimeter, the integraph, the
  ball-and-disk integrator, Kelvin's tide predictor and harmonic analyser,
  Michelson and Stratton's analyser, the Differential Analyser.
- **Algebra:** Kelvin's and Wilbur's equation solvers, Torres Quevedo's root
  finders, linkage function generators, three-dimensional cams.
- **Aiming:** the rangekeeper, the Norden bombsight, the Torpedo Data Computer.
- **Astronomy:** the Antikythera mechanism.

## Left out, and why

- **Electromechanical and electronic:** Stibitz's Model K (relays), the bombes,
  the Harvard Mark I, Colossus, ENIAC and after, and the Mallock machine
  (electrical). The Enigma is kept because its stepping is mechanical and its
  wiring is a fixed lookup; the bombe is not, being relays and motors.
- **Water:** Lukyanov's water integrator and Phillips's MONIAC compute with
  flowing water, which Bullet does not do (rigid and soft bodies only).
- **Clocks and orreries:** a collection of their own.

## How the hall uses this list

The hall's bays are walked in rising interest, so a new exhibit goes in its
place by its interest score. With eight bays, the hall holds the three built
and the five with bays; the Enigma would make a ninth (a fifth row of bays,
one spare). The best candidates for new bays, for interest against effort,
are the Galton board and the planimeter (quick and clear), and the Enigma and
the Antikythera mechanism (striking, and within reach).
