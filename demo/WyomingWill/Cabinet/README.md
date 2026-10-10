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

* moves everything it builds to its bay and turns it to face the aisle
  (positions, transforms, velocities, spins, forces and gravity are turned
  on the way in and back on the way out, so its own sums still hold);
* finds its files in its own folder;
* gives its bodies its own gravity (the Dzhanibekov handles float in none);
* keeps its sliders apart, and passes its keys, callbacks, help text and
  hover only while you're at it (hover works on any exhibit);
* leaves out its ground plane: the hall's floor stands in for it, at the
  same height.

The exhibits you're not at have their moving bodies taken out of the
simulation (they keep their velocities) and their callbacks aren't called,
so they cost nothing. Each exhibit's own physics settings (step, sub-steps,
solver iterations) apply while you're at it.

`CABINET_START=<part of a name>` starts at that exhibit (`corner` for the
view down wing B), for trying one out.

## Files

* `cabinet.lua`: the hall. Open this one.
* `cabinet-meshes/`: the gilt lettering (title and placards), `labels.lua`
  (their sizes), and the brass ring of the armillary sphere.
* `make-labels.py`: makes the lettering (needs Python with Pillow and NumPy
  and the DejaVu fonts).
