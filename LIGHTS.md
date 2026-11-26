# Light sources in bpp: a handover

Jakob's proposal (November 2026), for a new chat to carry out with him.
Read this first, then HACKING.md and CLAUDE.md.

## The goal

In Jakob's words: bpp should have classes for POV-Ray's light sources,
added from Lua with something like `v:addLight()`, with "the 5 kinds of
light" previewed in the OpenGL view. His test of it: rebuild the indoor
scene from LightSys (http://www.ignorancia.org/index.php?page=lightsys)
inside bpp, every object and every light.

So one set of lights, seen in bpp's own view and written to POV-Ray, where
today the two are separate (below).

## The five kinds

POV-Ray 3.7's light sources (its manual's "Light Source" section; check
the details there, as povray.org didn't load when this was written):

| Kind | In POV-Ray | What it is |
|------|------------|------------|
| point | `light_source { <pos> color }` | shines all round from a point |
| spotlight | `spotlight point_at, radius, falloff, tightness` | a cone: full inside `radius`, fading to nothing at `falloff` |
| cylindrical | `cylinder point_at, radius, falloff, tightness` | a beam of parallel light, round, with soft edges |
| parallel | `parallel point_at` | light from one direction everywhere (the sun) |
| area | `area_light <axis1>, <axis2>, n1, n2` (+ `adaptive`, `jitter`, `circular`, `orient`) | a grid of point lights: soft shadows |

And modifiers any of them can take: `shadowless`, `fade_distance` with
`fade_power` (falling off with distance), `looks_like` / `projected_through`,
`media_interaction`, `media_attenuation`.

## What bpp has today

- **The OpenGL view's two lights.** `v.glLight0`, `v.glLight1` (positions,
  a btVector4: w ≠ 0 a point at xyz/w, no fall-off) and `v.glLight0Color`,
  `v.glLight1Color`; defaults in `Viewer::init()` (`src/viewerdraw.cpp`), set
  up as `GL_LIGHT0`/`GL_LIGHT1` there too (fixed-function, about line 200).
- **The shadow map** (`src/shadowmap.cpp`) draws the lit scene with its own
  shader, which reproduces those two lights: `for (int i = 0; i < 2; i++)`
  over `gl_LightSource[i]`, position, diffuse, specular and ambient only (no
  spot cone, no fall-off). Only light 0 casts shadows.
- **POV-Ray export** (`src/povexport.cpp`) writes the two lights as
  `GL_Light0`, `GL_Light1` declarations; `includes/settings.inc` turns them
  into a `light_source` (an `area_light` by default), or into LightSys
  lights with `use_lightsys`.
- **LightSys IV is already in `includes/`** (`bpp_lightsys.inc`, its
  constants, colours, CIE.inc and spectra; Jaime Vives Piqueres, 2003–09):
  the `Light(color, lumens, area axes, sizes, falloff)` and `Light_Color()`
  macros. `settings.inc` and several koppi demos (studio, pulley,
  marblerun ...) use it.
- **`PovScriptWriter`** (`src/objects/povscriptwriter.*`) already has a
  `PovLight` (Point, Spot, Directional, Area; position, direction, colour,
  intensity, radius, falloff, tightness, shadows), bound to Lua — but it only
  goes into the POV file that writer makes, never into the view.
  `demo/koppi/studio.lua` builds light fixtures its own way.

## Previewing each kind in OpenGL

Fixed-function OpenGL has point, spot and directional lights; it promises
at least 8 (`GL_MAX_LIGHTS`), and 8 is usually all there is. A starting point:

| Kind | Preview |
|------|---------|
| point | a positional light (w = 1); `fade_distance`/`fade_power` as GL's constant/linear/quadratic attenuation (POV's fall-off is 2/(1 + (d/fade_distance)^fade_power); GL's is 1/(c + l·d + q·d²): fit them) |
| spotlight | `GL_SPOT_DIRECTION` toward `point_at`, `GL_SPOT_CUTOFF` = `falloff`, `GL_SPOT_EXPONENT` from `tightness` and `radius` (GL has no flat full-strength core: approximate) |
| parallel | a directional light (w = 0), from its position toward `point_at` |
| cylindrical | nothing in OpenGL matches: a spotlight from well back with a narrow cone is the nearest look |
| area | a point light at its middle, its strength shared out; or a few point lights across it, if the 8 allow. Soft shadows only in POV-Ray |

Then: `shadowless` lights left out of the shadow map; `looks_like` objects
drawn; and a small marker for each light in the view, which can be turned
on and off (as constraints are).

**The shader matters as much as the fixed-function setup.** Whenever
shadows are on, the scene is drawn by the shadow map's shader, which knows
two lights and no cones or fall-off. It needs a loop over however many
lights there are, with spot cones and attenuation, or the preview will look
right only with shadows off. Which light casts the shadow (the brightest?
one the script names?) is a decision to make.

## Step 1: settled with Jakob

The questions were asked in November 2026 (git history has them in
full). Jakob's answers, then what the LightSys archive showed, then what
is still open.

### Jakob's answers

1. **The Lua side: classes**, `PointLight(...)`, `SpotLight(...)` and the
   rest, added with `v:add` and taken out with `v:remove`, as objects are.
2. **LightSys: yes.** A light takes `lumens` and a LightSys colour and is
   written through LightSys's own macros, so a render matches the original.
3. **The old two lights: as proposed.** A script that adds no lights gets
   `v.glLight0`/`glLight1` exactly as now (golden and screens unchanged).
   One that adds lights gets only its own, in the view and in the render
   (`settings.inc` makes none of its lights when the export declares
   `BPP_Lights`); `v.glAmbient` stays.
4. **More than 8: as proposed.** Every light in POV-Ray; in the view, the
   8 that light the camera's position most (power after fall-off), chosen
   again each frame.
5. **The source:** the LightSys IV archive,
   http://www.ignorancia.org/uploads/zips/lightsys4d.zip (Bill attached it
   to the chat; ignorancia.org can't be reached from the build machine).

### What the archive showed

`LightsysIV/demos/` has two indoor scenes, and `templates/` a third,
smaller one:

- **`demo_indoor1.pov`** (Jaime Vives Piqueres, 2003; "usage demo for
  indoor scenes" in its readme): a room about 300 × 250 × 400 units
  (centimetres), lit by a table lamp, a fluorescent panel on the ceiling,
  a halogen spot in a corner and a skylight in the window (off by
  default). Radiosity on; `Lightsys_Brightness = 1/6`,
  `Lightsys_ExposureFake = 1`; sRGB with a D55 white point.
- **`demo_indoor2.pov`** (Ive, 2003): a larger room with chairs, a
  Mondrian-style material map and an LP whose sleeve is the album cover
  `cyndi.png`, which bpp shouldn't ship.
- **`templates/LightsysIV indoor scene.txt`**: a box room, one `Light()`,
  a sphere.

Taken to be `demo_indoor1.pov` unless Jakob says otherwise. Its lights,
in POV-Ray's coordinates (bpp's z is the negative):

| Light | Kind | Lumens, colour | Area | Other |
|-------|------|----------------|------|-------|
| table lamp, <120,80,155> | point | 420, `ES_Incandescent_60w` | 9×9, 4×4, circular, orient | |
| ceiling panel, <0,245.9,0> | spot via `Light(..., Cfall = 1)`: radius −89.9, falloff 89.9, tightness 1, down | 900·4·π/2, `ES_Cool_White_Fluor` | 15×15, 5×5 | |
| halogen, <−130,249.9,175> | spot, radius 15, falloff 45, tightness 0, down | 1000, `ES_Solux_Halog4700K` | 9×9, 4×4, circular | |
| skylight (off) | spot, radius 90, falloff 90, sideways | 1200, `Daylight(7500)` | 48×56, 6×7 | |

What this means for the classes:

- **Area is a modifier, not only a kind.** Two of the spots are area
  lights too. So every light takes the area settings (`axis1`, `axis2`,
  `n1`, `n2`, `adaptive`, `jitter`, `circular`, `orient`; area when
  `n1` and `n2` are both above 0), and `AreaLight` is the point light that has them set
  from the start: still five classes, as Jakob asked.
- **A LightSys light is `light_source { Light_Color(colour, lumens) ...
  Light_Fading() }`**, which is all `Light()` is; two of the four lamps
  are written that way by hand, because `Light()` has no spot of its own.
  bpp writes that form for every kind, so a spot can take lumens too
  (parallel lights get no fading, as LightSys's sun has none).
- **The scene-wide LightSys settings** (`Lightsys_Brightness`, the
  colour system, the `Cl_` colours it declares) are SDL, and go in
  `v.pre_sdl`, which the frame writes before its lights.
- **Every lamp's glow is a separate object**: a shade or bulb filled with
  emitting media, `no_shadow`, beside its light. That is the scene's
  modelling, for step 5, not part of the light.
- The room is in centimetres with `Lightsys_Scene_Scale` unset (1); the
  demo keeps those units, so lumens and fall-off stay as they were.

### Still open (proposals taken until Jakob says otherwise)

- **`PovLight`** (unused, but in the API listing): left as it is for
  now; replacing it with the new classes is a separate change.
- **The shadow in the view:** the brightest light at the camera that
  isn't `shadowless`. (Step 3.)
- **How close the view looks:** no radiosity there, so steps 3–5 compare
  where light falls and how it fades, not overall brightness.
- **Lights in the galleries' exhibits:** not in this work.
- **A light following a body** (`v:attach`): later, if a scene needs it.
- **`looks_like` and `projected_through`** take an object, which the view
  draws too (step 4), so they come with step 4.

## Plan

Deliver each step as a patch on test-harness, with the git commands, the
way the galleries' work went.

1. **Questions** above, answered; write the answers into this file.
   *Check:* Jakob agrees with the API sketch. *Done* (above).
2. **The light classes, and POV-Ray export.** `PointLight`, `SpotLight`,
   `CylinderLight`, `ParallelLight`, `AreaLight`, added with `v:add`, each
   light written as its `light_source` (or LightSys's `Light_Color()` and
   `Light_Fading()`), the old two untouched when no light is added.
   *Check:* unit tests on the written POV text for each kind and modifier;
   the Lua API snapshot (`tests/api`) updated; the golden and smoke suites
   unchanged. *Done:* `src/objects/light.*`, `tests/35-lights.lua`,
   `tests/render/lights.lua`; `looks_like`/`projected_through` moved to step 4.
3. **Point, spot and parallel in the view**, fixed-function and the shadow
   shader alike, with attenuation.
   *Check:* a test scene with one of each, compared with its POV-Ray render
   side by side, by eye (`tests/render` only checks how bpp calls POV-Ray,
   with a stand-in, so a real POV-Ray is needed here): the same lit areas
   and fall-off; screenshots with shadows on and off agree.
4. **Cylindrical and area previews, shadowless, `looks_like`, light
   markers.** *Check:* the same comparison for each.
5. **The indoor scene**, rebuilt from its source as a demo, lights and all.
   *Check:* bpp's view next to its POV-Ray render and next to the original
   LightSys render.
6. **Docs**: the API in the manual, a basic demo per kind.

## Opening message for the new chat

> Clone github.com/bullet-physics-playground/bpp, check out the branch
> test-harness, and read LIGHTS.md at the top of the repository, then
> HACKING.md and CLAUDE.md. Build bpp as HACKING.md describes and run
> python3 tests/harness.py. Then start on LIGHTS.md's plan, step 1: the
> questions for Jakob. Deliver each step as a patch on test-harness, with
> the git commands.
