# The Bullet Physics Playground

A simple physics simulation software for prototyping and experimenting with the
[Bullet Physics](http://bulletphysics.org) library. It provides a graphical user
interface (GUI) for real-time interaction and a command-line interface (CLI) for
batch processing and scripting.

![GitHub last commit](https://img.shields.io/github/last-commit/bullet-physics-playground/bpp)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/bullet-physics-playground/bpp)
[![GitHub issues](https://img.shields.io/github/issues/bullet-physics-playground/bpp)](https://github.com/bullet-physics-playground/bpp/issues)

## Features

*   **Physics Simulation:** Powered by the robust and widely-used Bullet
    Physics library.
*   **Cross-Platform:** Builds and runs on Linux, Windows, and macOS.
*   **GUI:** An OpenGL-based GUI for visualizing and interacting with the
    simulations in real-time.
*   **Scripting:** Extend and control simulations using Lua scripting.
*   **Import/Export:**
    *   Import models from [OpenSCAD](http://www.openscad.org/).
    *   Export scenes to [POV-Ray](http://www.povray.org/) for high-quality
        rendering.
*   **Command-Line Interface:** A powerful CLI for running simulations, rendering
    animations, and piping data to other tools like
    [gnuplot](http://www.gnuplot.info/).

## Videos on YouTube

<a href="https://www.youtube.com/watch?v=RwMhyvVPsQI&list=PL-OhsevLGGI2bFpOqzqnWsGILh9a5YkDr" target="_blank"><img src="http://img.youtube.com/vi/RwMhyvVPsQI/maxresdefault.jpg" alt="Bullet Physics Playground" width="640" border="10" /></a>

## Build

Select your operating system:

 * [Build on Linux](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Linux)
 * [Build on Windows](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Windows)
 * [Build on Mac OS-X](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Mac-OS-X)

### Optional: embedded POV-Ray VFE rendering (experimental)

By default, F6 quick-render shells out to an external `povray`/`pvengine`
executable, same as it always has. There is an experimental alternative
build flag, `USE_VFE`, that instead embeds POV-Ray's own VFE (Virtual Front
End) API directly into bpp, so F6 renders in-process with a live pixel
preview inside the 3D view, and a real cancel (Esc) instead of only killing
a subprocess.

`USE_VFE` defaults to `0` (off) and building bpp normally is unaffected by
it either way. Turning it on requires a sibling
[POV-Ray source checkout](https://github.com/POV-Ray/povray) and a prebuilt
static library — see [`povray-mingw/README.md`](povray-mingw/README.md)
(Windows/MSYS2 MinGW-w64) or [`povray-linux/README.md`](povray-linux/README.md)
(Linux) for the full build steps. Once that's in place:

```bash
qmake "USE_VFE=1" bpp.pro
```

This is a prototype, and statically linking POV-Ray's AGPLv3-licensed core
into bpp's AGPLv3 binary means the resulting binary is bound by AGPLv3
obligations — worth deciding deliberately before shipping a
`USE_VFE=1` build beyond a local build.

The Linux build has been verified end-to-end (builds, links, and renders via
F6 without crashing); see [`povray-linux/README.md`](povray-linux/README.md)
for the gotchas that took to get there. The Windows/MSYS2 path is untested
beyond compiling — see [`povray-mingw/README.md`](povray-mingw/README.md).

## Usage

### GUI

#### Menu shortcuts

These work anywhere in the main window (including while editing the Lua
script):

*   **Ctrl+N:** New file.
*   **Ctrl+O:** Open file.
*   **Ctrl+S:** Save file.
*   **Ctrl+A:** Save file as.
*   **Ctrl+Q:** Exit.
*   **F12:** Preferences.
*   **Ctrl+C:** Start/pause the physics simulation.
*   **Ctrl+R:** Restart the simulation.
*   **F6:** Quick render current frame with POV-Ray (or in-process via the
    experimental embedded VFE API, if enabled — see
    [Optional: embedded POV-Ray VFE rendering](#optional-embedded-pov-ray-vfe-rendering-experimental-windows-only)
    above).
*   **F11:** Toggle full screen.

#### 3D view shortcuts

These require the 3D view to have keyboard focus:

*   **S:** Start/stop the physics simulation.
*   **P:** Toggle POV-Ray export mode.
*   **G:** Toggle PNG screenshot saving mode.
*   **A:** Toggle display of the world axis.
*   **F:** Toggle FPS display.
*   **Enter:** Start/stop the animation.
*   **Space:** Toggle between fly and revolve camera modes; while an
    embedded VFE render (see above) is in progress, pauses/resumes it
    instead.
*   **Esc:** Cancel an in-progress embedded VFE render.
*   **Arrow Keys:** Move the camera.
*   **Tab:** Toggle between the single perspective view and a 4-view
    CAD-style layout (perspective, top, front, right). Scroll to zoom and
    drag to pan in the top/front/right views.
*   **H:** Show the QGLViewer help window.

### Command-Line

The command-line interface allows you to run simulations without the GUI. For
example, you can pipe the simulation data to `gnuplot` to visualize the results:

```bash
bpp -n 200 -f demo/basic/01-hello-cmdline.lua | \
    gnuplot -e "set terminal dumb; plot for[col=3:3] '/dev/stdin' using 1:col title columnheader(col) with lines"
```

### Distributed rendering with povomatic

[povomatic](https://github.com/koppi/povomatic) renders a POV-Ray animation
across a Kubernetes cluster, one job per frame. To send it a bpp scene, export
the frames and submit from the export directory:

```bash
bpp -f demo/basic/00-hello.lua -n 278 -e       # writes export/00-hello/
make -C export/00-hello povomatic              # rsync + submit via povomatic.py
```

`make povomatic` runs [`scripts/povomatic-job.py`](scripts/povomatic-job.py),
which copies `includes/` **and POV-Ray's own standard includes** (`colors.inc`
etc., which `settings.inc` pulls in and the render image does not ship) to
povomatic's shared asset volume, copies the exported scene to its input volume,
and calls `povomatic.py` with the frame count and clock range read from the
generated `.ini` (bpp exports each frame so that POV-Ray's `clock` equals the
frame number). Pass extra options through
`POVOMATIC_ARGS`, e.g. `make -C export/00-hello povomatic POVOMATIC_ARGS="--res 1080p --priority 5"`;
run `scripts/povomatic-job.py --help` for the full list. The API URL comes from
`$POVOMATIC_API` (or `--api-url`); `$POVOMATIC_INPUT`, `$POVOMATIC_ASSETS`,
`$POVOMATIC_REMOTE_INPUT` and `$POVRAY_INCLUDE_DIR` override the volume and
include paths.

## Documentation / Wiki

* [Basic Usage HOWTO](https://github.com/bullet-physics-playground/bpp/wiki/Basic-Usage-HOWTO)
* [LUA Bindings Reference](https://github.com/bullet-physics-playground/bpp/wiki/LUA-Bindings-Reference)

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an
issue on the [GitHub repository](https://github.com/bullet-physics-playground/bpp).

## Contributions

### People

*   **Jakob Flierl** – [koppi](https://github.com/koppi) – Creator and
    primary maintainer since 2011.
*   **Jaime Vives Piqueres** – [jaimevives](https://github.com/jaimevives) –
    POV-Ray export, the [Citroën GS](demo/jaimevives) and
    [box-with-oranges](includes/README.md) demo scenes, and his
    [latest computer generated images](http://www.ignorancia.org/index.php?page=latest-images).
*   **WyomingWill** – the [Chebyshev four-bar linkage walker
    demos](demo/WyomingWill).
*   Demos in [`demo/claude`](demo/claude) and select other scripts were
    developed with the assistance of
    [Claude Code](https://claude.com/claude-code).

### Bundled third-party content

The [`includes/`](includes/) directory bundles POV-Ray assets and lighting
macros from other authors, each under its own terms; see
[includes/README.md](includes/README.md) for full details.

| Content | Author(s) | License |
| --- | --- | --- |
| [LightSys 4](includes/readme_lightsys.txt) lighting macros | Jaime Vives Piqueres, with Ive and Philippe Debar | not stated in-repo; used with attribution |
| [CIE XYZ color model](includes/readme_cie.txt) | Ive | not stated in-repo; used with attribution |
| [Skylight model](includes/readme_skylight.txt) | Philippe Debar, adapted by Ive | not stated in-repo; used with attribution |
| [Studio Lighting Kit](includes/studio-light-readme.txt) | Jaime Vives Piqueres | not stated in-repo; used with attribution |
| Box-of-oranges scene | Jaime Vives Piqueres | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0) |
| Citroën GS car model | Jaime Vives Piqueres | [CC BY-SA 3.0](http://creativecommons.org/licenses/by-sa/3.0) |
| Nissan Micra K11 car model | Rene Bui | [CC BY-NC 3.0](http://creativecommons.org/licenses/by-nc/3.0/) |
| Dice model | found on Wikipedia | [Public Domain](https://creativecommons.org/publicdomain/zero/1.0/) |
| Humanity icon theme | Canonical / Ubuntu | not stated in-repo; used with attribution |

A few other bundled POV-Ray assets (e.g. the LEGO buggy, Wunderbaum, and
cajón meshes under `includes/`) carry no attribution or license information
in this repository.

## License

The Bullet Physics Playground itself is licensed under the
[GNU Affero General Public License v3](LICENSE). Bundled third-party content
retains its own license as noted above.
