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

1. **The Lua side.** `v:addLight{ type = "spot", pos = ..., point_at = ...,
   color = ..., ... }` returning a light object that can be moved and
   changed, or classes (`PointLight(...)`, `SpotLight(...)` ...) added with
   `v:add`? And removed how? Should `PovScriptWriter`'s `PovLight` become this
   class, so there is one light type, not two?
2. **LightSys in it.** The indoor scene is lit with LightSys: colour from a
   lamp type or temperature, strength in lumens. Should a light take
   `lumens` and a LightSys colour, and be exported through the `Light()`
   macro, so a render matches the original?
3. **The old two lights.** The galleries (Euler's Gallery, Babbage's Hall)
   and many demos set `v.glLight0`/`glLight1`, and the galleries swap them
   per exhibit and dim them in the aisle. They must keep working. Proposed:
   a script that adds no lights gets the two as now; one that adds lights
   gets those (and the two are off, or kept as fill: Jakob's choice).
4. **More than 8.** An indoor scene may have more lights than OpenGL shows.
   The brightest 8 (or nearest the camera) in the view, all of them in
   POV-Ray?
5. **The indoor scene's source.** ignorancia.org redirected in a loop when
   this was written, so nobody here has seen the scene files. Ask Jakob or
   Bill to attach the LightSys archive (it has the demo scenes) to the chat;
   don't model the room from memory or from pictures.

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
