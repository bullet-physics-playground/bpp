# Euler's Cabinet of Curiosities

An 18th-century walnut gallery, L-shaped, for WyomingWill's rigid-body
curiosities. Walnut panelling with gilded frames, parquet floor, a
coffered ceiling with chandeliers, the title in gilt on the wall at the
corner, an armillary sphere in the corner and a tall window at the far end.
Each exhibit stands in a bay of its own with a gilt-lettered placard.

**Only the exhibit you're standing at runs.** Walk away and it stops where
it is (a gömböc frozen in mid-air, a top mid-flip); come back and it
carries on from there.

## Running it

Open `cabinet.lua` in bpp. The exhibits' folders must be next to this one,
as they are in the repository (`../Gomboc/`, `../Bille/` and so on).

## Keys

Click the 3D view first so it has the keyboard.

| Key | Action |
|---|---|
| `Tab` | walk on: the view from the entrance, the exhibits in wing A, the view from the corner down wing B, the exhibits in wing B, then back to the entrance |
| `Shift+Tab` | walk back |

Everything else goes to the exhibit you're at, with the same keys as when
it runs on its own; the Shortcuts pane shows them. Its sliders are in the
Params pane, named after it ("Drop C: speed", "Tippe top: friction").

Rest the mouse on an exhibit, a placard, a covered bay or the armillary
sphere to see what it is.

bpp's own one-letter keys (`S` stop, `D` sleeping, `R` reload, `P` POV-Ray)
would change the whole hall, so at an exhibit they do only what the exhibit
uses them for. Looking down the hall, `P` is held back (use the POV-Ray menu).

## The plan

Wing A runs north from the entrance to the corner; wing B runs east from
the corner. Each wing has bays on both sides, 4.2 m wide and 3.3 m deep,
with a 3.4 m aisle between.

| Bay | Exhibit | Folder |
|---|---|---|
| A, west 1 | Gömböc Drop C | `../Gomboc/gomboc-drop-c.lua` |
| A, east 1 | Gömböc Variety | `../Gomboc/gomboc-variety.lua` |
| A, west 2 | Bille and the polyhedra | `../Bille/bille-drop.lua` |
| A, east 2 | the Dzhanibekov effect | `../Dzhanibekov/dzhanibekov.lua` |
| A, west 3 | the rattlebacks | `../Rattleback/rattleback.lua` |
| A, east 3 | the tippe tops | `../TippeTop/tippe-top.lua` |
| A, west 4 | the chain fountain | `../ChainFountain/chain-fountain.lua` |
| A, east 4 | the spinning egg | (in preparation) |
| B, north 1 | the double cone | (in preparation) |
| B, south 1 | the oloid and the sphericon | (in preparation) |
| B, north 2 | the falling Slinky | (in preparation) |
| B, south 2 | the Brazil-nut effect | (in preparation) |
| B, north 3 | Newton's cradle | (in preparation) |
| B, south 3; B, north 4; B, south 4 | empty ("reserved") | |

## Adding exhibits

Each exhibit is one line in `EXHIBITS` near the top of `cabinet.lua`:

```lua
{ dir = "../TippeTop/", file = "tippe-top.lua", name = "the tippe tops", label = "tippe-top",
  prefix = "Tippe top: ", floorY = -75, about = "The tippe top: ..." },
```

| Setting | What it does |
|---|---|
| `dir`, `file` | the script. If it isn't there yet, the bay is covered with a dust sheet and the placard says "in preparation"; when the script turns up, the bay comes to life. |
| `name` | what the header and Tab call it |
| `label` | its placard: a key of `cabinet-meshes/labels.lua` (the lettering is made by `make-labels.py`) |
| `prefix` | its sliders in the Params pane are named `prefix .. name` |
| `floorY` | the height of its own ground plane, in its own units: the hall's floor goes there |
| `stand` | `{ w, d }`: a walnut stand under it, for exhibits (the trays) that float above their ground plane on their own |
| `about` | what its placard says when the mouse rests on it |

Add lines and the hall grows to fit: both wings get longer. `SPARE_BAYS`
(3) adds empty bays at the far end.

An exhibit is written as a script that runs on its own, the way the
existing ones are: centimetres, its viewing side toward +z, a `Plane` for
its ground, its camera set once as it loads, and its physics stepping done
in `v:preSim` (the cabinet passes its physics settings on while you're at
it).

## How it works

Each exhibit is the unchanged script, loaded into a sandbox of its own (its
own set of globals) that:

* puts everything it builds into a Bullet world of its own, untouched, at
  its own coordinates (bpp draws that world in its bay, turned to face the
  aisle, and moves its camera there);
* finds its files in its own folder;
* gives it its own random numbers;
* keeps its sliders apart, and passes its keys, callbacks, help text and
  hover only while you're at it (hover works on any exhibit);
* keeps its ground plane, in its own world, not drawn (the hall's floor is
  drawn there, at the same height).

**Each exhibit runs exactly as it does on its own.** Each one has a
Bullet world of its own (bpp's `v:newWorld()`), made exactly as bpp makes
the scene's world, holding only what that exhibit builds, at its own
coordinates; bpp draws it in its bay (`v:placeWorld()`). It also gets the
same random numbers it would on its own. So it gives the same numbers, digit
for digit -- checked for all seven by running each both ways and comparing
everything it prints (with a fixed seed for the ones that seed from the
clock: `GC_SEED`, `GV_SEED`, `BD_SEED`). Walking away for a while and coming
back gives the same numbers as never leaving.

Why separate worlds: Bullet works out an exhibit's contacts in an order
that depends on everything else in its world, even things that never touch
it, and it rounds differently 15 m from the origin than at it. Either is
enough to send a rattleback, a tippe top or a chain a different way within
seconds. In a world of its own, at its own coordinates, nothing else is
there.

**Needs bpp with the separate-worlds patch** (`v:newWorld`, `v:useWorld`,
`v:placeWorld`, `v:currentWorld`). A script that doesn't use them -- every
other demo, the rec room, each exhibit on its own -- runs exactly as before.
(POV-Ray export writes each exhibit where its world has it, at the origin,
not in its bay.)

Only the world of the exhibit you're at is stepped; the others wait exactly
as they are, and cost nothing. Each exhibit's own step sizes apply while
you're at it; its other physics settings belong to its world.

`CABINET_START=<part of a name>` starts at that exhibit (`corner` for the
view down wing B), for trying one out.

## Files

* `cabinet.lua`: the hall. Open this one.
* `cabinet-meshes/`: the gilt lettering (title and placards), `labels.lua`
  (their sizes), and the brass ring of the armillary sphere.
* `make-labels.py`: makes the lettering (needs Python with Pillow and NumPy
  and the DejaVu fonts).
