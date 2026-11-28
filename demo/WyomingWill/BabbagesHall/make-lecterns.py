"""Babbage's Hall's lectern labels: the card on the lectern in front of an
exhibit, as a PNG in hall-meshes/ (lectern-<key>.png, the key its placard's).
Run from this folder: python3 make-lecterns.py [key ...] (needs Pillow and
the DejaVu fonts). The hall puts the card on a lectern before the exhibit's
table when the file is there.

A museum label: the name, a line saying what and whose, and a few
sentences, dark on a cream card, 36 x 24 cm.

A label can have pages: a list of cards instead of one. The first is
lectern-<key>.png, the next lectern-<key>-2.png and so on; each says which
page it is, and all but the last "PgDn: more". In the hall PgDn and PgUp
turn them. An exhibit with ways of its own (hall.lua's modes) has a label
for each way, named in its mode's card."""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = "hall-meshes"
FONTS = "/usr/share/fonts/truetype/dejavu/"
W, H = 1440, 960                  # px: the card, 36 x 24 cm at 40 px a cm
# (the card's paper is darker than it looks: the hall's light at full
# strength, at an exhibit, takes it to about (245, 234, 208), a cream;
# (239, 230, 207) went near white)
INK, CARD, RULE = (43, 30, 20), (181, 173, 154), (150, 110, 50)

# (the splitter board's last page, whichever way it is shown)
READING = (
    "FURTHER READING",
    "Fair coins and random walks",
    "William Feller, An Introduction to Probability Theory and Its "
    "Applications, vol.~1 (1968): chapters III and XIV.\n"
    "Charles Grinstead and J.~Laurie Snell, Introduction to Probability "
    "(1997), chapter 12. Free online.\n"
    "Remco van der Hofstad and Michael Keane, An elementary proof of the "
    "hitting time theorem, Amer. Math. Monthly 115 (2008).",
)

# (the suanpan's last page, taking away and multiplying)
ABACUS_READING = (
    "FURTHER READING",
    "Learning the abacus",
    "Takashi Kojima, The Japanese Abacus: Its Use and Theory (1954). Its "
    "soroban has fewer beads, but the same rules.\n"
    "Takashi Kojima, Advanced Abacus (1963): older ways to multiply and "
    "divide.\n"
    "Totton Heffelfinger and Gary Flom, Abacus: Mystery of the Bead (online).",
)

LABELS = {
    "suanpan": [(                    # (Matsuzaki and Wood: Kojima, The Japanese Abacus, 1954; Computer History Museum)
        "THE SUANPAN",
        "The Chinese abacus",
        "Each rod holds a digit, the units on the right. A heaven bead above "
        "the beam counts five and an earth bead below it counts one, when "
        "pushed to the beam.\n"
        "Type a number and press Return: the finger adds it rod by rod from "
        "the left, as it is done by hand, and the slate shows each rule it uses. "
        "Tab: taking away, then multiplying.",
    ), (
        "THE RULES",
        "Fives and tens",
        "Nobody works out 7~+~8 on an abacus. A pupil learned three moves by "
        "heart. If there is room, beads to the beam. If not, use five: "
        "+3~=~5~\u2212~2, the heaven bead down and two earth beads away. Past "
        "nine, use ten: +8~=~10~\u2212~2, two away and carry one to the rod on "
        "the left.\n"
        "The hand never needs more than that.",
    ), (
        "BEADS AGAINST A MACHINE",
        "From China to Japan, and Tokyo, 1946",
        "The bead abacus was in wide use in China by the 1300s. It reached "
        "Japan in the late 1500s and became the soroban, one heaven bead and "
        "four earth beads to a rod.\n"
        "On 12~November 1946 in Tokyo, Kiyoshi Matsuzaki with a soroban raced "
        "Private Thomas Nathan Wood with an electric calculator. The abacus "
        "won four rounds of five, losing only at multiplication.",
    )],
    "suanpan-subtract": [(
        "TAKING AWAY",
        "The suanpan's second way",
        "Type a number and press Return: the finger takes it away, rod by rod "
        "from the left. A adds a number instead, to have something to take "
        "away from.\n"
        "The tour sets 2000 and takes away 1. There is nothing on the units rod, "
        "so one is borrowed from the thousands, through the hundreds and the "
        "tens: 2000~\u2212~1~=~1999.",
    ), (
        "THE RULES, BACKWARD",
        "Fives and tens again",
        "If there are beads enough, take them away. If not, use five: "
        "\u22123~=~\u22125~+~2, the heaven bead up and two earth beads up. If the "
        "rod hasn't enough, use ten: \u22128~=~\u221210~+~2. Take one from the rod "
        "on the left first, then put two earth beads up.\n"
        "Each is an adding rule run backward, so the hand learns them in pairs.",
    ), ABACUS_READING],
    "suanpan-multiply": [(
        "MULTIPLYING",
        "The suanpan's third way",
        "Type 36, X, 4 and press Return. The multiplier, 4, goes on the rods "
        "at the left and the multiplicand, 36, to its right. 6~\u00d7~4~=~24 is "
        "added on the two rods right of the 6, and the 6 cleared; then "
        "3~\u00d7~4~=~12 on the two right of the 3, and the 3 cleared. 144 is left.\n"
        "Seven rods hold up to 99~\u00d7~99, or 9999~\u00d7~9.",
    ), (
        "TWO DIGITS, ALWAYS",
        "Where each product goes",
        "Each product from the times table is said as two digits: 3~\u00d7~2 is "
        "06. Its tens go one rod right of the multiplicand's digit for the "
        "multiplier's first digit, two rods right for its second, and so on. "
        "Said that way, nothing goes on the wrong rod.\n"
        "The products are added by the rules for adding; the slate shows each. "
        "Rods are named A to G from the left.",
    ), ABACUS_READING],
    "lock": [(                       # (the wheel pack and the 4-3-2 rules: Wikipedia, Rotary combination lock; Blaze 2004)
        "THE COMBINATION LOCK",
        "A lock that tests a number",
        "Three wheels turn loose behind the dial, each with a notch in its "
        "rim, its gate. A pin through each wheel carries the next round after "
        "nearly a turn, so the dialling rules set one wheel at a time. Only when "
        "every gate is under the fence can it fall in, and the bolt be drawn.\n"
        "Type 31 72 46 and press Return. G looks down at the gates.",
    ), (
        "LEFT, RIGHT, LEFT",
        "Four turns, three, then two",
        "Left four times to the first number: by then the cam has picked up all "
        "three wheels, and wheel 1, at the back, is left there. Right three times "
        "to the second: wheel 1 stays, wheel 2 is set. Left twice to the third: "
        "wheel 3. Then right, until the cam's notch catches the fallen fence and "
        "pulls the bolt.",
    ), (
        "NOT A MILLION",
        "What the fence lets through",
        "A gate need only be within a number or so of the fence: 27 of the "
        "million combinations open this lock, so a thief has about 37,000 to "
        "try. Matt Blaze put a real safe lock's at 22,000 to 111,000.\n"
        "Nor can every number be used: a last number from 90 to 99 is in the "
        "forbidden zone, where the cam carries wheel 3 off before it draws the bolt.",
    ), (
        "FURTHER READING",
        "Dial locks and their weaknesses",
        "Linus Yale Jr.'s Monitor Bank Lock (1862) began the banks' change from "
        "keys to dials; James Sargent showed the early dial locks could be "
        "picked, and in 1873 added the time lock.\n"
        "Matt Blaze, Safecracking for the Computer Scientist (2004). Free online.\n"
        "Richard Feynman, Surely You're Joking, Mr. Feynman! (1985): Safecracker "
        "Meets Safecracker.",
    )],
    "lock-safecracker": [(          # (manipulation: Blaze 2004; UL 768 Group 1 and S&G's 20 man-hours; US patent 4,901,546 on false gates)
        "THE SAFECRACKER'S WAY",
        "Reading a lock without its combination",
        "No two wheels are quite alike, and the fence rests on the largest. "
        "Rocked gently, the dial stops where the fence meets the cam's notch: "
        "the contact points. When a gate of the wheel holding the fence up comes "
        "under it, the fence drops a hair onto the next wheel, and the contact "
        "points close in.\n"
        "Press T and watch the graph on the slate.",
    ), (
        "LISTEN, AND READ THE DIAL",
        "A click says when; the dial says where",
        "Contact can be heard as well as felt: a microphone on the case picks "
        "up a click as the fence meets each wall of the notch, one each way. "
        "At each click the safecracker reads the number under the index; the "
        "gap is the difference.\n"
        "Ours chalks both on the dial, with the arc between. When the gap "
        "reads narrower, the arc turns blue, and so does the slate's reading.",
    ), (
        "ONE WHEEL AT A TIME",
        "Two graphs and a few tries",
        "Park all three wheels together on each number, feeling the contact "
        "points: the gap narrows at wheel 1's number. Leave wheel 1 there and "
        "park the other two: it narrows at wheel 2's. Then try every second "
        "number for wheel 3.\n"
        "Ours stops each graph past the narrowing. A real safecracker graphs "
        "the whole dial: false gates narrow it too.",
    ), (
        "LOCKS THAT LEAK LESS",
        "What safecrackers taught the lockmakers",
        "Makers answered with wheels cut to finer tolerances, false gates that "
        "give false narrowings, and levers kept off the wheels until the dial "
        "is at one point only. Sargent & Greenleaf's best locks are tested "
        "against expert manipulation for 20 man-hours (Underwriters "
        "Laboratories' Group 1).\n"
        "These wheels differ by 0.1 mm, on purpose, so the leak can be seen.",
    )],
    "napier": [(                     # (1617, Rabdologiae, Napier's death that year; the set of ten rods and four-digit
        "NAPIER'S BONES",            #  numbers: Wikipedia, MacTutor (Glaisher); 4138 x 567's rows: MacTutor)
        "The multiplication table, cut into rods",
        "Each face of a rod holds one digit's multiples, the tens above "
        "each diagonal and the units below. Lay the rods for 4138 beside the "
        "index, and row 6 holds 4~×~6, 1~×~6, 3~×~6 and "
        "8~×~6 side by side. Add along the diagonals from the right, "
        "carrying any ten.\n"
        "Type 4138 X 567 and press Return. M takes you close to the board.",
    ), (
        "TEN RODS, FOUR FACES",
        "Napier's own set",
        "John Napier published the rods in 1617, in Rabdologiae, the year he "
        "died. His ten rods carry four tables each: every digit is on four "
        "rods and no rod has one twice, so any four-digit number can be laid.\n"
        "Watch the hand lay 2222 with four different rods. Here each rod's "
        "opposite faces make 9.",
    ), (
        "SEVERAL DIGITS",
        "A row for each, then add",
        "For 4138~×~567 the board stays as it is: row 5 gives 20690, row "
        "6 gives 24828, row 7 gives 28966. Each is moved a place left of the "
        "one after it and the three are added: 2346246.\n"
        "The rods do the multiplying; the person still does the adding. Tab: "
        "rods that do the carrying too.",
    )],
    "napier-genaille": [(            # (Genaille, Lucas, 1891, the rows 2 to 9: Wikipedia, Roegel, nzeldes)
        "GENAILLE'S RODS",
        "The carrying, drawn",
        "Row m of each rod holds a number for every carry the rod to its "
        "right can send: the units of digit~×~m plus that carry. Its "
        "triangle points to the number on the next rod that the tens select.\n"
        "Start at the last rod's top number in the row and follow the "
        "triangles left: the numbers passed are the product. No adding.",
    ), (
        "AN ENGINEER'S ANSWER",
        "Genaille and Lucas, 1891",
        "The mathematician Édouard Lucas set the problem; Henri Genaille, "
        "an engineer on the French state railways, answered it with these "
        "rods, shown in 1891. They were popular for a few years, until "
        "mechanical calculators took over.\n"
        "They have no row for 1: times 1 is the number itself.",
    ), (
        "FURTHER READING",
        "Napier's bones and Genaille's rods",
        "Denis Roegel, Napier's Bones and Genaille-Lucas's Rods (2015). Free "
        "online.\n"
        "Michael R.~Williams, Early Calculation, in William Aspray (ed.), "
        "Computing Before Computers (1990).\n"
        "MacTutor History of Mathematics: Napier's rods.",
    )],
    "slide-rule": [(                 # (Gunter 1620, Oughtred c. 1622: MacTutor; Mannheim 1851: Oughtred Society,
        "THE SLIDE RULE",            #  Smithsonian; Apollo 13's Pickett N600-ES: National Air and Space Museum)
        "Multiplying by adding lengths",
        "On D, every number stands as far along as its logarithm: 2 three "
        "tenths of the way, 4 six tenths. C, on the slide, is the same. Put "
        "C's 1 over 2 on D, and 3 on C stands over 6: the slide adds the two "
        "lengths, as logarithms add when numbers multiply.\n"
        "Type 2.5 X 3.2 and press Return. M takes you close to the hairline. "
        "Tab: squares, roots and more.",
    ), (
        "THE DECIMAL POINT",
        "Three figures, and an estimate",
        "The rule shows only figures: 2~×~3 and 20~×~300 look the "
        "same on it. You place the point by a rough estimate: 2.5~×~3.2 "
        "is about 3~×~3~=~9, so the 8.00 the rule shows is 8, not 0.8 "
        "or 80.\n"
        "A 25~cm rule gives three figures. If C's 1 would put the answer off "
        "the end, C's 10 goes over the first number instead.",
    ), (
        "FROM GUNTER TO THE MOON",
        "Three and a half centuries",
        "In 1620 Edmund Gunter drew a scale of logarithms on a rule and added "
        "lengths on it with dividers. About 1622 William Oughtred slid two "
        "such scales along each other.\n"
        "In 1851 Am\u00e9d\u00e9e Mannheim, a French artillery officer, "
        "settled the scales A, B, C and D and added the cursor. Apollo crews "
        "carried slide rules; pocket calculators ended them after 1972.",
    )],
    "slide-rule-powers": [(
        "SQUARES, ROOTS, CUBES",
        "The slide rule's second way",
        "The hairline reads every scale at once. A fits two decades into the "
        "length of one, so over any number on D it shows the square; K fits "
        "three, the cube. CI, in red, is C backward: over x on C it shows "
        "1/x. L is even: it shows the logarithm itself.\n"
        "Type a number, then S, R, K, I or L.",
    ), (
        "WHICH HALF OF A",
        "Square roots, and logarithms",
        "2 and 20 stand in different places on A, and their roots differ too: "
        "1.414 and 4.47. Count the figures before the point: an odd number "
        "(2, or 200) takes A's left half, an even number (20, or 2000) its right.\n"
        "L gives a logarithm's figures; the whole number in front comes from "
        "where the point is. Log~2 is 0.301, so log~2000 is 3.301.",
    ), (
        "FURTHER READING",
        "The slide rule",
        "Florian Cajori, A History of the Logarithmic Slide Rule and Allied "
        "Instruments (1909). Free online.\n"
        "Peter M.~Hopp, Slide Rules: Their History, Models and Makers (1999).\n"
        "The Oughtred Society, oughtred.org: a beginner's guide and a "
        "reference manual.",
    )],
    "differential": (
        "THE DIFFERENTIAL",
        "Bevel gears that add",
        "Turn input A and the small gears on the cross pin roll round input B, "
        "carrying the ring round the middle half as far. The ring always turns "
        "(A~+~B)~/~2; with twice as many numbers as the inputs, it reads A~+~B. "
        "Turn one input backward and it subtracts.\n"
        "The same gears let a car's wheels turn at different speeds on a bend. "
        "Fire-control computers and Bush's Differential Analyser used them to add.",
    ),
    "pascaline": (
        "THE PASCALINE",
        "Blaise Pascal's adding machine, 1642",
        "Pascal built it at nineteen to help his father, a tax official, with "
        "his sums. Each dial turns a wheel of ten places; dial in a number and "
        "it is added to what the wheels show.\n"
        "The carry is the clever part: a wheel passing 9 lifts a weighted "
        "lever, the sautoir, which drops as it goes on to 0 and kicks the next "
        "wheel on by one. Watch 99~+~1 ripple to 100.",
    ),
    "lehmer": (
        "LEHMER'S NUMBER SIEVE",
        "Wheels that find factors, 1926",
        "Each wheel has as many places as its number: 9, 8, 7 and 5. Every "
        "turn of the handle moves them all on one place. Pegs close the holes "
        "of the numbers that fail a test; where every wheel shows an open "
        "hole at once, the probe falls right through, and the machine stops.\n"
        "Lehmer built his first of bicycle chains, his second of gears, light "
        "and a photocell. This one factors a number by Fermat's way.",
    ),
    "beadsort": [(                    # (Arulanandham, Calude and Dinneen, Bulletin of the EATCS 76, 2002)
        "THE BEAD SORT",
        "Sorting by gravity",
        "Each number, 0 to 9, is a row of beads laid from the left on nine "
        "rods: 3 is a bead on rods 1, 2 and 3. The first number is the "
        "bottom row.\n"
        "The hand turns the frame upright. Every bead slides down its rod "
        "until it rests on the bead below, and the rows, read from the "
        "bottom, are the numbers sorted, largest first. Type digits and "
        "press Return; R lays eight at random.",
    ), (
        "WHY IT SORTS",
        "Each rod counts",
        "Rod 4 holds a bead for every number of 4 or more, and they all fall "
        "to the bottom. So the bottom row reaches as far as the largest "
        "number, the second row as far as the second largest, and so on.\n"
        "Each bead keeps its number's colour. Afterwards the rows are mixed: "
        "the beads moved, not the numbers. A bead sort sorts values, and "
        "keeps nothing else that came with them.",
    ), (
        "A NATURAL ALGORITHM",
        "Auckland, 2002",
        "Joshua Arulanandham, Cristian Calude and Michael Dinneen described "
        "the bead sort in 2002, as an algorithm found in nature.\n"
        "All the beads fall at once, however many numbers there are; but it "
        "takes a bead for every unit of every number, and sorts only whole "
        "numbers. Done in a computer's memory it is slow: here gravity does "
        "the work.",
    )],
    "slide-adder": [(                 # (Troncet's arithmographe, 1889; the Addiator, 1920)
        "THE SLIDE ADDER",
        "Adding with a stylus",
        "Each column is a band behind the cover, with pegs a step apart "
        "and the digits 0 to 9; its window shows one.\n"
        "To add a digit, the hand puts the stylus between the pegs beside "
        "that digit on the cover and draws it down to the bottom of the "
        "slot. The band goes down that many steps, and the window shows "
        "that many more. Type a number and press Return.",
    ), (
        "THE CARRY",
        "Up, and round the hook",
        "A red gap means the band is too far down for that digit. Then the "
        "hand pushes it up to the top instead: up 10 less the digit, which "
        "shows the digit more, less ten.\n"
        "Round the hook at the top into the next column, one step down: "
        "that is the ten carried. If that column shows 9, it won't go down: "
        "add one there the same way, and carry again.",
    ), (
        "A POCKET CALCULATOR",
        "Kummer, Troncet, the Addiator",
        "Heinrich Kummer put the carry in the hook in the 1840s. Louis "
        "Troncet's arithmographe of 1889 made it popular, and the Addiator, "
        "from 1920 to 1982, put it in millions of pockets.\n"
        "It does nothing by itself: every carry is a move of the hand. The "
        "hook only makes the move easy to remember.",
    )],
    "slide-adder-subtract": [(
        "SUBTRACTING",
        "Up from the red digits",
        "Beside each slot, on the left, are the digits again in red, going "
        "down. To subtract a digit, the hand puts the stylus beside it and "
        "pushes up to the top of the slot: the band goes up that many steps, "
        "and the window shows that many fewer.\n"
        "To subtract from a number, put it on first by adding it.",
    ), (
        "THE BORROW",
        "Down, and round the bottom",
        "Where the gap is not red, there aren't enough to take. The hand "
        "draws the band down to the bottom instead, which shows the digit "
        "fewer, plus ten.\n"
        "Along the bottom into the next column, one step up: the ten "
        "borrowed. A column at 0 won't go up: take one there, and borrow "
        "again.",
    ), (
        "LESS THAN NOTHING",
        "The windows show the complement",
        "Take 4729 from 853 and the last borrow has no column to come from. "
        "The windows then read 996124: a million less 3876, the answer.\n"
        "An Addiator shows such numbers the same way; the person using it "
        "has to know.",
    )],
    "linkages": [(                    # (Peaucellier, Nouvelles Annales 1864, 1873; Lipkin 1871)
        "THE INVERTER",
        "Peaucellier's cell, 1864",
        "Two long arms from the fixed pin O hold a rhombus of four short "
        "bars at its far corners A and B. Its other corners, P and Q, then "
        "stay on one line through O, and OP times OQ is always the long "
        "arm squared less the short side squared: here 100.\n"
        "The hand slides P to x; Q stops at 100 / x. Type x, 5 to 9, and "
        "press Return.",
    ), (
        "WHY IT HOLDS",
        "Two right triangles",
        "A and B are each as far from P as from Q, and O is as far from A "
        "as from B: so O, P and Q lie on one line, square across AB at its "
        "middle, M.\n"
        "Then OA squared is OM squared plus AM squared, and PA squared is "
        "PM squared plus AM squared. Take one from the other: OA squared "
        "less PA squared is OM squared less PM squared, which is OP times "
        "OQ.",
    ), (
        "BARS FLAT ON A BOARD",
        "From the Walker Room",
        "Bars that hinge together lie at different heights, so they pass "
        "over each other. Each hinge pins its two ends at both heights, "
        "or the bars lean and the reading drifts.\n"
        "The board lies flat, so gravity pulls across the movement and "
        "the bars carry none of it.",
    )],
    "linkages-line": [(
        "A STRAIGHT LINE",
        "The circle through O",
        "Put P on a crank whose circle passes through O. Turned inside out "
        "by the cell, that circle becomes a straight line, and Q goes "
        "along it: its pen draws the line.\n"
        "Press Return: the crank turns across and back, and the slate "
        "reports how far the pen strays from the line.",
    ), (
        "THE FIRST EXACT ONE",
        "Watt's was only close",
        "Watt's linkage of 1784 guided his steam engine's piston near a "
        "straight line, but not on one. Peaucellier's, from 1864, is "
        "exact, and Lipkin found it again in 1871.\n"
        "Sylvester lectured on it in London in 1874, and Kelvin is said to "
        "have called it the most beautiful thing he had ever seen.",
    ), (
        "WHERE THE LINE LIES",
        "Half the constant over the crank",
        "The crank's circle has radius 3.5 and passes through O. Its far "
        "point, 7 from O, inverts to 100 / 7: the line stands 14.29 from "
        "O, square across the line through O and the crank's pivot.\n"
        "A longer crank brings the line nearer.",
    )],
    "linkages-multiply": [(
        "A MULTIPLIER",
        "Similar triangles",
        "A slotted lever turns about the fixed pin O. Across the board, at "
        "distance 6 along it, the b carriage tilts the lever: it rises "
        "0.75 b there.\n"
        "At a along the board, 4 a here, the lever has risen 4a times "
        "0.75b over 6: half of a times b. The cross carriage's pin rides "
        "the slot there, and its scale reads a times b.",
    ), (
        "THE PINS IN THE SLOT",
        "Blocks on the lever",
        "Each pin is a block that slides along the lever, hinged to its "
        "carriage. The blocks lie beside the lever, above and below it, "
        "so the two can pass.\n"
        "Type a, 2 to 5, Space, and b, -5 to 5, then Return. Set a and b "
        "the same, and it squares.",
    ), (
        "MECHANISMS THAT COMPUTE",
        "Kempe, 1876",
        "Alfred Kempe proved in 1876 that linkages can draw any curve "
        "given by a polynomial: they add, multiply and invert.\n"
        "Gun directors of the Second World War worked out their fire "
        "with such linkages, made of bars and pins, before electronics "
        "took over.",
    )],
    "linkages-kempe": [(              # (Kempe 1876; W. Spears's "Bill", 2026)
        "KEMPE'S REVERSOR",
        "Twice the angle",
        "Two crossed parallelograms share the angle at O. The big one has "
        "sides 8 and 4; the small one, 4 and 2, is the same shape. Turn "
        "the crank by any angle from the fixed bar, and the arm turns twice "
        "as far.\n"
        "Press Return: the crank turns from 20 to 160 degrees and back, and "
        "the slate shows both angles.",
    ), (
        "AND AN ADDER",
        "A parallelogram adds",
        "A parallelogram hangs on the crank's end, 6 out, and the arm's end, "
        "3 out. Its far corner sits at the sum of the two, so its pen draws "
        "6 turned by the angle plus 3 turned by twice it: a limacon.\n"
        "Doubling, adding and a fixed scale are all Kempe needed: with them, "
        "a linkage can draw any curve made of such turns.",
    ), (
        "BILL, IN CURSIVE",
        "One linkage, every bar",
        "William Spears designed one Kempe linkage to write his name, Bill, "
        "in cursive. Every term of the curve takes its own reversors and "
        "adders: built, it would need about 340 bars, and braces to keep "
        "each from folding.\n"
        "Across the hall, the linkages that write take another road: a "
        "small linkage, found by search, for each stroke.",
    )],
    "linkages-write": [(              # (W. Spears's synthesizer, 2026; Kempe 1876)
        "LINKAGES THAT WRITE",
        "One crank, many pens",
        "Type a letter. Its linkages go on the board, the crank turns once, "
        "and every pen draws its stroke. The other cranks are geared to the "
        "first: one motor drives them all.\n"
        "Each linkage is a four-bar with more pairs of bars hung on it, up "
        "to fourteen bars, found in advance by a search.",
    ), (
        "WHY MORE THAN ONE PEN",
        "Junctions are hard",
        "A pen on a linkage never lifts, and it can't turn back on itself "
        "sharply. Round letters, like O, C and D, a single linkage draws "
        "well; E, M and W it can't.\n"
        "So a letter is split where its strokes meet. Each pen draws one "
        "unbranched stroke, out and back, which a linkage does well.",
    ), (
        "SLOPPY, OK, VERY GOOD",
        "Accuracy costs bars",
        "1, 2, 3 choose how close every pen must keep to the letter: 8%, 4% "
        "or 2% of its height. For each, the cheapest split and linkages "
        "found. The slate counts the pens and the bars.\n"
        "Kempe proved in 1876 that a linkage can draw any curve; his way "
        "would take hundreds of bars for a word.",
    )],
    "beadsort-spaghetti": [(          # (A. K. Dewdney, Scientific American 250(6), June 1984, p. 19)
        "THE SPAGHETTI SORT",
        "Sorting by height",
        "Each number, 0 to 9, is a rod cut to its length: the larger the "
        "number, the longer the rod. The hand stands them in the rack, "
        "their feet level on its base.\n"
        "Then it lowers the palm, a flat board, onto them. The first rod it "
        "touches is the tallest: it is taken out and laid down, and the palm "
        "goes on down to the next. Type digits and press Return; R cuts "
        "eight at random.",
    ), (
        "WHY IT SORTS",
        "The palm does the comparing",
        "With their feet level, a longer rod stands taller, and the palm "
        "meets the rods in order of height. It takes the tallest of all in "
        "one movement, however many there are.\n"
        "Here each rod keeps its colour, and they come out in order, "
        "colours and all. The bead sort moves beads, so only the values "
        "come out sorted; the spaghetti sort moves the things themselves.",
    ), (
        "AN ANALOGUE GADGET",
        "Dewdney, 1984",
        "A. K. Dewdney described the spaghetti sort in Scientific "
        "American's Computer Recreations, June 1984, among other analogue "
        "gadgets for solving problems. He called such ideas folklore, "
        "passed on by word of mouth.\n"
        "Cutting the rods takes a step for each number, and so does taking "
        "them out: the time grows only as the count. But a bigger bundle "
        "needs a bigger hand.",
    )],
    "domino-adder": (                 # (Matt Parker: think-maths.co.uk, the Domino Computer, Oct. 2012)
        "THE DOMINO HALF ADDER",
        "Falling dominoes that add",
        "268 dominoes add two one-bit numbers, A and B, and show the answer "
        "as two tiles, CARRY and SUM, which fall to show a 1: so 1~+~1 makes "
        "binary 10.\n"
        "Three tricks are enough. Waves meeting head-on stop each other; a "
        "branch is taken only by a wave running toward it; and a wave can cut "
        "across another line. From these come the gates XOR and AND. In 2012 "
        "Matt Parker's team built one of 10,000 dominoes that adds two "
        "four-bit numbers.",
    ),
    "galton": (                       # (Tisley and Spiller made Galton's in 1873: UCL, LDUGC-063)
        "THE GALTON BOARD",
        "Francis Galton's quincunx, 1873",
        "A ball falling through twelve rows of pins goes left or right at "
        "each; the bin it ends in counts the times it went right. Where one "
        "ball goes is chance, yet 150 of them pile up in the same bell, close "
        "to the gold lines fair coins would give: the binomial distribution, "
        "which for many rows becomes the normal curve.\n"
        "Galton's, made for him in London, ran on lead shot. Here two "
        "mirror-image wheels under the hopper let the balls in one at a time.",
    ),
    "splitter": [(
        "THE SPLITTER BOARD",
        "Fair coins, made exact",
        "On the Galton board opposite, each pin is fair, but a ball keeps "
        "moving sideways and goes the same way at the next pin two times in "
        "three. Here every pin is a splitter: a neck drops each ball straight "
        "onto it, and the choice it makes is a fresh coin.\n"
        "Tab steps on through its five ways, with walls that catch balls or "
        "send them back.",
    ), (
        "A WALL THAT CATCHES BALLS",
        "First passage",
        "Count each ball's steps: +1 when a pin sends it right, \u22121 when "
        "left. The wall is at \u22122: a ball is caught the first time it has "
        "gone left twice more than right, like a gambler with two dollars "
        "going broke.\n"
        "It rolls down a ramp into the tube for its row: a quarter of the "
        "balls in the first, then a long thin tail. On a board without end "
        "every ball would be caught, yet the average wait would be infinite.",
    ), (
        "THE MATHEMATICS",
        "The reflection principle",
        "The chance of first reaching \u2212a at step n is a/n times the "
        "chance of being at \u2212a then: 1/4, 1/8, 5/64 ... for the tubes. "
        "The chance of not yet being caught falls only as 1/\u221an, too "
        "slowly for an average.\n"
        "The balls that survive pile up away from the wall: in each bin, the "
        "bell curve's count less its mirror image's in the wall. Flip a path "
        "that touched the wall after it touched, and it ends at the mirror place.",
    ), READING],
    "splitter-ruin": [(
        "GAMBLER'S RUIN",
        "Two walls that catch balls",
        "Walls on both sides, four places apart, the balls starting one place "
        "from the left one. Almost every ball is caught within the twelve "
        "rows, by one wall or the other, into the tube for its side and row.\n"
        "A gambler with one dollar plays one with three, a dollar a toss, "
        "until one is broke. The chance of winning is your share of the "
        "money: a quarter of the balls go out on the right.",
    ), (
        "THE MATHEMATICS",
        "A fair game stays fair",
        "With walls a places to the left and b to the right, a ball goes out "
        "on the right with chance a/(a~+~b), after a\u00b7b steps on average: "
        "here a quarter, after three steps.\n"
        "Why: in a fair game the winnings you expect stay nothing, to the "
        "end. If p is the chance of winning b, the rest losing a, then "
        "p\u00b7b~=~(1~\u2212~p)\u00b7a, and so p~=~a/(a~+~b).",
    ), READING],
    "splitter-reflect": [(
        "A WALL THAT SENDS BALLS BACK",
        "The reflection principle, the other way",
        "Three places left of the start, a half tooth on the wall sends every "
        "ball that reaches it back inward, rolling off its pin just as a ball "
        "rolls off any splitter.\n"
        "No ball is lost, and each bin fills with the bell curve's count plus "
        "its mirror image's in the wall: of 150, 47, 42, 31, 19, 8 and 2 from "
        "the wall out. The wall that catches balls takes the mirror image "
        "away; this one adds it.",
    ), (
        "THE HALF TOOTH",
        "Built, and measured",
        "The first half tooth was a bare slope. A ball dropped onto it kept "
        "its speed, crossed the next neck and went back to the wall three "
        "times in four, and the walls hoarded balls.\n"
        "Kept on its pin, a ball lands on the pin's shoulder as it does on "
        "any splitter, and after the wall it goes on inward half the time, "
        "as a fair coin should. Two thousand balls a test were counted.",
    ), READING],
    "splitter-flat": [(
        "THE PILE GOES FLAT",
        "Two walls that send balls back",
        "With a bouncing wall on each side, three places from the start, the "
        "balls wander back and forth between them and forget where they "
        "began: by the sixth row each of the three bins is as likely as the "
        "others, and 150 balls fill them 50, 50, 50.\n"
        "Wider walls take longer: the rows needed grow as the square of the "
        "width. Five bins wide, twelve rows still leave 26, 31, 35, 31, 26.",
    ), READING],
    "splitter-none": [(
        "NO WALLS",
        "The binomial, exactly",
        "Twelve fair coins for each ball: its bin counts its heads. Of 4,096 "
        "equally likely ways down, 924 end in the middle bin, so for 150 balls "
        "the gold lines stand at 34 in the middle, then 29, 18, 8 and 2 either side.\n"
        "The Galton board opposite comes close to this. Here the pins really "
        "are fair coins, and the pile matches the lines as closely as chance allows.",
    ), READING],
    "digicomp": (
        "THE DIGI-COMP II",
        "A computer of rolling balls, 1965",
        "Designed by John Godfrey and sold by E.S.R. Inc. as a toy, it counts, "
        "adds, subtracts, multiplies and divides in binary, run by nothing but "
        "balls rolling down a tilted board.\n"
        "Each rocker is a flip-flop, a bit that a passing ball tips over. "
        "Thirteen of them hold the numbers; four switches are its memory. Its "
        "programs are lines of settings, shown on the board behind it.",
    ),
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
