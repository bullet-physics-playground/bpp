# Light sources

One small demo for each of POV-Ray's kinds of light, as bpp's classes, and
one for a LightSys lamp. A script makes a light, sets it up and adds it with
`v:add` (and takes it out with `v:remove`). Each light lights the 3D view and
is written into every exported frame for POV-Ray; when a script adds lights
of its own, bpp's two default lights (`v.glLight0`, `glLight1`) are off, in
the view and in the render. F6 renders the frame. The sliders change each
light as it runs.

The rooms are in centimetres, as LightSys's are. The API is in the wiki's
[Lua bindings reference](https://github.com/bullet-physics-playground/bpp/wiki/LUA-Bindings-Reference);
how the view shows each kind, and what it can't, is in [LIGHTS.md](../../LIGHTS.md).

*   `01-point-light.lua`: `PointLight`, shining all round, circling the room
    and fading with distance (`fade_distance`, `fade_power`).
*   `02-spot-light.lua`: `SpotLight`, a cone: full strength within `radius`
    degrees, gone by `falloff`, `tightness` narrowing it; sweeping the floor.
*   `03-cylinder-light.lua`: `CylinderLight`, a round beam of parallel light,
    `radius` and `falloff` in centimetres: the same size wherever it lands.
*   `04-parallel-light.lua`: `ParallelLight`, the sun's kind: from one
    direction everywhere; sliders move it round the sky.
*   `05-area-light.lua`: `AreaLight`, spread over an area for soft shadows
    (in POV-Ray; the view shows a point), with a bulb as its `looks_like`.
    Any kind can be an area light.
*   `06-lightsys-lamp.lua`: two desk lamps in lumens with LightSys colours
    (`lumens`, `lightsys`), written with LightSys's own macros, falling off
    with the square of the distance.

Every light shows a marker in its colour (View > Show Lights, or
`v.showLights`): a star, and a spot's cone, a cylinder's beam, a parallel
light's arrow or an area light's outline.
