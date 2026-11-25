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

## Things to settle with Jakob first (step 1)

Each question has a proposal; Jakob's answer goes under it, and step 2
starts from the answers. *Status: asked, answers pending.*

### What the code showed while writing these

- `PovLight` is used by nothing: no demo, no test (`tests/31` makes a
  `PovScriptWriter`, but no light). Its `type` is a bare C++ enum, so a script can only set it
  as a number; its spotlight writes a `direction` line, and its area light
  ignores `radius` and always writes `<1,0,0>, <0,0,1>, 10, 10`.
- Only five scripts touch `v.glLight0`/`glLight1`, not many: the two
  galleries, the Rec Room, the solar system exhibit and
  `tests/media-check.lua`. The galleries reach them through a proxy for `v`
  that knows the light properties by name (`LIGHTS` in `gallery.lua` and
  `hall.lua`) and moves an exhibit's light with its bay (`bayLight`).
- `settings.inc` always makes its lights from `GL_Light0`/`GL_Light1`, so
  a scene that adds lights needs a way to switch those off in the render
  too, not only in the view.
- The export writes the two lights into the main scene file, once; every
  frame of an animation is rendered with them where they were last.
- LightSys's `Light()` is always at the origin (the caller translates it),
  always fades as the square of the distance (`fade_power 2`, with
  `fade_distance` from `Lightsys_Scene_Scale`), and its only spotlight is a
  cosine fall-off over a hemisphere.
- `v` already has the pattern `addConstraint`/`removeConstraint`,
  `addShortcut`/`removeShortcut`.

### The API sketch to agree on

```lua
local lamp = v:addLight{
  type = "spot",               -- "point", "spot", "cylinder", "parallel", "area"
  pos = btVector3(0, 250, 0),
  point_at = btVector3(0, 0, 0), -- spot, cylinder, parallel (and area: its orientation)
  col = "#fff4e0",             -- as an object's col; or lumens + LightSys colour (2)
  power = 1,                   -- multiplies col
  radius = 20, falloff = 30, tightness = 10,              -- spot, cylinder
  axis1 = btVector3(40, 0, 0), axis2 = btVector3(0, 0, 40), -- area
  n1 = 4, n2 = 4, adaptive = 1, jitter = true, circular = false, orient = false,
  fade_distance = 100, fade_power = 2,
  shadowless = false,
  looks_like = bulb,           -- an Object, drawn in the view as well
}
lamp.pos = btVector3(0, 240, 0) -- every key is also a property, live
v:removeLight(lamp)
```

Names are POV-Ray's where it has one, so the manual reads across. A light
added this way is written into each frame's include, so it moves in an
animation (unlike the old two).

### The questions

1. **The Lua side.** Is the sketch above right: `v:addLight{...}` returning
   a `Light` that can be moved and changed, and `v:removeLight`? Or
   classes (`PointLight(...)`, `SpotLight(...)` ...) added with `v:add`?
   (`v:add` is for objects with a body; a light has none, so `addLight`
   fits beside `addConstraint`.) Should a light follow a body, as a
   decoration does with `v:attach` (a lamp on a moving cart)?
   *Proposed:* the sketch; following a body later, if a scene needs it.
   And `PovLight`: replace it with `Light` (`PovScriptWriter:addLight`
   taking one), so there is one light type, not two? Nothing uses it, but
   it is in the API listing, so removing it is a visible change.
   *Proposed:* replace it.
2. **LightSys in it.** The indoor scene is lit with LightSys: colour from a
   lamp type or temperature, strength in lumens. Should a light take
   `lumens` and a LightSys colour (`lightsys = "Cl_..."` or `kelvin =
   2700`) and be exported through `Light()`, so a render matches the
   original? `Light()` fixes the fall-off at inverse square; a light with
   `lumens` would then take no `fade_distance`/`fade_power` of its own, and
   the view would preview that inverse square. *Proposed:* yes, both ways
   on one class: `col`/`power` writes a plain `light_source`, `lumens`
   writes `Light()` (and pulls in the LightSys includes, as `use_lightsys`
   does now).
3. **The old two lights.** They must keep working for the five scripts
   above. *Proposed:* a script that adds no lights gets the two exactly as
   now (golden and screens unchanged). One that adds lights gets only its
   own, in the view and in the render (`settings.inc` skips its two when
   the export declares that the scene has lights); `v.glAmbient` stays.
   Or are the two kept as fill when lights are added? Jakob's choice.
4. **More than 8.** An indoor scene may have more lights than OpenGL
   shows. *Proposed:* every light in POV-Ray; in the view, the 8 that
   light the camera's position most (power after fall-off), chosen again
   each frame. Or nearest the camera, or the first 8 added?
5. **Which light casts the shadow** in the view (the shadow map has one)?
   *Proposed:* the brightest light at the camera that isn't `shadowless`,
   unless the script names one (`v.shadowLight = lamp`).
6. **How close the view should look.** LightSys interiors are usually lit
   largely by radiosity (light bouncing off the walls), which the view
   can't show; there it would be direct light and `glAmbient`. So the
   checks in steps 3–5 compare where the light falls and how it fades, not
   overall brightness. Is that the bar Jakob means by "previewed"?
7. **Lights in the galleries.** Should an exhibit be able to add its own
   lights, switched on as you step in and off as you leave, turned with
   its bay? The proxy for `v` would have to pass `addLight` through and
   keep track of them. *Proposed:* not in this work; the galleries keep
   their two lights.
8. **The indoor scene's source.** ignorancia.org redirected in a loop when
   this was written, so nobody here has seen the scene files. Ask Jakob or
   Bill to attach the LightSys archive (it has the demo scenes) to the chat;
   don't model the room from memory or from pictures. And its units: LightSys
   scenes set `Lightsys_Scene_Scale` for theirs, and the inverse-square
   fall-off depends on it; keep the original's units in the demo, or scale
   it to bpp's usual size? *Proposed:* keep the original's, so its
   lumens and fall-off stay as they were.

## Plan

Deliver each step as a patch on test-harness, with the git commands, the
way the galleries' work went.

1. **Questions** above, answered; write the answers into this file.
   *Check:* Jakob agrees with the API sketch.
2. **The light class, and POV-Ray export.** The class and `v:addLight` (or
   whatever step 1 chose), each light written as its `light_source` (or
   LightSys `Light()`), the old two untouched when no light is added.
   *Check:* unit tests on the written POV text for each kind and modifier;
   the Lua API snapshot (`tests/api`) updated; the golden and smoke suites
   unchanged.
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
