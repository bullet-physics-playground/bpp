# Linkages That Write

*Babbage's Hall, the bay after the linkages: type a letter, and linkages
of hinged bars draw it.*

**`MANUAL.pdf`** is the manual: how a linkage can draw a letter, why a
letter is split among pens, and what the slider shows (`F1` opens it,
here or in the hall). This README is the builder's reference.

The ninth machine on the walk, and a new one: William Spears's idea and
his linkage synthesizer. A pen on a linkage driven by one crank traces a
closed curve; the synthesizer finds the bars whose curve is nearest the
one wanted. One linkage draws a round letter (O, C, D) well; a letter
whose strokes meet at junctions (E, H, K, M, W) it can't, so the letter is
split at its junctions and each stroke gets a pen of its own, each pen
its own linkage. One crank turns once; the other cranks turn with it, and
every pen draws its stroke at once.

**The slider** (keys `1`, `2`, `3`, or the "accuracy" slider) sets how close
every pen must keep to the letter: **sloppy** within 8% of the letter's
height, **ok** within 4%, **very good** within 2%. For each, the letter
uses the cheapest split and linkages found (fewest bars, then fewest
pens), and the slate counts its pens and bars: a better letter takes more
bars, and more pens. B: 3 pens and 22 bars sloppy, 7 pens and 34 bars
very good. O: one four-bar, at every setting.

    bpp -f linkages-write.lua            (or walk to it in the hall)
    LW_SET="W 3" bpp -f linkages-write.lua

| Key | |
|---|---|
| `A`–`Z` | a letter: its linkages go on the board, the crank turns once, the pens draw it |
| `1`, `2`, `3` | sloppy, ok, very good (and draw the letter again) |
| `Space` | draw it again |
| `0` | the tour: B sloppy, ok and very good, then K |
| `F1` | the manual, `MANUAL.pdf`, opened in your PDF viewer |

The sliders: the accuracy; how long the crank takes to turn once (6 s at the least);
the simulation's speed. (The exhibit takes every letter key, so in the
hall `I` doesn't bring its label close and `H` doesn't open the manual:
`F1` does.)

## The linkages

Each pen's linkage is the synthesizer's: a **four-bar** (two fixed
pivots; the crank, turned by the motor; the coupler; the rocker) carrying a
point, and up to four (for one pen alone, five) **dyads** hung on it: two
bars from the last point to a new fixed pivot, carrying a new point. The
last point is the pen. Four bars to fourteen. `synthesis/README.md`
says how they were found, and how to find them again.

`alphabet.lua` holds every letter at every setting: each pen's linkage
posed at the start of the turn, in the letter's units, and the stroke it
draws, with how far the pen strays from it as computed.
`make-alphabet.py` makes it from `synthesis/alphabet.json`.

## What is simulated, and what is the script's

Every **link** is a body (a link with three pins, the coupler or a
dyad's first link, is a rigid plate) and every **pin** a hinge (Bullet's
`btHingeConstraint`); the fixed pivots are hinges to the board. The board
lies flat: the bars' weight is across their motion. A motor on the first
pen's crank turns it once; the **other cranks are held in step** with it,
1:1, the same way round or the other as each linkage was found, as a
timing belt or gears would hold them: each crank's hinge motor drives it
to the first crank's angle. (Bullet's gear constraint, which ties two
bodies' speeds, let a crank that pulled hard slip 114° in one turn:
`FINDINGS.md`.)

The bars are drawn at different heights (each link a height of its own),
and each pin's two points are given at their own bars' heights (the
linkages' rule: a hinge pins its points in all three directions). The
linkages pass through one another: nothing collides. A built one puts each
linkage on its own layer, or side by side on a shaft.

Every turn is checked: each pen's dots against its stroke (the farthest the
pen got from the stroke, and the farthest a point of the stroke is from
the pen), against what the search computed for it (within 0.5% of the
letter's height). The slate, the letter's grey guide and the dots are the
script's; every dot is where a pen was.

## Files

| File | |
|---|---|
| `MANUAL.md`, `manual/` | the manual and its figures (`python3 manual/make-figures.py`, but for `fig-exhibit.png`, a screenshot) |
| `linkages-write.lua` | the exhibit |
| `alphabet.lua`, `make-alphabet.py` | every letter's linkages, and what makes them |
| `synthesis/` | the synthesizer, the letters, the search, its results (`runs.tar.xz`), the picks |
| `make-slate.py`, `slate/` | the slate's pictures |
| `FINDINGS.md` | what was measured |
