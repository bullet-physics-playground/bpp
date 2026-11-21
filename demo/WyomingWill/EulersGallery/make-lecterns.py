"""Euler's Gallery's lectern labels: the card on the lectern at the front of
an exhibit's bay, as PNGs in gallery-meshes/ (lectern-<key>.png, the key
the exhibit's placard label in gallery.lua; its other pages
lectern-<key>-2.png and so on). Run from this folder: python3
make-lecterns.py [key ...] (needs Pillow and the DejaVu fonts). The gallery
puts the card on a lectern when the file is there.

A museum label: the name, a line saying what and whose, and a few
sentences, dark on a cream card, 36 x 24 cm. Each page says which it is,
and all but the last "PgDn: more". In the gallery PgDn and PgUp turn
them, and I looks at the card close up. (The same cards as Babbage's
Hall's: its make-lecterns.py.)"""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = "gallery-meshes"
FONTS = "/usr/share/fonts/truetype/dejavu/"
W, H = 1440, 960                  # px: the card, 36 x 24 cm at 40 px a cm
INK, CARD, RULE = (43, 30, 20), (239, 230, 207), (150, 110, 50)

LABELS = {
    "gomboc-variety": [(
        "GÖMBÖC VARIETY",
        "Shapes that always get up",
        "Every body here is solid all through, the same density everywhere, "
        "yet put down any way it rolls over until it rests on one spot. Its "
        "shape alone does it. The white dot marks each one's balancing point, "
        "its only other place of rest.\n"
        "Each colour drops the next shape in a cycle. R drops them again; U "
        "stands them on their heads; K tosses them up; the count slider, how many.",
    ), (
        "ONE STABLE, ONE UNSTABLE",
        "The Gömböc problem",
        "A solid of one density, convex, with exactly one point it rests on "
        "and one it balances on. In 1995 Vladimir Arnold asked if one could "
        "exist; Gábor Domokos and Péter Várkonyi proved it could, "
        "in 2006, and made one.\n"
        "Here: theirs, M.~L.~Sloan's lumpy ones, printable ones, and two "
        "loaves that right themselves but balance in more than one way.",
    ), (
        "WHY THEY STOP SHORT",
        "Gentle slopes",
        "A Gömböc's resting valley and balancing peak differ in height "
        "by only millimetres, and the slopes between are gentle, so a little "
        "rolling resistance can hold one on its side. The lumpy ones often "
        "stop there.\n"
        "A table tilted a degree does the same; the tilt slider shows it, "
        "and the loaves shrug it off.",
    )],
    "bille": [(
        "BILLE AND THE POLYHEDRA",
        "Weighted so they land one way",
        "Each of these rests on only one of its faces: put down on any other, "
        "it tips over, face to face, until it lands there. Unlike the "
        "Gömböcs opposite, they work because of where their mass is. "
        "Red, yellow and orange are Billes; green, blue and purple are "
        "spiral polyhedra. Each lights up when it is home.\n"
        "R drops them again; U sets them down on a wrong face; K tosses "
        "them; Z, how slow.",
    ), (
        "BILLE",
        "A tetrahedron with one face to land on",
        "Almadi, Dawson and Domokos (2025) built a tetrahedron of carbon-fibre "
        "tubes with a tungsten-carbide weight placed so "
        "that its centre of mass sits in a tiny zone, 1.5 mm deep: from any "
        "face it tips on to face D. Its edges light as it rolls over them.\n"
        "This one is rebuilt from the paper's numbers; dropped 346 times, "
        "it always ended on face D.",
    ), (
        "THE SPIRAL POLYHEDRA",
        "Discrete Gömböcs",
        "An apex over rings of corners, equal weights at the corners: one "
        "stable face, the base, and one unstable corner. Domokos "
        "and Kovács (2023) showed 21 corners is the fewest for this "
        "design. Each band of faces tips onto the next.\n"
        "They are idealised: all the mass in the corners, which no real one "
        "could have. Each corner lights as it touches.",
    )],
    "galileo-ramp": [(
        "GALILEO'S RAMP",
        "A rolling race",
        "A wooden ball, a small steel ball, a wooden disc, a brass hoop and a "
        "can of soup are let go together down a ramp. Which wins?\n"
        "Not the heaviest, nor the biggest. Watch: the soup wins, the two "
        "balls tie, the disc follows and the hoop comes last.\n"
        "R lines them up again; Z, slow motion.",
    ), (
        "WHERE THE MASS IS",
        "Spinning up as well as speeding up",
        "A body rolling down a slope has to spin up as well as speed up. The "
        "more of its mass is out at its rim, the more of its energy goes into "
        "spinning: a hoop, all rim, spends half. Mass and size don't matter: "
        "a body with I~=~k·m·r² runs at g·sinθ~/~(1~+~k). "
        "For a ball k~=~2/5, a disc 1/2, a hoop nearly 1.\n"
        "The soup hardly turns inside its can: k~=~0.09.",
    ), (
        "GALILEO'S INCLINED PLANE",
        "Slowing a fall down to measure it",
        "A falling ball is too quick to time, so Galileo rolled balls down a "
        "long sloping board and timed them by weighing the water that ran "
        "from a tank while they rolled. In Two New Sciences (1638) he "
        "reported that the distance grows as the square of the time.\n"
        "Here the times at the line match the theory to a hundredth of a per cent.",
    )],
    "double-cone": [(
        "THE DOUBLE CONE",
        "A mechanical paradox",
        "Two cones joined base to base sit on rails that rise and spread "
        "apart like a V. Let go at the low, narrow end, the cone at the back "
        "rolls up to the high end: uphill, it seems.\n"
        "In the middle a plain cylinder rolls down the same rails, and at the "
        "front, on steeper rails, the same cone rolls down.\n"
        "R sets them going again; Z, slow motion.",
    ), (
        "IT GOES DOWNHILL",
        "Thinner where the rails are wider",
        "As the rails spread, they meet the cone nearer its points, where it "
        "is thinner, so it sinks between them faster than they rise. Its "
        "centre of mass goes down all the way: 1 cm here.\n"
        "It rolls up only if the rails rise more slowly than the cone thins "
        "between them: tanθ~<~tanφ·R/H. The back rails rise "
        "0.03 for each 1 along, under 0.058; the front ones 0.10, too steep.",
    ), (
        "THE LECTURE ROOM",
        "Natural philosophy as a show",
        "Eighteenth-century lecturers showed it to paying audiences, and "
        "instrument makers sold it as the “mechanical paradox”, with "
        "the air pump and the orrery. It teaches one thing well: a body moves "
        "so that its centre of mass goes down, however things look.\n"
        "Rest the mouse on a roller to see where its centre is, and where the "
        "geometry says it should be.",
    )],
    "oloid": [(
        "THE OLOID AND THE SPHERICON",
        "Rollers that aren't round",
        "Each is made of two circular arcs, and each rolls, laying its whole "
        "surface down as it goes, weaving from side to side. At the back, "
        "Paul Schatz's oloid (1929); in the middle, A.~T.~Stewart's "
        "two-circle roller (1966); at the front, the sphericon.\n"
        "R pushes them off again; Z, slow motion.",
    ), (
        "WATCH THE PENS",
        "A centre that rises, and two that don't",
        "The pen above each roller draws its centre's height, twenty times "
        "larger. The oloid's red line waves between its two rods, R/\u221a2 "
        "and 3R/4. The blue and green lines lie flat: those two rollers' "
        "centres never rise or fall, so on a level table either would stay "
        "where it was set down.\n"
        "On the board, a dotted track shows each one weave.",
    )],
    "eulers-disk": [(
        "EULER'S DISK",
        "Faster and faster, then flat",
        "A heavy steel disc set spinning on its edge on a mirror rolls round "
        "and round in place, leaning further over as it loses energy. The "
        "further it leans, the faster it goes round, until it suddenly stops, "
        "flat. A coin spun on a table does the same.\n"
        "Set going at 30 degrees, it rolls for about 80 seconds. R sets it "
        "going again; Z, slow motion.",
    ), (
        "A DEFINITE END",
        "Going round infinitely fast, in theory",
        "The lean α and the rate W it goes round are tied: for a thin "
        "disc W²~=~4g~/~(a·sinα). As it loses energy, α goes "
        "to nothing and W grows without limit, at a definite time.\n"
        "Here rolling resistance takes the energy, so α falls as the square "
        "of the time left and W rises as one over it. It stops at 0.3 degrees, "
        "going round 67 times a second.",
    ), (
        "WHAT STOPS IT?",
        "An argument since 2000",
        "Joseph Bendik made the toy in the 1990s. In 2000 Keith Moffatt "
        "proposed in Nature that the air squeezed under the disc takes its "
        "energy, which predicts a different curve to the same end. In 2002 "
        "Easwar, Rouyer and Menon spun discs in a vacuum and found the air "
        "plays only a small part.\n"
        "This exhibit follows the rolling-resistance answer; it can't tell "
        "the two apart.",
    )],
    "rattleback": [(
        "THE RATTLEBACKS",
        "A spin with a favourite way",
        "Spun one way, a rattleback just spins. Spun the other way, it slows, "
        "rocks end to end, stops and spins back. Tap one end while it lies "
        "still and it starts spinning its own way, all by itself.\n"
        "Left, spun the wrong way, turns round; middle, spun its own way, "
        "spins down; right, on a table that takes almost no energy, turns "
        "round again and again.\n"
        "R spins them again; T taps them; Z, slow motion.",
    ), (
        "THE SKEW",
        "Rocking and spinning, coupled",
        "Its mass is turned 8 degrees from the lines of its hull, as the two "
        "studs on top show. So rocking and spinning "
        "are tied together: spinning the wrong way feeds a rock, and the rock, "
        "pushing on the table through the skewed hull, turns the spin round.\n"
        "With no losses it would reverse both ways for ever; a real one "
        "reverses one way only, as the table takes a little energy.",
    ), (
        "STONES AND TOOLS",
        "Why it is also called a celt",
        "Archaeologists noticed that some smooth stone tools, celts, spin "
        "better one way than the other, hence the other name. Gilbert Walker "
        "gave the first account of the mathematics in 1896; it is still "
        "studied, because the motion is so sensitive to the shape.\n"
        "Rest the mouse on one to see its spin, its rocking, and how many "
        "times it has reversed.",
    )],
    "spinning-egg": [(
        "THE SPINNING EGGS",
        "Up on its end, and a jump",
        "Spun fast on its side, a hard-boiled egg rises onto its end and "
        "spins there like a top. Left: hard-boiled, 25 turns a second. "
        "Middle: hard-boiled, 40 turns a second; it jumps as it rises, and "
        "its lamp lights while it is off the table. Right: raw, and it stays "
        "on its side.\n"
        "R spins them again; S stops them with a finger; V, the views; Z, "
        "slow motion.",
    ), (
        "FRICTION LIFTS IT",
        "And a quantity that hardly changes",
        "The egg slides on the table as it spins, and the drag at the sliding "
        "point tips it up, raising its centre of mass. Moffatt and Shimomura "
        "(Nature, 2002) showed that Jellett's constant, its angular momentum "
        "dotted with the line from the table to its centre, stays almost the "
        "same as it rises: so its spin on its end follows from its spin "
        "on its side.",
    ), (
        "THE RAW EGG",
        "A test for the kitchen",
        "Spin a raw egg and only the shell turns at first; the liquid inside "
        "takes up the spin and slows it to about 5 turns a second, too slow "
        "to rise. Stop it with a finger for a moment and let go: it starts "
        "turning again by itself, because the liquid is still turning.\n"
        "A hard-boiled egg, stopped, stays stopped. That is how to tell "
        "them apart without breaking them.",
    )],
    "tippe-top": [(
        "THE TIPPE TOPS",
        "A top that turns itself over",
        "A ball with a stem, its weight a little below the ball's centre. "
        "Spin it on its ball, stem up, and within seconds it turns over and "
        "spins on its stem. Left, spun fast: it stands up on its stem, then "
        "sinks back. Middle, spun slowly: it gets only half way. Right, its "
        "weight at the centre: it never turns over.\n"
        "The needles above them point the way the stems point. R spins them "
        "again; Z, slow motion.",
    ), (
        "UPHILL, BY FRICTION",
        "Its centre of mass goes up",
        "Standing on its stem, the top's centre of mass is higher than where "
        "it began: the energy comes from its spin. The ball slides on the "
        "table as it spins, and the sliding friction tips it over.\n"
        "It can turn over only if its weight is off centre enough: here 0.3 "
        "of the radius, enough for its moments of inertia. The green top's, "
        "0.6 mm off centre, is not, and it just spins.",
    ), (
        "BOHR AND PAULI",
        "A toy that puzzled physicists",
        "Tops like this were patented in 1891, but became a craze in the "
        "1950s. A well-known photograph shows Niels Bohr and Wolfgang Pauli "
        "bent over a tippe top on the floor, watching it turn over.\n"
        "Its working out took decades: to stand on its stem it must slide, "
        "and it must keep enough spin to stay up, as the slow top shows.",
    )],
    "dzhanibekov": [(
        "THE DZHANIBEKOV EFFECT",
        "A spin that keeps turning over",
        "Three T-handles float without gravity, each spun a turn a second "
        "about a different axis, each with the same small wobble. Left, "
        "spun about its stem: it flips over and back every 3.3 seconds. "
        "Middle, about the bar, and right, across both: they spin steadily.\n"
        "R starts them again; Z, slow motion. The spin and nudge sliders "
        "change how they start.",
    ), (
        "THE MIDDLE AXIS",
        "The tennis racket theorem",
        "A body with three different moments of inertia spins steadily about "
        "the axes of its largest and its smallest, but not the middle one. "
        "Spun about that, the slightest wobble grows until it turns over, and "
        "the motion repeats for ever. Toss a racket or a phone spinning about "
        "its middle axis and watch it flip.\n"
        "Which axis is the middle one depends on the shape: with a longer "
        "stem, the bar flips instead.",
    ), (
        "SALYUT 7, 1985",
        "A wing nut in orbit",
        "The cosmonaut Vladimir Dzhanibekov unscrewed a wing nut that spun "
        "off on its own, and every few seconds flipped over, end for end, "
        "then back. On Earth gravity hides it; in orbit anyone could see it.\n"
        "Euler's equations for a spinning body (1765) held the answer: solved "
        "exactly, they give the time between flips, 3.31 seconds here.",
    )],
    "gyroscope": [(
        "THE GYROSCOPES",
        "Why doesn't it fall?",
        "The same toy gyroscope three times, spun to 100 turns a second. "
        "Left, on a pedestal, held by one end of its axle: it doesn't fall, "
        "it goes round. Middle, hung by a string: the same. Right, upright "
        "on a tightrope: it balances, and slides to and fro as the wire is "
        "tipped a degree each way; the gauge shows the tilt.\n"
        "R spins them up again; Z, slow motion.",
    ), (
        "GOING ROUND",
        "Precession",
        "Gravity tries to tip the axle down. With the rotor spinning, that "
        "twist doesn't tip it: it turns the spin's direction sideways, so "
        "the axle swings round instead, a turn every 2.45 seconds here. The "
        "slower the rotor, the faster it goes round and the lower it sags.\n"
        "After 37 seconds the pedestal one slides off; after a minute the "
        "tightrope one comes off the wire.",
    ), (
        "FROM TOY TO COMPASS",
        "Foucault, 1852",
        "Léon Foucault named the gyroscope: a spinning wheel that keeps "
        "its direction as the Earth turns under it, a way to see the Earth's "
        "rotation. Gyrocompasses, autopilots and the guidance of ships, "
        "aircraft and rockets grew from it.\n"
        "Rest the mouse on one to see its tilt and spin.",
    )],
    "bicycle-wheel": [(
        "THE BICYCLE WHEEL",
        "Turning a stool without touching the floor",
        "A figure on a swivel stool holds a spinning wheel, axle up; the "
        "stool is still. It turns the wheel over, and the stool starts to "
        "turn the other way; it turns the wheel back, and the stool stops. "
        "Pushed out at arm's length the stool slows; pulled in, it speeds up.\n"
        "F turns the wheel over, L holds it level, O pushes it out; A does it "
        "all by itself. R starts again.",
    ), (
        "ANGULAR MOMENTUM",
        "What turns, stays turned",
        "Nothing pushes against the floor, so the angular momentum about the "
        "stool's axis can't change. The wheel's pointed up and now points "
        "down, so the figure and stool must take up the difference: twice "
        "the wheel's. Held level, half as much.\n"
        "Pushed out, the same angular momentum is shared over more moment of "
        "inertia, so the stool turns slower: a skater's arms.",
    ), (
        "NO GRAVITY NEEDED",
        "Unlike the gyroscopes",
        "Gravity plays no part here and nothing precesses: angular momentum "
        "is shared out between two bodies, the wheel and the rest. The wheel "
        "is 44 cm across, 3 kg, spun at 4 turns a second.\n"
        "A favourite of physics lecture rooms; after each move the console "
        "prints how fast the stool turns, and how fast it should.",
    )],
    "newtons-cradle": [(
        "NEWTON'S CRADLE",
        "One in, one out",
        "Five steel balls hang in a row, just touching. Lift one and let it "
        "go: it strikes the row and stops, and the ball at the far end flies "
        "out. Lift two, and two fly out; three, and three.\n"
        "1, 2, 3 or 4 lifts that many; G opens a hair's gap between the "
        "balls; A does one, two, then three by itself. Z, slow motion.",
    ), (
        "MOMENTUM AND ENERGY",
        "And why it isn't quite exact",
        "A strike keeps both momentum and energy, nearly; with identical "
        "balls that means as many leave as arrived, at the speed they came.\n"
        "But touching balls pass the push along as a pulse, and by Hertz's "
        "law the push grows as the 3/2 power of the squeeze. So the others "
        "keep a little motion, and in a few minutes the row swings together. "
        "With a gap (G), it is one in, one out.",
    ), (
        "THE LAWS OF COLLISION",
        "The Royal Society, 1668",
        "Wren, Wallis and Huygens each sent the Royal Society rules for "
        "bodies that collide; Mariotte tested them with balls hung on "
        "threads. Newton described such tests in the Principia (1687).\n"
        "The desk toy and its name came much later, in 1967. Here two balls "
        "touch for 84 millionths of a second, as Hertz's formula says.",
    )],
    "huygens-clocks": [(
        "HUYGENS' CLOCKS",
        "An odd kind of sympathy",
        "Two pendulum clocks hang from one beam, on rollers held by a "
        "spring. They start out of step, yet within a minute they swing in "
        "exact opposition, and the beam stops. Every four minutes they are "
        "started out of step again, and fall back into opposition.\n"
        "R starts them again; the speed slider (up to 4×) shows it faster.",
    ), (
        "FEBRUARY 1665",
        "Ill in bed, Huygens watched",
        "Christiaan Huygens, who had invented the pendulum clock, watched two "
        "of them hanging from a beam laid across two chairs. Their pendulums "
        "swung in exact opposition, and if he disturbed one, within half an "
        "hour they were in opposition again. He called it “an odd kind of "
        "sympathy”.\n"
        "He wanted clocks to find longitude at sea; this was a by-product.",
    ), (
        "WHY OPPOSITION",
        "The beam takes the energy of the rest",
        "Swinging together, the pendulums push the beam to and fro, and its "
        "friction takes their energy. Swinging in opposition, their pushes "
        "cancel, the beam stays still, and nothing is lost. Each clock's "
        "escapement keeps its own swing going, so what is left is the "
        "opposed swing.\n"
        "Bennett, Schatz, Rockwood and Wiesenfeld rebuilt the experiment in "
        "2002 (Proc. R. Soc. A).",
    )],
    "kapitza": [(
        "KAPITZA'S PENDULUM",
        "Upside down, and staying there",
        "A pendulum stands upside down on its pivot, and doesn't fall. The "
        "pivot is shaken up and down, a centimetre, forty times a second. "
        "Pushed over, the left one swings back up and rocks slowly about "
        "the upright, as if gravity pointed up. The right one, shaken only "
        "0.6 cm, falls and hangs.\n"
        "Every 15 seconds they're stood up again. R does it now; Z, slow motion.",
    ), (
        "WHY IT STAYS UP",
        "A push, averaged over each shake",
        "Shaken fast, the pendulum quivers a little with each shake. When it "
        "leans, the pivot's push and the quiver line up so that, averaged "
        "over a shake, they push it back toward upright. Shaken hard enough, "
        "that beats gravity.\n"
        "For a pivot shaken a·cosωt, upright is steady when "
        "a²ω²~>~2gl. The left one passes; the right one doesn't.",
    ), (
        "STEPHENSON AND KAPITZA",
        "Seen in 1908, explained in 1951",
        "Aurel Stephenson found that a shaken pivot could hold a pendulum "
        "upright in 1908. Pyotr Kapitza, the Nobel prize winner in low "
        "temperature physics, explained it in 1951 by averaging over the "
        "fast shaking: a way of thinking now used for particles held in "
        "traps of shaking electric fields.\n"
        "The sliders set each pivot's shaking.",
    )],
    "double-pendulum": [(
        "THE DOUBLE PENDULUM",
        "Simple to build, hard to foretell",
        "A pendulum hung from the bottom of another. Left: seven let go "
        "together, each a billionth of a radian further round. For five "
        "seconds they swing as one, then fly apart. Middle: its two pure "
        "swings, and a mix of them that never repeats. Right: upside down on "
        "pivots shaken 40 times a second.\n"
        "Every 30 seconds they're let go again. R does it now; Z, slow motion.",
    ), (
        "THE BUTTERFLY",
        "Chaos, from a billionth of a radian",
        "The double pendulum is chaotic: two swings that start close part, "
        "on average, exponentially fast. Here the gap doubles about every "
        "fifth of a second, so a billionth of a radian is everything in "
        "about thirty doublings.\n"
        "Nothing is random: the same start gives the same swing. But no "
        "start is known to an atom's width, so it can't be foretold.",
    ), (
        "TWO SWINGS, AND A CHAIN UPRIGHT",
        "Normal modes, and Kapitza's trick",
        "For small swings it has two normal modes: the rods together, the "
        "lower swinging √2 times as far; or opposed, 2.4 times as often. "
        "Every small motion is a sum of the two.\n"
        "Shaken fast, a chain of pendulums can stand upside down too, as "
        "David Acheson showed in 1993, but only in a window: too gently and "
        "it falls, too hard and the shaking pumps up a sway that throws it off.",
    )],
    "pendulums-twist": [(
        "PENDULUMS WITH A TWIST",
        "Three that don't do what you'd guess",
        "Left: nine double pendulums let go from 60 to 120 degrees. Can the "
        "lower rod swing right over the top? Middle: swinging Atwood "
        "machines, a heavy weight on one side of a cord and a swinging light "
        "one on the other. Right: weights on springs, set bouncing.\n"
        "Every 60 seconds they're let go again. R does it now; Z, slow motion.",
    ), (
        "OVER THE TOP, AND A HIDDEN CONSTANT",
        "Energy draws one line; chaos the rest",
        "Energy forbids the flip below 70.5 degrees, where 3·cosθ is "
        "over 1. Above, it is allowed, but not promised.\n"
        "The Atwood machines have the heavy weight 2.8, 3 and 3.2 times the "
        "light one. Only at exactly 3 is there a second conserved quantity "
        "(Casasayas, Nunes and Tufillaro, 1990): only there can it never be "
        "chaotic, and only its dial's needle stays still.",
    ), (
        "THE SWINGING SPRING",
        "A bounce that turns into a swing",
        "A weight bouncing on a spring, with the merest swing. On the left "
        "the bounce is tuned to exactly twice the swing's frequency: the "
        "bounce drains into a swing that grows to 11 degrees, then turns "
        "back into a bounce, and again. On the right, tuned 2.4 times, it "
        "just bounces.\n"
        "Two motions whose frequencies are in a simple ratio trade energy; "
        "it is called resonance.",
    )],
    "chain-fountain": [(
        "THE CHAIN FOUNTAIN",
        "A chain that leaps out of its jar",
        "Pull the end of a long bead chain out of a jar and let it fall to "
        "the floor, and the chain pours out on its own. It doesn't just slide "
        "over the rim: it leaps up in an arch above the jar on its way down, "
        "here 10 to 16 cm high. The jar of 9.75 m of chain is empty in "
        "2.25 seconds.\n"
        "It starts at an eighth of real speed; Z, real speed. R starts again.",
    ), (
        "THE PILE PUSHES BACK",
        "Short, stiff links",
        "A chain's links are short stiff rods, and it can only bend so far "
        "between them. A link picked up off the pile is lifted by one end, "
        "so it turns about its middle and pushes its other end down into the "
        "pile. The pile pushes back, and that push, on top of the pull of "
        "the falling chain, throws the chain up above the jar.\n"
        "H shows the coil of coarser chain the exhibit had before.",
    ), (
        "THE MOULD EFFECT",
        "Filmed in 2013, explained in 2014",
        "Steve Mould filmed a bead chain leaping out of a beaker in 2013, "
        "and the video went round the world. John Biggins and Mark Warner "
        "explained it the next year (Proc. R. Soc. A, 2014): the fountain's "
        "height grows with the drop to the floor.\n"
        "This chain is the kind they used: 4.5 mm balls 6.5 mm apart, its "
        "joints bending at most 30 degrees.",
    )],
    "slinky": [(
        "THE FALLING SLINKY",
        "A bottom that waits",
        "A Slinky hangs from a hand, and beside its bottom a ball hangs from a "
        "thread. Both are let go at once. The ball falls; the Slinky's bottom "
        "hangs still in mid-air while the top comes down, coil after coil, "
        "and moves only when the collapse reaches it.\n"
        "Beside it the same Slinky walks down seven stairs. R hangs it up "
        "again; W sets the walker going; V, the views; Z, real speed.",
    ), (
        "NEWS TRAVELS DOWN",
        "The collapse is the message",
        "The bottom is held up by the stretch of the coils just above it, and "
        "that can't change until news of the release gets there: the news "
        "travels down as the collapse itself. Meanwhile its centre of mass "
        "falls exactly as the ball does; the top falls faster to make up.\n"
        "The bottom waits √(M/3k), with no g in it: on the Moon it would "
        "wait just as long. Here 0.2 seconds.",
    ), (
        "A SPRING FOR A TOY",
        "Richard James, 1943",
        "Richard James, a naval engineer, saw a spring tumble off a shelf and "
        "keep moving, and made a toy of it; it went on sale in 1945. This is "
        "the original metal one: 215 g, 86 coils 7 cm across.\n"
        "On the stairs, half of it pours over into an arch, and it turns end "
        "over end, each end landing one step lower than the other did.",
    )],
    "brazil-nut": [(
        "THE BRAZIL-NUT EFFECT",
        "The biggest come to the top",
        "Shake a jar of mixed nuts and the Brazil nuts come up, though they "
        "are the heaviest. Two boxes of glass beads, one bead thick, are "
        "shaken five times a second, a big bead at the bottom of each. Left, "
        "rough walls: the big bead comes up within seconds. Right, smooth "
        "glass: it stays down.\n"
        "The layers' colours and the red bead's trail show the flow. R pours "
        "them again; Z, real time.",
    ), (
        "TWO ROLLS",
        "The walls decide",
        "Shaken hard, the bed leaves the floor for part of each shake. Beads "
        "beside a rough wall are held back by it, so they come down along "
        "the walls and the bed comes up the middle, in two rolls that carry "
        "the big bead up. At the top the small beads go down again in the "
        "narrow stream by the walls; the big one is too big to follow.\n"
        "Beside smooth glass the rolls run the other way.",
    ), (
        "IN THE LABORATORY",
        "Knight, Jaeger and Nagel, 1993",
        "Knight, Jaeger and Nagel showed in 1993 that the rolls carry the big "
        "grain up (Phys. Rev. Lett.). Laboratories roughen their walls, with "
        "sandpaper or glued grains, because beside smooth walls the flow "
        "isn't reproducible.\n"
        "A shallower bed of bouncy glass can do the opposite and keep a "
        "heavy bead down: the reverse Brazil-nut effect.",
    )],
    "solar-system": [(
        "THE SOLAR SYSTEM",
        "Moved by gravity, from 2026 January 1",
        "The Sun, the planets, Pluto, twenty-one moons, the rings and the "
        "asteroid belt's largest, moved by gravity from where JPL had them on "
        "the first day of 2026. It opens in the dark, the bodies lighting up "
        "as the Sun's light reaches them. Every body turns as it really does.\n"
        "1 to 5: a quarter of a day to 100 days a second. R, the start "
        "again; L, the opening; M, the music.",
    ), (
        "NEWTON, AND A LITTLE EINSTEIN",
        "Checked against JPL",
        "Every body pulls every other, as Newton says, and Einstein adds a "
        "small correction to the Sun's pull. Without it Mercury would fall "
        "behind, 1800 km in ten years. Its orbit's closest point turns 43 "
        "seconds of arc a century more than Newton allows, as Einstein "
        "explained in 1915.\n"
        "Distances from the Sun are square-rooted so that everything fits.",
    ), (
        "WHAT TO LOOK FOR",
        "Rest the mouse on a body",
        "The Moon keeps one face to us; Venus turns slowly backwards; Uranus "
        "lies on its side; Mercury turns three times in two of its years. "
        "Io, Europa and Ganymede keep in step, Laplace's resonance.\n"
        "The music is Holst's The Planets, Holst conducting the London "
        "Symphony Orchestra in 1922–23.",
    )],
}

def wrap(draw, text, font, width):
    lines = []
    for para in text.split("\n"):
        line = ""
        for word in para.split(" "):          # ("~" keeps words together: a space that doesn't break)
            word = word.replace("~", " ")
            t = (line + " " + word).strip(" ")
            if draw.textlength(t, font=font) <= width: line = t
            else: lines.append(line); line = word
        lines.append(line)
        lines.append(None)            # (a paragraph's end: a little space)
    return lines[:-1]


def card(key, title, sub, body, page=1, pages=1):
    im = Image.new("RGB", (W, H), CARD)
    d = ImageDraw.Draw(im)
    d.rectangle([24, 24, W - 25, H - 25], outline=RULE, width=6)
    d.rectangle([40, 40, W - 41, H - 41], outline=RULE, width=2)
    def fit(face, size, text):          # (the largest size up to this that fits across)
        while True:
            f = ImageFont.truetype(FONTS + face, size)
            if d.textlength(text, font=f) <= W - 160 or size <= 24: return f
            size -= 2
    fT = fit("DejaVuSerif-Bold.ttf", 96, title)
    fS = fit("DejaVuSerif-Italic.ttf", 56, sub)
    fB = ImageFont.truetype(FONTS + "DejaVuSerif.ttf", 46)
    m = 100
    y = 80
    d.text((W / 2, y), title, font=fT, fill=INK, anchor="ma"); y += 120
    d.text((W / 2, y), sub, font=fS, fill=INK, anchor="ma"); y += 90
    d.line([(W / 2 - 220, y), (W / 2 + 220, y)], fill=RULE, width=4); y += 40
    for line in wrap(d, body, fB, W - 2 * m):
        if line is None: y += 24; continue
        d.text((m, y), line, font=fB, fill=INK); y += 60
    if pages > 1:                       # (which page, and that there are more)
        fP = ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", 34)
        d.text((W - 70, H - 62), f"{page} / {pages}", font=fP, fill=RULE, anchor="rs")
        if page < pages: d.text((70, H - 62), "PgDn: more", font=fP, fill=RULE, anchor="ls")
        y += 20
    if y > H - 60: print(f"  {key}: the text runs off the card (to y {y}): shorten it")
    path = f"{OUT}/lectern-{key}.png" if page == 1 else f"{OUT}/lectern-{key}-{page}.png"
    im.save(path)
    print("wrote", path)


for key in (sys.argv[1:] or LABELS):
    L = LABELS[key]
    pages = L if isinstance(L, list) else [L]
    for n, p in enumerate(pages, 1):
        card(key, *p, page=n, pages=len(pages))
